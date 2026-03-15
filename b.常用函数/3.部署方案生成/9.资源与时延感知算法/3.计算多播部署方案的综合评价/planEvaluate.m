%[text] # planEvaluate
%[text] 多播部署方案综合评价与排序
%[text]
%[text] ## 功能说明
%[text] 对一组候选部署方案进行综合评价，返回最优方案及其排名。
%[text] 【优化】直接使用候选方案中已计算的得分（来自calcNodeScore/computePathScore）
%[text]
%[text] ## 输入参数
%[text] - candPlans: 候选方案结构体数组（包含已计算的totalScore字段）
%[text] - deployMethodCfg: 配置参数
%[text]
%[text] ## 输出参数
%[text] - bestPlan: 综合评分最高的方案
%[text] - bestIdx: 最优方案在原数组中的索引
%[text] - rankedPlans: 按评分排序后的方案数组
%[text] - rankOrder: 排序索引

function [bestPlan, bestIdx, rankedPlans, rankOrder] = planEvaluate(candPlans, deployMethodCfg, ~, ~, ~, ~)
    % 注：后4个参数(nodes, links, req, t0)保留用于向后兼容，但不再使用
    % 因为得分已在生成候选方案时通过 calcNodeScore/computePathScore 计算好

    numPlans = numel(candPlans);
    
    if numPlans == 0
        bestPlan = [];
        bestIdx = 0;
        rankedPlans = [];
        rankOrder = [];
        return;
    end
    
    % 提取已计算的得分
    scores = zeros(numPlans, 1);
    linkCounts = zeros(numPlans, 1);  % 用于平局时排序
    
    for i = 1:numPlans
        plan = candPlans(i);
        
        % 优先使用已计算的 totalScore（来自 generateCandidatePlans）
        if isfield(plan, 'totalScore') && ~isempty(plan.totalScore)
            scores(i) = plan.totalScore;
        elseif isfield(plan, 'success') && plan.success && isfield(plan, 'e2eDelay')
            % 兼容旧格式（来自rdaLinkAndNodeChoice）
            scores(i) = -plan.e2eDelay;  % 时延越小越好
        else
            % 无得分信息，使用跳数估算
            if isfield(plan, 'placeLinks') && ~isempty(plan.placeLinks)
                linkCounts(i) = sum(plan.placeLinks(:) > 0);
                scores(i) = -linkCounts(i);  % 跳数越少越好
            else
                scores(i) = -inf;
            end
        end
        
        % 记录链路数（用于平局排序）
        if isfield(plan, 'placeLinks') && ~isempty(plan.placeLinks)
            linkCounts(i) = sum(plan.placeLinks(:) > 0);
        end
    end
    
    % 排序：得分降序，平局时链路数升序（跳数少优先）
    [~, rankOrder] = sortrows([-scores, linkCounts], [1, 2]);
    
    % 重排方案
    rankedPlans = candPlans(rankOrder);
    
    % 返回最优方案
    bestIdx = rankOrder(1);
    bestPlan = candPlans(bestIdx);
    
    % 附加评价结果
    bestPlan.evalResult = struct('totalScore', scores(bestIdx), 'rank', 1);
end

%[appendix]{"version":"1.0"}
%---
