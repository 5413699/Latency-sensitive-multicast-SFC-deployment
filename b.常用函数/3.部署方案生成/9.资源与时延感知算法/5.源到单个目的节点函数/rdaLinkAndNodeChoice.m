%[text] # rdaLinkAndNodeChoice
%[text] 资源与时延感知的链路与节点选择算法
%[text] 
%[text] ## 算法思路
%[text] 在确定源节点和目的节点的情况下，选择合适的部署链路和VNF部署节点。
%[text] 
%[text] ### 降低复杂度的策略
%[text] 原始方案：candLinkNum × candNodeNum^vnfNum 种组合（指数级）
%[text] 优化方案：采用**贪心+模拟部署**策略
%[text] 
%[text] ### 详细流程
%[text] a. 依次为每个VNF选择最优节点（贪心策略）
%[text] b. 模拟部署，记录资源消耗和时延
%[text] c. 生成该路径的完整部署方案
%[text] 
%[text] ## 输入参数
%[text] Pathinfo: K条最短路信息
%[text] nodes, links: 当前网络状态
%[text] req: 请求信息
%[text] t: 当前时间
%[text] nodeFreq, linkFreq: 共享潜力
%[text] src, d: 源节点和目的节点
%[text] req\_idx, dest\_idx: 请求和目的节点索引
%[text] candLinkNum, candNodeNum: 候选数量配置
%[text] deployMethodCfg: 部署方法配置
%[text] 
%[text] ## 输出参数
%[text] 

function [bestPlan, simNodes, simLinks] = rdaLinkAndNodeChoice( ...
    Pathinfo, nodes, links, req, t, ...
    nodeFreq, linkFreq, ...
    src, d, req_idx, dest_idx, destNum, ...
    candLinkNum, candNodeNum, ...
    deployMethodCfg)

    vnfNum = numel(req.vnf);
    
    % ===================== 步骤1: 计算路径评分并排序 =====================
    pathScoreStruct = calcPathScore(Pathinfo, linkFreq, links, req, t, deployMethodCfg);
    
    % 取前candLinkNum条有效路径作为候选
    validPaths = find([pathScoreStruct.totalScore] > -inf);
    numCandPaths = min(candLinkNum, numel(validPaths));
    
    if numCandPaths == 0
        % 没有有效路径
        bestPlan = createEmptyPlan(req_idx, dest_idx, d, vnfNum);
        bestPlan.success = false;
        bestPlan.failReason = 'no_valid_path';
        simNodes = nodes;
        simLinks = links;
        return;
    end
    
    % ===================== 步骤2: 为每条候选路径生成部署方案 =====================
    candPlans = repmat(createEmptyPlan(req_idx, dest_idx, d, vnfNum), numCandPaths, 1);
    
    for pathIdx = 1:numCandPaths
        k = pathScoreStruct(pathIdx).k;
        candpath = Pathinfo(k);
        
        % 为该路径生成部署方案（贪心策略）
        candPlans(pathIdx) = generatePlanForPath( ...
            candpath, nodes, links, req, t, ...
            nodeFreq, linkFreq, ...
            req_idx, dest_idx, destNum, vnfNum, ...
            candNodeNum, deployMethodCfg);
        
        candPlans(pathIdx).pathIdx = k;
        candPlans(pathIdx).pathScore = pathScoreStruct(pathIdx);
    end
    
    % ===================== 步骤3: 评估所有方案，选择最优 =====================
    [bestPlan, bestIdx] = planEvaluate(candPlans, deployMethodCfg);
    
    % 如果最优方案成功，模拟部署以获取更新后的网络状态
    if bestPlan.success
        [simNodes, simLinks] = simulateDeploy(nodes, links, bestPlan, req, t);
    else
        simNodes = nodes;
        simLinks = links;
    end
end

