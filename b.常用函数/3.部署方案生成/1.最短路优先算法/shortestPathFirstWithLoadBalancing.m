%[text] # shortestPathFirstWithLoadBalancing
%[text] 基于斯坦纳树(STB)思想的多播SFC部署方案生成
%[text] 
%[text] ## 算法特点
%[text] 
%[text] ## 输入参数说明

function plan = shortestPathFirstWithLoadBalancing(requests, KPathsNew, links, nodes, plan, deployMethodCfg)

% 遍历每个多播sfc请求
numReqs = numel(requests);
for req_idx = 1:numReqs
    req = requests(req_idx);
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
    
    % ====== 步骤1：收集所有目的节点的路径节点序列 ======
    allPaths = cell(dest_num, 1);
    allRoutes = cell(dest_num, 1);
    validDestMask = false(dest_num, 1);
    
    for di = 1:dest_num
        d = dests(di);
        routes = KPathsNew{src, d};
        
        if isempty(routes)
            warning('请求%d: 源%d到目的%d没有可用路径', req.id, src, d);
            continue;
        end
        
        firstRoute = routes(1);
        if firstRoute.pathshops <= 0
            warning('请求%d: 源%d到目的%d的路径跳数为0', req.id, src, d);
            continue;
        end
        
        allPaths{di} = firstRoute.paths;
        allRoutes{di} = firstRoute;
        validDestMask(di) = true;
    end
    
    % ====== 步骤2：计算公共前缀节点（分叉点之前的共享路径） ======
    commonPrefix = findCommonPrefix(allPaths);
    
    % ====== 步骤3：负载感知+资源感知的VNF部署 ======
    vnfPlacement = determineVnfPlacementWithResource(...
        commonPrefix, vnf_num, allPaths, validDestMask, nodes, req);
    
    % ====== 步骤4：记录链路并复用VNF部署位置 ======
    for di = 1:dest_num
        if ~validDestMask(di)
            continue;
        end
        
        firstRoute = allRoutes{di};
        linkIds = firstRoute.link_ids;
        actualHops = numel(linkIds);
        
        % 记录链路（保持原有逻辑不变）
        newPlan.placeLinks(di, 1:actualHops) = linkIds;
        
        % 所有目的节点复用相同的VNF部署位置
        newPlan.vnfNode(di, :) = vnfPlacement;
    end
    
    % ====== 将该SFC的部署策略记录下来 ======
    if isempty(plan)
        plan(1) = newPlan;
    else
        plan(end+1) = newPlan;
    end

end

end

%% ========== 辅助函数 ==========

function commonPrefix = findCommonPrefix(allPaths)
%FINDCOMMONPREFIX 找到所有路径的公共前缀节点序列

    % 过滤空路径
    validPaths = allPaths(~cellfun('isempty', allPaths));
    
    if isempty(validPaths)
        commonPrefix = [];
        return;
    end
    
    % 只有一条有效路径时，整条路径都是"公共前缀"
    if numel(validPaths) == 1
        commonPrefix = validPaths{1};
        return;
    end
    
    % 以第一条路径为基准，逐个节点比较
    commonPrefix = validPaths{1};
    
    for i = 2:numel(validPaths)
        path = validPaths{i};
        minLen = min(numel(commonPrefix), numel(path));
        matchLen = 0;
        
        for j = 1:minLen
            if commonPrefix(j) == path(j)
                matchLen = j;
            else
                break;
            end
        end
        
        commonPrefix = commonPrefix(1:matchLen);
        
        % 如果公共前缀只剩源节点，无需继续比较
        if numel(commonPrefix) <= 1
            break;
        end
    end
end

function vnfPlacement = determineVnfPlacementWithResource(...
    commonPrefix, vnf_num, allPaths, validDestMask, nodes, req)
