%[text] # calcNodeScore
%[text] 计算候选路径上各节点的综合评价得分
%[text] 
%[text] ## 算法思路
%[text] 对于给定的候选路径，评估路径上所有候选节点（除源节点外）部署当前VNF的综合得分。
%[text] 
%[text] ## 评价指标（五维综合评分）
%[text] 1. cpu_consume: 归一化CPU消耗率（越小越好）- 若VNF可共享则为0
%[text] 2. memory_consume: 归一化内存消耗率（越小越好）- 若VNF可共享则为0
%[text] 3. bandwidth_consume: 到达该节点的链路带宽消耗（越小越好）- 若链路已共享则为0
%[text] 4. delay_consume: 到达该节点的时延（越小越好）- 包含链路时延+排队等待+处理时延
%[text] 5. share_score: 共享潜力得分（越大越好），表示未来被其他目的节点共享的可能性
%[text] 
%[text] ## 共享机制说明
%[text] - VNF共享：同一请求的相同VNF实例可以共享，共享时CPU/内存消耗为0
%[text] - 链路共享：同一请求已使用的链路可以共享，共享时带宽消耗为0
%[text] - 共享潜力：基于介数中心性，表示该节点/链路被未来目的节点使用的可能性
%[text] 
%[text] ## 输入参数
%[text] - candpath: 候选路径结构体，包含paths、link_ids、pathshops
%[text] - linkFreq: 链路共享频率向量
%[text] - nodeFreq: 节点共享频率向量
%[text] - req: 请求结构体
%[text] - t0: 当前时间
%[text] - nodes: 节点状态数组
%[text] - links: 链路状态数组
%[text] - vnfIdx: 当前VNF索引（1,2,3）
%[text] - destIdx: 目的节点索引（用于计算共享权重衰减）
%[text] - deployMethodCfg: 部署配置参数
%[text] - prevPlaceInfo: 前序VNF部署信息（可选），结构体数组：
%[text]                  .placeNode - 已部署VNF的节点ID
%[text]                  .placeLinks - 已使用的链路ID数组
%[text]                  .leaveTime - 离开该节点的时间
%[text]
%[text] ## 输出参数
%[text] - nodeScoreStruct: 按综合得分降序排列的节点评分结构体数组