%% ========== 为单条路径生成部署方案（贪心策略） ==========
function plan = generatePlanForPath( ...
    candpath, nodes, links, req, t0, ...
    nodeFreq, linkFreq, ...
    req_idx, dest_idx, destNum, vnfNum, ...
    candNodeNum, deployMethodCfg)

    plan = createEmptyPlan(req_idx, dest_idx, candpath.paths(end), vnfNum);
    plan.pathNodes = candpath.paths;
    plan.pathLinks = candpath.link_ids;
    
    % 模拟部署状态（不改变真实节点和链路）
    simNodes = nodes;
    simLinks = links;
    
    currentTime = t0;
    prevPlaceInfo = [];
    totalCpuConsume = 0;
    totalMemConsume = 0;
    totalBwConsume = 0;
    totalDelayConsume = 0;
    totalShareGain = 0;
    usedLinkSet = [];
    
    for vnfIdx = 1:vnfNum
        % 计算当前VNF的候选节点评分
        nodeScoreStruct = calcNodeScore( ...
            candpath, linkFreq, nodeFreq, ...
            req, currentTime, simNodes, simLinks, ...
            vnfIdx, dest_idx, destNum, deployMethodCfg, prevPlaceInfo);
        
        if isempty(nodeScoreStruct)
            plan.success = false;
            plan.failReason = sprintf('no_candidate_node_vnf%d', vnfIdx);
            return;
        end
        
        % 贪心选择：尝试前candNodeNum个候选节点
        vnfDeployed = false;
        
        for candIdx = 1:min(candNodeNum, numel(nodeScoreStruct))
            candNode = nodeScoreStruct(candIdx);
            
            if ~candNode.isValid || candNode.totalScore <= -inf
                continue;
            end
            
            % 模拟部署该VNF
            [success, deployResult, simNodes, simLinks] = simulateDeployVnf( ...
                simNodes, simLinks, req, ...
                candNode.nodeId, candNode.linksToNode, currentTime, ...
                vnfIdx, dest_idx);
            
            if success
                % 记录部署信息
                plan.vnfNodes(vnfIdx) = candNode.nodeId;
                plan.vnfLinks{vnfIdx} = candNode.linksToNode;
                plan.vnfScores{vnfIdx} = candNode;           % 使用花括号存储struct
                plan.vnfDeployResult{vnfIdx} = deployResult; % 使用花括号存储struct
                
                % 累计资源消耗
                totalCpuConsume = totalCpuConsume + deployResult.cpu_consume;
                totalMemConsume = totalMemConsume + deployResult.memory_consume;
                totalBwConsume = totalBwConsume + deployResult.bandwidth_consume;
                totalDelayConsume = totalDelayConsume + deployResult.delay_consume;
                
                % 计算共享收益：共享时节省的资源量（不共享则需要消耗cpu_need+mem_need）
                if deployResult.isShared
                    % 共享时实际消耗为0，共享收益=如果不共享需要消耗的资源
                    totalShareGain = totalShareGain + req.cpu + req.memory;
                end
                
                % 更新链路集合
                usedLinkSet = unique([usedLinkSet, candNode.linksToNode]);
                
                % 更新前序部署信息
                prevInfo = struct( ...
                    'placeNode', candNode.nodeId, ...
                    'placeLinks', candNode.linksToNode, ...
                    'linkCount', candNode.linkCount, ...
                    'leaveTime', deployResult.leaveTime);
                
                if isempty(prevPlaceInfo)
                    prevPlaceInfo = prevInfo;
                else
                    prevPlaceInfo(end+1) = prevInfo;
                end
                
                currentTime = deployResult.leaveTime;
                vnfDeployed = true;
                break;
            end
        end
        
        if ~vnfDeployed
            plan.success = false;
            plan.failReason = sprintf('deploy_failed_vnf%d', vnfIdx);
            return;
        end
    end
    
    % ========== 处理最后一段链路（从最后一个VNF到目的节点）==========
    lastVnfNode = plan.vnfNodes(vnfNum);
    destNode = candpath.paths(end);
    
    if lastVnfNode ~= destNode
        % 找到最后一个VNF在路径中的位置
        lastVnfIdx = find(candpath.paths == lastVnfNode, 1);
        destIdx_inPath = find(candpath.paths == destNode, 1);
        
        if ~isempty(lastVnfIdx) && ~isempty(destIdx_inPath) && destIdx_inPath > lastVnfIdx
            finalLinks = candpath.link_ids(lastVnfIdx:destIdx_inPath-1);
            plan.finalLinks = finalLinks;
            
            % 计算最后一段链路的时延和带宽消耗
            for li = 1:numel(finalLinks)
                linkId = finalLinks(li);
                % 检查带宽是否足够
                bw_avail = simLinks(linkId).bandwidth(currentTime);
                usedFlag = simLinks(linkId).request(currentTime, req.id);
                
                if usedFlag ~= 1 && bw_avail < req.bandwidth
                    plan.success = false;
                    plan.failReason = 'final_link_bw_insufficient';
                    return;
                end
                
                % 累计消耗
                if usedFlag ~= 1
                    totalBwConsume = totalBwConsume + req.bandwidth;
                end
                linkDelay = simLinks(linkId).delay(currentTime);
                totalDelayConsume = totalDelayConsume + linkDelay;
                currentTime = currentTime + linkDelay;
            end
            usedLinkSet = unique([usedLinkSet, finalLinks]);
        end
    end
    
    % ========== 汇总方案评估指标 ==========
    plan.success = true;
    plan.usedLinks = usedLinkSet;
    plan.e2eDelay = currentTime - t0;
    plan.arriveTime = currentTime;
    
    plan.totalCpuConsume = totalCpuConsume;
    plan.totalMemConsume = totalMemConsume;
    plan.totalBwConsume = totalBwConsume;
    plan.totalDelayConsume = totalDelayConsume;
    plan.totalShareGain = totalShareGain;
    
    % 计算综合成本
    plan.totalCost = totalCpuConsume + totalMemConsume + totalBwConsume;
    
    % 检查端到端时延是否满足要求
    if plan.e2eDelay > req.max_delay
        plan.success = false;
        plan.failReason = 'e2e_delay_exceeded';
    end
