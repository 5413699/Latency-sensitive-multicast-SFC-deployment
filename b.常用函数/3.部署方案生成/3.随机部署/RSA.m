%[text] # RSA
%[text] 做一个“随机但可行”的对照，证明你的算法不是靠运气
%[text]
%[text] **具体流程（按每个请求req）：**
%[text] - 对于已部署的 VNFs（同一请求的前序目的分支已放置过该VNF）：在这些已选节点里随机复用；
%[text] - 对于未部署的 VNFs：随机选择 CPU/Mem 资源充足的节点部署（仅在本请求内扣减一次资源预算）；
%[text] - 节点确定后，用最短路把 src / VNF1 / ... / VNFk / dest 按顺序连接成链路序列 placeLinks。
%[text]
%[text] **典型特征：**
%[text] - 结果波动大，但实现简单，可作为随机对照基线；
%[text] - 用于证明“你的评价函数/搜索过程确实有效”。
%[text]
%[text] 说明：
%[text] - 本函数只生成 plan，不做真实部署；这里的“可行”仅基于 t=1 的节点资源预算与连通性。
%[text] - 资源需求：沿用项目内常见约定 cpu_need=vnfId, mem_need=vnfId。

function plan = RSA(requests, KPathsNew, links, nodes, plan, deployMethodCfg) %#ok<INUSD>
% deployMethodCfg 参数为保持接口一致性，本算法不使用

numReqs = numel(requests);
numNodes = numel(nodes);
T0 = 1; % 计划生成阶段使用 t=1 的资源快照（与项目内其他plan生成函数一致）

for req_idx = 1:numReqs
    req = requests(req_idx);
    src = req.source;
    dests = req.dest(req.dest > 0);
    dest_num = numel(dests);
    vnf_num  = numel(req.vnf);
    link_num = size(links, 2);

    newPlan = struct( ...
        'req_id',     req.id, ...
        'placeLinks', zeros(dest_num, link_num), ...
        'vnfNode',    zeros(dest_num, vnf_num) ...
    );

    % 本请求的“资源预算快照”（只用于保证同一请求内的新建实例不超分配）
    cpuBudget = zeros(numNodes, 1);
    memBudget = zeros(numNodes, 1);
    for n = 1:numNodes
        cpuBudget(n) = nodes(n).cpu(min(T0, numel(nodes(n).cpu)));
        memBudget(n) = nodes(n).mem(min(T0, numel(nodes(n).mem)));
    end

    % 本请求内“已部署/可复用”的VNF实例（按 vnf_idx 维度）
    sharedNodesByVnf = cell(1, vnf_num);

    for di = 1:dest_num
        d = dests(di);

        maxTrials = 30;
        ok = false;

        for trial = 1:maxTrials
            % trial 级回滚：只有成功才提交
            cpuBudgetLocal = cpuBudget;
            memBudgetLocal = memBudget;
            sharedLocal = sharedNodesByVnf;

            vnfNodes = zeros(1, vnf_num);

            % 1) 随机确定 VNF 放置节点
            for v = 1:vnf_num
                vnfId = req.vnf(v);
                cpu_need = vnfId;
                mem_need = vnfId;

                % 已部署：随机复用
                if ~isempty(sharedLocal{v})
                    cand = sharedLocal{v};
                    vnfNodes(v) = cand(randi(numel(cand)));
                    continue;
                end

                % 未部署：随机新建（资源可行）
                feasible = find(cpuBudgetLocal >= cpu_need & memBudgetLocal >= mem_need).';
                feasible = feasible(feasible >= 1 & feasible <= numNodes);
                if isempty(feasible)
                    vnfNodes(:) = 0;
                    break;
                end

                chosen = feasible(randi(numel(feasible)));
                vnfNodes(v) = chosen;

                % 扣减一次预算，并加入可复用集合
                cpuBudgetLocal(chosen) = cpuBudgetLocal(chosen) - cpu_need;
                memBudgetLocal(chosen) = memBudgetLocal(chosen) - mem_need;
                sharedLocal{v} = unique([sharedLocal{v}, chosen]); %#ok<AGROW>
            end

            if any(vnfNodes <= 0)
                continue; % trial失败
            end

            % 2) 用最短路把 src->VNF1->...->VNFK->dest 串起来
            chainNodes = [src, vnfNodes, d];
            linkSeq = [];
            for sidx = 1:(numel(chainNodes)-1)
                a = chainNodes(sidx);
                b = chainNodes(sidx+1);
                seg = getShortestLinkSeq(KPathsNew, a, b);
                if isempty(seg)
                    linkSeq = [];
                    break;
                end
                linkSeq = [linkSeq, seg]; %#ok<AGROW>
            end

            if isempty(linkSeq)
                continue; % trial失败
            end

            % trial成功：提交
            ok = true;
            cpuBudget = cpuBudgetLocal;
            memBudget = memBudgetLocal;
            sharedNodesByVnf = sharedLocal;

            newPlan.vnfNode(di, :) = vnfNodes;
            L = min(numel(linkSeq), link_num);
            newPlan.placeLinks(di, 1:L) = linkSeq(1:L);
            break;
        end

        if ~ok
            % 兜底：退化为 src->dest 最短路，并在该路径上均匀放置 VNF
            [fbLinks, fbVnfNodes] = fallbackShortestPathPlacement(KPathsNew, src, d, vnf_num);
            if ~isempty(fbLinks)
                L = min(numel(fbLinks), link_num);
                newPlan.placeLinks(di, 1:L) = fbLinks(1:L);
            end
            newPlan.vnfNode(di, :) = fbVnfNodes;
        end
    end

    if isempty(plan)
        plan(1) = newPlan;
    else
        plan(end+1) = newPlan;
    end
end
end

% ===================== local helpers =====================
function linkSeq = getShortestLinkSeq(KPathsNew, a, b)
% 取 a->b 的第一条最短路链路序列（KPathsNew格式）
linkSeq = [];
if a <= 0 || b <= 0
    return;
end
try
    routes = KPathsNew{a, b};
catch
    routes = [];
end
if isempty(routes)
    return;
end
r = routes(1);
if ~isfield(r, 'link_ids') || isempty(r.link_ids)
    return;
end
linkSeq = r.link_ids(:).';
linkSeq = linkSeq(linkSeq > 0);
end

function [linkIds, vnfNodes] = fallbackShortestPathPlacement(KPathsNew, src, dest, vnf_num)
% 兜底：沿 src->dest 最短路均匀放置 VNF（确保产出 plan）
linkIds = [];
vnfNodes = zeros(1, vnf_num);
try
    routes = KPathsNew{src, dest};
catch
    routes = [];
end
if isempty(routes)
    return;
end
r = routes(1);
if ~isfield(r, 'link_ids') || ~isfield(r, 'paths')
    return;
end
linkIds = r.link_ids(:).';
linkIds = linkIds(linkIds > 0);
pathNodes = r.paths(:).';
pathNodes = pathNodes(pathNodes > 0);
hops = numel(linkIds);
if hops <= 0 || numel(pathNodes) < 2
    return;
end
for v = 1:vnf_num
    idx = ceil(v * hops / vnf_num); % 1..hops
    pos = 1 + idx;                  % 跳过src
    if pos <= numel(pathNodes)
        vnfNodes(v) = pathNodes(pos);
    else
        vnfNodes(v) = pathNodes(end);
    end
end
end

%[appendix]{"version":"1.0"}
%---