function nodeScoreStruct = calcNodeScore(...
    candpath, linkFreq, nodeFreq, ...
    req, t0, nodes, links, ...
    vnfIdx, destIdx, destNum, deployMethodCfg, prevPlaceInfo)

    % 获取配置权重
    shareWeight = deployMethodCfg.shareWeight;
    congWeight = deployMethodCfg.congWeight;
    delayWeight = deployMethodCfg.delayWeight;
    
    if isfield(deployMethodCfg, 'shareDecayMin')
        shareDecayMin = deployMethodCfg.shareDecayMin;
    else
        shareDecayMin = 0;
    end
    
    % 候选路径上的节点（排除源节点，因为源节点不能部署VNF）
    pathNodes = candpath.paths;
    pathLinks = candpath.link_ids;
    
    % 处理prevPlaceInfo参数
    if nargin < 12 || isempty(prevPlaceInfo)
        prevPlaceInfo = [];
    end
    
    % 确定候选节点范围
    % 如果是第一个VNF（vnfIdx=1），从第2个节点开始（排除源节点）
    % 如果是后续VNF，从上一个VNF的部署节点在路径中的位置开始
    if isempty(prevPlaceInfo)
        startNodeIdx = 2;  % 排除源节点
        currentTime = t0;
        usedLinkCount = 0;
    else
        lastPlaceNode = prevPlaceInfo(end).placeNode;
        startNodeIdx = find(pathNodes == lastPlaceNode, 1);
        if isempty(startNodeIdx)
            startNodeIdx = 2;
        end
        currentTime = prevPlaceInfo(end).leaveTime;
        usedLinkCount = sum([prevPlaceInfo.linkCount]);
    end
    
    % 候选节点列表（从startNodeIdx到末尾）
    candNodeIndices = startNodeIdx:numel(pathNodes);
    if isempty(candNodeIndices)
        nodeScoreStruct = [];
        return;
    end
    
    numCandNodes = numel(candNodeIndices);
    
    % 初始化评分结构体
    nodeScoreStruct = repmat(struct( ...
        'nodeId',         [], ...      % 节点ID
        'pathNodeIdx',    [], ...      % 在路径中的索引
        'linksToNode',    [], ...      % 到达该节点所需经过的链路
        'linkCount',      [], ...      % 到达该节点的链路数量
        'canShareVnf',    false, ...   % 是否可以共享VNF（不消耗CPU/内存）
        ... % 原始指标
        'cpuScore',       [], ...      % CPU消耗率（越小越好）
        'memScore',       [], ...      % 内存消耗率（越小越好）
        'bwScore',        [], ...      % 带宽消耗指标（越小越好）
        'delayScore',     [], ...      % 时延指标（越小越好）- 包含排队等待
        'shareScore',     [], ...      % 共享潜力（越大越好）
        ... % 时延详情（用于调试和分析）
        'arriveTime',     [], ...      % 到达节点的时间
        'actualStartTime',[], ...      % 实际开始处理的时间（考虑排队）
        'waitTime',       [], ...      % 排队等待时间
        'leaveTime',      [], ...      % 离开节点的时间
        ... % 归一化指标
        'cpuNorm',        [], ...
        'memNorm',        [], ...
        'bwNorm',         [], ...
        'delayNorm',      [], ...
        'shareNorm',      [], ...
        ... % 综合得分
        'totalScore',     [], ...
        'isValid',        true ...     % 是否为有效候选
    ), numCandNodes, 1);

    % VNF资源需求
    cpu_need = req.cpu;
    mem_need = req.memory;
    bw_need = req.bandwidth;
    vnfId = req.vnf(vnfIdx);
    
    % 共享潜力权重衰减因子：随已部署目的节点数量递减
    % 第1个目的节点时权重最高（共享潜力最重要）
    % 后续目的节点权重降低（因为能被共享的机会变少）
    shareDecayWeight = max(1 - (destIdx - 1) / max(destNum, 1), shareDecayMin);
    
    % 遍历每个候选节点计算评分
    for i = 1:numCandNodes
        nodeIdx = candNodeIndices(i);
        nodeId = pathNodes(nodeIdx);
        
        nodeScoreStruct(i).nodeId = nodeId;
        nodeScoreStruct(i).pathNodeIdx = nodeIdx;
        
        % 计算到达该节点需要经过的链路
        if nodeIdx <= 1
            linksToNode = [];
        else
            % 从上一个VNF位置到当前节点的链路
            linkStartIdx = usedLinkCount + 1;
            linkEndIdx = nodeIdx - 1;  % 链路数 = 节点索引 - 1
            if linkEndIdx >= linkStartIdx && linkEndIdx <= numel(pathLinks)
                linksToNode = pathLinks(linkStartIdx:linkEndIdx);
            else
                linksToNode = [];
            end
        end
        nodeScoreStruct(i).linksToNode = linksToNode;
        nodeScoreStruct(i).linkCount = numel(linksToNode);
        
        node = nodes(nodeId);
        
        % 将 currentTime 取整用于数组索引（时延累积可能导致浮点数）
        currentTimeIdx = max(1, round(currentTime));
        
        % ========== 检查VNF是否可共享 ==========
        % 共享检测：检查该节点是否已有相同请求的相同VNF实例
        canShareVnf = checkVnfShareable(node, req.id, vnfId, currentTime);
        nodeScoreStruct(i).canShareVnf = canShareVnf;
        
        % ========== 1. CPU消耗评分（越小越好） ==========
        if canShareVnf
            % VNF可共享：CPU消耗为0
            nodeScoreStruct(i).cpuScore = 0;
        else
            % 需要新部署：检查资源是否足够
            cpu_avail = node.cpu(currentTimeIdx);
            if cpu_avail < cpu_need
                % 资源不足，标记为无效
                nodeScoreStruct(i).isValid = false;
                nodeScoreStruct(i).cpuScore = inf;
            else
                % CPU消耗率 = 需求 / 可用
                nodeScoreStruct(i).cpuScore = cpu_need / cpu_avail;
            end
        end
        
        % ========== 2. 内存消耗评分（越小越好） ==========
        if canShareVnf
            % VNF可共享：内存消耗为0
            nodeScoreStruct(i).memScore = 0;
        else
            mem_avail = node.mem(currentTimeIdx);
            if mem_avail < mem_need
                nodeScoreStruct(i).isValid = false;
                nodeScoreStruct(i).memScore = inf;
            else
                nodeScoreStruct(i).memScore = mem_need / mem_avail;
            end
        end
        
        % ========== 3. 带宽消耗评分（越小越好） ==========
        if isempty(linksToNode)
            % 无需经过链路（当前节点就是上一个VNF所在节点）
            nodeScoreStruct(i).bwScore = 0;
        else
            bwScoreSum = 0;
            t_temp = currentTime;
            T_bw = size(links(1).bandwidth, 1);  % 仿真最大时间片
            
            for li = 1:numel(linksToNode)
                linkId = linksToNode(li);
                
                % 边界检查
                t_safe = min(max(round(t_temp), 1), T_bw);
                if t_temp > T_bw
                    nodeScoreStruct(i).isValid = false;
                    bwScoreSum = inf;
                    break;
                end
                
                bw_avail = links(linkId).bandwidth(t_safe);
                
                % 检查链路是否已被该请求使用（可共享）
                usedFlag = links(linkId).request(t_safe, req.id);
                
                if usedFlag == 1
                    % 链路已共享，带宽消耗为0
                    bwScoreSum = bwScoreSum + 0;
                elseif bw_avail < bw_need
                    % 带宽不足
                    nodeScoreStruct(i).isValid = false;
                    bwScoreSum = inf;
                    break;
                else
                    % 带宽消耗率
                    bwScoreSum = bwScoreSum + bw_need / bw_avail;
                end
                
                % 更新时间（用于下一条链路的检查）
                t_temp = t_temp + links(linkId).delay(t_safe);
            end
            nodeScoreStruct(i).bwScore = bwScoreSum / max(numel(linksToNode), 1);
        end
        
        % ========== 4. 时延评分（越小越好）+ 真实排队估计 ==========
        % 计算到达该节点的链路时延
        arriveTime = currentTime;
        T_max = size(links(1).delay, 1);  % 仿真最大时间片
        timeExceeded = false;
        
        for li = 1:numel(linksToNode)
            linkId = linksToNode(li);
            % 边界检查：确保 arriveTime 不超过数组范围
            t_safe = min(max(round(arriveTime), 1), T_max);
            if arriveTime > T_max
                timeExceeded = true;
                arriveTime = T_max;
                break;
            end
            arriveTime = arriveTime + links(linkId).delay(t_safe);
        end
        
        % 如果时间超出仿真范围，标记为无效
        if timeExceeded || arriveTime > T_max
            nodeScoreStruct(i).isValid = false;
            arriveTime = T_max;
        end
        
        linkDelay = arriveTime - currentTime;
        nodeScoreStruct(i).arriveTime = arriveTime;
        
        % 【关键改进】使用真实的排队时间估计
        if canShareVnf
            % 共享VNF：需要等待共享实例ready（调用真实的共享等待逻辑）
            ready_time = findSharedReadyTime(node, req.id, vnfId);
            if ~isempty(ready_time)
                % 必须等到共享实例部署完成
                actualStartTime = max(arriveTime, ready_time);
                waitTime = actualStartTime - arriveTime;
                leaveTime = actualStartTime;  % 共享时无需额外处理时间
                nodeDelay = 0;  % 共享不消耗处理时间
            else
                % 无可共享实例（理论上不应该发生，因为canShareVnf已判断）
                actualStartTime = arriveTime;
                waitTime = 0;
                leaveTime = arriveTime;
                nodeDelay = 0;
            end
        else
            % 非共享：需要真实的FIFO排队
            % 计算处理时长（到达时刻确定）
            t_safe = min(max(round(arriveTime), 1), size(node.delay, 1));
            proc_duration = node.delay(t_safe);
            
            % 【核心】使用 fifo_find_start_time 逻辑估计排队等待
            [actualStartTime, waitTime, ok] = estimateFifoStartTime(node, arriveTime, proc_duration);
            
            if ~ok
                % 找不到合适的处理窗口，标记为无效
                nodeScoreStruct(i).isValid = false;
                actualStartTime = inf;
                waitTime = inf;
                leaveTime = inf;
                nodeDelay = inf;
            else
                leaveTime = actualStartTime + proc_duration;
                nodeDelay = proc_duration;
            end
        end
        
        nodeScoreStruct(i).actualStartTime = actualStartTime;
        nodeScoreStruct(i).waitTime = waitTime;
        nodeScoreStruct(i).leaveTime = leaveTime;
        
        % 总时延 = 链路时延 + 排队等待 + 节点处理
        totalDelay = linkDelay + waitTime + nodeDelay;
        
        % 时延满足度：总时延 / 最大容忍时延
        % 【注意】delayScore 已经综合了排队等待时间，无需单独评估排队成本
        nodeScoreStruct(i).delayScore = totalDelay / max(req.max_delay, 1);
        
        % ========== 5. 共享潜力评分（越大越好） ==========
        % 共享潜力：表示该节点被未来其他目的节点共享的可能性
        % 基于介数中心性（在K条最短路中的出现频率）
        
        % 节点共享潜力
        nodeShare = nodeFreq(nodeId);
        
        % 链路共享潜力
        if isempty(linksToNode)
            linkShare = 0;
        else
            linkShare = mean(linkFreq(linksToNode));
        end
        
        % 综合共享潜力（用于评估未来共享收益）
        % 注意：这里不再给当前可共享VNF加分，因为共享优势已体现在资源消耗为0
        nodeScoreStruct(i).shareScore = nodeShare + linkShare;
    end
    
    % ==================== 归一化处理 ====================
    % 提取各指标向量
    cpuVec = [nodeScoreStruct.cpuScore].';
    memVec = [nodeScoreStruct.memScore].';
    bwVec = [nodeScoreStruct.bwScore].';
    delayVec = [nodeScoreStruct.delayScore].';
    shareVec = [nodeScoreStruct.shareScore].';
    
    % 有效性掩码
    validCpu = isfinite(cpuVec);
    validMem = isfinite(memVec);
    validBw = isfinite(bwVec);
    validDelay = isfinite(delayVec);
    validShare = isfinite(shareVec);
    
    % 归一化
    cpuNorm = nan(numCandNodes, 1);
    memNorm = nan(numCandNodes, 1);
    bwNorm = nan(numCandNodes, 1);
    delayNorm = nan(numCandNodes, 1);
    shareNorm = nan(numCandNodes, 1);
    
    cpuNorm(validCpu) = minmax01(cpuVec(validCpu));
    memNorm(validMem) = minmax01(memVec(validMem));
    bwNorm(validBw) = minmax01(bwVec(validBw));
    delayNorm(validDelay) = minmax01(delayVec(validDelay));
    shareNorm(validShare) = minmax01(shareVec(validShare));
    
    % 写回结构体并计算总分
    for i = 1:numCandNodes
        nodeScoreStruct(i).cpuNorm = cpuNorm(i);
        nodeScoreStruct(i).memNorm = memNorm(i);
        nodeScoreStruct(i).bwNorm = bwNorm(i);
        nodeScoreStruct(i).delayNorm = delayNorm(i);
        nodeScoreStruct(i).shareNorm = shareNorm(i);
        
        if nodeScoreStruct(i).isValid && ...
           isfinite(cpuNorm(i)) && isfinite(memNorm(i)) && ...
           isfinite(bwNorm(i)) && isfinite(delayNorm(i)) && ...
           isfinite(shareNorm(i))
            
            % 综合评分公式（五维）：
            % - 资源消耗（越小越好）：使用 (1 - norm) 转换为"越大越好"
            % - 时延满足度（越小越好）：使用 (1 - norm) 转换为"越大越好"
            %   注：delayScore 已包含链路时延 + 排队等待 + 处理时延
            % - 共享潜力（越大越好）：直接使用 norm
            nodeScoreStruct(i).totalScore = ...
                congWeight * (1 - cpuNorm(i)) + ...
                congWeight * (1 - memNorm(i)) + ...
                congWeight * (1 - bwNorm(i)) + ...
                delayWeight * (1 - delayNorm(i)) + ...
                shareWeight * shareDecayWeight * shareNorm(i);
        else
            nodeScoreStruct(i).totalScore = -inf;
        end
    end
    
    % ==================== 排序：totalScore 降序 ====================
    totalScores = [nodeScoreStruct.totalScore].';
    [~, order] = sort(totalScores, 'descend');
    nodeScoreStruct = nodeScoreStruct(order);
