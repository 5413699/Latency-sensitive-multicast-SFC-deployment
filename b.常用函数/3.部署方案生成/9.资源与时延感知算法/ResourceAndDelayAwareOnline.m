%[text] # ResourceAndDelayAwareOnline
%[text] 资源与时延感知的多播SFC部署算法（在线评估版本）
%[text] 
%[text] ## 核心改进
%[text] 与原版ResourceAndDelayAware不同，本函数实现"真正的在线评估"：
%[text] 1. 每处理一个请求时，使用当前已被之前请求更新过的nodes/links状态
%[text] 2. 生成多个候选方案并排序
%[text] 3. 依次尝试部署候选方案
%[text] 4. 成功则提交更新，失败则尝试下一个方案或回滚
%[text] 
%[text] ## 输入参数
%[text] - reqs: 请求数组
%[text] - KPathsNew: K条最短路信息
%[text] - links: 链路状态（会被更新）
%[text] - nodes: 节点状态（会被更新）
%[text] - plan: 初始部署方案数组（通常为空）
%[text] - consume: 消耗记录结构体数组
%[text] - fail_log: 失败日志
%[text] - deployMethodCfg: 部署配置
%[text]
%[text] ## 输出参数
%[text] - plan: 更新后的部署方案数组
%[text] - nodes: 更新后的节点状态
%[text] - links: 更新后的链路状态
%[text] - consume: 更新后的消耗记录
%[text] - fail_log: 更新后的失败日志
%[text] - deployStats: 部署统计信息

