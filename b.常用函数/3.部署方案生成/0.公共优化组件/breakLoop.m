%[text] # breakLoop
function loopFreePlan = breakLoop(sortedRequests, plan, links)
%BREAKLOOP 仅对输入 plan 进行“破环（去环）修复”（接口与 FixedTreePlan 保持一致）
%
% 目的：
%   - 参考 FixedTreePlan.m 的 “B. 去环：保持 src 到所有 dest 连通的前提下删边”；
%   - 只修复环，不做“入度<=1树化”、不修正 vnfNode；
%   - 输出 placeLinks 为 1×M 的“边集合”（DAG 边集合）。
%
% 输入：
%   sortedRequests(i): 至少含 .id .source .dest .bandwidth
%   plan(i):           至少含 .placeLinks / .vnfNode
%   links(eid):        至少含 .source .dest .bandwidth(1)
%
% 输出：
%   loopFreePlan(i):
%     .req_id
%     .placeLinks   1×M（已去环）
%     .vnfNode      原样拷贝（不做合法性修正）

    loopFreePlan = repmat(struct( ...
        'req_id',     0, ...
        'placeLinks', [], ...
        'vnfNode',    [] ...
    ), numel(plan), 1);

    for i = 1:numel(plan)
        req = sortedRequests(i);
        onePlan = plan(i);

        loopFreePlan(i).req_id = req.id;
        if isfield(onePlan, 'vnfNode')
            loopFreePlan(i).vnfNode = onePlan.vnfNode;
        else
            loopFreePlan(i).vnfNode = [];
        end

        if ~isfield(onePlan, 'placeLinks') || isempty(onePlan.placeLinks)
            loopFreePlan(i).placeLinks = [];
            continue;
        end

        allEids = unique(onePlan.placeLinks(onePlan.placeLinks > 0));
        if isempty(allEids)
            loopFreePlan(i).placeLinks = [];
            continue;
        end

        u = arrayfun(@(eid) links(eid).source, allEids);
        v = arrayfun(@(eid) links(eid).dest,   allEids);
        G = digraph(u, v);
        G.Edges.eid = allEids(:);

        % 成本：沿用 FixedTreePlan
        costMap = inf(1, numel(links));
        for k = 1:numel(allEids)
            eid = allEids(k);
            bwAvail = links(eid).bandwidth(1);
            if bwAvail <= 0
                costMap(eid) = inf;
            else
                costMap(eid) = req.bandwidth / bwAvail;
            end
        end

        src = req.source;
        dests = req.dest(req.dest > 0);

        % ---------- 去环：保持 src->dests 连通 ----------
        guard = 0;
        while ~isdag(G)
            guard = guard + 1;
            if guard > 2000
                break; % 极端兜底：避免死循环
            end

            cycEids = findOneCycleEids(G);
            if isempty(cycEids)
                break;
            end

            [~, ord] = sort(costMap(cycEids), 'descend');

            removed = false;
            for t = 1:numel(ord)
                eidRemove = cycEids(ord(t));
                eidx = find(G.Edges.eid == eidRemove, 1);
                if isempty(eidx)
                    continue;
                end

                G2 = rmedge(G, eidx);
                if isempty(dests) || all(~isinf(distances(G2, src, dests)))
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
                    break;
                end
            end
        end

        loopFreePlan(i).placeLinks = G.Edges.eid(:).';
    end
end

% ========================================================================
% ================= 子函数：在有向图里找一条环上的 eid 集合 ================
% ========================================================================
function cycEids = findOneCycleEids(G)
% 与 FixedTreePlan.m 内部版本保持一致（轻量复制）
    N = numnodes(G);
    E = numedges(G);

    endNodes = G.Edges.EndNodes;
    eids     = G.Edges.eid;

    adj  = cell(N,1);
    adjE = cell(N,1);
    for i = 1:E
        a = endNodes(i,1);
        b = endNodes(i,2);
        adj{a}(end+1)  = b; %#ok<AGROW>
        adjE{a}(end+1) = eids(i); %#ok<AGROW>
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
            vv = adj{u}(kk);
            eid = adjE{u}(kk);

            if ~visited(vv)
                parentN(vv) = u;
                parentE(vv) = eid;
                [found, cyc] = dfs(vv);
                if found
                    onstack(u) = false;
                    return;
                end
            elseif onstack(vv)
                cyc = eid;
                x = u;
                while x ~= vv
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