end

%% ========== 辅助函数 ==========

function canShare = checkVnfShareable(node, reqId, vnfId, t)
%CHECKVNFSHAREABLE 检查节点上是否有可共享的VNF实例
%
% 共享检测方式：
% 1. 优先检查node.tasks（实际部署记录）
% 2. 如果tasks为空，检查node.vnf（VNF标记矩阵）

    canShare = false;
    
    % 方式1：检查tasks（实际部署记录）
    if isfield(node, 'tasks') && ~isempty(node.tasks)
        % 检查是否有相同请求的相同VNF已经部署
        mask = ([node.tasks.req_id] == reqId) & ([node.tasks.vnf_id] == vnfId);
        if any(mask)
            canShare = true;
            return;
        end
    end
    
    % 方式2：检查vnf矩阵
    if ~isfield(node, 'vnf') || isempty(node.vnf)
        return;
    end
    
    T_node = size(node.vnf, 1);
    t = max(1, min(round(t), T_node));
    
    % 检查vnf矩阵的维度
    if ndims(node.vnf) < 2 || size(node.vnf, 2) < reqId
        return;
    end
    
    % 检查该请求在该节点是否已有相同VNF实例
    try
        if ndims(node.vnf) == 3
            vnfSlots = squeeze(node.vnf(t, reqId, :));
        else
            vnfSlots = node.vnf(t, reqId);
        end
        if any(vnfSlots == vnfId)
            canShare = true;
        end
    catch
        canShare = false;
    end
