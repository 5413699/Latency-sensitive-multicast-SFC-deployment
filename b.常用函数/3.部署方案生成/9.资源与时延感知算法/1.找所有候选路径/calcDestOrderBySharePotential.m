%[text] # calcDestOrderBySharePotential
%[text] 根据共享潜力选择下一个要加入多播树的目的节点
%[text] 
%[text] ## 核心思想
%[text] - 首次调用（已建树为空）：选择K路平均共享潜力最高的目的节点（基于全局介数中心性）
%[text] - 后续调用（已建树非空）：选择与已建树共享度最高的目的节点
%[text] 
%[text] ## 输入参数
%[text] - src: 源节点ID
%[text] - remainDests: 剩余未加入树的目的节点数组
%[text] - KPathsNew: K条最短路信息（cell数组）
%[text] - links: 链路状态数组
%[text] - nodes: 节点状态数组
%[text] - usedLinks: 已建树使用的链路集合（首次调用传空数组[]）
%[text] - usedNodes: 已建树使用的节点集合（首次调用传空数组[]）
%[text] 
%[text] ## 输出参数
%[text] - nextDest: 下一个要加入的目的节点ID
%[text] - nextScore: 该节点的评分
%[text] - globalNodeFreq: 全局节点频率（供外部复用，避免重复计算）
%[text] - globalLinkFreq: 全局链路频率（供外部复用，避免重复计算）

function [nextDest, nextScore, globalNodeFreq, globalLinkFreq] = calcDestOrderBySharePotential( ...
    src, remainDests, KPathsNew, links, nodes, usedLinks, usedNodes, globalNodeFreq, globalLinkFreq)
    
    destNum = numel(remainDests);
    
    % 边界情况：只有1个目的节点，直接返回
    if destNum <= 1
        if destNum == 1
            nextDest = remainDests(1);
            nextScore = 0;
        else
            nextDest = [];
            nextScore = -inf;
        end
        % 如果没有传入全局频率，初始化为空
        if nargin < 8 || isempty(globalNodeFreq)
            globalNodeFreq = [];
            globalLinkFreq = [];
        end
        return;
    end
    
    % 处理可选参数
    if nargin < 6, usedLinks = []; end
    if nargin < 7, usedNodes = []; end
    if nargin < 8, globalNodeFreq = []; end
    if nargin < 9, globalLinkFreq = []; end
    
    % ========== Step 1: 计算全局共享频率（仅首次计算）==========
    % 如果没有传入全局频率，则计算（首次调用时）
    if isempty(globalNodeFreq) || isempty(globalLinkFreq)
        [globalNodeFreq, globalLinkFreq] = calcGlobalFrequency(src, remainDests, KPathsNew, links, nodes);
    end
    
    % ========== Step 2: 根据是否有已建树选择不同策略 ==========
    isFirstNode = isempty(usedLinks) && isempty(usedNodes);
    
    if isFirstNode
        % ===== 首个节点：基于全局共享潜力选择 =====
        [nextDest, nextScore] = selectFirstDest(src, remainDests, KPathsNew, globalNodeFreq, globalLinkFreq);
    else
        % ===== 后续节点：基于与已建树的共享度选择 =====
        [nextDest, nextScore] = selectNextDest(src, remainDests, KPathsNew, usedLinks, usedNodes);
    end
end


%% ========== 辅助函数：计算全局共享频率 ==========
function [globalNodeFreq, globalLinkFreq] = calcGlobalFrequency(src, dests, KPathsNew, links, nodes)
%CALCGLOBALFREQUENCY 统计所有目的节点的所有K路中，各链路/节点的出现频率

    max_link_id = max([links.id]);
    max_node_id = max([nodes.id]);
    
    globalNodeFreq = zeros(max_node_id, 1);
    globalLinkFreq = zeros(max_link_id, 1);
    
    for di = 1:numel(dests)
        d = dests(di);
        routes = KPathsNew{src, d};
        
        if isempty(routes)
            continue;
        end
        
        for k = 1:numel(routes)
            hops = routes(k).pathshops;
            if hops <= 0
                continue;
            end
            
            % 节点频率
            path_nodes = routes(k).paths;
            path_nodes = path_nodes(path_nodes > 0);
            if ~isempty(path_nodes)
                globalNodeFreq(path_nodes) = globalNodeFreq(path_nodes) + 1;
            end
            
            % 链路频率
            path_links = routes(k).link_ids;
            path_links = path_links(path_links > 0);
            if ~isempty(path_links)
                globalLinkFreq(path_links) = globalLinkFreq(path_links) + 1;
            end
        end
    end