%DETERMINEVNFPLACEMENTWITHRESOURCE 负载感知+资源感知的VNF部署位置确定
%
% 节点选择策略（适用于公共前缀和延伸路径所有场景）：
%   优先选择"资源占用量/资源剩余量"比值小的节点（资源利用率低的优先）
%
% 部署流程：
%   1. 尝试集中部署：找资源充足（>=120%需求）且占用率最低的单节点
%   2. 集中失败则分散部署：按占用率排序后贪心分配到多节点
%   3. 公共前缀不够则延伸：在路径延伸节点上继续部署（同样策略）
%   4. 所有目的节点复用相同的VNF部署位置

    vnfPlacement = zeros(1, vnf_num);
    commonLen = numel(commonPrefix);
    
    % 资源余量阈值：只有资源达到需求的150%才集中部署
    RESOURCE_MARGIN = 1.2;
    
    % 获取第一条有效路径作为备用
    validPaths = allPaths(validDestMask);
    if isempty(validPaths)
        return;
    end
    firstValidPath = validPaths{1};
    
    % VNF资源需求
    cpu_need = req.cpu;
    mem_need = req.memory;
    t0 = 1;  % 部署方案生成阶段使用初始时刻的资源状态
    
    % 公共前缀中可用于部署的节点（排除源节点）
    if commonLen > 1
        candNodes = commonPrefix(2:end);
    else
        candNodes = [];
    end
    
    % ====== 尝试集中部署：找占用率最低且资源充足的单节点部署所有VNF ======
    if ~isempty(candNodes)
        bestNode = findBestNodeByUtilization(candNodes, nodes, cpu_need, mem_need, vnf_num, t0, RESOURCE_MARGIN);
        
        if bestNode > 0
            % 找到了资源充足的节点，全部集中部署
            vnfPlacement(:) = bestNode;
            return;
        end
    end
    
    % ====== 集中部署失败，按占用率排序后贪心分配（占用率低的优先） ======
    if ~isempty(candNodes)
        sortedCandNodes = sortNodesByUtilization(candNodes, nodes, t0);
    else
        sortedCandNodes = [];
    end
    
    vnfDeployed = 0;
    
    % 在排序后的公共前缀节点上依次部署（占用率低的优先）
    for ni = 1:numel(sortedCandNodes)
        if vnfDeployed >= vnf_num
            break;
        end
        
        nodeId = sortedCandNodes(ni);
        node = nodes(nodeId);
        
        cpu_avail = node.cpu(t0);
        mem_avail = node.mem(t0);
        
        % 计算该节点还能部署几个VNF
        maxVnfOnNode = floor(min(cpu_avail / cpu_need, mem_avail / mem_need));
        vnfToDeployHere = min(maxVnfOnNode, vnf_num - vnfDeployed);
        
        for k = 1:vnfToDeployHere
            vnfDeployed = vnfDeployed + 1;
            vnfPlacement(vnfDeployed) = nodeId;
        end
    end
    
    % ====== 公共前缀不够，在延伸路径部署（同样采用占用率优先策略） ======
    remainingVnf = vnf_num - vnfDeployed;
    if remainingVnf > 0 && numel(firstValidPath) > commonLen
        extendedNodes = firstValidPath(commonLen+1:end);
        sortedExtNodes = sortNodesByUtilization(extendedNodes, nodes, t0);
        
        for ni = 1:numel(sortedExtNodes)
            if vnfDeployed >= vnf_num
                break;
            end
            
            nodeId = sortedExtNodes(ni);
            node = nodes(nodeId);
            
            cpu_avail = node.cpu(t0);
            mem_avail = node.mem(t0);
            
            maxVnfOnNode = floor(min(cpu_avail / cpu_need, mem_avail / mem_need));
            vnfToDeployHere = min(maxVnfOnNode, vnf_num - vnfDeployed);
            
            for k = 1:vnfToDeployHere
                vnfDeployed = vnfDeployed + 1;
                vnfPlacement(vnfDeployed) = nodeId;
            end
        end
    end
    
    % ====== 仍有剩余VNF未部署，使用最后一个可用节点 ======
    if vnfDeployed < vnf_num
        if ~isempty(sortedCandNodes)
            fallbackNode = sortedCandNodes(1);
        elseif ~isempty(firstValidPath) && numel(firstValidPath) > 1
            fallbackNode = firstValidPath(2);
        else
            fallbackNode = firstValidPath(end);
        end
        
        for v = (vnfDeployed+1):vnf_num
            vnfPlacement(v) = fallbackNode;
        end
    end
end

function bestNode = findBestNodeByUtilization(candNodes, nodes, cpu_need, mem_need, vnf_num, t0, resourceMargin)
%FINDBESTNODEBYUTILIZATION 找到占用率最低且资源充足的单节点
%
% 策略：
%   1. 首先筛选资源充足的节点
%   2. 在资源充足的节点中，选择"占用量/剩余量"比值最小的（资源利用率最低）
%
% 占用率计算：(总资源 - 剩余资源) / 剩余资源
%   比值越小，说明资源占用越少，剩余越充足
%
% 输入：
%   resourceMargin - 资源余量阈值（如1.2表示需要120%的资源）

    bestNode = 0;
    bestUtilization = inf;  % 占用率越小越好
    
    % 考虑资源余量的总需求
    totalCpuNeed = cpu_need * vnf_num * resourceMargin;
    totalMemNeed = mem_need * vnf_num * resourceMargin;
    
    for i = 1:numel(candNodes)
        nodeId = candNodes(i);
        node = nodes(nodeId);
        
        cpu_avail = node.cpu(t0);
        mem_avail = node.mem(t0);
        
        % 只有资源达到需求的resourceMargin倍时才考虑集中部署
        if cpu_avail >= totalCpuNeed && mem_avail >= totalMemNeed
            % 计算占用率：(总资源 - 剩余资源) / 剩余资源
            utilization = calcNodeUtilization(node, t0);
            
            % 选择占用率最小的节点
            if utilization < bestUtilization
                bestUtilization = utilization;
                bestNode = nodeId;
            end
        end
    end
end

function sortedNodes = sortNodesByUtilization(candNodes, nodes, t0)
%SORTNODESBYUTILIZATION 按资源占用率升序排序节点
%
% 排序策略：
%   优先选择"占用量/剩余量"比值小的节点（资源利用率低的优先）

    numNodes = numel(candNodes);
    utilizations = zeros(numNodes, 1);
    
    for i = 1:numNodes
        nodeId = candNodes(i);
        node = nodes(nodeId);
        
        % 计算占用率
        utilizations(i) = calcNodeUtilization(node, t0);
    end
    
    % 按占用率升序排序（占用率小的优先）
    [~, order] = sort(utilizations, 'ascend');
    sortedNodes = candNodes(order);
end

function utilization = calcNodeUtilization(node, t0)
%CALCNODEUTILIZATION 计算节点的资源占用率
%
% 占用率 = (总资源 - 剩余资源) / 剩余资源
% 综合CPU和内存的占用率

    cpu_cap = node.cpu_cap;
    mem_cap = node.mem_cap;
    cpu_avail = node.cpu(t0);
    mem_avail = node.mem(t0);
    
    % 防止除零
    if cpu_avail <= 0
        cpu_util = inf;
    else
        cpu_util = (cpu_cap - cpu_avail) / cpu_avail;
    end
    
    if mem_avail <= 0
        mem_util = inf;
    else
        mem_util = (mem_cap - mem_avail) / mem_avail;
    end
    
    % 综合占用率（取两者平均或最大值）
    utilization = (cpu_util + mem_util) / 2;
end


%[appendix]{"version":"1.0"}
%---
