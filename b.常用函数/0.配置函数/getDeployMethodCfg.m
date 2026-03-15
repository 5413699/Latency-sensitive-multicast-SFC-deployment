%[text] # getMethodCfg
%[text] 获取部署方法配置
function cfg = getDeployMethodCfg(MethodName,topoName)
    cfg = struct();
    switch MethodName
        case "shortestPathFirstWithLoadBalancing"
            % 部署函数名
            cfg.deployFunc = 'shortestPathFirstWithLoadBalancing';
            % 图例显示名（绘图时推荐统一使用 getPlotCfg.methodDisplayNames，但这里也给一个标准名便于复用）
            cfg.displayName = 'STB';
            % 采用原始，未排序的请求sortedRequests/'requests'
            cfg.requestsType = 'sortedRequests';
            % 多播树修复（你已改为 FixedTreePlan）
            cfg.FixedFunc = 'FixedTreePlan';
            % 生成部署顺序：
            % - 若使用 FixedTreePlan，输出 placeLinks 为 1×M 的"树边集合"，必须用 generateDeployPlan（基于digraph拆分）
            % - generateDeployPlanWithoutTree 仅适用于"每个dest一条有序链路序列"的 plan.placeLinks（dest×*）
            if strcmp(cfg.FixedFunc, 'FixedTreePlan')
                cfg.sortedFunc = 'generateDeployPlan';
            else
                cfg.sortedFunc = 'generateDeployPlanWithoutTree';
            end
            % 部署方案存储地址：采用原始的部署方案，不进行多播树修正
            cfg.planPath = sprintf('c.输出\\3.部署方案\\1.最短路优先算法\\%s\\spfPlan.mat', topoName);
            % 修复方案存储地址
            cfg.fixedPlanPath = sprintf('c.输出\\3.部署方案\\1.最短路优先算法\\%s\\fixedSpfPlan.mat', topoName);
            % 顺序方案存储地址
            cfg.sortedPlanPath = sprintf('c.输出\\3.部署方案\\1.最短路优先算法\\%s\\sortedSpfPlan.mat', topoName);
            % 多播树图存储地址：
            cfg.treePath = sprintf('c.输出\\3.部署方案\\1.最短路优先算法\\%s\\多播树示意图', topoName);

            % 部署消耗与失败日志存储地址：
            cfg.resultPath = sprintf('c.输出\\4.资源消耗与失败日志\\1.最短路优先算法\\%s\\%sResult.mat', topoName,MethodName);

        case "nodeFirst"
            % 部署函数名
            cfg.deployFunc = 'nodeFirst';
            cfg.displayName = 'NIF';
            % 采用原始，未排序的请求
            cfg.requestsType = 'requests';
            % 多播树修复（你已改为 FixedTreePlan）
            cfg.FixedFunc = 'FixedTreePlan';
            % 生成部署顺序：
            % - 若使用 FixedTreePlan，输出 placeLinks 为 1×M 的“树边集合”，必须用 generateDeployPlan（基于digraph拆分）
            % - generateDeployPlanWithoutTree 仅适用于“每个dest一条有序链路序列”的 plan.placeLinks（dest×*）
            if strcmp(cfg.FixedFunc, 'FixedTreePlan')
                cfg.sortedFunc = 'generateDeployPlan';
            else
                cfg.sortedFunc = 'generateDeployPlanWithoutTree';
            end
            % 部署方案存储地址：采用原始的部署方案，不进行多播树修正
            cfg.planPath = sprintf('c.输出\\3.部署方案\\2.空闲节点贪婪\\%s\\nfPlan.mat', topoName);
            % 修复方案存储地址
            cfg.fixedPlanPath = sprintf('c.输出\\3.部署方案\\2.空闲节点贪婪\\%s\\fixedNfPlan.mat', topoName);
            % 顺序方案存储地址
            cfg.sortedPlanPath = sprintf('c.输出\\3.部署方案\\2.空闲节点贪婪\\%s\\sortedNfPlan.mat', topoName);
            % 多播树图存储地址：
            cfg.treePath = sprintf('c.输出\\3.部署方案\\2.空闲节点贪婪\\%s\\多播树示意图', topoName);

            % 部署消耗与失败日志存储地址：
            cfg.resultPath = sprintf('c.输出\\4.资源消耗与失败日志\\2.空闲节点贪婪\\%s\\%sResult.mat', topoName,MethodName);

        case "RSA"
            % 部署函数名
            cfg.deployFunc = 'RSA';
            % 图例显示名（绘图时推荐统一使用 getPlotCfg.methodDisplayNames，但这里也给一个标准名便于复用）
            cfg.displayName = 'RSA';
            % 采用原始，未排序的请求
            cfg.requestsType = 'sortedRequests';
            % 多播树修复（你已改为 FixedTreePlan）
            cfg.FixedFunc = 'FixedTreePlan';
            % 生成部署顺序：
            % - 若使用 FixedTreePlan，输出 placeLinks 为 1×M 的"树边集合"，必须用 generateDeployPlan（基于digraph拆分）
            % - generateDeployPlanWithoutTree 仅适用于"每个dest一条有序链路序列"的 plan.placeLinks（dest×*）
            if strcmp(cfg.FixedFunc, 'FixedTreePlan') || strcmp(cfg.FixedFunc, 'breakLoop')
                cfg.sortedFunc = 'generateDeployPlan';
            else
                cfg.sortedFunc = 'generateDeployPlanWithoutTree';
            end
            % 部署方案存储地址：采用原始的部署方案，不进行多播树修正
            cfg.planPath = sprintf('c.输出\\3.部署方案\\3.随机部署\\%s\\%sPlan.mat', topoName,MethodName);
            % 修复方案存储地址
            cfg.fixedPlanPath = sprintf('c.输出\\3.部署方案\\3.随机部署\\%s\\fixedRsaPlan.mat', topoName);
            % 顺序方案存储地址
            cfg.sortedPlanPath = sprintf('c.输出\\3.部署方案\\3.随机部署\\%s\\sortedRsaPlan.mat', topoName);
            % 多播树图存储地址：
            cfg.treePath = sprintf('c.输出\\3.部署方案\\3.随机部署\\%s\\多播树示意图', topoName);

            % 部署消耗与失败日志存储地址：
            cfg.resultPath = sprintf('c.输出\\4.资源消耗与失败日志\\3.随机部署\\%s\\%sResult.mat', topoName,MethodName);

        % case "ResourceAndDelayAware"
        %     % 部署函数名（离线版本：方案生成与部署分离）
        %     cfg.deployFunc = 'ResourceAndDelayAware';
        %     cfg.displayName = 'RDA';
        %     % 采用按照最大容忍时延排序的请求
        %     cfg.requestsType = 'sortedRequests';
        %     % 对生成的请求进行多播树修复
        %     cfg.FixedFunc = 'FixedTreePlan';
        %     % 生成部署顺序
        %     cfg.sortedFunc = 'generateDeployPlan';
        %     % 是否使用在线评估模式
        %     cfg.onlineMode = false;
        % 
        %     % ====== 候选数量配置 ======
        %     cfg.candLinkNum = 5;
        %     cfg.candNodeNum = 5;
        % 
        %     % ====== 评价权重配置（五维综合评分） ======
        %     cfg.shareWeight = 1;   % 共享潜力
        %     cfg.congWeight = 1.0;    % 资源可用性（CPU/内存/带宽）
        %     cfg.delayWeight = 3;   % 时延满足度（含排队等待）
        %     cfg.shareDecayMin = 0;
        % 
        %     % 部署方案存储地址
        %     cfg.planPath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\rdaPlan.mat', topoName);
        %     cfg.fixedPlanPath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\fixedRdaPlan.mat', topoName);
        %     cfg.sortedPlanPath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\sortedRdaPlan.mat', topoName);
        %     cfg.treePath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\多播树示意图', topoName);
        %     cfg.resultPath = sprintf('c.输出\\4.资源消耗与失败日志\\9.资源与时延感知算法\\%s\\%sResult.mat', topoName,MethodName);
            
        case "ResourceAndDelayAwareOnline"
            % 部署函数名（在线版本：方案生成与部署融合）
            cfg.deployFunc = 'ResourceAndDelayAwareOnline';
            cfg.displayName = 'RDA';
            % 采用按照最大容忍时延排序的请求
            cfg.requestsType = 'sortedRequests';
            % 【重要】在线模式也需要多播树修复以节约资源
            cfg.FixedFunc = 'FixedTreePlan';
            % 生成部署顺序
            cfg.sortedFunc = 'generateDeployPlan';
            % 在线评估模式标志
            cfg.onlineMode = true;
            
            % ====== 候选数量配置 ======
            cfg.candLinkNum = 5;
            cfg.candNodeNum = 5;
            
            % ====== 评价权重配置（在线模式，五维综合评分）======
            % 共享能降低资源消耗，提高成功率，应当重视
            % 但也要平衡资源可用性和时延满足度
            cfg.shareWeight = 1;   % 共享潜力（共享能降低消耗）
            cfg.congWeight = 1.0;    % 资源可用性（CPU/内存/带宽）
            cfg.delayWeight = 3.0;   % 时延满足度（含排队等待）
            cfg.shareDecayMin = 0;

            % 部署方案存储地址（在线版本单独保存）
            cfg.planPath = sprintf('c.输出\\3.部署方案\\9.在线资源与时延感知算法\\%s\\rdaOnlinePlan.mat', topoName);
            cfg.fixedPlanPath = sprintf('c.输出\\3.部署方案\\9.在线资源与时延感知算法\\%s\\fixedRdaOnlinePlan.mat', topoName);
            cfg.sortedPlanPath = sprintf('c.输出\\3.部署方案\\9.在线资源与时延感知算法\\%s\\sortedRdaOnlinePlan.mat', topoName);
            cfg.treePath = sprintf('c.输出\\3.部署方案\\9.在线资源与时延感知算法\\%s\\多播树示意图_在线', topoName);
            cfg.resultPath = sprintf('c.输出\\4.资源消耗与失败日志\\9.在线资源与时延感知算法\\%s\\%sResult.mat', topoName,MethodName);

        otherwise
            error("未知方法：%s", MethodName);
    end
end



%[appendix]{"version":"1.0"}
%---
