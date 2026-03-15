%[text] # ResourceAndDelayAware
%[text] 资源与时延感知的多播SFC部署算法
%[text] 
%[text] ## 算法流程
%[text]    a. 获取K条最短路
%[text]    b. 调用rdaLinkAndNodeChoice选择最优链路和节点组合
%[text]    c. 生成该目的节点的部署方案
%[text] 
%[text] ## 输入参数
%[text] 
%[text] ## 输出参数
%[text]         格式与shortestPathFirstWithLoadBalancing完全一致
function plan = ResourceAndDelayAware(reqs, KPathsNew, links, nodes, plan, deployMethodCfg)

    % 请求数量
    numReqs = numel(reqs);
    
    % 加载配置信息
    candLinkNum = deployMethodCfg.candLinkNum;
    candNodeNum = deployMethodCfg.candNodeNum;
    
    %% 遍历每个多播SFC请求
    for req_idx = 1:numReqs
    req = reqs(req_idx);
        
        % 基本信息
    src = req.source;
    dests = req.dest(req.dest > 0);
        destNum = numel(dests);
        vnfNum = numel(req.vnf);
        linkNum = size(links, 2);

        %% 计算该请求的共享潜力（节点和链路的介数中心性）
    [nodeFreq, linkFreq] = calcSharePotental(req, KPathsNew, links, nodes);
        
        %% 初始化部署方案结构（与shortestPathFirstWithLoadBalancing完全一致）
        % placeLinks: dest_num × linkNum 矩阵，每行存储该目的节点的链路ID序列（0填充）
        % vnfNode: dest_num × vnfNum 矩阵，存储每个目的节点的VNF部署节点
    newPlan = struct( ...
            'req_id',       req.id, ...
            'placeLinks',   zeros(destNum, linkNum), ...
            'vnfNode',      zeros(destNum, vnfNum) ...
    );
    
        % 模拟网络状态（用于多目的节点之间的资源共享计算）
        simNodes = nodes;
        simLinks = links;
        
        % 初始时间为1（仿真的第一个时间片）
        t0 = 1;
        
        %% 针对每个目的节点进行部署规划
        for dest_idx = 1:destNum
        d = dests(dest_idx);
            t = t0;  % 每个目的节点从初始时间开始
            
            % 获取源节点到目的节点的K条最短路
        Pathinfo = KPathsNew{src, d};
        
            if isempty(Pathinfo)
                % 没有可用路径，使用默认值（全0）
                warning('请求%d: 源%d到目的%d没有可用路径', req.id, src, d);
                continue;
            end
            
            %% 调用链路和节点选择算法
            [bestDestPlan, simNodes, simLinks] = rdaLinkAndNodeChoice( ...
                Pathinfo, simNodes, simLinks, req, t, ...
                nodeFreq, linkFreq, ...
                src, d, req_idx, dest_idx, destNum, ...
                candLinkNum, candNodeNum, ...
                deployMethodCfg);
            
            %% 记录部署结果（关键：确保与shortestPathFirst格式完全一致）
            % 规则：pathLinks和vnfNodes必须来自同一条路径，确保一致性
            
            % 检查bestDestPlan的数据是否有效
            pathLinkIds = bestDestPlan.pathLinks;
            pathNodes = bestDestPlan.pathNodes;
            vnfNodesData = bestDestPlan.vnfNodes;
            
            % 验证pathLinks有效性
            pathLinksValid = false;
            if ~isempty(pathLinkIds)
                pathLinkIds = pathLinkIds(pathLinkIds > 0);
                pathLinkIds = pathLinkIds(:).';  % 确保是行向量
                pathLinksValid = ~isempty(pathLinkIds);
            end
            
            % 验证vnfNodes有效性（所有节点都非零）
            vnfNodesComplete = all(vnfNodesData > 0);
            
            % 验证pathNodes有效性
            pathNodesValid = ~isempty(pathNodes) && all(pathNodes > 0);
            
            if pathLinksValid && vnfNodesComplete
                % 方案完全有效，直接使用
                numPathLinks = numel(pathLinkIds);
                if numPathLinks > 0 && numPathLinks <= linkNum
                    newPlan.placeLinks(dest_idx, 1:numPathLinks) = pathLinkIds;
                end
                newPlan.vnfNode(dest_idx, :) = vnfNodesData;
                
            elseif pathLinksValid && pathNodesValid
                % pathLinks有效但vnfNodes不完整
                % 基于pathNodes重新计算vnfNodes（均匀分布）
                numPathLinks = numel(pathLinkIds);
                if numPathLinks > 0 && numPathLinks <= linkNum
                    newPlan.placeLinks(dest_idx, 1:numPathLinks) = pathLinkIds;
                end
                
                % 使用pathNodes计算均匀分布的vnfNodes
                hops = numel(pathLinkIds);
                validPathNodes = pathNodes(pathNodes > 0);
                recalcVnfNodes = zeros(1, vnfNum);
                for v = 1:vnfNum
                    idx = ceil(v * hops / vnfNum);
                    pos = 1 + idx;
                    if pos <= numel(validPathNodes)
                        recalcVnfNodes(v) = validPathNodes(pos);
                    else
                        recalcVnfNodes(v) = validPathNodes(end);
                    end
                end
                newPlan.vnfNode(dest_idx, :) = recalcVnfNodes;
                
            else
                % 都无效，使用fallback（第一条最短路）
                [fallbackLinks, fallbackVnfNodes] = getFallbackPlan(Pathinfo, vnfNum);
                
                numFallbackLinks = numel(fallbackLinks);
                if numFallbackLinks > 0 && numFallbackLinks <= linkNum
                    newPlan.placeLinks(dest_idx, 1:numFallbackLinks) = fallbackLinks;
                end
                newPlan.vnfNode(dest_idx, :) = fallbackVnfNodes;
            end
        end
        
        %% 将该SFC的部署策略记录下来
    if isempty(plan)
        plan(1) = newPlan;
    else
        plan(end+1) = newPlan;
    end
    end
end

%% ========== 辅助函数：备用部署方案（与shortestPathFirst逻辑完全相同） ==========
function [linkIds, vnfNodes] = getFallbackPlan(Pathinfo, vnfNum)
%GETFALLBACKPLAN 当主算法失败时，使用第一条最短路的均匀部署作为备用方案
    linkIds = [];
    vnfNodes = zeros(1, vnfNum);
    
    if isempty(Pathinfo)
        return;
    end
    
    % 取第一条最短路
    firstRoute = Pathinfo(1);
    hops = firstRoute.pathshops;
    
    if hops <= 0
        return;
    end
    
    % 获取链路序列
    linkIds = firstRoute.link_ids;
    linkIds = linkIds(linkIds > 0);
    linkIds = linkIds(:).';  % 确保是行向量
    
    % 获取节点序列
    pathNodes = firstRoute.paths;
    pathNodes = pathNodes(pathNodes > 0);
    
    % VNF均匀部署（与shortestPathFirst完全相同的逻辑）
    for v = 1:vnfNum
        idx = ceil(v * hops / vnfNum);  % idx ∈ [1, hops]
        pos = 1 + idx;                   % 映射到 pathNodes 的位置（跳过src）
        if pos <= numel(pathNodes)
            vnfNodes(v) = pathNodes(pos);
        else
            vnfNodes(v) = pathNodes(end);
        end
    end
end

%[appendix]{"version":"1.0"}
%---