function [plan, nodes, links, consume, fail_log, deployStats] = ...
    ResourceAndDelayAwareOnline(reqs, KPathsNew, links, nodes, plan, consume, fail_log, deployMethodCfg)

    % ===================== 初始化 =====================
    numReqs = numel(reqs);
    
    % 加载配置信息
    candLinkNum = deployMethodCfg.candLinkNum;
    candNodeNum = deployMethodCfg.candNodeNum;
    
    % 初始化部署统计
    deployStats = struct( ...
        'total_requests',       numReqs, ...
        'accepted_requests',    0, ...
        'rejected_requests',    0, ...
        'first_try_success',    0, ...  % 第一个候选方案就成功的数量
        'fallback_success',     0, ...  % 使用备选方案成功的数量
        'all_cand_failed',      0 ...   % 所有候选方案都失败的数量
    );
    
    fprintf('======== 开始在线评估部署 ========\n');
    fprintf('总请求数: %d\n', numReqs);
    
    %% ===================== 遍历每个多播SFC请求 =====================
    for req_idx = 1:numReqs
        req = reqs(req_idx);
        req_id = req.id;
        
        fprintf('\n--- 处理请求 %d/%d (req_id=%d) ---\n', req_idx, numReqs, req_id);
        
        % 基本信息
        src = req.source;
        dests = req.dest(req.dest > 0);
        destNum = numel(dests);
        vnfNum = numel(req.vnf);
        linkNum = size(links, 2);
        
        %% ========== 1. 计算该请求的共享潜力 ==========
        % 使用当前的nodes/links状态计算共享潜力
        [nodeFreq, linkFreq] = calcSharePotental(req, KPathsNew, links, nodes);
        
        %% ========== 2. 生成多个候选部署方案 ==========
        candPlans = generateCandidatePlans(req, req_idx, KPathsNew, nodes, links, ...
                                           nodeFreq, linkFreq, candLinkNum, candNodeNum, ...
                                           destNum, vnfNum, linkNum, deployMethodCfg);
        
        numCandPlans = numel(candPlans);
        fprintf('  生成了 %d 个候选方案\n', numCandPlans);
        
        if numCandPlans == 0
            % 没有候选方案，使用fallback
            fprintf('  警告: 没有有效的候选方案，使用fallback\n');
            candPlans = generateFallbackPlan(req, KPathsNew, destNum, vnfNum, linkNum);
            numCandPlans = numel(candPlans);
        end
        
        %% ========== 3. 评估并排序候选方案（在线动态评估：基于当前网络状态）==========
        t0 = 1;  % 部署起始时间
        [~, ~, ~, rankOrder] = planEvaluate(candPlans, deployMethodCfg, nodes, links, req, t0);
        
        %% ========== 4. 依次尝试部署候选方案（先修复再部署） ==========
        % 【关键改进】使用已验证的 generateDeployPlan + deploy_requests 逻辑
        deployed = false;
        deployedPlanIdx = 0;
        fixedCandPlan = [];  % 保存成功部署的修复后方案
        
        % 【重要】记录循环前 fail_log 的长度，用于控制只保留第一次失败日志
        fail_log_len_before = numel(fail_log);
        first_fail_recorded = false;  % 标记是否已记录第一次失败
        
        for tryIdx = 1:numCandPlans
            candIdx = rankOrder(tryIdx);
            candPlan = candPlans(candIdx);
            
            fprintf('  尝试候选方案 %d (排名第%d)... ', candIdx, tryIdx);
            
            % 【步骤1】先修复多播树
            try
                fixedPlanArr = FixedTreePlan(req, candPlan, links);
                fixedPlanRaw = fixedPlanArr(1);  % 取修复后的方案
            catch ME
                fprintf('修复失败: %s\n', ME.message);
                continue;
            end
            
            % 【步骤2】使用 generateDeployPlan 转换为 sortedPlan 格式
            % 这是已验证的图论方法，确保链路分配正确
            try
                sortedPlanSingle = generateDeployPlan(req, fixedPlanRaw, links);
            catch ME
                fprintf('生成部署方案失败: %s\n', ME.message);
                continue;
            end
            
            % 【步骤3】直接调用已验证的 deploy_requests 进行部署
            % 事务快照（用于回滚）
            nodes_snapshot = nodes;
            links_snapshot = links;
            consume_snapshot = consume(req_id);
            fail_log_snapshot_len = numel(fail_log);
            
            % 直接调用 deploy_requests（将单个请求/方案包装为数组）
            [nodes_new, links_new, ~, consume_new, fail_log_new] = ...
                deploy_requests(nodes, links, req, sortedPlanSingle, consume, fail_log);
            
            % 检查部署是否成功
            success = (consume_new(req_id).accepted == 1);
            
            if success
                % 部署成功：提交更新
                nodes = nodes_new;
                links = links_new;
                consume = consume_new;
                % 部署成功时不保留失败日志（恢复到循环前状态）
                fail_log = fail_log(1:fail_log_len_before);
                deployed = true;
                deployedPlanIdx = candIdx;
                fixedCandPlan = fixedPlanRaw;  % 保存修复后的方案
                
                fprintf('成功!\n');
                
                if tryIdx == 1
                    deployStats.first_try_success = deployStats.first_try_success + 1;
                else
                    deployStats.fallback_success = deployStats.fallback_success + 1;
                end
                
                break;  % 成功则退出循环
            else
                % 部署失败：回滚并尝试下一个候选方案
                nodes = nodes_snapshot;
                links = links_snapshot;
                consume(req_id) = consume_snapshot;
                
                fprintf('失败\n');
                
                % 【重要】每个请求只保留第一次失败的日志
                if ~first_fail_recorded
                    % 第一次失败：保留失败日志（只保留一条）
                    if numel(fail_log_new) > fail_log_snapshot_len
                        fail_log = fail_log_new(1:fail_log_snapshot_len+1);
                    end
                    first_fail_recorded = true;
                end
                % 后续失败不再追加日志
            end
        end
        
        %% ========== 5. 记录部署结果 ==========
        if deployed
            % 使用成功部署的【修复后】方案
            % fixedCandPlan 是 FixedTreePlan 输出的格式（一维placeLinks）
            newPlan = fixedCandPlan;
            deployStats.accepted_requests = deployStats.accepted_requests + 1;
            fprintf('  √ 请求 %d 部署成功（使用第%d个候选方案，已修复）\n', req_id, deployedPlanIdx);
        else
            % 所有候选方案都失败
            deployStats.rejected_requests = deployStats.rejected_requests + 1;
            deployStats.all_cand_failed = deployStats.all_cand_failed + 1;
            
            % 使用第一个修复后的fallback方案记录
            if numCandPlans > 0
                try
                    fallbackFixed = FixedTreePlan(req, candPlans(1), links);
                    newPlan = fallbackFixed(1);
                catch
                    newPlan = candPlans(1);
                end
            else
                newPlan = createEmptyPlan(req_id, destNum, vnfNum, linkNum);
            end
            
            % 确保consume记录为拒绝
            consume(req_id).accepted = 0;
            
            fprintf('  × 请求 %d 部署失败（所有%d个候选方案都失败）\n', req_id, numCandPlans);
        end
        
        % 确保newPlan有req_id字段
        if ~isfield(newPlan, 'req_id') || isempty(newPlan.req_id)
            newPlan.req_id = req_id;
        end
        
        % 将部署方案记录到plan数组
        if isempty(plan)
            plan(1) = newPlan;
        else
            plan(end+1) = newPlan;
        end
    end
    
    %% ===================== 输出统计信息 =====================
    fprintf('\n======== 在线评估部署完成 ========\n');
    fprintf('总请求数: %d\n', deployStats.total_requests);
    fprintf('接受请求: %d (%.1f%%)\n', deployStats.accepted_requests, ...
            100*deployStats.accepted_requests/deployStats.total_requests);
    fprintf('拒绝请求: %d (%.1f%%)\n', deployStats.rejected_requests, ...
            100*deployStats.rejected_requests/deployStats.total_requests);
    fprintf('  - 首选方案成功: %d\n', deployStats.first_try_success);
    fprintf('  - 备选方案成功: %d\n', deployStats.fallback_success);
    fprintf('  - 全部方案失败: %d\n', deployStats.all_cand_failed);
