%[text] # FixedTreePlan
function treePlan = FixedTreePlan(sortedRequests, plan, links)
% BuildTreePlan
% 作用：对每个请求 i，基于 plan(i) 的 placeLinks/vnfNode 合并修正成一棵合法多播树，
%      并输出 treePlan(i).placeLinks 和 treePlan(i).vnfNode
%
% 输入：
%   sortedRequests(i): 至少含 .id .source .dest .bandwidth
%   plan(i):           至少含 .placeLinks (dest_num×*) / .vnfNode (dest_num×vnf_num)
%   links(eid):        至少含 .source .dest .bandwidth(至少可索引到(1))
%
% 输出：
%   treePlan(i):
%     .req_id
%     .placeLinks   1×M
%     .vnfNode      dest_num×vnf_num

treePlan = repmat(struct( ...
    'req_id',     0, ...
    'placeLinks', [], ...
    'vnfNode',    [] ...
), numel(plan), 1);

for i = 1:numel(plan)
    req = sortedRequests(i);

    [placeLinks, vnfNodeFixed] = FixMulticastTree(req, plan(i), links);

    treePlan(i).req_id     = req.id;
    treePlan(i).placeLinks = placeLinks;
    treePlan(i).vnfNode    = vnfNodeFixed;
end

end % ====== BuildTreePlan ======



% ========================================================================
% ====================== 本文件内：修正多播树核心函数 ======================
% ========================================================================
function [placeLinks, vnfNodeFixed] = FixMulticastTree(req, onePlan, links)
% FixMulticastTree
% 输出：
%   placeLinks: 修正后多播树链路ID集合（1×M）
%   vnfNodeFixed: 修正后的 VNF 放置矩阵（dest_num×vnf_num）

src   = req.source;
dests = req.dest(req.dest > 0);
dest_num = numel(dests);

vnfNodeFixed = onePlan.vnfNode;
vnf_num = size(vnfNodeFixed, 2);

% ---------- A. 从方案里抽出用到的边，得到"候选树" ----------
allEids = unique(onePlan.placeLinks(onePlan.placeLinks > 0));

u = arrayfun(@(eid) links(eid).source, allEids);
v = arrayfun(@(eid) links(eid).dest,   allEids);

G = digraph(u, v);
G.Edges.eid = allEids(:);

% ---------- 资源消耗（用于删边时对比大小） ----------
costMap = inf(1, numel(links));
for k = 1:numel(allEids)
    eid = allEids(k);

    bwAvail = links(eid).bandwidth(1);
    if bwAvail <= 0
        costMap(eid) = inf; % 防除0
    else
        costMap(eid) = req.bandwidth / bwAvail;
    end
end

% ---------- B. 去环：保持 src 到所有 dest 连通的前提下删边 ----------
while ~isdag(G)
    cycEids = findOneCycleEids(G);
    [~, ord] = sort(costMap(cycEids), 'descend');

    removed = false;
    for t = 1:numel(ord)
        eidRemove = cycEids(ord(t));
        eidx = find(G.Edges.eid == eidRemove, 1);
        if isempty(eidx)
            continue; % 极端兜底：该边已不在图中（可能前面已删）
        end

        G2 = rmedge(G, eidx);
        if all(~isinf(distances(G2, src, dests)))
            G = G2;
            removed = true;
            break;
        end
    end

    % 极端兜底：怎么删都不连通，就强删最贵的继续推进
    if ~removed
        eidRemove = cycEids(ord(1));
        eidx = find(G.Edges.eid == eidRemove, 1);
        if ~isempty(eidx)
        G = rmedge(G, eidx);
        else
            % 如果找不到，直接跳出避免死循环
            break;
        end
    end
end

% ---------- C. 进一步变成"树"：每个节点最多一个父边（入度<=1） ----------
indeg = indegree(G);
for n = 1:numnodes(G)
    if n == src, continue; end
    if indeg(n) > 1
        inIdx  = inedges(G, n);
        inEids = G.Edges.eid(inIdx);

        % 注意：rmedge 会导致边索引重排，所以不能用“提前缓存的 edgeIdx”循环删除
        % 这里改为按 eid（linkId）逐次定位并删除，避免“边索引越界”错误
        [~, keepPos] = min(costMap(inEids));
        keepEid = inEids(keepPos);

        rmEids = setdiff(inEids, keepEid); % 需要尝试移除的 eid 集合
        [~, rmOrd] = sort(costMap(rmEids), 'descend');

        for t = 1:numel(rmOrd)
            eidRemove = rmEids(rmOrd(t));
            eidx = find(G.Edges.eid == eidRemove, 1);
            if isempty(eidx)
                continue; % 可能前面已被删除
            end

            G2 = rmedge(G, eidx);
            if all(~isinf(distances(G2, src, dests)))
                G = G2;
            end
        end
    end