end

function y = minmax01(x)
%MINMAX01 Min-max归一化到[0,1]
    xmin = min(x);
    xmax = max(x);
    if abs(xmax - xmin) < 1e-12
        y = ones(size(x));
    else
        y = (x - xmin) ./ (xmax - xmin);
    end
end

function [startTime, waitTime, ok] = estimateFifoStartTime(node, arriveTime, proc_duration)
%ESTIMATEFIFOSTARTTIME  FIFO排队：估计任务的实际开始时间
%
% 【核心改进】真实的排队时间估计
% 从 arriveTime 开始往后扫，寻找最早的连续空闲窗口（长度=proc_duration）
% 空闲判定基于 work_status.req_id == 0
%
% 输出：
%   startTime : 找到的实际开始时间
%   waitTime  : startTime - arriveTime
%   ok        : 是否找到（找不到说明超出仿真时域）

    % 检查 work_status 是否存在
    if ~isfield(node, 'work_status') || ~isfield(node.work_status, 'req_id')
        % 如果没有 work_status，假设节点空闲
        startTime = arriveTime;
        waitTime = 0;
        ok = true;
        return;
    end
    
    T = numel(node.work_status.req_id);
    
    % 处理时长为0：等价于无需占用处理窗口（start=arrive）
    if proc_duration == 0
        startTime = arriveTime;
        waitTime = 0;
        ok = true;
        return;
    end
    
    % 确保 arriveTime 在有效范围内
    arriveTime = max(1, round(arriveTime));
    
    latestStart = T - proc_duration + 1;
    if arriveTime > latestStart
        ok = false;
        startTime = T;
        waitTime = 0;
        return;
    end
    
    busy = node.work_status.req_id;  % 0=空闲，非0=忙
    
    startTime = 0;
    ok = false;
    
    % 从 arriveTime 开始向后找长度足够的空闲段
    for t = arriveTime:latestStart
        if all(busy(t:t+proc_duration-1) == 0)
            startTime = t;
            ok = true;
            break;
        end
    end
    
    if ~ok
        startTime = T;
        waitTime = 0;
        return;
    end
    
    waitTime = startTime - arriveTime;
end

function ready_time = findSharedReadyTime(node, req_id, vnf_id)
%FINDSHAREDREADYTIME  查找"共享实例"在该节点的 ready 时间
%
% 共享语义：如果该节点上已经出现过 (req_id, vnf_id) 的任务，
%       则认为该VNF实例存在/正在部署，ready 时间取最早完成时刻 min(t_end)。
%
% 返回：
%   ready_time = []  表示不可共享
%   ready_time = k   表示该实例从时间 k 起 ready（到达早于k则需要等待）

    ready_time = [];
    
    if ~isfield(node, 'tasks') || isempty(node.tasks)
        return;
    end
    
    % tasks 是 struct array：字段包括 req_id, vnf_id, t_end
    mask = ([node.tasks.req_id] == req_id) & ([node.tasks.vnf_id] == vnf_id);
    if any(mask)
        ready_time = min([node.tasks(mask).t_end]);
    end
end

%[appendix]{"version":"1.0"}
%---