end

%% ========== 模拟部署单个VNF（不改变真实状态） ==========
function [success, deployResult, simNodes, simLinks] = simulateDeployVnf( ...
    simNodes, simLinks, req, ...
    placeNodeId, placeLinks, t, vnfIdx, destIdx)

    success = false;
    deployResult = struct( ...
        'cpu_consume', 0, ...
        'memory_consume', 0, ...
        'bandwidth_consume', 0, ...
        'delay_consume', 0, ...
        'leaveTime', t, ...
        'isShared', false);
    
    vnfId = req.vnf(vnfIdx);
    cpu_need = req.cpu;
    mem_need = req.memory;
    bw_need = req.bandwidth;
    
    currentTime = t;
    
    % ========== 1. 模拟链路资源消耗 ==========
    for li = 1:numel(placeLinks)
        linkId = placeLinks(li);
        
        % 检查是否已被该请求使用
        usedFlag = simLinks(linkId).request(currentTime, req.id);
        
        if usedFlag ~= 1
            % 未共享，需要检查带宽
            bw_avail = simLinks(linkId).bandwidth(currentTime);
            if bw_avail < bw_need
                return;  % 带宽不足
            end
            deployResult.bandwidth_consume = deployResult.bandwidth_consume + bw_need;
        end
        
        % 累计链路时延
        linkDelay = simLinks(linkId).delay(currentTime);
        deployResult.delay_consume = deployResult.delay_consume + linkDelay;
        currentTime = currentTime + linkDelay;
    end
    
    % ========== 2. 模拟节点资源消耗 ==========
    node = simNodes(placeNodeId);
    T_node = size(node.cpu, 1);
    
    if currentTime > T_node
        return;  % 时间越界
    end
    
    % 检查VNF共享
    canShareVnf = checkVnfShareable(node, req.id, vnfId, currentTime);
    
    if canShareVnf
        % 共享VNF：不消耗新资源
        deployResult.isShared = true;
        % 等待共享实例就绪的时延（简化处理）
        nodeDelay = 0;
        deployResult.leaveTime = currentTime;
    else
        % 新部署：检查资源
        cpu_avail = node.cpu(currentTime);
        mem_avail = node.mem(currentTime);
        
        if cpu_avail < cpu_need || mem_avail < mem_need
            return;  % 资源不足
        end
        
        deployResult.cpu_consume = cpu_need;
        deployResult.memory_consume = mem_need;
        
        % 节点处理时延
        nodeDelay = node.delay(currentTime);
        deployResult.delay_consume = deployResult.delay_consume + nodeDelay;
        deployResult.leaveTime = currentTime + nodeDelay;
    end
    
    % 检查是否超时
    if deployResult.leaveTime > req.vnf_deadline(destIdx, vnfIdx)
        return;
    end
    
    success = true;
end

%% ========== 检查VNF是否可共享 ==========
function canShare = checkVnfShareable(node, reqId, vnfId, t)
    canShare = false;
    
    if ~isfield(node, 'vnf') || isempty(node.vnf)
        return;
    end
    
    T_node = size(node.vnf, 1);
    if t > T_node || t < 1
        return;
    end
    
    t = round(t);
    if t > size(node.vnf, 2)
        return;
    end
    
    try
        vnfSlots = squeeze(node.vnf(t, reqId, :));
        if any(vnfSlots == vnfId)
            canShare = true;
        end
    catch
        canShare = false;
    end