end

%% ========== 辅助函数：生成候选部署方案 ==========
function candPlans = generateCandidatePlans(req, req_idx, KPathsNew, nodes, links, ...
                                            nodeFreq, linkFreq, candLinkNum, candNodeNum, ...
                                            destNum, vnfNum, linkNum, deployMethodCfg)
%GENERATECANDIDATEPLANS 为一个请求生成多个候选部署方案
%
% 策略：
% 1. 【核心改进】动态逐个选择目的节点加入树（每次选择后更新已建树状态）
% 2. 为每个目的节点选择前candLinkNum条最短路
% 3. 对每条路径，使用calcNodeScore计算最佳VNF放置
% 4. 返回所有有效的候选方案

    candPlans = [];
    src = req.source;
    dests = req.dest(req.dest > 0);
    
    % ========== 【核心改进】动态逐个选择目的节点 ==========
    % 初始化
    remainDests = dests;           % 剩余未加入的目的节点
    orderedDests = zeros(1, destNum);  % 记录加入顺序
    usedLinks = [];                % 已建树使用的链路集合
    usedNodes = [];                % 已建树使用的节点集合
    globalNodeFreq = [];           % 全局节点频率（首次计算后复用）
    globalLinkFreq = [];           % 全局链路频率（首次计算后复用）
    
    % 为每个目的节点收集候选路径方案
    destPathPlans = cell(destNum, 1);
    
    % 逐个选择目的节点加入树
    for orderIdx = 1:destNum
        % 【关键】每次根据当前已建树状态选择下一个目的节点
        [nextDest, ~, globalNodeFreq, globalLinkFreq] = calcDestOrderBySharePotential( ...
            src, remainDests, KPathsNew, links, nodes, usedLinks, usedNodes, globalNodeFreq, globalLinkFreq);
        
        % 记录加入顺序
        orderedDests(orderIdx) = nextDest;
        
        % 找到该dest在原始dests数组中的索引
        origDestIdx = find(dests == nextDest, 1);
        
        % 从剩余列表中移除
        remainDests = remainDests(remainDests ~= nextDest);
        
        % 获取该目的节点的K条最短路
        Pathinfo = KPathsNew{src, nextDest};
        
        if isempty(Pathinfo)
            % 没有可用路径，使用空方案
            destPathPlans{origDestIdx} = [];
            continue;
        end
        
        % 用 calcPathScore 对所有路径进行预评估，选取得分最高的K条
        pathScoreStruct = calcPathScore(Pathinfo, linkFreq, links, req, 1, deployMethodCfg);
        
        % calcPathScore 返回的结果已按 totalScore 降序排列
        numPaths = min(candLinkNum, numel(pathScoreStruct));
        pathPlans = repmat(struct('pathLinks', [], 'pathNodes', [], 'vnfNodes', [], 'pathScore', 0), numPaths, 1);
        
        for pathIdx = 1:numPaths
            % 从 pathScoreStruct 获取原始路径索引
            origK = pathScoreStruct(pathIdx).k;
            route = Pathinfo(origK);
            
            pathLinks = route.link_ids;
            pathLinks = pathLinks(pathLinks > 0);
            pathNodes = route.paths;
            pathNodes = pathNodes(pathNodes > 0);
            hops = route.pathshops;
            
            if hops <= 0 || ~isfinite(pathScoreStruct(pathIdx).totalScore)
                continue;
            end
            
            % 计算该路径的VNF放置
            % 注：dest_idx使用排序后的orderIdx，这样共享潜力权重衰减能正确反映加入顺序
            vnfNodes = computeVnfPlacement(route, nodes, links, req, nodeFreq, linkFreq, ...
                                          orderIdx, destNum, vnfNum, candNodeNum, deployMethodCfg);
            
            pathPlans(pathIdx).pathLinks = pathLinks(:).';
            pathPlans(pathIdx).pathNodes = pathNodes(:).';
            pathPlans(pathIdx).vnfNodes = vnfNodes;
            pathPlans(pathIdx).pathScore = pathScoreStruct(pathIdx).totalScore;
        end
        
        % 存储时使用原始索引
        destPathPlans{origDestIdx} = pathPlans;
        
        % 【关键】更新已建树的链路/节点集合（使用最佳路径）
        if ~isempty(pathPlans) && ~isempty(pathPlans(1).pathLinks)
            usedLinks = unique([usedLinks, pathPlans(1).pathLinks]);
            usedNodes = unique([usedNodes, pathPlans(1).pathNodes]);
        end
    end
    
    % ========== 组合各目的节点的方案生成完整的多播方案 ==========
    % 策略：每个目的节点使用各自的最佳路径（形成candLinkNum个方案）
    for candIdx = 1:candLinkNum
        newPlan = struct( ...
            'req_id',       req.id, ...
            'placeLinks',   zeros(destNum, linkNum), ...
            'vnfNode',      zeros(destNum, vnfNum), ...
            'totalScore',   0, ...
            'destScores',   zeros(destNum, 1), ...
            'destOrder',    orderedDests ...  % 记录目的节点加入顺序
        );
        
        validPlan = true;
        totalScoreSum = 0;
        
        % 按原始索引遍历（保持placeLinks/vnfNode索引与dests一致）
        for dest_idx = 1:destNum
            pathPlans = destPathPlans{dest_idx};
            
            if isempty(pathPlans)
                % 使用fallback
                [fbLinks, fbVnfNodes] = getFallbackForDest(KPathsNew, src, dests(dest_idx), vnfNum);
                numLinks = numel(fbLinks);
                if numLinks > 0 && numLinks <= linkNum
                    newPlan.placeLinks(dest_idx, 1:numLinks) = fbLinks;
                end
                newPlan.vnfNode(dest_idx, :) = fbVnfNodes;
                newPlan.destScores(dest_idx) = -inf;
            else
                % 选择第candIdx条路径（如果存在）
                pathIdx = min(candIdx, numel(pathPlans));
                pathPlan = pathPlans(pathIdx);
                
                numLinks = numel(pathPlan.pathLinks);
                if numLinks > 0 && numLinks <= linkNum
                    newPlan.placeLinks(dest_idx, 1:numLinks) = pathPlan.pathLinks;
                end
                
                if ~isempty(pathPlan.vnfNodes) && all(pathPlan.vnfNodes > 0)
                    newPlan.vnfNode(dest_idx, :) = pathPlan.vnfNodes;
                else
                    % VNF节点无效，使用均匀分布
                    hops = numLinks;
                    route = KPathsNew{src, dests(dest_idx)};
                    if ~isempty(route)
                        pathNodes = route(min(pathIdx, numel(route))).paths;
                        pathNodes = pathNodes(pathNodes > 0);
                        for v = 1:vnfNum
                            idx = ceil(v * hops / vnfNum);
                            pos = 1 + idx;
                            if pos <= numel(pathNodes)
                                newPlan.vnfNode(dest_idx, v) = pathNodes(pos);
                            else
                                newPlan.vnfNode(dest_idx, v) = pathNodes(end);
                            end
                        end
                    else
                        validPlan = false;
                    end
                end
                
                newPlan.destScores(dest_idx) = pathPlan.pathScore;
                totalScoreSum = totalScoreSum + pathPlan.pathScore;
            end
        end
        
        newPlan.totalScore = totalScoreSum;
        
        if validPlan
            if isempty(candPlans)
                candPlans = newPlan;
            else
                candPlans(end+1) = newPlan;
            end
        end
    end