end

% ---------- D. 生成树深度 + 每个目的在树上的路径 ----------
depth = inf(numnodes(G), 1);
depth(src) = 0;

queue = src;
head = 1;
while head <= numel(queue)
    x = queue(head); head = head + 1;
    ch = successors(G, x);
    for kk = 1:numel(ch)
        y = ch(kk);
        if isinf(depth(y))
            depth(y) = depth(x) + 1;
            queue(end+1) = y; %#ok<AGROW>
        end
    end
end

paths = cell(dest_num, 1);
for di = 1:dest_num
    paths{di} = shortestpath(G, src, dests(di));
end

% ---------- E. VNF 合法性：保证每个目的的每级VNF节点在该目的树路径上 ----------
for di = 1:dest_num
    p = paths{di};
    L = numel(p);

    for vnf_idx = 1:vnf_num
        n0 = vnfNodeFixed(di, vnf_idx);
        if ~any(p == n0)
            hopIdx = ceil(vnf_idx * (L-1) / vnf_num); % 1..(L-1)
            pos = 1 + hopIdx;                          % 跳过源
            vnfNodeFixed(di, vnf_idx) = p(pos);
        end
    end
end

% ---------- F. VNF 去重：按每个目的路径向源对齐 + 保序 ----------
for vnf_idx = 1:vnf_num
    cand = unique(vnfNodeFixed(:, vnf_idx));

    for di = 1:dest_num
        p = paths{di};

        % 最早深度约束（保序）
        if vnf_idx == 1
            minDepth = depth(src) + 1;
        else
            minDepth = depth(vnfNodeFixed(di, vnf_idx-1));
        end

        feasible = cand(ismember(cand, p) & depth(cand) >= minDepth);

        % ---- 修正点：feasible 可能为空，原代码会报错 ----
        if isempty(feasible)
            % 兜底：在自己的路径 p 上找第一个满足深度约束的节点
            idx = find(depth(p) + 0 >= minDepth, 1, 'first');  % +0 避免某些类型问题
            if isempty(idx)
                vnfNodeFixed(di, vnf_idx) = p(end);
            else
                vnfNodeFixed(di, vnf_idx) = p(idx);
            end
        else
            [~, pos] = min(depth(feasible));
            vnfNodeFixed(di, vnf_idx) = feasible(pos);
        end
    end
end

% ---------- 输出：树链路集合 ----------
placeLinks = G.Edges.eid(:).';

end % ====== FixMulticastTree ======



% ========================================================================
% ================= 子函数：在有向图里找一条环上的 eid 集合 ================
% ========================================================================
function cycEids = findOneCycleEids(G)
N = numnodes(G);
E = numedges(G);

endNodes = G.Edges.EndNodes;
eids     = G.Edges.eid;

adj  = cell(N,1);
adjE = cell(N,1);
for i = 1:E
    a = endNodes(i,1);
    b = endNodes(i,2);
    adj{a}(end+1)  = b;
    adjE{a}(end+1) = eids(i);
end

visited = false(N,1);
onstack = false(N,1);
parentN = zeros(N,1);
parentE = zeros(N,1);

cycEids = [];

for s = 1:N
    if ~visited(s)
        [found, cyc] = dfs(s);
        if found
            cycEids = unique(cyc);
            return;
        end
    end
end

    function [found, cyc] = dfs(u)
        visited(u) = true;
        onstack(u) = true;

        for kk = 1:numel(adj{u})
            v = adj{u}(kk);
            eid = adjE{u}(kk);

            if ~visited(v)
                parentN(v) = u;
                parentE(v) = eid;
                [found, cyc] = dfs(v);
                if found
                    onstack(u) = false;
                    return;
                end
            elseif onstack(v)
                % 回边 u->v，回溯构造环上的 eid
                cyc = eid;
                x = u;
                while x ~= v
                    cyc(end+1) = parentE(x); %#ok<AGROW>
                    x = parentN(x);
                end
                found = true;
                onstack(u) = false;
                return;
            end
        end

        onstack(u) = false;
        found = false;
        cyc = [];
    end
end


%[appendix]{"version":"1.0"}
%---