end


%% ========== 辅助函数：选择首个目的节点 ==========
function [nextDest, nextScore] = selectFirstDest(src, dests, KPathsNew, globalNodeFreq, globalLinkFreq)
%SELECTFIRSTDEST 基于全局共享潜力选择首个目的节点

    destNum = numel(dests);
    scores = zeros(destNum, 1);
    
    for di = 1:destNum
        d = dests(di);
        routes = KPathsNew{src, d};
        
        if isempty(routes)
            scores(di) = -inf;
            continue;
        end
        
        % 计算该dest所有K路的平均共享度
        linkScoreSum = 0;
        nodeScoreSum = 0;
        validPathCount = 0;
        
        for k = 1:numel(routes)
            hops = routes(k).pathshops;
            if hops <= 0
                continue;
            end
            
            path_nodes = routes(k).paths;
            path_nodes = path_nodes(path_nodes > 0);
            path_links = routes(k).link_ids;
            path_links = path_links(path_links > 0);
            
            if isempty(path_links)
                continue;
            end
            
            % 该路径的平均链路共享度
            linkScore = mean(globalLinkFreq(path_links));
            % 该路径的平均节点共享度
            if ~isempty(path_nodes)
                nodeScore = mean(globalNodeFreq(path_nodes));
            else
                nodeScore = 0;
            end
            
            linkScoreSum = linkScoreSum + linkScore;
            nodeScoreSum = nodeScoreSum + nodeScore;
            validPathCount = validPathCount + 1;
        end
        
        if validPathCount > 0
            scores(di) = (linkScoreSum + nodeScoreSum) / validPathCount;
        else
            scores(di) = -inf;
        end
    end
    
    % 归一化评分
    validMask = isfinite(scores);
    if any(validMask) && sum(validMask) > 1
        scores(validMask) = minmax01(scores(validMask));
    end
    
    % 选择评分最高的
    [nextScore, bestIdx] = max(scores);
    nextDest = dests(bestIdx);
end


%% ========== 辅助函数：选择后续目的节点 ==========
function [nextDest, nextScore] = selectNextDest(src, remainDests, KPathsNew, usedLinks, usedNodes)
%SELECTNEXTDEST 基于与已建树的共享度选择下一个目的节点

    destNum = numel(remainDests);
    scores = zeros(destNum, 1);
    
    for di = 1:destNum
        d = remainDests(di);
        routes = KPathsNew{src, d};
        
        if isempty(routes)
            scores(di) = -inf;
            continue;
        end
        
        % 计算该dest各K路与已建树的重叠度
        linkOverlapSum = 0;
        nodeOverlapSum = 0;
        validPathCount = 0;
        
        for k = 1:numel(routes)
            hops = routes(k).pathshops;
            if hops <= 0
                continue;
            end
            
            path_nodes = routes(k).paths;
            path_nodes = path_nodes(path_nodes > 0);
            path_links = routes(k).link_ids;
            path_links = path_links(path_links > 0);
            
            if isempty(path_links)
                continue;
            end
            
            % 链路重叠比例
            if ~isempty(usedLinks)
                linkOverlap = numel(intersect(path_links, usedLinks)) / numel(path_links);
            else
                linkOverlap = 0;
            end
            
            % 节点重叠比例
            if ~isempty(path_nodes) && ~isempty(usedNodes)
                nodeOverlap = numel(intersect(path_nodes, usedNodes)) / numel(path_nodes);
            else
                nodeOverlap = 0;
            end
            
            linkOverlapSum = linkOverlapSum + linkOverlap;
            nodeOverlapSum = nodeOverlapSum + nodeOverlap;
            validPathCount = validPathCount + 1;
        end
        
        if validPathCount > 0
            scores(di) = (linkOverlapSum + nodeOverlapSum) / validPathCount;
        else
            scores(di) = -inf;
        end
    end
    
    % 归一化评分
    validMask = isfinite(scores);
    if any(validMask) && sum(validMask) > 1
        scores(validMask) = minmax01(scores(validMask));
    end
    
    % 选择共享度最高的
    [nextScore, bestIdx] = max(scores);
    nextDest = remainDests(bestIdx);
end

%[appendix]{"version":"1.0"}
%---