end

function vnfNodes = computeVnfPlacement(route, nodes, links, req, nodeFreq, linkFreq, ...
                                        dest_idx, destNum, vnfNum, candNodeNum, deployMethodCfg)
%COMPUTEVNFPLACEMENT 计算路径上的VNF放置方案
    
    pathNodes = route.paths;
    pathNodes = pathNodes(pathNodes > 0);
    pathLinks = route.link_ids;
    pathLinks = pathLinks(pathLinks > 0);
    hops = numel(pathLinks);
    
    vnfNodes = zeros(1, vnfNum);
    
    if hops <= 0 || numel(pathNodes) < 2
        return;
    end
    
    % 构建候选路径结构
    candpath = struct('paths', pathNodes, 'link_ids', pathLinks, 'pathshops', hops);
    
    % 逐个VNF计算最佳放置节点
    t0 = 1;
    prevPlaceInfo = [];
    
    for vnfIdx = 1:vnfNum
        % 调用calcNodeScore计算各节点得分
        nodeScores = calcNodeScore(candpath, linkFreq, nodeFreq, ...
                                   req, t0, nodes, links, ...
                                   vnfIdx, dest_idx, destNum, deployMethodCfg, prevPlaceInfo);
        
        if isempty(nodeScores)
            % 无有效候选节点，使用均匀分布
            idx = ceil(vnfIdx * hops / vnfNum);
            pos = 1 + idx;
            if pos <= numel(pathNodes)
                vnfNodes(vnfIdx) = pathNodes(pos);
            else
                vnfNodes(vnfIdx) = pathNodes(end);
            end
        else
            % 选择得分最高的节点
            bestNode = nodeScores(1);  % 已按得分降序排列
            vnfNodes(vnfIdx) = bestNode.nodeId;
            
            % 更新prevPlaceInfo用于下一个VNF
            newInfo = struct( ...
                'placeNode', bestNode.nodeId, ...
                'placeLinks', bestNode.linksToNode, ...
                'linkCount', bestNode.linkCount, ...
                'leaveTime', bestNode.leaveTime ...
            );
            
            if isempty(prevPlaceInfo)
                prevPlaceInfo = newInfo;
            else
                prevPlaceInfo(end+1) = newInfo;
            end
        end
    end