end

%% ========== 模拟完整部署（用于获取更新后的网络状态） ==========
function [simNodes, simLinks] = simulateDeploy(nodes, links, plan, req, t)
    simNodes = nodes;
    simLinks = links;
    
    if ~plan.success
        return;
    end
    
    currentTime = t;
    vnfNum = numel(plan.vnfNodes);
    
    for vnfIdx = 1:vnfNum
        nodeId = plan.vnfNodes(vnfIdx);
        vnfLinks = plan.vnfLinks{vnfIdx};
        
        % 更新链路状态（模拟）
        for li = 1:numel(vnfLinks)
            linkId = vnfLinks(li);
            usedFlag = simLinks(linkId).request(currentTime, req.id);
            
            if usedFlag ~= 1
                % 扣减带宽
                T_link = size(simLinks(linkId).bandwidth, 1);
                for tau = currentTime:T_link
                    simLinks(linkId).bandwidth(tau) = ...
                        simLinks(linkId).bandwidth(tau) - req.bandwidth;
                end
                % 标记使用
                simLinks(linkId).request(currentTime:T_link, req.id) = 1;
            end
            
            currentTime = currentTime + simLinks(linkId).delay(currentTime);
        end
        
        % 更新节点状态（模拟）
        T_node = size(simNodes(nodeId).cpu, 1);
        for tau = currentTime:T_node
            simNodes(nodeId).cpu(tau) = simNodes(nodeId).cpu(tau) - req.cpu;
            simNodes(nodeId).mem(tau) = simNodes(nodeId).mem(tau) - req.memory;
        end
        
        % 标记VNF可共享
        vnfId = req.vnf(vnfIdx);
        nodeDelay = simNodes(nodeId).delay(currentTime);
        leaveTime = currentTime + nodeDelay;
        
        if leaveTime <= T_node
            vnfSlots = squeeze(simNodes(nodeId).vnf(leaveTime, req.id, :));
            slot = find(vnfSlots == 0, 1);
            if ~isempty(slot)
                simNodes(nodeId).vnf(leaveTime:T_node, req.id, slot) = vnfId;
            end
        end
        
        currentTime = leaveTime;
    end
    
    % 处理最后一段链路
    if isfield(plan, 'finalLinks') && ~isempty(plan.finalLinks)
        for li = 1:numel(plan.finalLinks)
            linkId = plan.finalLinks(li);
            usedFlag = simLinks(linkId).request(currentTime, req.id);
            
            if usedFlag ~= 1
                T_link = size(simLinks(linkId).bandwidth, 1);
                for tau = currentTime:T_link
                    simLinks(linkId).bandwidth(tau) = ...
                        simLinks(linkId).bandwidth(tau) - req.bandwidth;
                end
                simLinks(linkId).request(currentTime:T_link, req.id) = 1;
            end
            
            currentTime = currentTime + simLinks(linkId).delay(currentTime);
        end
    end
end

%% ========== 创建空部署方案结构体 ==========
function plan = createEmptyPlan(req_idx, dest_idx, destNode, vnfNum)
    plan = struct( ...
        'req_idx',          req_idx, ...
        'dest_idx',         dest_idx, ...
        'destNode',         destNode, ...
        'pathIdx',          0, ...
        'pathScore',        [], ...
        'pathNodes',        [], ...
        'pathLinks',        [], ...
        'vnfNodes',         zeros(1, vnfNum), ...
        'vnfLinks',         {cell(1, vnfNum)}, ...
        'vnfScores',        {cell(1, vnfNum)}, ...       % 使用cell存储struct
        'vnfDeployResult',  {cell(1, vnfNum)}, ...       % 使用cell存储struct
        'finalLinks',       [], ...
        'usedLinks',        [], ...
        'success',          false, ...
        'failReason',       '', ...
        'e2eDelay',         inf, ...
        'arriveTime',       inf, ...
        'totalCpuConsume',  0, ...
        'totalMemConsume',  0, ...
        'totalBwConsume',   0, ...
        'totalDelayConsume', 0, ...
        'totalShareGain',   0, ...
        'totalCost',        inf ...
    );
end

%[appendix]{"version":"1.0"}
%---
