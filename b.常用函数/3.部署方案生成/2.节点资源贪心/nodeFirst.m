%[text] # nodeFirst
%[text] 空闲节点优先多播SFC部署方案生成
%[text] 
%[text] ## 算法思路
%[text] 1. 路径选择：从K条候选路径中选择平均节点空闲度最高的路径
%[text] 2. VNF放置：在路径节点中，按顺序为每个VNF选择资源剩余百分比最大的候选节点
%[text] 
%[text] ## 输入参数说明

function plan = nodeFirst(requests, KPathsNew, links, nodes, plan, deployMethodCfg)
% deployMethodCfg参数为保持接口一致性，此算法未使用

% 遍历每个多播sfc请求
numReqs = numel(requests);
for req_idx = 1:numReqs
    req = requests(req_idx);
    % 输出：plan.id / plan.placeLinks / plan.vnfNode
    src = req.source;
    dests = req.dest(req.dest > 0);
    dest_num = numel(dests);
    vnf_num  = numel(req.vnf);
    link_num = size(links, 2);
    
    % ====== 记录一条策略 ======
    newPlan = struct( ...
        'req_id',    req.id, ...       % 请求ID
        'placeLinks', zeros(dest_num, link_num), ...    
        'vnfNode',   zeros(dest_num, vnf_num)...      
    );
    
    
    for di = 1:dest_num
        d = dests(di);
        
        % 使用KPathsNew格式：KPathsNew{src, d}是K×1的struct数组
        routes = KPathsNew{src, d};
        
        % 检查是否有可用路径
        if isempty(routes)
            warning('请求%d: 源%d到目的%d没有可用路径', req.id, src, d);
            continue;
        end
        
        % ====== 【改进1】选择平均节点空闲度最高的路径 ======
        bestRoute = routes(1);
        bestAvgFree = -inf;
        
        for ri = 1:numel(routes)
            route = routes(ri);
            if route.pathshops <= 0
                continue;
            end
            
            % 计算该路径上所有节点的平均空闲度
            pathNodes_tmp = route.paths;
            pathNodes_tmp = pathNodes_tmp(pathNodes_tmp > 0);
            
            if isempty(pathNodes_tmp)
                continue;
            end
            
            % 计算平均节点资源空闲度（CPU和内存的综合）
            avgFree = calcPathNodeFreeRatio(pathNodes_tmp, nodes);
            
            if avgFree > bestAvgFree
                bestAvgFree = avgFree;
                bestRoute = route;
            end
        end
    
        % 最短路跳数（可用放置节点数）
        hops = bestRoute.pathshops;
        
        if hops <= 0
            warning('请求%d: 源%d到目的%d的路径跳数为0', req.id, src, d);
            continue;
        end
        
        % 获取链路序列（KPathsNew格式已去0）
        linkIds = bestRoute.link_ids;
        
        % 记录 src->dest 的链路序列
        actualHops = numel(linkIds);
        newPlan.placeLinks(di, 1:actualHops) = linkIds;
    
        % 获取节点序列（KPathsNew格式已去0）
        pathNodes = bestRoute.paths;
        pathNodes = pathNodes(pathNodes > 0);
    
        % ====== 【改进2】VNF放置：贪心选择资源剩余百分比最大的候选节点 ======
        % 该算法不考虑链路资源，仅考虑节点资源
        % VNF 放置：优先放置在资源剩余百分比最大候选节点
        % 注意：允许在同一节点重复放置VNF（候选节点可以在上一个VNF位置或之后）
        
        lastPlacedIdx = 2;  % 上一个VNF放置的位置索引（从第2个节点开始，跳过源节点）
        
        for v = 1:vnf_num
            % 候选节点范围：从上一个VNF位置（含）到路径末端
            % 注意：允许在同一节点重复放置VNF
            minIdx = lastPlacedIdx;  % 可以在上一个位置或之后（允许同节点放置）
            maxIdx = numel(pathNodes);  % 可以放到路径末端
            
            if minIdx > maxIdx
                % 没有足够空间，强制放在当前位置
                minIdx = min(lastPlacedIdx, numel(pathNodes));
                maxIdx = minIdx;
            end
            
            % 在候选范围内寻找资源剩余百分比最大的节点
            bestNodeIdx = minIdx;
            bestFreeRatio = -inf;
            
            for idx = minIdx:maxIdx
                nid = pathNodes(idx);
                freeRatio = calcNodeFreeRatio(nid, nodes);
                
                if freeRatio > bestFreeRatio
                    bestFreeRatio = freeRatio;
                    bestNodeIdx = idx;
                end
            end
            
            % 放置VNF
            newPlan.vnfNode(di, v) = pathNodes(bestNodeIdx);
            lastPlacedIdx = bestNodeIdx;
            
            % 模拟更新节点资源状态（仅更新第一时间片用于后续VNF选择参考）
            % 注意：这里只是临时更新用于本请求内部的贪心选择
            nid = pathNodes(bestNodeIdx);
            vnfType = req.vnf(v);
            nodes(nid).cpu(1) = nodes(nid).cpu(1) - vnfType;
            nodes(nid).mem(1) = nodes(nid).mem(1) - vnfType;
        end
    end
    
    % ====== 将该SFC的部署策略记录下来 ======
    if isempty(plan)
        plan(1) = newPlan;
    else
        plan(end+1) = newPlan;
    end

end

end

%% ==================== 辅助函数 ====================

function avgFree = calcPathNodeFreeRatio(pathNodes, nodes)
%CALCPATHNODEFREERADIO 计算路径上所有节点的平均资源空闲度
    totalFree = 0;
    validCount = 0;
    
    for i = 1:numel(pathNodes)
        nid = pathNodes(i);
        if nid > 0 && nid <= numel(nodes)
            freeRatio = calcNodeFreeRatio(nid, nodes);
            totalFree = totalFree + freeRatio;
            validCount = validCount + 1;
        end
    end
    
    if validCount > 0
        avgFree = totalFree / validCount;
    else
        avgFree = 0;
    end
end

function freeRatio = calcNodeFreeRatio(nid, nodes)
%CALCNODEFREERATIO 计算单个节点的资源空闲度
%   空闲度 = (CPU空闲比 + 内存空闲比) / 2
    
    if nid <= 0 || nid > numel(nodes)
        freeRatio = 0;
        return;
    end
    
    node = nodes(nid);
    
    % 使用第一时间片的资源状态
    cpuFree = node.cpu(1) / node.cpu_cap;
    memFree = node.mem(1) / node.mem_cap;
    
    % 综合空闲度（CPU和内存的平均）
    freeRatio = (cpuFree + memFree) / 2;
end


%[appendix]{"version":"1.0"}
%---