end

function [fbLinks, fbVnfNodes] = getFallbackForDest(KPathsNew, src, dest, vnfNum)
%GETFALLBACKFORDEST 获取某目的节点的fallback方案
    fbLinks = [];
    fbVnfNodes = zeros(1, vnfNum);
    
    Pathinfo = KPathsNew{src, dest};
    if isempty(Pathinfo)
        return;
    end
    
    route = Pathinfo(1);
    hops = route.pathshops;
    
    if hops <= 0
        return;
    end
    
    fbLinks = route.link_ids;
    fbLinks = fbLinks(fbLinks > 0);
    fbLinks = fbLinks(:).';
    
    pathNodes = route.paths;
    pathNodes = pathNodes(pathNodes > 0);
    
    for v = 1:vnfNum
        idx = ceil(v * hops / vnfNum);
        pos = 1 + idx;
        if pos <= numel(pathNodes)
            fbVnfNodes(v) = pathNodes(pos);
        else
            fbVnfNodes(v) = pathNodes(end);
        end
    end
end

function candPlans = generateFallbackPlan(req, KPathsNew, destNum, vnfNum, linkNum)
%GENERATEFALLBACKPLAN 生成fallback方案
    src = req.source;
    dests = req.dest(req.dest > 0);
    
    newPlan = struct( ...
        'req_id',       req.id, ...
        'placeLinks',   zeros(destNum, linkNum), ...
        'vnfNode',      zeros(destNum, vnfNum) ...
    );
    
    for dest_idx = 1:destNum
        [fbLinks, fbVnfNodes] = getFallbackForDest(KPathsNew, src, dests(dest_idx), vnfNum);
        numLinks = numel(fbLinks);
        if numLinks > 0 && numLinks <= linkNum
            newPlan.placeLinks(dest_idx, 1:numLinks) = fbLinks;
        end
        newPlan.vnfNode(dest_idx, :) = fbVnfNodes;
    end
    
    candPlans = newPlan;
end

function newPlan = createEmptyPlan(req_id, destNum, vnfNum, linkNum)
%CREATEEMPTYPLAN 创建空的部署方案
    newPlan = struct( ...
        'req_id',       req_id, ...
        'placeLinks',   zeros(destNum, linkNum), ...
        'vnfNode',      zeros(destNum, vnfNum) ...
    );
end

%[appendix]{"version":"1.0"}
%---
