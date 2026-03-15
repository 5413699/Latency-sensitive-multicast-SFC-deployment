# Code Summary

Generated on: 2026-01-13 17:09:46

---

## deployAndDispatchPlan.asv

```matlab
%[text] # 2.生成部署方案
clc; clear;
%[text] ## 1) 导入路径
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'a.输入')));
addpath(genpath(fullfile(currentDir, 'b.常用函数')));
%[text] ## 2) 选择拓补与部署方法（只改这里和对应配置函数）
% topoName = "Abilene";   % "US_Backbone" 或 "Abilene"
topoName = "US_Backbone";   % "US_Backbone" 或 "Abilene"

% 可选方法：
% - 'shortestPathFirstWithLoadBalancing': 最短路优先（离线）
% - 'ResourceAndDelayAware': 资源与时延感知（离线）
% - 'ResourceAndDelayAwareOnline': 资源与时延感知（在线评估）
deployMethodName = 'ResourceAndDelayAwareOnline';
% deployMethodName = 'ResourceAndDelayAware'; 
% deployMethodName = 'shortestPathFirstWithLoadBalancing'; 

%[text] ## 3) 配置表：不同拓补只在这里写一次
topocfg = getTopoCfg(topoName);
reqCfg = getReqCfg(topoName);
deployMethodCfg = getDeployMethodCfg(deployMethodName,topoName);
%[text] ## 4) 生成部署相关数据并保存
load(topocfg.topoInfoPath);     % 得到 nodes / links / KPaths
load(reqCfg.requestPath);% 得到原始请求集合
load(reqCfg.sortedRequestsPath);% 得到按最大可容忍时延排序好的请求集合

[fail_log, consume, nodes, plan]=initNecessaryStructure(requests, nodes);
reqs = eval(deployMethodCfg.requestsType);
% reqs = sortedRequests;

%[text] ## 4.1) 根据模式选择不同的部署流程
if isfield(deployMethodCfg, 'onlineMode') && deployMethodCfg.onlineMode %[output:group:21366e3c]
    %% ========== 在线评估模式 ==========
    % ResourceAndDelayAwareOnline 同时完成方案生成和部署
    % 返回更新后的 nodes, links, consume, fail_log
    fprintf('使用在线评估模式: %s\n', deployMethodName); %[output:49508bc6]
    
    [plan, nodes, links, consume, fail_log, deployStats] = feval(deployMethodCfg.deployFunc, ... %[output:50eda242]
                    reqs, ... %[output:50eda242]
                    KPathsNew, links, nodes, ... %[output:50eda242]
                    plan, consume, fail_log, deployMethodCfg); %[output:50eda242]
    
    % 在线模式修复，因为部署时已验证方案有效性
    fixedPlan = feval(deployMethodCfg.FixedFunc, ...
                    reqs, plan, links);  
    
    % 顺序化的部署计划
    sortedPlan = feval(deployMethodCfg.sortedFunc, ...
                    reqs, fixedPlan, links);
    
    % 保存部署统计信息
    save(deployMethodCfg.planPath, 'plan', 'deployStats'); 
    
    % 【重要】在线模式下直接保存最终结果（部署已完成，无需再调用sfcMapping）
    % 保存格式与sfcMapping输出一致，便于resultPlot统一处理
    requests = reqs;  % 使用排序后的请求
    
    % 确保目录存在
    [resultDir, ~, ~] = fileparts(deployMethodCfg.resultPath);
    if ~isfolder(resultDir)
        mkdir(resultDir);
    end
    
    save(deployMethodCfg.resultPath, 'nodes', 'links', 'requests', 'consume', 'fail_log', 'deployStats');
    fprintf('  ✓ 在线模式结果已保存到: %s\n', deployMethodCfg.resultPath); %[output:3e8af66c]
else
    %% ========== 离线模式（原有流程） ==========
    fprintf('使用离线模式: %s\n', deployMethodName);

% 原始部署计划
    % 使用KPathsNew格式（cell数组，每个元素是K×1 struct数组）
plan = feval(deployMethodCfg.deployFunc, ...
                reqs, ...
                    KPathsNew, links, nodes, ...
                    plan, deployMethodCfg);   
% 多播树修复后的部署计划
fixedPlan = feval(deployMethodCfg.FixedFunc, ...
                reqs, plan, links);  
% 顺序化的部署计划
    sortedPlan = feval(deployMethodCfg.sortedFunc, ...
                reqs, fixedPlan, links);  

save(deployMethodCfg.planPath,'plan'); 
end %[output:group:21366e3c]

save(deployMethodCfg.fixedPlanPath,'fixedPlan'); 
save(deployMethodCfg.sortedPlanPath,'sortedPlan',"consume","fail_log","nodes"); 
fprintf('✓ 已保存（时间：%s）\n', string(datetime("now"))); %[output:3121d3f6]


%[text] ## 5) 根据计划绘制一个多播树进行示意
set(groot,'DefaultFigureVisible','off');%不弹出窗口
req_id=1;
plotTree(sortedPlan, req_id, links, reqs, deployMethodCfg.treePath); %[output:8aef4559] %[output:96ed6179] %[output:7588263d]



% 查看请求4的详细消耗
info = extractDetailedConsumeInfo(consume, 4);
%[text] 
%[text] 
%[text] 
%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":34.2}
%---
%[output:49508bc6]
%   data: {"dataType":"text","outputData":{"text":"使用在线评估模式: ResourceAndDelayAwareOnline\n","truncated":false}}
%---
%[output:50eda242]
%   data: {"dataType":"text","outputData":{"text":"======== 开始在线评估部署 ========\n总请求数: 100\n\n--- 处理请求 1\/100 (req_id=10) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 10 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 2\/100 (req_id=8) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 8 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 3\/100 (req_id=44) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 44 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 4\/100 (req_id=61) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 61 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 5\/100 (req_id=74) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 74 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 6\/100 (req_id=77) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 77 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 7\/100 (req_id=4) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 4 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 8\/100 (req_id=25) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 25 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 9\/100 (req_id=26) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 26 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 10\/100 (req_id=70) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 70 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 11\/100 (req_id=91) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 91 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 12\/100 (req_id=32) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 32 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 13\/100 (req_id=60) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 60 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 14\/100 (req_id=72) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 72 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 15\/100 (req_id=82) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 82 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 16\/100 (req_id=96) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 成功!\n  √ 请求 96 部署成功（使用第3个候选方案，已修复）\n\n--- 处理请求 17\/100 (req_id=22) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 22 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 18\/100 (req_id=28) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 成功!\n  √ 请求 28 部署成功（使用第2个候选方案，已修复）\n\n--- 处理请求 19\/100 (req_id=48) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 48 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 20\/100 (req_id=84) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 成功!\n  √ 请求 84 部署成功（使用第2个候选方案，已修复）\n\n--- 处理请求 21\/100 (req_id=78) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 78 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 22\/100 (req_id=83) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 83 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 23\/100 (req_id=56) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 56 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 24\/100 (req_id=97) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 97 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 25\/100 (req_id=9) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 9 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 26\/100 (req_id=45) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 成功!\n  √ 请求 45 部署成功（使用第3个候选方案，已修复）\n\n--- 处理请求 27\/100 (req_id=7) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 7 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 28\/100 (req_id=52) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 52 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 29\/100 (req_id=75) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 75 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 30\/100 (req_id=11) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 11 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 31\/100 (req_id=35) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 35 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 32\/100 (req_id=71) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 71 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 33\/100 (req_id=80) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 80 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 34\/100 (req_id=46) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 46 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 35\/100 (req_id=57) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 57 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 36\/100 (req_id=58) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 成功!\n  √ 请求 58 部署成功（使用第1个候选方案，已修复）\n\n--- 处理请求 37\/100 (req_id=90) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 90 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 38\/100 (req_id=17) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 17 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 39\/100 (req_id=39) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 39 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 40\/100 (req_id=27) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 成功!\n  √ 请求 27 部署成功（使用第5个候选方案，已修复）\n\n--- 处理请求 41\/100 (req_id=64) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 64 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 42\/100 (req_id=38) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 38 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 43\/100 (req_id=85) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 85 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 44\/100 (req_id=2) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 2 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 45\/100 (req_id=31) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 修复失败: 边索引必须为不大于图中的边数(11)的正整数。\n  × 请求 31 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 46\/100 (req_id=15) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 15 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 47\/100 (req_id=43) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 成功!\n  √ 请求 43 部署成功（使用第4个候选方案，已修复）\n\n--- 处理请求 48\/100 (req_id=92) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 92 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 49\/100 (req_id=93) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 93 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 50\/100 (req_id=89) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 89 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 51\/100 (req_id=68) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 68 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 52\/100 (req_id=73) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 修复失败: 边索引必须为不大于图中的边数(16)的正整数。\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 73 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 53\/100 (req_id=76) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 76 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 54\/100 (req_id=30) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 30 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 55\/100 (req_id=12) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 12 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 56\/100 (req_id=23) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 23 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 57\/100 (req_id=53) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 53 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 58\/100 (req_id=67) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 67 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 59\/100 (req_id=19) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 19 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 60\/100 (req_id=37) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 37 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 61\/100 (req_id=88) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 88 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 62\/100 (req_id=95) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 95 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 63\/100 (req_id=13) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 13 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 64\/100 (req_id=29) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 29 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 65\/100 (req_id=18) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 18 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 66\/100 (req_id=33) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 33 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 67\/100 (req_id=47) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 47 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 68\/100 (req_id=98) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 98 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 69\/100 (req_id=16) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 16 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 70\/100 (req_id=59) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 59 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 71\/100 (req_id=40) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 40 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 72\/100 (req_id=62) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 62 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 73\/100 (req_id=69) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 成功!\n  √ 请求 69 部署成功（使用第4个候选方案，已修复）\n\n--- 处理请求 74\/100 (req_id=41) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 成功!\n  √ 请求 41 部署成功（使用第2个候选方案，已修复）\n\n--- 处理请求 75\/100 (req_id=66) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 66 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 76\/100 (req_id=34) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 34 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 77\/100 (req_id=1) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 1 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 78\/100 (req_id=51) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 51 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 79\/100 (req_id=99) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 99 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 80\/100 (req_id=21) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 21 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 81\/100 (req_id=14) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 14 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 82\/100 (req_id=94) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 94 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 83\/100 (req_id=100) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 100 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 84\/100 (req_id=20) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 成功!\n  √ 请求 20 部署成功（使用第2个候选方案，已修复）\n\n--- 处理请求 85\/100 (req_id=3) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 3 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 86\/100 (req_id=36) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 36 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 87\/100 (req_id=81) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 81 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 88\/100 (req_id=86) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 86 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 89\/100 (req_id=42) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 42 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 90\/100 (req_id=63) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 修复失败: 边索引必须为不大于图中的边数(15)的正整数。\n  × 请求 63 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 91\/100 (req_id=87) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 87 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 92\/100 (req_id=5) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 5 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 93\/100 (req_id=24) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 24 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 94\/100 (req_id=49) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 49 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 95\/100 (req_id=50) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 50 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 96\/100 (req_id=55) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 55 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 97\/100 (req_id=65) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 65 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 98\/100 (req_id=6) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 6 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 99\/100 (req_id=54) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 54 部署失败（所有5个候选方案都失败）\n\n--- 处理请求 100\/100 (req_id=79) ---\n  生成了 5 个候选方案\n  尝试候选方案 1 (排名第1)... 失败\n  尝试候选方案 2 (排名第2)... 失败\n  尝试候选方案 3 (排名第3)... 失败\n  尝试候选方案 4 (排名第4)... 失败\n  尝试候选方案 5 (排名第5)... 失败\n  × 请求 79 部署失败（所有5个候选方案都失败）\n\n======== 在线评估部署完成 ========\n总请求数: 100\n接受请求: 32 (32.0%)\n拒绝请求: 68 (68.0%)\n  - 首选方案成功: 23\n  - 备选方案成功: 9\n  - 全部方案失败: 68\n","truncated":false}}
%---
%[output:3e8af66c]
%   data: {"dataType":"text","outputData":{"text":"  ✓ 在线模式结果已保存到: c.输出\\4.资源消耗与失败日志\\9.在线资源与时延感知算法\\US_Backbone\\ResourceAndDelayAwareOnlineResult.mat\n","truncated":false}}
%---
%[output:3121d3f6]
%   data: {"dataType":"text","outputData":{"text":"✓ 已保存（时间：2026-01-13 15:02:14）\n","truncated":false}}
%---
%[output:8aef4559]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAd0AAADrCAYAAAAsaUxqAAAAAXNSR0IArs4c6QAAIABJREFUeF7tnQeYFMXWhg9KliwgOYiA4O5FJEhUxIAXUS4GBBRJCggiSM5Rclb0EiSJEhWQ5DWAZOVHQCSDXJbswsICS07736+Gmq3p7Znp7kk9M6eehweY6a6qfqumvjqnTlWnSU5OTiZOTIAJMAEmwASYQMAJpGHRDThjLoAJMAEmwASYgCDAossdgQkwASbABJhAkAiw6AYJtLaYBQsW0Pz582n69OmUK1euVLXw9r16w\/nz56lVq1bUo0cPKleuHPXs2ZMaN25MVapUIfU7\/D8QCWV06dKFevfuTSVLltQt4tChQ9SiRQs6deqU8\/u5c+eKOvo7BeqZZb47d+5MVeWXX36ZRowYQZkyZfL344j8tIzRPzZv3hywMq9duyb60fLly53PM3z4cHrzzTed9ZF9zkobWq3\/b7\/9Rk2aNHHLWK1jQBpCyXTkyJFUrFgxeuWVV1KxkpcFsl9oGeL\/vXr1SvXYbdq0EWOD2ST7gBxLcD9+x7Nnz6Y+ffoErK+brWe4Xc+iG6IWk6L62GOPperAcmCBgLoTZaOiG4zH8ya6+KF2796dRo0a5RRlKcIdOnRwDuTBqKsvZXh7Tl\/y9nZvMMvWaxs54YDAYgAP1MTGGwdtv\/c22TOTn5lr8Rtdt26dYKEnTshLfl6gQAFLouetPnqiGxcX51KW1Tqoky7t5BjlIskJmLd68veuBFh0Q9Qj5A8GP8hXX33VxULEDBoJP2wpuvIzOWNVhezBBx8Ulm6nTp1o8eLFTusEs\/7nn3\/eaQWrlq+01tRZsNYaRd1mzpzprBvqMGXKFFE3OSHAv1G2zE\/PenVn1Wg\/11qSat1w7dmzZ2n16tWiLFgQ2sEM12DQee+991yeGXXUqzs8DFqLzpNlYkT4vLUTROKpp56iIUOGuHCU3g5tG6htqDI+evSoi6WrZadafOCya9cuSkpKcukbeoOm5FGtWrVUg6pen0Of0vYJ+Sxaq1SdRKptf+LECRo2bBhVqFCBxo0bJ7gYsRDdtQfaIG\/evOK3g4Q+XKhQIRdrVJu\/p76nHSLAaOjQodSsWTPx23AnuvI3jPrI37G3\/qYyQx0ff\/xxOnPmjK5oGxFd1EE7QfLmZZAWM8o\/duyYKFv1Zhj5HYRoWA2LYll0Q9RMsuPXr19fiInqths0aBDVqVOHpk2bZkp0vbmXpetZDqjqAPvEE08I9++YMWPED0x+Bzxwmy5btsxlkFd\/uLjWk8UhBxJP7mTtwKAd\/FHep59+6pwEIE+9wQyusFKlSrmIrt7gBNds\/\/79afDgwaQKjFY0zVpW3kQXE5QiRYoIpkhw4crJg5aB+n88k8pYyx\/5NmrUSPQjeZ\/8vxxEJX+w69q1q8uESj6nnldC7yciy3D3LNoytJayVnTR9zDIq1a0rL+7n6gn0VUnrHoTCbWdvPU9bfnIe968eU7XvlHRxdID2ttdf5MTLvkblL8bd+5ho6IrJ51whRuxTtesWSPEXk6otaJrNr8QDbG2LZZFN0RNI38wcLt+9dVX9OGHH4o1Eum2evrpp11Exchg7k105Y\/FiMsa16o\/aq3omhUj7XqT1tKQVqq69oRBCBbQ2LFj6aefftK17OSAoF6rDhZaAVbrrR08pVXgbgLhbk1XteCMtpO0HKwy9nafOinxxk7LRJ3MeBI87ZquNwtKZaMVXe3yg6fJj6yTJ9HFNbIveWvn7du3Cw+Ju76njbnQ9lWj7mUj9VDX6b25hs2Irt7vy9vQ52kJwVtbe8s7mr9n0Q1R66udFiIIyxauKgw2EFytQBodzD0FUmldkp4sGOnKlOKIAUC6kbVuZ7PuJtXVK92g6mdqvaSgaYVD8pGDqzqoqIMFXO\/aAV3mr50IyM+1z+dtkFfra7Sd9ET3k08+EVnpBb14CqTSu8\/MhCWQoqt1l0urLZii662dsSQjXeR6fU8rujKASlqNekFnMh\/tEoleoJPsb6iHtv09iWUoRVfraQrRMBqWxbLohqjZ1B8MBA5BGViLhGt5wIABdPDgQb9bup5EV7XipBDqzWbVAUZd17US0KL+cOFKdyc4+FyvLvL+SZMmiSAtvYhtb6JrJgLYyOQi3EXXrHtZdT3quYwRrS7d2qGydL1ZZUasajlM6Lmq9Sxd7XKIuz7sacIm79Fa4eqkUe2\/ngRaO1EwMux5snTVSZ3e7gsj+UfrNSy6IWp57ZqcXMdFwAsGMu1M0uhg7snS1VrPWgtHXafyNkh4Wm9U8zUamAMXnycB1Bs4ZR2wZWP9+vXCDY0BQFs3d1tbzM7WAy26Zlz4gXIve2ovb1y1ddKKRahE11s7exNl7RDhztJVt9bI35q6tmylHp4mBEYtXauR5p7u8\/YsIRpWw6JYFt0QNZP2ByPdq2qwi7q2huvVfb34DnsoEZkpo5e9relqA6nkwIC\/tWvIMohDupe1gqD+6HC\/lUAqvWAWNXjGm7DI+sM1qK4Re4vW1FrIahS0p8HEiOgabSc997J04UvrURVARKH7EkilTmi8DcKetgzJwCltXbWTNL3AO7hWQ+Fe1lsb1fZfNRDN24TT6Jqut2AzlKNXD9n+\/gik8rYu7Gn44zXdwIgDi25guHrNVSu62sHeXXSuPKwALtVFixaJAylU0cVgLtewMMBpt89og4FUsVLXVfE5IqsR4au35cLddiJ3hxPoHY6hvVZ7jVo3d9aIHJi8HdygPptady0PT3ujjYiudn3PUzvpDe7u1kDVCQaeFUlPSOVavHbLkBnRRd56QWPeGKtthDzUwzXQFxE9KyeO6ho9tgwFMpBK73m07eyp72l\/zGail2W+2shs2U6e6oHvMMlxt89Xz9LVWzPW\/s6MWvaeRNeKu9rroBglF7DoRklD82MyASbgHwKetgj5p4SUXMysN\/u7bHf5QYxl7Amv55qnzqJrnhnfwQSYQJQTkFv7rByvaAadHUUXljKSkT2\/Zp41Wq5l0Y2WlubnZAJMwK8EguFitZvo8tnLvnchFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOTIAJMAEmwAQMEWDRNYSJL2ICTIAJMAEm4DsBFl3fGXIOdiLQsyfRyJEpNVq7lujpp+1UQ64LE2ACUUyARTeKGz\/iHn3GDKJWrYggtJUqEb33HtGmTUTff09UpkzEPS4\/EBNgAuFHgEU3\/NqMa+yOAKzc+fNZZLmHMAEmYFsCLLq2bRqumGkC0rVctKh74VXdz9rrVEsZLul164hq1SKaPp2oZUsi+X2PHg4XNv4eMYJo3z6if\/6T6OhRR5Xl5\/j31asOi3vu3NTfmX5AvoEJMIFwJ8CiG+4tyPVPIaAVvyZNiKZNI8qc2XGN1hJWRRYCvHChQzBhLT\/5JNGWLUSNGjkEtmHDlO\/btiX6978decoycR0EWBVqfAbBPXyYaMUKorNnHeLcv79DxDkxASYQdQRYdKOuySP8gRMSiOrVcwgmEsQTgoeEz2G5QhyR5LX4DEJavLhxOEeOEBUrlmL96gVsaQVZWr0oRZ0MGC+Vr2QCTCDMCbDohnkDcvXdEFCtXriHq1Z1WJnSIlVFt0QJor59icqWNY5Tiq6ndWSt5S1zlxOB3LmNl8dXMgEmEBEEWHQjohn5IXQJqK7eV14JvaXLzcQEmEDUE2DRjfouECEApKsYjwN3MqxIbWCUtzVdK+5lxYWc1KcP3X\/wIGV+7TXHuq27NV3V2o4Q\/PwYTIAJGCPAomuME18VDgS067mos3at1V30clycpTXdmzdv0tn16ylrw4aULTHRQclT9LI2uCscuHIdmQAT8BsBFl2\/oeSMwpqABdG9nDs39ezZk06dOkX58uWju3fv0pgxYyhLlixhjYIrzwSYQOAIsOgGji3nHCYELl67Tce276fYGrGGa7xr4y6KrR4jrr99+zYNGTKEypYtS2+++aZuHnv37qXz589TlSpVKG3atIbL4QuZABOILAIsupHVnvw0BglAaHedTKLjidfp2PnrlD3+BLVt9pTBu4kmz15PFx8qRNVL5KAr507RrAkf0\/Dhw6kYthEp6caNGzR79mwaO3YsffDBB+JPmjRpDJfDFzIBJhBZBFh0I6s9+Wk8EIDQ4s\/uU0m06+RlcWX2TGkppkAWir11jrKXLWmY38W9h2jTnewin79+X0PxB7bTRz370xPFHxR5Ih07dow+\/vhjYQH\/+uuvwhVdvnx5w2XwhUyACUQeARbdyGtTWz7R4cOHafXq1dS6deug109atbtPXRaiC1EskisjxRTIKv4WycKaLg7HiD+fRB917U4FHn+G8pSuJLLKlvE+urR\/I+3\/7Wfq3LmzcCt\/\/fXXNG7cOF7vDXrrc4FMwF4EWHTt1R4RWZvk5GSaPHkyHT16lAYPHkzp06cP+HOKddrz14VVi79Vq7bGIzlTl29RdPft2yfWcyGombLnpl\/3HacJY0ZSpmy5qFaDZvR4sQdp9fx\/0yPFi9I777wT8OfmApgAE7A3ARZde7dP2NXu7NmzIlAoZ84UYdu4cSO1b9+eypUrR5MmTaJs2bIF7LmkVbvp8AWn0Kayat2VDuE1mu6t3c6YMYNOnz5NPXr0EM+9Zs0a8e+YSjUoplYDSrydjtbMGkF13ulEz1Z5nHQF32iZFq67cuWKsLIXLlxIn376KZXhVxxaoMi3MAH\/EWDR9R\/LqM\/p8uXL1LVrV3r55ZfppZdeEjwOHjxInTp1ombNmtF\/\/vMfYekWLlzYr6z0rFoptLEFA7d959q1azRr1iyqVq2amFDIlJSUROvXr6cvv\/yStm7dSqVjytPjr3ek7HkLiSAqBF8VyZUpxbXtVxqOzCC2S5YsEfVDfZo0aSImPpgYINoan6VLl47d3QFgz1kyAU8EWHS5f\/iNwLZt26h58+b00UcfUct7b9HZuXMn4QAJWFgIJGrVqpXbYCK53mqkQh6DogpmdQYzGckrUNcgcrlfv3504cIFEdX8bruO9PuJq6mCuPxp\/WIisGLFCvrqq6\/o7bffpowZM9K8efNowoQJlDdvXjEJ6tixo3jkO3fuUM2aNUV78d7iQPUCzpcJuBJg0eUe4RcCWLf97LPP6NChQ5QjRw4hNup+VLmXtXLlyk4rWC0YIrrpcCLVjcnjsT6GgqL88kS+ZwIWffv2FQdmqNa99hlQkoyi9ibAMupaa8GD\/08\/\/STa4I033qAGDRoIaxaBXG3atKGn8X5gIoKr\/+LFi1S3bl0husOGDaPSpUu73V\/sOwXOgQkwAZUAiy73B78Q+Pvvv0Uw0YsvvkiLFy+mESNGpLKesP559epVsVdVK7jztp6m6iVykp472HRQlF+eyPdMsL4NS79WrVpuD8TQW4MWW5g8WOuT1x8X25xUgU5ISKDevXvT8ePHhSsfFizWcpEgvO4O5Jg\/fz6dPHmSunTp4vsDcw5MgAl4JcCi6xURX2CEAAKI4uLi6Pnnn6f+\/fsLCyp\/\/vwut+KaH3\/80SWCGaIDwUVq+5TrWq9PQVFGKm2zazb+leg8rMOT9Qtrd9Xus2JNuHGlFMawdiG6mPQsWrRITHBwYMdzzz3nIrrYP5wpUyaxlQmR15gE4aQsTkyACQSeAItu4BlHfAlYu4TINmrUSJxBjMCpSpUqUfHixV1cybt376apU6eKa7GGCFGF1YYECxeuZXdWrTsrOBLhaicbeEZt8NXIH46IR9cKLz5LTEwUbYBDOeBCfu+99yhPHofbHuvrWO+dOHGiCP5q27YtVa1alU\/JisSOxM9kSwIsurZslvCqFPaqIlgH64gLFiwQUbMvvPACdejQgUqVKuV8GFhhU6ZMEVtqdsZjDdexrUeKyqXrOJpRc1KUTYKiQtUicq1by0XLSnoJ5J7oEydOCI9DhgwZaNWqVWJ9V54LjWuwdQuR1FpXf6iek8tlAtFCgEU3Wlo6gM+5bNkyp3WL6OQ\/\/\/yTChUqJCxfvQQ3KgT3xu27FH\/pJkFAsEape1JUAOsdTllrg6\/OJN0Uh37kzZpeWLtgB08B\/o31XRxAIvdDYyIE1z8mOzJhfR0WMa\/lhlMv4LpGAgEW3UhoxRA\/AwZ5uJgLFCggrCdYurB+e\/Xq5eK2hHD8fvQirdqdQBAN\/B8pQ9r7hHu5Y+2ittjqE2KcHouX4rvkjzN06MxVJz+Ib8m8menV8g+l2v+LIzj79OkjtgbFxMSIc6AR6DZ69Gg+C9rOjc11i0gCLLoR2ayhfSi4kRHEA9eyfKMORHb1\/nM0b+vfTqGAdQaxkC8IwBew1GCxqZ+F9mnsUbreNiPVU6BOYFpUK5Bq6xWCp3AU56ZNmyg2NpbatWsn1nw5MQEmEFwCLLrB5R1VpcmgKFi3aw6cF5YtrFoIK8RWm1Shxb8RPOV8IUFUkXN9WKzn4gxpKazyb\/UqKcB4VSESrN4Gj+cN+MlXUdws\/OhMwBIBFl1L2PgmTwTkiwa0wT+BPvqQW8VBwF3wlbeDN5gfE2ACgSfAoht4xlFRgruTogrnzKR74EVUQAnxQ7o7+Sqatl+FuAm4eCaQigCLLncKywTC9aQoyw8cxjdaOfkqjB+Xq84EbEuARde2TWPfikXbSVH2bQnzNZNth7VfQ+8ZNl8E38EEmIAHAiy63D0MEeCTogxhCquLjJx8FVYPxJVlAmFAgEU3DBoplFXkoKhQ0g9e2e7amYOvgtcGXFJ0EGDRjY52NvWUHBRlCldEXczBVxHVnPwwNiTAomvDRglFlTwFRXl6zVwo6splBocAB18FhzOXEl0EWHSjq71TPS0HRUV5BzDw+O6sX+07fQ1kxZcwgagnwKIbhV2Ag6KisNH99MgcfOUnkJxN1BJg0Y2ipnd3UhGfFBVFncCPj8rBV36EyVlFDQEW3Qhvag6KivAGtsHjcfCVDRqBqxA2BFh0w6apjFeUg6KMs+Ir\/UuAg6\/8y5NzizwCLLph0KZJSUmillmzZvVYWw6KCoPGjJIqWg2+MtrXowQjP2YEEmDRtXGjYgA6ePAgbdu2zVnLChUqEP7IxEFRNm5Arpog4M76VWMJjPR1xskEIoEAi65NWxGD0IoVK0jO\/NVqwuKt+eyL9OeZ28Svz7NpA3K1dAmgvx5PvObSb8s9lJbitq9129fr1avn1cvDuJlAuBBg0bVpS61du1ZYue7SzSwFKG2hcuIl79rX50Go06RJQ1myZLHp03G1op2A6n6+fWInpb98yi2SUqVKUa1atXS\/574e7T0p\/J6fRdembTZ16lSvNXuzaUvKnimtuO7mzZt06tQpWrp0KS1ZsoQ+++wziomJ8ZoHX8AEQk3ASF9v3bq1s5rc10PdYly+LwRYdH2hF6B7MXufN2+e19wbN24s3G6XL1+mnj17CtHNly8f3b17l8aMGcOWrleCfEGoCfizr9+4cYNmzpxJsIyrVq1KmTJlCvXjcflMIBUBFl2bdgpvs3+ILURXTbdv36YhQ4ZQ2bJl6c0333T57sSJEzRt2jR66aWXqHLlyjZ9aq5WtBBQ3+ubtGO5x8e+mzYT0SO1CMdOynPA9fo6PtuwYQN99dVXtH37dqpTpw698847QoTTpnV4hDgxgVATYNENdQu4Kd\/bmq7eOldcXBz16tWLhg8fTsWKFSMMQl9\/\/TV9+eWXdObMGXr44YdpypQpwhrmxASCTUBG2msDqTIn7KHrCcfcVuehwg9TusLlXIKvcicn0reThzv7uvbms2fP0urVq2nSpElUqFAh8Xfu3LmD\/chcHhNgSzec+sDy5cvp9OnTqaoMK1cvohPXY6YPazdDhgwEd9vu3bspf\/78tHjxYkpOTqYPPvhABFlxYgLBIuDuVLSYAllFICCSkb6u5rNtw490fO\/v1KRdTypf7EGKLegaNHjp0iWaMGEC7dmzh3r37k3\/+Mc\/uN8Hq8G5HI8E2NK1cQfR7l2E2EJAsU9Xe1DGtWvXxLpu\/fr1qXbt2i5PlZiYSJ06daIPP\/zQZY+vjR+dq+YjASwnfP\/992Li9cILLwgXazCTp1PRajyS01kVXIdgQLN9vXPX7vRYtefpSu5YkRfykO7ny+fjhccHnp3OnTtTtmzZgvnoXBYTYNENxz6wavdZqhuTx1n10Sv30mNF8zg\/k7N+OYDt27dPWLjjxo1L5T7+7bff6PPPPxcuNh6AwrE3mKvzxo0bRVs3a9aMLl68SDNmzBD9IhjR7FZORVP7Ou6fuuYgVS2dn2TflgIurVm1r2fKnpt2nUyi3acui0M4rl48R2tnDaPqNWvR4G7tgrqWiyUciDyWb15\/\/XWqWLFiUMs310v46lARYEs3VOS9lItDBHafSqLGlfKLK0f+cES40CDEGFzmbT0t\/i3dcxhY4Yru0aOHyw8d67ojR46kwoULi6ASTpFHAF4OrOeXKFFCbB2Dlde8eXPh1cCSAgQYSwpYWghE0rNq0S\/hPta6ffXKh+giD\/R1\/D15\/XGqXiKHEF28yQjft32qsPNWd3391NkL1KNPP7qWPhdVqNuUcmbJ4BJ8FYhnl3miDfr16yfWjxHIOH36dIK3oWvXrtSgQYNAFs15hxkBFl0bNxiEFoMXBiMputVL5BSDkvwc1ccPftasWVStWjUqV66cyxP9\/fffYvaNAaFMmTI2flqumhkC2BZ26NAhsS\/7m2++obfeeovatWsnto916dJFrGOWLFlSZAmRunr1ql9FF+KIP5gYak9FkxHGRp8HwopJJPo0JpJSdLNnSicE10hfx+Ri8uTJ9Ndff9GgQYPoyEVKdfIV3M+qa9to\/bxdh7LRBlu2bKGBAweKrXr4LD4+nu6\/\/37KkyfFY+UtL\/4+8gmw6Nq4jTEQYUDCehUGuLxZ09OZpJuixhicjFgRK1eupB9\/\/JFGjBjB+xZt3NZmq4aIdOzlbtmyJb344ovONX4M9rB2EUiHhPV8eD+wnu\/OvSzXVY3UwUhQlJF8tNdAaNU+niHtfXTj9l1xGSad0qPjLm+4nGFVwo1eunRp52V6L17A70Z7ipuVOst74M5v3749pU+fnjJmzEgtWrQQkyDZBtq8z58\/LwQZ9bzvvvt8KZrvDUMCLLo2bjRYEJjpI\/1+9JIQ35J5M4u\/VXebu0dAEA0s3Jo1a9LLL79s4yflqpklsGDBArpy5YoQXU8J1x04cEBYvnp7VTf+lUjqiwf08jIaFGX2GdTrZV+H0OLfmGBCaI329TVr1ggXO5ZQ3O3J9eW1g9oYC7Xu+J1BSLGWe\/LkSSH+EF3tbw7XzJkzR8RXtGrVSnigeP+wL70mPO9l0bV5u8GtjLTp8AUxEEF0VXebt+rfunVLrOfxj9sbqfD6Hh6MXbt2iZOX4MWAdYtBvG7dus6tMRAArO9i4iVdzepTQnARgORuAmclKMoXiujrEF1MMAvnzCj6uYxj8CVf7b1WXjuIicCmw4nC6pZHr2JZB2KPZZ2cOVMisufPn09Hjx4VHgYkRGbPnj1b7BuGdYtJENbZCxYs6M\/H4rzChACLrs0bCjNsxw8+RXSNuNts\/lhcPR8JICIdFtVzzz0nopQPHz4sxHf06NFUvnx5saaINc7MmTML6w8TL0zAMPm6dP2OiPhFn5IBS7I6vgZF+fJYWE45dOaqi+gGuq+bsX4xKYDgygBGTGqwfo5dA3JSg8DFYcOGicNpXnvtNXE4DSZIcD8\/9thjziA37bY+X7jxveFFgEXX5u0lg0yk6FYsmo0axjwg3FONGjVKddyjzR+Hq+cnAjt27BCHP+APrCxtlDIi2bFvG4E9169fF5YW3K8jx39Ke86RmMiprlv0M38ERfnyeKjTkj\/inaJb45EcwrKEWxb9vUiRImJigYRng4WpPe7Ul\/Jh+V+6nvp1mTL4Sk6AUQbqlSPtTfroo4+oTZs24mhVBLctWrSI5s6dK+o3YMAA8RuFqxkBVXgJCbYV9e\/f3+16ry\/153vDgwCLbhi0E4JMVu1OEO7lV8vnpSoF7hcz7AsXLjgHInm4uxygqlSp4nRvhcEjchVNErhz5464A4O5TFi\/hbDCrQlLGGKASFpsY4G1+3jlarR8n2M\/K5I8UELuccX\/5VYfb4FLJqtr+PLBKw87RRdu70dy3a8rsHhWuM6RELGPLTq5cuUyXI6nC90FX+EeGamNf8PivX5qnxBXWLH79+8XngVYvjhyEhHNWMMFf\/wecbTr+PHjhRXMKXoJsOiGQdvjh97nu0NCdPu\/VIKy0FXnthAc7L558+ZU0cnYm4sk15XC4DG5iiYJJCQkiKhlGSWrbg3atm0b\/fzzz+KlGNijDZcy3LeIfoeo4G+sm0JopfgGYjuNyUeixTviadavp8T+2mH\/KimsXO0WKOSpfo7\/w6U7duxYvwmvrLfW\/Qz3NyKrH8qWXvwN93zlIg+IrVpw4aM91PgJuJt37twplgJQZ+yVxnIAIp05RScBFt0wafdXPt9BcC1DdLUDEWb9WuHFHs5ADURhgiyiq4ngHBztiSMe33jjDRGcg\/2pQ4cOFYdkqAnCMXHNUYq\/dJOOJ14XX0EwMImTLly7wJITTIhZjzrFxR50uGoxeYC1KBM+x7NCwAIpurI8uN9n\/XpSWLpyK5Nk+FJsbpfT41SWcPsvXLiQ\/u\/\/\/k8IL1zQHEBll94Wmnqw6IaGu+lSm87cRbVL56IW1Qrqzv5h2eJ9unI\/rp4Qmy6Ub7A1gf\/+97\/Cxbp161YhSFi\/Vc9Yhtjz0inVAAAgAElEQVQi4nbe1r+dLmUIBVzHEFyZ7GTpos7vztlDLaoVcAoZXOVNmjQRbxSSa7j4DH0ebuVz584FbIKJ+mAtF6IrE0RXO4HBhBjucBnZLK\/F244wGcI+6WCff23rzhvFlWPRDZPG7730kLBK1POYtVUP5DpXmGDiahIJgUBQ1MpdCcKylRaZdImqYqsCc4ivsaMbAwUaIoco4boxuV1Oj5KxCnDVIhUoUEC8sB5Rw4Hy6mjFFuXK9XDVAkbwlTxgBBZ6oE6+ChRzzje4BFh0g8vbcmnq2cuWM+EbI5ZAoE6KCjYw7dnLwS7fannatV\/k4++Tr6zWje+zFwEWXXu1h9vaaEUXs3scNzdmzBjhWoSrDS+o11oBYfJ4XE0LBIJxUpSFavl0i57oynVdWLfhEBhoZu+vT7D45rAkwKIbJs2miq4chOQ+Re16rlaQw+QRuZoGCQT7pCiD1fLLZXqii\/6NbTZ6e3K1fd8vlfBTJlZOvvJT0ZyNjQmw6Nq4cdSqqaKrRi9jD6BedCcCTXAgPr\/oIEwa2Es13Vm1eOuUkRdfhAsFrei62zLk8tsIg+1xbP2GSw8MfD1ZdAPP2C8laN3L6j5cPUsgUMElfnkYzsQwAXcnRXl7SYHhAmx2oRHR1U4ow62v4+QrBLjJiGg7RY\/brDtEZHVYdMOkWfUCqSC2y5cvF2+QwZ5cub6LR+LDMcKkYXWq6S4oyp+vo7MrHT33snb7m+z3Mno5XLfH6QVfIfoZ7xGOJO+FXftaqOrFohsq8ibLdRe9LNd3Ib5qwhGA4RB0YhJDxF4eiUFRVhrLXfSyuh0Or8yrX78+vfvuu6IIdfuQlTLtcI\/cUy2PmZTWb2zBrKn2\/tqhvlwH6wRYdK2zC+qdvGUoqLiDVlgkB0VZgRiuW4asPKvePRx85S+S9s2HRde+beNSMxbdMGkoA9WMlqAoAyhSXRLtoqsC4eArKz3I\/vew6Nq\/jUQNWXTDpKE8VNOdCzFSg6KstBiLrj41Dr6y0pvseQ+Lrj3bJVWtWHTDpKE01YzmoCgrLcai65kaB19Z6VX2uodF117t4bY2LLph0lD3zueVW32020I4MMa7qOD90YjitcOrBu3c69x5TpibnVuNiEXX3u3jrB2Lrv0bioOifG8jtnTNM+TgK\/PMQnkHi24o6RssG+9Oxez\/saJ5PL5lyGB2fJlBAuCOhBeTu0scFGUQpsHLZF+vWjo\/W7oGmamXWQ2+MtLXLVSHb9EhwKJr426BH8LBgwdp27ZtzlpWqFCB8IdT4AgY4c5BUf7lb4S5f0uM\/NyMBF8x9+D3Axbd4DM3VCJ+DCtWrCA5A1VvguVVr149pwWWnJwsXmCfJ08eSp8+5eXkhgrii1wIeOOes0wNirvkeK8qDjDAC+Gj4aSoQHYTb8zVvh7IekRq3u6Cr4plI9qw+j+GxphIZROK52LRDQV1A2WuXbtWWLnuUqlSpahWrVri60uXLlGfPn1o\/fr11KRJE\/rXv\/4lXu593333GSiJL1EJeON+M0sBSluonHhRuTYoCuKRJk0aypIlC0M1QcAbc7WvY4K5Z88e8RrLW7duUcOGDal69eqUIUMGEyVG76Wqh+aBc3so\/eVThsYY5u6\/PsOi6z+Wfs1p6tSpXvNr3bq1yzVnz56lJUuWEI7MQ2rUqBE1btyYRcAryZQLzHK\/efOm8DIsXbpUsP\/ss88oJibGRIl8qRnmeNlB3759xZu1SpQoIcQXE53+\/ftTpkyZGKZBAhDfBXNmeL1ajjHM3Ssqwxew6BpGFbwLYTHhtXzeEgRVG+SDGekff\/whLF9Ywh07dmQrwBvIe9+b5X758mUx+EN08+XLR3fv3hUvnVAtXZyNfefOHZ74uGkDs8yvXLlC8fHx9PDDD4sc4eXp3r074azx8uXLi88wEcIf9ji47\/iB4I7fAxJz9zzgsOgaHJCDfZm32T\/EFqKrptu3bwsr94svvqDhw4fTk08+KawATsYJWOU+ZMgQKlu2rPNF62iL2bNn0yeffEI5cuQQL2H\/+OOPqXDhwsYrEyVXWmEu0SQmJoqJZYcOHUSA4bJly2j06NGUNm1aZu6l\/\/iLOzw7n376KX377bdCcMuUKSO8EZiIckpNgEXXpr3CzDoXHgGDPFybmzdvFtYWD+7WGtYsd5QSFxdHvXr1EhMdiCvSvn37hMtz1KhR4jPku3jxYnENWwKubWOFOXKA1Ttx4kTBf+zYsbR161aaNGkSjRs3jooWLUo\/\/fQT\/fLLLzRw4ED29uj8HPzFPSEhgRYuXEjvv\/++8LyB+7p160T\/57V2Fl1rI3GI7sLr+k6fPp2qdL3o5W+++UasKU6YMIHy5s0bohpHRrFGucunxfUbNmwgWLtykIEAzJkzR4jsAw88INqxW7duNGDAABHkxsmVgFHmWD6BexkWLfjWrl2bOnXqJDLD382aNROfISHGYfDgwTRo0CDKlSsXI9ch4Cv3nDlzpsoVAaBDhw6l8ePHM3cd5mzp2vinqN1DB7HNnz+\/cKOpa7kbN24UL7GH4CLSk5NvBIxyRynyfcZ4v6sc7OWAD+urZs2aVLlyZVq1apWwxEaMGMGWrtI8cuuVN+YQ2z\/\/\/JPwAvtDhw7RG2+8IQIF4dHBEgosq+nTpwvLVwrBkSNHhEsf7mYWXdffhBHud9NmomwZ7\/fIXeYKTxsmQ+nSpRPLW\/BCsKWrPw6x6Po2Pgfs7lW7z7qcPjV65V6XE6nk3rvS2W9Tly5dxABUt27dgNUnGjLGC8Tl3ls8Lw4X+PXAaWpdu5T4XJ4+FVswZUsQ3MiwcOHSxBoWxAFeh8mTJ9MLL7xAFy9eFO42GUmOF65zciWg9nUwnrrmIKknUp1Luk6fT\/mCVn7zlRBRBAhizVYmMIewZs6cmT744APn52vWrBHeH0x04G3glEIAfVt9uxXaYM\/Rs9TtpbLiIrTDkbOXaesPi8RkRo+7yhNeBfR5eCBatmxJb731FmXLlo2Rs6UbPn0AArD7VBI1rpRfVFo9exk\/iHlbTwtR3rbue\/rhhx9SRc2Gz5Paq6bgDOY49AID06bDF6jtU47gp10nk+jS9dsuk6EZM2YI13GPHj2EEODfcHP269fPuXUIVu7vv\/9OvXv3dhELez156GqDAR99Gty1Zy\/jhRFL\/u8oZT6+nmbNmkUZM2YUwWoNGjQQh8EgIWq2c+fO9N5771GlSpXEZ7C8MBnCtqJ33nkndA9n05LVMQR9HW2AMadHneKiDfD\/3BnuUNyW791yR+Q4PBTwvskzAeCuxvYitnLdNzxbujb9UUihhYWFQV+KbvUSOcU5zPihYJDCNhUcEsABC\/5pSDn4gO2x89eE6Gr\/DfZIcC1DCKpVq0blypUTn8H1CVc\/XMvSpan3mX9qGxm5QFgxiQRXTCTlW4ayZ0onBn+1rx84cIAWLVokImUrVqwo1g5xChu8PZjUyPVyveC2yKDlv6cAc7BH\/8YEH6KLsQafI6EtwB5jjB53CK62r\/N6rvf2YdH1zihkV8gfhXRtZkh7H924fdf5g1DdnCGrZIQVjIEHAz1S3qzp6XjidfG3XAOTVq+7x\/7777+F1QUBkIdkYPa\/cuVK9kZ46CsQWjAG6zNJN0nt69LzoN6OfbgnT54Ua7qYdIL3yy+\/LNbVYeVCDLJnz07t27dn74Ib7mpfxxgD7rKvy4mO9laV+4ULF8RkBwGC6Otw8yOKGRHj2v3qETZM+PQ4LLo+4QvszeqP4vejl8S6Ysm8mcXf3gb\/wNYssnOXAgArAAMRJjcQAaPveN2yZYuImMU+6Rs3boggHwQA1ahRI7LB+fB0sq9jUol\/Y\/DHwG+0r+\/atUvsDX3iiSfo8OHDhLVz\/J+3Z3luFHjQhIfmzFUx6alY1LEOqzfR0csJQZzYkoWAQWwd2rt3rwjojI2N9aE3RPatLLo2b1\/5o4CbEwMRRNfdLNTmjxI21ZMuZoguLF0MRGAv3W1GHgSu5\/379wsX9KOPPsrRswagoa9DdDHBLJwzo+jnmPCAu5EkmSOCFszVYCsj90fjNbKvQ3QxwcTE0uhER\/KS3PF\/cOfjOD33JBZdm\/\/S5I9CFV2js1CbP5ptqyeDeVTRxWRHBrXZtuJhXjEsp2DwV0WX+3pgG1V6GFTRNTPRCWztIjN3Fl2bt6sMMpGiC6vLnWsZATuIZFa3Tdj88WxbPQjAxr8uOC3d5lULUha6Sq1ataIiRYqIbShIOHsZgVSIqOXkGwEIwJI\/4p2iW+ORHCnR+yNHipcbqAnnLSNqnJNvBLCcgomOtHR5ouMbT293s+h6I2SD7\/GjWLU7Qbg4Xy2f1627TR7UgDOZq1SpYoOah28VIADgDvdy7dK5qE21vLoCi7OucQQkEiKYsaeRD2Kw3u6DVx52ii4ml7C6sB6OJAUWW1K6du0qJkDYFsTia5037oQ3bfGOM0J068bkpoYxDwi22Hs7c+ZM3RPUOCLfOnMWXevsgnYnBKDPd4eE6PZ\/qYTT4tq5c6eoA44alJaWHJDc\/ViCVukIKKj9vH1CdJtXLUC1iqZLtS0Fj3j+\/Hnn5\/i\/dgtFBGAI6iMs3hFPs349Jd5XPOxfJV34qsdnYrKDbUEQYq0oB7XCEVAYllO6fHNAiG73F4pRjUccRzuib0N8Mc4gMhzeHbley6JrveFZdK2zC+qdr3y+QwT0QHS1SbW21O+0P5SgVjgCCpMehrGvl6ZCWdMIS1frRYB3AXtFceYvi67vjS4nmAjowUEN7rw3mFzi9ZcQghMnTvBkx0f08DCAPfq63IeuZgneTZo0cYovM7cOnEXXOrug3tl05i7h5mxRrWBQy43mwmB1zdv6N33R9DER0SkHHq1nAZYW3Mrnzp3jwd\/HDgOr6905e6hFtQLOZRTJfe7cuWLZRAoxtgXB0sWkE2\/XUi0xH6sRdbfP3HyS1hw4T3NaeN7qIyf4OHFt\/fr1LofARB00iw\/MomsRXLBv6730ECGwxOj2iWDXLxLLwzGQS\/44I7wLEF2tyw3\/x8AvXfnscvO9F0B0sXUIa4vSzYlcwbZFixZ06tQpUYj04sD1ifVdXk7xjT3WdRE4CJe+tyTdzriOYxi80Ur9PYuueWYhuUM9ezkkFYjCQtWzl6XoRiGGoD6y9uzloBYexYWpZy9HMYagPDqLblAw+16IVnTVIAfkrro8fS+NcwABrehK5rxlKHD9Q090mXvgeMuc9UQXyya8Tcv\/7Fl0\/c80IDmqoivXtOT+UPn\/OnXq0LRp03SjDQNSqQjPVBXd9HSLtwwFob21oqvt67IKvFXLv42hFV3epuVfvmpuLLqBY+vXnFXRVbepyG0UWPPq3r07jRo1Suyr4+AS3\/Gronvn2iXeMuQ7Uq85aEVXr68jE96q5RWlqQtU0XXHnLdpmULq9mIWXf9wDHgu3kQXPxRYuR9++KHYS8dBPb43iZ6ly1uGfOfqKQd3li5zDyx3VXR5m1ZgWbPoBpav33LXruli1jl\/\/nxn9KB2W4W6j5EPILfWDNo1Xd4yZI2jmbv01nSZuxmC1q7Vupd5m5Y1jkbuYtE1QskG1+hFL6vrWthC0bJlS\/H+UGyrULey2KD6YVkFvehlbQBbJG8ZOneO6K23iIoVIxo\/nihTJkczHjhAhKOmX3uNqGFDx79x6qi8Rn7frZvj\/iFDiPr3d+0CdeoQff010YMPun7uLnoZ3GvU+IH27WssbsiX7zv68cfHKDb2kVReHW15gwcT9evnWo6ZOgWz84aCOZ5PL5AK3rLnnltHx469KxDExGyideueoIMHU2\/TCmfmwWxflMWiG2ziFsvjLUMWwflwG28Zcgjmt98SLVhAVLq0AybE8u23if73KlXKndshujiRFP+vXj1FlFXR3bRJX2S1zeNOdHE\/XkeslinzV\/O4do3oo4+IChZMLbTuuoLM+6uvHJOEUKdgM3cnutHEPJhtzqIbTNo+lMWi6wM8i7ey6BLpCRJEQYpoQkKK6ErrVX5mRHSlZQexhjVqZJ+u1pJWm1fm17SpMQGVIo08VGveYpfxy23BZu5OdNWHiXTmfmk4g5mw6BoEFerLWHSD3wIsukRad+fVqw4xkyIpB+NHH3VYw7AWK1Z0CHEgRFe1vlAHbZL1ufcuEHLnxpb3ecsv+L0u+My9ia43RpHAPJjtzKIbTNo+lMWi6wM8i7ey6DrAqe5OWLHSzau6ktu1I9q+nSguzmGxtm\/vKrraNV13rlxYupv6TaBsbVu5HAOpZ81K4Ve\/g+t79GjHBACub701afV61WrXri9b7DZ+uS2YzKXo0qzZVHdMV936az0SkcjcLw1nIBMWXQOQ7HAJi27wW4FF18FctXTWrElxLUOkVLejtHAfeogoPt6YpZuqVaHaxYvTxkPn3YqunAgYWSf2JKqehCT4vc21xKAyx+lrq\/+gGs+VJ0pOdvvoRico4co8WG3Oohss0j6Uk5SUJF6o\/ljRPPzCAx84mr311wOnxVGQrWuXcr7wwGwekXC96mKGJqoWpqdIZWnNGh2sBau1a4meeYYufj6Nsr\/viJrVJjPrsJ7K9uY2DWXbBZU5Ee2au4Ji33qZaOZMoubNo5J5sNqbRTdYpC2UA7E9ePAgbdu2zXl3hQoVCH84BY4Ac0\/NVt0SIqOUcZVWdNX1PSOim8rafOYZh\/Bi4IcA3Euq2xgfyTXjV191RCsjIRBq8eLU7mVMErp2db0O25\/UPGVkduB6lfmcg8YcVdPhHo3MzbeS+TtYdM0zC8odGPhXrFhB+FubsmbNSvXq1SP8zcm\/BJi7Pk9pFWoDk\/SiWuWWItOi29ThWnYmxdUprdspUxzfyr23WqsX30GE5XVt2jjEWH4uxTkcRDcozLF\/+Z5LX8s9Gpn7dzTRz41FNxiULZSxdu1aYeW6S6VKlaJatWpZyJlv8USAuQepf2Cgh3WlTfhcJpzKoSb8v1mzVO5PCP\/06USDBqUc4KH3FEavCxKB0BTjJ+5GWRq9LjQwQlMqi25ouHstderUqV6vad26tfOakydPinOXK1euTA0bNqSiRYvSfffd5zUPvsCVgFnu6t2wktOkSUNZsmRhrEYIQABatHC4k70lTDBnzqTkokVpz5494pVzt27dovr1G9HPP9ek1q3vdx7eoZcVrLYBA4hatUo55MNbkRH7vY\/cwfLy5W7Up08+io1N7xYTM9dHw6Jrw18WBu958+Z5rRkOgYeLOTk5mSZPnkwnTpyghx9+mL755htxb7t27QjHQ3IyRsAsd+R68+ZNcezm0qVLacmSJfTZZ59RTEyMsQL5KgeBgQMdZqpektYtriEinAnct29f8ZrFEiVKCPHFRKd\/\/\/7iRR+cTBBg7iZg+e9SFl3\/sfRrTt4sLogtRBdp9+7dNHToUBozZgwVLFiQ7t69K86jxd9lypTxa70iPTMz3C9fviwGf4huvnz5BG+0gWrp4hoktn699JxZsxxWrzZpommvXLlC8fHxYnKJdOnSJfFKyzZt2lD58uUjvXv6\/\/n8yB1vJ7pz5w73dS+txKLr\/27slxyNri2io\/fr14\/Onj1LlSpVourVq1O5cuXYtWyxFYxyV7O\/ffs2DRkyhMqWLUtvIqyWiNAun376KX377bdiEMLkBxYaxJnTPQI43uq994jmznWPBF6D3bsd3xctSvT990TKRDIxMZE6duxIHTp0EP1fJvD\/4Ycf6JFHHmHPg0rXCHNcj1NFEMiGJaynn07VPip3THZmz55Nn3zyCeXIkYOKFStGH3\/8MRUuXJi7ug4BFl0bd4vly5fT6dOnU9VQjV7GTH\/ZsmX04L3jdGbNmkVVqlQRg1DatGlt\/HT2rZoR7mrt4+LiqFevXjR8+HAx4CAdOXKEFi5cSO+\/\/75YAvjpp59o3bp1wg2aIUMG+z58MGsmBeDZZ4nmzBFru1dy5qH0165QuutXU2qCNV+dgR9W78SJEwn8x44dKyY3v\/76K61atUoIbvbs2WnmzJk8+OuJLpi3bJmyVQhjRb16REuXuvYAHfZa7ljWQr8eNWqU6P+YuC5evFj8HtjDk\/oHxaIbzEHGZFna\/aIYvPPnzy\/26brbLoQBqFu3bjRs2DAqWbKkyRL5chAwyx0ivWHDBmHtuhNURKJjCWD8+PGUK1cuBg0CUnTxSiCc3VisGF1c9RPtGziWHiz8EJX87WfH8VdwgSJqmWB8JQv3Miaac+bModq1a1OnTp0oZ86cBDHAujpet4hgK0xIe\/TowZNPd6ILFz0iyDFRfPFFIngKqlZ1\/PvYMYdH4d\/\/FhMeT9y3bt0q2gIi+8ADDwhDAWPQgAEDeAxiSzd8x7rRK\/emOpHq8OHDNGPGDLGuKEUY7x199913heWlutvC98lDV3OcRoVTqTydSAU3JvjXr19fCICa4HaGQKRLl46++OILIQps6SqErl6lmy1aUXpYtViPHThQvGVoc59xFHvlNBVq8i8iZVvcmRYtqNP16yJe4Y033qBGjRoJKxaBVGqSa+245mkdCzl0PcoGJaveBQgrEgKqZswgwhbFESMcn3Xv7ogWX7SI\/syZk0aOHOmWO5a24GmoWbOm2D0BTwOEeMSIEWzpsujaoNMbrAJeKl03Jo\/zau3Zyxicfvq\/PbRs+ljxg4AFjITTq9DZsZ7I64cGYd+7bNfJy+K4xyK5MopPtGcvg\/mx89cptmDKlqB9+\/YJC3fcuHGpeGMwQlQ5rLKWLVvSW2+9RdmyZTNXqUi++p4AHMpfkkqOcUQnu4juFMepFudW\/EDTdu2l8mOHUuHmzanUiBEerdcdO3aI38SkSZMoN956wCmFgCq6mCTKvdBa0U1IoOSaNWllvXr08YYNYo0W5wKoS1awfrFTAn38hRdeoIsXL4plFEyGEOQJjwOn1ATYvWzTXgEB2H0qiRpXcoipKroYmOZtPU11Hs1JS7+eRgkJCdS2bVs6c+aMcGGiw7\/++uupLACbPqqtqgXOYA7hVUUXldx1MokuXb\/tMhmCpwHuNOnGhEsT7mlMguQ+abifsdWFrVxNU98TgD9LV6Y9\/2wouKNv72vegR4s\/xiV7PkB4XewZtdJynx8PWUaNEgM+pd696YGDRpQnjwpk1KZM4QAYov0wQcf8G9A++tSRRdrujL17ElUqpRjnRcpIYHu\/POf9H2tWjR882bKmDGjCBJUuaPfw7WPQE65TQ5W7u+\/\/069e\/dmt76bkY1F11ZDvmtlIACwvNo+VdgputVL5BQvP4AoYJC6ceOGWE\/8GmfvEX4zLUUEMx+MYa1h4WHAQA+2x85fo02HL4h\/YwIkP5eWMFzLCFyrVq2aiBhHgusT6+lwt8m1W17PddMW9wTgXJWn6ItSL4g+\/UriPrrT9B3668tvKcflRDqz8Ds60rU\/NS6eTgT6HG3XjmbHxYmo8IoVK4pJpurRQVQthAB\/eAuRDnc90V23zrFmrkaG4x2OCKwaOZLu1qxJBw4coEWLFrlwx+RS29f1+r+1X2Lk3sWia+O2hTULdyaEFxZAhrT30Y3bd0WN4XpW3Zw2foywqhqEFcKLlDdrejqeeF38Df5yAuTpgeB16NKliwgkwewflheimH\/55ZdUe3jDCkwgKquzfeVyvkI0f\/AMuvxwKdHXn54xiqosnOwovUcP55ojDiXBKWxY01VdnogQxwQU7n6OnPUguuo2LZ2tWLB0peiqkeMqd\/T1zp07C6tWWrrw6qxcuZL7uoffC4tuIAYTP+WpCsDvRy+JQb9k3syGBn8\/VSEqs4EnQa7fnkm6KSY3mPBUL5HD4zteJayN\/3sNz8CBA0VgCQamvXv30oQJEyg2NjYqeRp5aNnXIbT4NyY6sHyNTHRk\/ghcw1ouhPidd94xUixf4yOBLVu20KBBg+jJJ58UXjdMetAGNWrU8DHnyL2dRdfmbSsFAG5ODEQQXelatnnVw7Z60sUMLwMs3YpFswn2cDNDBIwkuJ73798vLn300Uf5iEID0LCcAtHFBLNwzoyinxud6CB7nAiGdUZE8nPAmgHgfrpE9nX8jb7OW+I8g2XR9VPHC1Q2UgBU0ZWBPoEqk\/N1BK6poovJjgxqYz6BIYDllENnrrqILvf1wLDmXENHgEU3dOwNlYyBH4ORFF1YXQis0ksIYsBJPIja5OQbATDf+NcFp6XbvGpBypMpWezJxVYIRCtz8i8BuJWX\/BHvFN0aj+RIid7\/37Y4vNxATThvmdvBv23AuQWeAItu4Bn7XAJczKt2JwgX56vl87psWVEzlwc1YMsQjoLkZJ0ABADc4V6uXToXdXq2qFirwjF38nxlNXd8hxcfYI80v+3GOvcJq4\/SmgPnhXsZk0usp4MtkhRYbL\/q2rUrtWrVSuyRZvG1zpvvDD4BFt3gMzddIgSgz3eHhOj2f6kEZaGrYsDZuXOnyAvHr0khkAMSzpzlYyBNo3a5of28fUJ0m1ctQLWKphNRyYjUdMdVKw6+lR6ddy\/eEU+zfj1FMQWy0LB\/lSScsKbHfcGCBeLMZQgxc4\/OvhKuT82iGyYt98rnO0RAD0RXmzAA4dhHbcK7dNnyst7A0sMw9vXS9GDa66kGf0xw8N5jyZj3KFpnLe+UE0wEUPWoU1y8rQkufa33RmWPA\/e1+0V9rwnnwAQCQ4BFNzBc\/Z5r05m7hJuzRbWCfs+bM9QnAKtr3ta\/6Yumj4moZUxuNv\/vdB4psrCwsC9RehW03zNX8wSwVevdOXuoRbUCzmUUCGyTJk1o7ty5YtlECrFcW2fu5jnzHaEjwKIbOvamSu699BAhsEQ9j9lUBnyxaQI4BnLJH2eEd0FuFVK9CvAk4EUHeMEEEkSA3fqmMbvcANFF5HjdmNwue6LhRWjRooVYN0eSXhwssWB9l7n7xp3vDh4BFt3gsfapJO0LD3zKjG82RED7wgNDN\/FFPhGA6MKtb2Z\/rk8F8s1MIMgEWHSDDNxqcaroIrgEgVR4m998cYAAAA6ISURBVIdeJK3VMvg+VwJa0ZXc9QLYmJ1\/COiJrrRyx4wZI9zLcOvL7UPsXfAPd84leARYdIPH2qeStKKLiM4LFy5QkSJFXIKlpDBgcOI9jD4hd3nLUHq6JQJ68HIDTHTkumKdOnVo2rRpIpKcA9d84427taIrOUvu2q1ZWkH2vQacAxMILAEW3cDy9VvueqKL7Svbt293Ce6RBfI2Ct\/Rq5bunWuXUkUvY8Dv3r07jRo1Smwj4oAe35lrRVfdMlSoUCGvkcy8R9r3NuAcAkuARTewfP2WuzvRdTfY8\/YV39F7E10IAqzcDz\/8UByIwcx9Z67nXlYnkHoHlDB337lzDsEjwKIbPNY+leRJdJGx1u3GVpdPuMXN2jVdMJ0\/fz5Nnz5dHOqu3cqi3bfrew2iLwd3gVRyexa8O9iTK9d3Zd\/H37ycEn39JRyfmEXXZKudO0f01ltExYoRjR9PlCmTI4MDB4jefJPotdeIGjZ0\/BsnMcpr5PfdujnuHzKEqH9\/18Lr1CHCu+gffDB1pdxFL6v5PPfcYfrrr5cpTZrr4qXqUhyQm7a8wYOJ+vVzLcdsnUyis3x5qJjrRS9DeN9\/\/xQlJn4knuf118\/RyZMN6e+\/j6TaMhTOzC03lo83eopeluu72ButJj4G0kfofHtQCbDoWsCNwfTbb4kWLCAqXdqRAcTy7beJ\/vcqVcqd2yG6OKUR\/69ePUWUVdHdtMm9yGqrpSe6uB+vrVTLlPmr91+7RvTRR0QFC6YWWnePL\/P+6ivHJCHUKRTM9UQ3mpiHos15y1AoqHOZwSTAomuBtp4gQRSkiCYkpIiutF7lZ0ZEV1p2EGtpjXrbp6u1pNXHkvk1bWpMQKVIIw\/VmreAym+3hIK5t326kc7cb41nIiMWXROw+NKwJMCia6HZtO7Oq1cdYiZFUg7Gjz7qsIZhLVas6BDiQIiuan2hDtok63Pv\/QjkyY2Ne73lZwGZz7eEgrkn0fXGKBKY+9xoFjKA6G7qN4GytW3lciKVhaz4FiZgSwIsuhabRXV3woqVbl7VldyuHdH27URxcQ6LtX17V9HVrul6cuWu6jqGqHkzt8dA6lnH8tHg+h492jEBgOtbb01axaBa7XrryxaR+XxbsJlDdC9Nnk7Vh3RyHgOp50FQPRKRxtznRjObAX4sxYvTro27KLZ6jNm7+XomYHsCLLoWm0i1dNasSXEtQ6RUt6O0cB96iCg+3pilm6pK9waiVbvOeDx72ahYerrOk3hbROW324LKnIh2bdpNsTVi6eLVW7qiiweLdOZ+azyjGc2aRdSiBV38fBplf99xpjUnJhBJBFh0Lbam6u6EJqrWjqdIZWnNGh2sRfXWriV65hk6Nu7fVOSjtro1NrMO66lsb25Ti7j8cltQmRPRscX\/oSKv\/ZNo5kyi5s1TPUM0MPdLw5nJ5JlnHP0dvMGdExOIMAIsuj40qLolREYpIzut6Krre0ZEN5W16WYgUt3GKFeuGb\/6qiNaGQmBUIsXp3YvY5LQtavrddj+pOYpI7N9QOT3W4PGHDXX4R6NzP3eiO4yvOfRcX595Ihjbx4nJhBBBFh0fWhMaRVqA5P0olrlliLTotvUscblTMnJzn9KS2vKFMdHcu+t1gLDdxBheV2bNg4xlp9LcQ4H0Q0Kc+xf1grAPe7RyNyHn4j+rbBk9RI+HzQo5ZsBA4hq1Up9JYSYxdjvzcIZBocAi25wOBsrBQM9rCttwucyaQcb\/L9Zs1TuTwj\/9OmOMUwe4KFXCaPXGXuAML3KT9yNsjR6XZjS9F5t8G7RwuFGNpvQ33\/5hUXXLDe+3jYEWHRt0xT3KmJmQIIVMHMmJRctSnv27BGvO7t16xbVr9+Ifv65JrVufb\/z8A69x4TVBmOiVauUQz7shiNo9bHAXbW2wLJXr5vUrNltKl8+s9tqM3MFzcCBrpatp8a+N7lMHjDApa83bNiQqlevThkyZAhaV+GCmIAvBFh0faEXyHs9DUjSusU1ROIM4L59+4o3sJQoUUKIb5o0aah\/\/\/7iIH5OJgiY4I5cb968SadOnaKlS5fSkiVL6LPPPqOYGN7qYpj4vSBBj9ejvyOoqlYt7uuGwfKFdiXAomvXlkG97m2fSFVFTTTtlStXKD4+nh5++GFx6aVLl8Qr53Ambfny5e38hPasm0Huly9fFhMdiG6+fPno7t274iD+LFmy2PO57For6d5Xl1FkXTXuZCN9He2CxO1g1waP7nqx6Nqt\/XG81XvvEc2d675mENf\/\/tfxfY8eRCNGuFybmJhIHTt2pA4dOlClSpXs9oT2q48R5mqtsVjesqXzk9u3b9OQIUOobNmy4gX3SMnJybR69WoaMGAAnT59mqpUqUK9evWi2NhY+z1\/qGpklDuC2GbMIFq9mmjaNKLMKe57ta+XKVOGxo8fTytWrBCC+9D\/NscPHDiQSpUqFaon5HKZQCoCLLp26xRyIHr2WaI5cxzBJvnyEWH2fm8Gf29UJ8JRWPXqEbVu7RQBWAITJ06kuLg4Gjt2LGXNmtVuT2i\/+qjMIaZyq1DatA6+S5em1HnvXkfQGqzhMmXE52ANQR0+fDgVuxfotnHjRpo0aRINHjxYDPpbtmwR7TJu3DhhFXMiIskdb+LAkWnu0rBhjtB77HNTRFfb17du3UrfffedmACh369fv54+\/\/xzwZ2Zc4+zCwEWXbu0hKyHHIgKFSIaNcoRpYlozcmTiXLlIvr+e4cQ4zMEUvXsScklS1L8Sy\/RsmXLaM6cOVS7dm3q1KkT5cyZ025PZ8\/6qKILLwJEF9xffJEInoLatVOibSG2CxcSzZ7tOFOTiPCquQ0bNojBHgE9sL66detGzZs3pxo4H5SIIBAQ5qZNm7L3QdvXt21zbG5HQmTf9etE+\/YRLVvm+AwbxnGm6pYtlDx1KsUnJRnq6\/JVgI0bNxaeBk5MwA4EWHTt0ApqHaQAwKrFeuy9YCnhXjt40OFKxmdHj1LyqFGU9OqrNCR7dlobH09vvPEGNWrUiAoXLiwCqTgZJKCK7rFjjpvAWGWOzyCg2CisuJflwF6\/fn0x2UFat24d4aXrcO3v3buXXnzxRdEuadOmpfvvv1\/8zemepdu4sUNc1eBAyR2Tnntb6JJ\/+YUujBpFnbNmpd3\/\/a+hvn7gwAHq3LmzWGeH65kTE7ADARZdO7SCnuiWK0fUvXvKNxoBuL1qFcUNGkRjk5LotU8+oVq1avFgbrUtVdGFcMq90FrRRf4\/\/ED05ZdEcP+3bEn79u0TFq50G8v1XYjtxx9\/LLwNX3zxhbB0EU3OW1uURgL3V14h+uMPot9\/T80d+8+HDaPbcXH0nxw5KN2vv1L62bOpZp06Hvs62gCu5aFDh1KTJk2oWbNm\/Nuw+tvg+\/xOgEXX70h9zFC7viiz69mTCAEhWHNMSKA7b79Ni6tVowk\/\/EAZM2YUATwNGjSgPHny+FiBKLzdCHMVC9oCacQImjFjhgiU6tGjhxjY4Vpu3749denShSpUqCAuk98PGjSIiquni0UhapdHlqLbpIlLYBqWTERfR8ImciWtfughOtq3L7385psufR2Ba8ePH6fFixfTokWLqGjRoqJN\/vGPf7DXJ9r7mc2en0XXZg3iDC65Z0mJ6q1b5zh1Cuu5ENWOHYkmThRritimAjcaBppvv\/2WKlasKGb4HDhiomH1RFdlfuaMgz1c+zJ4beRIula5Ms2aNYuqVatG5eCZIKLz588Lwe3duzeVLFlSfAYxwBovAq1YdJV28cZddQmvW0fJU6bQwW7daMHy5S59Hd6DCRMm0Jo1a4Rl+8orr1CBAgVYbE38BPjS4BFg0Q0ea2Ml6W2jKFrUMehjEIIVMHKka1731hhxUMPJkyfFmi6vGxrDLa7yxhzXqNw1W4bUkm7cuCG2qTz\/\/PNijRcW2MKFC2nz5s00YsQIPqxEhWWEu7wek6CpU53Ry7KvI0oZ67ZHjhwRa7fwLnDfN9H3+dKgE2DRDTpyLjDSCRw8eFBEKsO1CRH+448\/hCXG+0UD0\/Jnz54Ve3MxucHBMG+\/\/TZbu4FBzbn6gQCLrh8gchZMQEsAUc379+8XoosDMR544AGGFGACWGo5evSoWGrZsWOHOCiDl1kCDJ2zN02ARdc0Mr6BCTABJsAEmIA1Aiy61rjxXUyACTABJsAETBNg0TWNjG9gAkyACTABJmCNAIuuNW58FxNgAkyACTAB0wRYdE0j4xuYABNgAkyACVgjwKJrjRvfxQSYABNgAkzANAEWXdPI+AYmwASYABNgAtYIsOha48Z3MQEmwASYABMwTYBF1zQyvoEJMAEmwASYgDUCLLrWuPFdTIAJMAEmwARME2DRNY2Mb2ACTIAJMAEmYI0Ai641bnwXE2ACTIAJMAHTBFh0TSPjG5gAE2ACTIAJWCPAomuNG9\/FBJgAE2ACTMA0ARZd08j4BibABJgAE2AC1giw6FrjxncxASbABJgAEzBNgEXXNDK+gQkwASbABJiANQIsuta48V1MgAkwASbABEwTYNE1jYxvYAJMgAkwASZgjQCLrjVufBcTYAJMgAkwAdMEWHRNI+MbmAATYAJMgAlYI8Cia40b38UEmAATYAJMwDQBFl3TyPgGJsAEmAATYALWCLDoWuPGdzEBJsAEmAATME2ARdc0Mr6BCTABJsAEmIA1Aiy61rjxXUyACTABJsAETBNg0TWNjG9gAkyACTABJmCNAIuuNW58FxNgAkyACTAB0wRYdE0j4xuYABNgAkyACVgjwKJrjRvfxQSYABNgAkzANAEWXdPI+AYmwASYABNgAtYIsOha48Z3MQEmwASYABMwTYBF1zQyvoEJMAEmwASYgDUCLLrWuPFdTIAJMAEmwARME2DRNY2Mb2ACTIAJMAEmYI0Ai641bnwXE2ACTIAJMAHTBFh0TSPjG5gAE2ACTIAJWCPAomuNG9\/FBJgAE2ACTMA0gf8HBXbkWzwf\/XgAAAAASUVORK5CYII=","height":235,"width":477}}
%---
%[output:96ed6179]
%   data: {"dataType":"text","outputData":{"text":"多播树示意图已保存至: c.输出\\3.部署方案\\9.在线资源与时延感知算法\\US_Backbone\\多播树示意图_在线\\MulticastTree_Req_1.svg\n","truncated":false}}
%---
%[output:7588263d]
%   data: {"dataType":"warning","outputData":{"text":"警告: 绘制场景时出错: Error while executing frame: TypeError: Cannot read properties of null (reading 'supportsPicking')"}}
%---

```

---

## deployAndDispatchPlan.m

```matlab
%[text] # 2.生成部署方案
clc; clear;
%[text] ## 1) 导入路径
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'a.输入')));
addpath(genpath(fullfile(currentDir, 'b.常用函数')));
%[text] ## 2) 选择拓补与部署方法（只改这里和对应配置函数）
% topoName = "Abilene";   % "US_Backbone" 或 "Abilene"
topoName = "US_Backbone";   % "US_Backbone" 或 "Abilene"

% 可选方法：
% - 'shortestPathFirstWithLoadBalancing': 最短路优先（离线）
% - 'ResourceAndDelayAware': 资源与时延感知（离线）
% - 'ResourceAndDelayAwareOnline': 资源与时延感知（在线评估）
% deployMethodName = 'ResourceAndDelayAwareOnline';
% deployMethodName = 'nodeFirst'; 
deployMethodName = 'shortestPathFirstWithLoadBalancing'; 

%[text] ## 3) 配置表：不同拓补只在这里写一次
topocfg = getTopoCfg(topoName);
reqCfg = getReqCfg(topoName);
deployMethodCfg = getDeployMethodCfg(deployMethodName,topoName);
%[text] ## 4) 生成部署相关数据并保存
load(topocfg.topoInfoPath);     % 得到 nodes / links / KPaths
load(reqCfg.requestPath);% 得到原始请求集合
load(reqCfg.sortedRequestsPath);% 得到按最大可容忍时延排序好的请求集合

[fail_log, consume, nodes, plan]=initNecessaryStructure(requests, nodes);
reqs = eval(deployMethodCfg.requestsType);
% reqs = sortedRequests;

%[text] ## 4.1) 根据模式选择不同的部署流程
if isfield(deployMethodCfg, 'onlineMode') && deployMethodCfg.onlineMode %[output:group:21366e3c]
    %% ========== 在线评估模式 ==========
    % ResourceAndDelayAwareOnline 同时完成方案生成和部署
    % 返回更新后的 nodes, links, consume, fail_log
    fprintf('使用在线评估模式: %s\n', deployMethodName);
    
    [plan, nodes, links, consume, fail_log, deployStats] = feval(deployMethodCfg.deployFunc, ...
                    reqs, ...
                    KPathsNew, links, nodes, ...
                    plan, consume, fail_log, deployMethodCfg);
    
    % 在线模式修复，因为部署时已验证方案有效性
    fixedPlan = feval(deployMethodCfg.FixedFunc, ...
                    reqs, plan, links);  
    
    % 顺序化的部署计划
    sortedPlan = feval(deployMethodCfg.sortedFunc, ...
                    reqs, fixedPlan, links);
    
    % 保存部署统计信息
    save(deployMethodCfg.planPath, 'plan', 'deployStats'); 
    
    % 【重要】在线模式下直接保存最终结果（部署已完成，无需再调用sfcMapping）
    % 保存格式与sfcMapping输出一致，便于resultPlot统一处理
    requests = reqs;  % 使用排序后的请求
    
    % 确保目录存在
    [resultDir, ~, ~] = fileparts(deployMethodCfg.resultPath);
    if ~isfolder(resultDir)
        mkdir(resultDir);
    end
    
    save(deployMethodCfg.resultPath, 'nodes', 'links', 'requests', 'consume', 'fail_log', 'deployStats');
    fprintf('  ✓ 在线模式结果已保存到: %s\n', deployMethodCfg.resultPath);
else
    %% ========== 离线模式（原有流程） ==========
    fprintf('使用离线模式: %s\n', deployMethodName); %[output:49508bc6]

% 原始部署计划
    % 使用KPathsNew格式（cell数组，每个元素是K×1 struct数组）
plan = feval(deployMethodCfg.deployFunc, ...
                reqs, ...
                    KPathsNew, links, nodes, ...
                    plan, deployMethodCfg);   
% 多播树修复后的部署计划
fixedPlan = feval(deployMethodCfg.FixedFunc, ...
                reqs, plan, links);  
% 顺序化的部署计划
    sortedPlan = feval(deployMethodCfg.sortedFunc, ...
                reqs, fixedPlan, links);  

save(deployMethodCfg.planPath,'plan'); 
end %[output:group:21366e3c]

save(deployMethodCfg.fixedPlanPath,'fixedPlan'); 
save(deployMethodCfg.sortedPlanPath,'sortedPlan',"consume","fail_log","nodes"); 
fprintf('✓ 已保存（时间：%s）\n', string(datetime("now"))); %[output:8d7737d8]


%[text] ## 5) 根据计划绘制一个多播树进行示意
set(groot,'DefaultFigureVisible','off');%不弹出窗口
req_id=32;
plotTree(sortedPlan, req_id, links, reqs, deployMethodCfg.treePath); %[output:882131d8] %[output:4de63e59]



% 查看请求4的详细消耗
info = extractDetailedConsumeInfo(consume, 4);
%[text] 
%[text] 
%[text] 
%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":34.2}
%---
%[output:49508bc6]
%   data: {"dataType":"text","outputData":{"text":"使用离线模式: shortestPathFirstWithLoadBalancing\n","truncated":false}}
%---
%[output:8d7737d8]
%   data: {"dataType":"text","outputData":{"text":"✓ 已保存（时间：2026-01-13 15:56:16）\n","truncated":false}}
%---
%[output:882131d8]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAd0AAADrCAYAAAAsaUxqAAAAAXNSR0IArs4c6QAAIABJREFUeF7tXQmcjVX\/\/9JYxr4TIWTrJXmjeo3ipVJelVQiJWsUInuyk8geStmVLVkS9aqX7CnZQkgy9uzbMJZp5v\/\/nuvcee4zd3nunTt37vI7n898Zube85zzO99znvM9v+WckyEpKSkJkgQBQUAQEAQEAUEgzRHIIKSb5hhLBYKAICAICAKCgEJASFcGgiAgCAgCgoAgECAEhHQDBPSBAwfQsmVLjBo1Cg8\/\/HCKWj19b3zg\/PnzaN26NXr16qXKWrBgAWJjY9X\/5u\/Sonmso1u3bujTpw\/Kli3rtArdnhMnTti\/nzt3rtO2+0PGESNGqGKIgb+SxnLnzp0pinz66acxfPhwREdH+6s6h3LMGBPPnj174oMPPnCJeWoF4Th655137MWY25gajH2V39k4MrazXbt2fu1zdxjq9+ytt95C79698fXXXwd0XGzevBnsg2nTpiFfvnzqvTf2lxbGF0yMZZn73fweGMtn\/8yaNQvvvvtumr0LqR3Xwfa8kG6AekRPOrly5ULfvn0dJk7joLZCTO5INxDN8US6ziZYPXl26tQJL730UiDETHUdntqZ6grcFBDIuuPj4xWJMBkXEpzgOdHrST41pOsPrLScTZs2TbPFmys5jeTCPMTLLIeWr2jRommyEHBGunqxreX2RQYS7vz58532s55rmjRpot5bXX6NGjXs7zGfZwqV99ofYzE1ZQjppgY9L57VRPTMM88gW7ZsDgOUL9O8efNw5MgRu\/ZqnuCMRJY\/f367pnv48GH7apcrVGpDHTt2tJfjaZVK7Vtro5wsZsyYYV8QUIZPPvlEtbJKlSrqpWSilq21P2eLBL6EmzZtSqEJmj93JxvznjlzBqtWrVJ19evXD8uWLbNPDJSDmAwbNgyjR4\/GlClTlGxa03UmO7UDJuOq3txmY5daIT5P\/USLwKOPPoohQ4Y44KhlMWty77\/\/Ph5\/\/PEUGLPPjZquGTs+pyc9tm\/Xrl24cuWKXRszfm8etq76yzzBsq0cKxynzvrf3BYjtsbxy\/rZbw888ADGjBmjxLFiOXBFuuaxwjHJ8WrURr3R3py91mx7rVq1FNm7I38zMeq8Wis2y8H8L7\/8sh2D+++\/H6dPn3ZK2lZIlwWZF+Xm54ztc0aixvy\/\/\/67g3bNZ\/V8pRdoVt4TL6bKsM8qpBugLtaTDklh7dq1oIlKmyb5QleuXFkRhzYZe5rMrZiX9cSjV6XGF+yf\/\/yng7nbrO2Q4IzEaZyYmdedeVlPJO60dvPEYH75Wd+ECRPsiwBnZnOjWd2Il5lEjP+b2+VuQrIymVjppxIlSqgFiNaQtCZkbpPx\/3Llyjlg7GzRpbUPszaiFxUaf7axe\/fuDgsqs2Zk1FxcvRJsK8lDL8yMGtK5c+fcjqdjx47ZFw0sn4s9EpDRJaLb46p+d6RrHCvOiMTYT57Gnrl+4+KOiyWrpMv3m8RvxNYoh9mlpN8bV+Zhq6RL+VnP3Xff7ZP26cmi4WyRlpr6AjQFB001QroB6grjpLly5UrUq1dPaZScAAYNGqRImBOjP0lXv3zaPOipqe7IyVsN0JN\/0EiYumzj5Pb999+n0JaNk4F54tPftW3b1sHfbUVuVxOGK5+u1vo5AVshXd2nWsvWixnzAsCdrMbxs23bthTYGCdkM3bu\/PzexAC4a6sz375xPJlJ1+yf9jTRExt3pGtcIJo1Ma396YUi8TObZc3EauwLc3mu5DCbdq3IYZTbk2nYG9J19n5Zef\/pIzaOb\/MzrsaLK2uJpzoj8Xsh3QD1unHSpFZAszDNgXyRqPmaycKbydxVIBXrcGbmNU\/uRnOxNn9xAtCfm02wVjRAYx1GU682cxo\/M+bVL7wz0jVOOsRQm5aN5NeoUSOXAUfugnKcmV+ttNObfjKT7ocffqia7iz4y10g1eLFi1M8527BEkjSNS9U9HgKJOm6CjDS45j4abeJs7GnTf\/6OzOBmU3GxjKMWqoVOcz9744s05p0jYtfZ0F7um9pYjePWXcWowBNsSFTjZBugLrKbB6kdjtgwABlUqaviOZEo8nYm8ncF9I1To6acJytVo0TjNGv6yl62RmsxhfT7IM153cmi5E8uKAwaisaL0+k600EcCSQrjNTrKtXwsqYpK\/X2XgKNOm6W2xa0arNi0YjOTrTdM3uEPMCy1mUuzM5\/EW6qTH3OhsT7giXbXVnKQjQFBsy1QjpBqirzBG92o9LUzPJl8nfpMsyWY8z87Iz05c7E5E7f6MRQneTuCcTqbEcV7KwPQwQ4o8xetSqedmIsaeuT2vSDQbzsidyMBKDO9Kl5YHBgMbo5\/Q0L7sa957a62xMuNJ0zdHLrNMY7e1J+3PlG3Vl\/bCq6XrjMnCW1\/wOW9l54Kmtnt61SPpeSDdAvW0mXXPQhHnwG4NUtPlUB7EYo5fd7dM1B1JpEuZvatfGiUnLo82B7gKO+LwvgVTOglmMwTNWfMpaTmeR1nqyMk9mZn+ncXuEJ9OrJ43em34yT\/jahK99vsbJjhHMxrq9DaQyanqeJmF3W4aMgVOeSNfdeAqkpuvMN2ocA3qB62rsmbVSqz5djbOrwDnW60wO3f\/+CKTy5Bd2tagwB03qd8QZVlbKCNC0GpLVCOkGqNvMpOsuctW4LUFvNZg4cSIWLlyoDqQwk65eiRYsWBAjR45Ejx49XG4ZMm5ZMPpV+fmzzz6L\/v37q+jUu+66y2HLhavtRK62ojjzn5rzmvMYZXOl6ZonNmMEuFFDMLbN3VYoPuMqytqKpmv277nrJ2dalhkDo09Qt4G4Mdrcmy1D3pCufgXMfnZPh2M4s95oX6l5PLEOLb\/xbx2AZcXkazWQiuWbfcvm4CB3Y888JXgTvazLNUdm6y1W7uTgdyRsV\/t8nWm6zg7HML9nVrRQY98bZXTllza3IzXm7ABNwUFTjZBu0HSFCCIICALBikCgSMXK4iPYMNI7MOgmMwehBZuswSCPkG4w9ILIIAgIAkGNADXYQBx3GIqkS22YSU6ksjaEhXSt4SS5BAFBIMIR8GXvq7eQhRrpBmox4i2OwZxfSDeYe0dkEwQEAUFAEAgrBIR0w6o7pTGCgCAgCAgCwYyAkG4w947IJggIAoKAIBBWCAjphlV3SmMEAUFAEBAEghkBId1g7h2RTRAQBAQBQSCsEBDSDavulMYIAoKAICAIBDMCQrrB3DsimyAgCAgCgkBYISCkG1bdKY0RBAQBQUAQCGYEhHSDuXdENkFAEBAEBIGwQkBIN6y6UxojCAgCgoAgEMwICOkGc++IbIKAICAICAJhhYCQblh1pzRGEBAEBAFBIJgRENIN5t4R2QQBQUAQEATCCgEh3bDqTmmMICAICAKCQDAjIKQbzL0jsgkCgoAgIAiEFQJCumHVndIYQUAQEAQEgWBGQEg3mHtHZBMEBAFBQBAIKwSEdMOqO6UxIY1A797AiBHJTVizBqhVK6SbJMILAoKAIwJCujIiBIFgQGD6dKB1a4BEW7060LYtsHEj8O23QMWKwSChyCAICAJ+QEBI1w8gShGCQKoRoJY7f76QbKqBlAIEgeBGQEg3uPtHpIsUBLRpuWRJ18RrND\/rfNHRNoS++ALo1ctG3A89BPz0E9Ckic1c3bhx8vfMw8\/4e\/hwYO9e4KmngMOHbeXoz\/n3tWs2jXvu3JTfRUq\/SDsFAT8jIKTrZ0ClOEHAJwTM5Pfyy8CUKUC2bLbizJqwNkeTZEmuVlP79sDHH9ty6zr5PAl47Vqgdm1g2jRbmSTcgweB5cuBM2ds5Ny\/P9CqldXaJJ8gIAiYEBDSlSEhCAQLAmfPAg0a2LRUJmqsJDwmfk5CJDky6bxVqwKTJ1tvAUn6pZds+Y1+ZHPAlpmQtdbL54yLAes1S05BQBAAIKQrw0AQCDYEjFovtc5\/\/cumZWqN1Ei6RYoAX31lvQVG0nXnRzZr3roGvRAoUMB6nZJTEBAE7AgI6cpgEASCEQGjqfeZZ9JE042fNAnRHTtiYYcOyN+oEWJiYpAlSxYbGmZNNxgxEpkEgRBEQEg3BDtNRA4zBLSpmM2iOZlapNn06y+f7m1N9\/Tp0xjZqhX6bdqEy\/XrY3q5coiOjUX3VauQYcAA1z5do7YdZt0gzREEAoGAkG4gUJY6QhaBhIQE\/P7771i0aBEuX76MgQMHInv27P5vj9mfyxrMh2O4il4uVcq6PPPnI+H55zFs2DCULFkSzatXR4b69e3Ry2datUJBmrSZzNHL5uAu67VKTkFAELiNgJCuDAVBwAUCM2bMwIcffogKFSqgUaNGeOSRR1C4cGFkyJAh3TG7FJ+AXcev4PK+P1D\/6QctyzN51jqcypiAn778CD27d0PmjIkoW7Ys8ubNizVr1qB8+fIoXry45fLSMiMXOadOnVLySRIEwgUBId1w6UlpR6oQWLt2LfLkyYMqVarYyxkxYgTuvvtuvKSjfVNVQ+oeJsny58j5eBy9cB1Hzl9XBeY+dQztX3vUcuEb\/rcdn367Ahu\/moXy\/6qHXLly48ivG9GyTTu0efWldF1QJCYm4tKlS\/jzzz+xYsUKfPPNNxg1ahRq1qxpuX2SURAIdgSEdIO9h0S+NEfgypUr6NatG5o0aYI6derY61uwYIH6m5M+tUCaY6tXr54cbJTGktlI9jqOXojHruNx9tpyR0ehUtEcKJEvGiUu\/wV4YV6O27MHXceNQ41Ha6PMQ0\/i2MUb2LrjV\/y4aDKebd8XNSqVtrX5nrxp3LqUxW\/fvh3Dhw9HtmzZcPHiRdx7773o37+\/He+kpCQcPXoUK1euVNo4LQ9pYuoPeMulwkhCQEg3knpb2poCAfpsJ0yYoH7ef\/99B62WpEtti2bOqlWr4scff8QTTzyBTp06ISoqKk3Q1ES7+8SVZG02Ogo2os2JEvmyqr\/tKTbWK9I9v2MHuo0bhz59+tjNtgePnsTbXbuhTtOOuJH9zhTkHmgCPn78OLp37453330XlSpVUvKwn2junz9\/Plq1aoWTJ09i165dGDdunDKNSxIEQgUBId1Q6SmR0+8I6Imckzf9hvTVduzY0UHT3bBhgyLjHDlyQJPB4MGD\/epn1P5ZB7NxdJQi2OJ5o1G5WA7XbfeSdC\/v2oXuH36It956y05oW7duxciRIzFx4kRkyp5Hkf2l+FvYePBiCgKuXCynI+n7uVeozU6ePBnXrl1D586d1eJGf0YXAH3shQoVwtWrV\/HOO+\/g1VdfVdYHSYJAqCAgpBsqPSVy+h2BuLg4fPfdd6hXrx6WL1+O2NhY9OLZw7cTtSmSbc6cOdUn8fHx6N27N5o2bYqHH37YQZ4Nf1ywmXvzZfUop0v\/7G2i1Rqtx4J0BhKv1XT33Vi8eLEyl\/fo0UORG0249FszWMyc9ILAGQFbbS\/LJJHTH+1Jaz5w4AD69eunzMz0pzPR7Ny+fXu8+OKLytT84IMPKsvD3r17UaxYMRSQgzqs9r7kCwIEhHSDoBNEhPRHYPPmzVi4cKHaSmM\/IOK2WVObkp1pV0YttWn1ZNOsM\/Ly6J+1QNj+QIoBSxs3bsT06dNx\/fp1vP7666hVqxYyZszotnhXGjn9y0yeCHXelpMqnyucaHmwb2Vq3lxZHm7cuKFImGTcpUsXFexGV0D9+vWdLhL8gY+UIQikJQJCummJrpQdMghs2bIFn332mTIl6+AcRtCuX78egwYNUkRMU\/Ps2bPBqGb6EUlCJBL+JpGYtVyv\/bMhgxZUm7llyWgSp\/g6yMsZAXPRQbyYp36lginw0oFU48ePRxEebwkosu3Zs6fSfLmdiYn9wAUSP4vWtyyFEHYiamQjIKQb2f0vrb+NACd3almjR49Gvnz51Kc8tYm+z8yZM6NMmTL49ddflSmW24poTtYmV5Kt1t5S5Z8N0d7QiwsrfmCSrt7uROLV\/mptuq9Ro4ZDMBstEN9++63SdrXFgaS7ZMmSFFaJEIVPxI4wBIR0I6zDpbnOEeBWFBIqiffOO5PNxCSDffv2qYd4SMZNZFIanibcGwmJqFPeRtLOAqG89s+GQQe58wOzeUb\/MEmX5MtEH3vWrFkdIsNpgaAPmieB0drAPAMGDEDt2rXx9NNPhwFa0oRIQ0BIN9J6XNrrFIHz58+rvbrGrTTmjNqcfPrKTWVe5Q9JV\/s0HfbPBsg\/G+zdqQl494k4hRfTgdPXkCUqI7JmyohCOTMrczMtBQ5boW43jCRL837p0qWVeZlbhmiJ6Nu3rwpykyQIhBoCQrqh1mMib5ogwOCiW7duuTz4gkQxed1RaMKlEJo4YsrkcUkaaSJsiBZKs\/Li7aew9chlOwGzKSTb4nmzov2jxZ1GfzOA7fvvv1cHYzBymVuEPAV9hShEInYEICCkGwGdLE30DQFqZr8cvoRfDl+2m0RJtCQJ\/lBL08ldAJFvtYfPU87MzbQQnLp8UzWSZnmdaDWoX6kA0no\/cPigKy0JNQSEdEOtx0TeNEPA2f5ZbRLVJ0GRXPVnOr9RIFeRuWkmdJAXTO32m91nUmi2WsPVv6\/fSlRWBB53qRc1Yq4P8s4V8XxCQEjXJ9jkoXBBwNL5xhb9s0Yy1sQRLjj52g6SrvbVOvPZOivXmR9YE3Du6EzuT+jyVVB5ThAIEAJCugECWqoJHgScEa0mSafnGweP6BEniav9wLYjMrN6PJAj4gCTBgc9AkK6Qd9FIqA\/EIjE\/bP+wC2YytB9SJnS41zoYMJCZAldBIR0Q7fv0kzyc+eAZs0AHn07diygD\/3Zvx\/g1bLPPw80bmz7m0cQ6zz6+x49bM8PGQL07+8oZr16wJw5QP783omvZYqJAfr18\/ysNvWaT02iRkstKRL3z3pGLbRypPZc6HAY56HVYyItERDSlXHgFAES5qJFAK+UvX36niLLV17hMXwAz5gn6e7cafufZOiMdDdu9I1kjULpclnX4MGuSdef\/lkZFqGFgK9+4FAc56HVMyKtGQEhXRkTThEgWdasCXz+uU1rZeIEpUn07Nlk0tXaq\/7MqOm6Il2rmquRcCmDmXTd+Wfp8\/PmJhwZCuGBgDd+4FAZ5+HRM9IK0XRlDLhEwGx6u3bNRr7avKvJsEIFmzZMcq5WzUbE\/ibdb74B6tdPNm2\/1T3lYfvabOzx\/lnp84hCwJMfuFh0TrzROsruSgmmcW7FjRJRnRkmjRVNN0w6Mi2aYTS9UYul5ms2Jb\/5JrBtG8ArXTlJdOiQTLp9+97Ae+9lcRDNqDl7I\/MvOxPQtEkG3F\/rGqo9d1Y9Kv5ZbxCUvETAmR944xf5sHdTDnw6KwGZb2Xxepw7i13wdZwb4yaEdMNzzArphme\/+qVV2vRGol29Otm0zCAoo\/9Wa7iFCwOnTgEdO8ajatXfMHhwEg4eLILWrVcje3bbqUO8TMDKQfVms\/GZY5kwd1ghVKsdj57vJIrZ2C89HNmFaAL+auUtjOpYCG+MPomje7Lh9IFsGP3RDdSslMPtOKdF55lnrqBnzytYvz7RYZx7M9aNvSCkG\/5jUkg3\/PvY5xYaTczUZI2Rw+4ilbt23Yby5X\/BihX\/TEG6FCZnzpxo2rRpCrnc+WeTLmbH0LdzoOlLGS1FL\/vcaHkw4hDgOG\/cJBE5C9zCoVigcLlrqPvyRYVD1JUcmNwvHwb2vSNFRP6UKfEoXPh\/mDr1Tqfj3N1YdwWykG74Dz8h3fDv41S10Gg606ZlFmgmXWPAU6tWq\/HQQ3+4JF0+X6TIP\/DRRzF44MFENGl3DbtPXLHfs+rMPyuTUaq6UR72gIBxnK9c9TeylbiMy9cTsPqnG8rC8ugLl1D7P9eR60ZuvN8tJ3bvyoB3392LEiXWux3nV69mxbx5DfD00\/ksLRZlnIf\/UBXSDf8+TlULtYnZvL\/WTLqsZNq062jTJiuskC4no1kLXkSh8teVVuHJPyuTUaq6UR72gIC7cf7cC4l4oWU8sv\/jtCpl++ocWPBBQcvjfNq0OmjYsCCGDnWMb3Amkozz8B+qQrrh38cBa+GJEyewfPlyy\/VF3VUF5cqVc\/DPJiQkICkpCZkyZbJcjmQUBAKFgPYD7\/vzKBJjN1uutnbt2ihbtiz27NmDTz75RF0j+corr6BGjRpyTaFlFMMjo5BuePRjULRi69at4I\/V9MADD4A\/Oh05ckRdWF6wYEEMHjwYmTMnX51ntUzJJwi4Q+Dy5cu44447kD179lQB5ctYj4+PR79+\/dC6dWt1J\/Ds2bNRvnx5vPrqq8iQIUOq5JGHQwcBId3Q6augl\/T333\/HmjVrLMvZoEEDFC1aFLxAftmyZZgzZw5OnjypCLdOnTqWy5GMgoAnBG7cuKHG2Icffqh+qlat6ukRt997O9Yfe+wxjB8\/Xmm2L3EzO6DG+oABA9RCk1H9kiIDASHdyOjngLXy008\/tVQXI5hr1aqlzMgjRoxQ2i2JduzYsRgzZgyKFCliqRzJJAh4QoAWlKFDh6psffv2RYkSJTw9Yul7b8Z6lSpVMHLkSPTp00eZmZnOnz+Pbt26OXzmqWK6Xkj433\/\/Pe655x488sgjqdbaPdUp3\/sXASFd\/+IZ8aVR0+Wk4Clx4smYMSM++ugjNfHQ3DZjxgy1+u\/VqxeioqI8FSHfCwIeEbh58yb69++PatWqoVGjRn7xn2q\/7o6fNyJz3AnPMuQoinL33ofPx\/RFixYt7FacDRs2KO2X7wAXnVbSihUrMGTIEOUPZtq8ebP6v1SpUlYelzxBgICQbhB0QriJ8PXXXyvydJWo5XKS4GQ4cOBAPPzww4iLi0PHjh3x5ptvqv8lCQL+QmDBggU4c+YMWrZsqfyoq1evxlNPPaX2ikfrK7QMlR05f13dROUskXDnbTmpTrZixH2xSzs8jvVLxWqq\/OcP7sDmL8bjxRdeQJ48eTB58mTUrFnTHr+w63gcKhfL4bbZNJPzJ1euXCof37W9e\/eiR48e4hf214BJ43KEdNMY4EgtfuLc5Sm0gMSoaNzIfieee7wm8ma6hf\/+979qErx27Rruu+8+ZW4bN24c8ubNG6mwSbtTiQDH0M8\/\/6xMrtRuSaq7d+\/GhAkT1KEs9J3Sn8v4AY65Dh06OFhVSHyX4m+h5j2OY9B4fCTJtlLRHPY8zqw7rIuR+QwU\/Ouvv7D4h624kPMe3IyPQ1GcRZXiuTF9+nQ0a9ZMuVmYvtl9xusrJ7\/77ju1iJDAw1QOnAA+LqQbQLAjqSpqA8dOX8C1i2dw5coVNeFly1NQ\/W7\/aHE7FPRRHT9+HMOHD8c333yjTIAMLEltdGkkYS1ttSFAcy39pgxW4tYcmmw5lhioRysKXRj8zUjh2NhYvPPOO3j\/\/fdxNy+Ovn0u8+R1R9G0+p0Omu6GPy5g9wmScYLSRGPK5FVarjFxjNO6o8c6yZ1jnenQoUOKFPsOGoafT0EdAvPX7g04t2cdJo0fY89Hwifx8v0wl2\/uY26t27lzJ9577z20adMG9XkjCABGSPMnR44cEv0fpC+GkG6Qdkyoi6UnEE5UnLDKFsqGQjkzI6ZMnhRaBDWBt99+G71790bx4sWRL1++UG++yB9gBM6ePatiA2hmrVSpErg1qHv37mjbtq3SbKdMmQJGEOsgJhITxxtNzHRnGM3GmvT4GUmQJEkSrF+poEuzs7vmkiA\/+OADZRamL\/bb1Rsw+\/M5qNvqXdxfqYIieSbWw8UqTdv6M35OIt+yZQt+\/fVXRbR8Xw4ePKi2G3Xt2lVpyufOncPEiRNVhPZdd92l2s\/tSXXr1hWzc4DHoqfqhHQ9ISTf+4wAtQZOJJp0SbycTMyr+B07dmDWrFkqIIQrdEmCgLcIHDhwAMOGDcPo0aPVoo1Ex\/FEQnK2\/Yyky0jil19+WWnAJDtNrhyju45fwcaDtpPSjKZkb+XS+Um4NAPTmlOmTBnUa9AQ55Bb1cGkF6MjVh5S\/1OjfuofBdRhM7QC0VTORQMjr\/lDLVoHG27fvl0tMBo2bIhWrVopK9Gff\/6pniMmBQoU8FVseS4NEBDSTQNQpUgbAtQSNvxx0U661UrmcljBG3HipLly5Upl\/pMkCHiLAH25U6dOVaZWki4D89599120b98eFStWVCZXfl+vXj3la6XGyJOhaJ7dcw528ssSlRFZM2W0B0o5WyR6K5u7\/GZt+vSVm6AMTE2qFcHFY78r4qxQoYJ6N8xRztwp8MYbb4Ca\/v33348XXngBTzzxhIqPkD3A\/uwp\/5UlpOs\/LKUkEwLUHKjtak23c52SLs1zZnOfgCkIpAYBBk8xUIm+VFpPqPlySxq359Dfmjt3bkW4UXmKKi33RkIiTl2+qX5zcegP7dYb+ek3Xr3\/PA6cvoZcWaPs7wlJv3D2DFi4cCE+\/vhjdOnSBc888wyyZMmizM40qZOIGfXPNvHgD2q6DBC7cOGCCkqU7Xfe9ETa5xXSTXuMI7oGmstoQuNE1v8\/ZdQKnMfgUdNgYiCLPqGHew5pJuPkqH1vEQ2eNN5nBEi4JJvmzZs7lEENmOce0zx79RYwY9NxRXRHL1xXGibjDuhT1WblEvmiffLjWhGcWq7tOst4VT\/l4EJVa7uUhWZmHXjIQz4YKMaIZ\/qh165di8WLF6vFg3bLUPOl\/5j5ZBeAlV4IfB4h3cBjHlE1knBJvM\/dXwgtaxRL0XbuoWQUqTnxonv6pJzto4woAKWxXiPAICL6azt37qwWb4we3rVrl9IQdSLZLd5+Ct\/sPqu0WxIuYw7M8Qb830bAOT3uofVGUJLrxoMX7NdZGp+lbCRgLVf9SgVcvjuM\/m\/SpIn9cfqNuXeXJml5d7zpkcDlFdINHNYRWRMnl47z96JXvVIqWESSIJDWCFDb48ETjE7+4osvsHTpUhXJ++ijj6pIXu1HnbflrxTarSbZ4nmj7ddNprW8eg8w66HGy3eGib\/5P5OzRSs1XZ5QxW1RWbNmxbZt21Q7eeiMHDCT1r3me\/lCur5jJ09aQICL4YPdAAAgAElEQVQTx+AVB0F\/rqfTdiwUJ1kEAY8IaDcFtUBqtwxA0vu+te9Un\/5E323ZQtkDRrAehb+dwWZ2pqn5htLGqfly0WrcQ0w\/NaP+586dq57ifmSe8KYXF1brknyBRUBIN7B4R1xteu8h9zgK6UZc96dLgxlERZ8m97Dy1Cmjdqu1yFAbj3rfOwE17+NlEOL169cdthGlC\/BSqSUEhHQtwSSZfEXAKunKliFfEZbnzAhQw+UPL9Rwd3xjqCFnbAtld3bQTKi1KRLlFdKNxF4PYJutkq5sGQpgp0RIVRx73CuuLydI6z23gYLVXydlBUpeqccRASFdGRFpioCZdGXLUJrCLYXfPkPZ3ydKBSOw9E+bT7QKRjlFJiFdGQMeEDh3DmjWDOA58GPHAvr2s\/37gZdeAp5\/Hmjc2PY3b+HTefT3PXrYnh8yBPj\/2\/scUr16wJw5QP78to+tbBnS5XJrr\/l56czAIhDIsWGlZcaxUfexJHR9\/xJ2nbuQ4vhGjrnbV9CiXTvHcW2lnmDLo\/uh6F2JqNXiNP66Gq\/anOtGbnzQI5df31ErbZd31ApKtjyi6VrHKqJykjAXLSIpAuXL25quJ64NGwAe50rSJRHy\/5gYwBnprlqTiFrtj+KFGvl9CqTSZU6aBFSoYCNz1tWvX0R1R1A11l9jY+NGxwWYt400jo2idyegwXMJKFYxHo1axzlcTsB6ata0jVM9brlwDPUxZOyH6II2U\/qaFVmx4IOCWLnqb5Qsdoeld9Sf\/SDvqOdRLKTrGaOIzKEnqs8\/txEdE19y\/YKePZtMulr71J8ZNd3\/rfkbtdsfS0G6eqXuiUBJ9J99lrrJOSI7MA0b7a+x4Wqy92ZsTJ+ZiG7vX3aq3WoIOIZGjrQtIEm6zqw4aQhXmhXtrB\/avB2P9euBJr1Oo3yevErrNVqInL2j\/ugHeUetd7OQrnWsIiqn2Yx47Zqjlqm1DK5sOZmRnKtVsxGxP0mXRP\/bbzbo589HWJgGQ30g+WtsuJzsJ85Ds+VNPVo0Ova4iZ+2JeDW30nYuTY7WrZOxKQJGe3uEI2zUSPWmq4eo6HcF6764YEH\/0alp09j669\/Y\/77hVD1vjuwfMkdLt\/R1JKuvKPejSIhXe\/wiqjcRvMVV8jaRGc0Jb\/5JrBtGxAbazPXdeiQTLp9+97Ae+9lccDMqDlbAVP7hWkaFNOVFcQCkye1Y8OZv1+NjZhYoFQpICnJZUN09O6MiVnx\/ey8mLXkGv7zSDa3rgetFbJQb8dgYBD1rRZ3\/fD1uqto1zIT\/tXgMi4dzYaoa9lSvKMu++G2dcuKVPKOWkEpOY+Qrnd4RVRuoy9s9epk0zKDoIz+W63hFi4MnDoFdOwYj6pVf8PgwUk4eLAIWrdejezZbcfZ8YYXnqtsNRlN2tmyAW+\/bSN4YzCW1bIkn\/8Q8HVsGK0gTjWsNWuAf\/8bmDEDaNHCQWDznttflhTAsb3Raiy4GxtGWcNt4eapH154MQnPtbiGa7kvKK236J0ZcPNKJmWNeuaZK+jZ8wrWr090eEe9fU\/lHfXuvRLS9Q6viMptNF+R6Iz+V3eRyl27bkP58r9gxYp\/piBdAsgbXpo2bWoJS7NP1\/iC6whoSwVJJr8i4OvY0Fqmy34k4ZJ4Sbgk3tvJ2Z7b5YujHPz9rso0fx5OY8hqPzRolIBXO17F19NzK0SHj7uMe0uvxdSpdzp9R715T+Ud9e7VEtL1Dq+Iy200P+koZYJgJl3jloFWrVbjoYf+cEm6fL5IkX\/go49iPPrtjPU8+aRELwfTAPRlbLglXa7sSpXCOeRHM8xBzOB6eKt7AlztuXU1Nrp3t1lEmLidbfFi23Yho4vCvB0umHD1VhZv+qFBw7\/xx7470PyN7Yi5f4vbd\/Tq1ayYN68Bnn46n9tIb3lHvesxIV3v8Iq43Np8Zd4fayZdAjNt2nW0aZMVVkiXL\/SKFS\/j0UfvQOvWJ9RF3JkzZ3aKr9EfFw57LMNlEHkzNvR2MzvpdruIjR\/\/ijkFOiP\/HReTIYmNTSbdPHvwVpax9u9yV7wHeO01B7Ozs7HBB4yky33mRmIKt73evvSD1Xd02rQ6aNiwIIYOdYzNMI9heUetv9VCutaxkpweEDhx4gSWL19uGafatWujSJEiePfdd7Fu3Tq8\/PLLaNiwoboDlefmSgpzBKjZtmxpMyd7SrVr28zNVFEN6cqVK+pCA32Ju\/6Ki8Jp04BBg5IPd\/FURaR878t7Wq5cOUu4RwqGqWmnkG5q0JNnHRDYunUr+GM1PfDAA+AP05kzZ7BkyRJ1QhUTL+am39c8mVotW\/KFEAIDB9rY0VkiyVK7ZZ7b6ebNmyBx8J5cjplJkyahUqVK9u\/j44EBA4DWrZMPdgkhNNJcVF\/fU0+4p7ngYVKBkG6YdKQvzbh69Sq+\/\/57RXhPPfUU7rrrLl+KsT\/Dy8PXWNFabj\/RoEEDFC1a1P48b4bZsWOH0nypBXfu3BlZsrg3a6VKYHk4fRG4dg23WrVGpgXzXctRvz7wzTe270uWxLVFi9BzxgxFurSS8A7ZUaNGOSzOSA78kQWbc1h9eU9z5cqF3r17u8U9fQdT6NQupBs6feVXSfnivfPOO\/jPf\/6jyv36668xduxY3G0y33lb6aeffmrpEUYw16pVy066vJCbWu7UqVPx\/vvv46GHHlJmQ0lhjABPXGnbFr+WfxD3JV5wru2WLo2rH0\/Bn\/940OEYUY6XIUOG4N5778VLPJHl9iXuy5YtU3fpRkVFqbE8dOhQFC9ePIxB9K1pqXlPzbhrCY4dO4YpU6aoOeXBBx\/0TbAIeEpINwI62dxETlgjRoxA9erV8cQTT6i7R0l0derUwcO8wcCHpPdQ7vh5IzLHnfBYws0cRZG\/7APgdWuUhybCTZs2Ka3F20mSz9O3x3YwnTp1Cn\/\/\/beDydGjQJIh8AgYSDfPonko8etPuFT4LtyMzo6Csfvt8syftQpNmtdxkC82NlYtGjlu9UJx9erVmDhxIsaMGYOSJUsqK84PP\/zw\/5bpgWIxMfUuLVJceHtK9OXS6qSTGXe+e3PmzMHs2bNx+vRplC5dGp988omyQkhyjoCQbgSODPPdtXxxPvjgAzz33HOoWLGiU0S4T7JEvqxOv9t1PA4bD15Q95ZWLpYDfx\/ajJMnT7pEllpu8epPqmvJSJSJB9dj98aVGDduHAoVKuTwHMtmma4SyZUa8rRp03Do0CGVrVSpUvj4449hDv6IwK4O7ibfJt1rhe5EtnGjFeHihx+wacpiVD65D3ft2w7s2JHchl69gOHD1f+0zKxfv15pu3RBXLhwAV26dMFrr72mFo9MdJsMHjwYgwYNQr58+YIbi3SQjhh6ek\/N++nNuN+4cQO7d+9Wh94sXrxYvc8dO3YUK5Wb\/hTSTYfBHugq6d9iwAnNPvRz8cWYPHky9uzZg\/bt22PVqlX4\/PPPUaVKFeVHrVy5cgriuxR\/CzXvyevwufky7Zgyee0E6WwlTbIlEergKT4\/fu43WDbzQzz7Rn+89uSDKYidpOusbjOGbBMjoKnBk7yFcAM9ynyo7zbpIi4OG3KVwsZXOqNQzswo8uUcFDwZi1UteiDm8\/GoGXUJ4DVTbdsCdesivmlT5V989tln7QS7du1atfAaP3488ua1jVMuwmheprlZSDdl\/\/DdWrt2TQrLVGJUNAoXL43nHo9xeEgv1o246wx60fPWW2\/Z328fRkREPCKkGwHdfPbsWbX67NWrF6pWrapazBUqJyqSVPPmzfH888+r7T6MCJ0wYYLaN8tEYpy87qi6Kk1rnObj+CoVzZGCkPksTb5cSfM3CZerYf7WiZpIt27dcH\/tp3GrWDX1cUyZPA5lcWLglWU0Q7vStPnchg0bMGzYMLz33nv2NpKI\/\/jjDxXclS1bNhUsJpNvEA14TbpVqmBXszdVP99ISMR9E99DXIkyON7oZXVHbPvEgwBNnL17K+H3vvaa0nBpRqYZk\/1MYmUfc5zrRHMzF5vDhw9H9uzZg6jhwSPKiJWHkDEhHufPnMKt61dRrGBeJGTNi5f+VTrF+7Z3714H3I2t2Lx5Mz766CNl3mfQlSTXCAjpRsDoILm2bdsWnTp1cjD9bN++XfljOIFFR0cjLi4OXbt2VXnp7yW5zttyUv3WpOfsOD5OjL4kTogrV65Ufty\/78iqJl2Wz\/KMRM6JgckV8ZJw+\/Xrp9pRk7cyAMpPPGPGDMyfPx+tWrVSEzProw9QtGBfeisNntGkW7cu0KoV2M+Fd\/yI+h90xyfvfIoyiMNDe39EmWnjAd640aABMGIEph88qBZzXEQyYMo8bnX\/czyUKVNGLSolOUeA7xwXtgdOX8PpKzfVolctdB5NGXw2ffp0B9x1iTpGhLEYgrXnkSak6xmjkM5BLZMBJ+XLl8evv\/6qfLfa\/Pbdd99h48aNirA4edF81KdPH3VIRblKVR1IkITn6jg+XwHido9bt245BLkYSZ2aLTVsTfzOJgMuHLjFiHJrwqU81HIYCW30E9MfdfjwYQdtyFfZ5Tk\/IKBJd+5ce2GXChZDn\/YfAhUrKk3rjW8nIdf40bbve\/VC\/IABmDlzJmrUqKHcIUznz59XFhOOAR6swuQs0MoPEoddEdqSZCRdWrT43hkT5wYz7vr7v\/76Sy3WOY+4igkJO+BS0SAh3VSAFwqPkljpu6W2R3J65ZVX7BHKNBd1795dmelIyvv378fo0aOViXb\/pSgV6ERz3\/VbiWr1y2Q2\/6YVBhv+uKDqNydOxFwAMDH6ksEz\/Hn88cftwRv0Yffv319FZuugGk3EW7ZsURqSpOBDgASwZMcp\/HL4MornzYqa9+RBvTJZ0Lp1a3VYit4aZJZcLxZ5exX7m5oXXQ25c+dGhw4d1IJSkmsE6D4i5lrT5ftVMDpJ+c25j97T+7JixQpwnqEZnxYzSe4RENIN8xHCAzA46TDCk2H9R48etZvljCZX+nA5STHS80b2onb\/GlfATGULZUOLfxVz61f1N5TUehdvP4XdJxhMlaBkIPmT+B++O6cyjdNHzKhr455evYezWrVq9msEuZ2B5NyuXTu1P1hScCIweMVBO+nSxFks+qbSYi9evIgSJUo4TOzUcEnI3OZWv3599O3bF\/\/8J2+2OqjIgv\/LARme+5km5sXbTyvSrV+pgDItM9aDW7GcLXT4HQ8nIcnyuFZquI888ohXV3Z6lip8cwjphm\/fpmjZgQMHVDQnXxrjPjr6xGjmJYFdvQWMX30Ypy7fxNEL15ElKqOKKNVBTNrfWiJfdJoQMMmVZLv7xBX1m4mTgSZ\/Xb8z\/y7J9ssvv1Skqs3qmpBpambUtPZfR1C3h1RTucia+eMJ5dMf1rCsg+l427Ztai+3WaPieGZi5Oy+ffuQKVMmVKhQQTRciz3Pd67bl\/vVe9bzibtxb76kFOZ6c1Eac2rBnDu46BWLgjXAhXSt4RQWuRixzFUpSUmfRGVsGF++mT8ex4Y\/bGZlTbYkXp20mZkkXKloTr8SL0n2yPl4RfaacHW9lMe4EKDWy0nZmLhtoUePHujZs6cKliLx\/vLLL2p7FCeFDz\/8MMU+4LDo2DBqBE3M7351QFkzetUrlcJfyz3ZZuLlYpLmZLpGJDrdt8FACwOxH\/1CeeTAtRSky+jkefPm2Rc8grlvOPMpIV3fsQvJJ82b23Uj9NYg+lG1dsuACpIsf4rnjVa\/3W3b8TcgWuvlPl1NxCRfar38jrL0fKKUXSYdRcmtSfTv0UfN7U80m9NPrbdB+VtOKc9\/CLBf23y2By1rFFXBPM6CpIzmTfoQnRGx\/ySKjJJmbDqO1fvP47OWtj36ZkyJOecO7ghgsJpg7vu4ENL1HbuQfJKRhozs5b5c+nn1nttvdp\/F5esJyqzHQy4CTbBWwTSanylzrqxRaFq9iH1vL33Y9F0zsCNPnjxo1qyZ8jfJxQlWEU7ffOxfbh2ib9F8GItRMk76jMpnYhQzD8YQLdf3vqNflxYuo\/XIiDEXsTwUo02bNqoS+sw1Aftea2Q+KaQbmf2uWm3ch0uSpZ\/U1z236QGj+UQsV4d0pIdsUqdvCGiLS6Ci5H2TMvye0vt1adKXlLYICOmmLb5BWbrVE6WCUngnQjnb2xtKi4dQwTkQcjojXR2lvHPnTiUCDzhxtX0oEDKGYx1WSJd+XB5mYzz1KxyxSOs2CemmNcJBVL6RbClWuGkTxr294da2IBpGaSqKmXT1eb88DINEq\/+vV6+eukaOREzTp+wRTV23WCFd80Upqasxcp8W0o2QvjebYhmkEsigqEDBHCntDBSega7HTLrOAqmocTFCnaerSVCPf3rISLruLAuMYuaBOuLP9R13IV3fsXP75LlzQLNmAO+EHzsW0Ae17N8P8M7t558HGje2\/c0rbHUe\/X2PHrbnhwwB+vd3rKpePWDOHCB\/fs\/Ca+124pQELPjAdrRbu3aOMnkuJfRy6OPtKLnxFKvQa0lkSWyFdEkK1HK5L5fRy5G4fSWQ84sxoMo4Go0WBs5Hr7xi+zYS5pfUvJVCuqlBz8OzJMxFixh+D5Qvb8usB+eGDUCBAjbSpauK\/8fEAM5Id+NG6yRrFEnfc\/vrL1H4uNud+O+qBNxdLMpO+v36pWHjg6DocPNdBwGkaS6CM58uJ31eXKEjlKlt8XzwuXPnqtOozHtI01zIIKnAn\/NLi77ncPjqZbU32tvE+Yn3jBjnNCoV4T6\/eIuTzi+k6ytyFp7Tg\/Hzz21aKxNfFE2ivDhFk67WXvVnRk3XFenq1S7J2jjAzSbWE7\/kw7LZ2RX5k+idaeAWmhOyWcxR2uFqWg\/ZDjII7ip62bx9hWeJ81xlHkcYqdtX\/Dm\/OCNdV\/OLeZxRkRg50qZcROL84u17J6TrLWJe5DebgHipCglPk6TWaitUsA1YknO1ajYiTkG6DeYhf8emDrWbXwpXmp2uh\/eAa+1al+9Fc0I+qwRaBX8XypYh633kz\/mFpJtr6QzUH9XdLoBV0pX5xXqfMaeQrnd4eZ3baAKiFqvNMEZT8ptvAtu28Toym8baoYMj6Zp9ukbNWQvkac+tXhUzv7PnvW5YiD5gtgLwIBCevCUpOBAQ0vWuHwI1v3iSSuYXTwglfy+kax0rn3Ia\/R2rVyeblhkEZfTfag23cGHg1CmTpvv1eczZUg75Z4wCWrRwkMOK39IoA7Vqo7btU6PC4CEre3t5djMTL4KQFBgEiDmvmvtX+TvdnkgVGGmCvxa\/zC8bgb7PrUTN9k8CM2akmGM8oSDziyeEHL8X0vUOL69zG01A1GSN\/ld3kcpaG1U+4LE\/Y86F+sjf4mnbS3H7NCl9qTz\/577UysVyOj1RyuhHJtmb\/\/e6UWH0gDOTMyd+3tW7detWe0t5QxF\/JKUNAoK5b7j6ZX5hoGbcs8i\/cZmNcG\/PMVYlkvnFKlK2fEK63uHlU27jth8dpcyCzKSr\/2c0s510u16wkS6aIT\/OAUlJ6vhG7qvbF3sTX44sjKcei8KoYa4v6jZGTGtN17yVyaeGhclDRpNz3ky3kPPUVnVDkTlR423QoIFovn7ud2K9fPlywdxHXFM1v3BR\/794zFlX3Da\/MCUlqV9Wfboyv3jXcUK63uHlU25tfjHvrzWTLp26c6qPwytnx+HzAm+jWY6lGHKxEzZe\/Ecy6d59tyJdpvOJefHG39MQUysKrSYUUvsWH3zwQTRu3BglS5ZUF0zrZHwxvdnn61ODQ\/Qhar07ft6IzHEnXLaAVwbWrl3b\/v2RI0fU1YHcO8oTk3i5gtwr6t0AWLNmjbIsuEpmzI35SNi8tjGSL6u3PL9wy+K4M3jl7YKO88v1BzDn+vPJpMsVOUn37zxodnY8Ygr\/gX4DMjqYnc24y\/xifcwL6VrHKjA5aYNu2RJYs8ZzfZz8Z8xAUsmSauI\/duwYSpcurS5yZ3rzzTfVEXmSrCPw6aefesz8+uuvqzy8salTp05K++V+UZ7Sw2sFuZVFiNcjjPYM3mDOh27evKm2Ci1duhRLlizBpEmTUKlSJesVRnpOH+YYnvIjuPtn4Ajp+gdH\/5cycCAwaJDzcrkSfe01gHkA7N69W90XO2rUKBQrVgyJiYnqlB7+rlixov9lC9MSuXrnRd2eUtOmTZWJmYcyzJkzR537mz17dpw8eRJ9+vTB4MGDUbx4cU\/FyPeAMil7g3lcXBx69+6tSLdIkSJqjHPcR7Km6\/NA8mKOsYI78zBJX7jvESFdn0dsGj3Izbxt2wJz57qugIEOPEOybVvceO01vPvddzhz5gyqV6+OmJgYdb+o0bScRpKGZbGetK7EqGi0b\/Wqavvx48cxZMgQ9OvXTy12ePg+CXjs2LGKECR5RoCukgWfTXebkQuc+g1fdAgSTEhIUNjfe++9Lm8c+u2335TZn1YIsTzchtjK\/GLsjV69gOHD7Z84w51kyzFPvzwJt\/D\/b8EYOHAg6BaQlBIBId1gGxX6pahbFzhyxLm226QJcOgQ8NNPuLpiBZacP4\/8tw9injlzpppkaPaUica7zuWxmdt\/2oDrZ4+4fDBrgRJo3uhJHDp0CGPGjMGOHTtw\/fp1dSrS2bNn1WHwDRs2VH5GSdYQmL34v24xv5mjKJ558jGHCzpiY2PVJfa85u\/u2z5IXduNGzcwa9YsjB49Wl1Dxx\/pDxPpcn5p1cpmLXNmUWMUM4+ZatAAoDuFecGzBFLivnr1anz11VdqEcQF0rp16\/DRRx9h\/Pjxsvh08goI6VqbFwKXy0i6n31m8+1yUsmRg3bkZDn27rUFNowYAdSqZf+cL0WPHj0wbNgwdQOLJO8Q4B7RxNjNiLp+IcWD1HKrxDyGSkVzoEuXLnjiiSfw4osvquvmxo0bp0z5jRo18q5Cya0i8WO3rXGJeca7H8LrdRy1pq+\/\/hrr169XE32WLFnsKDKwbejQoUoD\/vHHH5UpumrVqoKyRsA4v5BI\/\/1v2xyTKxdAv\/imTclYMYq5d2+AGutt0nWFuxFguQLQ\/XAT0g2211G\/FHfdBXzwgY1wf\/gB4MkaW7YA+\/bZXpKlS3F9wAB8XrkyXvroI\/s2FprT2rRpo7QAmpsleYcACWDP4TMqgjn60p\/qYZJtQta8iM9dGi\/9qzRunDuqJnb6EgsWtN3cxOhbXjU3cuRI5M2b17tKJTdGrvjNAXNqTOeScirM\/1GyIHhetk56Un\/22WdRp04dWx8lJmLZsmVK4+ratasyK9PfTmuE+BgNA8xIuqVL20iXc8wbbwDnzwPt2ycHci5dCjCwcNQooGJF+13GRtydDd39+\/erPuD7ITElKRES0g22CU+\/FAxK4Ar9drAUpk\/nzG7zr\/Cz\/ftxY98+jC5UCC1nzlRRs0w80IF+xQkTJohpx4e+5UlV87actD956\/pV5MiREzcSEu1XBNK0PGDAAIwYMcIBd5ozGUkrpOs98MSc2GeJyojjZy6gWMG8CnOmptXvdDAt7927V2m4JFT6zi9cuKACCbkAoimZmi\/7hsFszZs3916YcH7C7L5iWzmfGOcXfvbuu8D8+bbPb1vSzLibYaK\/l6Zl9gVvgXrttdfExeVkLAnpBtsLpl+KKlWAnj2TpTOZefDVV0gaNgxfVq+OHblzo3379jh9+rQa8IyufeGFF8SP5WPf0sTMAB+SwNEL11GtZC5FBtS2eE4zJxcuaujDJe706XKhU61aNfW\/+A+9B17ff0yi5d+FcmZWRJs7OgrtH3WMBJ8+fbqKFO\/Vq5ea1OlT5N9169ZVJJsrVy5069ZNBfOIpmXqCyPp0kqg\/eHG+YWHxHN3BIM1+ft2MuPOj5OSknD06FEsXrwYCxcuVOcDsC\/uu+8+eQ9cvAZCut7PD2n7hNnnwtrWrrUN\/m+\/VWYelfhiNGiAW0OHYq26p3eO+phXnjGCWaKXfe8mTQBG0iUJGCd\/Ei8PdSDujN7kwRjcE230L\/ouQWQ+OWLlIaXd\/nL4MornzapIl8eb1rwn2VxP0zKDBWvUqKGi9HXi1iNqWbNnz8aWLVuUa4VBVqVKlZLJ3zicPM0vdJd07gyMH2+7kux2coY7LQyMZeCih5rtM888owIKZdHp\/v0V0g22+c1ZSH\/Jko6EayBdcyBVsDUnVOUhARhJt2yhbMrMKSntEKA\/nYSrSZdWBWJObddqYuQyt3BdvHhRRTVT45WFkAE9T\/MLNV4GZxrTtGn2QCr9MQm3c+fOKoqfvlueSy67JayNUiFdazhJrghDgD7GDX9ctJuXG1aMxoBuHdCkSROX+0IjDCK\/N5cWhiU7TtlJt+Y9eRwWOvTTfvLJJ5g7d67aFucs8VCYvn37KiKQA0r83kUOBfJsAO7N\/eKLL3D58mW88sorou1agFxI1wJIkiXyECAB0LdLn26d8vnQvGpOpTVRgypRooTy4UZHRytgGCnbunVrRQT0Z0nyHYFxqw5j9f7zyrzcq14phwAqki61V26L42+a9M2JRMBDSng+tmhevveDN08ycvzw4cPKp7t9+3Y5HMYDeEK63owuyRtRCPRZegC7T8Shc50SqFoogyJdHvO4bds2bNq0yYF4CQxJgUmI1\/dhsnj7Kcz88YTaCz2soeM+c026JNsFCxY47QPfa5YnBYHAICCkGxicpZYQRICa7je7z2L0C+WRP+q6nXR56IizSZ+mTR5Kwq1D+fLlC8EWp7\/IjBp\/dcYu1K9UQAWuaSsCtVcmBkdpDZd49+zZU+2PloNg0r\/vRAJrCAjpWsNJckUgAgzsmbflL0xsUhF\/x192IF2t2fLgfW1qFu0r9YOEpNtx\/l40rV7E4UAMjTd9ujoxennixImKdLlNzpWfN\/VSSQmCgP8QENL1H5ZSUpghwPt1qenSt+gqgpZEy9O\/mEgC06ZNEy03FeOApMvIcWq6xq1CmnSNvlyjFizYpwJ0eTSgCAjpBhRuqSyUECDpbjx4UZk5vdm2Ejqxf+IAABPrSURBVEptDDZZSbo065v35wabnCKPIOArAkK6viInz4U9AmbS1Wf+8gAACZZKm+53R7pWtgyljVRSqiDgPwSEdP2HpZQUZgiYSdcYPWtuKr8z+nfDDIqANccT6XraMhQwQaUiQcBHBIR0fQROHgt\/BIyk6yyQyhnx8jPRgn0fG1ZIV7YM+Y6vPJn+CAjppn8fiARBioAn0t28eTPmzZtnj16WLUOp70gz6cqWodRjKiUEFwJCusHVHyJNECFgNi+btwTRpMxLvWfMmKH2icqWodR3nidNV7YMpR5jKSF9ERDSTV\/8pfYgRsBZ9LJxixBvFeKF3m3atFGtYICVJuAgblZQi+aJdGXLUFB3nwhnAQEhXQsgSZbIREC2DAW+32XLUOAxlxoDi4CQbmDxltpCCAEh3cB3lpBu4DGXGgOLgJBuYPGW2kIIgR\/383q\/C3i9Tjk5HCNA\/cbL6Hk4xr\/K35niRKoAiSDVCAJpioCQbprCK4WHIgKc+H\/\/\/Xds3brVLj4v6eaPpLRBQDBPG1yl1OBDQEg3+PpEJEpHBDj582Ju\/jannDlzokGDBuBvSf5DQDD3H5ZSUvAjIKQb\/H0kEgYQgTVr1igt11UqV66cuiDdWSJ5ZMiQATly5AigxKFflTeYJyUlYc+ePeDWoVu3bqFx48aIiYlBlixZQh8IaUFEICCkGxHdLI20isCnn37qMevrr79uz3Pz5k11\/OPSpUuxZMkSTJo0CZUqVfJYhmRIRsAbzHkgSd++fdG7d2+UKVNGkS8XOv3790d0dLTAKggEPQJCukHfRSJgoBCgpsoTpjwl3t1KE3NcXJya\/Em6RYoUQWJiIkaNGuWg6TIPk2i\/zlH1FvOrV6\/i1KlTKF26tCrw8uXL6iL7du3aoWrVquozwdzTCJbv0xMBId30RF\/qDioEjpy\/jv9+OdutTIlR0erCdONVfwkJCRgyZAjuvfde8FxgJt5INGHCBCxatEgRbsWKFZWGRnKWlIwAtwgt+Gy6W0i4wKnf8EWnEeQXLlxA586d0alTJ2VhEMxldAU7AkK6wd5DIl\/AENh1PA5r165B5rgTLuvMWqAEmjd60uH72NhYdZH9+++\/D56YxHTo0CF88cUXeOONN5RW\/P3332Pt2rXKDCr+R0d4Zy\/+L66fPeIS85s5iuKZJx9DiXxZHfJQ6x0\/fjyI\/+jRo3H27FnBPGBvi1TkKwJCur4iJ8+FJQLcI5oYuxlR1y+kaB+13Coxj6k9pMbE85fXr1+vtF1XhMrgrPfeew9jx45Fvnz5whI7XxvFxc76Vd+6xDzj3Q+pvdJMDKSieXnZsmX47LPPUKdOHXTp0gV58+ZNUb1g7muPyHNpiYCQblqiK2WHHAI8DIOHYlDbjb70p5KfZJuQNS8yFylnn\/x1w\/TF9jyDmQRgTDQ7kyAyZcqEqVOngpqZaLrOh8TIFb85xTw+d2m1yIkpkwe\/\/voreMkEb3N68cUX0aRJExQvXlwFUukkmIfcKxdxAgvpRlyXS4M9ITBi5SGVhf7GW9evKvNwlqiMyrzZtLqjlrt3716l4Y4ZMyaFv\/bMmTOYPHmy0spatWqFZs2aIVeuXJ6qj8jvv9l9BtR4byQkqj3SmbJmt\/twG1ctiP99NQ\/Tpk3D0KFD1ZatqKgopzgJ5hE5fEKq0UK6IdVdImwgEJi35SQYVMWfoxeuo1rJXIp0Sbhmv+L06dNx8uRJdXE9iYDRtCSNO++8ExkzZlTi0vzMrS6i5bruPRIuiZek+8vhyyieN6vCmj9PV8ypospnzpyJrFmzqmC15557DgULFlQFCuaBeCukDn8hIKTrLySlnLBBQBOAkXQL5cyM9o8Wd2gjTcskgho1aqBKlSrqO2cX2Ytv0drQoD\/99JWbDqRbv1JBVC5mO2yEW7L279+PhQsXqqjwatWqKT85FznDhg1TwVTaXy6YW8NccgUeASHdwGMuNYYAAjQxG0mX2i4JwFNiBG23bt3Qo0cPtYWFgT+MYv7hhx9S7OH1VFakfU9Nl1qu1nRJtuaFjsaEh5IcP35c+XQvXrwomEfaYAnh9grphnDniehphwAJYMWus3bzcot\/FUPB6CR1GAYvq6c52VXasGEDBg4ciEceeURtY\/ntt98wbtw4VK5cOe0EDoOSuciZ+eNxO+n+p3IBSwsdNl0wD4MBECFNENKNkI6WZnqHAE3MNHfSp1unfD50qVtSRc5yH64+AMNYIr\/jyVTDhw9XxxHS9Lxv3z6VpUKFCnJEoUX4x606jNX7zyufbq96pZAD19C6dWswQGrGjBkoW7ZsipK0SZ+mZkaLC+YWwZZs6YKAkG66wC6VhgICfZYewO4TcehcpwSqFsqgTJh9+vRxOvGzPSReJndacCi0Oz1lpGl58IqDqFQ0B4Y1TCbY8+fPK\/LduXMnnn76afvihrI686OnZxukbkHAHQJCujI+BAEXCMzYdBzf7D6Lqa\/+A3\/HX05BuoxIZlSt1m5l8k\/9UOI2rVdn7ELT6kVSbM\/SpRP3l19+2U6+x44dSxFIlXpJpARBIG0QENJNG1yl1DBAgAdlfLL+GCY2qaj2jC5YsACbNm2ykyw1W24H0mZP8\/dhAEHAm0DS7fblfjSqWsijP5d48\/jNfv36Yd26dQ7RywEXXCoUBCwiIKRrESjJFnkIkHTpX+xcp6T9oAY90RMNmjl5ElWbNm0UOAywcuV3jDz0fGsxSXf86sPKj17znpRHO5pL1WZnfs7DM+SITd9wl6cCh4CQbuCwlppCDAGS7saDF9W2FeOtQiHWjJASl6TLADYe+2iFdEOqcSKsIABASFeGgSDgAgEz6RqDefgIbxVyFsksgPqOgDvSpTmfl9bPnTsXDz\/8sO+VyJOCQDoiIKSbjuBL1cGNgJF0M+OW2qPL06dItPqig3r16mHKlClOo2qDu3XBKZ0n0uWWLV7l52rrVnC2SqQSBJIRENKV0RA2CJw7BzRrBvBK27FjgehoW9P27wd4t\/zzzwONG9v+pqKk8+jve\/SwPT9kCNC\/vyMsdercQuHCXTFo0Fv2LUOMVu7Zsyc++OAD9Zk5kGrOHOCVV2zltGvnKFPYgO7nhlghXS56JGjNz8BLcQFDQEg3YFBLRYFAgIS5aBGwYAFQvrytRk1+\/39QFAoUsJHuzp08xQiIiUkmZSPpbtwIvDX0Inadu6B8us62DNHcTC33rbfeUodfGLcM7d2bDzVr2urQdZL0+\/ULBAqhW4eZdN2Z9M2LntBttUgeSQgI6UZSb0dAW0mWJLvPP7dprUwkYn5O8j17Npl069Vz\/Mwd6eotQ7Nnr8D169NQu3YmPP64bb+o9jEa9+0uXhyNkSNt5E\/SdaaBR0B3eN1Eku7GfuOQq33rFIFU2qerC+UlExMnTlSWhqZNm4qf12u05YH0QEBINz1QlzrTDAGzifnaNRvhUaOllqlNyRUq2AiR5Fytmo2InZEu5k9FzJAu9ujlqVOX4K238iNr1q149dVYdU9uhw4d1BGQxi1Dup5Jk5I1XV1+mjU+HAqOjQVKlcKuDbtQOaaSQ4vMx3AatWASsGwZCocBEP5tENIN\/z6OuBYaTczUbLWZ12hKfvNNYNs2gHM8ybhDB0fSNft0jZqzVUC11s38vjxvtZ6wyjdzJtCyJS59NAW537Dtf5YkCIQTAkK64dSb0haFgCY7+lNXr042LefP7+i\/1Rpu4cIAz8k3a7ojmq5ClRaPATNmAC1aeIWuUQZq1UZt26uCIi3zv\/8NrFljw5u4SxIEwgwBId0w61BpDmA0MVOT1aZlYuMuUllro3YfcNyzyL9xmU8EYPQjk+zN\/0s\/OUHgtmnZ\/s2hQ7ZQdEmCQBghIKQbRp0pTUlGwLjtR0cpOyNdTcKMZnYg3f\/FY8664siPc7ZCk5LUL03oRiJ3hrsxYlpruuatTBHbX9RknSV+PmhQ8jcDBgC1a6fMSSCFjCN2+IR6w4V0Q70HRX6nCGjzro5QprbpjHT52ZxxZ\/DK2wXxeYG30SzHUgy52Akbb1TDnPhGyaR7e5I\/93ceNDs7HjGF\/0C\/ARndmp2NxG+WI6K7jRpty5Y2M7K3if3www9Cut7iJvmDBgEh3aDpChEkXRHwhgiofdHfaNK2rly5ggwZMiBHjhzp2pSQqXzgQEfN1p3gxPq115A0YAD27NmjjoO8desWGjdujJiYGGTJkiVkmi2CRjYCQrqR3f\/SejMC7ojg9sQP5rmdbt68qbYLLV26FEuWLMGkSZNQqZLjVhcB2Q0C1HYZPOWJcLnIqV0b3Avdt29fdSRnmTJlFPlyodO\/f391QIkkQSDYERDSDfYeEvnSHgFu5m3bFpg7131dnPgTE4FVq4ApUxCXmKgmf5JukSJFkJiYiFGjRomma7XHrOCeOzdw6ZKtxGnTcPWll3Dq1CmULl1afXT58mV1FGe7du1QtWpVqzVLPkEg3RAQ0k036KXioEFAT\/516wKtWkFpssaAHi1ow4bA9u22cOgpU4Bs2dQ3CQkJGDJkCO699177rUNJSUlYtWoVBgwYgJMnT6rTknjheuXKlYOm2ekuiMa9ShWgVy\/X4ly9Chw+bPOfcx9vxYr2vBcuXEDnzp3RqVMnVK9e3aGM3377DTxAg9hHRUWle3NFAEGACAjpyjgQBMykq\/eKUsuiqZhRWTqNHw\/89JMD6fLWGxIqr\/rj7TdMGzZsUEcUDh48GOXKlcNPP\/2E8ePHY8yYMUorlgRA416sGNSZma4SLQwPPQR07w7MmmU74gvA1atXFabEf\/To0ciZM6f6\/MaNG5g1a5b6rGPHjuqHJmhJgkAwICCkGwy9IDKkLwJG0qXZkqRL8nzjDeD8eaB9e+DJJ22bfMeNA37+2YF0v\/76a6xfv15puwzoofbVo0cPtGjRAjV5HNZtgiAxv\/rqqyk0svRtfDrWrnHfutWGLRO3CZUoAUyfnrzYoXVg1y5lXk5q2VKZl5ctW4bPPvsMderUQZcuXZA3b171+JEjRzB06FBldfjxxx+V+V\/MzunYx1J1CgSEdGVQCAJG0j1yxIYHTcyc+H\/\/XUXNYsIEgBM7z47Ml89Ouvpe3WeffVYRANPatWvBc4Jp7qSJ88knn0STJk2UifOOO+4QU6ceccS9aVNg2TLbIoc4G3HnQud2kFVSXBwuvvgiFvJmp7\/\/xosvvqgwLV68uNJi6U8nEX\/11Vfo2rWrMivPmTNHWRYkmlxe8WBCQEg3mHpDZEkfBIykS+LUW4F69wbKlbPJ1Lq1o2wvv6yId+\/hw0rD1WZj7d8l2VLjogY2depUZQplhK1sbTHASNyfecZ2z+KWLSlxp389NhYJLVpgRvnyyLp8OR555BHc9fnnDgsXWhbee+89FCxYUJmSiTEXPSTk5s2bp8+YkloFARcICOnK0BAEzD5dm7pq07y+\/dYhcEd9\/umndk13+vTpKlCqV69eighIALx1qFu3bnjggQcUtvr7QYMGoVSpUoK3UdMl6XIBQ4I14376tMI\/rm9fLOnTBw\/MnImpZcuiQrt2eO655xTJMq1evVrhX7duXUWyuXLlUvgPHDgQFQ1BVwK8IBAMCAjpBkMviAzpi4CzrSslS6YkXE0Kt0k3PkMGzJw5EzVq1ACvlmOiWZMTfp8+fVC2bFn12dGjR5WPl4FWQromTde8VcuMO60NI0aoh5KmTsW+GjWwcOFCLFq0CNWqVVMaLgPTeDDJunXrMHv2bGzZskWZ9jXeEkSVvq+X1O6IgJCujAhBwI8IMHKWGtbjjz+ufLzcOvTFF19g06ZNGD58uBzg4CeseSjJ8ePHlQnZuB2I+Pfr1w8XL15UkeRcAIlJ30+gSzF+QUBI1y8wSiGCQDICv\/\/+u9pCdN9996ntKzt27MC4cePU1iFJaYvAgQMH1IlVPKSEhCxJEAg2BIR0g61HRJ6wQIBRzfv27VOkywMxsmfPHhbtCvZGnDlzBjt37kTt2rUlSjzYOytC5RPSjdCOl2YLAoKAICAIBB4BId3AYy41CgKCgCAgCEQoAkK6Edrx0mxBQBAQBASBwCMgpBt4zKVGQUAQEAQEgQhFQEg3Qjtemi0ICAKCgCAQeASEdAOPudQoCAgCgoAgEKEICOlGaMdLswUBQUAQEAQCj4CQbuAxlxoFAUFAEBAEIhQBId0I7XhptiAgCAgCgkDgERDSDTzmUqMgIAgIAoJAhCIgpBuhHS\/NFgQEAUFAEAg8AkK6gcdcahQEBAFBQBCIUASEdCO046XZgoAgIAgIAoFHQEg38JhLjYKAICAICAIRioCQboR2vDRbEBAEBAFBIPAICOkGHnOpURAQBAQBQSBCERDSjdCOl2YLAoKAICAIBB4BId3AYy41CgKCgCAgCEQoAkK6Edrx0mxBQBAQBASBwCMgpBt4zKVGQUAQEAQEgQhFQEg3Qjtemi0ICAKCgCAQeASEdAOPudQoCAgCgoAgEKEICOlGaMdLswUBQUAQEAQCj4CQbuAxlxoFAUFAEBAEIhQBId0I7XhptiAgCAgCgkDgERDSDTzmUqMgIAgIAoJAhCIgpBuhHS\/NFgQEAUFAEAg8AkK6gcdcahQEBAFBQBCIUASEdCO046XZgoAgIAgIAoFHQEg38JhLjYKAICAICAIRioCQboR2vDRbEBAEBAFBIPAICOkGHnOpURAQBAQBQSBCERDSjdCOl2YLAoKAICAIBB4BId3AYy41CgKCgCAgCEQoAkK6Edrx0mxBQBAQBASBwCMgpBt4zKVGQUAQEAQEgQhFQEg3Qjtemi0ICAKCgCAQeASEdAOPudQoCAgCgoAgEKEI\/B8BC3JMpe1AyAAAAABJRU5ErkJggg==","height":235,"width":477}}
%---
%[output:4de63e59]
%   data: {"dataType":"text","outputData":{"text":"多播树示意图已保存至: c.输出\\3.部署方案\\1.最短路优先算法\\US_Backbone\\多播树示意图\\MulticastTree_Req_32.svg\n","truncated":false}}
%---

```

---

## resultPlot.m

```matlab
%[text] # 4.RESULTPLOT  
%[text] 主入口：批量加载 sfcMapping 生成的 result.mat，并输出论文作图
%[text] 依赖：b.常用函数\\6.结果绘制 下的各个指标函数
%[text] 输出：thesis\_plots\_output 目录下的 svg 图与对应的指标变量 mat 文件
%[text] 
%[text] 使用说明：
%[text] %   1) 离线模式：先运行 deployAndDispatchPlan.m，再运行 sfcMapping.m
%[text] %   2) 在线模式（ResourceAndDelayAwareOnline）：只需运行 deployAndDispatchPlan.m
%[text] %      结果已直接保存，sfcMapping.m 会自动检测并跳过重复部署
%[text] %   3) 在 getPlotCfg() 中指定拓扑名（如 'US\_Backbone' 或 'Abilene'），或留空不过滤
%[text] %   4) 运行本脚本，会一次性生成 QoS / 资源效率 / 稳定性三类指标图

clc; clear;
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'a.输入')));
% 加载常用函数与绘图函数
addpath(genpath(fullfile(currentDir, 'b.常用函数')));
addpath(genpath(fullfile(currentDir, 'c.输出')));
%[text] ## % -------------------- 1) 加载配置 --------------------
% 可指定拓扑名进行过滤，如 'US_Backbone' 或 'Abilene'；留空则不过滤
cfg = getPlotCfg('US_Backbone');
% cfg = getPlotCfg('Abilene');

% 可按需调整配置
% cfg.figVisible = 'on';     % 调试时打开图窗
% cfg.slackMode  = 'abs';    % 'ratio' or 'abs'
%[text] ## % -------------------- 2) 扫描/加载结果文件 --------------------
baseResultDir = fullfile(currentDir, cfg.baseResultDir);

if cfg.autoScan && isfolder(baseResultDir)
    files = dir(fullfile(baseResultDir, '**', '*result.mat'));
    resultPaths = arrayfun(@(f) fullfile(f.folder, f.name), files, 'UniformOutput', false);
else
    % 如果不使用自动扫描，在此手动填写需要对比的方法结果
    % resultPaths = {
    %     fullfile(currentDir, 'c.输出', '4.资源消耗与失败日志', 'RDA_result.mat'), ...
    %     fullfile(currentDir, 'c.输出', '4.资源消耗与失败日志', 'SPF_result.mat')
    % };
    resultPaths = {};
end
if isempty(resultPaths)
    error('未找到 result.mat 文件，请在 resultPaths 中手工指定。');
end
%[text] 
% 拓扑过滤
if strlength(cfg.topoFilter) > 0
    mask = cellfun(@(p) contains(lower(p), lower(cfg.topoFilter)), resultPaths);
    resultPaths = resultPaths(mask);
    if isempty(resultPaths)
        error('按拓扑过滤后为空，请检查 cfg.topoFilter 或手工指定 resultPaths。');
    end
end

% 方法名称（用于图例）。默认取文件名作为方法名，可根据需要覆盖。
% 在线模式结果文件名为 "ResourceAndDelayAwareOnlineResult.mat"，自动提取方法名
methodNames = cell(numel(resultPaths), 1);
for i = 1:numel(resultPaths)
    [~, fname, ~] = fileparts(resultPaths{i});
    % 移除 "Result" 后缀，得到更清晰的方法名
    methodNames{i} = strrep(fname, 'Result', '');
end

% ==================== 可选：按配置筛选方法，并固定顺序 ====================
% 说明：cfg.compareMethods 非空时，只保留白名单中的方法，并按该顺序排列
if isfield(cfg, 'compareMethods') && ~isempty(cfg.compareMethods)
    keep = ismember(string(methodNames), string(cfg.compareMethods));
    resultPaths = resultPaths(keep);
    methodNames = methodNames(keep);

    % 按 cfg.compareMethods 的顺序排序（未命中的自动丢弃）
    [~, ord] = ismember(string(cfg.compareMethods), string(methodNames));
    ord = ord(ord > 0);
    resultPaths = resultPaths(ord);
    methodNames = methodNames(ord);

    if isempty(resultPaths)
        error('按 cfg.compareMethods 筛选后为空，请检查 compareMethods 与结果文件方法名是否一致。');
    end
end

% 显示找到的方法
fprintf('找到以下方法的结果文件：\n'); %[output:8b39b225]
for i = 1:numel(methodNames) %[output:group:6d0dab60]
    fprintf('  %d. %s\n', i, methodNames{i}); %[output:213abc6f]
end %[output:group:6d0dab60]
fprintf('\n');

% -------------------- 3) 读取结果 --------------------
% 关键：把 cfg 传入，使 cfg.methodDisplayNames 映射生效（图例名将变为 NIF-Greedy / SPF-Greedy / RDA）
methods = loadMethodResultsFromPaths(resultPaths, methodNames, cfg);

% -------------------- 4) 统一绘图与保存 --------------------
outDir = fullfile(currentDir, cfg.outDir);
allMetrics = runThesisResultPlots(methods, outDir, cfg); %[output:2129cb7e] %[output:1a2f9b1e]

% 额外保存一次总览，便于论文表格或后续分析
save(fullfile(outDir, 'AllMetrics_ForPlots.mat'), 'allMetrics', 'methods', 'cfg', 'resultPaths');
fprintf('✓ 论文结果图与指标已输出到：%s\n', outDir); %[output:61ab821d]


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":32}
%---
%[output:8b39b225]
%   data: {"dataType":"text","outputData":{"text":"找到以下方法的结果文件：\n","truncated":false}}
%---
%[output:213abc6f]
%   data: {"dataType":"text","outputData":{"text":"  1. nodeFirst\n  2. shortestPathFirstWithLoadBalancing\n  3. ResourceAndDelayAwareOnline\n","truncated":false}}
%---
%[output:2129cb7e]
%   data: {"dataType":"text","outputData":{"text":"数据已导出到: F:\\00_当前工作\\251020-代码阅读与魔改\\代码整合\\c.输出\\5.结果图保存\\Data_CumulativeResourceConsume.xlsx\n累计资源消耗数据已导出到 Excel\n  失败分布数据已导出到: F:\\00_当前工作\\251020-代码阅读与魔改\\代码整合\\c.输出\\5.结果图保存\\Data_FailureBreakdownDistribution.xlsx\n","truncated":false}}
%---
%[output:1a2f9b1e]
%   data: {"dataType":"text","outputData":{"text":"正在导出指标数据到Excel...\n  √ 接受率曲线\n  √ 端到端时延曲线\n  √ 松弛比曲线\n  √ CPU消耗曲线\n  √ 内存消耗曲线\n  √ 带宽消耗曲线\n  √ VNF共享增益曲线\n  √ 综合汇总\n✓ 所有指标数据已导出到: F:\\00_当前工作\\251020-代码阅读与魔改\\代码整合\\c.输出\\5.结果图保存\\AllMetrics_Data.xlsx\n","truncated":false}}
%---
%[output:61ab821d]
%   data: {"dataType":"text","outputData":{"text":"✓ 论文结果图与指标已输出到：F:\\00_当前工作\\251020-代码阅读与魔改\\代码整合\\c.输出\\5.结果图保存\n","truncated":false}}
%---

```

---

## sfcMapping.m

```matlab
%[text] # 3.sfcMapping
%[text] 进行实际的sfc映射工作，并计算资源消耗和接受率
%[text] 
%[text] **注意**: 在线模式（ResourceAndDelayAwareOnline）已在 deployAndDispatchPlan.m 中完成部署，
%[text] 本脚本会检测并跳过重复部署，直接使用已有结果。
clc; clear;
%[text] ## 1) 导入路径
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'a.输入')));
addpath(genpath(fullfile(currentDir, 'b.常用函数')));
%[text] ## 2) 选择拓补与部署方法（只改这里和对应配置函数）
% topoName = "Abilene";   % "US_Backbone" 或 "Abilene"
topoName = "US_Backbone";   % "US_Backbone" 或 "Abilene"

% 可选方法：
% - 'shortestPathFirstWithLoadBalancing': 最短路优先（需要sfcMapping部署）
% - 'ResourceAndDelayAware': 资源与时延感知离线版（需要sfcMapping部署）
% - 'ResourceAndDelayAwareOnline': 资源与时延感知在线版（已在deployAndDispatchPlan完成部署）
% deployMethodName = 'ResourceAndDelayAwareOnline';
% deployMethodName = 'nodeFirst'; 
deployMethodName = 'shortestPathFirstWithLoadBalancing'; 
%[text] ## 3) 加载配置
topocfg = getTopoCfg(topoName);
reqCfg = getReqCfg(topoName);
deployMethodCfg = getDeployMethodCfg(deployMethodName,topoName);

%[text] ## 4）根据模式进行映射
if isfield(deployMethodCfg, 'onlineMode') && deployMethodCfg.onlineMode %[output:group:3738a4a0]
    %% ========== 在线模式：部署已完成，直接加载结果 ==========
    fprintf('检测到在线模式: %s\n', deployMethodName);
    fprintf('在线模式已在 deployAndDispatchPlan.m 中完成部署。\n');
    
    % 检查结果文件是否存在
    if isfile(deployMethodCfg.resultPath)
        fprintf('正在加载已有结果: %s\n', deployMethodCfg.resultPath);
        load(deployMethodCfg.resultPath);
        fprintf('✓ 已加载在线模式结果\n');
        
        % 显示部署统计
        if exist('deployStats', 'var')
            fprintf('======== 部署统计 ========\n');
            fprintf('总请求数: %d\n', deployStats.total_requests);
            fprintf('接受请求: %d (%.1f%%)\n', deployStats.accepted_requests, ...
                    100*deployStats.accepted_requests/deployStats.total_requests);
            fprintf('拒绝请求: %d (%.1f%%)\n', deployStats.rejected_requests, ...
                    100*deployStats.rejected_requests/deployStats.total_requests);
        end
    else
        error('在线模式结果文件不存在: %s\n请先运行 deployAndDispatchPlan.m', deployMethodCfg.resultPath);
    end
else
    %% ========== 离线模式：执行传统的SFC映射 ==========
    fprintf('使用离线模式: %s\n', deployMethodName); %[output:2c4f6933]
    
    load(topocfg.topoInfoPath);     % 得到 nodes / links / KPaths
    load(reqCfg.requestPath);       % 得到原始请求集合
    load(reqCfg.sortedRequestsPath);% 得到按最大可容忍时延排序好的请求集合
    load(deployMethodCfg.sortedPlanPath);% 得到最终的部署计划,初始化的consume, fail_log
    
    requests = eval(deployMethodCfg.requestsType);
    [nodes, links, requests, consume, fail_log] = deploy_requests( ...
        nodes, links, requests, sortedPlan, consume, fail_log);

    save(deployMethodCfg.resultPath,'nodes', 'links', 'requests', 'consume', 'fail_log'); 
    fprintf('✓ 离线模式结果已保存: %s\n', deployMethodCfg.resultPath); %[output:99f9d86c]
end %[output:group:3738a4a0]

fprintf('✓ 完成（时间：%s）\n', string(datetime("now"))); %[output:637c5fcd]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":33}
%---
%[output:2c4f6933]
%   data: {"dataType":"text","outputData":{"text":"使用离线模式: shortestPathFirstWithLoadBalancing\n","truncated":false}}
%---
%[output:99f9d86c]
%   data: {"dataType":"text","outputData":{"text":"✓ 离线模式结果已保存: c.输出\\4.资源消耗与失败日志\\1.最短路优先算法\\US_Backbone\\shortestPathFirstWithLoadBalancingResult.mat\n","truncated":false}}
%---
%[output:637c5fcd]
%   data: {"dataType":"text","outputData":{"text":"✓ 完成（时间：2026-01-13 15:56:35）\n","truncated":false}}
%---

```

---

## topoAndRequest.m

```matlab
%[text] # 1.生成拓补与请求信息
clc; clear;
%[text] ## %% 1) 导入路径
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'a.输入')));
addpath(genpath(fullfile(currentDir, 'b.常用函数')));
%[text] ## %% 2) 选择拓补（只改这一行）
topoName = "US_Backbone";
% topoName = "Abilene";   % "US_Backbone" 或 "Abilene"
%[text] ## %% 3) 配置表：不同拓补只在这里写一次
topocfg = getTopoCfg(topoName);
reqCfg = getReqCfg(topoName);
%[text] ## %% 4) 生成拓补相关数据并保存
topo = feval(topocfg.topoFunc);                  % 等价于 Abilene() / US_Backbone()
[link, link_num] = topology_link_new(topo);
nodes = Node_model(topo, topocfg.minm, topocfg.maxm, topocfg.minc, topocfg.maxc);
links = Link_model(link, topocfg.minb, topocfg.maxb);
KPaths = KPathsGenerater(topo, link, 10); %[output:85d466ce]
KPathsNew = refactorKPathsToCellStruct(KPaths);
if ~exist(fileparts(topocfg.topoInfoPath), 'dir'); mkdir(fileparts(topocfg.topoInfoPath)); end
if ~exist(fileparts(topocfg.kpathPath), 'dir');    mkdir(fileparts(topocfg.kpathPath));    end

save(topocfg.kpathPath, 'KPaths','KPathsNew');
save(topocfg.topoInfoPath, 'KPaths','nodes','links','KPathsNew');
fprintf('✓ 已保存拓补（%s） 时间：%s\n', topoName, string(datetime("now"))); %[output:80e2e11a]
%[text] ## %% 5) 生成请求相关数据并保存
load(topocfg.topoInfoPath);     % 得到 nodes / links / KPaths

if ~exist(reqCfg.requestsDir, 'dir'); mkdir(reqCfg.requestsDir); end
if ~exist(reqCfg.sortedRequestsDir, 'dir'); mkdir(reqCfg.sortedRequestsDir); end


for requests_round = 1:reqCfg.requests_set_index 
    requests = generate_requests( ...
        reqCfg.requests_num, nodes, ...
        reqCfg.destNode_count, reqCfg.vnftype_num, reqCfg.vnf_num, ...
        reqCfg.maxbw, reqCfg.minbw, reqCfg.maxnr, reqCfg.minnr, reqCfg.maxt, reqCfg.mint);

    filepath = fullfile(reqCfg.requestsDir, sprintf('request%d.mat', requests_round));
    save(filepath, 'requests');

    % 生成按照时延排序后的请求
    sortedRequests = sortRequestByDeadline(requests);
    filepath = fullfile(reqCfg.sortedRequestsDir, sprintf('sortedRequest%d.mat', requests_round));
    save(filepath, 'sortedRequests');

end
fprintf('✓ 已保存请求（%s） 时间：%s\n', topoName, string(datetime("now"))); %[output:5c591ea7]

%[text] ## 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":17.4}
%---
%[output:85d466ce]
%   data: {"dataType":"text","outputData":{"text":"并行计算 10-最短路径，节点数：28 ...\n运行时间为 0.53 s.\n","truncated":false}}
%---
%[output:80e2e11a]
%   data: {"dataType":"text","outputData":{"text":"✓ 已保存拓补（US_Backbone） 时间：2026-01-09 15:54:57\n","truncated":false}}
%---
%[output:5c591ea7]
%   data: {"dataType":"text","outputData":{"text":"✓ 已保存请求（US_Backbone） 时间：2026-01-09 15:54:59\n","truncated":false}}
%---

```

---

## a.输入\1.原始拓补信息\Abilene.m

```matlab
function Abilene_topology = Abilene()
%%Abilene拓扑


                   %1   %2   %3    %4   %5   %6   %7   %8   %9   %10  %11  %12
Abilene_topology = [Inf  1   Inf  Inf   Inf  Inf  Inf  Inf  Inf  Inf  Inf   1  ;  %1
                     1  Inf  Inf  Inf   1    1    Inf  Inf  Inf  Inf  Inf  Inf ;  %2
                    Inf Inf  Inf  Inf   Inf  1    Inf  Inf  1    Inf  Inf  Inf ;  %3
                    Inf Inf  Inf  Inf   Inf  Inf   1   Inf  Inf   1    1   Inf ;  %4
                    Inf  1   Inf  Inf   Inf  Inf   1    1   Inf  Inf  Inf  Inf ;  %5
                    Inf  1    1   Inf   Inf  Inf   1   Inf  Inf  Inf  Inf  Inf ;  %6
                    Inf Inf  Inf   1     1    1   Inf  Inf  Inf  Inf  Inf  Inf ;  %7
                    Inf Inf  Inf  Inf    1   Inf  Inf  Inf  Inf   1   Inf  Inf ;  %8
                    Inf Inf   1   Inf   Inf  Inf  Inf  Inf  Inf  Inf  Inf   1  ;  %9
                    Inf Inf  Inf   1    Inf  Inf  Inf   1   Inf  Inf   1   Inf ;  %10
                    Inf Inf  Inf   1    Inf  Inf  Inf  Inf  Inf   1   Inf  Inf ;  %11
                     1  Inf  Inf  Inf   Inf  Inf  Inf  Inf   1   Inf  Inf  Inf ;  %12
                    ];

end
```

---

## a.输入\1.原始拓补信息\Chinanet.m

```matlab
function topology = Chinanet()


% topology =[0  Inf  Inf  1097349  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  1251073  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  2564262  Inf  Inf;
%           Inf  0  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  507861  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  1183510  Inf  Inf;
%           Inf  Inf  0  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  1077360  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf;
%           1097349  Inf  Inf  0  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf;
%           Inf  Inf  Inf  Inf  0  Inf  Inf  Inf  731929  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf;
%           Inf  Inf  Inf  Inf  Inf  0  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  440086  Inf  Inf  Inf;
%           Inf  Inf  Inf  Inf  Inf  Inf  0  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  517385  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  401984  Inf  Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,265626.286472896,Inf,Inf;
% Inf,Inf,Inf,Inf,731929.106503330,Inf,Inf,Inf,0,80450.8852942024,Inf,Inf,Inf,Inf,1658027.65954568,Inf,1218578.71240591,Inf,Inf,2003280.18109100,163523.660828082,689670.702993764,402208.448945799,270343.199393927,1212209.65551279,Inf,Inf,606640.760938230,Inf,Inf,Inf,Inf,Inf,Inf,962468.100819169,1068257.60352113,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,80450.8852942024,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,193076.507656545,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1046029.74143410,Inf,Inf,506153.707275002,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,293412.010956309,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,522496.108110645,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,763444.385458459,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,268782.082213653,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,978901.672677967,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% 1251073.77204239,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1658027.65954568,Inf,Inf,Inf,522496.108110645,268782.082213653,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1404248.15823747,1237622.45387023,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1090006.86194361,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,507861.072301573,Inf,Inf,Inf,Inf,517385.830861684,Inf,1218578.71240591,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,646370.129730092,Inf,948352.664197798,1308231.51878745,Inf,Inf,Inf,699592.482069513,2118052.03482256,Inf,Inf,Inf,Inf,Inf,912319.036440713,767019.179149956,524965.983570565;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,621965.226301287,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,1236053.54393564,Inf,Inf,454966.739438372,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,2003280.18109100,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,1484998.01932906,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1804402.18364281,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,163523.660828082,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,689670.702993764,Inf,1046029.74143410,293412.010956309,Inf,Inf,Inf,Inf,646370.129730092,Inf,1236053.54393564,Inf,Inf,0,Inf,458902.350283383,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1054600.03711104,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,402208.448945799,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,270343.199393927,193076.507656545,Inf,Inf,Inf,Inf,1404248.15823747,Inf,948352.664197798,Inf,Inf,Inf,Inf,458902.350283383,Inf,0,Inf,Inf,669170.429277951,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,898221.299117680,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1212209.65551279,Inf,506153.707275002,Inf,763444.385458459,978901.672677967,1237622.45387023,1090006.86194361,1308231.51878745,Inf,454966.739438372,1484998.01932906,Inf,Inf,Inf,Inf,0,514391.905054892,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1820203.85326040,1890380.55397845,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,514391.905054892,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,669170.429277951,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,606640.760938230,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,699592.482069513,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,Inf,1326985.93533664,Inf,Inf;
% Inf,Inf,1077360.58272094,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,2118052.03482256,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,Inf,2412701.82506663,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,Inf,1057398.87123599,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,Inf,860046.518773168,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,Inf,Inf,627547.306543061,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,0,383101.505235222,Inf,Inf,Inf;
% Inf,Inf,Inf,Inf,Inf,440086.548431889,Inf,Inf,962468.100819169,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1820203.85326040,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,383101.505235222,0,108213.873846855,Inf,Inf;
% 2564262.94564025,1183510.38580166,Inf,Inf,Inf,Inf,401984.160622373,265626.286472896,1068257.60352113,Inf,Inf,Inf,Inf,Inf,Inf,Inf,912319.036440713,621965.226301287,Inf,1804402.18364281,Inf,1054600.03711104,Inf,898221.299117680,1890380.55397845,Inf,Inf,Inf,1326985.93533664,2412701.82506663,1057398.87123599,860046.518773168,627547.306543061,Inf,108213.873846855,0,414338.747648264,886595.143814688;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,767019.179149956,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,414338.747648264,0,Inf;
% Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,524965.983570565,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,886595.143814688,Inf,0];

% topology = [ Inf 2100 3000  Inf  Inf  Inf  Inf 4800  Inf  Inf  Inf  Inf  Inf  Inf ;
% 			2100  Inf 1200 1500  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf ;
% 			3000 1200  Inf  Inf  Inf 3600  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf ;
% 			 Inf 1500  Inf  Inf 1200  Inf  Inf  Inf  Inf  Inf 3900  Inf  Inf  Inf ;
% 			 Inf  Inf  Inf 1200  Inf 2400 1200  Inf  Inf  Inf  Inf  Inf  Inf  Inf ;
% 			 Inf  Inf 3600  Inf 2400  Inf  Inf  Inf  Inf 2100  Inf  Inf  Inf 3600 ;
% 			 Inf  Inf  Inf  Inf 1200  Inf  Inf 1500  Inf 2700  Inf  Inf  Inf  Inf ;
% 			4800  Inf  Inf  Inf  Inf  Inf 1500  Inf 1500  Inf  Inf  Inf  Inf  Inf ;
% 			 Inf  Inf  Inf  Inf  Inf  Inf  Inf 1500  Inf 1500  Inf  600  600  Inf ;
% 			 Inf  Inf  Inf  Inf  Inf 2100 2700  Inf 1500  Inf  Inf  Inf  Inf  Inf ;
% 			 Inf  Inf  Inf 3900  Inf  Inf  Inf  Inf  Inf  Inf  Inf 1200 1500  Inf ;
% 			 Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  600  Inf 1200  Inf  Inf  600 ;
% 			 Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  600  Inf 1500  Inf  Inf  300 ;
% 			 Inf  Inf  Inf  Inf  Inf 3600  Inf  Inf  Inf  Inf  Inf  600  300  Inf]./2;
         
     topology = [ Inf   1   1   Inf Inf Inf Inf 1   Inf Inf Inf Inf Inf Inf ;
                   1    Inf 1   1   Inf Inf Inf Inf Inf Inf Inf Inf Inf Inf ;
                   1    1   Inf Inf Inf 1   Inf Inf Inf Inf Inf Inf Inf Inf ;
                  Inf   1   Inf Inf 1   Inf Inf Inf Inf Inf 1   Inf Inf Inf ;
                  Inf  Inf  Inf 1  Inf 1 1  Inf  Inf  Inf  Inf  Inf  Inf  Inf ;
                  Inf  Inf 1  Inf 1  Inf  Inf  Inf  Inf 1  Inf  Inf  Inf 1 ;
                  Inf  Inf  Inf  Inf 1  Inf  Inf 1  Inf Inf  Inf  Inf  Inf  Inf ;
                   1  Inf  Inf  Inf  Inf  Inf 1  Inf 1  Inf  Inf  Inf  Inf  Inf ;
                  Inf  Inf  Inf  Inf  Inf  Inf  Inf 1  Inf 1  Inf  1  1  Inf ;
                  Inf  Inf  Inf  Inf  Inf 1 Inf  Inf 1  Inf  Inf  Inf  Inf  Inf ;
                  Inf  Inf  Inf 1  Inf  Inf  Inf  Inf  Inf  Inf  Inf 1 1  Inf ;
                  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  1  Inf 1  Inf  Inf  1 ;
                  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  1  Inf 1  Inf  Inf  1 ;
                  Inf  Inf  Inf  Inf  Inf 1  Inf  Inf  Inf  Inf  Inf  1  1  Inf];
end
```

---

## a.输入\1.原始拓补信息\Cogentco.m

```matlab
%[text] %[text:anchor:T_9c34] # Cogentco拓补的邻接矩阵信息
%[text] 
%[text] 调用案例：
%[text] - bone\_topo=Cogentco(); \
%[text] 输入：
%[text] - 无 \
%[text] 输出：
%[text] - bone\_topo：Cogentco拓补的邻接矩阵信息 \
%[text] ![](text:image:9732)
%[text] 如上图，（4，5）位置值为1，代表节点4和链路5之间有链路连接
%[text] 若值为Inf代表节点之间没有链路
%[text:tableOfContents]{"heading":"**目录**"}
%[text] 不要修改该函数的任何值！
function topology = Cogentco() 
%[text] %[text:anchor:H_8ba1] ## 1.权为1的邻接矩阵
topology =[Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,1,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf;
    1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,1,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf;
    Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,1,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,1,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,1,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1;
    Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1,Inf];

end
%[text] %[text:anchor:H_93fb] ## 2.带权邻接矩阵
% topology =[Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,256309.466708745,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,804769.110055544,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,190285.381271698,Inf,204282.608439078,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,159598.031060415,32160.1963772630,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,94065.1180868363,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,71608.0000812709,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,94065.1180868363,Inf,Inf,190832.626817427,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,164160.119107942,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,150365.081479879,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,260385.543532234,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,190832.626817427,150365.081479879,Inf,355716.983905178,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,355716.983905178,Inf,54883.6854989017,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,804769.110055544,Inf,Inf,Inf,Inf,Inf,54883.6854989017,Inf,161414.936940448,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1004523.53685428,Inf,Inf,122051.879073531,Inf,Inf;
%     256309.466708745,Inf,Inf,Inf,Inf,Inf,Inf,Inf,161414.936940448,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,479609.251287666,Inf,133860.022302985,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,479609.251287666,Inf,Inf,Inf,Inf,Inf,376812.042631257,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,117581.955176469,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,213079.232611127,Inf,223821.632560546,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,133860.022302985,Inf,117581.955176469,Inf,Inf,418505.211942424,495218.307307997,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,387240.749117097,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,350414.816802112,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,891804.868093834,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,418505.211942424,387240.749117097,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,376812.042631257,Inf,495218.307307997,Inf,Inf,Inf,197824.670578810,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,197824.670578810,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,249320.710328739,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,171850.838511824,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,249320.710328739,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,315831.673581860,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,346268.098763673,Inf,Inf,Inf,Inf,Inf,Inf,294140.766233639,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,150253.670499674,Inf,104947.557805049,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,150253.670499674,Inf,Inf,Inf,Inf,Inf,74535.8933044092,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,261764.029074562,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,120746.603998765,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,104947.557805049,Inf,261764.029074562,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,158046.678116769,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,302666.669746289,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,74535.8933044092,Inf,Inf,Inf,Inf,Inf,96619.9239890086,325460.768363567,77118.5556276242,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,158046.678116769,Inf,96619.9239890086,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,325460.768363567,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,318536.624747894,Inf,Inf,88202.4506201213,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,77118.5556276242,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,203077.062932571,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,213079.232611127,Inf,Inf,Inf,Inf,Inf,171850.838511824,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,270474.418963963,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,349746.385883190,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,223821.632560546,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,85329.8625258719,Inf,Inf,Inf,155762.466338890,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,85329.8625258719,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,286040.872676376,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,270474.418963963,Inf,Inf,Inf,Inf,Inf,Inf,203269.284015838,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,613583.759350441,357799.248000253,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,349746.385883190,155762.466338890,Inf,286040.872676376,203269.284015838,Inf,Inf,278620.802420063,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,884424.098126725,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,613583.759350441,278620.802420063,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,418848.884701113;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,357799.248000253,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,799446.032701123,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,416342.709231458,483243.470249755,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,416342.709231458,Inf,Inf,512935.826320162,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,395748.482595582,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,483243.470249755,Inf,Inf,28400.9707960603,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,288355.071807315,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,512935.826320162,28400.9707960603,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,130924.176369460,Inf,147617.121710528,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,130924.176369460,Inf,Inf,Inf,103653.142262803,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5748332.10985876,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,66591.0903003481,Inf,295191.602481490,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,147617.121710528,Inf,66591.0903003481,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,103653.142262803,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,4964417.99933124,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,295191.602481490,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5768608.53671682,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,267481.419993776,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,176038.871213359,Inf,Inf,Inf,Inf,Inf,188667.104236463,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,318536.624747894,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,176038.871213359,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,106973.117479337,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,68574.9825412180,Inf,125371.558501645,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,68574.9825412180,Inf,Inf,Inf,Inf,Inf,236542.562015718,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,88202.4506201213,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,302366.423755444,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,302666.669746289,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,125371.558501645,Inf,302366.423755444,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,188119.597707906,Inf,157056.606340817,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,188667.104236463,Inf,Inf,Inf,Inf,Inf,188119.597707906,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,236542.562015718,Inf,Inf,Inf,Inf,Inf,89081.4305860150,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,157056.606340817,Inf,89081.4305860150,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,118437.565993898,Inf,Inf,Inf,Inf,Inf,Inf,Inf,235878.097758631,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,118437.565993898,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,235143.612067340,Inf,Inf,Inf,Inf,Inf,807692.670615323,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,260862.300120149,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,773778.061623658,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,260862.300120149,Inf,Inf,Inf,Inf,Inf,317239.851361263,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,350414.816802112,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,157167.902181887,Inf,382177.922995629,548440.979935058,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,157167.902181887,Inf,305444.294071751,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,305444.294071751,Inf,48508.8291685995,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,382177.922995629,Inf,48508.8291685995,Inf,Inf,362711.406126777,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,315831.673581860,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,317239.851361263,548440.979935058,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,235878.097758631,Inf,Inf,Inf,Inf,Inf,Inf,362711.406126777,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,92833.3644188301,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,204942.637722507,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,96794.5121066753,Inf,Inf,Inf,Inf,Inf,Inf,159731.301877422,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,96794.5121066753,Inf,156514.276366080,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,156514.276366080,Inf,109520.773247452,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,109520.773247452,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,112063.706222785,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,130436.567209552,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,159598.031060415,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,32160.1963772630,71608.0000812709,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,183410.475887862,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,423632.900834698,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,6148081.43724052,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,203077.062932571,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,206755.464316493,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,210567.908645220,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,92833.3644188301,159731.301877422,Inf,Inf,Inf,Inf,Inf,Inf,206755.464316493,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,65916.1736168933,Inf,Inf,Inf,Inf,329934.635580459,328965.554527829,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,65916.1736168933,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,346268.098763673,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,364064.147351898,Inf,Inf,Inf,Inf,458944.585741646,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,364064.147351898,Inf,Inf,208559.207488939,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,109100.890964046,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,208559.207488939,109100.890964046,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,773778.061623658,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,329934.635580459,Inf,Inf,Inf,Inf,Inf,Inf,124463.819797382,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,328965.554527829,Inf,Inf,Inf,Inf,Inf,124463.819797382,Inf,201253.692586695,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,458944.585741646,Inf,Inf,Inf,Inf,201253.692586695,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,294140.766233639,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,7805520.48431356,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,7805520.48431356,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,93681.8019007979,Inf,Inf,Inf,Inf,Inf,Inf,119873.288837839,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,93681.8019007979,Inf,174671.541350354,Inf,Inf,275892.645009028,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,393206.980047722,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,174671.541350354,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,210567.908645220,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,126893.760723083,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,275892.645009028,Inf,Inf,126893.760723083,Inf,1456411.86068172,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1456411.86068172,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,117411.028025709,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,186159.195790733,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,119873.288837839,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,129529.855989108,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,129529.855989108,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,69739.8748828962,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,46512.1778364563,Inf,497017.382879007,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,368137.252025661,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,46512.1778364563,Inf,Inf,Inf,Inf,Inf,Inf,Inf,135674.975008593,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,62156.6297374179,Inf,13463.7936503580,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,497017.382879007,Inf,62156.6297374179,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,109872.921366122,856393.976306156,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,778018.923245147,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,13463.7936503580,Inf,109872.921366122,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,856393.976306156,Inf,Inf,476174.596653099,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,596863.170942569,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,476174.596653099,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,554782.580600863,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,135674.975008593,Inf,Inf,Inf,Inf,Inf,Inf,Inf,480510.456363473,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,480510.456363473,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,555965.559482220,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,181131.056072154,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,60823.1583499602,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,181131.056072154,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,401089.254024363,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,236721.833248087,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,442510.749000273,Inf,Inf,Inf,Inf,Inf;
%     Inf,190285.381271698,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,236721.833248087,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,93658.5811433518,Inf,30060.7055128138,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,204282.608439078,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,93658.5811433518,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,87074.3836690965,Inf,129308.842606578,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,30060.7055128138,Inf,87074.3836690965,Inf,378119.014022726,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,378119.014022726,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,129308.842606578,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,192490.429500260,Inf,217023.162432725,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,235143.612067340,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,192490.429500260,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,563429.189774382,184878.872242478,307069.025694438,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,217023.162432725,Inf,563429.189774382,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,184878.872242478,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,307069.025694438,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,370122.437058611,Inf,447462.120116866,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,807692.670615323,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,555965.559482220,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,370122.437058611,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,891804.868093834,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,596863.170942569,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,101638.224108715,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,447462.120116866,Inf,101638.224108715,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,260385.543532234,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,117411.028025709,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,165387.011481025,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,69739.8748828962,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,74793.5263223717,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,183410.475887862,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,217141.651040487,Inf,119347.267963122,244714.461152003,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,164160.119107942,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,74793.5263223717,Inf,217141.651040487,Inf,592990.825377022,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,592990.825377022,Inf,Inf,Inf,116902.668276715,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,401089.254024363,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,119347.267963122,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,244714.461152003,Inf,Inf,Inf,Inf,Inf,Inf,130679.603420821,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,116902.668276715,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,60823.1583499602,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,81163.9336634516,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,130679.603420821,Inf,81163.9336634516,Inf,905803.719360225,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,423632.900834698,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,165387.011481025,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,905803.719360225,Inf,254923.956820695,Inf,6654254.44924845,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,288355.071807315,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,254923.956820695,Inf,6090871.61918445,Inf,Inf,Inf,Inf,Inf,5826276.42791986,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,95187.6172144107,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,6090871.61918445,Inf,310153.121960283,Inf,168811.244121986,Inf,366547.045607891,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5799568.43464635,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,6654254.44924845,Inf,310153.121960283,Inf,262662.746696548,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,315817.131436965,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5682157.29010307,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,262662.746696548,Inf,121020.534441665,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,168811.244121986,Inf,121020.534441665,Inf,150618.164673319,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,150618.164673319,Inf,Inf,Inf,Inf,Inf,Inf,Inf,264283.049794691,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,6061155.36367819,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,371316.935941580;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,366547.045607891,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,884424.098126725,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5826276.42791986,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,196831.409108376,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,6148081.43724052,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,196831.409108376,Inf,54453.1024032552,Inf,Inf,Inf,5975602.07599826,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,54453.1024032552,Inf,347691.748760095,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5877846.55163665,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5748332.10985876,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,347691.748760095,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5768608.53671682,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,315817.131436965,Inf,Inf,264283.049794691,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5518902.96915625,Inf,Inf,Inf,767217.199568141,Inf,Inf,6222339.88420222,Inf,6294349.68154129,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,496712.328130844,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,402526.223111288,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5975602.07599826,Inf,Inf,Inf,Inf,Inf,182325.059478679,Inf,Inf,Inf,Inf,Inf,101125.221909695,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,182325.059478679,Inf,325171.141985635,Inf,Inf,Inf,Inf,Inf,57492.4582142598,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,325171.141985635,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,594101.754770604,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,496712.328130844,Inf,Inf,Inf,Inf,31685.7780247605,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,31685.7780247605,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,30908.4323321973,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,30908.4323321973,Inf,51013.8792414627,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,101125.221909695,Inf,Inf,Inf,Inf,Inf,51013.8792414627,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,57492.4582142598,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,267481.419993776,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5518902.96915625,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,233081.264850063,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,778018.923245147,Inf,Inf,554782.580600863,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,233081.264850063,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,368137.252025661,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,799446.032701123,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,4964417.99933124,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,767217.199568141,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,317886.192851598;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,82089.8279929012,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,204942.637722507,Inf,Inf,Inf,112063.706222785,130436.567209552,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,393206.980047722,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5799568.43464635,Inf,Inf,Inf,6061155.36367819,Inf,Inf,Inf,Inf,Inf,Inf,Inf,402526.223111288,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,204526.850977398,Inf,264308.424409859,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,6222339.88420222,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,204526.850977398,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,95187.6172144107,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,594101.754770604,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,6294349.68154129,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,264308.424409859,Inf,Inf,Inf,40997.5862524615,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5877846.55163665,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,40997.5862524615,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,120746.603998765,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,106973.117479337,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,395748.482595582,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,82089.8279929012,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,410360.315589423,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,1004523.53685428,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,442510.749000273,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,410360.315589423,Inf,Inf,Inf,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,250587.197099985,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,250587.197099985,Inf,257884.605313040,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,122051.879073531,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,186159.195790733,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,257884.605313040,Inf,Inf,Inf;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5682157.29010307,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5260113.26357935;
%     Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,418848.884701113,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,371316.935941580,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,317886.192851598,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,Inf,5260113.26357935,Inf];

%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[text:image:9732]
%   data: {"align":"baseline","height":345,"src":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAeEAAAFZCAYAAACv05cWAABAMklEQVR4Ae2da5MkV5nf6yv4jcNhf4EN+wUQjuhWhSMWv9zABnuXhSXCG3h6ZlTLrmJZL7tcvGbtDQz0XKBgl9siLhIXCQHNaDS6ISxAXIJdgzUzGg0a0ULSCgmBBoS6NdMzPdfj82RWZuU5mSfryays7KyuX0VkV+Y5T+bJ+j3\/k\/86mVmdvX\/2mlUjU+\/f\/wUTDNAAGkADaAANtKmBaU343\/zOu8yZwYfM61\/7bhLXZuJoC72hATSABuZfA74Jv\/0z3zHa6WMfu808\/da\/NT\/de9h867V\/aX77t\/90\/oEganKIBtAAGkADbWmgyIRNwev69fPmHdagr176ibmy\/f\/MS0\/eZr53+HXme6tvMmfee7P54r9bMe\/717+nTtyN3zdm\/bbD4fhXHzYfeqZgR9KiU+bGV78tvP4kgKPt3\/veKbYxqQ3q6+cHdrBDA2hgETRQzYQfikx44+kjkQGf\/PSbzQOH32AO73m1+cC\/\/V3zz2\/440LR9G97IbXOiTPf\/0K8jcgkA0ZbVqdNGiZcmCvuDeDeCDSABtBAixrwTfgvP\/1QgU9eM9evbZi3f\/qbZuPp+1IDvnLyg+aL7\/6P5k\/+w2+Zt79LeXNX1kBf\/QVz7zMPmn7RiHZkkgU7MyoKGPQ8mjBfCPhCoNUtcWgFDewuDfgm\/LZPPJDzvevXL5hrV8+a933k84UG\/PCD7zCyXum3p9R85TTzyEATE37vKWOSEXAisDS+4HRxWV2y\/qT3Lhlfl\/ZlEjfqy3UOH\/igATRQRQO+Cb\/1745lTNiOgK0BX7\/6otl45iHzrQP\/ycgp6OwI+OEH\/4fZ3vg7I+sFTThrMlkDTUxYRsJixKNRsVwvVr9CI+lJENJ9sqPxTGPONWLZv0ydMZnRd1T3gvnQbXa\/Ry\/nGre3rlOX3TcvLmHQ88udtuPr5fe+190\/9b5n22c+rFvYwAYNoIFZa8A34Zs+8FVrvOfjyZ6ClhGwGPD3DhcY8Df\/xmxvftJcfOmDRtYLmfCN37dmtb9gROt\/OGvEqVmJCWUN1qkTE1Ju028jWR6ZsGOs8kUgMbuRCab7I+sV1Kcj+P0PmnUz2qdo3cz+pYYfYODXT2w7uWkt86WgYN+C+54w4D2o2ZCWKW\/xWhn6RJ+LoAHfhP\/owO0mO737wMftCPh1zgj4j1\/zW+ZP3vHfzJ++\/712+mvz1ve\/M1qn7AA1aXTrGIaAHxlRMsrMv2dMzk+Us24gzje+qM1khOmOzNPPlV2n0GhHbUWGmN\/j3GdM9ju7XSmT9bNfQPx98+P9+knrJ+3yzkEODaABNLCzGvBNeP\/\/vjW6A1p+ihS6Cev4t95nLr38eTsK\/vtoFLz1q0NG1kvNKpTUyDw8U4xGkJkRXbKumFzWiKyxpCZWtJ1kPe17bSMb7f8kE87u+6R98vclaKJJ25kvC8m2s9uYtH6yDu+TNQsjGKEBNDBLDfgmvPK\/bo5+B\/ybs98z96z+QW4EHBvwF60B32wN+MPmwouHzPkXDhlZb6IJywfJmEX006Uis3JGsvkR5bjEM\/QqoEb7kZ5OtuvGP6XK3DRmG0qNX7adNbcyEx7tf\/Ya7Y3fL\/iikexvhknEcLR+uO3R6ejMzWyV9j1pl3edZuEEJzSABmalAd+E3\/xXHzWXLzxk1m4fmv0re8xjD\/19+jOklZtuGo2Ab45uxrr4m0Nm6+whc+75g0bWU5mwGJnzKjGn7Ie26zmmlK2rM58YnzXH8cvbl9yXgUx9mQnL\/kQj\/PGWs4ZcxCn9LXXypaS07dFIuO6+1+HFOjp9wwlOaAANVNGAb8J\/+I4PmUvn7zZ73\/xG8\/r\/\/NpoesvrXmUetjdhvfkd9k7o6BT0h01qwL84aDZ\/dsDIekXmImXO9eDM6C2K983me3dP+E9ZY2OL5hLTqvKh5z02+QLBf\/sKai6kRcrtF8R51z\/7Tw53kwZ8E37T2w6anz\/5KfMv\/uW\/Mq\/5nVebD77\/j+zyR6K7oP\/Ln\/95dA1YTkFHI+CRAW88dcDIenTulg5wmDBa200HIT4Lel5kDfgm\/Ia3vi8yXPnp0fbmJ+xp54\/Fp57tz5De9NabjNyEJdeA5RS0jIDFgF9aXzWyHiY8wYT9Uf9oUD\/pVHWOKyaM1hb5oMVnR\/+7SQO+Cf\/eTX9j6k45s9hNoPgsdHw0gAbQABpoWgO+CWOkE0azTSeA7dGp0QAaQAOLqwFMGNPlixcaQANoAA3skAYSE97Y2DBNTL\/61a\/NP\/zDP5ovf\/nL5tZbbzUf\/\/jHzUc\/+lGmjjC45ZZbzO23326+853vmrNn7b8kbSjvbKeZ\/gNHOKKBxdJAr0kTFgMW4\/361x8wjz++bn7xi7Pm5Ze3zNbWNlMHGJw7d8Ea74vmiSeeNN\/4xv8xYsgvvPACRswXETSABtDADmmgUROWEbAYMKY7H186HnjgG+bb3\/42nW+HOh8jnsUa8ZBv8l2kgUZN+I477ohGwJjwfJjw+voT5rbbbsOEMWE0gAbQwA5poNCEjx07ZpKpyLlDZXIqWk5BY8LzYcJnz\/7afPazn6Xz7VDnC\/UjyhkxoYHF0UChCdcVgNyExTXg+TBg+aIk14jlprm6+Wa9xTlQkGtyjQZmo4FCE05GwfJeBbwc0KuOgs+fv8vs7fXM3jsvVl63alvE578gYMKz6VhV+g2x5AANLK4GCk24riB2kwk\/cnDZ9JYPmUfOd\/\/LwWNn1s2zzz6f+xIjZVJX9uUDE17czl+3n7MemkEDzWmg0IQZCW+beTHhM4\/bm6u+9BVz6+e+6BixGLCUSd0jj\/w4aMSYcHOdiQMTLNEAGqiqgUITrrqRJH66kXB8WrpnT03LlD09ff78aXNwOS6P6\/eZO0cj1KRu753ZmGVz8JHxCDY55V207aJR4p17s23Z+b13RSaWtJVsp9fL7kdyWr3e5yjaD03ZC2d\/Zb525zHz5FP\/ZD73hdsjIxYDlnkpkzqJCW0LE+agkfRf3tECGmhfA4UmvBMjYcfQ7txnjTg20tT4RkYoZhKNUkcGmNaP4qU+MtHRqeSkfvng6dhIHzlkljOxIXPyR8LJdhJDzu9HYr4ZY67wOUL7Man8woVt+w84fmXuPHq3eeqpZ8wXbvtSNMm8lEmdxIS2gwm33+k40MEcDaCBRAOFJpxUVn2fbiScHbnGo1oZDZ+PjGxsbGImycg2qh+NkhOTjeojo43X8ddPzDQbX2RQOROeuB\/JSLje5yjaB21ZYsRHj91rnnr6mWiS+UkGLNvHhDkYVO3nxKMZNNCcBgpNeCdGwkWnn8UofTMU48gaaTLvrJ8x4XjU7J1etqe7q5rw5P0Im7Dmc2gNNxT385\/\/0l7\/\/ao14J9Fk8xLWSg+KceEm+tMHJhgiQbQQFUNFJpw1Y0k8c2NhMeG5o9kxTyKRsIhE47Wr3GXs2+6k\/djvM+JwTn7OWEknaxT5\/25n\/\/CfOmOr5qnrQEfu+f+aJJ5KZO6sm1iwhw0kv7LO1pAA+1roNCEpxkJX7hwyV6D1E9bW8ei3wnLz4FOWYOVdU8dvMFeE95njtrltH7vsXS7Uf0ofmtrdOr6aLyurL91Sq77uuvLaDTZr6N747pkueh966hclx7HTd6P6T5H0T5oyp5\/\/pfmjq98zTz9T8+au+\/9ujlrH6Ihk8xLmdRJTGhbmHD7nY4DHczRABpINFBowkll1Xc5oG9vX640Xbx4t9lnTw\/vO3TYGmdy2ni\/uevipXQ7SUx6V\/LyYXN6VH\/x4mPmkL1zet9dmfjTsq3xNi5Gy8m23djQ\/jpt7rs72henTPbV2Y\/pPkdoPyaVyx3Qd951t7n3\/gfMr379YspM5qVM6uSJVqHtYMIcDKr2c+LRDBpoTgOFJjzNSPjy5StmEadLl+4x+60x77\/7cquf\/8qVq9GjCX9tTdfnLmXy2EKJ8euSZUy4uc7EgQmWaAANVNVAoQlX3UgSLwd0OeAv4nT58siE77nS+ue\/ejXMvKxO8oQJc9BI+i\/vaAENtK+BQhOuMxJ+6aWXogP6tWvXzDxMV6\/eY25MT3+PT1X3bvigedyaWtXPkGzvxnuqr1u1rSbj5aEbL774YqX\/EU5Hbb+jwhzmaGB3aqDQhOsk+5e\/\/KWRRxnymi8Ct9xyi\/0vW89iwjzOEA2gATSwAxpozISfeOIJc8cdd8yXA7G3Uc5Onz5N59uBzlfnyy7r7M7REHld3Lw2ZsLf\/OY3zQ9+8ANsbc4I\/OhHPzL3338\/JowJowE0gAZ2QAO1TViuAcspaBkBiwF\/7nOfMxcvXpwzC2J3t7e3o9w98MAD5syZM+a5557jGvEOdERGQos7EiL3i5371ITlLtmqk1wDllPQMgLGgOfX0MWIH374YfOVr3wlMmS5WauqFoiv3n9gBjM0gAZSE55fC2HPIQABCEAAAvNJABOez7yx1xCAAAQgsAsIYMK7IIl8BAhAAAIQmE8ChSY87Y0C84mCvYYABCAAAQi0S6DQhP\/yM981dScxcF4QgAAEIAABCEwmEDTh3KrXr5rrVzcic75+6TFz7eL\/Nde2vmmunTtqrm5+wVx96eNRHSacI0cBBCAAAQhAoJBABRO+bE34N7EJb\/\/YmvA\/WhN+0JrwndaEP48JF+KlEAIQgAAEIBAmUGjCb7v5W+4a168bc+2CNeGzRuqubz9qF39grp3\/hrn28tesCX\/OmvBHo7qFHgnfNzC9\/tCsu\/RqLK2bYb9nBveFVr3PDHoDE6wOrUY5BCAAAQh0ikChCf\/Zx74+3kkx4OuXrAG\/ZK5f+bmRuusXj1sT\/q414futCX\/FXN34rLn6m7+N6iabsBhIz\/SHnlWtD00\/81SjnAGJwaX1WgNqsy2LDBMe64Y5CEAAAhCYSKDQhG\/68DFrvFftdHk0AhYD\/oVdfMpI3bULcipargffZa5t3m5N+GZz5cUPRXVhE45Hdz07ghsMfBOOzTI13shwM0Zb2dzabCvDuPJ+ZtZ1ZhkJOzhYgAAEILBLCRSa8FsOf9V68IadfmOns9EIWAz4ur0WLHXXtr4zGgWvjU5Ff8xc+fUHorqwCY8J3ldowhnTtSdaB72+iQfLYkjJ\/Hgb2rk222IkrM0KcRCAAAQgIAQKTfjG999mdNMXbdzNdvqwnT4QrVPPhI1ZH\/bHp6hlRJkMi+U0tb3OOrTGnZyOTk5lyzoysk6ujYrhpuuN8ps34XptFcslHsEn+xW9O9eE\/frxvtoPbE+\/h5aTkbC7foLEnvf2rgm7cQmf4n2mFAIQgAAEukKg0IT3vucWexn4sWjkKzdhxdeA5RT0d4zURaehX\/5SfC34pY+Yy3YUvP2Lw1HdNCacNbPUSKJT05mblCLzGo+MU5MNnApO6zPEY\/POm3o0krXXnVOz89rKbMLOxsaXxkqJfAlITTiuTz+HrBx9lpHxKkw4+wXDWdcxYWlnzMN+xZhwU5fsCC8IQAACEOgCgUIT\/q9\/\/cn4d8DyMyS5C1puwpJrwPZGrKguMuBb7B3R9jT0ix80l144bC48dyiqq2XCObPLGFyBubrGGsf2HCMao3VjbflUbY23G5liarij8uy+ZufT1TIGqTDhrMG75iqfeWTmkbGPv1AkX2Qc80\/bZwYCEIAABLpEoNCE\/\/BdH4lNV34HLD9Dkrug5Sasl9eM1EV3Q0cGPDSXzn7AXHj+sDn\/zKGoro4JRyNT13GiUWVkJGJWntm5xlrNhKdrK5O6IpPNlmXn09Uy17ebNGGPT9ocMxCAAAQg0GkChSb8pr\/4oDXdo3a6M\/odsPwMKboL2v4eWOqu2lPQ0QjYGvBFMeCfHTIvP3UwqqtjwqWj09Hp1XRk541kE0OOzLXAjJL6NAve+vYcsR1VJqeg45FqqK10G9FMdj0piNedeDo62UdvP+JT5Mk14tG2Ml9M3PrMSNjZ\/3gP7xsk24mX+QsBCEAAAt0kUGjCb\/iz1fhfUcp\/wpJ\/xCG\/A7Y\/Q5LTz1In14CjU9CJAT990Lz0xIGorpYJCxvvtGrGf6QyMsrkVGtSJwY7Nr28ccWb9X8OVa8t2Vbu5eyzvS479P9Zh7vfzjVeu7HYWONTyX1rnOMbteLPMrBlyWd2182acLSh8t9Y53acAghAAAIQ6AKBQhN+\/U3vsYb78dH00egfccjvgOVnSFInN2HJNWA5BS0jYDHgF8+sRnUaE+7CB2cfIAABCEAAAjtNoNCEf\/ct\/9PUnTDhnU4p7UMAAhCAwLwQKDRhMdJppnn58OwnBCAAAQhAYCcJYMI7SZ+2IQABCEBgoQlgwgudfj48BCAAAQjsJIFCE97JHaJtCEAAAhCAwKIQwIQXJdN8TghAAAIQ6BwBTLhzKWGHIAABCEBgUQikJnzrrbcaJhigATSABtAAGmhPA6kJv2f1w4YJBmgADaABNIAG2tOAY8KzHv4\/9NBDs25i12wfVvpUwgpWegL6SNHV888\/z6RgQB+spqtstGPC169fN7OcJFGz3P5u2jas9FqEFaxm0fdFV8899xyTggF9sH4fdEz42rXrZpaTJGqW299N24aVXouwgtUs+r7o6tlnn2VSMKAP1u+DnglfsyY5uylO1Oy2P8t9b3vbsNLrBFawmkX\/FF397Gc\/Y1IwoA\/W74OOCV+9es3McpJEzXL7u2nbsNJrEVawmkXfF10988wzTAoG9MH6fdAz4avWJGc3xYma3fZnue9tbxtWep3AClaz6J+iq6effppJwYA+WL8POiZ85cpVM8tJEjXL7e+mbcNKr0VYwWoWfV909dRTTzEpGNAH6\/dBx4QvX7liZjlJoma5\/d20bVjptQgrWM2i74uunnzySSYFA\/pg\/T7omvBlu6EZTlGiZrj9Ovt+6dI9Zn+vZ244fGamn73qvnWN1aW795ue5RRPN5jDj13uDK\/OsRppKma139x9CVaT9N\/Ffii6+ulPf9qZ6cG\/elWmD9q++Aef6cy+da0Pit7cY1Z3+qHPyjHhS5cvm1lO0vgst19l29uXHjOHbhBT2W\/27RcTfqwz+yafo1us7jb7bjhsTl+6FDHajgx5vzk2Wq7CfRax3WIluhqzOWa11dt\/d2e01SVWWS2cPnxDZDBd6ofCan19vTPTp97YM6\/679\/ozP5k2XRNV9ExKnPMymptp+d9Vq4J22\/sl2Y4RY3PcPt19\/3YPmvCh6wJd2jfuspKGG1vW1Pu3WAOnbam3AFmnWZ1zJ5BkIPBNqxCWtk+fdjcYBkd6lg\/FF395Cc\/6cwkJvzGTz3emf3JsulSH9zeli\/C3Tk++br3WTkmvG1HNrOcpPFZbr\/utu+ynX\/50OlO7VtXWQnji8f22VHLPnPX9nYnmHWZVde01TVWF7dPR2ek9h3bNl1k9fjjj5suTGfOfN2865XJ5SB5f4P55Jkzndg34dMlXV08fcgs33Ao+lKXXELr0vHdZ+WasP22vj3DKWp8htuvu+9p5+\/QvnWVVSRwe214313WgDvCq2usEkZyAOgSJ8lX11hl+152vgvaElZnrNF1cbr\/na80vVe+09z\/2GOd2L8u6eriXTJIGPe9uD\/KyLgbxyyflWPCFy\/aUc4MJ2l8ltuvu+2jMhI+eLpT+9ZFVo8elOt2N5iDj27DStlPRFu95UPm0QvdYNYlXV04ag+WGTZd64fC6sc\/\/nEnp9OnP2F+v\/dK8457T3di\/7qsK\/GFLmnLZ+WY8IWL22aWkzQ+y+3X3XaSoLrrz2K9rrGKzGTfXZ3MX9dYZfWwdeEus7e3bL+4XOwEu66w2rpw2hxczp5ezcxbYz51Yed5CavTp093cnr0UTHhV1gTfrQT+9cVXUnf23rUno72NNSlY7zPyjVh+239wgynqPEZbr\/uvh\/dG4+E664\/i\/W6xGrrlBW1vQZ8dMseGDuYv86x2mu\/rIw4nTq4HI32TnWEXZdYJYyS9671Q2H16KOPdmI6deoec889p9J9+cTv2y8tr3i7uefUuGwn97VLutrair\/gydlN0VZ8\/LJfhE914\/jls3JMeMt++5zlJI3Pcvt1t31nZMKPdmrfusTqvJw2TH8jPB6x7D16oRPMusRKNPiIGG\/Ka5+5c6sbnGTfusYq22e71g+F1Slrcl2YHnnkHvP2V4z7XmTAjzzSiX0TPl3T1fmto\/YM1JhXV45VRX3QNWH7bX1rhlOUqBluf5b73va2YaXXIqxgNYv+Kbo6efIkk4IBfbB+H3RM+Lz9xj7LSRI1y+3vpm3DSq9FWMFqFn1fdHXixAkmBQP6YP0+6JjwufMXzCwnSdQst7+btg0rvRZhBatZ9H3R1fHjx5kUDOiD9fugZ8Jb1iRnN8WJmt32Z7nvbW8bVnqdwApWs+ifoquHH36YScGAPli\/Dzom\/PK5LTPLSRI1y+3vpm3DSq9FWMFqFn1fdPWjH\/2IScGAPli\/D3omfN6a5OymOFGz2\/4s973tbcNKrxNYwWoW\/VN09cMf\/pBJwYA+WL8POiYsIJlggAbQABpAA2igHQ04Jrz58nkzy0mSyktHAFY6ThIFK1jpCegj0RWs9AT0kb6uMGE9u1Yj\/US12vicNQYrfcJgBSs9AX0kuqrPChPWs2s1ElHrccMKVnoC+kh0BSs9AX2krytMWM+u1Ug\/Ua02PmeNwUqfMFjBSk9AH4mu6rPChPXsWo1E1HrcsIKVnoA+El3BSk9AH+nrChPWs5tx5LoZ9uN\/OD64j5uNymHDqpxPthZWWRrl87Aq55OthVWWRvl8OavaJryxecTssU+pWFo9qb6j2v8GUL7j819736Bn+sN11QdZH\/ZNT9x39IJVQiL\/Dit0lVdFcQl9sJhLUSmsiqgUlzXJqrIJb2yeNKtLMmJbMXtWMOHiFMWlVRLlx2LCYbKw0pswrGAV7kluja8Vt9Zd8mM5Xrl8skuTWFU24ezviNcw4Szr3LwPPxeQKfBjEXUGjjcLK4zFk0Rw0ddKMNBW+LH0wTAtWDXXBzHhsM6mrnGFep8Z9PpmOBykD3xPTlVL3Pgh8AMjJ6UX+wAAqzLxoasyOm4drFweZUuwKqPj1jXJChN22Ta6lE+UNdvkuu\/60PTFlEeXjN1YTHhg7zeAVbEcXa3IFxZYFZPyR7ewCnGScnRVRseta5IVJuyybXQpn6ix6Rojd8yNl91YTDg6a5De0warrDBdrYzOGsAqiyidh1WKYuIMrCYiSgOaZIUJp1ibn2kyUc3vXbe2CCt9PmAFKz0BfSS62hlWmLCee+VIRK1HBitY6QnoI9EVrPQE9JFN6goT1nOvHNlkoio3PmcrwEqfMFjBSk9AH4mudobVVCac\/bmSZn7R7vjVpzQfCas8k1AJrEJk8uWwyjMJlcAqRCZfDqs8k1CJzwoTDpHa4XI\/UTu8O51uHlb69MAKVnoC+kh0VZ8VJqxn12okotbjhhWs9AT0kegKVnoC+khfV5iwnl2rkX6iWm18zhqDlT5hsIKVnoA+El3VZ4UJ69m1Gomo9bhhBSs9AX0kuoKVnoA+0teVY8JSyQQDNIAG0AAaQAPtaMAxYc0dztPESFJ56QjASsdJomAFKz0BfSS6gpWegD7S1xUmrGfXaqSfqFYbn7PGYKVPGKxgpSegj0RX9Vlhwnp2rUYiaj1uWMFKT0Afia5gpSegj\/R1hQnr2bUa6Seq1cbnrDFY6RMGK1jpCegj0VV9Vpiwnl2rkYhajxtWsNIT0EeiK1jpCegjfV1hwnp2M46Ux\/XZ58LaZ8PKI4f9RM248TnbPKz0CYMVrPQE9JHoqilWtUx4Y20lMgsxjF5v2ayeOGc0d00vmrG4\/xC9PGXrw\/74IfY2FFZhXrDqmf4wfYBwGJStgRWsSgWSqeR4lYExYbZJVpVNeGPziNmzdMAc34yNNzbkFbM2Wi4zY4wlnFk\/qbCCVYiAr5VQnJT7segqTAtW+i8ssGqOVWUT9k02MmXlaJgDAAeAEAG\/U4fipNyPRVdhWrBq7mAZprw7anytlH0qP5Y+GKY1idX0JhydmmYkXJQCF\/59ZtDrm+FwkJ7KT04pSlx8al\/eB8ZeEl7w09GwKtJTUoauEhKT32E1mVESAauExOT3JllNZcIbJw6YJXtdeM8a14SL0pZPlDVZuetKXutD0xdTHl3ac2Mx4YHcbwCrWCveX1cr8oUFVh6idBFWKYqJM7CaiCgNaJJVbRM+vrpc6aYsOY292KcsRqO79H4aubsQE05UnRf1mI39xgKrBJR9h1UGxoRZWE0AlKmGVQbGhNkmWdUy4bUV+8175YjqjujsNWRMGGMJabtJUYfa2C3lsNJnElaw0hPQRzapq8omHJ+C1l0DzhowI2FGwmUSb1LUZe3shjpY6bMIK1jpCegjm9RVdRN2fiNsR8TRb4V114UZCTMSDsm8SVGH2tgt5bDSZxJWsNIT0Ec2qavKJuyPbqssL5oJ61Oaj4RVnkmoBFYhMvlyWOWZhEpgFSKTL4dVnkmoxGeFCYdI7XC5n6gd3p1ONw8rfXpgBSs9AX0kuqrPChPWs2s1ElHrccMKVnoC+kh0BSs9AX2krytMWM+u1Ug\/Ua02PmeNwUqfMFjBSk9AH4mu6rPChPXsWo1E1HrcsIKVnoA+El3BSk9AH+nryjFhqWSCARpAA2gADaCBdjTgmHCVO53rxEpSeekIwErHSaJgBSs9AX0kuoKVnoA+0tcVJqxn12qkn6hWG5+zxmClTxisYKUnoI9EV\/VZYcJ6dq1GImo9bljBSk9AH4muYKUnoI\/0dYUJ69m1GuknqtXG56wxWOkTBitY6QnoI9FVfVaYsJ5dq5GIWo8bVrDSE9BHoitY6QnoI31dYcJ6djOOlMf1xf+LWx6j6ydqxo3P2eZhpU8YrGClJ6CPRFdNsaplwhubR8ye0YMbej39E5UWzVjcf\/JdnrL1YX\/8EHsbCqswL1j1TH+YPpg6DMrWwApWpQLJVHK8ysCYMNskq8omvLF50qwujY23yrOFMZZwZv2kwgpWIQK+VkJxUu7HoqswLVjpv7DAqjlWlU3Y\/33whjzacOmAOb55zvh1\/jIHAA4AIQJ+pw7FSbkfi67CtGDV3MEyTHl31PhaKftUfix9MExrEqupTVhGwkurJycasBjyYifqPjPo2ecJDwfpM5iTU4qSpOS5zL3ewNhLwrCCVbBXu50aXQVB2QpYldFx62Dl8ihbapJVLRPeOHHALI2uCe9ZmzwCTkbEmLA1W7nrSl7rQ9MXoxld2nOTigkPRF+wirXi\/XW1IiYMKw9RugirFMXEGVhNRJQGNMmqlgknpirv0TVhTkenycnO5BM1Nl3rwvZu6PGyG4sJR2cN0nuPYIWusgT0826\/Gp01QFeFAGFViKWwsElWU5twfKf0slk9MXlEzEh4bLqYsKvtJkXtbnn3LcFKn1NYwUpPQB\/ZpK4qm3B0KnrlSHoN+PjqMjdmBXLXZKICTeyaYljpUwkrWOkJ6CPR1c6wqmzCcgo6Ml5+JzwxY4h6IqI0AFYpiokzsJqIKA2AVYpi4gysJiJKA5pkVcuEs9eEq8wv2unoNGM1ZmClhwYrWOkJ6CPRFaz0BPSRvq4wYT27ViP9RLXa+Jw1Bit9wmAFKz0BfSS6qs8KE9azazUSUetxwwpWegL6SHQFKz0BfaSvK0xYz67VSD9RrTY+Z43BSp8wWMFKT0Afia7qs8KE9exajUTUetywgpWegD4SXcFKT0Af6evKMWGpZIIBGkADaAANoIF2NOCYcJU7nevESlJ56QjASsdJomAFKz0BfSS6gpWegD7S1xUmrGfXaqSfqFYbn7PGYKVPGKxgpSegj0RX9Vlhwnp2rUYiaj1uWMFKT0Afia5gpSegj\/R1hQnr2bUa6Seq1cbnrDFY6RMGK1jpCegj0VV9Vpiwnl2rkYhajxtWsNIT0EeiK1jpCegjfV1hwnp2M46Ux\/XZ58La\/8ktj9H1EzXjxuds87DSJwxWsNITqBvJ8aqMXHkfnMqE48cY9szS6sn0qUpld00vWqLcf\/JdliT7YMNhf\/wQexsKqzAvWPVMf5g+FDcMytbAClalAqlcKc9kzjPleBUGOakPTmXCydOUMOHiBFQxYT8WURczlVJY5Q+CIVqwglVIG9XKk9HcwAwGeaYcr8I0J\/XB2iYcPVd46YBZXWEkHMLvww\/FSbkfi6jDtGCVPwiGaMEKViFt1C33NSXb4XgVpunz8lnVMuGNzZNmdaln9qydM2uYcJC+C19O4\/TNcDiIrvvKtd\/klKLEyXI8DYy9JLzgooZVUFS2Al2V0XHrYOXyaGLJZRpv0TeWJtrp8jZcBtMdr2qZcNZ4s\/Nl14OljkRZo5W7ruS1PjR9MeXRpT03qZiwXHeCVSwV\/6+rlfgaHax8SvEyrIq5TFPqMo23xLG9\/vGqsglvrK2Ynj0NfXzzXHQzFiYclrMr1tG3pfR+GrnGggkn9GCVkJj8DqvJjJIIWCUkmnt3mcbbxYTHx3I7wqp0bK9kwslp6PGp0+QUqn3PGHNoREyi6iequS7UzS25HZsvLGVZglUZHbcOVi6PJpZcpvEWObbXP7ZXMuEic2UkHJa1K1aMJUwqcJ2TswaFyNBVIZbCQlgVYpmq0GUabwoTxoSnEtWsVnbFigmXcYZVGR23DlYuj7IlWJXRqVfnMo23gQnvoAkXjY5DZYuWqHoSX0xRw2oaAvp16YOw0hPQR6Kr+qymPh0dMtyichJVP1H6NRcvEl3pcw4rWOkJ6CPRVX1WmLCeXauRiFqPG1aw0hPQR6IrWOkJ6CN9XWHCenatRvqJarXxOWsMVvqEwQpWegL6SHRVnxUmrGfXaiSi1uOGFaz0BPSR6ApWegL6SF9XjglLJRMM0AAaQANoAA20owHHhItupmqyTJLKS0cAVjpOEgUrWOkJ6CPRFaz0BPSRvq4wYT27ViP9RLXa+Jw1Bit9wmAFKz0BfSS6qs8KE9azazUSUetxwwpWegL6SHQFKz0BfaSvK0xYz67VSD9RrTY+Z43BSp8wWMFKT0Afia7qs8KE9exajUTUetywgpWegD4SXcFKT0Af6esKE9azm3GkPP4qfiqVPHLYT9SMG5+zzcNKnzBY6Vm5kfRBl4e7hK5cHmVL5axqmfDx1WXjPM5w5Uj0bOFJd1IvmqiL\/tF5KFXrw\/74IfY2CFYhUvZpnbAy\/WH6iKkwKFuz6KxK4aSV8nCVXo4pfTAFlJtZdF01eWyvZcJVHl+YNWZEndNyWuAnFVYpmtwMrPKGkYM0Klh0ViEucXkyQhmYwSDPlD4YprfouvI\/f5iU\/5jW\/ACrtgnvWTunGv1iwroRi59UDgBhWcMqbxghWovOKsTFL\/c5ST190Kc0XvZ5wWrMxp+bxKqyCW9snjSrS\/G1y\/iU9IpZ29QZ8mInavQ84eEgPZWfnFKUJI1P7w+MvSS84AcAWPkdObvsdmpYZdnUnXeZxlvheGWfkcvxqlBSrl6m64OVTTg7spX56Prw0gFzXGHEiNqardx1Ja\/1oen3xg+CdpOKCcs1OljFUvH\/ulqRAwCsfEZVl12m8docr9BVSEeuXqbrg1Ob8MbmEbOnt2xWT0weDSPqselaF7Z3Q4+X3aRiwoPMFxRYuYcCVyujb+HpVQ905dLSLblM43U4Xo2PT\/RBV0euXqbrg5iwy7bRpSYT1eiOdXBjsNInBVZ6VtpIl2m8FiaMCYf04+qlZROWa8LHM6NeuVO6x+nowlw1majCBnZRIaz0yYSVnpU20mUar4UJY8Ih\/bh62QETdm7MUhqwXD9G1Ii6DVGH2tgt5U0eAHYLk2k\/h8s03hrHK45XIV25emnZhP0bs6osL5qoQwnUlMNKQymOgRWs9AT0kegKVnoC+khfV1NfE8aE9fCrRPqJqrLuosXCSp9xWMFKT0Afia7qs8KE9exajUTUetywgpWegD4SXcFKT0Af6esKE9azazXST1Srjc9ZY7DSJwxWsNIT0Eeiq\/qsMGE9u1YjEbUeN6xgpSegj0RXsNIT0Ef6unJMWCqZYIAG0AAaQANooB0NOCZc5SarOrGSVF46ArDScZIoWMFKT0Afia5gpSegj\/R1hQnr2bUa6Seq1cbnrDFY6RMGK1jpCegj0VV9Vpiwnl2rkYhajxtWsNIT0EeiK1jpCegjfV1hwnp2rUb6iWq18TlrDFb6hMEKVnoC+kh0VZ8VJqxn12okotbjhhWs9AT0kegKVnoC+khfV5iwnt2MI+URdPZhGPbZsPLIYT9RM258zjYPK33CYAUrPQF9JLpqilVtE95YW4kMQ0yj11sxa5s8T9hPivtPvv1ad3l92B8\/xN5WLZoJw8rVQ9kSrMrouHWwcnmULcGqjI5b1ySrWiYcGXCFpyclP2fCWNxEZpf8pMIqS8edh1XP9IfrLpTAEqxgFZBGrtjXSi4gU+DHcrzKwPFmJ7GqbMLyPOHVpWWzmnmmcGKyk95JlJedzOKkRGVCd+Ws\/\/nLPqQfi67CtGCFCYfV4db4WnFr3SU\/lj7o8skuTWJV3YRPHDBLdhS8uhJfv5TT0UurJ80kA5b6xU7U6JmTw0F6Gj8ZzUiS4tP68j4w9pIwrHr2WaawyvbldN7t1OgqBVMwA6sCKIEiWAXAFBQ3yaq6CY+uBe9Zi68Bb4gp93QjY0zYmqzcdSWv9aHpi9GMziq6ScWEB3KvAaxirXh\/Xa2ICcPKQ5QuwipFMXEGVhMRpQFNsqpnwt714DU7KtaMhjHhselaF7Z3Q4+X3aRiwoPMFxRYpX0\/mnG1MhoJp5eI0VWWFqyyNMrnYVXOJ1vbJKvqJjw6HX08czc0JpxNz3i+yUSNt7o752ClzyusYKUnoI9EVzvDqroJRzdmjUe+nI4OJw5Rh9n4NbDyiYSXYRVm49fAyicSXoZVmI1f0ySryiYsN1htbB4xe6LfB8uNRD2TXB+edHMWp6PHp585xerKuklRu1vefUuw0ucUVrDSE9BHNqmrWiY8yWxD9YtmwvqU5iNhlWcSKoFViEy+HFZ5JqESWIXI5MthlWcSKvFZYcIhUjtc7idqh3en083DSp8eWMFKT0Afia7qs8KE9exajUTUetywgpWegD4SXcFKT0Af6esKE9azazXST1Srjc9ZY7DSJwxWsNIT0Eeiq\/qsMGE9u1YjEbUeN6xgpSegj0RXsNIT0Ef6unJMWCqZYIAG0AAaQANooB0NOCYcuqu5qXJJKi8dAVjpOEkUrGClJ6CPRFew0hPQR\/q6woT17FqN9BPVauNz1his9AmDFaz0BPSR6Ko+K0xYz67VSEStxw0rWOkJ6CPRFaz0BPSRvq4wYT27ViP9RLXa+Jw1Bit9wmAFKz0BfSS6qs8KE9azazUSUetxwwpWegL6SHQFKz0BfaSvK0xYz27GkfIIuvh\/cctjdP1EzbjxOds8rPQJgxWs9ATqRnK80pPzWVU24eOry9FDG+TBDdlJ8xAHv3H9bs9npPtPvss\/w\/qwP36IvQ2FVZgXrHqmP0wfIBwGZWtgBatSgVSulOdX55ku2vFKh03HqrIJ+z9Xih9luGLWMs8X9mOS5UVLVBUT9mNhFZY5rPIHwRAtWMEqpI1q5ckZlYEZDPJMF+14Vc6uGqupTXhthUcZhhLiHwBDcVLuxy6aqP3PD6swAViF2fg1sPKJTL9cxHTRjldaihpWU5nwxtqK6S0dMMcVo2AZDS9aotwEyKkJ+zzh4SA9jZ+cUpS48an9gbGXhGEFq2A\/R1dBNLkKWOWQTF3gMo03t2jHdi1EDavaJryxedKsLulHwZhwfH2gJ3ddyWt9aPpiNKNLe36yFk3U7ueHVSyS4r+wKuZSVAqrIirTlblM420t2vFKS1DDqr4Jnzhglnq6a8FcE5aUjUbC6f00ct0AE07E7IoVVgmXondYFVEpLoNVMZdpSl2m8ZYw4WKiGla1TViuBS+tnjSJwWreFy1RbgIwlmKZxqWwKqPj1sHK5VG2BKsyOvXqXKbxNhbt2K4lp2FVy4Q3No+YPb1ls3riHCZckg03AZhwCSrvxjRYwaqMgL6OPqhnpY10mcZrYcLF9DSs6plwjVPRXBPGWIplGpe6YoUVrMoI6OvQlZ6VNtJlGq+FCRfT07CqZcKaU89FMSSqOFFFpbAqolJcBqtiLkWlsCqiUlwGq2IuRaWwKqJSXOazwoSLOe14qZ+oHd+hDu8ArPTJgRWs9AT0keiqPitMWM+u1UhErccNK1jpCegj0RWs9AT0kb6uMGE9u1Yj\/US12vicNQYrfcJgBSs9AX0kuqrPChPWs2s1ElHrccMKVnoC+kh0BSs9AX2kryvHhKWSCQZoAA2gATSABtrRgGPCRXc0N1kmSeWlIwArHSeJghWs9AT0kegKVnoC+khfV5iwnl2rkX6iWm18zhqDlT5hsIKVnoA+El3VZ4UJ69m1Gomo9bhhBSs9AX0kuoKVnoA+0tcVJqxn12qkn6hWG5+zxmClTxisYKUnoI9EV\/VZYcJ6dq1GImo9bljBSk9AH4muYKUnoI\/0dYUJ69nNOFIebdgzvV7PyCOH\/UTNuPE52zys9AmDFaz0BPSR6KopVrVMeCN6gENsGGIae9Z0T1NaNGMp+ufdocStD\/umJ+47esEqIZF\/h1XP9Ifpg6nzgDIlsIJVRg6lsxyvSvE4lU2yqmzC8WMMx8a7sbZiR28rZm1zshFjLE4enQU\/qbBy8DgLsNIbC6xg5XSekgVfKyWh3qNHF+\/MXZOsaprw2HSrPFsYYwnL2k8qrGAVIuBrJRQn5X4sugrTghVfWMLqcGt8rbi17pIf6\/fByiYs\/7zj+OqyWVo9aWQ+GgmvHInmJ\/1jD79xd1d335ILf\/SM3OEguu4rp\/GTU4oSJ8vxNDByUhpWfTOEVWGnQFeFWAoLYVWIpbAQVoVYCgubZFXbhMem0UsNGRN285VPlDXa5Lrv+tD0e9ZoRpf23FhMeCBfSmDlCmq05GpFvtzBqhCULYRViEy+HFZ5JqGSJllVNuH4pqxls3oivgbsXyMuM2JGd2PTNUbuLhwvu0nFhAeZLyiwcg8FrlZGZ1jS+7TQVZYWrLI0yudhVc4nW9skq8omLKeie97p57UV3WgYEx6bLsaSlXTRiAVWLqHxUpMHgPFWd+ccrPR5hdXOsKpswoyEdyZR+lbnM5IDgD5vsIKVnoA+El3tDKvKJpzejJXeSDT+uVLZqWipYyTM6C4kcw4AITL5cljlmYRKYBUiky+HVZ5JqKRJVrVMeJLZhuoXzYRDCdSUw0pDKY6BFaz0BPSR6ApWegL6SF9XmLCeXauRfqJabXzOGoOVPmGwgpWegD4SXdVnhQnr2bUaiaj1uGEFKz0BfSS6gpWegD7S1xUmrGfXaqSfqFYbn7PGYKVPGKxgpSegj0RX9Vlhwnp2rUYiaj1uWMFKT0Afia5gpSegj\/R15ZiwVDLBAA2gATSABtBAOxpwTDh0V3NT5ZJUXjoCsNJxkihYwUpPQB+JrmClJ6CP9HWFCevZtRrpJ6rVxuesMVjpEwYrWOkJ6CPRVX1WmLCeXauRiFqPG1aw0hPQR6IrWOkJ6CN9XWHCenatRvqJarXxOWsMVvqEwQpWegL6SHRVnxUmrGfXaiSi1uOGFaz0BPSR6ApWegL6SF9XmLCe3Ywj5RF09rmw9n9yy2N0\/UTNuPG53jysytKHrsrouHWwcnmULcGqjI5bV86qlgnHT1KKDaPXGz9beNJd1It2sHT\/ybebFn9pfdgfP8TeVi4aK59H8XL8APv+MH14bhS2aKzQVbE6ikphVUSluAxWxVyKSptkVdmENzaPmD12tLZn7ZwR091YWzG9pQPm+Ga8XGbEHCyL0hmX+UldNFZhMlKTfJMcmMGgZzDhPIMQv0XXlf\/5Q5yk3I9dtD7of35YhQk0yaq6CXumu7F50qwu6UbDiFqf1EVjFSbj1hSJf9FYFTFwKY2X\/FhYjdn4c7Diy52vidCyr5VQnJT7sX4fbMiExyNjRsLjdLjw5VSqfZ7wcBBd95Vrv8mITuJkOZ4Gxl4S5nT0GKMz5zKNq3xROyvswgWXAboqSzGsyui4dbByeZQtNcmqugmfOGCW\/NPRmWVMeJy6fKKs0cpdV\/JaH5q+mPLo8qYbiwnHkPJ\/fU4SgQmjq7xS4hJXL\/E9BfTBYlqwKuZSVNokq8omnF4HTkZu9nrw6gqno3WJGptufJ1zvOwmdfGMpYhfUZnPSWIw4bGO0JWrGlcvo7MG6X19cq\/BmJ0bi66iM3ewcgU1WnK1Mp2uaplwdrQb36i1Yta4MSuXrCYTldv4gha4TGMImPDYSDBht2O4epnuYOluefctwUqf0yZZTW3Cays9s7R6MrpTOmvORfMcLDlY6mVeHOmKP45BV+iqWC3+TTGYcIiTlLt9C1ZtsapswvHd0MlNRHoDFlPmYMnBskzYmjr3QBGvga7QVUg7rl4wlhAnKYdVGR23rklWlU24aISrLVu0g6WbtmpLsNLzghWs9AT0kegKVnoC+khfV5iwnl2rkX6iWm18zhqDlT5hsIKVnoA+El3VZ4UJ69m1Gomo9bhhBSs9AX0kuoKVnoA+0tcVJqxn12qkn6hWG5+zxmClTxisYKUnoI9EV\/VZYcJ6dq1GImo9bljBSk9AH4muYKUnoI\/0deWYsFQywQANoAE0gAbQQDsacExYe5dz3ThJKi8dAVjpOEkUrGClJ6CPRFew0hPQR\/q6woT17FqN9BPVauNz1his9AmDFaz0BPSR6Ko+K0xYz67VSEStxw0rWOkJ6CPRFaz0BPSRvq4wYT27ViP9RLXa+Jw1Bit9wmAFKz0BfSS6qs8KE9azazUSUetxwwpWegL6SHQFKz0BfaSvK0xYz67VSD9RrTbe+cbkEXTx\/y+XxzPDqixhsCqj49bByuVRtgSrMjpuXTkrtQnHjyzMP7AhKe9Fzxcuf64wB0s3NfGS\/FP5nukP0wd3RsWLxsr9h+hFnMZl68O+SR\/MbothNWbjz8Eq37d8RskyrGCVaGHSe5PHq4kmPH5q0orZ4z22MKlLHmW4sbZier3ws4UX7WBZnsjk29HADAZ58S8aqyqi9mNhFVYarPJ9K0QLVrAKacMv97Xi12eX\/Vj\/eDXRhLO\/CfafHbxx4oBZyphuYsp71s4VPl\/Ybzy7o4s87ydJWCwaqyIGIU34sbAKkfIfT4euwqRg5fcrWIUJNMlqOhOWke\/KEcdwfaPOmviiHSzDKXRrihK6aKxcBqPnvg4H9sxKfO03OV0vcUlZrzcw9pLwgn9hgZXbm9wldOXyKFuCVRkdt65JVlOZ8PHVZUzYzU2tJTeh8SYwYWu2cteVvNaHpt8bP7je5wUrWMVCyf91tRLff4Gu8pykBFbFXIpKm2Q1lQlH14AZCRflqFKZm9B4VYxlbLrWhe3d0ONlnxesxmxg5XY9VyujswbpPZDoKksLVlka5fNNsprehJcOmOOb8TVgrgmXJy5U6yY0jsJYMBadXjCWECcpd\/sWrGBVRkBf16SupjPhzZNmdalnkhuxopFxxpSz14NlftGMRZtSN6HxWovGymXAwbJMO7Aqo+PWwcrlUbYEqzI6bl2TrKYyYTHW+A7p5GaZ8M+TMGE3idklN6FxDSbMSDirkey8qxe+sGTZ+POw8omEl2EVZuPXNMmqkgn7I9uqy4tmLH7iqizDSk8LVrDSE9BHoitY6QnoI31dYcJ6dq1G+olqtfE5awxW+oTBClZ6AvpIdFWfFSasZ9dqJKLW44YVrPQE9JHoClZ6AvpIX1eYsJ5dq5F+olptfM4ag5U+YbCClZ6APhJd1WeFCevZtRqJqPW4YQUrPQF9JLqClZ6APtLXlWPCUskEAzSABtAAGkAD7WjAMeGqdztXjZek8tIRgJWOk0TBClZ6AvpIdAUrPQF9pK8rTFjPrtVIP1GtNj5njcFKnzBYwUpPQB+JruqzwoT17FqNRNR63LCClZ6APhJdwUpPQB\/p6woT1rNrNdJPVKuNz1ljsNInDFaw0hPQR6Kr+qwwYT27ViMRtR43rGClJ6CPRFew0hPQR\/q6woT17GYcKY9Vi\/8HtzxG10\/UjBufs83DSp8wWMFKT0Afia6aYqU24Y3NI2ZPr2eWVk8a\/67osrps7KIZi\/tPvstTtj7sjx9ib0NhFeYFq57pD9OH4oZB2RpYwapUIJlKjlcZGBNmm2Q10YSTZwT3eitmz4prwmV1WfNN5jGWcGb9pMIKViECvlZCcVLux6KrMC1Y6b+wwKo5VhNNODFQeV\/zTFhbl8RxAOAAECLgd+pQnJT7segqTAtWzR0sw5R3R42vlbJP5cfSB8O0JrHChMPspq5x4Y+e+zocmJ49rS9TckpR4pKyXm9g7CXhBT8dDasy8aGrMjpuHaxcHmVLsCqj49Y1yQoTdtk2upRPlDVbuetKXutD0++NH1zvxmLCA\/miAqtYK95fVyvyhQVWHqJ0EVYpiokzsJqIKA1okhUmnGJtfiafqLHpWhe2d0OPl91YTHiQ+YICK1ebrlZGZw3S+7TQVZYWrLI0yudhVc4nW9skK0w4S7bh+SYT1fCudW5zsNKnBFaw0hPQR6KrnWGFCeu5V45E1HpksIKVnoA+El3BSk9AH9mkrjBhPffKkU0mqnLjc7YCrPQJgxWs9AT0kehqZ1hVMuHkp0Z13xftNnZ9SvORsMozCZXAKkQmXw6rPJNQCaxCZPLlsMozCZX4rDDhEKkdLvcTtcO70+nmYaVPD6xgpSegj0RX9Vlhwnp2rUYiaj1uWMFKT0Afia5gpSegj\/R1hQnr2bUa6Seq1cbnrDFY6RMGK1jpCegj0VV9Vpiwnl2rkYhajxtWsNIT0EeiK1jpCegjfV05JiyVTDBAA2gADaABNNCOBhwTrnvXs3Y9SSovHQFY6ThJFKxgpSegj0RXsNIT0Ef6usKE9exajfQT1Wrjc9YYrPQJgxWs9AT0keiqPitMWM+u1UhErccNK1jpCegj0RWs9AT0kb6uMGE9u1Yj\/US12vicNQYrfcJgBSs9AX0kuqrPChPWs2s1ElHrccMKVnoC+kh0BSs9AX2krytMWM9uxpHyCDr7XFj7bFh5jK6fqBk3Pmebh5U+YbCClZ6APhJdNcVKbcIbm0fMHmsQS6snTfZu6I21lcg4xDx6vWWzeuKcU5+NXTRjcf8hennK1of98UPsbSiswrxg1TP9YfoA4TAoWwMrWJUKJFPJ8SoDY8Jsk6wmmvDG5kmzuiQGu2L2rLgmHBnz0gFzfDM23tiQV8zaaDlrwDKPsYQz6ycVVrAKEfC1EoqTcj8WXYVpwUr\/hQVWzbGaaMJZI13zTDhbJ\/PxaDk8GuYAwAEgRMDv1KE4Kfdj0VWYFqyaO1iGKe+OGl8rZZ\/Kj6UPhmlNYtWsCUenphkJJ+lw4d9nBr2+GQ4H6en75JSixMWn8+V9YOwl4QU\/awCrRENF7+iqiEpxGayKuRSVwqqISnFZk6waM+GNEwfMkr0uvGeNa8JJ2vKJsiYrd13Ja31o+mLKo0t7biwmPJB7DGAVa8X762pFvrDAykOULsIqRTFxBlYTEaUBTbJqxISPry7bEVz4NHRy2nqxT1mMRnfp\/TRydyEmnKg6L+oxG\/uNBVYJKPsOqwyMCbOwmgAoUw2rDIwJs02ymtqE5Tpxb+VI8I7oxIDlHRPGWELablLUoTZ2Szms9JmEFaz0BPSRTepqKhOOT0GHrwFnDRgTZiRcJvEmRV3Wzm6og5U+i7CClZ6APrJJXU1nws5vhO2IOPqtcPi6MCNhRsIhmTcp6lAbu6UcVvpMwgpWegL6yCZ1VcmE\/ZFt1eVFM2F9SvORsMozCZXAKkQmXw6rPJNQCaxCZPLlsMozCZX4rDDhEKkdLvcTtcO70+nmYaVPD6xgpSegj0RX9Vlhwnp2rUYiaj1uWMFKT0Afia5gpSegj\/R1hQnr2bUa6Seq1cbnrDFY6RMGK1jpCegj0VV9Vpiwnl2rkYhajxtWsNIT0EeiK1jpCegjfV39fxCBZQSeKPCHAAAAAElFTkSuQmCC","width":481}
%---

```

---

## a.输入\1.原始拓补信息\US_Backbone.m

```matlab
function topology = US_Backbone()
%bone_topo=US_Backbone();
% 输入：无
% 输出：bone_topo：US_Backbone拓补的邻接矩阵信息

topology =[

   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
     1   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf     1   Inf   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
     1   Inf   Inf   Inf   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf     1     1   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf     1     1   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf     1   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1     1;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf   Inf   Inf   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf   Inf   Inf     1   Inf;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1   Inf     1   Inf     1;
   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf   Inf     1     1   Inf   Inf     1   Inf

];

end
```

---

## b.常用函数\0.配置函数\getDeployMethodCfg.m

```matlab
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
            % 采用原始，未排序的请求
            cfg.requestsType = 'requests';
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
            cfg.displayName = 'NIF-Greedy';
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


        case "ResourceAndDelayAware"
            % 部署函数名（离线版本：方案生成与部署分离）
            cfg.deployFunc = 'ResourceAndDelayAware';
            cfg.displayName = 'RDA';
            % 采用按照最大容忍时延排序的请求
            cfg.requestsType = 'sortedRequests';
            % 对生成的请求进行多播树修复
            cfg.FixedFunc = 'FixedTreePlan';
            % 生成部署顺序
            cfg.sortedFunc = 'generateDeployPlan';
            % 是否使用在线评估模式
            cfg.onlineMode = false;
            
            % ====== 候选数量配置 ======
            cfg.candLinkNum = 5;
            cfg.candNodeNum = 5;
            
            % ====== 评价权重配置 ======
            cfg.shareWeight = 1.0;
            cfg.congWeight = 1.0;
            cfg.delayWeight = 2.0;
            cfg.queueWeight = 1.0;
            cfg.shareDecayMin = 0;

            % 部署方案存储地址
            cfg.planPath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\rdaPlan.mat', topoName);
            cfg.fixedPlanPath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\fixedRdaPlan.mat', topoName);
            cfg.sortedPlanPath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\sortedRdaPlan.mat', topoName);
            cfg.treePath = sprintf('c.输出\\3.部署方案\\9.资源与时延感知算法\\%s\\多播树示意图', topoName);
            cfg.resultPath = sprintf('c.输出\\4.资源消耗与失败日志\\9.资源与时延感知算法\\%s\\%sResult.mat', topoName,MethodName);
            
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
            
            % ====== 评价权重配置（在线模式）======
            % 共享能降低资源消耗，提高成功率，应当重视
            % 但也要平衡资源可用性和时延
            cfg.shareWeight = 0.1;   % 共享潜力（共享能降低消耗）
            cfg.congWeight = 1.0;    % 资源可用性
            cfg.delayWeight = 2.0;   % 时延
            cfg.queueWeight = 1.0;   % 排队成本
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

```

---

## b.常用函数\0.配置函数\getPlotCfg.m

```matlab
function cfg = getPlotCfg(topoName)
%GETPLOTCFG  结果绘图的统一配置（论文作图用）
%
% 用法：
%   cfg = getPlotCfg();            % 默认配置，不按拓扑过滤
%   cfg = getPlotCfg('US_Backbone'); % 只绘制 US_Backbone 拓扑的结果
%   cfg = getPlotCfg('Abilene');     % 只绘制 Abilene 拓扑的结果
%
% 输出 cfg 常用字段：
%   ---------- 路径与过滤 ----------
%   cfg.topoFilter    : 拓扑过滤关键字（匹配文件路径，留空则不过滤）
%   cfg.autoScan      : 是否自动扫描 baseResultDir 下的 *result.mat
%   cfg.baseResultDir : 结果目录（相对于项目根目录）
%   cfg.outDir        : 输出目录（相对于项目根目录）
%
%   ---------- 绘图外观 ----------
%   cfg.figVisible    : 'on' or 'off'（建议 'off'，批量画图更快）
%   cfg.lineWidth     : 曲线线宽
%   cfg.fontSize      : 字体大小
%
%   ---------- 保存选项 ----------
%   cfg.saveSvg       : 是否保存 svg
%   cfg.saveMat       : 是否保存 mat（保存用于作图的指标变量）
%   cfg.svgBackground : svg 保存时的背景（'none' 更适合论文排版）
%
%   ---------- 指标计算 ----------
%   cfg.slackMode     : 'ratio' 画"裕量比例" 或 'abs' 画"裕量时延"
%   cfg.e2eSource     : 'auto'（自动优先使用 requests.e2e_delay/branch_end_time）
%
% 说明：
%   - 本配置控制"数据来源/过滤"与"画图/保存"策略，不会改变你的实验逻辑。

    cfg = struct();

    % ==================== 路径与过滤 ====================
    % 拓扑过滤：只保留文件路径中包含此关键字的结果（大小写不敏感）
    % 留空 "" 则不做过滤
    if nargin < 1 || isempty(topoName)
        cfg.topoFilter = "";
    else
        cfg.topoFilter = string(topoName);
    end

    % 是否自动扫描 baseResultDir 下的所有 *result.mat
    cfg.autoScan = true;

    % 结果目录（相对于项目根目录）
    cfg.baseResultDir = fullfile('c.输出', '4.资源消耗与失败日志');

    % 输出目录（相对于项目根目录）
    cfg.outDir =  fullfile('c.输出', '5.结果图保存');

    % ==================== 绘图外观 ====================
    % 图是否可见（批量出图推荐 off）
    cfg.figVisible = 'off';

    % 外观
    cfg.lineWidth = 1.8;
    cfg.fontSize  = 12;

    % ==================== 保存选项 ====================
    cfg.saveSvg = true;
    cfg.saveMat = true;

    % svg 保存时的背景（'none' 更适合论文排版）
    cfg.svgBackground = 'none';

    % ==================== 指标计算 ====================
    % 裕量曲线：ratio 更适合不同 max_delay 的请求做公平比较
    cfg.slackMode = 'ratio';   % 'ratio' or 'abs'

    % 端到端时延来源
    %   auto：优先 requests(i).e2e_delay 或 requests(i).branch_end_time；
    %         若没有，再尝试用 nodes.tasks 估计。
    cfg.e2eSource = 'auto';

    % ==================== 方法显示名（图例） ====================
    % 说明：
    % - resultPlot.m 会扫描 result.mat 文件名得到方法名（如 nodeFirst）
    % - 这里提供一个“方法名 -> 图例显示名”的映射，用于统一论文图例命名
    % - 你后续要添加新方法时，只需要：
    %   1) 在 cfg.methodDisplayNames 里加一条映射（raw 方法名 -> 你想显示的图例名）
    %   2) 若你只想画特定几种方法，再在 cfg.compareMethods 里加入该 raw 方法名即可
    %
    % 你要求的统一图例：
    %   nodeFirst                       -> NIF-Greedy
    %   shortestPathFirstWithLoadBalancing -> STB
    %   ResourceAndDelayAware(Online)   -> RDA
    cfg.methodDisplayNames = containers.Map( ...
        {'nodeFirst', 'shortestPathFirstWithLoadBalancing', 'ResourceAndDelayAware', 'ResourceAndDelayAwareOnline'}, ...
        {'NIF-Greedy','STB',                            'RDA',                 'RDA'} ...
    );

    % ==================== 对比方法筛选与顺序（可选） ====================
    % 若非空，则 resultPlot.m 会：
    % - 只保留这些方法（白名单）
    % - 并按这里给定的顺序排列（保证图例顺序稳定）
    %
    % 你目前已有的三种方法（图例统一为 NIF-Greedy / STB / RDA）：
    cfg.compareMethods = { ...
        'nodeFirst', ...
        'shortestPathFirstWithLoadBalancing', ...
        'ResourceAndDelayAwareOnline' ...
    };

    % 若映射后出现重复名称（例如同时加载 ResourceAndDelayAware 和 ResourceAndDelayAwareOnline 都会变成 RDA），
    % 是否自动加后缀做区分（仅在必要时触发）
    cfg.disambiguateDuplicateLegendNames = true;
end

```

---

## b.常用函数\0.配置函数\getReqCfg.m

```matlab
%[text] # getReqCfg
%[text] 根据拓补名获取请求配置
function cfg = getReqCfg(topoName)
    cfg = struct();
    switch topoName
        case "US_Backbone"
            % 生成的请求路径名前缀
            cfg.requestsDir   = "c.输出\2.请求信息\US_Backbone\request";
            % 用于测试的请求
            cfg.requestPath   = "c.输出\2.请求信息\US_Backbone\request\request1";
            % 生成的按时延排序的请求路径名前缀
            cfg.sortedRequestsDir   = "c.输出\2.请求信息\US_Backbone\sortedRequest";
            % 用于测试的按时延排序的请求
            cfg.sortedRequestsPath   = "c.输出\2.请求信息\US_Backbone\sortedRequest\sortedRequest1";

            % 多播结构
            cfg.destNode_count     = 5;    % 每个请求的目的节点数
        
            % 请求集合规模
            cfg.requests_set_index = 20;   % 生成多少组请求集合
            cfg.requests_num       = 100;  % 每组多少个请求（强耦合参数，不建议改）
        
            % SFC / VNF 参数
            cfg.vnftype_num = 8;   % VNF 类型总数
            cfg.vnf_num     = 3;   % 每个请求使用的 VNF 数
        
            % 请求资源需求范围
            cfg.maxbw = 24; cfg.minbw = 6;     % 带宽
            cfg.maxnr = 4;  cfg.minnr = 1;     % 节点资源
            cfg.maxt  = 100; cfg.mint  = 50;    % 最大时延

        case "Abilene"
            % 生成的请求路径名前缀
            cfg.requestsDir   = "c.输出\2.请求信息\Abilene\request";
            % 用于测试的请求
            cfg.requestPath   = "c.输出\2.请求信息\Abilene\request\request1";
            % 生成的按时延排序的请求路径名前缀
            cfg.sortedRequestsDir   = "c.输出\2.请求信息\Abilene\sortedRequest";
            % 用于测试的按时延排序的请求
            cfg.sortedRequestsPath   = "c.输出\2.请求信息\Abilene\sortedRequest\sortedRequest1";
            
            % 多播结构
            cfg.destNode_count     = 5;    % 每个请求的目的节点数
        
            % 请求集合规模
            cfg.requests_set_index = 20;   % 生成多少组请求集合
            cfg.requests_num       = 100;  % 每组多少个请求（强耦合参数，不建议改）
        
            % SFC / VNF 参数
            cfg.vnftype_num = 8;   % VNF 类型总数
            cfg.vnf_num     = 3;   % 每个请求使用的 VNF 数
        
            % 请求资源需求范围
            cfg.maxbw = 24; cfg.minbw = 6;     % 带宽
            cfg.maxnr = 4;  cfg.minnr = 1;     % 节点资源
            cfg.maxt  = 100; cfg.mint  = 50;    % 最大时延

        otherwise
            error("未知拓补：%s（请用 US_Backbone 或 Abilene）", topoName);
    end
end





%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\0.配置函数\getTopoCfg.asv

```matlab
PK      ! =岶=  �     [Content_Types].xml祿薔�0E鼾
薣敻癅%閭嚹*T>`pT嵌霫悉iK��.摍{铛X�&浧�哫;浰髏,Z硎�.r�2籓���,鎟婹奍1蔲[廞摆芢VD┄+l ξｅ诬�埶癙��.沏K%磾P菒臜堨缧7}��7�鈒je薕躣螸気L琷蟲@娀S�3q7J5軇颜趨e炀鸡�LKй�5_餧萦焫崱.�#瀙Cj'欱燝h鵁:衵W_a鷢实鋄�1p涄L|鄋�鼷<5E�T78=锡佝}惜斡仆鸁瓘�;<肣蜱a炑 D|皊7<螇�(S�'[屴 PK      ! 杅AD9  �     _rels/.rels瓟蛂� €�>�=�&MF桐濕珠�罢�:Q` 涗韹i浤l&G`髹�鄱!铷t-xBC?�y.姎�	}]>M�(�x嵿樞jJ�縛�&楠枤X
�	瓕�岄悸�/$r徊�c嚜d�5斎� �3u薁〨� K�"�*+BJ枲J4	禍轝!虍En|K穻;塯祄d�j\挫+蟦�/N嚗<漱攬�哐麡>髭�)囁綮@Dgdw点9f'h� 銪岢睲W=Z鎥%妈嚾愯�!舾5塞{~壻蘨v@;�#m偲尟�%掲N�窩篥脱嶟變g﨑�沉搝PK      ! �)=醒       documentation/doc.xml}ROo�0亏S<傌�!槎$n&(ep)t繩溙抍G禰谯@.	q�軤浮�ゅ[`gI穅j肾{亏絞鞳rc"茧tn�媱颥�锘窚�%"鍎k�$a+襲v:貕P:獗�#ぉf$蕡夿粢yRS誜Q渇袇K鏂6� 鏳y5�1葿(暞�-�>鵸V>淉;}3?喖&�I嫪�γ剮!fX)揑旮'�6-ld:l魯尢碧(`@�7薽3鲓IN靍郲廞N躢B砪m�鍞/憡&d 2;谮輒门�!5�)�)�饊�1�4苖�#)fmP�+WI遇趆}PUz \��{Z棻琨!h2�.f43m1掙6涋U伖邓療:/��|睒}�|箻�(?箭}蜍壹哤9媛参慭氉\Z醉€'�鼹p�餻 院kr鷥{等u棫7Y憌鮱�>跣�璉并然奘蠋�PK      ! 趠\/  ]     matlab/document.xml瓟MkA秋�)�i
夯Q"挿+/RhzjK貺f摰�3颂轙Z[絋E� +"h<偊鷄礇x蔠pf矷搻��3巷�?�^�u�蹣q噿L�&� ZvH%W婯棷脜|6H�)獃� y掠AV咅訂罳{砖弶屬攜枑CV1适>�s.�<赘b氉蟫T�%Z轖�龞Y原�� 絤�9(醔hɡ詻t�-詼袿妦">:l燑鼅辦{�:隣懍薕)囯b鰆颻燀焼�>稁v蹗7趰O釈'?钷瞬襪<禗雎阝虰卑f�r� �+ *X㎡鞪B叁跺醳戎s羓H$�3�仾�Fskq嚓舒m�(涟姤t暢$KK凸p.3柤El簂壀�!役�霄楷'趿]YP賂9幪彦y仯抂驹婔d決2i獎XP戶釯┇f�;搓j�2G婯揾2Y挕帾�<���%桥觸帯�8V鴂鋐�65飙瞖捁゛s'∮荪Y鄍<攷�,脳颶疦�+�4�.騈鬆蔌躾��<馢;蛧餜灸�摬�>M圬葟惯F�93螣庶oPK      ! h�<繒   �      matlab/output.xmlm徎�0Eナ亶罥厔X; `圲U剩J湂�=)€娡鱘貵嗹閘3QLC餔旆;褠3鴁壽跫9圴�;Cλ<fN1瀽盫趯\�/孡凇蟞A�9X,!�獉@~镉s菼GBS@�0�镽c囊pI	済!5D戢髈%護� PK      ! `{w�       metadata/coreProperties.xml晳薔�0E鼾
他膟礏V�.@]亜D垵eOS嬝眑C诳�M牓栔=s4瀃狢焋濎u呌8�4飬詍厽汳t儜驦瞩*| 囇篰斳P轠x唇�%8L赒n*俭轕B邅b.�岫穵�-1尶�H�$+⒗3�<#Gadf#>)煏婷vp(修�4N�?�:1吙hV公饦啼奚��!驊漉狺i黬$躐Vp紷�<�)防<魗�)y蒾餁$[Fie�&-h兢E鯲拫�3�
m�?r.�颛藌�PK      ! wn�   M     metadata/mwcoreProperties.xml]辛j�0鄘灺8苝\贏O�%{ �崺-鄞僳蟘�&7瘢CH額糲wL��8C伊X�鼂<炯r��>c鎙��:$麶!b*3�鍋Oツ7!矠蠧n=旈�-�:xA哙姠�6絏龉j�:PA*�QA屛j(�2q'驞丈隶�坈睭仆熰Q}烨誉擂抓乓鸠熝!dT缇敕)杋S冋T�PK      ! 邟=�   �   &   metadata/mwcorePropertiesExtension.xml]幗�  w焸�#⑵�uj��|庾J0€站}秜炕滌v3�鸂漨℉3J�*7h{o桴rb5%!�`v@I�&襩蕐<{窢�y噇h�鉹�<�勗@7绉�*g�j�;�<%鯊{D爉B圽W=碋)d D墒:Vg諐鮁1€J坁I﨓�徻�PK      ! �-鹵�   /  (   metadata/mwcorePropertiesReleaseInfo.xmluN��0襟#鱎á悢/藜棧Aㄐ皺専o+K�8厶ｑ哗崤�]贋阙累E[D鳄t@�3嫯偹��>:伽劫�谴/瘽�$�%�^骉q@H'�6}箼<� 鐳0�;膓咥鑞(瀥銘�-6灕x艶斯胜x�"屸_鬠訛除P 窭劦�0F蔎濽jh貧祠刣隥紣�J PK-
      ! =岶=  �                   [Content_Types].xmlPK-
      ! 杅AD9  �               n  _rels/.relsPK-
      ! �)=醒                 �  documentation/doc.xmlPK-
      ! 趠\/  ]               �  matlab/document.xmlPK-
      ! h�<繒   �                4  matlab/output.xmlPK-
      ! `{w�                 �  metadata/coreProperties.xmlPK-
      ! wn�   M               E	  metadata/mwcoreProperties.xmlPK-
      ! 邟=�   �   &             N
  metadata/mwcorePropertiesExtension.xmlPK-
      ! �-鹵�   /  (             ;  metadata/mwcorePropertiesReleaseInfo.xmlPK    	 	 {  <    
```

---

## b.常用函数\0.配置函数\getTopoCfg.m

```matlab
%[text] # 拓补信息配置
%[text] 此函数的详细说明。
function cfg = getTopoCfg(topoName)
    cfg = struct();
    switch topoName
        case "US_Backbone"
            cfg.topoFunc = 'US_Backbone';
            cfg.topoInfoPath = "c.输出\1.拓补信息\US_Backbone_topoinfo.mat";
            cfg.kpathPath    = "c.输出\1.拓补信息\US_Backbone_10Path.mat";


            cfg.minm = 30; cfg.maxm = 50;
            cfg.minc = 30; cfg.maxc = 50;
            cfg.minb = 100; cfg.maxb = 200;

        case "Abilene"
            cfg.topoFunc = 'Abilene';
            cfg.topoInfoPath = "c.输出\1.拓补信息\Abilene_topoinfo.mat";
            cfg.kpathPath    = "c.输出\1.拓补信息\Abilene_10Path.mat";


            cfg.minm = 50; cfg.maxm = 100;
            cfg.minc = 50; cfg.maxc = 100;
            cfg.minb = 100; cfg.maxb = 200;

        otherwise
            error("未知拓补：%s（请用 US_Backbone 或 Abilene）", topoName);
    end
end




%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\1.拓补信息提取函数\KPathsGenerater.m

```matlab
%[text] # KPathsGenerater
%[text] 并行计算所有节点对的 K 条最短路径

function Paths = KPathsGenerater(bone_topo, link, K)
% computeKShortestPaths  并行计算所有节点对的 K 条最短路径
%   Paths = computeKShortestPaths(bone_topo, link, K)
%   输入：
%     bone_topo — 网络拓扑的代价矩阵 (node_num×node_num)
%     link      — 对应的链路编号矩阵 (node_num×node_num)
%     K         — 每对节点需计算的最短路径条数
%   输出：
%     Paths     — node_num×node_num 的结构体数组，
%                 每个元素包含 fields:
%                   .paths         (K×node_num)  节点序列
%                   .pathshops     (1×K)         跳数
%                   .pathsdistance (1×K)         距离/代价
%                   .pathindex     scalar        实际路径数
%                   .link_ids      (K×node_num)  链路 ID 序列

    tStart = tic;                  % 启动总计时
    node_num = size(bone_topo,1);

    % 显式启动并行池，使用 'Processes' 配置文件
    if isempty(gcp('nocreate'))
        parpool('Processes');
    end

    % 将大矩阵封装为 Constant，避免 parfor 中重复传输
    C_topo = parallel.pool.Constant(bone_topo);
    C_link = parallel.pool.Constant(link);

    % 结构体模板，预分配所有字段
    temp.paths         = zeros(K, node_num);
    temp.pathshops     = zeros(1, K);
    temp.pathsdistance = zeros(1, K);
    temp.pathindex     = 0;
    temp.link_ids      = zeros(K, node_num);

    % 预分配结构体数组 Paths
    Paths(node_num, node_num) = temp;  %#ok<AGROW>

    fprintf('并行计算 %d-最短路径，节点数：%d ...\n', K, node_num);

    % 外层 parfor：按源节点并行
    parfor src = 1:node_num
        topo = C_topo.Value; 
        lmat = C_link.Value;
        for dst = 1:node_num
            P = temp;  % 从模板拷贝
            if src ~= dst
                % 调用 K 最短路核心算法
                [SP_cell, cost_vec] = KShortestPath_new(topo, src, dst, K);

                nPaths = numel(SP_cell);
                P.pathindex = nPaths;

                % 填充节点序列与跳数
                for p = 1:nPaths
                    nodes = SP_cell{p};
                    P.paths(p,1:numel(nodes)) = nodes;
                    P.pathshops(p) = numel(nodes) - 1;
                end
                P.pathsdistance(1:nPaths) = cost_vec;

                % 填充链路 ID
                for p = 1:nPaths
                    for h = 1:P.pathshops(p)
                        u = P.paths(p,h); 
                        v = P.paths(p,h+1);
                        P.link_ids(p,h) = lmat(u,v);
                    end
                end
            end
            Paths(src,dst) = P;
        end
    end

    totalTime = toc(tStart);
    fprintf('运行时间为 %.2f s.\n', totalTime);
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\1.拓补信息提取函数\KShortestPath_new.m

```matlab
%[text] # KShortestPath\_new
%[text] kShortestPath优化实现
%[text] K最短路算法 (Yen's Algorithm)
%[text] 经过优化的版本，主要减少了netCostMatrix的重复复制。
%[text] 严格保证输入输出与原始版本一致。
function [shortestPaths, totalCosts] = KShortestPath_new(netCostMatrix, source, destination, k_paths)


% 输入参数校验
if source > size(netCostMatrix,1) || destination > size(netCostMatrix,1) || source <= 0 || destination <= 0
    warning('源节点或目标节点不在网络成本矩阵范围内，或索引无效。');
    shortestPaths={}; % 返回空cell数组以保持一致性
    totalCosts=[];
    return;
end

if k_paths <= 0
    shortestPaths={};
    totalCosts=[];
    return;
end

%---------------------INITIALIZATION---------------------
k=1; % 已找到的最短路径计数

% P: 存储所有已生成候选路径的单元格数组。
%    P{path_id, 1} = path_vector (路径向量)
%    P{path_id, 2} = cost (路径成本)
P = {}; 

% S: 存储生成对应P中路径所使用的偏离顶点(spur node)。
%    S(path_id) = spur_node_value (偏离顶点的节点编号)
S = []; % 将根据path_id动态增长

% X: 候选路径池 (Yen算法中的B集合)。
%    X是一个列单元格数组, 每个单元格是 {path_id_in_P; path_vector; path_cost}
X = {}; 

shortestPaths = {}; % 存储最终找到的k条最短路径
totalCosts = [];    % 存储最终k条最短路径的成本

% 1. 计算从源到目标的第一条最短路径 (k=1)
[path1, cost1] = dijkstra(netCostMatrix, source, destination); % 假设 dijkstra 函数已存在且可用

if isempty(path1)
    % 如果没有路径，则直接返回空的shortestPaths和totalCosts
    return; 
else
    path_number_counter = 1; % P中路径的唯一编号生成器
    
    P{path_number_counter,1} = path1; 
    P{path_number_counter,2} = cost1; 
    
    % current_P_path_number 指向 P 中那条作为当前第 k 条最短路径 (或生成下一批候选路径的基础路径) 的路径的编号
    current_P_path_number = path_number_counter; 
    
    % 对于第一条最短路径，其“偏离顶点”可以认为是源节点本身。
    % 这是Yen算法中用于确定下一轮偏离起始点的一种常见处理方式。
    if path_number_counter > length(S) % 确保S数组足够大 (MATLAB会自动扩展)
        S(path_number_counter) = 0; % 仅为演示，MATLAB会自动处理
    end
    S(path_number_counter) = path1(1); % 记录偏离顶点
    
    shortestPaths{k} = path1;
    totalCosts(k) = cost1;
    
    % X 初始为空。它将在主循环中被填充新的候选路径，并从中选择下一条最短路径。
    % 原始代码在这里将第一个路径的信息放入X，但其管理方式略有不同。
    % 严格遵循原始代码：X在主循环内填充和选择。
    % current_P_path_number (对应原current_P) 是关键，它指向P中最新的最短路径。
end

% 创建 netCostMatrix 的一个工作副本。这是主要的优化点。
% 所有临时的图修改将在这个副本上进行，并在每次Dijkstra调用后恢复。
temp_netCostMatrix = netCostMatrix; 

%--------------------MAIN LOOP------------------------
% 当已找到的路径数 k 小于要求的 k_paths，并且候选池X中还有路径时继续。
% (注意：原始代码的X判空在while条件中，这里在循环末尾选取前判断)
while (k < k_paths)
    
    % path_k_minus_1 是 P_k-1, 即上一条加入 shortestPaths 的路径。
    % 它的路径向量存储在 P{current_P_path_number, 1}。
    % 这是原始代码中的 P_ (P下划线)。
    path_k_minus_1_vector = P{current_P_path_number, 1}; 
    
    % w 是用于生成 path_k_minus_1 的偏离顶点。
    % 这是原始代码中的 w = S(current_P)。
    spur_node_value_for_pk_minus_1 = S(current_P_path_number);
    
    % 在 path_k_minus_1_vector 中找到 spur_node_value_for_pk_minus_1 的索引。
    % 原始代码使用一个for循环查找，这里用find等效替换。
    w_idx_in_pk_minus_1 = find(path_k_minus_1_vector == spur_node_value_for_pk_minus_1, 1, 'first');
    
    if isempty(w_idx_in_pk_minus_1)
        % 理论上不应发生，如果S和P被正确维护。
        warning('KShortestPath:SpurNodeNotFound', '在基础路径中未找到预期的偏离顶点。算法可能存在问题。');
        break; % 终止循环
    end

    % 迭代 path_k_minus_1_vector：从 w_idx_in_pk_minus_1 开始，到倒数第二个节点，
    % 依次作为新的偏离顶点 (current_spur_node) 来生成候选路径。
    % 这是原始代码中的 for index_dev_vertex = w_index_in_path : length(P_) - 1
    for dev_node_idx_in_path = w_idx_in_pk_minus_1 : (length(path_k_minus_1_vector) - 1)
        
        current_spur_node = path_k_minus_1_vector(dev_node_idx_in_path); % 当前迭代的偏离顶点
        root_path = path_k_minus_1_vector(1:dev_node_idx_in_path);       % 从源到当前偏离顶点的路径段 (根路径)
        
        % 计算 root_path 的成本 (从原始 netCostMatrix 计算，确保准确)
        cost_root_path = 0;
        if length(root_path) > 1 % 根路径至少包含一条边
            for i_cost = 1:(length(root_path)-1)
                cost_root_path = cost_root_path + netCostMatrix(root_path(i_cost), root_path(i_cost+1));
            end
        end

        % ---- 管理对 temp_netCostMatrix 的修改 ----
        % modifications 列表用于存储对 temp_netCostMatrix 所做的临时修改信息。
        % 每个条目是 {row, col, original_cost}, 用于后续恢复。
        modifications = {}; 
        
        % 规则 1: "移除" root_path 中在 current_spur_node 之前的所有节点。
        %         通过将其所有出入边权重在 temp_netCostMatrix 中设为 Inf 实现。
        nodes_in_root_path_before_spur = root_path(1:(dev_node_idx_in_path-1));
        for i_rem_node = 1:length(nodes_in_root_path_before_spur)
            node_to_isolate = nodes_in_root_path_before_spur(i_rem_node);
            
            % 隔离节点的出边 (设置行为Inf)
            for col = 1:size(temp_netCostMatrix, 2)
                if temp_netCostMatrix(node_to_isolate, col) ~= inf
                    modifications{end+1} = {node_to_isolate, col, temp_netCostMatrix(node_to_isolate, col)};
                    temp_netCostMatrix(node_to_isolate, col) = inf;
                end
            end
            % 隔离节点的入边 (设置列为Inf)
            for row = 1:size(temp_netCostMatrix, 1)
                if temp_netCostMatrix(row, node_to_isolate) ~= inf
                    % 避免重复记录 (node_to_isolate, node_to_isolate) 如果它已被出边处理。
                    % 简单起见，允许记录，恢复时正确即可。原代码是直接整行整列赋值。
                    modifications{end+1} = {row, node_to_isolate, temp_netCostMatrix(row, node_to_isolate)};
                    temp_netCostMatrix(row, node_to_isolate) = inf;
                end
            end
        end
        
        % 规则 2: "移除" 从 current_spur_node 出发的，且与已找到的某条最短路径
        % (shortestPaths中的路径) 或当前基础路径 (path_k_minus_1_vector) 共享相同 root_path 的边。
        % 这是原始代码中 SP_sameSubPath 变量收集的路径所对应的边的移除逻辑。
        
        % 收集所有与当前 root_path 匹配的、需要移除其从 current_spur_node 出发的下一条边的路径。
        paths_sharing_root = {};
        paths_sharing_root{1} = path_k_minus_1_vector; % 当前基础路径本身总是要考虑
        
        for sp_idx = 1:length(shortestPaths) % 遍历所有已确定的最短路径
            A_path = shortestPaths{sp_idx};
            
            % 检查此 A_path 是否与 path_k_minus_1_vector 相同 (避免重复处理)
            is_same_as_pk_minus_1 = false;
            if isequal(A_path, path_k_minus_1_vector)
                is_same_as_pk_minus_1 = true;
            end

            % 如果A_path与基础路径不同，且长度足够，且共享相同的根路径
            if ~is_same_as_pk_minus_1 && length(A_path) >= dev_node_idx_in_path
                if isequal(A_path(1:dev_node_idx_in_path), root_path)
                    paths_sharing_root{end+1} = A_path;
                end
            end
        end
        
        % 对收集到的这些共享根路径的路径，移除它们从 current_spur_node 出发的下一条边。
        for psr_idx = 1:length(paths_sharing_root)
            path_to_check = paths_sharing_root{psr_idx};
            if (dev_node_idx_in_path + 1) <= length(path_to_check) % 确保路径在偏离点后还有节点
                edge_u = path_to_check(dev_node_idx_in_path);       % 应等于 current_spur_node
                edge_v_next = path_to_check(dev_node_idx_in_path + 1); % 偏离点后的下一个节点
                
                if temp_netCostMatrix(edge_u, edge_v_next) ~= inf % 如果边还未被移除
                    modifications{end+1} = {edge_u, edge_v_next, temp_netCostMatrix(edge_u, edge_v_next)};
                    temp_netCostMatrix(edge_u, edge_v_next) = inf;
                end
            end
        end
        
        % 从 current_spur_node 到 destination 在修改后的图上运行 Dijkstra 算法，寻找偏离路径段。
        [spur_path_segment, cost_spur_segment] = dijkstra(temp_netCostMatrix, current_spur_node, destination);
        
        % ---- 还原 temp_netCostMatrix ----
        % 将之前修改的边恢复为其原始成本。
        for i_mod = 1:length(modifications)
            mod_info = modifications{i_mod};
            temp_netCostMatrix(mod_info{1}, mod_info{2}) = mod_info{3};
        end
        
        if ~isempty(spur_path_segment) % 如果找到了有效的偏离路径段
            % 构造完整的新候选路径：连接 root_path (不含尾部spur_node) 和 spur_path_segment
            new_candidate_path_vector = [root_path(1:end-1), spur_path_segment];
            new_candidate_cost = cost_root_path + cost_spur_segment;
            
            % 遵循原始代码逻辑：不在此处对 P 或 X 中的路径序列进行显式去重检查。
            % Yen算法的边移除规则旨在避免在 *shortestPaths* 集合中产生重复路径。
            % 不同的生成历史（即不同的path_number_counter）即使产生相同序列的路径，
            % 在P和X中也被视为不同条目。
            
            path_number_counter = path_number_counter + 1; % 为新路径分配唯一ID
            P{path_number_counter,1} = new_candidate_path_vector;
            P{path_number_counter,2} = new_candidate_cost;
            
            if path_number_counter > length(S) % 扩展S数组 (MATLAB会自动处理)
                 S(path_number_counter) = 0; 
            end
            S(path_number_counter) = current_spur_node; % 记录生成此路径的偏离顶点
            
            % 将新候选路径 {ID, 向量, 成本} 添加到候选池 X
            % X 是一个列单元格数组, 每个单元格是 {path_id_in_P; path_vector; path_cost}
            X{end+1,1} = {path_number_counter; new_candidate_path_vector; new_candidate_cost};
        end      
    end % 结束偏离顶点 (dev_node_idx_in_path) 的循环
    
    % 检查候选池 X 是否为空。如果为空，则没有更多路径可供选择。
    if isempty(X)
        break; % 终止主 while 循环
    end
    
    % 从 X 中选择成本最低的路径。
    % 保持原始代码的平局处理方式：如果成本相同，则选择在 X 中索引较小者（即较早加入或上次重组后位置靠前者）。
    min_X_cost = X{1}{3}; % 取第一个候选路径的成本作为初始最小值
    min_X_idx  = 1;       % 取第一个候选路径的索引作为初始最小索引
    
    for x_entry_idx = 2:size(X,1) % 遍历 X 中其余的候选路径
        if X{x_entry_idx}{3} < min_X_cost
            min_X_cost = X{x_entry_idx}{3};
            min_X_idx  = x_entry_idx;
        end
    end
    
    % 获取选中路径的信息，它在P中的ID是关键
    chosen_path_info_from_X = X{min_X_idx};
    chosen_path_id_in_P = chosen_path_info_from_X{1};

    % 将选中的路径添加到 shortestPaths 结果集中
    k = k + 1;
    shortestPaths{k} = P{chosen_path_id_in_P, 1}; % 从P中按ID取出路径向量
    totalCosts(k) = P{chosen_path_id_in_P, 2};    % 从P中按ID取出路径成本
    
    % 更新 current_P_path_number，它将是下一次迭代生成候选路径的基础路径的ID。
    current_P_path_number = chosen_path_id_in_P; 
    
    % 从 X 中移除已选中的路径。
    X(min_X_idx,:) = []; % 按行删除 (因为X是列单元格数组)
    
    % 原始代码在 while 条件中有 size_X ~= 0，并在内部有 if size_X > 0。
    % 这里的 isempty(X) 检查和循环结构已等效处理了这些条件。
    % 当 k == k_paths 时，下一次循环的 while (k < k_paths) 条件将不满足，循环自然终止。

end % 结束主 while 循环 (k < k_paths 或 X 为空)

end % 结束 kShortestPath 函数


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\1.拓补信息提取函数\Link_model.m

```matlab
%[text] # 初始化链路资源
%[text] ![](text:image:84b8)
function links = Link_model(link,minb,maxb)

% 假设 link 是你的 28x28 链路编号矩阵
% link(i,j) = k 表示：从 i -> j 的链路编号为 k（k > 0）

% 找到最大的链路编号
max_id = max(link(:));

% 预分配结构体数组，提升效率
links(max_id) = struct('id', [], 'source', [], 'dest', [], ...
                       'bandwidth', [], 'delay', [], 'request',[], ...
                       'bandwidth_cap',[],'base_delay',[]...
                       );

for id = 1:max_id
    % 找到矩阵中等于当前 id 的位置 (source,dest)
    [src, dst] = find(link == id);
    
    % 这里默认每个 id 只对应一条有向链路，取第一个即可
    s = src(1);
    d = dst(1);
    
    % 为这条链路生成一个 [100, 200] 的随机带宽值
    bw_val = randi([minb, maxb], 1, 1);
    links(id).bandwidth_cap =bw_val;

    % 填结构体
    links(id).id        = id;
    links(id).source    = s;
    links(id).dest      = d;

    % ==== 带宽容量生成====
    
    links(id).bandwidth = bw_val * ones(1500, 1);  % 1500 行相同的数
    links(id).base_delay     = 2 ;       % 1500 行全是 2
    links(id).delay     = 2 * ones(1500, 1);       % 1500 行全是 2



    % 1500行数据代表1500个时间片，
    % 行号标识请求id
    % 第一列标识当前时间片、当前请求id该链路是否可被共享，若可被共享置0，不可被共享置1
    A = zeros(100, 1);     
    data = repmat(A, 1, 1, 1500);   % 生成 1500×100×1 的数据
    data = permute(data, [3 1 2]);  % 调整维度到 1500×100×1
    links(id).request = data;   % 先固定为0，后期会根据节点资源动态更新

end

end


%[appendix]{"version":"1.0"}
%---
%[text:image:84b8]
%   data: {"align":"baseline","height":179,"src":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAfEAAACzCAIAAAAWt7L5AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAgAElEQVR4nO2deVjTx\/b\/D9dgIBAImoDssrggXEAQFb14cW+tVUulrpWCWqW1LteCVRRxreL1B\/q1RVtLikvR6qUKVlttK5UWBISLNoALBFnClihZIIvGm98fAx9DEnZIAszr4ckzTCYzZ06Sk5P3ZzJjoFAoQBPp6emBgYEa72qrfWlpaefb6y0uLi56OxF9tk0dFxeXLr2EMBhMz\/mbrg3AYDAYTK+BYzoGg8EMHEi92Ne8efN6sTdd8ejRI72dyKNHj1avXq1rKzpLenq6rk3AYAYdOE\/HYDCYgQOO6RgMBjNwwDEdg8FgBg44pmMwGMzAoWvXSJOSklDB1NT03Xff7QN7NCCve1Qos\/FyoGpnuHaRcx8XSkd42Zt1rrVWLX9Z81ee2G6yi0XnWnMe5EkdJ7uY97FVGAxGq3QtTw9pQWsBHQAaim58n1mhteHapaHw+vcZVQAAILqbuCvquwfy9lpr1XJe3oWvfioDAADBb0fWhH2R\/bK91vkXv7pZoh3LMBiM1uhmng4AISEhvW1MH5Kfn89gMOzt7YmayspKLpfr4+PTzR6p3m+usICRvbAYtPdtM5+8ZAMdRhv23DZ1rl696uTk5OnpSdTcv3\/\/6dOnCxcu7IvhMBhMl+hmnt7NgP5KLhWJpC9UauVSkUgkVkt45VKRhsbNnYikcvW28ldtjsxgMG7evFlZWYn+raysvHnzJoPB6MYkWjCyHjvG2qi1yWJNE+mIPrCN4uDt6UBpVfWyUSBobC9zb2knFggEYlmb9zs5OR07duzBgwfo3\/v37x8\/ftzJyakH1mIwmF5DO3k6Nz3+G9Gkf3Dv3K5XyEUiktf7298bSwIAqLubyLxRDsbGryQSkwnL1789xggAQPo47eT5uw3GVONXYGT0EmybO5I+TjuZfE9qZAxSCclr+YZFY4xAWng5\/vtHptYMaU0N6R+hG2Y7aJiUvb39nDlzbt68OWfOHABABeXUuOsUfhd1y2bz5kAGcG\/HfyOa\/A9u+m0eyBtFJK9V2xePaW2EtPDCkRQIiljqbqTWUR\/YlvdFWIrjgQPzraEmLSqWP\/ONmrS0OngpEBhO3hy3xrN1Ai\/OS4hkQmhsuC\/kfxX19QNzB2txRYXhrMiYd13UU31PT89NmzbFx8dv3rxZoVAcO3Zs8+bNymk7BoPRIV2L6T3QW0QFRbBm6y5rElRe\/\/fJO\/feHDuZCjU3zqaJJ23eM52Bot6ZM4zPPpxMfXH\/+7MFlkGfbR5PBZCXpv47UQwAAC\/uf3+21H3DntlWAK8qb8RdvF0z5k3y3dv\/dQjau9xrCIBIJKW2OSMidAJAj4Om2vT+KoKwT3dZk6Dixr9P3b43d8xkpSuj3Nunv+cFbAjXENC1YJsgNw8+jT3hYAilFyMPpGUEe85QujJakxb7Vd0bMbt8KcC7lnrX9YPEjycBvBIIZOZtaTeenp6bN2+Oj48HABzQMRi9omvaS5ISXR3Jxf8f1iQAAPuRNiCWSgGgouB+g3vANCQyGLm\/Ndu+vKBQBHLW\/UemEwLGo6BIMqM2R0I56\/4j14DpVgAAMMTeY5y89HEDmFpbUkrz7pSK5ABUaltBs89xmdQ8PQcHG5BKpa\/vkRZ9d\/KPYUFrAhlDdGSb24y5DoYAAC6ujiAWi1\/fI87\/4sDPjNDI+dZDAMDcwY5S\/Pu14oaXMMTcnNJGbwAA0NZ2nhgMRrdoLU\/XRGODiGFjQ0Q6KtUMpFIpNAieg42XtVrzBsFzYF\/\/9+FbRI3lNIChY97buPyPH9P+va\/BwjMoZJGXRRuhE+nUvadvdI7a26eLG2CoRYMAoO0PHN3YVpUWW8ADMp3XAEABAEPP0AMf\/3ru3I4NPPrk0E2hk+maH\/fgwQMkuSgUCiTC4FQdg9ETdPqbI1MLKre6mriwKWx4DkZGRmBhPgzq6xvUmluYDwOLgNXbPvus5S\/M3wIAgOryj6Wb9+xa717zfdIdrsahiKBpb29PCB3EZck+5BmMWb998wzS7Uvpmi3ToW114BkVd2CBYdrX12pQzRBztzkfH0g4EeVT\/lVcS2VriIDu6enp5eW1adMm5UumGAxGt+g0pjtMmMwozLhdIwcAkBZev10z2s+bCiTX0fb8u7eKpAAA8pqCwuZgSPLwdRdl3HogQv\/KRSI5AEgrS1EHJGsHayOpRKphIAAul6uc\/KLQyeW2FWZ7D\/fps61JVP93p8Pt\/2SJ9Ms237eDHAzNZ4W9DWmJvwgAxKWFFS8BAAwdXB0p0iaxpgeVlZVt2rSJSMy9vLw2btxYVlbW59ZiMJhO0Jt77XYdRuDqVaJvTu7LNjaWSyQjJq8P8TUCALPJS95hn0ret9uESjKwDHB3gUYAABjq\/t6ahjNJ\/9593dgYJBID9\/c+eW8Mr\/TP5NNnFMbGIJGA+3ubNUsW6mu9UVLcVYPtRxrdupTyaGfQmK6J44zABZPvff1D3vhVvmoKTC\/ZZu0ympLyNfPBiVDPrtlmPf\/9GXc+Z2b4vi24eSL2BFAoIG4E33UHXDS1Vl+H7uXl5eXl1UVrMRhMn2DQi2fXjRkzpntGyKUiCRhTjUidqAUAkItFkr+1ukcuFUn+Z0yl9MJH1KNHj9qdiFwqkpM0WaUFHj161O6T8lIseGloTunRb41eigVioJhSDHt8RberLyEMBtNzdJunN0MyomrYEkVzLQAAiaJ6T9ttex2SUdvLJXWNIaXN9Ydd6QPvAYPB9FvwvowYDAYzcDC4ffu2rm3AdJaRI0eOHDlS11Z0lqdPnz59+lTXVmAwg4v29PSJEydq2RoMBoPB9ASsvWAwGMzAAcd0DAaDGTh0YQlH9Nm\/GGbS\/3dF468LW\/H+DKe97\/+9B1ZhMBgMpjt0Iaaf\/a2sjsnYtrDjfb0PX9X8Y04MBoPB9Cl9or10JpcfNIiu71yZVNj2GROtkeUf38ws7mzrDpFXpURG\/8LroBXvl8iVJwraHFTGY6cnRa5Yefy+DGRVBVk5OVk5OVk5BZxeMxODwfQWPfr5TNBh\/p8Pm4\/OiVhE+XShSWceJROJXgylUsldH4\/PLijmwQg3byelHxjJRewHxTwZ1dnPja5\/PwaS5Zw8XjE7zvaFiN\/6xKYhGlwgK0nefLBABsU\/zkwIcmijRzn7l5PXilr+Y0wJXebT1s+tZAXHPjqQTl66VDaL3nosUUGy8m5ncpCdjt4mnuVM7K\/LmBa6xJsKUHA6cPPtiUHBi9d\/EeJMA6jLOXVZFLrYjZdxJG10QoJtN55FDAbTh\/QoCv758GUdswtHrInyk\/bFM3\/N503cn56wSGkjV871zf9P+unhIDtlczgpm2ONPj02zw4AAGT5R4J3c2atnAQ\/HDkwdF3C\/ll0AJBXpWwOTqYEBdA5+w\/a7r0Q4d2pj5WC4xNP2aUlBFl13vY2Ojrhe8ru51ZzUaap4Pi+lKEUu+h111rVv+KyGRt\/Tgh6\/TC5qPjakehz5I1fJAaYFn8VHhwdtDdivpuGn6w+K\/jPSfbkr5e7AQDAUKuhbZgmKz69enP1+qu\/2iSHrjwembhxolLoF7PvZMje3vxPwoDJk5Qe2vD7kTT28iXeVAAQ8N7aGrtReUMaG6+J\/t68OnpaGwNjMBgd0sPMVpGa+1o6X+DXwYkUVPegXceD3k7w\/07lDtt5OxcdCN+cEhffEtY5KeGbipefjLJrblGctD3n3S8uhbgCLAkavy\/wVFZAlD9Zlpt0gLwrPXYeFWC+7cqPzhb\/tN5N49AykejFq6FUWnNeKdO05aCMLwJTKrl9l8hEIgkMJZrJ2tYf5FUp28LZqy+lLrJTvasuJTyGaCaryr1w\/OjJsomxCcfIzIiw\/4bHbkxMyDkd+fZSeuiG9UH\/cFaN7AHT3vKf2MbHSPPQ12M+Ogkbzx2eZUeCiJMbD4TO2bwycd+7Sh8Sw1wm+nmRG9XOezWmUvlVygE7ZXdwDgUA3NZ9sTfgcTFvhHc7I2MwGN3Sw5hukJbbrL2Mse2ENE+mUslA1ZRZ0gOiEqAlrNc1B\/QAIm6JOFWciUGuzb1MDJwfnnE\/yn\/i\/YzkmXM2ovzTOTDIJiyjeL2balCXV13ftjKWO3GixcMczqR9+9y+C47OAICZHtEQco4VYXclPFIWujgnMrbcLnT\/ubcehgeWrmNt9QYAqEsJn1m6jhXhDQByXsaxzZE\/CO1syVwOOfRULPXEnOgMAAj02AkhZ1gRrXZX5P2yI\/iW\/0bn5C3Bya9r5++4FIJ2MBxi1NLs7VOwPuJY+kRbMgBEJDpnnP4uY9TGgPWJ6UuLr39zZEXa7C8PBtkRIkdtVc4QV5DLRDIyVdOXEl7WV5ERTFidcP59b+qzlPAY2JcQFHXhfMrnmwMveUftjwgaS4Xhb8XGApWfEf3xqWLika+47Ic829Bzlza9FRsLRFY\/f2viRm8AgKFDCo4fqwr9whkAqFZ2BQnHjz+2Gx\/2YUB7Hy8YDEardCem\/\/tq05ErzYnu1x\/12t5ZzWE9LIwsdlmnHNABgEqnU+4XV4C3AwAAt64Kyqp44FxVBoxZLQaYmdE5pRrS5sKUXQ0br54JsgOQiURkKjXgVwifeWv2r83aCw8gZ99+tzM\/p\/uQAYD3ULN5Vf\/ZHF7y1k\/py+xIACKRjEolJ6RDeOCtuematBf6rINZs0gFRz6fGIU+EgB4V8KZ6ACQBl6ZE0q06bNis2ZBwREP3zDlR5\/4CgC8t176ZmvCPJWOX8lkBSfDVzBBXMUmzz58bO8s29d38q5vXnyesfHb9CDX1kq3iXPQ\/tRpWV9FfrwLzhwOsiVTqQDUWXsvzmpuICpOjtmWHZx4eIkzGYCs9KwONaNSaQAAUFLtsid+nhUAANk\/Kstfs6MwGIwO6U5M\/3ShCbocahXKXftl8zkPY2z\/1slrpO1Ad3ajc64Vu813oqnc4x20gxr8r0juysnmmSmFrzR9kFDpmqX9Ea4TH3+XkjVxnZ8dua3dG5dEbPRp\/3IfOyOlIGTruWZpqDOXeNtxrVhQ1ep\/7wgWK0Lpf1n+kZWJLofed9Mwiuf69GsRdBoAyAqOBq\/8f9ezjs4jZkWfF5+u+iHwGrr\/h4k\/azKMd31z6H\/nn06N13SB4bX2smNawc65x8kMdLAqt0wW+l1qiGvb08RgMFqnp3r623493tyVgJMSvqng3TNZ3uzW2joAANgtSkj\/B7v4idBsx7mQx0eu\/8ygAhgp7\/HNq2Zr7NZqXsJ\/6EnxnwVGwPxP9366yFlDoKR0GKOFVYUBLo5dnhNA0kqP1+dxh5wBAOBx2BMdlVJ7WVVBfvVrYbvu9yMH7wfs+2d1bgH4eNupWEai0ps\/8MjeSz+YOLew9Oi8LijcyKX5RzxWqZ4S\/stMJZEIQs61fL0I2nOJkJUmbbgpfbUrdh4VmjIOLC2eOLLzA2MwGG3QUz29w+uinQUFdKQk2Cpp60oGkunO3nQAgOL8XwP+HkoGupO33WV2FfjYAQDwqsoCXNQuRwIAgNXEkM\/PhYhyjiwPPu6QF2GrsVH7mNm5ZxQ\/loFVV1fvvQ6OAACc65FLmA85svmnlSzl55yKL329CsXqnxHH\/gnA+z0+zeV4gl07i3NeyESUbq0m9Gn9xaCuWXZXlZDkMtEL4LByMiqK\/\/u4UOQVGTVz\/fgPI1O8Yp0vHBdsSHTTv8WjGMwgp0e\/OZo61tAqlIv+\/n21qfsd8a5vJgI6ACBtfUnxlm3XiZ\/LyEqKq+QAAFCRcvyc57uBdABw+0cQL+l6sRwAZDmpKU5zp2m4XMcpLkb6ENXNfbTsRZMMhts5gwzkmm0hG1OhhF0lB5CLcs59m9Fc7RwQ5J383QU2mqWIXcUHALqdE8jkXfnRrO282IuXUv9I\/XAs+\/qJjNc\/BhrmMtF\/osqfyzC1h8urrp9Mbp6OXJRzKUm0ZJrmhT69QcHZlUd+BF55FVhNDPpw16cz6UByXrZv9q13AqNfReybq61jSDAYTKfpUaKVsk1V9m4XXkp4YHRzjGy9VoQ+L\/7CPBVb6AFR5yZCSxYqKk4\/Ev4tz26EkF3rvPFUwiw08tiQw0HhYYHX7Cy4Mq99X87XENJFdRnHV4Vz6AyyuKpqdOwlfzKQvGZvEK1esiB5xKR1zCgV4YL6j+Uffr164dxkWwr13UMRIcy7qN7u3fiEqs0rpjPtnMyqOPTQL459SKN6zd0oWhu84JLdpLWJUbPUYxzZ3JZdXCJyUbNL9td\/jhe6nCP+f16ak5XTuhWv9DmonghKsvN0YH\/2pr\/Q1g44bPKsfad3evfdz368Qy\/tfe5xa3pQQIv2IirLSD54nDcvyPnnIwdGt7GCHoPB6I4u7J\/uFJrayV8YHb5K+mShXy9Yp4JcJmoEYo35a2QikZyqcWGfcpMXf2vdpkkkIrV5rbPNterqNshlIkmbF01lJddPfXM5gy1Sqac6B4Ru2BiAvpfUpYRvLFX+BRAAENqLxh9GyfiiF8aduFDblqhCUJa88u0DBUB22\/DNufUaPh4KmMH3fdD6S94vkYu\/HRK67sOgACcqyHk5Z2OP\/8jYmBQxsaeXxjEYTK\/RhZiO92XEYDAYPcegurpa4x2PHj3C5xxhMBhM\/4JkamqqaxswGAwG0zuQ\/va3Npe+1NfX4zOCMRgMph9BMjAwaOs+XZ1SHx0dHRwcrP1xdc6lS5c+++wzXVuhSw4dOjQIPTA4Z90XYE+CPp9Hij5sBtstBoPB9AT9jeloQc5gu8VgMJieoL+\/GCHyVoVCMajKGAwG0230N6Yr562DrYzBYDDdQ3+1F31Qt7GejsFg+hf6nqcfu15tS\/9fws\/8Dtsv8B228U1rfdDEe0VPx7\/aHZwecA5LbecLmwEYxKz0WDXTSYsW9VcGrSf1N6ajvDU173kdkxGztNU+Myfu0TZMUI3yey68VE9129Kp9b\/+7G9ldUzGtoUdT\/zw1a5sDNl\/GJweUCignV2VdiaLX736nzbt6b8MWk\/qr\/aiUCjakpj\/L9dCvfLLn\/kKNYh++kV9hz7ROPHOZLIDBuwBDKZ9eiemy4QazgF9jVAobGOz8nbonr78Wpt+dmvvwoUL997it9asH367cOHCvbee6YV6jvX0PqcuJdzDw+Noga7t6A5Zj15O2vZ8cSyf+PvtgfT7O2UrYzPQ3\/ZvlebVizPtZFeoWXgKr3V1wVEPD4\/wlDrV5m3Va4GueVKZ9l2hl6+uXtBeuGnh0zaVbrh28+NxqnfJyvOvJh89+FWWbF78nZ3ko+tOFKI73tqT9qGPauvWdCZvbetRrx\/rYE9rQ7NW9JIC3ru3GB1TlxI+Mxr2azw3XNuwyl+KxIpNIep7GTe\/VOKvNWjZJA24OrfjKd6V8MCdsPdXzVtGa43+4cleopsxPf+Q8+KvWtUcne98lPjnw8vsz3zg3kG39866v71mx\/eHFnrbk3nf1\/9FdvnEH\/74IvV5x0N0I29FD1EgbZo+Z3fqHIXaGnCiV52vQ2+rjNEhvKxbGQABujaDIGiKUcC4No\/8XXyk47UDfYhVUAIrqN0WvDs\/64s79dqTvUoPtJeQxIK8ArW\/tD3+yo1c\/WdNsZdWFdbKoKYyC3xWbdm6qnOnZRBCc+dppVnzbu5ZsGDhtw8VCoVCUZy4YMHChQsXLFgQmdKqsYrGrdtylybbNryUcI9mmr8XFxzxIDhS8LqNWrn523Q48Z264KhKV+qd6yO8Ky1Wzmw5WQsAlKfTau7N03l8JTxwZwYAZOwM9AhP0dy1Vvh\/qeL4a+LfC1++etXFV0XJqXBiPnUArabsEX6FBwCQf4R4kpWfRw1OU9IW0L3hV3jNTgtP4bVSHl6\/xlYy0YOJc80yome2DA1wK6a1MX1M9zzZ6dePxrvQ1JBDmpsh3ann0+kM3dVehrm7g1nJpRW7f1SutXvjsw32ju7urw\/SLLl66mDWEHBfFyfLT5XN2+oKUAIAVflZv5JdZ7q3c2ySgUHzeR0n7tHUr4yNSWi1COkTvwYALvEoAwMDhVI\/xcxtV8B3Q2L0HPqjxAWRV5T616tblTl2aeIEBUcDozOUzgUEXkr4yqTmo64LjnisXOkB51ihbTseIMN5HSshAaDgqMdKpkpXgdGwN50VRM8\/4rEqeteVaX2qUXTPA1CXsmtnBoSeY2315rWEaWieTsg5VoR3XUr4zOiVR2efg5WtfRWUDuGBOzMCdKq9iGWKo1ebPp5HeSHv+sc8eu7qUsJnRkfHpExLCPLeymJthebnbiezYFHziecZrutYCQkFRz1WMqOZ+UERtpqcZuXsDJBRwuaB3Z2fMwAgo7QKAEozIGD\/NDrcIYYtOLoyCQL2\/poQZFVwxGNlEgAAPSghHcIDozNQPRQcBYAM57WshARVY\/qIbnqy068f1srXD1L38+xQSGIm3cqP8PYpuMUECJjdm3Nrm27GdJ8P09IAKn8ODAwEAAA5N\/\/y91lNEPjKfsHBtAWvG\/pvPZ343giQ\/XV6RST547NzzQDcg+J3\/Pgk80GV3Uz3doYg8tYNE\/gqy9fGJDg9Ci9Tab9P6VHKOa9CUZz1A4Cv\/4ThoFCM8X8Hrvyg2lJ\/bpXp0sQJ7FwCADKSVnkkhZ5jbfWGuju3MgBCZ3sDAHjPDoUkJpvd\/nWq5sbohbg3lLjwgbqC6ECPaFSRUVoF0Iexr3seQPpJyHRvAKD7zw6AjAyA5ulA0kqPpOZ2JWzK3Na+0gMMDAyOXG0iDTHY8a7J1zfF5c+6GNbRc2c1bXYAZLQ8PeizGQAA2Ow6QPMMcLGDllcLu4LHq9DoNPSCKa0C59KMgJBQSGLeKljpwgZwdlB+3ptj1jQr4iFt2RfgYkuU2ew68O4znb3bnuz860f94rCyn4NW7g1gRifdLoiAW0kAAXOn9ca0OqZH10jt527dOhegIf\/ouhX5jPfivz+0wFGlSfpnU5w\/AwiMjZ9uDT\/FLE5vrrdbGLPWvt3Ou62nE\/+0rmzW0tX1dGU05ss6rO8G9EUJLP+U8JnRGcyVHsyQc7+qnlPdU\/Qm\/HWHgL3prU5nDWrlK1aEne5MQ0QtGdcoewXwuHe6q0sJnxmdASHnWBHwOuJ0Ae\/pIcBMunUUkgJmp08vTWKyb51jZ0DIOh8AXaxg6Ty97EmEyuunLoUoaPAz+mRl3kpxYQOErNPWN7\/u6encn3e8\/fbClr\/3wr64JyPLCr\/e2FKz4+eWL8Pua46dP3\/m\/IbJ430WMOrNAzdE7Nj6ll3hX1zyMLP2xyCE5s6jaE1LpaWdL0BeZi5PoVAUZ6rp6SoP0WF9lybbHlZBCaz0vQEAwGbDtNkBAMxbBQBK+RTd2RVQNgFQVZqhsReUw0Uz84lunZ0BgHmqeTlafopO1qV1CN3BGQCSbhdAS84FAKrTqUtJQQVlX9U1P1aHrJ7rsnauc9sH1XQEeqLzmdHoyxmnNAMgYH+oN\/DYJe09rg2nAdi6BACwS9jg6kz3mR0CGUnMjJZvcgTIt7fu1EFLPtvcq7NrdyfSY7rtya69fhCa\/UyfNjcAICl6p7rH+pDu5elkhntgIKGFV2UVlua7egb6E0mOJYMslwkFMgCQVRVmllSWFC1MCF7oHne6JOI9Rm46+e34haoZvSqEnt4lNOnpw2Z\/vCEr7MSJsIUnwNfXFyCvdUu9ue3qZDWi9AUQQs4kBFkBJJwr9VjZ8p0x5FxCEB2AvnJvADM6eqZHNAQEBABoCOsteugqjyRozlAiWOfAY2X0TCS+BOz9tf1lDzrCJ+JcaNJK5koPJihNrvV0AELOBGnwlVXo3oCk6J2BHj\/vZSXofnYpmdK5XkPbuvcfblS1uhZxIGBv+lZvALvm6ewMCGh\/+YlmpzUnm9EZGSFrEwB4LgEAGc26hBL0oJi9t2ZqeDl5t7zMbu1PX9eFefc+XfBkp18\/Sg8J1ehnQrpR81gfYtDU1KTxjpycnBaxvCPuHXR+7\/Sa79k7JihVclPDJm1OBzJjnI\/\/ZB\/fwFXv\/YNRfyHsnzvSgRJ46KfE99r+lqt8ztGs\/YXqP\/DVKKpahXJ\/2dmeQK\/\/KJ9z5BSa2vmJlzEXwIBA+ZyaweMBldN5xDK536afyk4Oz3r0cnOiyH64aqpZ9ex\/xmQjC9Oh9pbUzz\/otzpYH6CHnnx9ZbUvetdEj\/R0WW1hfokQHlcCuNurLE9gLEj4Os9tbWXzNVJhZeHlg0ePpAOFTBZnnT1y2mjN3Llu9uS2x28nb\/3ET8MPBD6aS2u1Ph2gn5bbQePE\/7XIusMHDhgGlQf8xxhmHx6mXv8vpvjvLq5LpnX0VRfTgs48WZdyiok0Ge3Ro5hOthD+tH7FWTGZMXOrj1reTR5m7\/53mfkQAAAoPLvl8\/zx685nh\/lDwdkTnx898aPP3L+3d5UUCS8LfIfFXHipti8jd59a+wW+wxSvNXTV34v2rzIAvD\/D6fBV9V0JNUz8\/RkDcG85wB7A9G9alueHnmNpd11sz\/YGIPvvYbH3tHXv+DVpV1sa+u34Pa+lfsL7e\/7zfod9I5V50zwbhUKxeKKdPujd2tTT0eaxnyzs5jMzABi0HvjrKV\/y4n9Wody2GgwxAA8dX8rtH+jUk\/QOf2XbR2hrr92uj6O8GmTw3GIwk8bQ2Yn9+PKA\/jA4Panv+6er0JbuPFDrMRgMpkvob0xvK28dbPUYDAbTefT3TAwDPdjNXPu3GAwG0xM6WJ8eHR2tZYMwGAwG02060F6WLl2qHTuUuXDhgk7G1TnjxqmdKoLBYDBdoWPtRVf6gz4oIVh7wWAw\/YuOY7qu1vPpw8pCvJYRg8H0Lzpe90Lkj8rr7fq6rKtx9aGMwWAw3abjmK6eO+NyX5cxGAyme2A9XTe3VVVVMTExIpFI49wHAyUlJWFhYQ0NA+e89vbJzs52biE7O1ubQx\/7oYgrkKIyVyCduuW61ZILKw7dEcvkqPLrG4+tllywWnLh9v3Xu+tEnr5nteSC25ofCsyBAMkAACAASURBVMs7Pn+ZK5Ae+6Go\/Qbzd\/3Sma4QYpl8\/fEslfaF5fz1x7MIs7vNwHZIH+jpvJ9j5sf8zMN6epu3lZWV0dHRIpFo0OrpJSUloaGhfP7AOay9fRoaGpKTk\/Py8thsdnJy8uHDh7X2YRZ5+l7OI56JEQkAuALpopjf9n8wvu7i0kCvETFnCwDg6xuP0+\/Xlp1ZzPpq0dHLhShqRJ6+BwB1F5de3jV92+l7RATUCOqWYtTel\/56vhQALGlGnTS7SSo3oxg6jTBt3YnEjGJIaWc3104w4B3SqTxdnTbq+Tdj5s\/\/vyqHCar3dqmfro\/bn+pZLNbu3bvDwsKoVKpK+04+u\/2d7Ozs0NDQ7du302g0XduiJSwsLOLj4y0sLABg9OjRAPD4ca+eqaYJsUy+4tCdpFsltnQKettfyayY6m453csaAFxtqByeuILbeDWzYscyTwqZZGJEMjcZWs+XFJbzi8r5EcEe0BJ06vlSrkAaefoeSgkjT98jEtjCcv60rTdKqoWuNuoHdDTntlO3XE\/5o3ycI41hboSsUsmCiQ65AumKQ3e4AinraYNQ\/HJtXKbVkgsongJASbVolK0ZANy+X4N6UE6usUOQQzqVp6vTRj1tTsy1azHv2Knd26V+uj5uf6r38PBITEx0dHRUbgODKU+fNGlSRkYGCm2DkGfPnikUiuHDh\/f1QDFnC2zplP0f+KC3vVgmT79f+6afrXKbonK+uclQlewvs6gehRvlyqd1jX8W1s3+7OaKQ3f+LKw3NTYEAK5A+mF85pG1E96Z6mhJM1YxgMht938w\/kRq8ShbM7FMvjYuM9BrRN3Fpb\/FvrHz2\/zCcj5XIOXwxB4jLQCgni+lUgxNjEgl1aLfH9TuWObJ+mpRUTkfJcu1zyVTxlnevl\/z0f\/d\/S32jbqLS23plPO\/sbFDlB2C9XT9usUMbCQSyYkTJ5YvX+7q2ucndcaumRC7ZgJ62wNAk1QuaHpBBJqSapEtnVLJFRNJK9HgCUeIoh4oSQR+o+m3Ds0daWX6tK7xSswMv9F0AGCYG\/0ZN2\/SWIa6LKCc204ay5g13sbVhpr9kAsAK2Y4A4C7I22qu1U9X0KELVASE55whF9+MtndkcYwNxrnSKvnS7gC6cNKAZVCOn3jyb\/edXd3pAHAm362TzhC7BBlh+D16fp1ixnASCSS7du329jYEEcz9jXobU\/IBaAk4KI4pR6tqBQShycmdIN6vsTcZKiJEQlllADwdyeLaVtvKF+sYz1tAAAVVbeeL1HObakUQ0uacUm1KNBrBGoplsk5PDEAZBbV+44ajipLqkVv+tkiQQMlqkQzFOkA4Gld485v85HUsPTg79ghKg7pk\/XpKO0EwOvT2ywra+7qc8cMPBoaGlavXr1s2TKtBXRQ+uaO\/rVjmBDXBovK+SGzXZ9wXsu+SGGgmxmhcIMqb+RyUNBB8u7XW6ZQyKTI0\/cyi+pRYghKqm5blNU2VnGbVK4HltU2CppeeIy0uJHLQQKIWCbPe\/JsyjjLJqkcAJCpRLKMMlbjoaSRVqZXYmaoKCHYIYRDuqCnd6GslHt2+bFqevrgKXf4XGD6KRKJZM+ePVoO6ABQz5cQGZ8lzaiK21RW2wgARy6xFk5xcHekjbI1u5HLAYDCcv7VzIqIYA8KmWRGMcwsqgeA2\/drODwxUgame1mf\/2wa6ip2zYS1b76+HEKoGcpY0oyLyvlcgVQskx9MfoByW1cbavr9WrFMjirHOdJMjEhC8UsUMWPOFvxV1mBJM2I9bUi7W0mYOs6R5u5IQ4ESxTWUCBeW86du+bHzywEHiUM6lacrun4Gm0FLnt7VxxKhrXuP7Ue3oJStEzWYAQmHw8nLy0tNTd22bRuqSU5OnjRpUl+PS2R8AMAwNzq8ZsLifbefi2Qhs11RDFr75mi0EmMYlXx513SU68W87702LnPnt\/muNmZXYma0v3ZQWc1Qxt2RtnCKg8eHV4ZRyevmja5+LqGQSdO9rEuqRU6rLgNAyGzX2DUTAMB31PAZkT+hmqnulgxzo5Jq0e6V3h\/GZ5ZUC1EzlLF+stCNQibtWOaJZoFsJrJj7BBkcwd77RYVtbdsvg0absYcg09i5nT3wj7elxGDwWC6Rxf0dGXayisVCoWBwbC5e\/Z0pb3m\/LTr4w7AegwGg+kSXdvvBddrvx6DwWA6D16frl+3GAwG0xPw+nT9usVgMJiegPdP17syBoPBdBu8f7o+ljEYDKZ7dBDTL1y4oB071NHyanF9uNWVqzEYzIChg5i+d+9e7dihTHR09MiRI7U\/rs4Ri8W6NgGDwfRvOr5GisFgMJj+gp7GdH0QtXEZl3EZl\/tdWU9jusYFMLiMy7iMy7jcfllPYzoGg8FgugGO6domNzfXo4Xc3Fxdm6Mz2Gx2eHj44DlmmiAuLi4uLk6bI3557QlPKENlnlA2c\/tvTqGpYXHZxEmezFtsp9BUp9DUO6x64lE7zzxwCk31+eSn4sqODxLiCWVfXnvSfoPFB\/7oTFcIsUy+6VS+SvviSuGmU\/mdP4C0LQa2Q3o3ptdciwpDRKXV9KQjZZ1oINU3NDRcunTpjz\/+YLFYTCYzLi4OBbWe9K9vc+xMPZvNXr9+vUAg0PK4Op97bm7uN998o81xd555cO\/Jcwp5CADwhLIln\/+5e4UHO\/HtAA\/GwYtFAMC8xc5gcQtPzss9NvfYlUcoauw88wAAypgLzkdO2XXmAREBNY6FujUmD2nHNq5ABgAMc3In5yKWvaIakxwtKcr1XIGUakxS2eq2qz7R6JAy5gKNDjl+9XFRhUCjQ9p5XREOacc2dYe0Pxd1hwBAPV+i7pBejek1efBuYmJiYmLiAf+7UV\/kd7+nthZr9\/d6CwuL2NhYGo0GAKNGjQKAJ0+e9LB\/fZtjh\/W5ubnr16\/funWrubm5lu3R7dz5fP6lS5fmzZunnXHFMvnq+Jzzt5\/aDDdGb\/u0bI6\/G32ah6WBgYGLtWn1M0klr+nHnOqIxW4UMolCHmJuMpQrkBZXCh9WCjcvGgMtQYcrkPGEsp1nHohlcgMDg51nHhAJbHGlcE7UbXZto4u1qboNO888cA5Lm7n9t6tZVWPtzehmZLFMHhaX7RSa6hyWRnRCdMgTylbH5\/CEsqIKgUgi3\/BlnlNoKoqnBgYGpTXNo9xh1aM8OiwuW\/LiVSd9gobW6BAA0OgQM4ohTyjT6JBnohfIIQCw6+xfGh2ibgNK9mftuK3uEKfQ1IxCrrpDwuKyn4leqDsEANi1TeoO6dWYbj1\/vk9zydquNzsekDx\/\/lyhlfPj9Q0\/P7+bN2+ij7RBBZPJ9Pf3t7a21s5wBy8W2Qw3jl7ugd72Ypk8g8Wd4zNCuc3DSqEZxVAl+7v7kIfCjXJleX1TVjH37Zg7YXHZWcU8dLwOTyjb8OW9AyGeCybbqR8mR+S2u1d4nLpR4mJtKpbJN3yZF+DBKGMuuL43cM\/5v4orhTyhrPqZZJyDOQBwBTIqxZBCHlJa05jBqo9Y7JZ7bO7DSiH69lDXIJ08ln6HVb\/5VP71vYFlzAU2w40v3qnADlF2SB\/p6TU1VdaOWnrp9kskEsnJkyffe+89Z2dnXduC0QZsNruxsfGNN97Q2oj7V3nuX+WJ3vYAIJa9EopfEoGmtKbRZrhxFU9CJK1EAyIdBiXNxNd1WFrMPx0tTcrrmy5un+rrOgwA6GbkXz+f4Td6uLosoJzbThg1bLqnlYu16b0nzwFgyTQHAHCzN\/N3Y3AFUiJsAQChrpTWNMav83GzN6Obkcfam3EFUp5Q9pgjMjUmfXur7JMFo93szQBgjs+I0ppG7BBlh\/RJTK9JO5FiFzS\/BzFd52s8+7QskUh2795tbW39zjvv6IM9uNzXZbFYfP78+RUrVhgbG4MSfT0uVyB9zBEhuaCeL4UW6UChUKA4pRKtFAqFqTGp+pnExdq0RQeXmlEMjYf+DWWUAODuaD4n6jbKE1EbpDgbDx2ibANXIEW5LWpDpRii4BjgwUARs0n6svqZBADuPuR5O9NQZWlN4+zxVkjQGOdgrlAoxDI5aoaOhwZQlNc37f2OhaSGkKN3u+RPFAcJ\/UShUBCKtrJDlK8BmBgNQQ4h5mVGMaSQhzRJXyKHeIykEQ5BbZBDKGSSsg31fAmR7CsUCnWHEDNFDkH+LK1pnOMzokn6EjlE2W9cgczUmKTukI738OoiNdeiorImH0gM71GWrvM1nn1X5vP5H330UXBwMBHQ9cc2XO6jcm1tbUZGxsWLF0GJLVu29PW4POELIuMzMDCwpVNQ+ZnoxcNK4YrpI5Vj+t2HPDcH8+HUoSjcoH5u5tcGeDBMjAyRvHviI18KmbTzzIO7D3lu9maoDeqkHXvK68UcnljlemAFVyIUvxznYH4zvxYJIGKZvIDNnzyWLpa9AgAKeYiBgQGRLKOM1XgoydHS5OL2qSpKSCd9opwCA4Adw4S4WKrsENSekFyQQ1A\/yCEUMkmjQ6C17t+WPRVcibpDyuvFyg4xMDAgHCJ58T\/kEACQvPgf4RAziqG6Q3p93csJ2JB44G0su2hGIpEcPHhQJaBjBjzOzs43b95ksVgsFmv16tWrV6\/esmWLFsblCqRECswwJ3N44vJ6MQDEX3n01kQbN3szF2vTm\/m1AFBcKfwxp3rzojEUMolqTLr7kAcAd1j11c8kSBmY5mGZuGUS6mr\/Ks\/Q2a81Q0LNUIZhbvSwUsgTysQy+ZHLxSi3dbE2zWBxxTI5qhxrb0YhDxFJ5ChiHrxYxHrKZ5iTiyoE13OrCVPH2pu52ZuhQIniGkqEiyuFM7f\/2vnlgIPEIb2ap+enZE3ecADH87apqakpKCi4fv36rl27UA2TyfTz89OtVZiBCpECAwDdjLxvleeK2MyGxhcrpo9EMSh0tjNaiWFhOvR85BSU6+1YMm7Dl3l7v2M5jzC9uH2qylI5FZTVDGXc7M3emmjjt+lnC9Ohq+c41zRIKWTSNA\/L0ppG9\/XXAWDF9JH7V3kCgLczbV50Oqrxd6PTzcilNY07lrhv+PIeu7YRNUMZ6\/p5rhQyKWKxG5oFshllx9ghhEMMmpqaNFqWk5MTGBjYeWcBQE1aVNQPSsvS\/T5ODPftUg+I6Ojobdu2aVyepdCzM6D1oV4fbOgv9fpgQ3+p1wcb+ku9PthA0Jt5uvXbBxLf7p2uNE4A12us1wcb+ku9PtjQX+r1wYb+Uq8PNhDgvQEwGAxm4IBjOgaDwQwc9DSm68OaYlzGZVzG5X5X1tOY3uE6U1zGZVzGZVxWL+tpTMdgMBhMN+hg3Ut0dLR27MBgMBhMz+kgpu\/du1c7digTHR1NoVA6bofBYDCY1mDtBYPBYAYOOKZjMBjMwAHHdAwGgxk44JiOwWAwAwcc07VNSUlJQECAs7NzUFBQQ0ODrs3RAdnZ2c4tZGdn69ocrVJSUhIWFqbl5\/3YD0VcgRSVuQLp1C3XrZZcWHHoDnHe\/Nc3HlstuWC15MLt+6\/34Is8fc9qyQW3NT8UlvM7HIIrkB77oaj9BvN3\/dKZrhBimXz98SyV9oXl\/PXHswizu83AdkjvxvS8L8Ka6ckB0wMYiUSSlJTEZDLZbPayZcv27NkjkUh0bZRWaWhoSE5OzsvLY7PZycnJhw8fHjwfbCUlJaGhoXx+Z9\/GvULk6Xs5j5pPy+QKpItiftv\/wfi6i0sDvUbEnC0AgK9vPE6\/X1t2ZjHrq0VHLxeiqBF5+h4A1F1cennX9G2n7xERUCOoW4pRe4vo0ClLljTVIzrbokkqN6MYOo1odW51PV9iRjFsf6vbDhnwDunVmF4Dkw8kJiYmJh4Iqj7xRV5vdj1AMDY23rdvn6urKwCMHz9eKBRKpe29OAYeFhYW8fHxFhYWADB69GgAePz4sa6N0gbZ2dmhoaHbt2+n0WjaGVEsk684dCfpVoktnYLe9lcyK6a6W073sgYAVxsqhyeu4DZezazYscyTQiaZGJHMTYbW8yWF5fyicn5EsAe0BJ16vpQrkEaevodSwsjT94gEtrCcP23rjZJqoasNVd0GlNtO3XI95Y\/ycY40hrkRskolCyY65AqkKw7d4QqkrKcNQvHLtXGZVksuoHgKACXVolG2ZgBw+34N6kE5ucYOQQ7p1Zhu7etr3Vzwt66uqemg+SDnv\/\/9r5mZmZFRZz+oBx7Pnj1TKBTDhw\/XtSHaYNKkSRkZGehjTDvEnC2wpVP2f+CD3vZimTz9fu2bfrbKbYrK+eYmQ1Wyv8yiehRulCuf1jX+WVg3+7ObKw7d+bOw3tTYEAC4AumH8ZlH1k54Z6qjJa3VUauglNvu\/2D8idTiUbZmYpl8bVxmoNeIuotLf4t9Y+e3+YXlfK5AyuGJPUZaQMuhoyZGpJJq0e8Pancs82R9taionI+S5drnkinjLG\/fr\/no\/+7+FvtG3cWltnTK+d\/Y2CHKDukbPb0mLwv8ffGBR23Q0NAQFBS0bdu2ZcuWqRw6PHiQSCQnTpxYvnw5+taC6XVi10yIXTMBve0BoEkqFzS9IAJNSbXIlk6p5IqJpJVo8IQjRFEPlCQCv9H0W4fmjrQyfVrXeCVmht9oOgAwzI3+jJs3aSxDXRZQzm0njWXMGm\/jakPNfsgFgBUznAHA3ZE21d2qni8hwhYoiQlPOMIvP5ns7khjmBuNc6TV8yVcgfRhpYBKIZ2+8eRf77q7O9IA4E0\/2yeczp5dN0gc0ssxvSYtKiwsLOwEbDgwH4f0trCwsEhJScnLyzt8+PBgu0iIkEgk27dvt7GxCQ4O1rUtAxn0tifkAlAScFGcUo9WVAqJwxMTukE9X2JuMtTEiIQySgD4u5PFtK03lC\/WsZ42AICKqlvPlyjntlSKoSXNuKRaFOg1ArUUy+QcnhgAMovqfUcNR5Ul1aI3\/WyRoIESVaIZinQA8LSucee3+UhqWHrwd+wQFYf06nmkxFFHNdeiwqL8D+C43h5GRkYODg4VFRWTJk3StS1apaGhYfXq1cuWLcMBva9RzvgAwI5hQlwbLCrnh8x2fcJ5LfsihYFuZoTCDaq8kctBQQfJu19vmUIhkyJP38ssqkeJISipum1RVttYxW1SuR5YVtsoaHrhMdLiRi4HCSBimTzvybMp4yybpHIAQKYSyTLKWI2HkkZamV6JmaGihGCHEA7pG+3Fev6GdyDrHhbUVWloaAgLCyspKQEADodTXl4+fvx4XRulVSQSyZ49e3BA1w71fAmR8VnSjKq4TWW1jQBw5BJr4RQHd0faKFuzG7kcACgs51\/NrIgI9qCQSWYUw8yiegC4fb+GwxMjZWC6l\/X5z6ahrmLXTFj75usLA4SaoYwlzbionM8VSMUy+cHkByi3dbWhpt+vFcvkqHKcI83EiCQUv0QRM+ZswV9lDZY0I9bThrS7lYSp4xxp7o40FChRXEOJcGE5f+qWHzu\/HHCQOKQ38\/Sa\/DzwQSp6XsoP4H8AZ+mqWFhY7NixIzQ0lMPhAEBycvJgU5M5HE5eXl5qauq2bdtQTXJy8mD7pqI1iIwPABjmRofXTFi87\/ZzkSxktiuKQWvfHI1WYgyjki\/vmo5yvZj3vdfGZe78Nt\/VxuxKzIz21w4qqxnKuDvSFk5x8PjwyjAqed280dXPJRQyabqXdUm1yGnVZQAIme0au2YCAPiOGj4j8idUM9XdkmFuVFIt2r3S+8P4zJJqIWqGMtZPFrpRyKQdyzzRLJDNRHaMHYJsNmhqatJoWU5OTmBgYOedBQCQ\/0XYieYVjL4bEj\/26dqjCaKjo3WyHyQGg8H0d3pVT\/f5ODGxN\/vDYDAYTJfAewNgMBjMwAHHdAwGgxk44JiOwWAwAwcc0zEYDGbggGM6BoPBDBw6WPcSHR2tHTswGAwG03M6iOk6WSceHR0tFou1Py4Gg8H0d7D2gsFgMAMHPY3pCoUCl3EZl3EZl7ta1tOYbmBggMu4jMu4jMtdLetpTMdgMBhMN8AxXWfExcXFxcXp2godkJub69FCbm6urs3REmw2e86cOR4eHsuXL9fyMdNfXnvCE8pQmSeUzdz+m1NoalhcNnGSJ\/MW2yk01Sk09Q6rnnjUzjMPnEJTfT75qbiy44OEeELZl9eetN9g8YE\/OtMVQiyTbzqVr9K+uFK46VR+5w8gbYuB7ZA+iek1aVFhUdd6snu6sk40IOtzc3O\/+eabXulf53PpUj2fz7906dIff\/zBYrGYTGZcXFxDQ4PW7NHV3MVi8fnz50+ePMlisYKDgw8ePCiRSLRjz84zD+49eU4hDwEAnlC25PM\/d6\/wYCe+HeDBOHixCACYt9gZLG7hyXm5x+Yeu\/IIRY2dZx4AQBlzwfnIKbvOPCAioMaxULfG5CHt2MYVyACAYU7u5FzEsldUY5KjJUW5niuQUo1JKlvddtUnGh1Sxlyg0SHHrz4uqhBodEg7ryvCIe3Ypu6Q9uei7hAAqOdL1B3SFzE9L+WHnp6GoawTDbx6FNfmzZvXK\/3r5xzbqqfRaLGxsTQaDQBGjRoFAOiEEO3Yo6u5UyiUXbt2OTs7A4CXl5dIJJLJZH09rlgmXx2fc\/72U5vhxuhtn5bN8XejT\/OwNDAwcLE2rX4mqeQ1\/ZhTHbHYjUImUchDzE2GcgXS4krhw0rh5kVjoCXocAUynlC288wDsUxuYGCw88wDIoEtrhTOibrNrm10sTZVt2HnmQfOYWkzt\/92NatqrL0Z3YwslsnD4rKdQlOdw9KITogOeULZ6vgcnlBWVCEQSeQbvsxzCk1F8dTAwKC0pnmUO6x6lEeHxWVLXrzqpE\/Q0BodAgAaHWJGMeQJZRod8kz0AjkEAHad\/UujQ9RtQMn+rB231R3iFJqaUchVd0hYXPYz0Qt1hwAAu7ZJ3SG9H9Nr0lLgnSB8HEY7MJlMf39\/a+vB7qTnz58rFIrhw4fr2hCtcv\/+fSqVSiaTO27aMw5eLLIZbhy93AO97cUyeQaLO8dnhHKbh5VCM4qhSvZ39yEPhRvlyvL6pqxi7tsxd8LisrOKeeh4HZ5QtuHLewdCPBdMtlM\/TI7IbXev8Dh1o8TF2lQsk2\/4Mi\/Ag1HGXHB9b+Ce838VVwp5Qln1M8k4B3MA4ApkVIohhTyktKYxg1Ufsdgt99jch5VC9O2hrkE6eSz9Dqt+86n863sDy5gLbIYbX7xTgR2i7JDejuk1107c9Q+a0Mu9DiTYbHZjY+Mbb7yha0N0jEQiOXny5HvvvYey18EAn89fvnz5rl27goODjY2N+3q4\/as896\/yRG97ABDLXgnFL4lAU1rTaDPcuIonIZJWogGRDoOSZuLrOiwt5p+Olibl9U0Xt0\/1dR0GAHQz8q+fz\/AbPVxdFlDObSeMGjbd08rF2vTek+cAsGSaAwC42Zv5uzG4AikRtgCAUFdKaxrj1\/m42ZvRzchj7c24AilPKHvMEZkak769VfbJgtFu9mYAMMdnRGlNI3aIskN6N6bXXDuR5b+hF06W1vkazz4qI111xYoVKm9pfbBNy37YvXu3tbX1O++8ow\/2aKdMo9G+++67jIyMuLg4dHG4r8flCqSPOSIkF9TzpdAiHSgUChSnVKKVQqEwNSZVP5O4WJu26OBSM4qh8dC\/oYwSANwdzedE3UZ5ImqDFGfjoUOUbeAKpCi3RW2oFEMUHAM8GChiNklfVj+TAMDdhzxvZxqqLK1pnD3eCgka4xzMFQqFWCZHzdDx0ACK8vqmvd+xkNQQcvQuKNGhT1AcJPQThUJBKNrKDlG+BmBiNAQ5hJiXGcWQQh7SJH2JHOIxkkY4BLVBDqGQSco21PMlRLKvUCjUHULMFDkE+bO0pnGOz4gm6UvkEGW\/cQUyU2OSukN685yjvISo8ncTP7YG6PHh0jpf49lH5dra2oyMjIsXL4ISW7Zs0QfbtFbm8\/kfffRRcHDwO++8ow\/2aLlsZGRkZ2dXVVXl5+fX12PxhC+IjM\/AwMCWTkHlZ6IXDyuFK6aPVI7pdx\/y3BzMh1OHonCD+rmZXxvgwTAxMkTy7omPfClk0s4zD+4+5LnZm6E2qJN27CmvF3N4YpXrgRVciVD8cpyD+c38WiSAiGXyAjZ\/8li6WPYKACjkIQYGBkSyjDJW46EkR0uTi9unqighnfSJcgoMAHYME+JiqbJDUHtCckEOQf0gh1DIJI0Ogda6f1v2VHAl6g4prxcrO8TAwIBwiOTF\/5BDAEDy4n+EQ8wohuoO6b08veZaSi7knQgLCwsLi0qpqUmJCvsir9d6HyA4OzvfvHmTxWKxWKzVq1evXr16y5YtujZKq0gkkoMHDxIBfZDA5\/PDw8PZbDYA1NTUVFZWenl5aWFcrkBKpMAMczKHJy6vFwNA\/JVHb020cbM3c7E2vZlfCwDFlcIfc6o3LxpDIZOoxqS7D3kAcIdVX\/1MgpSBaR6WiVsmoa72r\/IMnf1aMSPUDGUY5kYPK4U8oUwskx+5XIxyWxdr0wwWVyyTo8qx9mYU8hCRRI4i5sGLRaynfIY5uahCcD23mjB1rL2Zm70ZCpQorqFEuLhSOHP7r51fDjhIHNJ7ebr1\/AOJ85vLNdeiTsCGA70gwmAGGDU1NQUFBdevX9+1axeqYTKZfn5+urWqr6HRaBEREevXr6+urgYAJpOpnasIRAoMAHQz8r5VnitiMxsaX6yYPhLFoNDZzmglhoXp0PORU1Cut2PJuA1f5u39juU8wvTi9qkqS+VUUFYzlHGzN3troo3fpp8tTIeunuNc0yClkEnTPCxLaxrd118HgBXTR+5f5QkA3s60edHpqMbfjU43I5fWNO5Y4r7hy3vs2kbUDGWs6+e5UsikiMVuaBbIZpQdY4cQDjFoamrSaFlOTk5gYGDnndWKnsX06Ojobdu2aVyepVAocL1KvT7Y0F\/q9cGG\/lKvDzb0l3p9sIGgN\/X011jPP3CgRx1onACu11ivDzb0l3p9iOBI1QAAB45JREFUsKG\/1OuDDf2lXh9sIMB7A2AwGMzAAcd0DAaDGTjoaUzXnzXFuIzLuIzL\/aispzG9w3WmuIzLuIzLuKxe1tOYjsFgMJhu0MG6l+joaO3YgcFgMJie00FM37t3r3bsUCY6OppCoXTcDoPBYDCtwdoLBoPBDBxwTMdgMJiBA47pGAwGM3DAMR2DwWAGDjima5uSkpKAgABnZ2dnZ+egoKC2TlgewGRnZzu3kJ2drWtztIQOn\/djPxRxBVJU5gqkU7dct1pyYcWhO8R581\/feGy15ILVkgu3778++iDy9D2rJRfc1vxQWM7vcAiuQHrsh6L2G8zf9UtnukKIZfL1x7NU2heW89cfzyLM7jYD2yG9HNPzEsJaiLrW45MxBiTPnj3z9fUtLCxks9kpKSkWFha6tkirNDQ0JCcn5+Xlsdns5OTkw4cPD5JPNV0975Gn7+U8aj4tkyuQLor5bf8H4+suLg30GhFztgAAvr7xOP1+bdmZxayvFh29XIiiRuTpewBQd3Hp5V3Tt52+R0RAjaBuKUbtLaJDpyxZ0lSP6GyLJqncjGLoNKLVudX1fIkZxbD9rW47ZMA7pJfPrqupsg46kJiYmJiYiHdP10xFRYWNjY0WjqPUTywsLOLj41FEGz16NAA8fvxY10ZpA+0\/72KZfMWhO0m3SmzpFPS2v5JZMdXdcrqXNQC42lA5PHEFt\/FqZsWOZZ4UMsnEiGRuMrSeLyks5xeV8yOCPaAl6NTzpVyBNPL0PZQSRp6+RySwheX8aVtvlFQLXW2o6jag3Hbqluspf5SPc6QxzI2QVSpZMNEhVyBdcegOVyBlPW0Qil+ujcu0WnIBxVMAKKkWjbI1A4Db92tQD8rJNXYIckivay821jiUt0tZWdnJkycHm\/KgkWfPnikUiuHDh+vaEG2g\/ec95myBLZ2y\/wMf9LYXy+Tp92vf9LNVblNUzjc3GaqS\/WUW1aNwo1z5tK7xz8K62Z\/dXHHozp+F9abGhgDAFUg\/jM88snbCO1MdLWmqH1dEbrv\/g\/EnUotH2ZqJZfK1cZmBXiPqLi79LfaNnd\/mF5bzuQIphyf2GGkBLYeOmhiRSqpFvz+o3bHMk\/XVoqJyPkqWa59LpoyzvH2\/5qP\/u\/tb7Bt1F5fa0innf2Njhyg7pHdjenV5Td4XSHlJw8qLBiQSSXV19eHDh5Hy8Omnn5aUlOjaKN0gkUhOnDixfPlyV1dXXdvS5+jkeY9dMyF2zQT0tgeAJqlc0PSCCDQl1SJbOqWSKyaSVqLBE44QRT1Qkgj8RtNvHZo70sr0aV3jlZgZfqPpAMAwN\/ozbt6ksQx1WUA5t500ljFrvI2rDTX7IRcAVsxwBgB3R9pUd6t6voQIW6AkJjzhCL\/8ZLK7I41hbjTOkVbPl3AF0oeVAiqFdPrGk3+96+7uSAOAN\/1sn3A6e3bdIHFI756J4ftxYiIAAOR9ERb1hW3ixz692n3\/x9jYOD4+HpU9PT19fX3\/+9\/\/DoagpoJEItm+fbuNjU1wcLCubdEGunre0duekAtAScBFcUo9WlEpJA5PTGSv9XyJuclQEyMSyigB4O9OFtO23ri8azoKIgDAetoAACqqbj1fopzbUimGljTjzKL6QK8RqKVYJufwxACQWVTvO2o4qiypFr3pZ4sEDZSoEs1QpAOAp3WNO7\/N3\/ltPuo5ZHYX3DgYHNI35xyBb9A71ic4NeCDhZgOcHBw0LUJ2qahoWH16tXLli0bJAFdI9p53pUzPgCwY5gQ1waLyvkhs12fcF7LvkhhoJsZoXCDKm\/kclDQQfLu11umUMikyNP3MovqiRBGqLptUVbbWMVtUrkeWFbbKGh64THS4kYuB0VMsUye9+TZlHGWTVI5ACBTiWQZZazGQ0kjrUyvxMxQUUKwQwiH4LWMWqWhoSEsLAx9737w4EFFRQW6Tjh4kEgke\/bsGWwBXVfPez1fQmR8ljSjKm5TWW0jABy5xFo4xcHdkTbK1uxGLgcACsv5VzMrIoI9KGSSGcUws6geAG7fr+HwxEgZmO5lff6zaair2DUT1r752n5CzVDGkmZcVM7nCqRimfxg8gOU27raUNPv14plclQ5zpFmYkQSil+iiBlztuCvsgZLmhHraUPa3UrC1HGONHdHGgqUKK6hRLiwnD91y4+dXw44SBzSR3l6XsoP4H8AJ+mqWFhY7NixIzQ0lMPh2NraMpnMwbaWkcPh5OXlpaambtu2DdUkJydPmjRJt1b1Nbp63omMDwAY5kaH10xYvO\/2c5EsZLYrikFr3xyNVmIMo5Iv75qOcr2Y973XxmXu\/Dbf1cbsSsyM9tcOKqsZyrg70hZOcfD48MowKnndvNHVzyUUMmm6l3VJtchp1WUACJntGrtmAgD4jho+I\/InVDPV3ZJhblRSLdq90vvD+MySaiFqhjLWTxa6UcikHcs80SyQzUR2jB2CbDZoamrSaFlOTk5gYGDnnQUAUHMtKioFXRv13dB9MT06Olon+0FiMBhMf6dX83Tr+QcS5\/dmhxgMBoPpClhPx2AwmIEDjukYDAYzcMAxHYPBYAYOOKZjMBjMwOH\/A62YKfzbsA6eAAAAAElFTkSuQmCC","width":497}
%---

```

---

## b.常用函数\1.拓补信息提取函数\Node_model.m

```matlab
%[text] # 初始化节点资源
%[text]  ![](text:image:03be)
function nodes = Node_model(bone_topo,minm,maxm,minc,maxc)

% 获取节点数
node_num = size(bone_topo, 1);

nodes = struct('id',         cell(node_num,1), ...
               'src',        cell(node_num,1), ...
               'dest',       cell(node_num,1), ...
               'mem',        cell(node_num,1), ...
               'cpu',        cell(node_num,1), ...
               'delay',      cell(node_num,1), ...
               'vnf',        cell(node_num,1), ...
               'mem_cap',    cell(node_num,1), ...   % ➕ 总内存容量
               'cpu_cap',    cell(node_num,1), ...   % ➕ 总 CPU 容量
               'base_delay', cell(node_num,1), ...   % ➕ 基础处理时延
               'tasks',      cell(node_num,1));      % ➕ 调度队列

for n = 1:node_num
    nodes(n).id  = n;
    nodes(n).src = n;
    nodes(n).dest = 0;

    % ==== 内存、CPU容量生成（30～50 或 50～100）====
    mem_cap = randi([minm, maxm]);
    cpu_cap = randi([minc, maxc]);

    nodes(n).mem_cap = mem_cap;
    nodes(n).cpu_cap = cpu_cap;

    % 当前可用资源（初始等于容量，后面部署时再减少）
    nodes(n).mem = mem_cap * ones(1500,1);
    nodes(n).cpu = cpu_cap * ones(1500,1);

    % ==== 初始处理时延 ====
    nodes(n).base_delay = 2;                         % 基础处理时延
    nodes(n).delay      = nodes(n).base_delay * ones(1500,1);

    % ==== VNF 共享状态 ====
    A    = zeros(100, 5);           % 100×5：请求id × VNF槽位
    data = repmat(A, 1, 1, 1500);   % 生成 1500×100×5
    data = permute(data, [3 1 2]);  % 调整为 (time, req_id, slot)
    nodes(n).vnf = data;

    % ==== ➕ 初始化调度队列 ====
    % 一个节点上等待处理的所有 VNF（不按时间片分），由调度算法管理
    nodes(n).tasks = [];    % struct 数组，后面 deploy_vnf 会往里 push
end
end


%[appendix]{"version":"1.0"}
%---
%[text:image:03be]
%   data: {"align":"baseline","height":116,"src":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAABC0AAAB0CAIAAAAuIF9wAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAgAElEQVR4nOydd6BkRZX\/v+dU3dDhvTeRJMlEGAFz+ImIiglXcgYBF0HERRmCoGQGRDI6YAbJKgaCuKLLijmuuuuiriQDOc+89zrcUHXO74\/b3a\/fBJgBZAaszx8z\/W7fUF3dt+751jmnDp100klYClYQRElKZlWNHXep9oCZ1U5GQEZoardnBdRvZ11aM4oHa26CmIyxAKv231Me7D\/8uQiyxPbq4ytNvWaZOnbadXv\/y9A2GRw7OOuKt3+pYwOBQCAQCAQCgWclJCLL2KqoLGbPAGA83\/Sz3+3zsbPKxmxh++zSIcNGfMO3Pn3cQdu9+TUGxqmzZFdduwKBQCAQCAQCgX9elm2IK4GUAekpDUPdUqL6LG3Oncydp94U\/rCJ\/8Sz+quOQTtj1aQxYmAEYsl6LNvRMN0fMrxPbxOW9Ics20nR3zos14I\/JBAIBAKBQCAQgCValmGrAAlARIAyRNPERL7dXvRALU11yHSeJkVWM\/dITyQMtSrWTtFpZ1knSRIhMcMaYLgbpnXJ42kMU\/3xBFJi+AxmuWdcsRMEGRIIBAKBQCAQeA6wnMAkEkgBYmgMAohiN3HbzZc7wE+f3h82i1c3l8gg4Iz7fxrgFz\/6cRon4j2Ywbz0zljig+hSr2no36V5fDFGsvQVnpjl9XggEAgEAoFAIPDsZHkJEgIS6JTVy3Cx15hpmh28hM29mvlD+oJhWgJMpK735urW2kAgEAgEAoFA4J+G5ekQBhjEAw9AydYx0ZAMYaz2c\/O95vH0bQZkiGjZAWnLPQmGVdkzzWrez4FAIBAIBAKBwEryOAtGTXvLq3qAANO3imUo3qmCl1qndkoB9I34Zbw1vM8AGvpzZazwZSz+tcQOT9qmp9XP4RMIBAKBQCAQCDw7Wb4\/ZGCvEwAYhdHeNgUqR4kQYcg4FwBwABS2UikCMATa86sIFR5QxABYhAEeytAoPSILUYD6yeUK4erE0nPRLKOhKL1GhrwCQ8tJeUVM6CrqhGxo5+kM1QYBD\/5ebq7IUIdMyxVZ+t3lwlPHLo+hMzypbJJAIBAIBAKBQGB1Z5oOueqqqwav99lnH2DKJiZREk9MWnk9FOgrjSUMbwUEUKDyn\/BgK6ZcIpUCYa+Af\/CB+\/\/+UGvzLTaxw5b9Upb6Mk13AgSIDAEggipIe1LEEBSoE9yQHc\/BoxEIBAKBQCAQCKwGTNMhPe2xLIiIWIlAqlXBDBbqOS6qRX6VwYIhl0KlN8zwolSIK6cGKZgAQ8jHb7vld1+4+Q9nb3HsWhGk47luhp0UgDAEYAEvnaBRndk7b4zpRYWpQoF+Iot33loDoF83XQwpSIkUvETKx7K9INMCyVZRnsYT+GcCgUAgEAgEAoFnG0\/kD1kKUigJ1AjBKKAOvuivgctQywTX35kHcVkDvwr60qUAAMRclHnJtQwoFHHkocrE\/UMcVydTC2IsJ2eEgH+\/4YYXb\/TijTZ6cW+T4rZbb7399tu33XZbwED8U1cQEjRAIBAIBAKBQCDwNDFNh+y9996PuzOTKqi3apYqxHumEr6DPJd6TanRfTRziNI5iQIWLoYDfGt8Muf66NgoKSwBPgdDnGcp0R0vHdimCngCfAeSZhOFS0ZrozCwLp+06kSpg8SbWj22EVBWrQE8YAC1\/PwXvfCsc8454oj5m2yySVEUt99++wUXXjD\/sPlsLabXIJclFMxTZOk4r7C2VSAQCAQCgUAg8ERM0yGXXHLJ4PUBBxywnEN6\/g0isDVwAumeecrJG7\/l7V\/52nX+ofE\/\/umO0y+6fJttXseuWLzo4UM\/dNjDjy32xDNnr7Hwk19Ye41RgP7yh98ffPjRkUHcebC+1vPb628FQMT\/7W9\/nf+hj1hOF3fLbbd\/12FH\/puJaldfeukll1z+4le86r\/\/8MfTTz\/9ta9+jeVp0VQGNG\/evCOOOOLMsz4x\/7D5ABZ++sIjjzxy3qabASoQXaqweiAQCAQCgUAgEFiFTNMhy9ce6BXcIEA9AAUDUO9IBeoM6Ib\/\/M0FX7x8Db3332+48bJrrtl6m9eNonbkUce\/4e27HXzAPoRFX\/3iRcd+9LiLvniBn8g+dtypH\/jISe\/YZsumefCbX\/n6dbchBlqT\/uiPnbLg05\/aYqNNUEwef8Tht97xp5lz1v\/iZd+99hs\/GVnTZFknjmNST2BoP0iqL0nmbbLp4R86\/JPnfTJN0yPnH7nZppsBKJyzNmKdkiAs3MufV1qixGEgEAgEAoFAIBB4ZpiW8nDZEI9\/WJWGTsZCSrAr8vZ22+8a2wjGbbzx8x9+rJV73HXnPf\/zv3\/ccZc9CgAo9tzp3Xff\/pe7\/j75u1tumSyKN2z9pjiK4PM111kjdx0L3PnnW9eYM3eTjV7S9V1I\/prXvOKnP\/2piZI5a6174\/e+h0LSNAFbNRbKvSao7zVIASYislGU57ml3ueyNsqL\/GnvtUAgEAgEAoFAIPBUmOYP2X\/\/\/VfgkF7Sec\/FQAwpY5aIJAaAEdAo2bGC8VjuXrzZZo26dc7FStSYM5rUpN26b9HDczdcZ3YNBEBNq\/RitAV0Fj\/43z\/\/yS7bbSuEZmzE+x1233PNZu2iS867+DOfecv\/O\/pt2+980HELahYJYFWhUiWvZ51uFNk\/\/uGPn\/70p+fPn6+Ec84\/79BDD33pS1+qXhIbDZdO91XlEygBVDlVaPizrTBPJQ9khY8NmfGBQCAQCAQCgeckT9LQnYpzMhYCIXBVWERjaEwmFkJ9rP7Xv\/81G1\/csJaikfF2d1He0YTmzp3bnpjMcnjnEY+aKCEiA8yZPbbpRi+45mtXX3vtdVd\/49tfvfbb79lrf6euVjeHHTX\/5l\/9LOtmF116fWsq17zX+DiO77j9joUXXHDY\/PmbbbH55ptvPn\/+\/M9\/\/vO33nqrsaYoiqfWRYFAIBAIBAKBQOBpZuV1SE8DDDIrLGxSUgpJq4LkrKK+EI81545s9f9e\/s2rvwwAiL7y9W+s9+p5a2601hYv3ji\/f\/HPf\/rL2Brkre\/c8O0kihvApptsUnr3i1\/8IjaJQBYteqzweafdvvPOOwGgkBe9aKO8Na5ltfIvDyoeepXb7rzj\/R84eNOXzKvaNG\/evEMPPfSWW25R1chGj\/dZwvJWgUAgEAgEAoHAM4594l2mUWmNIeudLLjmKDbqDABiIaZ8gnPMqNcPm3\/4SSed8c5t3hZpd52NX3zsmecTMDZnzvEf\/djhJxx3ztnJGo3szdtt9+v7PAEmjhZ+9rOHHHnMR44\/cWxszFpz2aWXtdrtY445urVo0Uhio3TsjM99pRkN6g8yAO99FEXbbbcdABHp1yvEpptu+qIXvYiInHfGmqelswKBQCAQCAQCgcDTAok88ZpRRPTjH\/94q622qhItBPBwABswKyATYAbVAQY6gC0RqyBSQCGAaBmpU6Ab1ZiQVgkaxAIAzgMFLIAUnsWLwisRBAATMRulqoShALYgALBDfhwR4X7F9kqEDGeDLM0Pf\/jDN73pTU+qrwKBQCAQCAQCgcDTg318q31Au90eiBDtywAFhECmRvDoVVFngCPpuywYRDCIoIaAeiUvCAAEomAPCyCGMAAYYUOAhTCmPBhTCfEKu1TlwIEIWUF6n2JIvQSeCqqhLEsgEAgEAoFAYKWxlTfk8U1yEWk0GoUriawxA90iAHtAERlEpuflcL3UEQLI9aOnGOB+MFV1JOtQfBdPu\/4y\/DPS34d1IGN6rKyYYGZVrf5dQQ22Sqms\/CfXzoFCoOlbHv9sK37FJ\/Y+BQKBQCAQCAQCy8T+4Ac\/YQVhoB8EvTKFLFRV\/QMbrL\/++updnEQlAIDBvdApwFdFzRU9vUH985AAwlUKihIAVSj1\/wUUMKAlbOQ+PPSqHzrW88fgSS\/zBeB5z3veL3\/5yyzLjDFDMWn9wogkS2mcx4tbE+qVaWcdrOK1EixR4l1o6iRWmBRKAhLpLRHGSx8yfLLBaZZqNvffddP\/HHxYC+UpDdk\/SqorQlgBEhnaMriEatAhgUAgEAgEAoGVhlS1PdFNDRF7rwVYo4gffmyiPjJbYFmZFYAQHMN5YklH2l0fSbuRxOREYKvYqog8UGkPSM+anjJqDVsAygSSyuIXKAAvspRhLQBDYyiTAiTKBSBClRUuAISGVMrQ4cMxQisXL6QWGgMAFSA3tbFqzz+m7DrpVOOrDlOC9LQNG2FWCDvAK4kQhJilF662pA5TnqZDqJyupgzUDm2PhkRXCTA0Aiod4kl7BypFJcWkiMQxykqHlJQAbFGQ+kqAEK3sUgeBQCAQCAQCgQBsezyP47ib52xIbZ2YJ7rdaHTtkiLpW\/mkACUMeEJRQmAM19UVJJ60BCUAe+iQvV5F7Awm3dlLNXeOfoJJj2oPmtogvel15d5e2jOvWUWIn4TP4Umiwx6SZx6ZrjUYANQM3C8rRF\/yrRRKU18HDV9LGVS1Y7hDwkJkgUAgEAgEAoEng42Z87xErd4BKEKusM2oA6AKwCJ4AIAKFFAP9qgzCFakABxIiERhh5cAHs4ZUFrCFH4cy7hv4GoV3FWllAgpV\/qEte9oWTLo6KkjoAJA5QypkumnLP5eezDI1AdA1dpcCgCeptpRbVnBYKVlyiqGBwHkhQwAaNTf3m\/q0tFpJP20juqd6sDpH3Bw+iWuNrVH9dowgdSTeksFAGV4mEoYGc1ZIWSUTHXSIEQCgUAgEAgEAk8CaxmZmlzxpa9+uzmSXn7llRRFZSkxMSmIqG9Ss5JhZfVu9+3fsef2b587VnOlB4SIAaYVzqVW1em5GQOmZ6tPkxxPnKrxlJiWFgIiUsVUgNayXCJexVAVtAZPvUQRWplYsOoMgz91IGbUAF4JpB4wShCVqVR+WnYvEJHCo5KNvTirsrficfU9qgKmt8M0DAChSuP1wvAYAmVPEDD3JOkyFEdYcSwQCAQCgUAg8OSwpZRs6qXi+uuv\/+bVJ+2x\/REslpSjyHZb2YyR0aIoIKrqidVzo0trfftb30tr7H0BZaCXWSFagsSanrVaFEWtXmdriqIoiqLZbHa7XWutMSbPc8OmKIokSfI8Z+Yhc5ydc81mmrVzkYLZGMMAeU9KIJ6K0cJynAlxFE+2Jmu12nBNwxVh4McgIgWIfSXD8jyv15tZlnnvkyQBwH3JUpZlvdZU8bk6MmyUxHlV6eZ5s9ksy9KYKdvdOUdEzWbTO1+UhfceQOkdM09bQViE2bCtdTtdVW00I+cK9U4FaVrvdrpsmJllqNlKHjAKX6+nne44c2Q4abe6aZoQq6oSAfCxTSYmWmmasoH33hAzmdJzkiS5z4ss80qNer3Iu\/XUFq1urT7aKjitp6aAL7vGwCuRib0qQ8IyWYFAIBAIBAKBpwIrQQgloOAIE3V9qKEPpHhEZDxqoFu2y7ydRt7KolTuHUnGY1NcfsUVbEhUVUWFVEiVavXUGhOlCRv2IkVZ5HmuXoqiUNWiKJxzItJut40xzrtKJ0RRZK3VCiEVBXhyohvFzIacy0W998iygogeP9tBVb333aybpmlZlk9mWV5lKHslT67wXY5LtkWSRmWZxXE8LCoAwBhjTNntnnHGGb\/89a\/IMAADAjA6Orr0uZMkMcb86le\/WnjBwrIsa2lNoCaKwCxTsV4AEHFUdIpafYSipkDVeENlkhLgnC+NscxMRKoy5FPyzrks73gpnC9OOfnj997zoAiqXiUikHSyVhRHxkRlWRpDv\/71L0497VRRtFotQNLUxrEx5GPOjBa50vd+9LODDjn0pz\/6Zaed3\/Lb3\/\/2Zz\/6\/W9\/\/ee\/3J1x6tkA1Re\/SpJnAoFAIBAIBALPeiwpK+AJjmKW2GgcCTomfcCPfeKTl9xxy12UlSabOHC\/d2+\/7Uttrl1H1tQsJ4nVIiuBkqCk3O16a8z\/\/eGPd91997rrrrvJJhtPTrbEextHqvrzn\/9UVefN22xsbMz70nkXRbbbbUdR4r03REQM+EoJGOaJifEoMsYaa03WkU67G6cJkapUifPL+CREFEWRqjrn4jiuHA79eKQlWTK\/opeVXmWkOCKkNdvNH2PliGcak3rv0zQVV6LnM4F4iZj\/+9e\/ueV\/\/vfd++5+9\/13z7ZNLcq4UVs8MWGMsdY2anX0A66cc3fddde5554rItu8eesNNthQjPEojYmB3qJhqqIOgvLRhxdf\/+\/f2XPfXdNarG6STde7bmtSf\/TDn2222RZz11yL0pjZGJ1KArHWlmXOMS781AXfuv7GN73hrc9\/wfOIyIm3UVS6cnJy8oZrvzc50faU50W3nsTfvfG7XqKZM8cyN9FopLX6zL332GnELLr44quuvvlP79phn9NPPf35a61x79\/u\/ebXr9t1u63+6ze3TIw+ut8mL7KOIxWGACy6dApQIBAIBAKBQCDwBFhP8AzPUIIRjnq1REDJjN\/88Z5vXHVF7BF71Gkywh1O1CRp5vDoosm5M2KlqrKEA3jR4vGPfvSjo2PNF274grNO\/\/jee+2zz\/7vA9MD99714cM+tPvuuwv01I+fsfDCCzdY73nW2DzvLlhw2vzDjpozZw2PguBYGYojjjj6uBOPW2POaBJRlmXnnnXOtd+4ocjdf\/zs+3EtZuX+WlJV9RIhOIAVFkCed5v1VLr5Pnu\/55iTF2w8b1OrBZF4NVU1DK4yH\/qQMADPLCxWhFRADDAjYvWRFJdfejnZdfbd9xBw1O5mtWjqugZFa7J74ee\/kHk9+bgTW52OcSAnccKdLKuPzP3SJV8SKdkQqVXwNdde963v3HDyySfPGG2eePyxr9tyy5133yNNGqVXUgaVUNRrzc7E4n\/dd+\/f\/f52W99kx112TRJnI1bVyy+79NwzzlFNz\/\/8lXPWf5Gx8GXOmAppY2ZRuuSSy2679bbrrr\/m+I+e2Mp23PZd7xAVsBX1Rdb54Q9\/+L4DDmLriGAMXvWq17Kp5UUep\/TAww\/d8O3v77PLDpo9WnYeft8HDt56m7fZTum9Y7Yzxma85jUve6g1\/r\/j7A3URdCCqooxQYQEAoFAIBAIBFYeWxqpdAjBpexJC3BhbWOU6pTJL3\/6ewOOrK\/Tw+96zSyXl56ltFQfaZRlxxoISRXcldSTDx\/+4XnzNilbk3v+yzv\/7dAj3vKOndZab80f\/OBH79jmzbvvsH08Nmabs7713e9\/8MD9jbo0ifbaY48jjzjuE+ecNXftkTxro11+9CPHfXD+R+bMnsNcdIoOGO874L27vm3HQz50WOmEiKwKKym0WgRYUVqfEdmJnLPSNUeMy8fjPCseW2yTmRJFndbDtcSQGYFJxyc6tchGZRYZKtSnUVpD5AWLVE3dGDeRGPvwI23nTTrSbCg1xI+yXVTYzJsoRprUNSsMRKrVh8vFnzj15Ff+vy0\/+G+HdFttGFUT+7KYmfg7\/3rX+Z+\/Vk3Nadv68r9\/e+vCT1+8\/sabHH\/K6eeffdrO2\/\/L+ed\/8oorrth7jz3fd9D7t37LNrVavcjLWpy4omDyl1\/1qfsezPZ6z5neQbxlrrPKQfsfeNDuOx19\/IKWmLKeoHAEybKiUaszmzStdbvZwk995r77\/\/aJT5ydRGNnnvvxD3344Hvuv2evfd\/rsk7DWnJuxujYq1\/5ym57sY3JiS+8qzdHJsZbM2bNed6i9o03\/kodcZTavPupT5y08DOfjVF+9tyF9\/79gShNECtiROw1Rz2BdhouzxSeYtJ+ukpIGgkEAoFAIBAIrCC2ik4igOHi2KKlBcViZra6NubmL3\/xk2Yj6rYnN163Ia94hSEWJmUCM\/dqqQMAKeI4ev7z1yf1zXqtPmdOt5sVTlyOkYQXPbDYxKbVyRojs1UeJDKi3pX5y162xSmnHX\/8sceccfbH0zg58siPHHnkRzad9xITUZ4XqsKGE2MbJjYCIXbEBmAV6i0HLADElZ84\/fT\/+r+756wx98EH7zzqkEPOOOq4xW3ZbqddkdKPbvjcD3\/7q1vv6d7z4OSvf\/HLT55z5qL77\/rB9\/\/zhJNPYofH7r1vz333+9y\/f3O0NkJE55xzzte+\/q25a29w3wMPLjz75B98Y+G11924KNr09IVXn3P2x9\/6xteO1QBAiQk477wz11lnrR\/f\/PPvXP+TxHZNDY\/m2UeP+vC7tny5hV\/ULrqKETafOu+MR+5vnXTssWtttLFTd\/ppp95047cfeuiB\/f\/1vdvvuvvlV375xpuOO23BKWOj9Vpak25uyBMKRkGQqiILKSvVoR5aGC1KtgUBQMpcHxlhiLL+4Ac3n3DCKTvvvOMpC06ZmJhYcNY5J514ymWXXXbGGafvvP2\/HHfcsa94+aZz1173uBNOeOSRR8888+SHHro\/qdVUsGhi8p57H9pxp90OP+ojpy44NUkLlOVoPT7ysENfuvW2RT5hhC654qJj5x8GbtTqozd9+Yb77n\/0wL12X3vG2Fgt9b70y1iAKxAIBAKBQCAQeAJsUqYQRBEYLs89udHrvvubz13xmXZz40xGjj78UMkeSWw6Yrpl+w6NUh9BRLz3XjzHRGoAAihiHhmb6duZqtxyx52NNeeOzRipRdjhnVt\/8ENXLjjvjD32O+Rb37rphI8dZ4RqqekCjt26G6bHn\/CBj33wKEXt8OM+tvFLN1VFluW1Wmq4lmXduBa5JCcmIhpaqqoHKf\/19rv\/cuc9X\/7qN2xq0e7UDb\/++lfuuu\/7Lr7y+plrNufiL7+XcuEXLj134UWnHH+cuu737787M3EcjySeGEnDUJktNrb+jSu\/81+\/+tP3vnfTjDkzH5lYXDfdN73uDIpGxubtsuueu62ZwLhCqlqKYGU+6sQT8gn\/vz\/++Bc+87mRdTi3rf\/8xU1sW8gnrMrYGmv4FGU7OfqI48pOd6dd9rj9vvvBFKEk8V6poGivfz34qKOPdlm3ERv1bvFji0ZrdQCDvBUGLIThPKwgZmXWaev8FkURW3Pjjd+58sovn3HWOa999cuNHX\/koQljG1EyEkf56QtO\/M2Pf37qGWd+7BOnbzpvi7GZtfra8RcuvajdGjcaLVrUuvDTX9xllxfu9973eMAknVb3kSTRTlHWRWePzsx98uBdd73\/wPe+ZPMtXKe15eu3u3qbXcGoA3nH5b5Vq6UuD6nqgUAgEAgEAoGVxgogBCUIQERxrbHLDnu+bcd\/a9Wx3S7HXPy5C6h8OCbeYM2xfXfbZqJdinjxXkTEoxIGvRoaoj7rGsaihxeffPZ5H\/jQ\/NHRJkvZanU23PCFLe\/223\/\/rV+7LXshYwv1HBtQUavxmrNHmvX0wUe6s+c8b3zC1WusIoaTydaiyFoTJTaJASxRrIK0ylbnenPGI48s\/snNP3zN67dKbASy3VZRdIrFixevs\/5oauJaEr\/x7du98g2vioBuu12qtErvhEkhuYuFGjEtfuzR7974n\/vtd8DY2NhkazytWc1L5J3JdqtJVoBuKxurQUSF2RMp1BgDFt\/JG8StTjuabT3gC0EctSbGs6IrBIrqJk2Mdzf+8D86rawU37Bqm83f\/Oo3n7v4yiOOPDrL\/UiaZp3JJIqZLSDKrlewhRwIgKhq9UmhPedV9X1BoarWmh133HGbt76tdMa5rCgea9aTLPetFuKZRKBXv27L677+2glIElnnym6RG6hNa\/ffdd9HDj\/m1I+fuea6G8QpxtuuMVKParNRLDJRcs55Cz9z5bdjLo467NCLL7jwlGOOnjV7ro+T\/7vvgS9cfNFLnr9hQirAY+OLamnjGfy5BgKBQCAQCASeI9hu7ApjS4YQi8sh44Z8jNzKOprf\/\/KXvBFupNlIyLUgrUZjdKJaxMoYQ0bFA6qqUI2Z2RUoul+56ooNNnn5pq9+Qzfv5N3Opy64bJu377DZlq86ar659LNf\/txnzjzhtOPEaOnLGDJx3\/hJx56y+\/7vXWu9jU877dTjjz9p5kgzSmtZ1jEmgrFl4YqiAODKIrX12ERWxJcFAFYoMHeddS666KLPfPqi0085bbeDDnjvnruntXRGvVazsTiVMlNijeomBnK\/xqxmHAmRGgMYMEfOlUkaqdVFjz78\/PU3YGJiUkIcWaiZMWOGcy6KMJKmMIpuVvWaEBZPPLpGfVaRPfSmN726O8c9mI17H3\/uvDPh4rvvvvsFG27gCiQ1LHp0Ueq7v\/vZT8ooNVEi2eTk5OR5Cz9z4AcP\/\/nPf7HZFls04iROEhKbJMw1xEWUdTMbRQzHBsok4FoaodMFbFob8R4RQMQ2iiyRqmZ5ZiJj4sS78ZoVV3RKD45hbeycdjoyOmu0Pn7\/bb\/9nx33OtixFS4M+VjVl+WOO7+96xybel6YsRnP++H3vrJmPeoU5VEfOf4N79wuZpf6jP517\/FHHtpu5+0XZ3TwYQtmNteO2Rp1YpK0lpDKMus8BgKBQCAQCAQCj4MVdkp2qiYgF0DLkJnJ64xw+9UvfXktLeM6dVsPtDvjGiembqwx1rL1VuEVLOBIhfNciuKKyy6798FHj15wTqNJ6FgS89v\/\/Z9DPvzBmo1NFO+4yw4HH\/JvixY\/NjKjDtFHHnn0hKNO2Huvfd6wzZu7mRx15GELTj7uhFM+Nmf2WKNmiQ1by+qJ1JWlsUZEunk+I60NZySko425qqeedtIRiyf3mv\/hF26wzpvWXbfIWuKzZp2obbJC8kLyEq7IvGRUdrnsxhbIEdWaEqWZ87WR5trrzL7jzj+\/aN4GxsS59zauIyd4aSRWHDIFtdscMdSTKJGr2ag9OUkGN918E9aL4pFG7nD\/X\/7+\/oPef9fd9x92+iV1QukwY\/ace2+95Yorv7zTew6IImNsaqJiwakLcrWfv+ySo44+eu7o+qxgZUDhMpBL09pDD02oL\/LCZcLNNGo\/uqiRKEza6UqzMeoAcWVUj9Q576XnKCJX1UEnQMCCaklfNo3EOYmTaKONX3jrrX\/yZIQ9w937t7+df+45p535CTJWKS2KiKrjnQAAACAASURBVNnUWKH3tsvywdvuXOx+8LdbfzNvwzV3fPOWHz\/1pBds\/MKf\/+7Wd7592\/XXHmUpQQ6wQoxQVT0QCAQCgUAgsPLY1DExjAUrVxFBwgIt8sW3vnajdQ\/Z\/8MZChrJd9pu6wN3fUe7y17Vee+clOrYoArKMioosku++MUf\/eEvZ1742VlNM764bWuRj81aa4394fc\/33Kbt3U9\/+nv962\/0TwjNi5ofKJ1xoKz93\/\/Ya96zetKL+rd+uuOHX74gR89+sgLLvxULWmKK40qCue9j2Pb6bRqs0cUmFYPhOTBe\/6Gspg5NrM2Em+y0fNbix+tbbzezNk1owUpMiGNUmNMZGANxUyzInQfvX9yvDsjqV11zbX3PLLYUwLmbbd7y5VXfP5Fm75w\/Re+uN3xrWzRhnMbc2fPguukFosyzB5pSpaxlkpgQbM+ImQyidCYocYxINJdf8M1vnDll7vtQnnuJZd+db8D9yhJhSObjG3+6i1rI6N1ZC5vp2k62eqsM6tZjD\/Kui5geisFMLJuN43tjNFmHEm9biVB18soOXTaUG\/i0cL5okTTmNKVdlBIhQQgkJAyCwuJ9t+JrCvU+aSeNGZkbWEVAwcSX3ivxnIzStKJyU6jabwi6z5283ev+4+bvr\/uq9Z+6eve8bat3j9muyNjyYcP+dA+B37kla9\/6ylnfGh8ojOzpgQnjMevLBkIBAKB1YClXdZh6A4EAqsFtppOjxWsKKluaEbJVjSlKDnupJMdZmYKbWR1U050H7Jpot4blzPEe+GqwjiJEn78g5svvvyKu3Lzuq3emJRZXnSPWXDK3nvtdvxJx5980gmfv+yqxzo+GVvr9NPPGKk3GG7ujNkLP3XBRKkmiYtOJzJkSLbYfJOLLv5CmqYqhaje8vv\/ee9e+7lHWiOzZr95661f+8bXf\/HCC4uiWi+qN7Defudfz\/nEaQAmusV6G2\/++te9xq45+9277LT\/fntstPlLzjv9CFCSIq8pmBjgV7\/sFZfpl7d569Zrzl7vtGNOWXvD9Q3imNN3vONtjz7w0H777bf2ei94eNHEGaceu+Ha8974lm0PmH\/mN6+\/aY999tp5+3ekBChIPQDXVXias\/7z\/vyX29awM9qlcVm7JZ69+kLv\/tsd\/\/Wzm3fc7a2zZo2JMZNZ\/tNf\/HJkdHQkVi26sY0mJiZa44vrqQUgBBCIMNFq\/\/lPt+239+7Ox+Jnbbb5i7d619u\/+LnzyWKn7Xe+4y93+trMi\/\/z12Kjr37pU\/NesP5YvV+4XRkEKCtSQYepGKyg631JBrmniVa7zjFEuKoPQ+xEO1nOhURJPNmaHJ0xAo9\/2WH3ex7qzNz4X17+0k1H0G2yu\/eOv5x\/4edf8YrX\/+63\/33JxZfutuv2EAMGqwgFKRIIBJ5ehko8LVWENlRNDQQCgecS9HCunuEEu+9x0PVfvzDiopsTRzVvTSkAwQnUVGs3Ac7Fwl+74qr99tzNkBBrladOgBFR4pxjBRsVQISYSVlKAqrwLSELwIoQhEiVILAAVHVQXtCrAVDZygBIYYQVXJqqfqEwhEGAKEGot4wvACh7YgasOACOYiEYFJ64pBTKkWaWvGoVS2YBawQAPIuwswJSKLGgKmXorBQAHNUFtrqQQVFdF0BkFcq3\/vmuyy+74k+3\/knYAWAVAM7J+utvuM++73nNlq\/z4u\/4\/R8\/+clPbr\/bbqOjo2kS+TLvtlveuau\/8c1jjz9x3fXWA5iUWUEoQNIr1Khx9anVFwmJrc4MW5hYAIZjiBEmhZIAUCZ4x9qZaOdHH3PmOWd\/cqwROZ8rPLhXVJ6E1fuHHr5vh512nBhvHXDQgfOPONJ7iZK46kSjRZ3bl1zy1dmbvHHzLTbfIJk47YSPtjTZfZ\/3vfJlL3ts0fj3vnfjNdd87YrLLiGGgoWqOvRhbi0QCDwJBEuLjaF8M15Kh8jyBxsN5Yt6THURqWDZPRPG7EAgsFpAdz6yeO7ssU4Hl1\/+1dlza1deebk1zW6pPjFOwERexDD3StQV3aaWu++43W677Nxo1IoyG8xdVakCPat0qYdHxfDIR72HD2N6qJXXanGoIT9yb8adgV5KNEMrETJ1xZX4yAL0jh1eBreqrf74TzKCDHQIs7XGekiR5ZGJASgJM5MxIr4oChjDkTEglL4oCiEY7l3OVJ\/dROJFmZiIhvpNWNCXNNJ7JE+1s7dPv\/19HcJCAIS0zLNSJYHySDMpyoyGpg8jjvIyi9LE+7IoHBHZJPbOKVvDDIiBs2XeKpDXZrP4ufoY1OXxrFw5tSjyLiviOHZ5BmvQC+RjCc+0QCDwZOiXQB1+ZDz+uhdLO2Cpnw0XxqEeoR8CgcCzBlrUmoijtCzIe29jb5iNSR5dNNkcG\/UCIngvxnAlQ3xZWmhk2LkcEGIlUuWBTlgpHTJl8g\/rkJ57Y4lH0eDZQwL4yrZeWkusGMNnHjp2Rc7TbxURqar3noxJo7jbblftUVUynCSJc17EKzO8ByCqhnkgCarP7r0zxoIN+o\/hYR3Sb+eydcgy20+sIoWqWDMCoN0Zj6LI9C+qKgCYjUCLopgxY4aHtlstGDMlkFSkyOO01nLMQJNziPcm8UqqaowxpEVRqCr3YvJCmEQgEHh66U8VLX9Mnv7G4+gWfqIdnpNM655leZAkjNqBQGA1gVzRUVWAvRdmBRBFaeG8eIgIEXnxZExlOrvSO+8b9boXJ+KquCypHBgVyssTIXgqOgRVCoRUFdxXuQ4BkOd5kiQw7IsyMhZ9X4oTEfGiao1VlaqpqsJs2PQu4Z1XlU63O2NszAnwNOkQAOBChaCxFw84a5mURXrNLsuSiZQpTdNunjWbI48uXsREaZqi5+0BiarXJK11up16GrsicwJrI+ZKO\/ULxwQdEggEng6GR2QZzJssf1J\/yGk97dClHj3DZ\/jnkSLTRcj08ZkVg67gf6I+CQQCqy\/2lz\/9iaoC4sWDLMBxbEqv1RS4shHv2RgwAShLT0RELOKTJFHvBnFKpMu2lWU40slLkiRFURhjFB7oWc\/DOoTILNXIoeGSREWnH7JqdEivDYYjNiSq2hNQTkW8V1UbRUAvFktViYiI8jxHX0exYfEC8LAkG7rKyusQEpBbQocA7H2lHJiZVdU5Z631qqoiIqYSUVUYsaplE1sW570q2DCzeifimQ0zDeuQXrMrfw4tGdBWFEWj0cjz3BgzbYmzfwLSNM2yrOr2QEW9Xp+cnIyiKM\/zOI5XdXNWGUVRNJvN6r5Y1W1ZXfDe53neaDQoijOnlem8nDgrIfTHanp8EVLxz+4PqfJDKqy1WacTRYaZvS9Je31Ydd3wGL70eP5cJcuyer1eliVzmFBbBs1ms9vteu+JaDChGXhaIKIsy0ZGRkTkn61vh20kay2pesADDgJQAgDEgAMMoAB7qOnPQDkBGAR4RdwfqarxfwXHLe\/8mWedOX\/+\/P5dv5QOwVKP5+nPm2pnnRpeV\/ZxPmwdDh278jpERMiYyBgSFdUl\/CGRjQBUPhDvfLfb+exnP\/vhww6L47ga5Q2zF4Fy5WoYPvHUv9UVh\/NYhnec1uYqf8apEGDFA+SMJfT9IURU6RDvvTHGQ1VVvBhr0P8KVNQyx9Z471RVyRg2Xrx6Z5mZ1Cm8FwDGsEg1t0aY\/g32WsO96y5cuPCwww574r59DkFECxYsOP7444koqJGKc8899\/DDD4+iyBjzzzbmDsPM3nvv\/QUXXDB\/\/vxV3ZzVgiRJsiw7++yzP3Doh9rCnmzvjeWkglS5fKF86jJZQo\/xUAZOHEfnn3\/u0UcfZRmR4aBDKrz3zrmFCxcefvjhq7otqx3GmAULFpx44olEVFWUDjxdWGvb7fbo6OhZZ511xBFHrOrmPKMM20iqagFGtfwUD8Z3VItjQQgM46ekAStUQQTWFVYe0zHWOOcARJEFADUApD8ZD6Ay5yunx4rQ8xcsY4Zs9SJNUzYmrdfK0lXdqdorRb+kVdbL2Rz6d8jKn\/6Y0emvFUrVOVVlyMnR202HgaqoqmjlkhIFQKoQr0peSRVWS4YXYVESqIJEpDqpSG8NrurUS1uW6ku2Ns\/LLMuIiFRWNoJLSFgHfrZq1ZepHKTqu65Cn1e3AAPnXKU2syyrYt4C1jKxMiMvuoajJ32eJf2DzzbUlyZK8jzP85yheLKRjYN57urwQQ4AT1uHY3m9tRyf8Coiz\/M0TYuiYI6IiKqnz\/IbJkNT10P3Pq9eo8CqpvqF+EEXqRBHYGuixOWZUTf4CfV+JUO9+s+jQ1Qdc+S9L4pieO2cQIWIi2Orqr1A9JU6lgSoAvV5iRDKodf\/2N7uj4T\/0Is8Sayxo6OjZVk651b2jlv6cw1HHg1vn74aIVcLpw52nt4zz9zTdQkbyaI3pU2iPblBgyZVlq1isGiTas8kVp0SIgStquitYAu895OTk0569hkpV1FLoN6XwUQCM\/XFKLjXm6LUt4P7K1spOShXsoUFIBFAWWh5mXjDX4uu5JNr+v59i18FOvAIqIoMTP0pcSXG2lanPTnZiiIrRKxQNiIemMpf79kQvdfVPHplVbDAKIEUrIO3MN2fU31PXlShlTAQgABTTckTURUiVelAr6Kqvq8fes0XBYOZSk8QR+RVjRN14lUNkYj4SnJUkWYAiC0Aay2mIZY5K4ukXnMi6ste5\/S\/0oF6JO1tpGohZrCAh2wLb7TsH9Kvs9k7dqqvoCAIo+zvtoojXowxWZZZayPuLY22xDpsUxuHZ3xXYxX91CmKIrbGl3kaRVkx5SMaXv9t4P0bDI7Vdp3KQBv8XJ+RRv8DaNSSsnT15giRgfcg0eoXq1YIgANNc6D1u2LqJ00KwE+fgWCharXvyvr0oN6a5KQYvi\/6uh3T3cKrmLIsAcRx7L1zYnzPQNapFJHBAiHVjQNFVflVxfXuLJ62\/3Lp\/dD81FOcl3mHPh0scTs\/cduejv2nrBGeukmIIaSS55NRlJalT+NYXcaiw\/edHzqhkaHISapG4OdmGGGSJEVRNhojRMaLB4SVAYayUPWrmBYW3v8FctXhtLImxLMLEmtsVuQ2sYXL3RKzjSRVNHh\/bU9eYt5QeOphzRCAh8aff0i\/kbASQE6oNzc9fJn+GtZL2BirjNznIlLZTuqn25bDNfLID3q4mrhH5SMYFiHLV1xTBm\/f2FCCkAj7an9W9O\/u6qFQ3e\/8D73lBzaSMcY5NzAfLSAeoCr8VkFKIHjybAAxUIBA\/QrebEimRsqVm9BTpnqzAUtlUTSaDZd5gwhVhC8XRARlUFWVBKwQMBSSZfVmvZtNEKAEhiWNlCBUgjyLpWrdLhWxpZISKesy+nFZ+ScrzjKO7bkC+sO\/ZWN5aDdRAZhNXmbWclqLATBRURQJs3ovKkymujFIHSAKCyBOIgOabI2ztRIljqubBxbu8cU9EwHMhnsxDETDIoGITBQpYMkAWDJG3YAAJzCkMEaVvAJMli0ABZHhZYa1LxWXpc47a21WFsRUFGVkTC1N291u6cpCpTE2CnDkLCkpKSAE5xlCiQDOOYaLDccE8iXUe7IEBlTAwkQKFmVFyQQwAUZ9rA5AwbFf1ZN5qhrHsbgyMqS+TEdG824WJXFWOK4kEwm0V6lGidMaT7ayoiySJKLKOHrOVYfsSWgRI4ht5BkAjIhVAHDESrK4NT571iyUpE5IudKlniHUM7VBYkR4BezN1RbvvfcOZEvvnS9rSdTqdJsjc7slKQBTKru+c4NZUY+TPOuqIIlS5yrD2QE9b6T0vNmk1Y2gYtUD4ogJTGADF0sGwFNcgj1FSiAteKoLV\/3MdxzHVbaMc57UJmky2W7bJKU4QvVkJa2eu5E4UkwWrp6kCZF4n4sfcig9gTw1qkYghIIhBCMwotVz2tOypcizzTPAA7Ojeh5W83eV1WwIIr4WWxaxxjhfxlFalpn0FpupPqkAlaPOJoklxmSrZS1Zip+TUsQ577wjeOdcszHabj1q2ViKilJBVhN+5LFHZo2OAeIZDI28A7gko7D1NOq2O+RcrZ6UQzMD09bdWc2mTFbm9ywAlVKY2HTKrli1BmXpa\/Vm6ZzToppCZlXtKVWrwrWk5jsd9c4zAOsZnmFEUi9QeI4BQIunfQAXEhbLagXiWYQEsCx2MLdFEKNOiUtYqcqfrWopYq313quQL7zm3liTJEkny6IoIsNqzeLJiTgmwCk5AAKr1Js7aKSj7YlJ9tqoJU6FSKiXp139u2Qkf6Wu+\/MOhkipqvRAomDujRAMcqAMAKT+D300VDaS995aSzSIxO0NPYJpP1MFIARDyxjhn+LtpSo2sp12RykhskoAYlFLMApbuTsGBrdRbdS502pFSQzAeQdFpd6W8Cv1i2\/wMkXIKqNXnbDvBxcyJvVkxdaIptLShapaiiBBV5B18jiepRF7FWg\/7uAZHNae8lpYlUMGkTFxHGeFN+lIdcbHsmykkRgBC0pDQoZhBCgMVECxZbHsHWkGeEBIq9Ixg\/b05lcqmSoAEasyreqRZQmEDFluZ+I4nexCKTYEM5jsr5x4hLKAMzGRV6NLF5B+DkDV\/KFWP3LuelvCAjDS642S4UnimesuyvMRm1j28AUpmEQra5tkNTCYnzaqOytJkrLMo6TWdiLGiAFsA6hXExsMKNABYGP1kokQKUOgYIVMD3Ss+rYaRRhCWi0sMrVDb3KXhJRX48gTTuOaENeaIyUhB3ylyZQ8gRSpRKwgE7UzdeoiwxiOJlpGjME0SGFUWFHJYFIm9JSw9u\/HJQ95Kj+7gYdzyWmF5QxTT9v+y4Z1quyvqCGbOoolTgTQXgkrKDsoqzIUTtFtS5zOIOOl8Kvtj+bpgAG0JxfFcVxkviSJkxoMxj2aa6xRFlBCbsEKx46VS2IyUIDjGlPL+ZLI6HOujqYQBCJTSaoMMu2ueGVEtd4Qo6AqvhRkCBMdKTOaPWtscrxtjUU\/cqGKnyEI\/hHjj3LPzp4WniogNzThAiXGoMrEk80s+AfBzEkU54WP4kZBEEI3g2mMuaoaxJQnhwAYQrsEbAI455RYGCIkSoDaZZxdeagKX\/VlWChADnC9qQesyufCMhrNKgD3XeCGoaAhf9pTtoRZQQpSQA0naUlRl+AJoLiKLoDCVE\/W\/g8lUvKlGWmOurwgqRxGfsptpQyFkpSmBMBqSFhXm2jhavEXA2fUsQJqpQRM0nYQ25MfCkhvTWIYBRPUoTErmSwAj5g4QhFLlyGs9lkyLyWDdtbSNCu9RrVc0SZohCipLSoQe0CR9b59gAAPI4iBukLFqCiIlblvcgkDLINhsX8lAmBzTlnlccotP8MoccnoIi6IS4WpoZOBBVF\/\/rWa4jUe5FFP2ZrEuwJe7XNxcf9+\/BV7SjsJZVy5R0CAJxQWAmZFs5aM52iyib01KAQwArATVIplMAw9i7tI+rZtu91K4qRAlMHkFjn3JDVVcw6KqnCrYVjDVjjiwqpApRIjS5zVam\/4HL4FPNmSUiX2ZAUcSYF+ZEJ11OrWj95p16ETIQM89x5ESigZrPAAe3hGkhLElgUIRLyiMWZKvYgsI6gmLabq4T7XGRZpQpypV5PmHmpQeeGNr+xEqwwlKOAFzVFuKWfONtgl8pxKU67sg8G8KyvY2m5RRulYrqatyD2QYNIhYXhCh6AEw3ZgyLJHw9KotVrkKvTUQi1WQxiAJxZi4y179Z7IxKQgRldRlEBlt1BvzsMo6jXuSq2bw6SNVGGltOoAEVgGR1KwwvPTOf6QVHNcDMCz8CCyDg4EqCW1gICMI6OqRnuOkad85acJEpCk9TTPPUVxBxj3KDxsDFUYCyISGAC2L50UcB3UOWZrxeVMDizgotISvIQUqeLTel9RX3KoYY169hbc0M4WqDImBjs\/EyxLPAGDFvSio6jXAaSqT5OfOqHYMV98xdXOJFdf+y1PAJUOtZLmsthUWga9GRiCYxRvf8vrD9p\/36aJyEnCDIJnAQkGdvnqH15PAnICKyb5ytXXxQl\/5eqrhZMqKKWktMCoECfaslq43KW10cfa7e3f9db5B+1mVCKVatbziaZdVovRUGlqFbBOntmo2VF86apvCGfXXHdtfXRmt5VFAtG0bWaUzAYdhqtmK42J3v3mN77n3Vuvv+bM0ov2A8wIqlrdM+zZCqz2lykTMBDrdL\/TIImloloo7BnsAyhs5vm9HzhciDtZQeqNiFEHEk9WwdCYFEd8+JCtttrUwCqXcLR0y5\/9iJBUetsz7bDbBwuOY8kqp5ZncewUDJ80TGKK8oC9d919u62hMgh8NSq9WO3Vejr\/iRFMSeixsbFOIQWlB37w8IcWT1aPiipyDwDUqsYlTLOe7rnbO\/feeWstuZrBEfHad2UrgUhZFQQoqsWmVKUfLcuOY0wXJ0TUm6VZzX5irOhkmaTRwQefgsR2uw8YFKzwxLmxrJL6gpSFZ+y9x747vH0zivr1plaYSvxXA2k1Qj3ndQgPRQ0QwIoScDb6ytXX1CL+yteuLlFXxFaNZ+RGlMXCG5WiKJJ6c3Gru8O73nrUe\/dcpR\/iH4j2g9nYsEiUqbnsy1ePjqWXXnWl2pGyFAZKspNR6okTKay6KuGBiPbc\/p37bf\/muWMjWfZcdGQPfjwknqIS8aVfuvJ5c0cvuezywo54skJScpzRDCgn2oo0c1k3SWoFore95Q1Hvn9PK2Igqr3hh3vL4wwqOj\/l9mkva7S\/bKtA+zk8LEv5CXkwf10t0\/SUL\/+00ck6UdRsK7505TUF+29959vg2DslMh5pTk2QpLo4koKVQULqdtlh2z132G7WSKqFiBasvMxJ2CqvuE9vJGCtvCIMqXItBgcyNP4HZe88Dhb\/n7vvDtequNZfa83s9pXT6JZYEESlFwUVbIiiiCWINWqMxhsTjUajMcabau9dVMReYi+A2HvFEnuMCgrCgXM47Su7zMxavz++A2Ki+SU3It77Pud5OIdT93x7Zs+s9ZaVBx\/oljl2642AUByjAgC0qdGBz9ahIgBYxdKqtbZqxMhu779a28dC91Pyqw5UIoIsSoBB\/\/nBebffecMP9tvKgy5HkEKhKuu+\/OIrOw5dpxA48TxGJsyc5G578FVdyHMCgbJKCaCQH5UqFV8pQgA0KCrnFdI0JQ8NZt8pXhYjOARHzGgtQqrgjgcemHfLmYfvMQDQYwSnbIKFeS9+ttXWW+fccp12BloxFap+r3vue9DnLGBGCQC+fg\/2Lx\/D6Gve\/4YhxIg1rSSicqJSgtlzH7r7xtN+On0LBp+EyGXsN971+NsTd53sc6sHCTEZDCuuft7cR+rqwzgtoR9IdxVcCBGA2TlQgaXIMJAwsEUkEhAA18167Fah1aT5AJAkSS2Us1AolEolVB50t27XMP9bNArE5c677\/ydx+2e05IZpSWMAocUp77ivjfeOFs6S74F6zIC6wTzUSGpVmtJO9\/8X7Q2Fl\/pvvkZgBRD5POdN19Yj4vBtqHSSZxpUZGfd+ylruH6m58Kwx6JAx0FaZwGni+SAVgUXm17\/b8XJCgkTAJZ6kQHRkF7+4pn770YsxXWWt8LLUsQ+tW0kmEY635XX3tHSK7UZusDzSbL5XRqLKvuJrWC7iMrMwtpRM3MAgLO1hyQap\/V4ADA1QypxNV2Xv+DotKavX+QC3ldcU5lK26ddUmePmvMZVlmUysY5gBASeKk7rJrn88rKw6M4WKBkgQAQBHxSneQr0Pt7LFSOwuKlLWWEbTvGef+r59HvoAAGIK77nngkVvPOmz3TUkrRgLRCeUefOXdcVuPaTRLvbTd8\/zUq+v0173nvrlrusy3xtwCvha1bY9grenGJOAsgw5jgLsfeHD2LWccsGt\/183isV02fPyNZWPHju2hlodcRtaphFVumPvQvHqdhxRWGa783R34dc+X1a931feuGuLvyBpHAr4Dj9mpLEFlFTzw6ONzb\/v193f7JWLBoXZkE8rNe\/GzceO2CblFp52R5Bjzy03u4Ucf02CU1OpqgDb1wihj37ma4q+brPUf4YtjBiOhiJBznkfkBXHGYhUAaOV1DyeyEsvsKMgBAFvzH\/7ybxYEKkOMCR545KH7bvnTTw8ZUpOPOislo597fdG4cWMKsiTkqmZtIGyT6KE5j6HPaRqDcQSQq2s0bJX2AKhU7vzC3AxZVtGxav9BAswC4mlSKp9kqWMH4FYTEn+lCLjG7FkjBidffcMzAjtARWBicJmQ5wRIK2AHq909uFJgXynHSIAE7IBd91bBZe6fzCdkAkEBDcABtOWgucjNOWnLB\/a1Vx5vCsoqXoDJQkgXYvKJTZfceOsdsQArAA1sE2vScjkuFBsZfIaa1YwhLkc+J85lEnx3+DkrQdDtkqwNgkNNVAZsBWkmWOLBYp+a5786z2at9VG5PlwRUnOoWgC6brz1OqAYMBV0\/+oyvfZbQ8S19X1lvphDsAiM5Ek5kpY8t+S4hdJFOdXx2quPRTouyPJ6t6R2DwQB33DzDVE+jPI5B5pBMxILCltgxyZxLOxDBcBp0r5PwASWupmOX0Br3dHRUTMcrK+vV0qlaep5\/3PT2H8bAoSgmXLcUZSljVG1Ke\/CSJWziuFqGDBDqjwHaJ0Fz\/cde8yYZikoStP0O1Ww+Q\/BQN2PfAACoyDJwfKcLAOoAGah5zTG+YgJEvK0IV1xkAhAGGSkDGqLuruD9L8cX6xLtQaR0hmBRUo6F3vZkshrz8qLA4I0jpVmxtjZSrEQKE0MxAQW\/dQRk++YGDQDOUFxFtjZLGUGDrwyBE6HXhCiOCUG2BJngbJauGx1oj0Gqs0XtbJ2+B0BAzhiQaslCyXrE8U+dASUaMk8FyuuKE5JUtIZ+bZqnA4oNaCItFJxkvyLXURBqG2FMLU+I2ll\/m+7HnWDV8oUhREMAiN4UA5kmYfNASwJZEkIy1999UmTdTYE1aLfHqrlEbYDVG+++cZv+OWQCwAAIABJREFUv0T6LUGIV5b8GcGhTgkcksKuCJbneXkkyzFeVAwq8195uuBDnpfnzOIo+zwybSG5G667fvVN1P94xf5OTcNVqJmL1HqwgmQJLPqIVR9aPGgOZUmEi31cPv\/VR7NsRX1YbvA7dfZZAG1+aO+69w4AC8iCgAihFgWuCl6iQ0HVvf7wN7D+MIIVl7kUMPOgoiBLRVnOa8ppDBjIETkiFA64HKE1FmNRX4QUfQdQa\/pbBIPgEDR05aW5yM15aZZkQV1YmT\/\/iVxg6sKOunB5zm+tDyp1Bf+m228NIj8q5AEglyvElTippABQjctBENRsUVf+cLZkrWJGsiLOpIAJUTtimR2ADTTlFHk1RQ3g3++jvgV8zYshSArYOvIAwFXKUF\/vAwCqL8nCDQACpImJchEAsINVTlFiQfmKjZD3lQ+G7h1JzecFpGZ5xB5Ci1FdMVYTW+8HJgiZrALHGDmviArixBVD5\/u07PNlex14RK9+G900a5ZDQGAPOyFeccUlV51324s33\/XQFhv1Iki+sXH6z0BCyoXKhdqFDmvcIDJEWgGwBcyAEqFch7Ec5cp2qTZdhShfSWIXBjbQmbaEGYjutoD4Z8yrlZ9aq0eR2rxaRcxiAIdgCAz6DrXUKJsCfr7Y1tlZZb+UYg4YJANmDUysA69e67BaKbP2BEiJBWBE9Ag7ujp232\/v9bbc85wLTiULWTWt80RLCgAixOqLW5qZ6+vrkyTRSnd2doZhaIxZdehnAECnVnoTrbmxUC6M0jCQAtjc\/PeXnnbNn3tusHGkbFYp5\/MNK5Z1av3h7BeecMz1gbdhr+JRhx8KAJ7v47+covPP8e3XGv8B3SLClc7UHohWrA3Xv\/huevVN9zXkBazJ5xrjqm4r+fTu355+5fm6fFjualuvb8NP\/+sHCgjBErCClVpDoX+8yVf1db8Saz1thoEQiYE8gVU2TQYhIz91yipNyn\/3s+aLLr27oV\/\/mNq7yp0Nhb7t7eVA03MvvBJo0oSNTfVHH3mEhlWaY0ZETdDZ2brHfntsMGaXcy46DSxklbjOZ48zRtKSLf\/wb3v\/4KjNpxz1698d1xN1IEkt0odBr8Xy6xcFYARGcMSZxwmAIRLQAF6lC15f6C686paevQskrBgc+gtaO\/3Cx8+99qwyzmPu2dD0wx8dpnyP2RGpf8K4oJW1Z4dACKXlKw44+KAltvzcKy+h\/N+0iOgeY+S\/Kz6jACIyMqsa+RwIMkCuxqz8uoptVRnnCoVKKtprAJ2rFZX++fz6z1AraapvhJOOKF9Wjbuve2j+HStPADOCjLQjFrYgORDtBdSWQEciJSdFqwInwAzEKYALPPFVNa4oL\/gGy0Zrcpz\/DQiSIxIk7bQW3xCA+MA5kBBEA1kAFqSOjDhsqmbtXlqtL\/glW\/ILG0MhtERagBE8sUs\/emfvA48YvPexp\/z2GJ91yAl0O\/n+B+tPLYUTAAh1FKbl5ZFfvuzCq8++7rk\/3\/3woD6egkQV6y0SCWuwkLbOmjHz7DtfvPKGO0YNWGetD+\/qcAQOa5zyGmGbyDEhR36wIrFtiepyOmTnuURZsWANEqmcp4IkTgvFfFItRYGHyuuqdIS5vLMSBMGqDOWVCXDA4BHpXKir8eJcoeOiC66++rKX7rrrsb7r50El+YICrFEwdK1ovnJ28CqOyRrySfr7cwiCVZAJaoHAKuWDzJsz+4RfnnnllVeP33owaBLwAUCJAcSlzR233n7ndbOu3XrMmDN++\/tTTjqhdUUzhuGEXfc68sgjIusUMMBXl5\/liysEJoaaLhPIgmJS9T16QlfJA8PAgCjopUZnAHWeamtf2qcutC6rVrKGukZAQGDN4DODxGHkx4YyF34HZvGX0G2tXettIQCwkGWx1K1RBwZiUqxQjCvUNVRblnr1GxiQ1LratTBZEqtAg2iH2qKqsck91y32dcTd0mcBEHJEDKBA1rY\/Ha\/6R4BqzQ1VK5N4WGzqQWEuqT010AIACVfTxLC1BhA0O0EFBBbBZpaV1sY4YwGDQiZQVJDzjBYDAA4DEEJxNV9zQWAkEWltWTpltx8e\/MOfHPiDQ0ilSZxS6MNqnOk1eOW1yit5AqFI3kHDG399o5IG+03aq8HPPKj6WnV2doaeh0KBn9fo3XPnfSVLkQees6rmCod6lVn4ql0UAGju9nKo+duuavErsQRc0xcCrGTDIzBoAOgen7UAWkWFEAQBzZJz4n\/avHh5lzviiEM8SdgAZyoXNlqjEFUlTlDn5s5+kAE0KGSjGTxhALakLUG3db3oGmWWAQA0CStIAMBgCEAeWwAwpIGQxQHAP0q8v03UXq8aTb8mknYIDrXO5YSSqgvfX9CSuGDXyXtJ2OEFTBmjAFvj+RDHJfILDz82P9OADpQwYUxgrQXla2dS4yyEdalAHUHgixILQCw+AwQEIKZiwNSE2mIZgYEsEYDWzCRgFAOwx93L0VqRcjIAEzOyRersTMN83zc\/fq\/DBIdO2TuQRDGxQqNFNAXki6WkKg\/PfrRG9lBiwZGoABFRLAA41AjssaXazhGopqtRkCnhyy++UAHefddd1TTJK\/\/\/96f978Wqowiv7IqoLz6FFkAzAtV2Qko5UtZCsaFXuWVZUN\/YCdYa4ZUxkVRbQwBqcTS1TkJtXapluXhfXpdWxRooMbVXQVBZJBLw2DAqgxoANHb\/WAD6+zwo8Bg0ICtJaxtfBuWIUECLQWFBbzXZGK9c3xyI133hX4sv2QStyjKyRIwrnZ2FCXXPup5IvhVlUJiAoNY8IfQC8HSo8kliCbofYSC08oQPBBkAA2gQql0FoyUBJUQATM6w9cCrxZUwdndUSJjAIdYUob5DYgQSJsxQAMSXbsYBE1isef13BxDV0gMB2alvgnJcexG\/2E0hd7c4gKGW0SEEqIAQnKtvKHKppVjXuELizlLZgThgBvDYFnzl1WxkFIChlYw4ILA1C\/tVI+ZxBli7T8iCDwCeZCTMSNK9XgHa1FOaBVdtlLM0VtItubbOZ+t7WoPECExCjMQAioynOLEuYUQhzTUzRl1LStCQSO1JAeBJBgAGfUYisbSGFds14xBBqL1xTfmADAA+Ue98IxA6wJo9Lwg7kGrFcaaNBQ\/RsrUuDQkfmTPvhN\/84bKrrh286cB8FKqayAI0CwAmgKxFUDBNDQAgZATWCBnWgVau241KK8lIrAOfQYOwUmCdA3CyJrMEvjiHiAgSiaui7pw5Y+bvLrjDghdimUya9+v+67D9rKukAsYvTN9nrwvPOPWdV+bvf+QpW+2wy2VXzxy\/5fB08YrF77477eDdHnnltbebO9s98EBpMSL0dz4SiIgk5LkkM6yd0mStseyQISMhT3RIla6WPBqQjFiMZRVFAQZoAREam+qRk969+zz5xLPaV7mQbaUrVDngAFTRUD7KNXy1ednaBFuVOcoArWAgGjJMgMukMmEE0GhJ2HcgAXpsYrCduVwuzZyvKO8i3wQ1jiaxCTgBlSuJWPIMkOcoykSBQJ3faarWEzC2CUJrxIa+CoBTQ2uNdbDa78Va0gGLQDVJ6nIeaASlSlklRkuhnxnjiyPCDE2WxQDWgcvSFIJQTKz9xAu8JA0oKBjWcWasSQMNxawj51eysqWoZ4VzjqEeyx4ZC6pUTf1iU6lzxV\/fnr9s6eK2FDkA24VRGGay+sNpja4vwBpcoKpaO8obqAMvt\/uEoTtv0ZRXnZ7UjqA9YKXhd4INv3r\/Q1PM+ybxVKaBbbkq+caqcSHqQi50lcSg2MgTx3nPT9s7RQP6gRf5FcNxanoUAl8Q4lJswcsXU8s+kk3KDLoqXhAoH9fSuVSImBiZiVky0FhK80JOnJm09eCt+ueUqfjaU055NgPRqMR4vVdkTeee+ZfIA0iNZ7JQCaADllRUjBlhrAgxzQELkYuiQkdnVvDR9w1Y25lQGBS1dUSUgAceIAMJI+I\/qXyvaS7cP\/707t2PEose6t6k8mNG9tt2RKSoItKFmogJJSRhoCjB+jPOe40VoAPixFcditD4BR1EVjhN08waT0OYlfNeJa0whD0rEoC1NZ9Nh0YhUFZytmx0kAVeF4OPulhJg5xvVZqk1RwCiDLk\/TNa7X+Af74rLHiBcTbMexiCuB6dxsVoth4\/eNuhDXnuqNVx3EovRAO5Llj3vIsuBsUaXIGcgHCgy1UOVGZd5qAYEPb0OS11MPlV8DLdiCg5U\/ase\/+DtwWhrtiQj\/Kc2i\/40\/9HOiP\/bJprDYhiXBwECjghIEt+oqjsMp8CU40hLhe8KEmMUo5AVtURUFwUqKRclrAhNewjFHM5U4ktiPU1OK7z\/LitM2rIV5I0QdFhZBxDlvQKCQg5gxQU+IG1Ju8Mg8SeTz7YmL0vziFEkPmYiTOWIiueI+0r4KSMkmY6EO2lqPOhRpOGCEK+NVoJxFXQEbMkSIKihP\/\/WuQv5aiu1PGTAFLIBlUgkMSow6TS5XtKa4WIrAhYCyrQpHyPAapxojBAzjzPIkqpnDgMIOyRj8BmsU0q+XyPSlWUUl6outI0DDSXVRjoBMqOMw8DRC8Iqa0j9iKPhBlBSRp6mYkTpXvpMKg4YEnymHJmfL9PJUODCjghW84FfpoSkudqFJUAnEsCJP1Vx5B\/c33rdgqxSA6gKwYH7YFfRZdyBuA0OSZn0WV1pCjrBNdOPsSl1kJxk5z4imt2ugxAgR+FirirOUjBAzTsdUncVFfgUhs5YRU4ijLxfAK0HUoyiz7km2JQYqEggGAMBxn5KsQkAc2x0hIbDqJcmsY+om8k8ApSSRwUCmGkKVW+8dE4l1p21g8kyoGfr4gxCgq5XA4QqwkVc1Z0NVX5AJSRJO2CHv2SJIlshfxIgqCUQj4AzpKVqfBrBKv4b0zAyM45JqDQl7hKYNs7FiGXiU0kROCBIkEdciGvixogTdM4q+YCgLT9scdmU1ivw6aGph6clF1cDet6pTEiQQaphxklFtlXxYigF7Bzqe83FF1oPF1V1gjUgYjH7aS0caERQHJKAbhaRQBgjeU\/dutXaq4IiIhgAawzHXvsMfGVV1947Y03X3vzL2\/Of\/mVl1549fV333j7b9vvuDOiAKYFX7kURo0ch9r76NNFndWqce6IH+y\/44RtMpGkNqUx+MrfysjluGyFWesKkPF7JWG\/Srh+EvYpg65SLiv06+Q8hL1WlCTBworOFICwO\/qRRWTJ50snTtzl16f8Ju5YQra0+8RdxwzdcszQ4eeed25m2TheW1vvfwbsNv\/piiEDBUEDe01d1NiFvbpw3S7sl+peyw0m1CPz+3K0Tqp7OgmsIRKNQsg+gYK0\/KtfHD1k5KgtRo3+8dE\/cSY79eQTtxo16uDDDh8+elTzpwtKK1rGTth+kyEjthg88uHZT34LVf9\/ESggQOzX+43fa0506vVqN4UsXKdE+XbwOnXPLt2zopqqqq5Y39OQTqwLcxER5kLfk3T2vXduPnpsn4033W23KeWuDtDsLFDSNev8s4YOHtR\/wCajxu3QWUmTcuvJJxyz+dBRQ0Ztu\/+Bh8yb+\/Avf\/ET4fjCS6484NBfa9\/PTM269NvwyWEE7UNK1GaD2x9+8fq7H3rzg3clbi9KV55b89ya57baW05ac9LqQdmgnxBY5aPwsvfe3GPnHaZOO2DCxN2HD9182BaD\/nD+uZuNHLHZgE1+d8rJIFlQjD79fMn2O+4wYJP+m2064OZb7lzRHl9x\/tmjxww99KjDNtik\/4jNR5zyi5O+\/\/2pg4duMXbb7d7\/cNFa100JUDU2DuGeOS\/dM+f5d95+zyerXakxTENpCWGZgmYlS0iWBNKmwKCARgCThGRBYdeS5ePHbbfu9743eMjmzz4z7523X9t8+Kgjf3rcpoM2WX+9PuO33T6JjbS37LPbzof9+OjO1NlqZb+99zrwkB8ZBNctJFubwJVPHVi5+6nVixOqu\/Hux2++c847H3wEVPWwLSetBWkJYbmPy3PcFkpbCG0KuyyxJQCEfIA+mDkP3r3FmC37bTxg9912q3S1gmZjgZLyzPPPGzp4840GDhwxbpf2Sq3IxAAsCDOunTFy5MjRo0du0n\/grXc9WM3ctL1223r4Zs3NzaL88y+6atiw0WunnyxUbu0MKUwMxxZuu\/uJBx5+4a9\/W6DRhNIVSmsIy0NYvnLuLA+li4AZFWoAzFDik088bsK2O3\/y4QcBxM89OXunnXZ+6aX518+4ctL244762VHjtt124nbb3XfHHYiw915Tl3y2tKOjsv1OO5bjeC1c7LeDL1sIrvwQKhVg8jhoAK+pij1K2KMLe5SxnsOGDiAT9ZbiBhL0S7AxkzBJAQCoOw\/RLnr\/zd0m7TR1+sHjd54yfNgWQ7fY9I\/nnbvZyBFbbDrgd78+WTgN66KFixbvstvkLUcPHzFsyC233q283MUXnDNq8\/4\/PPLQTTcfNHLwqJN\/ftKUqbsO2mLA6LHbvf72QgFaWXoHJAmiAMXeeP2sIcNGbDFs1OFHHt26ouOaay8dOXLg2NGDNxmw0bW33NlaNu+989bG\/TfY77AjBmwxfOSQ0WOGD1m2oiOjiMlLkmTVnpv\/BQ\/JWngXiWBNH6vyLmiMM7\/koo7Yj72mktWdDO1Q3yY9OqC+xHmiXGecrugsWWalFbCQS5cuWrjzlD1HjNtuxPCRc+c+9ub8F7fZeuwPjzpmxJhttui\/6eihWyaCyzqTSbtO3XvP\/ZiNUjBp0i4HHXxYZzmLCiEyizCyFTFi4pkzrxk0eIv+AwcfdODBzpjLLzxv6KD+w4duOnjw4Otm3ap0+MnfPhy8+aCfHPOLISO2HD1k6I4Ttm1u61JhiOobKcXSF3FDyOiB+H6mGoyuL+vGsm6qUt8q9a1SYbm1VaozQa9ENbriusvLxjhEBmARVshYLZcD0os\/W7TjDnsMHbTx+G1H\/+3TzzuMzLh2xsiRm40dPXjQwAHX3vDn2AIJHLj\/9AGDh286eNiJx53k4nhZS\/MO20\/YfNBGo0cOvubGe1QIqLQTyecjE5cbfA7BTpm85xaDRmw2cIsZl11R6mhnmyioNi\/9ZOtxW40ePXrQwM2uvOKKcmur0QqAxdkliz\/bcYfxg\/t\/b\/NBA8ZuN7m9BI\/Pvnf7rbececMtDvyulrZdt97mhBN\/kwhUk+QLzfeaAiuw1G0g4ccctWdhCRqqUd92m8e63qkqxlSoUO8E+1ZUU1UVgnxQTbhUcojK83Xoq1NPPG7eQw+saKvsc8APrrzm2oWLFk6auOOQjTbacsSY0cNGd7R3OcEXXnhh6JAhgzbfauttdlj8zl8bg1y53O7QvP\/eRyMGD9t6zNDmzxcc+\/MTBgwcuvnw0QcedlTKbMWJ1OqHQm5N7Sb1lwp0LKDzYNt7FOs33YDm3HvjPXffrQGDTGmvkFDuyGN\/vtngkaF0gUgQBA745ltv9R+UHx52QOeytv6jhqm+fTyT2aWlN576oN\/2gyJARvqKNUAoDHNVQyn5j7z8\/tOP3KXEOvATKrRKDiD68bm3eabTmYoH1Qbfjhmzi1vZukGBLMvyhbynlCTVYsBXXnLFR23ZHfc9Max3625T9\/kwRaW+W6QsACL2lfM1s1GSy2EVogdfWPDck\/cnzrOQE8mVsL4F1znxrDt68sJ6FVuDoPMTd50ek1c7iQJHJDTzitMfmTf3Dxfdtv3ue\/ZQwJWWIMgqtn3fww69dNaM+JM3D9p3336bj7\/3uauLALZSIVn7AXA1WjYgGPLvffzl+a8+lThfBQXL0IW5Zm762RnX9HRtda4SukzAHz5+r6rkMiHNcRjm0CRLP\/7okgsv3WrXPc888\/SP5tx1wsknpa4r0HDTlTc+ePP9f\/nL68syb\/f9jvvDf\/9q203wnjtvPeP6J7fbZXtVlQJ2rVtIjj\/ptKNPOXnafnuKQBRFsXEAAOi+hVDIRKDsZHnWNOO2p6bttRugJQgImIS\/pmCpQQCBSHST79UFUVK\/\/oO33vfOIzf96qQTPupoe2z+Gxcff\/TT99z29iHTosbe0w477GdHHfXD\/fe4dubNZ51\/1Q7bTMysqdrS3j+YduGVMw\/f+eDnZz91w92XuTDaZa\/\/unbW9Ref9Zs1fs1fhVodxaG2iOQ1LGmF6+58Zu89JxtsY9AM2qFvVCrIGlJwCvALX3PrgNgApi0LPt1p2k\/WHThmwcvXBF7Vk+Vvvfc3q7xY4L235i\/86ON9Dz7p9D+ccd5J+8WVqqxfrDilAWypzA1RzBARqFovHnktJdavIsZ8QQUJBEB0iXtcdduLB+2\/T3u1VMgXHQELoWgQXFktImAtRJnmDAA1cJKsWPjRjCtmjNtlzzPPOPejObcef\/KvU9sVarjxyhsfvPn+N\/\/y+vLM232\/435\/2n9fctL0GmuDAX5y\/Im\/OPpwk5gTfnv2xRdeu+cue0\/dbdw1V1363l8\/HNy4401zXth45HYGfVrdV34NDQd+8Y4goJAPvqlSoHsJwh33PrfnXrtL7KtUVC045e+AwFLzKWFGW83igw8+8NEnTv3gtde2HrDVG888pSTaZOPhL7z1tFW4+w9\/9NsxE47Z96DbZl6+6x7jZt0\/+5h9jlm6vGPW7FszwHC1gNH\/u\/hiAHMFSCF68OWPn3vhkYpTDJqEEsotS4snn3VdXdpSr2xWiYUK4\/c4OLG5GrGKgTy2jYEUI882rHv\/rX9+5+GbTzn5+I862x579Y2Lf3H0M\/fe\/vah+wYNPfc98LCjfnT4oftOuebaGy88+\/Ltxu0Y5fPWM\/seceDpF19x+NSj3nj8xatvPbPEbsr+x8+65obRZ50KoGotlzCn4q6W66+46vIZs\/544ZXbT9otABHuOOaEw449bn+u4C9Ou+iqK27affL3yYnvh0vKbs6zz\/qf\/WX\/\/fb7wzkXnHnJnzhRYRSiZRCqkZpAvjaqoua1uDoc6NnPvPLS849K2KMrRgadqvolSe7402f20B15W\/Y5E\/C33nV\/6zVgmCM2gCqIwqxl4YH7T68fMP62x2et6wNU295\/96XUmeYUnnjhleydpw865KDf\/enM037\/pzDfmMt5LEZAAq8+8OqdM85mqmbbjQmJvfzK6y6+5OqLr7lthx13IiuRtj\/\/6c9\/fsQRRkWn\/OHiK6+8ae899iMnWvsVzD\/98ivxJ69M2WOPP5xxztkX\/6ketPcfz19k0s73nPbEKvD8iFZk4V3PLnz68Xt04Iv4FnIxNSxx\/U6+8PbGbGFRx51d5ai+35bjp1QQUZNiAskpoEKYi5NscWs898kHm1rf+v5eU845+6IZs6772XHH\/fynh3FifnnahZfPuG7qXtOvOu+8999fdP\/T89fboF+huqzl87f2P+JnBx1++KHTd5856\/Yzzzpj6IgxQzbsp7XYSrlOpVBuuemq6xetqNx678Mj1zH77j39ucUYROGyzz889OB9f3T0ydMPOurmmTNnXnbBdmPOSpQmJ5DFPfv3eur5x4Czdz78bPIRv751zt0HjNs8jPQDD86bPu3gt+a\/395S2mHiJC+AHBVB7Bqty9Q4pShgERKsn\/Pixy88O8cr9IiTJPIhwcIS1+cXZ9\/aS1bkuEtBVcCfMOEAjPIqUBp0Iarj8rLT\/\/QH4j\/9+aUll11388gR6\/u28szTz4OFt95+74DDf\/jw448OHjbkR8ccv9f0\/U7+\/emhlOu9zyKo5CCpdJR\/eeKfcrnej8++9pY\/X3rn3Icvm3nX+B23EYFSV2fohwigGDxXoyyuEaHpynMIQnfeAwtQYdohPxarn3rx5Uk7bQ8Wffbvf+ixT1qWGlDHHntkEQDSJcJijb300ks23aznG++9d9z5Pz3v978BwKl77r3Ce2fRxx\/hhEH\/5FkfZ6mXr4\/TZMSozbbf6jQFzEAJQIvAOeffeNqJR3oATiohxEWsJll06TUvrfpeZk7TNMsyTQBx6aEH7tt89NS+\/b+H5KbvM\/V3N775XTuHoICqudsAAEAlBdL+uLETthy+mYrqHfoiuorwy\/PnHHf8tPUJApc6IkCvIwPRIMQi3YGmGw0Y5Pnh70895dEnnrvwvD8V\/WI1yeobew7cfAsAWPDeOy2fLzryjEMShJwBD7\/wBPw2UTN4W5k6szp40q4777Hr9mWnUucFftAB8NMzZpxyyo\/XRyi6zHdWJFzhaNZVM7XS2gXOsXLu7dfeaG5ePn2PPWOAgf03rgu93k3FciJ33nlvpTMeOGxMFtZb19jSI1pnx61I4wnH\/HSHXfa76rL\/5jjMssS6tFItkwJwkCQJqG\/JMouAPSAF2b0PPZtIYf\/p+867r5K0rRDnUNE\/jg4JEFO3tzeQR8TW1fVYFzwgdJktDxw2vL4QbdZ\/w5cfTQHta2+92Vo2fzrn4vNOP5kNGtd36acLhLMw8jcYsBFpHYiXR79nz6aSksamJk+v6brO16NGgO42LncPzn08I73X9F3mPfxMqfkDwiCutik\/YEylm1Je41KzkM3SuM53kHW99vrLrSmfdNTxSmlIU0+ZQuhjmBs+dqzv4YCNvtfU2OPzpc1ss1wQdjD5OaAyirOgg0QgFBARXunhtlZAwNId5UskoIB9IY\/5ptue84sbTJu+78P3pyuaF9USglHIAZJAN7NfCNmvkU7TNGObvffGW20tbdOm7B0DDNxk47pI9e5RLCVw55\/vrXbGmw7bMg3rrGtc0ZgnYRIGtAJgmK68+Oo7bpixpDN1PYa1rWg\/YP+p9911zewHHtQN\/Zd22QMP3dOC8qTb2vLbjLLRpBwCOrz5lhcT1tP2n0wPvNjV\/NZXv2RCTDXVGQmSFxU23WyLjdbv896brzVP2OSpZ1\/92bHnKk+xcSK4zkabqFw4eNMNnntm4fsLFwzadIRlCv1IEQVRyJn9Dhm9rxF86RQXx6B1tNXYCVuOG4GqjoEUcAbeSeff9IsTftADIALrgRIwbP6wAAAgAElEQVTAFRaK+YISRmFCQGAf2Zm00KOPeEBkMlMeOHR4fV1us\/4bvvRoCmjfePutBUvbzjr\/8gvP\/LWvIpf2XPzJR9ZUEaG+d5MXBn4GoaFe669TF1Dffv1UTW8s3UtiZqoibvbsh0dvOW7LbXewCA2+8Uhn4l184fn3Xn9dcxtkjWObF7euB0qsm7jHXvX9ij2l5wbf69Xc3mUAgCiJk7wKQcABgXzFCEC3aPOrP9x5+4k7b79VexaQ3+QAY4ATz7zxV788pLeGPFjfWYd+lehSRo88FDCGOSvPf+H51tYVvzj9x+yDTV3k0h6FnKeDLSfs7DfQBv37rdcz\/+nCzzsrYIwBUMYkqH1hVS4nSmOalfM60mIZLSDff9+DI0eN3XLr8VZAJ52gHKTq6qtvOP+ysyXsU4FNm5d11IFCxBFbb0sBbLhOjwEb9l3W0uq+uVQcFFLcrQLyAKIov\/34HXYdv03ZVhm0SFglfeqlD5143JS+ACGYLmcyCEpOWRBHtSxSICEEBKEtho7OBdBQ72+15dA7Xvxra1vWs2d02YV\/vOPmq5e2i6kft2jx8t69e2dJdcouu5\/6m1N+Mm27Dz94\/\/PWjvMun3H5RWekGRvq1bzk8xED1ncuA3CADjh+6L67Bg6Z2G+DAaAX7Dl50vMzX4yz9K8L321etvT0Cy464+KZQVqCpKW1+XMtWgTZARF0VUv7TJn4aUspzW3yyvxXjj1wm+n7TTv\/9mcXfLJ49rzng0LvEUOHioEUzLeZOkZCk3faafIO4yqWAj8ESMsQHHfWLSf98qA+Ajl2iIkDP7VeKYmtgAhnsfFRgeNcFCH4vu\/buC3v06KWyqEHHFRqWWicee61N0ZM2HHdDdZ9ZN59D8x76LnHH6jvE3R0lQ2bmTOv+XTR0plXXFws5vtvtGF9oXDsT382cfLUCy\/6PeXzxiY15dwapRKsrg+x1oL2PHABOMSgOH7cDtttu11nR+nkE\/8bfH3HPbdvNmgDH8AI+9aKiBcGk6dMUUF2\/DH\/NWST\/pdccO4VF1Viq2z9oCN\/fExEgADqH3ZbIsLgwAcrSc5XeWfq4NOIu7QLq9jgh+v0ccv62WY\/XRZ4UhPTVKGvgi9lKcTVmJkD7QGpukK+LMwKILZ+kPeVciYliNbgsP37qOnJGIgBowAiTutdS6BWJNkKEAoclFRTvVnQi6Ah+aRRl9IMy1REfyPtZ4bYE0ZOGXj8Hnvdt9W4\/fc98MUH\/zz66ZeeePhJwCZn\/FxYVEo5EC8MAs8PPTCx9T0FX+MJuFbckxRkgW0JoTXPGoTQ+qEqNuKSddGuywuaTIdyOsEmtutFJgkcaPbSNCGUQrEIAI65qCFfLAaetp1tOXKGeNT2O825+saU\/HofPLFptuzhEWMPnXboK7NvGPjkk48\/8VAQ5ZK47GudZcAA6Lj7rhcFa8YMe\/XrDTN93A+nr0iigo7yUukVwVLJisUixCWQ7lOBTRJdyANAVjWhVlkVWEOl3BmxWEZRvkMQrYgoKxsPIJUUAwyCACEoV9W1187adYeBBcWuon1xs96dgwaQERFDpcEPRFOSJXG16utv0bN4dQgxkiABWkT5rx\/t25okBjpiAzYpBchoHWfgewEQMllEYOOc5\/yCRzojnSiJQTvyJOW0FosRKg+VVyqVytVKlM9pIj+MgnwEnkZPW2FgAQbOMtFkuPuFRgFdcw9brQb6re2zu8\/nsjIlVkG13FUsNhx7xGEr0oJHQUGleSlJPvJJKZUDZjQxgAVIQADAR6PzpkAZgBGtdV1dXaVaBYDQg4aGxkhrrJYaQ4BQDRg15q5Zt\/p1Oc+CV+1MlrypPUWStq6Q3Xeekk9an3ty7sxbbrvolpfZmrr1msZP2PrPTzy5xZjJfq64+7Q9V9+yfYv+0ZzasgWYtu8uLZ2dXoSiQLAS5bVzAKwACRCBEBABUZHnadVZ6Qz8KMCoUirnPNhh25FzZ8+Z+8yQEjQNGLlpXU9il0Q69ECycslUq8C20NAjcRL4UbvtCv0Av3u58msAtPpyFymAcrXJdAa4nO2SGl+rpJoisyRvXRMuypt2Yo6lvim3iQ9duFpxPTMmy0zEbByIElKUlDMFIFpUSIiIEADVn3f5tbV1iaueJ+769+f6qAEIESPS1g8EwCGwcwpRAdYAgMKilEJEJ2gEQhJbaW7raJ+4z4+Zy68+Mef6m+7847V\/UQKeVlprRCpXobevE2dMlpWr0KjB8\/S\/S2WvNeUAwBMbZi05aW0ALenSzKqqbuzHy9ZR0Nt+nOcO5XQGTe16\/dAk2oJmLeIAIAgCEVakPAW+rySVNE5smuWKhVIM\/Qo5BxL6gTOOhB1bFpFMbCoSQWoy7dPqh6U0TZmdMUYT+9TVurxj2j7HZEnp9Zeen3Xr3edc97pxYqyxqSFPkw9eEDACG8s1r5aV0\/Z\/vL4RsGZHYGvn\/AxAVdtz8ZIideYBAcB3UKGeddVFRQu9eElO2hpVUKZ6pXorFAESJMUMYpM4C4LII04NQBih0uxcZ2tlp+8fJpUFTzz58BXX33761a839aifdPThu0wYOu2wn1\/637995aFhe0yb3lX1rpl59a7bjQw8nThfKZA0U0oYA7aGUmS\/kFpHBJBylrLnESlM09QP8udceMXE3XfBzuW9cgaSZe+\/eXVdsSfr8JprrrnuyrOP+eWxEyZNnbzXTwJxLokn7DT+4lsefOGpR+cvWPaDY3\/dp0cDYwaijQX8Gl3lN7I2MpBBLQieQN515qvNgV3WkzwyCJSVdY\/e0LaegnWqLXluyxRUVV2n388PyPcBDVQqse8jqLBSytKMc77Xx69cfNFFZ17z3K9\/deohOw3YY9o+mV\/fsN76d9w646ozf3vfvCcnbjfm0ovOyAp9bZiPJQY\/+WjRJ1t7Q3edcuhzw3bZ\/4DDX547d+snnnzjjWeMBSGyCFaQBGtGy9\/4arky36TmEg0AmQOv7tLzL526+1777LPvwfvtt\/+07z\/9\/Aux4ZNO\/MU+0w+auv8hJ530S8gyEcmy7Jyzz54xY8aknXccP2Z4YxieeNJvdthl6vzX3+rVtw8B8D9EOqwCChCAx9aXJOKOomstuOV1rjWUas5Viraj3raFti1wHR6XA87Uak15IopyQZQLUuvAcP\/+\/d954\/nmz5pBR3fcOw8ACtF3rrZVc6V0SLV4S8LMk2ooXTnuKHBbxG1F15aTtoKkeW6PaoIB7ggg0SAkhKxJlCAxeT169Xz6uWf22Gmis7Lgs6VCyhhr0jhJkt7rbWAYb5g5w1QAEYMwXNvX\/SWQsM9Zjst5bitya55bC9yW50oeyg12ue+aFbdG3BFIWaMFBEYoFqMgyvVZdx1rs0cfuE8Ennvhpc+XNhOLAhw5dsyTLzw\/e+4j1rhFC5e++OLLpMKNNh3yzLOP7jpxWwtuRWdX79596\/KFXJTL5wAJrFvjbJNVUMy+JJMnbj1p4kgUUC6rdHYk6HVKvgKNGfSovUm0nlBvod467G2ypOBDfQS+r53SzSs6BCHyIUmdgI60Hxvw81HiXFw1AzbcxBN7w3VXd5TKseO5jz2c2MRYA4y5IOdr7cDFNmFBFhX6gc3WjpM1I9S8CAGAwE7eYez3d93RB5MLISrkU9GO6vzi+mVXV7ZNJdfUxQ1l6tmeRaUUAL0szowF8Aob9B+YV+6W6y6xcWKMs4n1vVwhHzz\/7DNJbGfPfXTh4k+3mjAO87lho0cu+OA9F8OKcrkrST2v2xNRsZBDcmtNikzCBN05Xh4pX4m2sOfkkRN3HuiRDsAqsOWKi02u1CmA9ax7stfbBX0k6JO6BuaGpMvoDKIgAEU9+\/XRgX7soXvRwHPPv\/DZkmUeUFx1mw8bMv\/tt194aX6SwPKlbS+9\/BJpnZpMMa9YtiSpVn567DHF+rpPF3xMLkYXg8COkyZnHV2nn3rypJ13qKurxR5341sbHEHw81G+LtpxuzFTJ28f5VSSQa4YZY5TKCbQI4UeqTSlrjG1DZltqNhCKqg8P064pbXLiwrG8ZRJO2SVrj+dd8nGg0eut2EfgTTw8yA+GxBGHUWiPUTt6aBU7XCcKVyDvOfvLASBwAZSzXNH0bUW3fIitxa4LeRqyNWCa6t3y4puedG1hc4qsbDK1QdIB\/nOrnLBx945INbazzXkCwKQOGMBCIMN191g9XVpzqNzExNnWSYWQi\/QRFZsbBM\/CjPLmlTg+bU5UdOIA6skyUaMHPaXN1594+WXigE5wZbWjricHnv0CfmGPgs\/XUI2iZTElTIKvPDUo5rg2dff+Xhxy66TduyRA3JWWLhbBLgqOOUf0K3YZIQvfQGB9STxuBy4jtC21dkVRdsVuWrkynWuNe+Wh9wWSocHCUFWW0m0p7VS9T17aq1vue5KTiAxogpNIJqz9KH7bheBBx9+ckFLacK4LXtGarNBGy9Y8FGlZNraKoiqUMhZZ3zfFySLmkGD0NixY+a\/8uLzTz2hlBblL1zavKyt9djjj8337vPZ50uMjYVjjzQBPPvYvMzAnGdf\/OuiZZN3nqgt4DeyP16ZP1uT7pCAkiyQsi8dOe7IuQ7NbXnXluOOHGd5bgu5rcBtOdflc+ah6jYIRQZkI2Jt+tJTc7uWV+e\/\/tF9817YedJOCqtLFn182CGHaK\/w2eLlvlaVUjsQbDRq5KvPPLVhv35\/\/WhxvqEXAc+67uq2UrViYc7Dj7S3l5WCSqnTCVKu3vnF9QduvuDDd9uaPweK7pvzeBj5BHb9DTdKMr79jtsqsaioMO+RxyE1dVFUbm+3cfrJ3\/7W0NRj\/C5TFja3V0vl0NMqzA8eNXKD3tHll53+16VLB0\/YAQA8ZsVfKPrWJAikZiuXadeew84QVvhumW9W5Gx7aDtDB3lu87g1z20hd3nCSjIEIKJCsR50CI4GDx0eKudLNevq+vTTBaoY7bz3Hp98\/mlbZxuShD409aj\/7em\/Pf2cM5zWHy9qtioMcsWfHXvs1N0nXnThuR\/8bVHmwt49ej7xxKN7Tp1aq1o6V8vYodVsfL95fEnMpDy\/djAZMHBwNSh4oarH8uJFze\/d8eS2g0dvvOH6yicH8r3eRRFpaWkJgmDx4sWLmuMP3qweM33qnddcEen6hQvbdp60Z\/9Ne1oAC9UQCv94JkAh7XxGT0mNi+LXwuQFmYEs1nzWqNumo5vOQbCS54OIaZoSogCBX3\/qb\/\/w+O4HHrD7hJx2Q0eOhfYlLqkQFnCtCyNWwiFkCjL1RReCAVLNyjFaBtAOtUNfMSthEBLQDh0AaaDQaN\/6ymkBAoILzjnrlptmAecyLJx7ydVbDOz3uJ\/WFTFQVpO\/3iZDbr9\/9m7TD9lm1FCN\/gVnnz150gT8d+tC\/xm+zARjlFpsLQCAYgocadAA1iEgEIgOnOcDkVDNq06QnbJGpVY7YJuUXD5w\/YcO+dFRPzrv2rsmzJs3qG99vu8GQnnlqVN\/+982KZ120k\/iE3Tg9bjkgrNmXHTJzBmXOVFlDi+YcfumG\/dryoZN2XWv3\/\/+j48\/+\/oNF\/+2WCwmlr+1dhAJhz76DABgU7GUv+f559cfuyyXpTWD1FrcgbNVAFBeOmzo0FBBXO2IQiiR9pt6iFSyDLQqoBQ8JJs5J0ooVFi38XobPf3A9VOnThk\/9H7W4aZDt56w856Sb8gcuKqTzKZe5iLMhNjpuihv43ht6YV4pY+wx9wjDKWr2issKoCOjB5\/9YORI0eiiVn7jFCTJZAWY+LULNnwe8M0NQLEIOH3NszfO+vSAw76wdjhT1iXXHvtOYUePVxaffW5Z0aPeiDyo8l7Hrj3AdOk0DH9BwfePve0SePGDN+kT1mJMl15BcoyMnkOANiutD\/+1lDbrxCAWzkfS+VyPh9mcWcqdaSxM+4wNgGde\/61v20+akV9kLFZweQ51A4JgEJRRPGYkVtGCjwCYd13ow0PPHj\/S266a5sH7h++Yd+6ft8rx1LIqTPOPfuPHpz088MdRc7krr\/qEudFoKMIvcEbrTt19zEXXnTaxedXx4yd4EkmNk6paf0NBq\/bWKSOdLsxm4FZOykrjKTCQmzEVTs9ImUTTVCJ00eff2vU8LHeSpMSABAWAEipVKbFg4eMNpzVN+XTNC36euSQIX1792xe3j56\/Kj6XI47O0sVqGZBKZYmL2f8gqEo60qxLouTEmqrbAapoi\/per8rD441BEGwCozOnMqY7arXGmsFL9a1dBpgUQCKNbHvwHfIAGBRVyCI6hp01gEV+X\/svXm8ZUV1NvysVVV773Pu0A0Nir4EDKAhKioGY8ABFUeQoU0giAwiYAj6CgQHcEAEgqBRFCXOkUQiGpRBRMUhxuTTJBoloEFj1IhoZFB6uPecs3cNa71\/1N7nnnv7NjTQ3YBf1u\/87nD2VFW7atUan2WpB+k75dAgCrveCsszezzykcvypSYhDaMG9db7UpsgqZaCzWiwfgFWGEzam5myZ593dozNm0955Sl\/Evfc+\/Ef+sBfHvKcvS++4M0Xvj38\/t7PXDndY7+GiUKov\/cvf\/\/kxz+uD3r+gce87IjD2KMqjTRWhUFgyF1BdbcqylhIyUXRWXJhZgWIlViJEy1UYs0ho4ljMt67aCRVrvQNPWqvfS75m0sPPfakpzzmUaWbfef55zxmx2ln7Pe+8ZW99nz0CuP+8LATTn75y9atXXfUEQdfe\/Vlz9j3ub\/3xL2bZuTD0BpjXBGiMtgoC4YXnP8WFf\/6V5\/82te+\/vf+YK8LLzj3wNV7n\/XWV517Ye+xv\/f0Xkml9WnUGOj1X\/\/Snns8vrR68GHHvezow53CbI7kLiXUDrVF7CC8E6O2Uphoo7IyYL0BU20wTCaKIBiIwkWUCZXAggIjgBtXkEG\/vuOgZz+1GY32fsoLT3\/dqTts13\/hCx974UVveed737bXU\/a3IJPqN73pnKs+cakpH8LVir+67OOP3H3Xv7\/mkhcevP9eT\/p8NNO\/\/5T993rqs3zSqqqMsyMfejMPOeXVr\/u3o4479AX7rizKxz7xyd+9\/gcqo8ft+eTLLr\/isONPftqTnzBfy9OfuPtz9tkjgKatbleaY4866rDPXfW0Z63e7dF7Ts\/MFEUxbKhf8WEHP+2cCz\/y6P0O3P6RK4PCiM0W8C0sMCwgIysLWQUSNIBzAYZoaMhUewNHLBwN6lKHhQ6MRpCMmhgFvWrbgw9e\/YGPXfGi\/Z5y+htOOvLlf\/bR6176pCfs\/Kwn7j6z\/cNW8ujn\/\/Hdpx7wLFO41Fu17377H\/\/y4y668C\/Xr5lzKE4\/+ZXf+uq1L\/6jg597wAuuuvyTtpjS6iHvvvh9oxinp6dDPbIKI+0E2BJkgW7p5XxIn8D0\/NWHPtvCIiL98sc3\/fSvrviXg150+MHP2iMCHrCpaX550+mnv2b9nP3yF7\/wtKc94Q+e9OjeypVvOOucw484qlz5W+\/84MdnCEOEHjYGys5EDjn0UGwwK2uwoVjzrKBQlEOeDaYpDQEihBqzRmNbI10LRbHTzo\/62levGw6TVsPS0Ne\/9iWylbAZeRZTNA1Y0wNqNxFwJBsZQspEDAlUjXgWDJYCXNQ8nRN2R7zCcNVIajAFLcZVRzK97nVnnHHGGXMDpnI22YJi\/PO3nk2VG0RVa6vp2d12f+yN13+LTdV4OGPuGr1xC1F2dhFhbJQhhVOwImCasK2SJAazbWiGpWStgq4siAXc0HSEVUJgkHJRWaUG5cpXvPKU41\/xppTYUeJqak1y5FH1py5897vfxjahqn2v50j3eewr\/\/RErWbXDhJPzaZ6mJI58+zzT7ngYYlgGZIEY8yiLTxDGLA5RZ+gJNP96tGPesSqf\/7mVVdell82AIFt6jQ3qKHl1NTUTjvuwAkWKQpmH\/Zb1331a\/XMbBPxrH33u+GG789zr6zMy0886dijX2rctt77PXbf7fs3fNuU01T1B4ABjnnZiccef9w6Mf1q+rPXXRMb39tmulb9ypevYoHqlg1Fu0sSVjFCErxNKY4CAnZ\/xEO\/PU1XXnGZBTxYiUlFUf5qXbR25XRvxW4777xiukBN3ttef9UTH\/fYH\/7wpl\/fWVe9YqoY\/tv3vovgX\/vaN\/3poasBDjMzQnG+0cfutc\/1\/\/b1eiirdpiaGwxj2Q8+GaTOrMVbqiDTppG2ZYZpMBiumJ4VJcsoK1ITH7HzQ6YqfP6zV5VubjRc62wZUXmaFq3C3GjVyu122P4h0wU4ICSUK7Y\/7TVvPOnP3joc+pnCRte7E1UJiOpb\/vycsy44v4m2mppCQLPmls998atm24fP1XLBeWcW57yWYV1\/xZ2DZuVUz8\/98v\/s8qgXHfbij152xVN+73FTBhS3nttwkprGJ+V+VTSND\/MNGuyx68O+bEaf+ruPGwVERTUheTiv\/YSeraZ22GHVdFXVw7my7IVG6kif\/PTV9Tar5jTV6+a2rWZe\/srTjj7xzwbTvVGMp7\/pbHp9rFbMDNaPrrnus03TFNuuHEQPxRi6YPMYsEgm+fbi6bbcZr45z8\/oTwwICEIMhZnYCKiF4JWG+oZXEiTXZ\/CYZbGktqGVhhKx1Loy5boWxKLMEIVdsf2OX\/jyP5iZ7ZsmPP3p+33n298bmH5Z4P+efMr\/PekVrtqOmff43V3GfGkeMISjjjvx2OOPq2F71cy1\/\/C50Wgos1hpzFe\/+HlNwjkZiUTAKQpISzZnn3vuee\/asWmwTmNZ4IK3nnPBeWeNTL\/sz46GmCnxoxvWOravO+WUo19+YlMjNU1BIs0ghGTYjSta8sbrGKJdjGNNTEsho+IxO+TIBIC9Ut6dI4ohrWSCkK1pOtfgE3Ainas9EYVhetxee\/\/oP2+aGyRU09LIzdf\/A4m+5cw3H3H88erRM6CUtp+ttt\/7ST\/60Q9HkqZ60\/Uc2CL1wnAwb7kHMNQCBTidc\/afn3Xutg16DdvKpXPOO\/P8t50ZeCZgmtmZoLd8939E9dRTT33ZK\/90OMLKHkxSoxGyGdavAAk2kdV2CoEUDfdHvNKwsrJQ4WlawEJc02xiG9jVOi05HAvoyl\/y9r+1y3X\/8I8op9c3aEzfFCiMV7\/mne84j\/\/ibT5tEzATGax40plnv+n1byhmH+oj5kOoCn7c7o\/6wY3Xx940uW3uHMTS2rKQuk5NGhVVbyB2h9\/a7f\/7xteRBOrqSOtF+1MuyNwT9nzyjd\/51iDwKPWmTALdevxJrzrqpLe5wjbrqxu\/94M56gvzVAGKmkZrEdPBB6\/+4KVXPOMZTy4dELqFNv65xUjBQjAEUnieGslMZkKJeWRmFTYSD820EEA+UUUqTj1DVHR6drqZr5s69lZu\/+Uvfs5UxUBDYP7xTTcAKIkcm0Q2iXzvph8GZV\/MGAnA\/EknvuIlf3KOdXCD+X\/+5j8nS0Fx3nnnRTWRp8CQVDe1txjXeOUtlG9sQS0LI2JNQsZAFZx8HK6du+OXN33nhz+9zfSnt93h4bWiItQRjol2\/K23nnfuUae\/98J3\/cVjduyn4bprrv7COy96f2QX53991WUf5OaQffZ5nNmwiKG2+K0NcwDqUd2f6g2aHUZmOwESFYl4732fM3Q7RFrFXVyjEXvCSw6diugV0NRTtTFaBWxpPByKaVYWEATWQiC2Qq5j1T10gV\/TVs9RzVsCERguGQNKVmxhNNKqhqak7EMLKCfCk\/bZT9gNe7sMUkOFSYniKBxy6MHeCsQzhClFLSXBVVahlBoQAjNCYGKJMUBAKK0RpH7JQAQ2U1Hue0ikoC7o2nCZPByQap2zDzXuoVGkCZ6EiqJ86r7PHTXuV+Hh62U7gBOsUu\/YI49NYtSZ6JMqpaQwM1bYsgEMYpgmQowEG8Cqloh6LBCx5UwkEY9+4WIMhTGJZwmoKCkxNKjmAkpEIBB3IDxbRM0nBXwkUp\/IVgj+13s+artLLzhJCTk0KBELKlc+5N0X\/c0uO+110EH7+ADW4KhKEokNsXVNNKquqlR1ihW+UXVFOSPQsix9jOymkpKOApMlFbIVoZhmgk9JYQo3Go0ETGoV2NIgSMvHOxGERCijE2pM1lW9ZCsV7POoqWede5RRAWRsOYi67YUf+Noej3\/q7++1y2wBP5qrlDgmjTaWK4JKtU2\/SjWG61dCKRk1lfb6TqLGBhBD06MhyFBvxo1GI8uEGFiTYVKmyEAW0CYyRBb+2nL7TWtpBZiIiYhcUQFS+xQMmghXJNDcY3931SUXvlLFRQrGiQsjLlesr1dd\/IFP7bzX3s973j4FoyL4GFVN46cAAVy\/dAlAxAxHjGBMobACOMOpEWgqZ7ZVlTT0PcASK1UqPBo1zpn5wZpZhztuvfUDn\/rckX9y8sNXbY+mhlFsxfT0TKyCWKcoiQmmcNKbAf5g1+mr3veaOEpG4ASJBTO8Jk1f9LFvrNhm1+c99UlOQMNYoqSGIMV6YhiEgTgyzs5KwIgZjk3ElFpmZirDSAtXRQNTFiGJJauqPGYCm4VjLr3J3XGYLXD+ZEE0bWs4AQArCkJVmHVhZSxXxdjWB0haPG3f57Bx82anUO3Y1KFJnBSHHf6HpJLdJkIGXLLh6GsDpqoHoGJBE4l7VJZRIxJIGcVUUkp1w2QBIeMExoGjr5MwFUa9V8CSZ4trPnv1615zmoBdWTWj+g2nv+64lx0tzqmvlXmKmUSS7bHCkQ1NBOz69fMSG1KOWiZBmYYahyR906UV311IYbbIdJXwCL3eNAJmGvQVQ7PDwGzXhFC4YpBG\/Wp2n2c8pwl2rdtpQA\/P5QVHAxx16DHiORKDhEw0bnYoQA21TpM44x3HENI63x9GzCqKphGtvQqrVaCw1oeGnIL4y9d+7lWnnKxKGtHrl6eddupLj3kJl9OALYmtJpaovMKLqFhCBCmrZx2JJLPioes8Vjkt\/NCo5NSaCXlxkr\/dg52OYFksaU\/JGeW+YkU1U4dtyG7nc0H8YsUAACAASURBVHFGcIJ96r4HEM\/O86wjrEcMqq6wRxz94sAgsBOQ2IhCjGhM1jpDSRIoJUY\/oGBlZWsQCAwWKiuUVS0exL2SfKgtCue2YWFphr247qtf+soZp51ubTVsSFC87vQ3Hv3iF5NECxFKVPAsGMkLjFeCUg9UmsgqSWeVBJDgoymrpCgRRNgmJ5qmZlbGZv6Sy\/4+pJlD93t6NQrOkNB42i8\/RMugzWz68LYJURC22i+IYRPUG08PFbvSN8RFMed9Uc0++ekvHPrClP9nBAXECIyPhx+yOvlgrBvUgY2h3oyHAAgEZuey\/qfjtDAxQI+qkjilRGDvC3BVUYKCe84jSlIlNuwIMBQAwGQnoGobVLOlAkkmndHZ4QgQlLi0BVVTZ519\/o9uvnXPvV+0046rAKydS1MzhpSA4hGPeuyuu+1sOBS98qabfnru299x6IuPOumkk757443vveg9\/\/DFa576+3sQ3+W0V7zogAMuu+TTV372MzmCXAijpi77vQ+\/B8kLEWWZsUhy5Av37xFIMKxjaR3acdFEDLIT\/EYYHovzUB8IlNFvAJAKfDxwv2d98uNXXnHVZ5Ipu7xpjEajD1\/8lyGGouqrUvJhtiqe+4ynAFmGS0Qqbe1YEDSzWzEEGAIMFiz8Btrx2S2bgblxXs+d3Y2JyIem3y8PfsGzL7vsmis\/e5WqGmudtXVdJ4mXXPw+FzUXhwHAhp\/\/\/OdbziasXN3ZYrGdspCMW2AEhtSQAohQSOc6J4VFW1MZgIUfQ8OxbsFIx8WUpspiXoXF1CPveYWVZNQLRDggV5fXcv3cyMCoNH4IZxJTJGVQkSOorMTxIJtWu2YZhwfkkp0KguQqsCAWMHXqpwAkbADNtX7vj2LqrGAVqznWluvaz0cBFaowcKbL1+dxYqX2KBn1cUUPnIYEL8KWHUBRTVQyBCExhiXG0hqJQQElsdmHrqViHHFBAKxGMKCktIWhCTaJzETV57ZseaGwVCi2ixajhlXYc2FIVxQ8HCUQe++npqqpHgZrh9OuT4iEQiay5roU21weh6SDCSLyqqrECjIaTSuPtkvAOdPU8TWvfvXnr\/vKPgcdd8KfHsNRS2fqFO8XKIupqm+SBkaILvIUGTTRxRALnhLiyBCKdYi1ukFDK5SNwramX87W60gFkKsTI7OCRAqC1Za\/SCePp27HY6A7uOXont5885yvS5w7WQ+GTBE\/7ylPuebKL15++eWmcOOTnXUffHcdQyh6VV3XStzr9Q7Yb19GJEVSYWYlq63FoZVLbMeXxgFQ2m38DOHMlyaPsgAwsAYQSgwcfOALVx98YBTAMJLEGOuoxjhlANLGxsDmWEpSsQ4qzLZkWxZF0bMwjlUATUoGgCptAq+TnL2Q27Ru7dzMzKwPYfXzn\/2Zq7\/wV5d93FrrfSoK533o93rvv\/BCZyx3VecsaP9nP7fvYAgpCcHqeLAVTMIqCh4FYbaWYJOw+IyVp9zik4LEWBNDc9ALD3z+c5+XooQQe9N9AJJaCZJVMt\/STlRgCEEZ0avCFSIy04Oto5UIElXGOITsPlCbrtPtNT3mZ+2zzzVXf+kTl\/+dNW58f2fd+97VhJCqfm9d8ABWFtUB+z0DAJQ0gpgTXFvoHULku5bZ8TsFYrcqu4Pd68u7v0kwFLftFYfs\/9xDDjjQBwrRuWLKOHiPBNudL10gOkOZVE23b0obHy3Z7QbAqBiVelgXRfHtb99wxBFH9Hq9T3ziqoetnC2sRk3YOkHtJOvWz2+zctp7HPy851x15XWX\/u3fWJ4ehUj9sg6+1+9f\/I6LnGvXqZPYl+aQ5+1XliUDKakQwJzQ4hxwVxIQG1gGDVrXqKAAwNSWU5usWssA61J75RbdDhb8IePHjQ\/1ejt8+vP\/pDCBKwAOQI8dALLA9La77HHFpz5uQQAevddTv\/EvXxeCY\/vEvR77sUs\/KkAI3sDabmgmV4VRcZCe4T858o+Mc8e9ePVYLmya0dRUv2kaJGLOeWTMCoQwCqNt+r0QIe3QLpTEzpdPujpajAjttpplOriViCVD14nRmDGYVdKfHHlkr8fHHvrHuZ255Ukkaooh9vrTTYAkWIPZCqORz0FEohnR4x51YavrY633iQGCJgCNH\/Sq0lqc9PJDg+L4ww40BsxwBusHnoicM5Csh0A1JUlMJM1I2TClLSE6bzWvmI8jWxRrfr4+Ne6FR5xpRABOxnszJywm9o3YEigNjjvmd6kUpLiFUqjzbe8X4ZIgTsQKoMxqZ2embrj+v+pROOwlp1rUnRCTEW0BAGpnq9nHPOYxhpCt8tLGjgpIjIJAQoxqu92esN1NN15vigr+QVKKTichcTqHoeCn3\/uf9bf5F6w+01oSICSNpJajkZFRccU0KXb8nUePIoqK5gZ3Oq7u48rOM0F842zx9vd+6M1zgwZTFJAkBENYmui1dYiboRRTxfwo\/eCnP\/91KA449rwYbzVOJBloGxUQYiyrvqA4dPXO6IRaAEILPq5JjKBJm1T+W\/JRkvGZ+sAp+Lo5KI+IUg7fWnrUidTrmj87\/miRdMyBzyciNpxjk5hN0zRRAxtTuAJsQggWyuITxJDd7FmXeQ1Y6ySJMdQED9GiKKyxAEIMS7tGUEmIjbX827+z57dv\/KE3LN6zKrkpALRM4cKNBWUxJsKeq17lfQDFlx5xaLLuj1\/4AmvozjXrtt9uxXAUnHNj\/sQKApIPvcJJ1JS8M5orQY9vTUoE7L7nk3\/005+PTD80gMbEhmGVZFyshhQKZWPqemSMLYqi358ajYYA6O7w5b3QLr\/7hO\/c8L3abhOHQkiJOVvZ7iIjZlOplZ0EFHOXB\/N45Z8eFRWHH3KAhY4bZ4ypfZNE2JTsSiIkDwvYBIqqhKR63w1\/QqJKSIUSoFw4F1M0nEbDYJlhWJXvndZARN77xzzmMTfeeOPY5JdSAm8d9iesMltZCqgULzv8kP40H\/NHB1lDv17b9KfL+ZEv3KIEB4YgNSumer9es6bX62+VRm5ZWsgPWUysQl59YaZ8qA3DAARUtk0Uz5hDykHYxRiJmBiOCgCGM2q0EU1WMeFykQlVREDRkOmVlBAAWBArmHm2X6bYmOiNtUSkYKEE8MCHqamZuToYx7oAeSQAtZgMD1gigTJBGGIUpChJYxjWAYaUJjxGBrBJTOFMFG2kX1kfEIbqFMREZGKK9xhqdovB3TAvcLpFuz6NVfCsk3NR2Kh+NBz1ez1fN9vOrrhz7XpbllG1B1FJJlpiGkN8JE3OurKsVLWuw5bxXWylCeOjlD08csdtrr38HSG1cYnJoLbQXB5IMG2AhOTrUb1uxj2wIM42F6lq59pCM\/J77vHIKy9711yAtQuasnaCLwtcQpExPSFgqyqJRQgZYjVjzont13VdlYix3spgDPedJpeMUX3q4x\/+hb979yBiPoJ6uegjnEGvwNw8tpmGJDhAJJAVwmZz67Ayu3I48lV\/piQ3GM0HUWOL+0VfhTKZ4tdrPFXm8Xvs+IEPvqU3jbXzEMFUldF7IITKYjSHvskCksg4uB9mvBHwhAwhslQPoQk9JEf\/LiOtP5hp8vXlmIpWz2qdhNorQOpFU1VYACJN5z8NZKTfm5qbm+8VjllGyff6vaZpmCwTY8vgOKtoVKkH9ew2K5MPo9FIVavl8B5ZAaKqKofDIbGzxjgKSZWZWwwDVQJtQiOzcsLjLOGyKkaD2lh1jsGSkpSFK2arMD9XGeOgIgJR1VZx6RVWktfgp\/ql9wGLPfYEAjiQGflQWjGkTKQwqfW\/CQGsEIJhdlXZjOqmacqyJ5LKshSRpHfTCzJOmEWBMNd3FakqeDPCbwhBKDIiQwToFTnrVgpjbQqamrYZyn1Nvan+3Hzds6UhDFPs96yvNcMPiCQluc9hntz6MAj9qlo\/P1dWRQhNvypahKPlVO5NIWttVkWqqhIRACklY4zQVoIsZ8i0dUm8NWRs4EApJVuW04VSaFY6ck4zgKGI5qXto\/gQV6xY6b2\/u9s\/CMi26QNZk2i1DBAAgkUZAeMqaCQymYepggjJqCF2KABY6wBhEBAFwmAgpRR6RQXoUmcIqUggi2AkGiSS3IB2AxEJajQBxtmi9N6jBaDTXq+nSEVhF5VByDaH3Ohl9alWIp60DdwvBmGtqiKnzZHEynH2ZxPZcexZPhqRSIhEpiynOpaWc6wRExEpSDcuH2xtBPxFtp+lPIahLEldWcYUkySi6GwMIRhj1o3Wln1b13OuKFUyr40adRxKREAK0khKKaqqdiKFTGgkrc8RwBIb\/4RGujHJVCmhmxqdOLc5o3XKsgTAzEqFxOh9mLEk3haAKpwACcGLshAxKzgpq4CEneWuO6pKotoF3tCEBKAT0TiTO1\/+nnR5\/fB+I2UlBIqD0PQc181cWZbih6UUDgWCHW8eouO+gxVMgTgpRFUSNEud2hq3GeBRUCEbhiNnSNmIapdRtmD+zCMmbdLk8psKTwaPbmGLRlmWTdOklFQ1pXbWsTYuVM7AGfRKKHmCWKkcEBoUBNfAsBC8aJOIFAQVWhx72rY7z40JGwEEqqrKop3Rf8w0iYjJN5FtFRMITWVJ0DasG7TNTJOrtYsNc+1rIgRS4ywhxPXSV5fWYIWBA8wQoFQXg8CcRv2esGliv7KZcaBlDnFhvehkaSzJy4dzUhhl6AjiifpkmwXn9IFDk4PcBmmIHQ3nB6ORMjFrTNkoIGoEaLHjiJiFQWkwalzZS6Cm9mRs4xOURYVMtz7HD9ocrSWiICmlVJZlqBsAxhjNFc2WI2au6xpA4phiQ+KIWDjHZN6TFin3ijI2MUax1g5HQ3BiwKdIQsa5QT1v2JjCiGpMQUOkriQaEUlUVXKVa0LdZn8B6PYpZoayKFlrNdQ252y0gaMgVVJRgjIlEdSByVjjYggZC067RMZ81xyByYu8dgwgqYFGlsAL++cyAzbZ500cG0GCalFaQAwohoZdIlEVODiGEe5pO+BUlS6F0HclUkgNeqwSkjX5eRm1jIip5VL3xM+gqtA8GoCwMikw9IGs1SjOcPS1M5bupS8EAJjZe5+50Hi\/4FxPuBvTjUlX92X+Rx+yFmHJNvUAACCkCrFV4YKvrSUAklLjR6pKZIha5681EpoRjDHMWTduJV3lcavaCIi7bMOmrZdWzrrnXdwoGWOkwwslIpvbsXhekEITaQ521Fx4ixggUs0CtKoqtdkI2saKEqCc1RQliMIooFCFjtFpUoyhKAqy1qekpJpiDshRItZOyUmJRJMxKUUs7K8sYkg1pZAmIlcmE1A2Ok6TY30\/eE4SALAji5FvDKhwBpRIGUTLuoyFkIsf56rSDFAb55s7+4A2\/WbI9vyifQhlWVoyIAUlkIhAyVhmw2yJlFlJLBllneiXISLDRrOS0jFfXeT1BjptJAcEdwdouT8XtxDAltTbQggiMhwOiYjIMMDqSRPAkGRUgORIRQUZA6h1B2aGv8WadX8RCQjWWmLt9aYKx957aHSSoEHRGwc9j3miaFIE4sSCNn9dkf2iQN7ZJE+BcYmL\/GuRLD5B3Z2X5xAyuaA2uHbzUl3XxpimaWJcSPuBJJaa2BTCyiPReaPiUs\/qNGBVQplgJAnFABXmCDXZPjZxZ538vagXrCrSDlH7vPGhHHxOHby2apQ2tYwFW6TKyuQtSVtVJMYEIMaGpxKQHMEIWDQRqYEFCo3g2nLdGERli4I5VEwequPAKmXplHCeWPz5S9XxfGmbISlhQcN\/QDPVe0dCgGYDfBKVqf6UMRy8Z0OFtQCE2VgDZPEbRIYVSViFrDUGzMIZU6EFnmpDdXTRI+4ztcHJzJnto7PKLWtGyeFPZFySQFaUmcUSmVyDvDXwbdK8ZQCSUFVV8IHIiAgoM2QFDERVNAeBkwgrRMZSDyirECoKTguAQkAnbogIIDk+SlQ4y4tQAAokVWpFJ0ZXHm6yYo\/q2AywoF\/JxIrn9nvqeJ9ASai1+0xK5YsxuDf1hWUzXV3Xw9EghFC6wlAAKZFxxABn74NAiYmZWB04KkkiAZEhyvDHY0Px+G3qPdRDWJGgBAiYmAggJhCTwpASG2Y22USrS3f1SR65KGpjciTZGGOYOc89IIv3TDROAdgigdwphaqqgvfMrEIgASVVVXUqRtVnB087a1RBSbltkSqJCqkKDHX6LRajEm1Km7eQseluiYiYuWmaVg9Z9qQu00cZCQSIy\/luJK351QmI2inNClLOUgEEuewHa\/Z15hEcO0Ngiyop5TRCgAHDKqSwyqQJyHEXkliFo9CEOYQM2mfKpC7Bi\/a1jYSB3s9RW0Yo+VTXGnozUzF42EQQEkvE4w5kzquUVywESJHIgpRbzktslIRyeNuGPXqg+EOIAJKoYRRGEqiuh9Y4EBElwCgcwRlYIBXkUo6PNaxKCyHaykTElpnipB6yBPpr\/PXk04U2is84pi1d5HI4HKaUpqamQghE6gxD2RBRXvNUJEIyI7ASq8KALGBVDYSNqlERElVl4WVr4m7IW9v0idbJls9kdKa7BaLOpbQBv95cKu7kfSf0PamM6dliMDdnjHW2h7wxAwwjpPmshfQQJYUQK7PNL1RFiWmcesREBDEikclTQdbabBuZ6PskdbLn0u\/zaJiJHC3ZKK\/Y2Pd3ve6W6rwJqa7rlStWEpG1FllmMiAFrBpKDixcAZJKJpOI1JI4MladkgNiNGAwK1uBTCYXtt5sweKdnohUGboAXUAL\/hBDZCysMwkgIZfAVhsCFJwjR+6iL3fd000hQS6MToN6KEnKKTek9cJJU0nREaICoiYQ5bIrKVqToClAVSWqwKR2O1js+OqiRnOa80TOZf5+YjW1e90DDdfkPlObJJCTf1kNE6lGIoopzfZmQj0CIJIgxIpW6CUVhUpSURFLIIkBTEScBR0xOQV8M49Vfh0pJebWrZG19I25c5mZVUTEJIikCCgnnpDXN4mUAY7BD4fDFStn6rp2xoKiElSIyDkuiQwTs2aECyRKebpmPwYxCZSsAcHKgvKTlZKu8aLEiQrAMAejKU9Qk5lf1v3I5GmpokKJDQFQsd1aYpB0vH0p5zeaVNmjhK1Yk9ExotHGvOKbukLzxmJtURQm+mArinHIKXEs1baaUlaCQKTOiMSEGI14FQPKXsw8yCklhhB1yAF8D7hEXtFZNJJu8BmMlEihRDGqGk08qbkt0KboIVbFe2+MMcZESQBiSlYWTfUtYZFJKcW6XrFihY\/CtgIE5JWFqc+GGSmrRZQyXo8SEbgdw6RElMgQswGNQwUXOcxomV1+KfH9JBtnS9z01LQPnojojWeejQ1kykjqKVlrOCVNSOKccSWQUvCkREQpMrNay9ZKU5PCgAyRJGHDUSSmWJaliopMRtOgaZpe6ZpQa1kaZokBIkZgiAFhhTKJpAQtS7co9I1tVqFGo5FzC+qTWVhXW1sQ33QSkkZ8b3pqNN\/0CpfiQGJgKYhMlhgUICYViikRZZ0fMSZrDQBSNlmQT6mTkx64eohmfwh8VVXJa7+c8nUDCJMnTSoOZI01dV0XrlLVpGBjRFUmZAFiNsakFLqYigx0scya4SU+sQeAP2E0GpVlmcMMmtHQOQuwATuJokgoEkvkUTQRTAJmFIBNyqQoFFYFENHIanNVYABOF7QnQZoYqAVG0vo2F94FG1h0bwRoo8OzKrsAhNJezFhs3VxkRVswJdwF2xK0ECUAyYJ1iiKjndI+iTGGyMQYDbcgb7lOM4Bc1lpYBAlaE8GwFWKoTVDixK1Rg4mIIYQoCbXAmMKQqiaa0EIn9Yq0AJo7\/r6dKqRL9JBxX8b5bNz9uzFaBE2zWJPppPMuh60obF3XrBxCKIo2+5BUmBMMK3HM8TIkqppjlJOXHsqMHhcQo+OYQpkmt0bGwltmoM267rCMjKoKWLu4rAkbpQG5mJIzCpJEgCYjDUgENinxOIt3mYrULJMGyM5mtHReAcsovRNDpEyiOoKZN71YTqXSpihl7FmxpEhQcYaIOCl3byElBRBVelWhqVMkcsTLWNfKfdQsTOTAhWyDZlFtq+iQLNhohYDWoNzNhMlYTTMxDqn9ZrKLNHbSm6X9bTu75KrxzTdmFRnH7HUnTN52YQDb04RygYcFEmIFR7I5Yc+QWqQizm1LAxtrETBxkmSNpUnXEImmpKI5aD6EQEzIRX0AsgZbwIaapfCUEhFl1N271kOIiKzRmAqmKJoIRLbFV70HbWOAy7IcDUfE6r2f6fdAMedDG3XW9mIIbLIhRQGkmEcp218pGRIktiam5EQmzGWKBY+cCHFgSzAsgTR1mDqtYZvJEBFzTsqPgmQWlL0F21DH2xdJ1dmhk5RqQVFULIFVNvRQ3Ts9JMc1KNJwMJia2taAYljPKSG50vRAkjq\/DRE7Z5PESMlbiZIYbGAAy8IAJ0mc93G6V3FZgIgoiwDEbYClpmSEiThFMcYSa2vGXdKLifkwmdE6+b211ntvrWXm2OaHRGMsJtykm10PyS6XHHYuCe17Ia+qjGnnXIoDNjkeQFiRo44zWxMgQUWEDCzZibCshSJIS\/7eGG3c7rZlaX5+fiwjERHdsqYeH1tw2y8gn7WyBTJ37uypLaeewCNfTIvy0YGMpgpWcUR\/+a63n33WmZvQ1GXefNcqWvLNkqcuc8X9TNLFfli0oypLxJe7p9Zvsvkbt3lJFv3miXDFXDF3g17fZY\/unRX6AUTjt9Y6scdZWAJIABRswQykicmavYJQmxOSCeB8eNLc391nI0PEjE59m1Q3EPPco+5G47IJgkXpXIuM4eOwptYLuuxD25fbYrstPYQNXxqP75RLF49FNRYgQrOp20IKAOAICKSbP9SGgo4LAGTnaIfKKhDOoJwCpA4z1ABGAUJAW9ts2Z4KLV2hYyF4SZc2nM86cXTcHO5ulweGF18iiIohAKACrGlP9xNtsO1NCRP9FSB2RxltZZh8viRIgDC4gM1ZextbStq9+m58Wo6tS+UFmRgEztj0sjDBBS2EQO7dojm3lGjiEEGAXwEvefun7+QVIiCxrMytK0PJcPYVGxEnwkBKUEIDcf0iSepw9hTK2iHdGxA6eOs2pkglb0Fo9TTp8LI0C5VCnNgzxCZmSDCxi5dhRYGccEIR5AFACxJuc5YIQsKIAJN0Z463RYrjZy34r8bbf7u3LlkaAootwInarHu3PydfBEk23rWpxJ05ptXqFUIZxZiNRoKo6EP1jsvfcNCMNOBSABFkq7t2qxCARqgqWwJBYspW2C4uK7\/xhTd6PweS6mbfEMczfHGoyEbm8HhNbXw\/EkGLXnVvtIFFDVvu6glmu3H5Z5LuqcdSJvwXi7eTDUeecmfHLbLLP++uZfqJ245NQeMXPZYusrll6QS4z5Ph7uTJrjGb+4n3cD7I4nZu5OpN0Z0eGPKkDTyRz7dBolNrbCGgTWVrO9xhMkz+u9zGQ6DMpjNnJGFKm2yxXnLeg9pvvsQTeQ81kAclTVrv0IXnbZyF3St6gGiZm0R5jbRhUa0LLHOQnHpmeBHXHf9qNX9awnBlsQi+QK2VrZPLxwmU1EnDk5fwohi\/VmLeSOMXEWNxWsXSprf7xNg4txEcyW7XH3u0SLohst3RjkEtgsXrukYTsogu3JTzUCsDwoS0gcCgi66YuK7Vz+5+TvFym\/yiWwHjynETZy6986T6h+zgneCfULtQCiBPlIlx2EDNbJ8rsNIqnHdj7prsRTfFON9zqftj\/Ftzx3hRHTiAsTSQa0FjXJ4WpmgA1rvt19OK6dS4iVKbrGIME1FSZbE2wQgMp8jCRGydKKkywCIGAEkCIkiyX4JzCQTVnAcDcBIH5HjsfJoQK4lVdqycjAWESUDCzK2xUC3BdnpIW+8lF59lRMkzlgRgUuYJPaQjOwY\/XTSSY3zzZf1F1GqhqhZgqF3km8oqetZwNE+QMW9Z2GsY7MAAk9pEdk5cL\/mlOLgbUFt5hRb+XQhiu7trtzZtESlqubW\/kQfdLZuQ9uottlON7UlbiiblOl72YUuY2+Z9J0tUkWVMPv9\/pLvcfB6EtHx+yKbTOCRm08MypQtEuqePuofnL3rmxN\/3l9R6n5+7jND5QJTAN1GQvY80KU9vkm3g\/qK77Di18nq2avNYjGuLCqmHsjE2Ap5B3Bnvx2tNgeWg4qmTRrsTIgAWC6CDxctjJpN8frmBy5Jva+rutAUei6qLxl5zcfr8TQQxkOOOZOwi2MDqm+FVRVCDwG6sOGUDf+sEyi\/V5OeSBRbFj2U5ibNtjNtRyalmBoBaqDgWGUu3xAJLrXeibZW0Nub2RbRVBWhJHNrSEVpkJlxMk6+9Uyc3puYJgRkZorQDUh\/7gmBzrquMS00RGEyAggXMQK7zpW2tT2irIWRUQUnLrYnOryaAZzCjmBCUWm2nkykmeidjnRAATDvCYx2bF88rdPNnI\/0GOKvTuUla9FJ4xyt+f8VEVqDm5Jmcw6ltFL4kJIYHXB9RWzVOJU\/1Tv\/TFhQ1Q6WMW6CdKte5E1s0C01AhmsjZHT1xB3iLWC66H\/N2MEAd\/oyxgF+aMvboYN9a5+OTsOjCXSN5fTgdoxpooWTK70dpYlTF6+CDVVtyt4\/IBHmDF5z4dcNogDaVf5dNu6JaOHWRO0AjafHkiY\/0Heje0xbqRMbkyI37rbcBNoCEROLhuMe3Hnhus2jgS3lpxvhaA9C8fzejsxGdpMHp252D\/SQDeM177JY+hJiAKopI9tsCX\/qA5nuItT1N4B+s3u3RajzELbhjRAQEmzoOAu1dnELsAdCJzRnDYA6SXRZJaSl8Z7UBW6Z\/Kish9ASm\/qEv25iM8seD0WO4JBOPcghmrktcSy2dv6u2Nm520eMhcDlG6oMFm2jF6whbpUBRSLUE7FaFUDgRNBOXXCdIgEgURtFRFgQGYVy5BCD2oQ8AadOOF6ytXXuHVnAjmhbvsxOBeesjwAAIABJREFUqtqZibUVthdJgZ2rigUgBALAZiMjwO1ZxcLlQKfFtdUAkkAIvosly7FPptO6Y9ud\/BJFgNB+Y5dv\/QL\/zV8LMhhEJ5pjgkPL+N3Jcmx7Up7OE6DzaMnEkQ1JxlOuaweLLZNsA2yjC4kZqsJimBWqrJwzL7OWI9I4KRttZ0ieaoocFygZpy5rFBlvJk50eCKQOE+ortR313ECVBdwMYwspA+l8R06PYcJpFBWajE1KCNQC1SYVBdGgaDcRq9x9hXKYhVi4d2otrH+OmYJ7e9FZgi0rcqrNOs8TtBiXCoKaUASUFmQUw9aWI\/3gnSxcvS\/9L+0tekuJ9+DTgn5X8rEUDP+ENmFD9P4A6AoLABjbdM0AKreUgUm203aD3cfymlYJt+oZalttCsWPr9xFEJIMc3Pz292aJEHGuUOhhDGPzdvFiPfzYeWfDbjo++W8loYk3SkE3ljy1I2888LPAAwTAU2AswDtyrWAg2QFJoYFkMgAAL0O2tZFjTXEeaABERRBXyLbQ8f4ljFCRJA7GEVth0yZCmZARuSFdhBoJHoqEneC8BRGcRReH5Y57AWL0mhjIrADGagDggBSZBggEJBCgPm6HM8VQEqNrRx0AafThqyBn2Bi7CK1ouSAkYBI2AeWA8M20HTGgjAAFgbIQBJhmVBBH4lCACpMoEVceRbbDkLEEOtCAsswKOYx73z7AACeAWjiDARPNdAGLVglLSODPBk5VQVQEk7oSzUaRQkgmvNCQk81g5VkRQGGE8UFahgyQyZnNKZ5ocesKPECfCAMoYBaxUDYAB4wANBIUEhiPnLiLFm4oEaGAG+G+cxskFMiKkdf6\/wWgCVyMRbgRmHySVglFDLglE\/pARu5XZFEvFtj71HAphBNiTbJEuwtdoEa2BHIQy9Z7CAE0jBXlEvrtljhElZACUef8BWiaFskQbr7vQ+hgRlhLohRAh8RFDUCXWCJwRGtNQYMw\/MC5qA6KMfNUJY67FeUKcFYPkk8NE0wTSBfNLcwSSICRFoQs4LgUmIgnU1RoKQUK\/XHkM9UkQE1o8Qh0DQxhMMJaUosm79qE4SjDQKOAwiakHtMQoEZyKZrCQLEBgDwfoGDdAAg4RaIQwJsGQKmFg3JRPFqN6npjGCZhRIURXQ2BauZoF0jawFMIgxzo3CIKrYwpU9770PEHbCjgCaQNJpdXLGpFGRukDHbGDKdWaIs3am2dfEOqnOPRApp5Xnn03TdHi4D+xGL8MMNpkIm7IB5gHJJCIppvyNqi7Zu+92I7ufadP6u3loY\/LqpsmxqprR\/MeT8D4O7L2aH1ubMtDUeHblLo\/n2yRtUl+Kwta1JyLnkDFehgN\/L8ZBJ+ieXvsgIhH52c9+9tJjXwq0fPw3uL85hdRa2zTNLbfccsIJJ6xfv\/7+btRWImvs+eefv+OOOz7zmc+85ZZbMv59\/nnXDiIB1gBrPT597b\/cPgdAAXPZl77z7Be9+sAXvfGA1a\/583MvSoJg8fGrrz\/48Nc\/d\/Up13\/3f0aAByfgnR+67tmrX3PoUWf85JZagZLJAsyWgSYhA32AkQQjcj++s\/7bT14dxnZrswDVwwYBWDPi004\/9xe\/vN0UdgSMGPOAZ\/T7\/SgSAculgkeoG5AH1o3wros+8aOb54hBoKFqo\/b7P\/7ZWy\/40HyAGgjDK5RydnhLd71fRIDhBsDHrv6n2269A0BkXHntt\/Zf\/frnHHL6\/oeefNZfvP8Xa+4kmGu+8I1nrT7x2QeddNN\/rQuKAAwEb\/vAp\/ZdffIxJ5z5\/f\/+FRFllaV0lhjJdw4bENgOEm5eg49f\/hVM7GIKRLChYgAYmDsGeN2b3\/XDW1I0iIaMxWiiqYzWwqIKSYDBwId3vvdD\/\/XzNfmdJwUY\/\/HTO8+78JIoCAlDgLM6gWVyASa2sRwYpgCm+pUXpIRPXvm5KADQd\/j0tTfu\/5K37H\/oGc855FVnnPW+dQM4R5\/\/4r8++4CjD37R8Td87+YAJIUFPvLRzx5y6Kv\/+Kg3\/eJ2EOBDNN0LsAalgQB10gQI8f\/M61XX\/f1EqBsB2WkGBchg3QCveu3b\/uvHt6kCzswJAigCREbYtlb4qsgpz1ExjHjnxZf84OfzAfBABCpX3nr72re9++JBk0KiBPgAZnhBvkQAiV5C0oSUVITGn3aDZzO9ajszbUeKz1z39WjLICyEr3z1x0cec8GLj3rTi49+9Tsu+tsmARZf\/sq\/H3vcGUcc+arv\/ud\/i7FUlupw2SevPfGkM0\/+s3N\/+vOGHYQRAHZAQepIHQWCEEwJFLhzgM9\/6R8DUAckwhe+\/N0TTjzzyGPe+J0bby2naNggKi752Jde\/JI3vOa159\/263kvxA4RIKAseGZljy1HTUFxzXXff+kJbz36uLcfedxbLnzPXw\/rBQeIEkYBXKGaxboRzjrvPb+8feB6oAJqaDBETDC2Cgm2tNMrCjIMBpyLwB1r5EMfveyW\/1njFWSgBFfgF3es\/dBH\/25u0BTOFaUzBTWJBk3qVWVKUFOQcfc1FPvBQ7k0yn\/+8D8POuigW2655b\/\/+7\/33XffnXfe+RGPeMROO+206667Xn311fd3G7c2DYdDY00Wi3\/84x\/\/4R\/+4c0\/u5mY1q1bt3r16l122eWZz3zmT37ykzH04v9GOmwWIqIbbrhh991333nnnXfddddvfetbv8ED+6\/\/+q+77rrr4YcfnouNGmvWrFlz2mmnPfKRj\/zmN7\/Jpq1ZNEl3z5RUtK59hjyrR\/Hmn\/3sry+55JiXvnSX39510Wm\/sZL2PSMRufnmm4866qjddtvtN1j9mKTMrW677bbjjjvu4Q9\/ODPncqT3d7u2OF1x5RV33HHH97\/\/\/ZtuuunUU0\/9yEc+smLFik25MENg\/eWl1w1+9ev99\/8DD1ob8O\/\/9cuLP\/wXO8zgYQ49wCdces1\/3HDjTz5z6Xlz83j9We9yJ5\/yO7+NCy\/+grHp4598++23ybvf+fbz3njqqpVFaVAY1AGVGz9EauXbGpz6houOXP3MkuCBwgAKFGgixCICAbh9PXHvIeXUCu0s6MguCUE\/42kCgCvhclzQ2vUgu+qhD58JwDDBGeoBvx4EM70d+pgDImAJA0GPFwCpliUBmBETksEQeM8H\/3H9nbf+8QueBmB9wo9vHV78nvN23BHUhWB96mvf+OY3\/unqT75\/bcAF579\/+xOOfORO0+\/48LXiVnzhynf\/9Bb\/gfe\/\/zWnveqh26IQFMraJFOaNjCJqAHW1XjVGe960UEvUIBRC2zmgRaoFYZwJ3DbXBpRybMGaEGsmohVtg03k9iWW2XbJhvUQtpbNfOQbUZADUwR6oTb14dop9lBgTorgIqkcICF0JIhIVmIcAMAGwRJcfH7rl277hcvOhhQrAn40c9\/ef673vzo7UFAIdiG8bef\/e63v\/0fX7n2b+5cl8674D2z275il53cRe+51PWrz13+F9\/\/Cd7+zve98bUnPGxbm9sMIClCUmupMtQAPx3ijWe9+8BnPqkL3+pCrwgeGAIK\/OJOUG8711+Z3SyGMY\/WDF8xJyAFQISYghAKDCJMf4fZh043imkCgGHCnWvqXn9VUZgk8An9AjGhMvABzsEBhVMwOwO3UHYQAKBIRIMGRR+\/Wo+\/u+Jrt99++z7Pg029+Tn84Ae3n3fO6x6xG6JgMIIr8Jmrv3Xj9Tdefslbb7stvvf9HzJTL9lxx9lLP3DlTM99+D1nr1mHD33kr096xTGzs7BV55MxkAQiOEYMuPVOnH\/B+17w7KeIgTI+\/\/lv\/8f3\/vO97zs7RFx88Udntzts112mPvyRr4Sof3vpn\/\/sZ6P3fewTJ5x47PYVZhwkoB5AHdhBYUdB\/v27P3njWWfsuhucQwowBEhggOESUFaoI5hx2x0DNn3iKiZoAjPKWYxGIEYd0S8wGoELt3aUiAwZrB2GYHordtimBkpCUWK+wZ13eue2mZ0qRwNIiRggBKOm8X5mZRHi\/2Pvu+PsKsr3n3fmtNu2ZDed9ARIoUpVQFSQLr0rCEKkiwKCIlWaCITQi4gBkaZfBMWf2BAUSOhJKCFlk+wmm2R7ue2cMzPv749z7927u9mQiAIpz2c\/yb3nnjPnPTNzZt7+khBGATAhhIuB4kPKV+6NnBHN5\/O\/+MUvMpkMgPHjx7\/00ksAjDFz5sy58cYbv\/rVr37WBH7a8Dwv8qM2xtxzzz1tbW3MnE6nr7vuun322ef3v\/\/9nDlzLrvssrvvvnvw4MGbyT7+KaC7u\/vXv\/71a6+9VlNT869\/\/eu222679957q6urP2u6\/ieQUh522GE33nhjLBYDYIyprq6+7bbbRo0alc\/nwzC0bbvPsvLxk4wEua4TOWLdc\/edv3\/6iZqqlGFK5\/3\/qFbDJ53Wn\/PX4vXXX58+ffpll11WKg6waUMrTUSvv\/76iSeeeOmll0oZZUP\/nI\/Sfwd1dXW77rJrPBafPHkyG16wYAHW2\/Z1zc8e+euf\/z64ZgiAvEHj6pbX57x57vQrv3X8Jb985O8B0JrBv9+ee+TJR1sStRWoSA3K+ViwDCtWtp1w7CEpB5WVIpGqSGezTW3pGfc93pJBQPj5nY\/++833fQ1ANK7pPOf861c1tQ0bMbxkDsmGOgS0hZkP\/uGgb5z13Qtu+ccrb1fUjKwdnOwMce1NvzjihB8cevKPXpvfGhqEwO33P\/nuR6vzQGte\/eTaWxtb0Nisu7K5G26adeDh58y894kc0AY0rO4YOno8JF6d13XwUT847LiLrr\/xAV0KuB\/YcTeXDQ0hZ3DzrU8\/+\/xfUlU10gaAxQ3+i\/9+6YLzLjv+uEseePgZBlpC\/PGFf33nO9+pcuC5SCYqmtvTH9YH9Y1Nxx+3PxsMqnR847Tk0JbF7Q891qGgXPmzO37z2ttLfI0QWLIyPf3sy5tbOkePHR\/dXUABRgE+cOe9sw448rRvf\/fqP\/31lZFjxqcq0Qpcd\/MDh57wg6OOOe+fcxbngJzGQ48+8\/o777OF5auz1894oCmtFixtCIy47me\/+vqRF9x659MKgERLW8focZM6DF6bu+ao43502BEXXXv9w7kAoqyucA84ctgqEgUYxpXX\/OYv\/\/j3sBGjpUCosKK+5Y1XXrnke9ce\/+1rHp71VxJY0YkX\/\/XGyaecRkDcldKuqG\/qXlBvGls6Tz7+GK0xeDBCbdrb002t+Rl3P5wHssCt98ya996CXE4TsGRF9vzv31i\/snnQkKEFoxFMJBJ1Ktx2zzMnnHzl9Avu\/fsr82tGTqwa4qZDXHHNfQcefe4hh09\/7e2GKFXtjHufePvDOi3F6tbOm2bet7oD73zU1J4Lr7\/x0SOP\/N7Me59tDyAklq5oHjZ6UgC8+8GKw44446CDL7ju2lnpDIRVcFNkQzCqb88U+4el1ZnFfQ8\/84cX\/harHKQkQok1bf78D+b\/5Io7Tzjhynvv+z\/bxqpV6fnz3jv5xJNgkExa8YrqrhwvX6XWtHYcdPD+jg3LQ1ap1a0dLR34xSN\/7Q6QCTDr0Rfmv78GAprR1Jb70RU3NXd0Dh0yJFBoS+PNee8dfdzhFYNgJOBaren08kY0NDYed+LXLYmKSk+T1ZHl9m7ccc9v0wqBjV\/++v+9M38lhOjsyCxbVnfFlTcce9wPH7j\/D0ZHAffCwNKAIvzqkRe+M\/2Kyy6\/5+WX\/r3ViBHDR8iuDG6+5ZETTz7\/uBMueGve8pyBcfDwY8+9Pe\/DvEbG13c\/8OjqNjQ2d\/ta3HXfU9869fK7738+8GEROlq7Bw8a7vuYN2\/Z9NN\/OP07F8+841c5H7bj5HNQWoeaNYO1WscrubGj3Lnoj3\/8YzKZrK6uDoIg8jtiZqXU008\/ffXVV6dSqc+Qzs8EkbkewLPPPmvbdiKRiPSG6XT68MMPBzB16tSJEyfW19dHJ3\/G5G4qSCaTM2bMqKmpAbD11lvncrl58+Z91kT9rxAVY1FKRf5XUd30IAjCMEwkEo7j9N8BB55nUdAIAEBp7fuaBF1w3jk\/+t7ZlZ4kz0PM1QxmaECjr79X36Z63U5sULU5U\/aHtWWTXKc3Zf+Ygv8tdt1l1xdeeGHq1KlK9eyp\/1Wd0qf3LOuDyMS22267vfLKK5MmTbIs679e5Wqd6B908Ckhl8utWrVqzNgx0pJCiBEjRzQ0NERS2UCXRPEzAO6acf+YipofnHLKNoMr3QApgYaFS\/aYMu75p6597OGfL2+sf3nuynnL1lQOjU2cAEXIKtRUVlCId+YtHTu2dptBkArSQVbpHKvmzuy\/3l12\/k8e\/ME1v5n9QWOsstZINKdxw8\/vOufMb37joD1qalNRkaCQEXdkCNz44PNZ6Tz33H3nn3P60\/\/3xDY77rhG48ob7vzynrv96YnbZt554wOPPFnf7K9Jo6HdHzZuWAxY1ZizYjXxQViwbMncD989\/fRjH\/\/1PU2t2boVCBirmjMTt57w5ty2GbfeNvPWW373m1sH11b89tkXDKChQ84PFOETi9uOwN0P\/C5eXX3WWd\/cesJwQUhng6VL3tlt57FPPn7Tw7\/8+fIVbe\/WqY8+SlemRgzbqpYBUjChMcJ96513h1Y6o5OIEQTDB7OHxtbMmx\/UHXH+DWdc99ScBQ1aemC0dmZuv2Pm2edO32vPHSq8yE3JiyI4JHDXw7+FJ55\/5uHTvnvun1\/454RRW3GAG386a5cdv\/iHJ267\/efX3vXQrAUr0dCND1emJ2w\/NQ90kBfEh+qEtbIt+9qc2d8+9YSnnrijozs9b1lnxmDNyvrtp01548PcVT+bec8t177wu1uHDh3xx7++XgxONkRcTFFQylomYDwYYRj3PPCHIaNGfues04YOG9zdDWmjbsHi3SaOe+4XVz778FXNKxrnzs8tqsvEHdp6FJkQUiKvpBbuB4uXxSsqkglYAsKGZUvXkh3t6X+88cFJ3\/v5hbf8ds6iZjtR5XhyaZN\/1U9vOPv0b3\/tizttVVslAMMhAIV8V4g7Z\/2\/piz\/5rFrp592wiOPPzZ09Picxi23PbTDTjv98Xd333X\/A7\/81azGxmy3j5Wt3VttPV5aaMvk2I1RBRo6u19+\/bWzTj\/qmSdmLllWX78KOcbi+jUTJm83f2H71Tf8bMadM\/7+pzsmjhny4ouzZTHaP0oOVoifMWBDYCr+i3wOTz31fEXSPfWbx00cN8IS8Dx8tPjDUWOTd957\/qOPXJvp6lzw\/tKujk4prcFDY3lCKJHxdTZv6pY2Dhk2ctBQNxDwATiw7HDlmvpX3ph31U8fnTnzmbolKyoTbtxCy2r\/gXt\/eeq3j991560rkkIYrGhIp5KVw4Yl0mmwC22RZYm33pg9vCZRmUSoEeq0LaUraEVj8\/zFSy++7oHr7nz2jQVLfThhiNdnvzV+bM2js378yEM3B91dC95a5DEolL5PxsUvf\/0cBD\/0wE9PPeWbf\/vLCxNGDTUBZs367bQdpj3y8J3XXH3lb373TH2TSYeoa2gdP2YSaTQ2dll2leuhuaVr0ZL6I446+tbbr29sXL1qRV7l0LGmebcvTJv\/gfrlI3\/46VXXPDHrlmSy5t+vvEsKDsESsCLrpOxd8XBtf0CvBVWCZCkCtAyfr90IAHrKDyxatOjPf\/7zfvvtp5SK1IIRF\/7WW29JKSdPnvwpECMKMXWFyLqP\/et79fqcte77r+3aRYsWPf\/888cdd5wQIp\/PSym11pHDvJSys7Nz0cJFn+QeH0Nx\/017gA38Y64tP7LelKz\/3wbQ\/HGsh1IqYgzy+XxUwm\/kyJHr38MbgPWh83\/MLjmOk8\/niUjIqLokO45j2\/Y6gjI2bPUQbKKKSAZC9y1VtgVrx2binbUZYuXKlZHQ5TiO1tq27XWfXzrh+9\/\/7ne\/c0iuo2PKxDGOQOjjsK\/t\/uPvn5IgJDzsssvOc96ct7qlNe4W5PWcb5pa1sQ8rG5cMXbUKAI8C82tyLGpHlw7ZsKQm277UXzQsNUduWtuvHTcpKEaqEji7pmXT9tujC3F0EGVLgBAK5UHljVmli5vOOboAwQweeKgqVOnJKtq3ni3CVZsv723F4xJgzBlypQ1rR1tnUE8mYqYxHQ6TMYTSYG65Ysv+P4540bHB6UwYsSETA6hwtJljbXDkv\/3hz8dcfSJ48cJy8Iee+7d2t5NgAa7FF9rh0Q5jhTwvbOOPuP0\/XLZjm0mjQHgus4RB+5x2UWnVMdQm8TOX9jzr39\/bc2qzqFDR7pRkT+F9vb2qurq5qbWbcePBGAR8vlQSHIExo5KzJhxxcjRk5o6MjfMuHTqDiMtC0MqEzddd\/kXdhyT8syYrXrWPQGxoL6trm7ZMUcckQC+sN3gHbfbecxWYxbMb+dAH7DvNAeYNmnQ9jvt3pHhtk54iQrHQQh8uGSZcRMg1C2pv+C8s8aN9ipdDKqs8fM6k8OaplWJlP3Ecy8cf\/p5I0bbQmKn3XZb3dRWCAvuI6xSr72PGWeeediZZ365raN1x+2nppIwjMMO3eOGK08bHYdH2Gv3PV9+7bW6hvqxY0d6FnyDjAJbcvCIxIdLF0+cPEUQPEJbJxRxTW2qZnDt\/bN+nhw8dmVrcMlVF0+YNJyAwUPcB++\/bscpw2uS8RG11RKwyAGkMXrNmjVLliw9\/fSjbMZOU6v3\/tIXR4\/danFdDiQPPXB3CQwbhsnb7bh8xco1zdmKqkoQNNDU2eHGYwmJpqbVV1754xHDE8kYxowb35YOmjvR2uWH5Dzx2z8dc+J3xo1N+cC222+\/tKGBUchnpXldtaVcF6ecfMhppx0c5NPTtp1gEfJ5HHjQjhdfdFJFHJkcpk7d7q233qtbUj+4upIAVvB9rYKguqJ6ed3ySZO2jrKotXfkmU1FZXz8xNE333JRRfXgNWtaz\/3ud8aPrspnMKjKveyyc6dOG1dRGR8xeBABDSuWx1OxWAxeAn6InB\/G48nGFfXbThpLGkQItcpksok4pmw\/+Cc\/vaR25KiG1pYLf3jOjrsMDkIccdi+F55zksuo8LDd5G0WzH8\/zIE1Egl88GHzylWrDzpoP6MxekzFF3bdZcjQIQsXLO1oa937SztXxLHNpNqtRo9pzwT1q1E7ZIQtpTQIfQWSXhyL6pYcd8Lx4yfI2iHYaqsRXZ3t+QxaW5qMxp\/++sqB3zi+ZmisM4udv7B7d2fadWHZcCzLsWwbIPHxtvqNd3MnQb7va6V\/97vfnXHGGaNGjZJCCiGMNgCY+cknnzz22GMjp5HNEGEYPvPMM+ecc04ymYwEM8uyUqnUc889R0QNDQ3vvffeZ03jJoWS\/lErbVv2nXfeedJJJ02cOPGzpepzhc+PFmMTxBYJZNND+ZiOGTPGdV0AQRB4ntfd3U1iXRqGUpoIAfjAB0sX1w4fYttwbAQ+BjlIEhI2hNFEsmn1mklDB1cAAOobm8nzkoPQ1dE5bvSEjA\/NaO\/KWl6CJDQw884n2OQnbzv+3PMuX1zXQoABNGP58m7W7iAHDmADnm3lAzQ2rNhm1NAxlXA0YhLVyYohtYmW5o7tp05zAMohkwGl25Wv33333Uljh8dd5IFlyxbtt\/cORkMiP3nbWkHIZNHc2t3ZhZX1SMQruzUa2rrv\/uVv9j30ykO\/ecOlV99qQjIMD85Ar4EAtGYLyCu0N2NF3UdDaxICsCWUQayYJ9iyXNtNrFjRuM2kCVE8x5pVmVgsVluLrs62SWNGENBlsLK1oSYhhlfChLjj508Mlv6UEZUXfm\/G+0tCDQT5bI2N+o8WuewnosoaAOAIyKAtmDR41JjKlDKotjDIqxg5LLm6cfV+X9y1wgEDaYXVq1u7O9ML5y7ebsKYGMEFutrW7LXHrtJAqGDq1lvVAmEe+Y4Mglxnawcbho3la7rueuTpA46\/8uvHXXbrzLt8P4cBraMWYIFUKXY+m8HK5ctSSU8AWiGKB4\/sWl1dHRDBquZlQ7Ya0mXALpat7NaUtWNo6Wobt\/V4AWhg5ZomryphiO0Erv\/Zk2w5Y8aOveLHty2vTztUKIe+bPEq7eeTsVIcO2wR725pmzpm6IRBcAyEQmVSJmJY1lC\/\/U47Jh0A0AarmtqkE1\/w0YIJo4a7EgGQyfn777WbNJDZ1nHDkyTRkUdzZ1c6n+\/OI1U91Etg+YrOX836w\/5HX7X30VdcevM9bdkwr2ATHMB2Hel6kY3dmMK\/KObPdSV0iJY2NKxcFZPsMVwJUogTEMC1kMn5QeA2N3aPrK1NCcQNWpetSjqxQVXoam8bUj3IUpB56FyYSlTE3LhFmDnjN4m43Hrr8ddee\/OqxrxlwXbhxbFkcXPoi1jCsm2saVo+dEQFXITGNK1Jx53qeDKWTqfHjBpJChbQsLw1lvTYQlsHZsx4WiCYMHbwNdfd8v4ClYhDGlQJJAykASAEBQJGhX4+h\/aOzuqK6uGDLFvA13BTg2KVg5bVr9hx6rbVHvxulcugK5NOZ\/MfLVoyaswYzyYLaG1e9eV99jIKnmNN3mYwG+Qy6Oxq1zroaGshEwobixsaHnzsiW+ec91J0y+79Y7b05nurm5tNIw2RvO6K7psAhBCuK777tx3HcfZY489tNba6CAIpCW10nV1ddlsdtq0aZ81mZ8NtNLz58+XUu6+++5BEPi+n0wmY7HYueee+9RTT02ZMuWmm26aNGnSqNGjoiDjLfiEiExMkQqSBF18ycXjxo076KCDSsLJFuCT1zFcX\/SkPN9kl7\/+KDEcG3es3xYMgIqKipUrV+6yyy6+769atWrSpElhGAohBjKMaKOhIC2ZV1jWkPOSMTeFEFiyOPfMM89ccOlJBISEOa+\/feDhR7\/yyr\/GTP6CDXTlsWz56q1G1lakYFlWRaUDFwaY\/a9\/f22vPYY4mDN\/kaPT37\/4jFQCv4pnF7z\/zvbj94cBM+ob6keO2CqfR9KJAl457hAzebajATCWLU+vWdNUXQm8U+ypAAAgAElEQVTWisgKDFJxvLewq7m5eeqUEe\/Ne3eX3XbzgC4fi5bWf3HXyQLwYqkAyBOyjNbmVSMHo2V13vOcZBzjx466+sqzq6tAgNCoIrgE\/XGrjDaosLA6n4lLjrsA8MHCZc+9+K9vn\/GtComsxpzXXjn2xFP+\/eJLyURFVsFYWLK0btyYUTEPEMKrrAYQCPzz5Tl77bZTSuDN91v8bOdVP\/qu52DGQ39ZNP+dXcfuZtluHmhtbZu27daSSxG6EgCETKRqWEAFWLwc9cvqHHcfxwUTAsAC6pa2B\/ns5MmpR+a8+vWvfpEIOYUlS5ZP2npHIhiWlZVeGsjk0NTSGk9WtXW0p5JV0sawEVtddtUp21YXbODugNVeRKHMIQygJFmS0d5mXEckHFiElU2Zp5557oRTT0ykoBjzFy486OD9X39jds2wIbaAAupXrRyz1ZBhlaiKV8Zj1QGgNd5+a87uO06Lxem9+Qst1X31pccnLdzzQNv8d1+fNvqrJgAJNDWtHjlyZCENe8AaRjrSsAw1p30MctHYnF26eNHY0Vi5SPh5FRpkQyxdia6u7PiJI5+a8+ZOu+xGFtLAv+bMO\/P4I7vb8hyqiiQU0Omjo6uzelBFuhtsjCCMHTtxxm3neLFC4ZcUEAMCwAdyvu\/3duksrZoCMCE7DnV25oWg2irXBGhY0fLc8y9MP\/1k6YANlixcus\/e+y1c8GFF1WDLhiWxvKG5uqoq7iDhiWQsEYaQFt556+0dJk+tjNG8eUtYdU8\/\/aQY4bGH8\/Pnzh01fHc3jmyApjUtI0aMiscQ+lD53NCabbVBV7das2LNkEFVCQ+pygpYdsiQwKKPGrafsk1VCosW65RrnXXa4bEkHnzo+cUL5sUw5YXn\/3jmycd4MWQCfPD+oi9\/aZoTF+xbGgBbXqwiCKGAzg40rWlLxOO2FTOWgAVia9WKzkxnftSIqvfnzdtrlx1hwTA+WrJs\/JSdQo1QGWWQ8xFqtLa3xZPJtq72QUMqXRdjxo++6KRvDhmJIIcKCcrBs9HFMAaaoQHWoL4Za9YXG8v+\/fLLL99333133XVX5Hp07rnn3n\/\/\/RMnTpw7d+4222xTCtf+rMn8tBGEwezZsx944IF7771XKWWMOemkkx566KFJkybNnj0bQHt7+4UXXjh8+HDbsjfPLvrvgoiUUkKIXC536qmnHnPMMccdd5xWun\/OqM0Zvet4rEc1DymlJaUf+BzVh2IwG2YG6bX\/cVl399QPGRBrd1TdeECCosCveDwupcTmJIRERt5Ij7Jp52hmZs\/zpk2b9ve\/\/727u3vFihVhGG6zzTaRjXugqxzHiVYfy0Im3bXTTtsZW+cBtzb2Vl3DX95sTQNP\/eWjLi132q569FajXnr9vU5gRRP++dJr3z7pkBoHsYT3yrv1nYzX3kl3t6zef7epBHxxu0k3\/viMkQlUAN877ZCTDtvfgfEEbIH25pU7bz81Zheqb9iCNGNQ7ZD3Fjc0dmNNiHsf+30ilaqMYdTQ2rq6um6gBfj17\/9eO2IcSXR0ZRPVtV3AA7NeXdzQaZyKt+av\/sercxs70QLc+cifJoyt2Wk0OroaRo+qTWro1oaVy\/JxYNlyXHLR7SvqO8I8LCAMB5wDUhIzCMi1N++wzfhqBzpE9eCh79U1vvJh2wrgyb9+5JLaZSImjKx9e+48ZWF+o\/nbP\/55wjEHIMSg2sHvLG7KAHPn5zpazde\/vKsF7Lxd7fVXfbfCQYzxo29\/\/fTDdrPAWspOg+VrOidOnCS5xzM2AJzBVXMW1a3OI3Ax6+k\/Vw+vTSZRPdj9+7tzW4Bug989+88JE4fFKtBhBdao1Bpg5q\/+WbekddTI2Oy3u\/45e35dIxTw2O9eGrPN5DHjE01tevSErW0J1n5rCwKgoQUXXjizYXlmrZ7MUQW6YoydAcAGna2rpmw9tiqJUKN6cOLdD+d\/uKwjAzw\/uzkD+YUpQ7ceMeKtdxd0Ah+swvN\/\/ue3jznC82FlzAfvLJPA3HktHfXLDt5rZxhM3mbMHZefMc7CIODK6Ycef9hXYeA5sG2salo1efspBlAacAgkDTB0q63nL29pYdRlcO+jvx08bAQYQwbXzJ3\/UV6AXfzm8WfHj94mZqOjU9eOGp4BZjzw6tIV+VhFall9+5w3FqxYjYzCI4\/\/ddvJ2+4wDos\/mjd21NCEizDXsfDDQAALV+L8i+6pW5YJSr7KQgvRMzB9Vk1LkAmQ6Wybtu2kpAfSura6omHlig+Wd3Zr\/OPFj6AxZcqwrcYM\/aihqd3g7Tr8Y878Qw89sDKG6qS7cOGHnRpvLMg0rWnZf69pKYldd5jw08u\/W+EiLnHW6QcfeuDuBIQ5kEJ3e\/MXdpgMBQ4wdsS4j+bVcx4tjfzO7NlHHrqvI+AlUktXtXIcb81Lr6hfecTBuyY0dhojrzjnyCoXtsJ5pxxy9AE7jxzq1dU3vrMi3y7xz9eXdGaz206dms7rZJVUQO2wEY0t3R0KXXk8\/tgfbLLiAoOqR85f2LQmi6yNJ559adzoScMrwOl8zKnIE+5+5MW5H9RD4r0F3XM\/WNTcBrLw1P+9MnbC5FHb1DS2NFUOSrGFzkxHSwe6fNSvwZXX3Nfc0qGNKoYcl2\/BAwaGDISi4+Dnt\/ZXabv5\/ve\/v3Dhwrq6uhdffHGXXXZ58MEHI0+YxYsXjxo1qhSuvbkhFoudc845H3300eLFi\/\/xj39MnTr1F7\/4xciRIy+66KI5c+YA+Nvf\/jZkyJDhw4cbNp\/3LvpUA0L\/c0RVDS699NJICAEgLbkJ20OijFhaa6NNFBgThmGUoq1UQaUPNtgeopQKQ+U6rm2XVefaAAgAhiDp87iKfXKEYei6bpQcQEq5WWW+U0ptDhqU0ot01FFHLVu2bIcddhg2bNgjjzxSVVW17jj1EgQw9+1Xd9hlR5dYQA8bJK+4\/NKLr\/7pdR1do0YPve7Ki1nhxEN3uu2B5w897PyqZNUNP7280gMB50zf98Zbnj7mV3eNHFxz+w2XVkjYBgQt0SPtEzTIMKt0d9C4fEFl\/OsCiPTPkhATmDyxav8v73HGKecnK6oOPfTQptWNlQJf3GVIZ8uEI486G0IedMih55y5vwNsPX7UJRdf1NWdO+qwYyZPHFFbg7feWfWtE4+++ab7VrSsOfire\/7o7KPyGsvq5h568EGDEjh\/+knf\/8lPf9qeqamuvOHqH00Y7VkGrGDbA\/ZJLhfGYrYOMfvlv++zzz4wkDaGV8fOO++ci6++uT0djhpc88D1lwwSOPbgqbc\/8PzBR55dlUrecd11w6vhEo7\/xn4\/v\/9Xd955z4RRk2666sKCHxcgAMkAK2IJkCVIAeks6uvrK7\/2ZatUiBoAMGq4vde+u37ztB\/HrPjJJ560evn7tQ723mn8ys7gzNOvzbV1Hn7APmefcbgApk0bd9bZP3SUffC+X9l52rbDE5jdtPrk44++\/ZaZy5YuPeSQb1x41tdywHtz3zji0APiFi48\/aArr739Z6sah1QlZtx41ZihA6qTdWHsCnxi3KY5s1\/eY489tIErEQj+4aXfv+r6mUsamsZuO+nm6y5MWTjsgF3vfvSFw4\/43sgRIy6+4Lsjq8CMi8875Mabnz784XuHDU7ddctP4haM4ZTjwigJ2LAKpcJB0Sa+avWyZOorWQ2Ty1UlY0JCG6QSOHC\/r5z2rR+mPOfoIw9vbmmuEth7h0GrGyYffcTFwo1\/9StfufCsr9iMaZPHn3n6xeQmDvnGIdtNmVgRR2P90unf+da1V9\/U2tpxwIFfO\/ub+7Z1Y\/GHb51w\/Ik1cZx1xrHXXHNNa3sH296M226aOLyQkVkCtsWsCWtLAS8YSisYseC9udtNm6YUBFHMtb937llXXP\/zdDaYMmHSRRee6cXwtX2nPPrESyee9MPq2ppLL7xgRC0q4zjl+K\/PuOeRXz3x+IjhW13zw7OlicpAGukICdhRvgAq3FcSVtQtdPfdWzKlHByy\/86PPfXyqd\/8SfWg6isv+d7gJGQMxx59wH2\/ePLhh389tHrYVZefbRnYDGnABKlhCIJhADeF8875zo0z729t7xg3svaKS851bFgsM11IJTBqpLPjDlN+8L3r\/Xx4xJFHqnymugo7Thu+srXzvPNuhvEP2O8rp5y4lw6xzbgRV\/\/kYunG9\/jSF\/fYc5ehQzB\/XsORhx981523r1q1eq+9vnTuOYdlMljTtHrvL32p0sHpJxx2w213tPkd1VXuFT84f+K4OLLamCgHrxADpOvdNNBn+TXGEJEUMsqXlclkGhsb99tvv8+KvM8V4vF4IpFwXdeyrLPOOmv69Ol1dXXbbbfdrFmzPM8z2mxR2\/+3UF9f\/\/bbb7\/wwguXXXaZ1pqInnzyyd133\/2zput\/As\/zHMeJ4q8sywrDMEpfFGVS9X2\/f2gWLe7ot+r3epF7JcKyOUiZ\/L0PPbznEd+qGjI4zrAZhgxgJBUSwZRDIMq7BR1tvyFsoe6bcct111zWSw4pu+P6GEA+53x91O9EpJWOzCOfNUWfHiI5JOqB0sFNSTIpl+ajGo6lf9e7DaNAAQiAi0DCBlNeAXYPM1oI6zaAgAa680i5AOm8EYEhbRC34WhYKOqEyl9iAsAQBpBBkSkv1oozLAwsmwUI8AEX6GRYBBXAlojLghtVToEshBpKIg5EYe45qBisHJAFskAKSAEwEAKRbsdnbUg6QKggDJIODMChL2133T2icqEVKzizmZBhkwICoEthkAUXIEBrBAauDQZYo7Q\/RtXllUFcgAHB0ASKPKAYMGACCKEoOFm5CsRgi5koOjlSyecBmxE3oBAQgA1F8KMONqHDWktLw+rUqJLwCrwrivUnkM4j5RXK3kkLOoRtQwOBhifhAiFgF2uQ9FnDNBDCALBhoqL1ASM0iEtk88Z2hVWozQgCAsArSix5wAa6QtgSnoCNwjP6CjEL2ocAyC0WrInmSWm2MFQU12FUSpAHaVQgLCdUkBbyecQ9ZHw4Dowp1NbI5GHZcCVaFTyrUGRGETQhr5GUcItUqeINcwFSDtIhHBsJIA3k83nLdmOSCFC6UFSxBTj+lhdDhXvP\/0pl2ItRFlwoHOnrQnEbSbBQIMwAiqFCxOIAI1TwQ47FKAhhEWQIVsjlQjtuaxvxGLKdSNlACNsxOcs3bKzQFiwMRVYCoYGcRMIDdeuYK3NGkyvbc7AFYhqWgHKhBbRCmIc0SMTACpJBDMEwpJlgSGpCwBAONCMeQzoN0qBA25KSSZHOIiD4ij2bSCKQsAQ4i5iLTAhpAwZBANuGMfA8ZHOwXVgW8nmAEOW21hpCwPcRc6BDJB2wrzhk27ZDgcCCFtAGtoH0czkvNv2ueQ6J5344rbrw4qx1sxVr+bQxQystpIjUsQAiN63N1i+rhFKlwtKRcp1p9Dmbzcbja08xsgXrD9\/3bdsWQmwmct2rr776+OOP33rrrX3qhNx444377rvvnnvu2f\/V67fUfMyLKUIW3\/r2GbWDaqzixYLLyib3RiHTbrHN6INZ5y023rWv5IYUiYD9a9dvPhC08Q7jBiAS8aMUddGR9TS2CnAckAhksWacy6EHJIAEEEeU7daHAPKhBKo8SIKETogwJYMqB3FCj6DHpf+4+JVgwAgFBwJg1hE3DQmyLRIswiwBLnOg4TA4RNxGQoKNsQCofMyCzfAkYoCBAhQ4J02u0283Oh8DqgAHkIAUMAw\/H9pAgigKLvfIT9haM4wxQhLWndfbsOUKsIFSYCMsYsUOkASGW5AR853xJSFmR6ECoWV0wZMpYAG4gMO6YExgyLIwDC0KC44ECwaHoCggnIp9xVHdcGPrbJx8UjnoHIIQBIuRAFwEFmclGQcE41cJdg3CjBEAFKSCBRBU0lZg2AYJC1L5CRsOTAy6UsIEuVDrKDZerI35o55sWYX\/HYIA5zW7nrAJiqH80AVshEmwBRgT5IOcC2WBK6wgJdgGNIwNhGE+ZsEobXRAkQDUe33m4hwhhmYdE\/AK9jQDsCVABnEL0Ei4kCEsBUcgzMMGe6T9fDZG8ADByhEqThB+PiU0hxmBLBB4QBJR1+koR4JLymIdQifBrvCrpPYQuuCEhOjZc6L0aSA20Z5S2lnYQBnYEi5BAmAww88p0uwyczYtTY5DHWSV8cMY5XV3R5wzMsypfM6zkIxJm8MKx6h0PuWANASzUQpKC6MFFMEINgIm8gtzCWEexigd+mGQkeDKOCQj7gIKytdSQ2okbEgBrSAIUbovQ1rARDNLMCzWFCrPcKalOybYFqoqKROuCLPwJCxwyiUXAanAZZgACQ+ejZQDBL5tVNLWpEKLlcqphA1baxFw0mab\/YSEB+Zctwz92hQ8iZiExXCIbYQJCx5DZEMrMA4BgGXJXB5aB1rpEAB\/vL5vk1nBSRRqMQohomT6nudhs88i06dWekkIKUlrALYIIZ8czOy6btSfQgpsBhNPa\/3888+feuqpHR0dAHzf7+zsPP\/88x988MGBqurR4s51d4pG2ZIkGEJrQwjJQeT5AAMyDESZgvqvboKlocI+aJRxydxz+803XP3jgewhGzvKJ1n0ebOyh2xW6GMb2aBrDcDQMtIac0EaKfsxugFKfoyi\/Hh\/JqGvPaRXOwX1AxcILbtG6OKFROWNFhT2pqhAL3LP0bXlBS\/6UFy4MDqfmZhZRDcW69ADmWLLDMPRmcxsCFHPCDBxec2hiNUThWdZd8dzjx2g56lE2a+ABphYFApJG0TWop7nUgAEMwBNAhCyfJkr0BCldhJFeowGE4gLnd7TteWV1MtH0RT\/KUojpXJJkcgAwUXZKSK879wTa5kcpUMDO1IX6S7eX5Rcw4r9U3RYKkwc6nd1YZ4wAIloS7BKZAygclfgEAAoMu0EzXCOvOUlX4v7z9u7NuyRWkuDbghEgjkKnuHSYxUaLHv7KOp3LhaIh2RjQMaQAYQwAhAiMg6SARmwKNhDUBjB6DOxlmAWxARDQhgZ+TcWipoYik4TDJCO5KXS+ERkm2j9p\/IR7xG7OLJbGsMEAwlA9hrfQs9pbaQsmz8k1qrIE0wAExsBgIUhYmJNlCcIhsN+h+2ecdscm8SzP951CGumtc\/DXt+4dy8XR3Mj2s82c6PHFmzB5xD930prIFMGAFDPflA6TQkhjLBL2f\/IgIsesbS2FYq0YKmjJRtmII3gJonIY2fLUrgF\/SEAZtFXNOj5Mfqhz\/eBGYC1z6\/C+RRxydTn1AKLX\/xC\/S8U\/Y6UvvQhpYzCPimPaC3+\/r3AvajvSXxsypemPoUlmAAYWs+kP1yQE0RJTih3T4oWN6aiFCJAJR66h++K+GwRsdm9n7Dsc6+fuPjk6\/PyF8WPnmKtotgIepbfgVoSWOvkGFBy6JERiiJXdP+yHi+\/9uMeQ5SCOqgvJWufssYCG8BEQTxgDQIzaZbgvmNdsKIDiJhsGBCDhYnuVZCXyu5DYAKX5UcxhZlekjGitFyiNP1Nr3eiACapIsmhZJYp3j7a8gAwRU6A0hS7q9d+yn359n4pWoghwT0vatm1sniM+jzdwFs2MUnd8xREDLv4gAYgIiE0AVTIDbHpY8vOuwVb8HlD\/7fSEutwmeCebZV69uzea2nxHMK6fHEifQ\/YCDLERvTfbTZRRD2+RRTZgs8Un5UG0wAlY08vI8LHXvVfRv8cfRuJbXxdeqL\/HAP18Kc1TwhGOMX7GRRSNQmGMBLK9BIvC7b0iO9nFMzwVDxSdk4EUXZ+sYX\/\/LnK2ylvOdo1+xoy+0wr6rGulLew7vb7HidRPlob9CQEOCZkgi8sRQAEcdTbn2ig\/2N6tmALtmAL+sMiqI89qbeOh0sLkSjqWmSUf4XXEvsRZQ6xWAIwMJJNwYN2C1u+BVuwBVuw+aHkqRt9K\/nyGRLdci0iYp9tpcfAFnn89TFKUe9z1paAa\/3Rv+WIHua1SLK9TIrc25+tX2v9aetlDhmA5g1SZ0mGYJuBvESnhVBYLquSs+UWbMEWbMHnARaZjwmnLvNZhVirby5H6xpF+0m5naMQsQfWRAA8KWO2RSrEWgWRMuv\/xhvKs\/FS\/ulgU+qf0ruAYnxU4fPHMQtRJ\/S8Suuswt4f5e1rLgaRFLFuH+7Stf8BDQM9V+8xNWXHywyqBXOpQF9eqvx8RnHRGCCZz4D0rNUnFOhl1O19vDyMIrpv5OxlALCgvvSbtRiHAVA\/S0shNiBS80f+qGUk9PIl6xXV0+OR1au1tfRh\/+PlDOwA\/TBA++XXMq+9neK49ETCFM28fce6nMKSKXitbVJkIuMAZCA9F\/CEzlnxS2bMkb2rGZY8oFDs+ajNcr8sib5vX\/84vf8MveZYlBOyML49LnrlPd5rbhheawvlGCjGbCCaN9SuHsVZhQJKOLAqHdY2ILCBK84WFLEp7V8bivWZe5tz\/wyE9ds3N2tY9955x\/qc1xOBV\/JqL4MhENGAnlYsFFkAoHwL2hKM0IewubhpFcZpnev1xoKNl\/JPB5tS\/zCtnYf4WBRYpeLln6RPoijY\/rznx\/pL\/BdpGHid7f9Gr4vS8jhssR5+m7Q+adnWWTW1\/F7FxnoiHEw5V10uZ\/ZyA+pLZzGkgkqfSYo+v\/bcaaBvRaytD\/sfH0gGK7\/lgJLpWtvv1Yzp2z\/97xvR03+U1zWvuBRnZAxEKmz1jQ9ywb2qWhXkJwaoEDJUkEO4TA7pJZH2lUPMJ9jvBfq2HNETyf\/l0lHx\/PIH5LW20PsUXuuvA8ohG2jJiALSGcbWAQXdlSK7AZ5U\/b0bNujen2P8xyzgFt5x3djSP+uPLX1VAvnr1xcl2cOsLUuvIQhai1NWzwnRzRik9a03XPejn1yuQ9UTnico0stGypuCpnbjHKT\/lh5rU8VGOqxrhSlT3JZnRVtPe0jp8g3NqNbLHlLI5lQelav7HClokanXtetJw7p57vKmeigqUVLGqxU11hJ9+6efTp2jVj5+nggqq1GDAWLWeQB7by99fxS3HHnzl+n7y31Wy2xfoqccNSSoXGEf0c9UoN\/0Oh8AqIzm8oXUUBSErdeac6n4vD391vt4GePeS+4qy1lVsIf07Y3+skT\/dgwboJiMu5c9hEtt9s4NJfud06tNQ8LAAozFiuCDlJJe3k34HCUv60MjSlHghWb6ZArgXhMzIrP8HPMJlpz+LSPKDzaAE3L55+i+a22hhHI6y38dyIy3QRnRiUEGWiCUAMNiJAluEAjOMYShQux+L3tOuURXtm5EWPcjf\/6xbtvU+mBT2r82FFvsIf8ZtthDPhaWvR4n9Wj2yj\/0wzo6NfpJAbaQmWxWh4EqW2f76D6jYdtIGfctcsi6sSm9ewPtausjhxgyJKgQMBrZNDjK8xplBwVgdCGJkSlW5ROICmJIAhC5r3ChoEKPalkAgmEbYUiEsoezpyjFUI9goVEsP1okoYQi\/0oGLIhLmaakoZIvSpT5NGL6OMqDR1ygp1Cyw3Dpc3lept7906PVjnhwii5iLqWfYohSZG3UD4U2iUvRBVyW8MlAgIxgI1gYtsACpEpB81H2JGFEwb8Ggo0EDImID7eYYIEBo0FR8l1AELiYz0oUu1AWnosMiwKvKwAyIjrfABCFtLCiwLaacr6\/Fw8noh7rtcAygQbw26GCr1T02IQerlGYYkolArhk1Smo8qMWrML4AqJMfuv7bhbtFcJoppLVGpEpQrCIGO3IrE39yqKVyyHUyzJT6EemqKNsEwas0kkSbqAcy6Y+VBTGKeKYFSJ5qTQHYIh7vN0YoMIkGMAvi4UozrFoMhTUYWQK\/Q\/oQh8K4uKsYIFSyxGMLs6lwtthIJgK+RhkIQ0ym6IlLXq7y\/3HyuXMaJpFvxaOGwmAo8zCKL3FQvTNEy0K72nZA5rCVyHZkNGGTKgFkwjzJubaxu8mASUsBkUyZNQ9G6RJ2Ujxyb31NqX9a0OxRQ75zxDV0Oyj6dvSUeWwNnS9GUh\/gwEklHK1jkMIVWg5DpNg5pJPSC+7+UY+OkKIMAxd183n81FV9ej4QNNuY5+ORBQEgW3bWmvbtl3X7erqArCp1lMvh9baGFNRUZHL5cpTon3smBoy+TCTTFakA60128JySSL089l8ZW1NLqNVLkcWrKpkd3dnTSIWdnfbwgEAQSD4lgCMyQcIQ2HZbNmKREmAsdgIxTKAZJP1jBamwvV0wNm8qaiyMnkuKcg914IOSXBra1sinpSWJdgQC7DHZIxQIBXVWwAssBUEKq+VlUgYo2ztS3AobCY4jh34+QrP6u7osJ1KTdIIDUCW8bvl3vyF\/inmUZUMqQHAWI7rUTaTV2GYSDiZ7s6KZCqdzbMdy6nAdWJB3k85cduSOQFldMKVXd1ttvBIWNIRWgccwhjtS0lgzwTMFiMFQLIBKThM0srC5LP5pPSkgYABg9kGQCavBdiOpbszrgEJbSWFISNYkLEMZMllq8eQy+jq7q4ZUhMgDTJaacNCwgNbthQGEDZaWlsq4zXEQggFgIVBjwTSwwGXIMp6hhhBGMTiri2F0VorIiLLlm1tzRUVVWyIYFlSBsTd6a6YsABoy9ie66fTtpTxRDwM\/M50Lp5KMjOBWYRgYdgFhEBADCmlMRRzZWtrezKeKCNEAYBxAIRBTkN7yWQmm044DgsTFQyxWQgWYVQpsuihRIDv+xWVqVzOdz1bCJHPZrRS8VgsCEJpyVwuZ1uuLSJLnGFokpbNgkOyyGbmvkX2GAaWgQ2AoImNa8db27rdVIxZxWxpg8iyu9q63XjMCGhSlkWWoVxnWjoWAMuyHcfxs1khbMdzOQe\/o91LxkNbMQnDliGwUNIYK6oe47gGSNhobclUVcW7c92Gped5QZBPxmNaK9e2cx3ttiR4UliOnw3ZSCUtJhihpIFlCBAy7qXz3ay1F\/MqyPP9XJgLJKSUliEoaQAIRYagBQTD9dzO1pZ4ZUJpIdhiwL5m2ywAACAASURBVAgFMqDI5gkylinYlEJACFhEUhttdODYlM1mtRFuLBFCMUEaYQycaIYTa2Jhi9AEtmUDkLB70ogVXQkLQ1h8Qxllx3t+7DM4n2sIIZhZKZVIJNLptJQyDMNYLEZEHR0dqVRqY99\/Pwm01olEgpkjpkVr3dHRMWTIkDAMTe8YrQibc199QmitiUhrDSCaiuUM0iaGqF4FEXV3d7uuG8lgETMspVRKeZ7n+375JfLqq69EocDu+uXSjbYaAmi9+EsqquWiz8aYf7380j777KM30SmtlFJKRZW2o8HYVLnwCNls1vM8ZpZSAlBKWZa1DkejTak3hBBCCGNMGIYbZsQTcDwRwvgspbBDPw9tQDbcZFqRgrClI6U0tvANMVmW4xnNAmyE8YXMkOWH0jLSsmIkJUcO\/AQQE4wASyOkkgCHUhthCEKFSthOV9q3bGEIkQ+QH+TIkoGCF0\/kwxBgi2xEDDexETrSoBNIRJpXkrDcjNbxuGO0BjOTYEYYakc6Rhtpe4YidawBiIUoWg8Kb0Hv3om0v0KAJQwJBBDZIIQ2AkbYVqihhQMvaWzP8TwV6rgbcxyRDZDRCA2CoNt1nHzIPmQoZC4fWpBBXpFrAWwxE0uQRUwSIZFSWmfDfFbDko4NEhzFXgsTmTvICCmJpCU9z41ZtmUoZOJIyw2WhiQTTCGuRkAIIuG6ntI6b7QmYUgCljCSQNog1KGBdl2XjAQRyBjSvfuhJ7yAIQASEMQiGsuoxDdIhr5SgWLYebYDsrozyvEShomZBCwt0OobNxmTWpCAEswk4148CCif075mLxkLVCgFgRgUGgLYEUwgDagwCFmFQaA826WyAB1DgklSVD1DOrbrSVc6tk1swGwIBHIMEZMhQWAiQ9FgEgnbCTWRZeWDMPR91kZIsoS0XCefyzm2J4QAmULGKZZgCciC3T1yiOsNhjAkQSAoIjJGSssjWyitiS3FVmcW0nONMZoVW8KQ3ZUL3UQSzEIgVCo0Bl6iOyDfFyZAPOZB54xFSrAhwcRGhEQsjdCgjFahMWFeuK6jOZS2TbarIAIDxca27Wx3t2PZad\/PsWRhW2yBhRakCRCaAMk2gxRr4TjseIbsAABsW7pSOgAMsSZiMFMkHyqC0b4W0pGOZQxHNismMEVmOSYIQBZsWcIAwmhbSAmBUPu+H1iu48QqQpJaGoZ2NKQhEDGREpHFigVATMQW94pbKXsnN53lGZ7nhWEYBIExRmvtOA4zJ5PJIAiIKBaLrZXb3kwQVTZDkWPRWju24zhOSXO\/Rer4byGbzbquG\/FIWmutteu6JYZh3fisad9glIp3G2Pi8bjnedHzRuJuEASWZSnVN0nvpySTlbOlTJGXxcfk6doYEfV1tMAxc7T8SSk3xvm0nojH40qpeCwuLRmGoVIqDMNyQ9AmjNKr5TiO1pr7uab0RySdGmNMYGBZcdsjhuMJZdBNMi8QEiyAAUdLP22cpNtswBrVbszWORYqJGlY2jaYZBBCspQiZ3P5iy20gG9H7KKyDWzbEp7oznZKBxAKsAwckOXYFblcCMtRoXEsE4YawrGFA1JMxsACLAETefMIGC\/upbt96bl5hmV5rAOhjQMhpZvL6zw8Fka4eZCyNABoATAsIyxTjKIo1\/2TiRT\/DGgRKA4D2LBdKaWEk8mFVkV1ewjfQAhIH4NtC4HJQAYOiCCMEMZLhz4nUqFBECDhJVQeFSkvr3wAzHEDSASClGRlVEggz06QFTeayeQFk4EDFkyhJgAOQpasXOlmARa2ZTwb+YgxDgqpZi3AaGEQKc6ZyRhDgu2UUiCCJAgyQKigyaK8CQDYIpoVBmSKnjm9BfWomDuLgoAIo4XRQmkmCMd2PEshF6DLhc9IJB0dABoOwSIECpSSnRq1MUsqYYtQaWpPIxa3hYAloPwg4VmhZhABtg2AQoIQCEFGumyYWEujNWBBCi2UIcHsEGDBCCEgKDQIMqEtwhhgsWBE3noAG4thYATyAEI4oXB8RZqIGXHPIe04AkabdBB4UsJJ5MKwIuVl\/TxYgC0uVNVTBB8w\/bckAwEYQhAVDYwciYTDWocxz81m4AMqic4AniZPgEIRCMGpeKtCdSwOFQobPlvtIbkVAoCr4acDN+FoDgBYHBgyhICFyFuegbQFsyEiDrWKXkYFUhLkOVojk84k4wmfhS\/iyiJhgxSkgCFlhAJpklYetg0I8o0yhqxAIASkQNzAZtiQIAaMITCFAkpywGQFViWRnUunHUtEVovIEgK2GMKwAAumYhQTCWNkJqdJqLhXqUUQaPLJYQsQ7BpjGyMNQuGEJDhqh1RPMUcGsWDaZBlxZs7lckIIx3Ei7oeZLcvq7u52HCdS\/0fs0WdN6WeDSIkWBEGkQJRSZrKZaCND0Ulvc5bT\/oso55Ei8S8MQ9ten5CIjQ8R\/xPxvUEQ5PN5z\/MilxlmjsfiSisqFvguXbXJJMD4jFGyfrz33nsTJ06cNm3atGnT3nzzTQARh1qOz5rY\/yaiN+rV114dM2bMlClTpk2bNnv27M+aqP8tSvKGUmrGjBl77rnnvvvuO2\/ePJQpmT4GZCuK+yb++NN\/7ujSxhjD9Nzf3jjkxEuPO\/VnBxx20fU\/u6817WtbPPncq6ecfsnx3zr3rQ+X561YXsRDsh+Z9acD9j\/35FOv+2BxF4hQCA7p+TMQWphQWIqrQq565NH\/M1pIMAnNXIyUAPmaYDmdGVx59c+XLltpSdtXTlYjEJYiB+yALQOP4TEsTSKdVUK6ocItMx5auqKDyWPyjLEEUd3SxrvvfzSnRYi44oRCSiNRTHwkzMDRtUTSkNBCGCtGTsWzf\/xHV1c66+dD6T32zL+PO+3yI0++9MQTf3DzTXdnfcoZ8eQf5xx41PnHnviD2W8uJOEYSuQNfvnYn4889owzv\/uTuob2tjQiCcrAZlhaQAloIVjGhF0p7Pjy+u7n\/vBPhgtEjB2UMKGAT3YoHDvmdWTMxT+6eeHSNrBnOK6QDERck6WF0CQ12ZqEJmghjLC1QBBi5sxZKxp9AxgDA2GkXLm65bY77g0DgK1QuoFwNDkM62OWXDKGjP7\/7X13nBXV3f7zPWfKrdt7Y+lVRI2a+KYYjZpYARGxK4loTGwRFTUoqKA0BVEsqKhYYixRE40mRmMLKtLr0nZZtve9\/c7MOef3x9xdFlyM5vcmvJJ9Pvejy7135n7nlJlvfxgEaTZ8DvO+\/qf39tS0agaYgVffXDfuouljJ90xdtJ19z\/0uM0RAd54d\/1Z51534cXXf\/RZRWdcWhbnGn9y2YuTLrz14inztlU5xAw7IYTSHWUKZUqhQyqSAlIpyR2e1hbFy3\/4U9K2OQNTEi6fIEEANrE4oT6MaXc+vKe+WUETMGz4bHgc8tiMCQabQXSVHQkybGhxyR54bPm2qibBIDXYhLZosrKuae7CJQnJpO7tTMIij8UMmzFBJFNk5wfoNOCuISVJwSaPRd4X\/vBmY3tY0zXLwut\/XjHholvOvOCucRfcsGjxAwAsqb35zj\/OnHj1eZdc99GnmztjLJLUJadHnvz9ORffcMkV07fs6bAMHnNsmzQJTcKtqNIkNEFMkCZ1ozOm\/vDa67bjSKbHkuoPr7999vhLTh9\/+cq1lY7QoPGoooef\/v25F111\/qU3rN9Wl2QgpgHgYFBMECxAOCqZUC+\/vuKss6eee+Etp5w6edacJe2RuHIDMAoAEzBt8grySHhuvfPezbuq\/WnBYNBvE7Pd+hnlhsggiNmM2QSbYJPHJuOxp17YVlkHwxOOC0dwf8DcVdW46MEnSBAUs8lrMX+SvDYZinS5tyqG9+hUdsiCiObPnz9ixIijjz765ZdfdrWiFStWHHHEEaNHjz7iiCNWrlxp2\/bBFvOgQSm1adOmKVOmVFdXSyljsdgVV1wxbNiwk08+ec2aNW5CxzdtoNKHXtFTRxo5cuSIESMObR1p5cqVRx111OTJkzs6OjRNE0LE4\/Hbb7991KhRH3z4AQDXJul5iPZ1+lqCoBwI4TywePH6jet0XT\/55JMnTJjwb7qMbx3csQZg2\/by5ctXr17t9Xo\/\/\/zzJUuWLFy4MCcnx\/20G4eSKUJEoVDopZdeevfdd4uLiz\/\/\/PMFCxYcc8wxhmEcbNH+LeieO6XUG2+8UV9f\/8EHH2zcuHHOnDmPPvpoIBAwdMN2en+8OY7j7kCmGREbjz\/9RjTSfqKiBPGYg1UVNXfcPWdEP\/gVkLD8acaLb63duGX3M0vmSce5edqCa66+tv9gz9JHl\/u14B9eeai2Lrn0kcUzp12Zk+23HGF4NcYQCSW9hk7SMTkPJbWqEGbc+eBZxx9mcO4NZFgimXBg2cLQEU0IqXOPD\/U1SnFvXma2EExqaIvBUAh6GMWTXEnofttWBlMer24lBBmIhMGNPJ8\/K56ET2e2YNJG3LFIJ08AUkIxIyGgHGQFwIFIKO7ze6XjMCX3u9sQcaWIaxp4QDhY\/PB7NdV1px7vNzw8Duyq75xz\/6wsPzIUDCAi8fZ7n66vWPvE04vjMWvJosX56RcNGZa39JmPkgl685XHm+paH3jwiem3T7UU+TSmA5ajbKWBGRqIGEmJhgbcOuuRM049WbnOeObYJJiJaEJKAd1AbQyNYW7pgazcLMEgpRHjsCU8Gqxo0mtyAB5DJ6AzIjwGAUYoHoXmz8k3wREOwWfCSaiq+ojpLUz3pMctRAhch8fhEKSY4Ht7fuzX+EkClmJSSF1x01F49LE\/hdtbfvLjk2yJzrDatbvlrrvuGjkEMo50A7EE3v57xbqNFa8+uzDc6cybuygr95eDB\/geffT3vqDn6Wdnb6vHA488evs1F6enecGJaUjEOHNsgzkmh8k9cWVW1GH6zIcuHnu8hKYxKW0lEtySgge1qA1DR1SgNoG46fX6A1CarTMHiAtwBo+ma9yJC4iknQk9EXccnxYWaIlADxZk5+dJIGGDE8jw1jaFlOaXnHEDtkDSQroPtgBTkGSTkkzqAN+\/OKRLX2ZChWwpArTo0dc7O9tPG5dGAsmYXVHTdts99wwcDplAkYZkPPHWR5+v2bzzD88vDnVg\/tzF2TnD+vfHI0vfzPF6fr9swZ5G66GHHrzj2smZQR90g3PEY5DCIWZoXDM0SipUNeKO6fef\/9PjMoPeOPDnP368c\/uuZ5Y93Wphwbz7Cq+6lJnmoidf1z3Bl5Yv2bN7zyNPPH\/DdTcMzCdTeRJJS+O64hASltTCFnbVRO6eM39AP\/g1GBb8mtBFTEqLMVMpv9RgSZiGr7KyU2jpGQVlgqMhDDKhSQRIS4bDpgcWU5bpcZhhx6DpIEJba9SCWT6k1AK4oWvCiUVkqDOhkzdd05NJGdY8CQc+E8IhnTSSDgAiRiCwlMnX1WWuZ5l7z\/Ze3z53uOM4rlN\/1apVRLRu3TrLsq688spRo0aVlpa+8sorn376aXZ29t\/\/\/vf777\/\/wQcfzMvLO9gi\/0fh9XpDoZBlWUqpF154obGxsbOzMzs7e\/bs2SNGjHjsscfWrl07a9asJUuW5OTk9Cx67MO\/jJ46UklJycqVKxcvXjx06NDs7OyDLdq\/CyeccMLMmTMDgYD7z2AwOHPmzMzMTE3TpJT7FYfgazpF7IQNoL2j48QTTnjqqaeWLl26c+fODz744H9X9G8pusuPADDG5s+fr+s6Y2zkyJEAKioqOOPdcahDLx7COQ8Gg7Nnzy4rK9M0bcCAAR6Pxw0OHHpwXURu7aMQorq6+thjjw0Gg4MGDRJCbNmyxbZteYCOm90lNADiScyZ9\/Rb73zk82f4\/Yw4q2to2rl92\/Sbp\/38ghuXL3uNyGhotlasWnfWhPFcJDXbycsta+1QtTWoq2k+56zTfBoy0kzD62nvDEdiztMvv1UXQafEo8+8snLVBijNkWzH7sZpMx5ujziFpWXCcds\/MYN0DT5B\/IWX3zr33F9e+av573\/yeUH5EG96TsxS8+9bfvnlN192yW\/Wra\/lhlf3+Zc988rmLZWM661tsVn33tfYKrZub+7sdB5e8rtLLr35wYdfIRMOobK6obC4NJ7E6rVNEyfddv6ldyxY9Fw4AumAMe1AXKlKKSkhBdo6cNuMR\/7690+LygYG\/KbtYEdVeM3qjTdeddtl5\/7qhad+xwkxiZXrK86\/YEJOFrJyDdMbDMfVjl1WxeaKSRNO8QJZfi\/TzMZWK27jsadeaI4iydkjy15cv2mnLcmW2F0TvXbqbfWtofKBQwEAUimlwJJCN7zmwkdemHDB7b+euuQv739eVl5ueBF3cMc9j58+7spxEyav3VghSBOEx5969S8frogpFbdx1+wHmtrC2yv3KG7Ove+ls8\/97bJn\/6g4yNCb26N5BQMcwoYtteedf83ESdfdec9jcYuBDtRfmDHlan7SIdUedubc\/9I77\/3D4w9IBovQ0Nq4fcu6mdPvOm\/iTU8v+4Mj0RGyP\/zow\/MnTvAB2X4NmqeuLVLVIDft2PHTn\/7YtsF0JKXTGok1tIXnLlreEkNCYdnzf1yzaVtSoCNibd\/V+Oub7qpuifkycz0+L1PgpDRuGD4zQXj2969fcMktN9\/yyDvvr8kqKk\/LTotLdtsd9\/\/srCmTLr55xarqzrgVtdWjy57fvL1W8\/tDcTlrwaMdCWyram7tCD\/84BPjxl350KO\/74xDaqht6cgr6W8Bn63ZM\/HCa848e8otdz\/eEhZOj26wTLFU++IvgesGSJ81e9lf3\/0oMzuf67AFausbK7ZsmjF95gXn\/Hb5k6\/bDjpDiQ8+\/HjSxAkeIMsP4r7GlsSeOmytqDr95B9TAjrTHKnawpHG1tC8hctboogDy57\/47oNO2whO6Lxisrmq2+cU13fmZaembTQFsWHK9ZNOGtsThp8JtKy8pvaYxVVHXuq6ydNONWnIeDVHFBH3KqqT9z\/0DOtUcPWaPGS369Zu5MMra6h4YvPV9xy4\/QLz7\/pycdfF0oSKUkw\/emOMpWGRQ+\/eubZ114w+e4\/\/u3TnILitCxqimL2fY+MG\/+rs8\/51Scrt0stKPXAY089v37TRhA6Epi\/aHl7BFV1bVFL3bPgmYkX\/PrBR56Gqeletnt3w6CBo5I2rd1QeekvbrroFzfNWvBsc6ctJTNN0+3VJsG+osP+tx1CCMuyTMM86qijpk6d6nZPGTNmzKZNm7KysubOnev3+6PR6JFHHqmUqqioONjy\/qcRj8eJKC0t7Z133tF1PTMjs6CgwLbt5ubm8ePHa5o2ZMiQwYMH79y5UwhhGubBlvdQwH460rBhw2zb3rZt28GW6+CgVwWYdRedf0VDXt2jA8jNzTn8yMPdlMGioqJupeq\/HLILjDHXAvF6ve7GjsfjmZmZsXjMjf9+e2uPeoVrU7k1MIyxRCJhWVZ7e7sUsqCg4GBL92+BUsowDLcGy3GchoaG0tJSKWUgECgpKdmzZ4\/X643H470e69owGteEEMueejI\/L2fyxRcVZebIOLjAlnVrRxT5\/7T83mVL5rW3tq7cUL2jNuQNmDk5pm6axAzT9BqGZ8vmqsKc4gyPMoTjM5CIJiCporLuLys2XXnLA3cseuvTzXs0X6ZgrKYjPmfxg5dcOP773xtaPjAziXhCJgFoDmmMP\/7ip40R7cXlD0+55OzlL78UKB7YCSx48Kmjxgx96Zk5i2bf++jixyqqOhqjqNrTOXDggGgcbe0xnz8rLY3XVLdtWr\/lnAlnPv74nMb2jk2VcVtHTWPosBGHb9\/adM\/998++b9bjy2ZmZZtvvv33WBKmqSdisQPwDEgh4nFLvf7mX3NLisaff1J2sRG3BZG2ZdPWQYW5Lz8y6+3nH2psDX24es\/6Tc0m1woz0pyoQwK6nuZIWrvqi2H9cwozoEtwoWlC04RRW9mwbn31L29eOPvBt7durTXINBicOBbMm3v5ZReffMIPdbLBoJCUBKl0TWNLn\/or93sfWXbnlCsueefN10oKMhJJzF748qjvHPfqi48smjtzyUOP1DeFWtuxo7Jp+GFjLEktHTHNTA9mpre0h1ZvWDfxgnMeePju6vra6rpOEBrr60Yecfgnm+L3PrjswQfm\/vHlhf70rDf+8rH8KtcPg9IkDEeqJ555Wvdp5150dumAAt2LiI0t27cNKNZffnr675bNteLtX6zdVVm5uyTDHJ5PHil0ZQGwGftkzRf5\/QpyM\/1+HZkB6KYWFfHmaGh9Zc31v334vkff\/mxdpSe9gLzeiEX3Pfjw5MsvOvGk7xUX5TAiIhLEkpoMAQ8uf6cpRs8tv+eiCT\/706uv5uSVRBlun7fgsCMH\/+mNx+bMmvH8s8821DbZcarfHS0rHtYRQUgQfJnwo661dcOGdePP\/NljDy+qa2xoaLekjj0NbUNHH\/np6t2Lliydeuv0V996LLOg6G9\/\/xQcUDqUBnJAVq8+eAkWEc7DTz6Zn5s55bJJA8syHBtkomLH9kGF\/teeuOPlx+4W4eTKtXsqqppzstPLS7yclMt+LsE+\/6KypKQoO9Pv1ZEZZKbusS2nPZTYsr1t6i1P3\/fI3z5fV5mekW56KCzi8x5efOnPL\/7R8d\/t17\/YIqyqaOP+7KK8XM2GCXBwS3m3bKsaXp6TbcJP8BpeLzPthF3X1LhxV92Nc5+79q43N2xr9AUyJMP2bRtGlQbfeOaux5fMbWxu+Xz1GptpcTI7Be8gbd5jrwpdvfj6okuvuebFP\/25fFBZNIE59y\/rP3TUc8sfmj9\/xhMvvLKt2aqJUm2rU1JYBkvW1dRbxJkXu2rr3\/vks7Hnnnf\/kgdrWtq2VtXHHDQ3dQ4bNvqTDdG77n9mzp23PL1kls\/ve\/8fKy2hkgmbKTf6xLpMEdn16nmfkntf30Kkp6f7vL5YPMY555wzxkKh0Lp164qLi90nr5u8UFNTYxpmUVHRwZb3Pw2llK7rGzZsePfdd0866SRiFAqF9lMNbduuqalhjDli\/3riPnxTuDqS4ziujiSlbGlpSSaTxcXFB1u0\/0P4WvEQYdukQUrhJC03ZbC1vS0zJ\/tL97D\/Rrh1At35lK5BIqV84oknJk2aNHLkyF77AxwCcG0qxlggEEgmk4yxeDy+bNmy8WePLywsPNjS\/bvQ3UvEcZzW1lZ39t2CdcZYNBr179P8dB9YluUIh3N+4YUXXnbpaa3NTUcfOcKjQRFOOeWUGTf9OsNARgDDR43ctL1qd21zYW5WRgASCCVEe6TN9FJ19e7S0lKfj3PutHcmTa8\/mJ5WWtZv7sJbigaM3FLZMGP2zWOOKAODP82\/aNFdY0bl68oyOTgpWziO4g60+obE1i27zj\/3ZybHyMFlx33v6MLCshVfNEvN990fHkM6CkuMw474TnvMbm6zg+kZugnDi8bWUFZWFhSaGxt+c901Awf7gllIy83piCWb2rG7tsH0Z\/z5r+9NPP+iojKAYcxRY1rbO7kBy3I8Xu1AtwpN55zT2WNPmvLzM+1EaMSQMs64x4PTTj76nrsnZ3rBoMqHDP9iU0VtfX1+QZ5PN7L8WiKKSCyRmZ27p642PyuYDAslEA5HhSOyc1Dev+iOu2\/NLxu8eUf1rbfdNGhgmWPJrEw89vDM0SOGenWUFAelclnCpSJs2ZrYsGHbuAln6l6MGuY\/5qjDB\/Yr3V5RmbTiJ\/xohAYMHVh6xBFHtHdGQiEU5RfonAyOltZO05\/h8WBnZc3lV\/yiuAQZmSgsLu7ojIaiqrm52fR4\/vDOBz+dcGFOoceW+OEJp9Q1NH\/FyuoiPYSmmZdf8fMrfj2utaP5uGPGiGTSNPHTk354+7SrdSE8DIcfNvLzL1Y1NDTlpvt0BXJkOBQTQmbl5uzaXTNw0DAhkgxobEzYtp2fnzV4RMmsebcEc0t2VNXOnH1DUUk+5wgGAvfNnzFqZHmaz8zJypTScZRMyGR7MtzQEd5YsXXSBWeCMHxYv+OOOaIkP3\/tulZPIOvU036qaygp9o4aNaq1LdraFstIyzR0QMfu2oac7DSvjrrq3b+8fMrIoUW5WWZZv\/7NLR1NzWhoagsEA397\/8NxZ08cPTpXEUaMPrKhqSWR2DsEkg7YslGCXf+bKVddNba1pXZgWV7AQNzCyaf9ePq0X3EJU8Nhhx322Rcbaxo6sjLSdAUIGQ3FhLCy8zyV1bsGDRoiHUUKTfVJKymz84sGDS+ZPffazJziHZW1M2f9prC0yL2VLZx\/56hhhdmZaR6\/LgnVtTX5xQVpWbpksBy0d0b96VnNzc39i\/NMKRNJGe1MklSZaYHhh\/Wbfuc0w59dU9\/x2zuu7leeDYXTfvazGbdd7yUEAxg2bPjmzZsTls0MXWqorI9v27X7rDNOIcLg4WlHHHNMcWHR9s07mMLpp3w\/K4DSwpyhhx1e2xGvbrG5NyMvI0fGk8lk0uPzgmH3nsobp93Qr7+en4ey8v7hRCIcQ2NDIwivv\/3xWedempabafr1Y477YUNDK9NI141vF+fgv4bOzk7GmRDCtm2l1GuvvXbiiSeWlpYee+yxGtfcOHYymXziiSfGjht7qPrLvgJE5PF43n333SlTprg5abquB4PB3NzcV1991XGcbdu2bdiwwbZtxlg4HD7Y8n7r4epIwWDQ1ZGEEIsXLz7\/\/PP\/C9feV+BLDCC9vbiuQwqmQcG27MTfP3w\/YVuDhw9zqW\/7rBHDMNxyCNfeDYVCM2fOzMrKGj9+vJuN4zYs7\/7+t7ov236Ix+OxWMzr9cZisRkzZmRmZo4fP\/4QjpXF43EpJefc7\/dnZWVJKXVdj0ajbvNiXdfDkfCBcvDc5EgApml0RNHS3pif4\/V5YXMkHKkTDAXNhK1kRzTc2FhTmpXukbCAdks4LJmRi+a2htJ+ZUrnjm622raWHtQ9pmnggYWvSMceMWzIjTfcs2F9NVN2mpn0ceypbOPKKAxk6JZO8MShhXXUtDYPyM0sDSDo+YdOKwAAHlVJREFUBVQyk1MG552tnSNGj9HS4XjQ4SDk2JaU69avGTig0OODTaisbhg5fKidUB4eKysLCI6WOOpaW8OJRFunZfg9yoOaltCSpU+NO+fW8y66\/p759yVFVEjohrKT0Z7uVUl7X5pGpg4vR3uNbKrYXZqeZ2iIxpJeA46DJDlxgmPoESfZFmrJyAzoGqSNWEQSpANKJEV5aXnAxzU\/msNt2XnZSQtCx7wHfi9EuLQ066Zp99bUdUKLJuwwJCp3VhhIZgahBEmlC7IUnNa2xkGDywtymU5IRMGEyM8tbK6r\/8FRh\/k1KMdOJJJtHZ1EbPPalf0Ls7N8hgbU1TUe+70fdIQgBfUvzVdJIImWupZkQoTCSWKeaBK7auofff6VUy+452eTZs6YOctj9O73kdTFWEcOwYFwNIa2DjQ0NqTplO3lhq2YowyCx+AKsGwG8rR3hsv79dMMJITe1BoHoBHam62yoqFcN6LxZFtHyNQ9JslYe+z++39HxAcMKLv5xnu2V+yBDU05mkRTZZOPmzlBIiki8U6H7KzM9Lrm6iHlwbwMhC04mvKayYJMfc\/OHaOGjgzomhWDUgiFo8yTvnHrjhFD+jEJjaOlvuE7g0tlsx2w5ajyYi4hbDQ2tDLui0TBuDcWx45dtY88+tS4ibedeuZNC+YvYnD8HnBmEbcJJsFL4L32r9QYJRNoaHWaG2vLsjM0W2oMCpAc3IMER0xGbcbaOkL9S0sMDZC8o9OS0jE9aGlpyssrME3OODrakoaZLjSjJYz5859nKj6wLO+G62du2bE7KeG1yJtAXVWjrqm8vIACmuu3lpaltTmJNinaE9BMvz9ILc21ZcUljJjXZOGIZZpeTUdnCPPmPeVRHUP7BW++ae7OXQmmIJLQNXATjgOvj3Eok3NylHTQ0dk4oH9RSWaAR4Ek0jw+r2G21NWNGVKWbkAlbCsZr2toiDvWtl07BwwexBS8pre2pvqY7xwhBTi3+w\/IEgIdIbS2tDhx0binLj3TVITa+p3LnvvdhCvuPPWi2+6ctxhcM3TEIzH3Ua0kSZXq3tbL61sOxlgkEvH7\/V6P17btc845Z9WqVUd\/5+jp06d3dHZwzqPR6L333puXl3fGGWccqj2LvgLJZPKDDz6wLGvUqFGc81gs5npOJ0+e\/O677x511FHLli0rLy8fNmyYy\/NwsOU9FOAyaWiaFo\/Hp06dmp+fP27cuEOYP+RfwNceC5KOndTNwOw5swcMGjh16k3cJWQ+5PtufA24BQNEFAgE6uvrp0yZcuEFF44dN9aNx+m67m71Q6wyxIVrYrW0tFx55ZUTJ06cNGlSN6PIwRbt34Xu6r3CwsL6unrLsjwez44dO0499dSvb4C1t0agbJ1sx2KbKxvefuf9KZdc4vehJYQtO3b++IST16xdU9qvnGtQFioqtpeXFaQFITmYPxAhKJ0++seHIw8b7PGybRUVXopd9cuzg0E89Ujrrp1bxgzLZ0iQLVuaakuKCrgEESOCSzxtCWFw0nXEJRrb2jub9gwp06p2RjUfE4AgNLY7Ta1txWX5mzauPnzYsGgSoSS2VjUcdfTIpG05Unp84BrCIRWLh\/ILcqKJUDA7TfMhIy\/j4Zvn5mSDC+gSaRo0QCTjgYD3QJ1pbCFiMcvU\/Myysvz+dJ9hO05tQ+0Lr737y6unGKYWi2H16i\/OGDdh7eovBpYNUwzxJDauXTt8YFlBDrjG0rJyLQZb4uOVq0YcNjgjG+s3tqWbctqvJwX9WLr4za0VmwYNGiOkLR10tLUWFaRpXRRuiqQkyXSedKQAhEJ9S2dTR6Pu05SmYskYOEjpVdW1oVCkvLx47Wdbjhw9LJZU8Wi8qmrn0MGjGYFpHr+fdB0dbZASOXlFzS2NvkBaWjpycjOm3XlZejp0B2lAlgFYB+B+I6lSBNxIJqIWp0jI0TkzDU0mrB1VtX\/5+8eXXH4Z8yLSiVUbtpx1xumrPl1hpKVFFZiJjTv3DBsyuCATQV+Q6UGLa1pQW7dm1fe\/e2RORuDjTz9PM+QVvz7VQ\/jdU5G2+mp+WCkpy9C1UEtjYWYWSUAhEAgkmIrBIYZ0XxqTIAM1dR3RcKgwz7MRlhRGVIA0VFV2NjU35BcWrlm3dtTQoVJHexS7qpvGHD7SqzNhJ4NpcCQicUSSjmZ4OiPx\/MJirx8lpf0WLZ6m6bAUdIUAAY5kcJhLXnXgpinJeMIhRDqiOtfSfT6Tq42bd732p79ce\/2Vph9WBzasW3fWmWd\/9tln3kBWwgEUNmytLCktyAoiPzMYDASjNnwG1q1e\/f1jjsxOw4qVG4Ie+aurziCG5c9GGxpqaVQ\/7ii\/F52t9bk5GUpBwYKwiooKmdfjSKxau7a0JDs3DxKO7k1zGNojeP+DFaNHDC\/OwUef7EnjmPLLScEAnnwc2ys2e7ShL\/3+heuv+wXjMANYu3b92B8fyx3H6zViEcGYbnh8ioM4WpvQ2tSam5FZEUsaZobS4DX1LXs6Ewlr+JDcP\/6p4vDhgyyGpI3KPXVDRh+ZTEBjXkPXOYfGEQvHPaYvHI3pOsvOR0FB9vXTrsopAhF0BV0iEYdH40rZh4Dn66uRlpYWiUSUUsSpu1dKcUmx2xWqurr6mmuuueyyy0455RT300P4OdUriGjlypXPPvvs888\/D8BxnKuuumrJkiVlZWVvvvmmruuNjY0zZszIzc3tpug92CJ\/6+HWD0ej0RtuuOEnP\/nJeeedF41GfT7fwZbr\/xCY7D1LdF9I4XKnz59\/78Tzzztt7JkkJQNczjNxSFKBfBO4iqlSKhqN3n777ZMmTXKNEPemH4vF9uOsOdjy\/m9C1\/VIJHLPPfdMmjRp3LhxlmV5vd5Drxy\/V5SVlX308UeJRGL9+vVKqVGjRnW3Y\/9qMKh4R9uRw4ZmeAMi4WRnFW7a2fDF9vYWiTfeWxlLWKOH5g8oyf1g5QaLobIq\/PlH75931mm6QlZR\/qaaxrDCB5\/XtjfWnPT9MRq3x4weeOOVE9OklSYx9Yqzzjj1+EQioqSy7ET17u1Dh5RKBkUSkARBNvJzM9fv2r07gnoLT734ema638dRVhZYs+HzRAJS4NnnXy0qLQlkoL6lwZ+T63jw4htbt1S1+XPTK\/Y0\/vUfq3bVoyOO55\/784ih\/cvKtK1VFZmFWcyEoo5du9vB0NCMqTfds7u6VedQjnRs60BDIaRUyiGGyt0VRUU5Xh8AKZm5aVfzio3RDoG\/vL+9IDPt6KEFA3OyNq3Z2J7E1j3JDz\/4y4RTfxTk8Bhq7baqdgcfftYYS\/AfHP8dnfDdUWnTrx5fpsPswA1TThv3s+OkY4Clx5Kob2gc1j9fEzFOYVBckhTENI+\/rinc2IGOOF7+89vBokw9G9n9s9Zs3dUaQVzhldc\/Lskr9XvQHBMspyRq8uUvv7Nx\/Ya8DH3TltZPv1hT1+gI4I23Piop759byCt37+lfXqgTNISbquN+jtoq+5ab7tm8eQ\/rtY0B7XMPDvp9aX69tWHP8EH9fX5TaN7c4n6rNu1Yva21MYa3PqkMC21AWVZ2VmDVlp2twKfbY39bserMM07J8CM9K7i9rj6mY8Xauro9FT86ZgRJHD169PRrzi\/ywJO0f33p2JNPOMqKd5p+wxGyvm5XeVmuklBwAGjEIEROMG\/Xto6WJkTCeOWVvxqegCL0H1SyduuGRgd7wlj27AsD+5drDG3hmKdwQMSLR5\/\/x+otNcqbvrlqz8otm3c2wvHgd6+9n19YPGiotrNyR0Z2uumH4mrj5nYQWhtxzVUzdlRUkZJ72RMP7I8PBIJBv95S1z584EiucShWVFC8u7p5TUWoKYRP3tvMY2pIaUZulm\/V5tp2gQ3VeOfjzy676FyPRK6f79i60Qji4y+a6mo2H\/\/dISbEd0f3n3bthZle6I515eSzTz7+OCuW9PkM20FDze7yknwlQYoNLB+2bnV11EZVtVi35sMJE36g6dCD3nU76ztsfLGxORyyjv\/e91gUx48qvfvaS4t0ZAHXXX7mKScemZXrq25pXLW1KaLw2hvruTIHlPXXHGmHE17O0\/3Z26tadrShIY5X\/vD3oCfda2rF\/QZ8srG+JolN7XjmtU\/69R8QNBFqCqWnFUQ5Fjz5lzUbqvILAtu3hT5bsbu5AUxi2RNvlfUb3H9w0c6amvySUqEgpLNnd6uPoaEWt9ywqLaqw2tA5xqR5jZHptRKk729vt2IRCIAlFLLly+fM2dOOBwWQnz00Uff\/e53lVILFy6cPHny6aef7iZL\/xfyY5imefXVV1dUVKxevfqVV14ZPnz40qVL8\/LybrzxxjVr1hDRPz75h9frDQaDpmn+N\/c1\/l+EYRhENHPmzLPOOuvss8+2LMvn83UTjvUB34THkO3cUdmvvF+\/0n4amEDqcaq+qr79vwWWZQUCgWg0WldXt2PHjg8++OCuu+5yeZSee+65733vex0dHcFg8GCL+W+BUqq6unrr1q1vv\/327NmzXUV86dKlRx999MEW7d+OsWPH1tXVHXvssYWFhY8\/\/nh2VrYjnK9jg5GSn3\/y3v9893uGRkoZmYZ2\/a9\/NfOe+8LhcHFRzm1Tr840cfqPj6p4\/JUzTruyf0HGnbfdlBMwJHDuGcc\/tHT5xKWPDSwtmjPj+iw\/mLQ1JT0yken1wrYSiYRhaKbpk8oSjtPcXF1Skq0otVsZpMbUwLL0n57y\/UsuvCq3wDv29FM6qqtzgjh2zMC62l2XX\/CbZFKOH3\/aZZNPciRGDi6\/\/daboAWPPObEMWMGeUzU1lRdcP74Rx96oLm++aen\/M8l559lJUNNVZt\/dtqpPmZdfO7pd8xa9MCcSNDErNtvHlKWLW1oGmfEpOwtDEDSdcNDYvOWdaMPO4xzELF+JcU3Xn\/dtN\/O6wglhvYvuu\/OqzMJZ5543BPPvHrFz2\/WdJp1y7Vlhbpl4arLz5254ImXXnoxKy39t7dc79eFQY5Hs+14wtCzwByDGw7BljweV7ZNHW2txXmZTCZd\/m6mwCGPOixzy9Yhv\/nlNN3Dzzz1J9Foo8bFYSOH7t4e+uWVtyWTyZNOPG7atedaNkYMKbv11ls6w7XnnX3mD44enZuBtevqLjp37JJF86p315xwwk+uv3Zccyt279o8\/qxTCrJwyaTTFiyaO7e+IT87ffpN1w4bUAhh9R4PSd1Iu5iMhdyyduXo0Uckk\/B5yG8YN027+cbb7myP2SX9h0y\/+Ve56Zg47kfzHn7psouvN03zrjtuzUkjLnDhxB8uevjZZ59alJfhn33rDQUZnlioMy09IIVtQg8EtGQsBim8Pl8kFu+M2h2t9QU5QSUkgGg0Yfi9BqnS3Nyf\/OAH11x+czDoPe2Mkxqb9hRmIOfw\/s2NI3\/x86nJhHPOT384+ZJxPi+GDSy77jdXm570caecetiogfl5xucrqy66YMLcObM6mxpO\/dkpV\/3i9M4O1Oxcf+aZZ\/oYfnnpxNvvmBEJR4jovnvv6pfnN0iRZKQgSEL1TljAFKRwFLSN61YeMWa019ANnbLTzanX\/XrqzLsikcTI4v6\/vfm63HRMHPuDeUvevOyiO0wPzZn929wMyIQ8Z+xP7nvwsceWP1peXjZ72rX5mUYk3JIWTEsI6dGZEdCjyRDXDb\/Hk4jGIlEn1NJQlJMO6WhK\/vRH33ly+Vu\/uOg206tmTruiNEOPJ8XkiyctvO+JZ558YsiAfrfdeF26l4ImJIN0nIBXk4T2SNjv9wcN9pvrrrrjzvmNzZ1DBpXfOvWavBxD2gkiRkB5qeeow0fceOP0YCD9x8f9KOmJBzw44vCBtSHzF1fMcxLR88addsmkoz0Mw\/vlzLjlppBQp51x2nFHH+5RaKutueiccx65f8nOHVvPO3fc5Mk\/bmly6qp3jh1\/TpqBn583dvbc+xYv6DA9+j0zbx1RnkYCWheHj8tMegiYHL3CcRyv1yuEmDRp0l133XXiiSdGIpGTTjppzpw51dXVmzZteu+996699lqv15tMJp977rn\/hudUNxhjRCSltCzL7S5j23Y0Gh04cOC111576aWXNjQ0fOc731m4cKFrhHg93oMt8qEAKWVNTc3WrVv\/+Mc\/3nHHHclkUtO0pUuXHnvssQdbtP8E9uv+3KsjnsTXIjWU0nHef\/9vL\/zudyAeTsa9\/sCAgQOn3TjNJVGjr52dZdv23Xfffdttt+1HqdGHPhyS6HXXSTAFA4AmHUXMJiaoi2c7lTIkAUhi2PtPBkiQI4lJqQHQIAkOCU5ATy+7JKZIgizJuE0eALqwASkYAMlBUhGUAQBkAZK5FMucJDQmGABwRykBZUiQIiWYtBkjBVMAgM3BFDQBBim0GOBogjHFBGmCNAkNIC4Vg+RKMiVd5ysRV1K5VchdbUMlUjcpnaArlzmCFGNCKsWELgGHgRQ8ElzCYXAYFAACQbmXLAkqpWC5AR\/pMl8DIEmkwBSTYDaHo7iSjCvoKqGQJA7JXOJBDdIPpSlyaaotRYByL8SdQsngcCVJasp9kxxAcgUoJmg\/V44EUmdWYDbTuixAcOXoytGUYl3ZrD3XhiQwBYIDQEETpFnQXE5BAnoGUdwx1JQDSMFYdy4Tg+MGFhSTSS6Zgt\/SmIKjKUByyZhiRCTQVZ4PSDCXglCnJJTlvu2QrqApYbhnYwrEIAkgKQg2Y+6hlGLDTJFUMiW5kroElJbgkARTOgQJ9SXqRgVFcAgMMKQ0SDJpS4IgBjB+ICvNDecxppTQBZRSkpBabwrMJekjqbrK\/VMTRwlSgPIoMMmc1DikHP+MYEBBMgFylBIA0ySD0izOQOCIk3IIhoTmMA4oj7AI0mZMEFPQUuPTNRQuBSRIByCZBUhJDEpTigGpFQlIBUFELpOgAhPkXhe691eSQRG4BFfgbns1kgBzn5fukmE9Hp6MAHJcV4MiBsUcYoogu7yEDOBKalDkOAAE27tQWS\/WyLc+z9pVtb+cetDnfsa+95xuQt4vf9qTJus\/KF0fDgWsWLHi1Vdfvfvuuw3DMA0zaSXd8OOCBQt+9KMfHXPMMd25Qt34mvEQYpp24kknn3jSKQCTkHaqzO2bGSF96EMfAFexSAAplU5XTFdujbJkyuVjZgAM5SBltDBJjMExRAKATT4FjWABUOD7Z9W7dgUxCcFUUrrqdRckhKYkwWIqlYYhoSkwJgAIkgYggYj7VQVNMkuQQ3AYYCgDACmHQeoAQdquRSUdV\/vhcECW25aHFHreGJQ80POMAVIhCWKuhixdamuVZArC1ReVBmJEUndlVhCsO3yQMnUUpa4FkilGABymCFIXACQXRKQAxgAiEOkCgBKA1BRIxZkCFFIVvGASDMoBAHIkizNIKINBkrKYEkj9FlPEAYsBKeZ4SroKrpQcJCSBS96DHEMQAGK9atpMuSPO3OXBlaNBQTFFDIoA6Sr6KeMtpWwLbW9iCXOIgwlNOVCOhGRgXHmY0iUEwFiKQpsABcUAdzQkkxLkdBs6pJiuBCBAjjt5BAYFpZhryupKCiYk8e7GVqRs1yYkxXSpQzmSMSipI86lVNCA\/auBpWIcDICmQEISMQYpUp1kDxBfd4lFlKWUAmlQxCCZiqcGHFwyBsU4oMMhJeD2UCHHNQY4wFUcJEEalO62SAYBpEAOyOGQTCkCKVK6ApRgJKEcTo4E06TLlS5JAZLpYIqsvc6CLlIORd0pT10rUzkAcydXAoK6zDY4XEm3i64gZjEJAlcGUyCyoKQuGZOMlMbggBIAk8qjyPUdgLoJiElCOXuDGwoAuGJQLMUTTymqe1IpC5apvYQthyS6\/a99OvRX48s+sr4R68P\/P4joz3\/+c31d\/cJFCzMyMoiovb193rx5r7322v\/8z\/\/0mgz5z+MhSqXSOiSEgFSKDG64akbP833N+ty+eEgf\/qvQazxEEGwOQBoC3cqlwwGAC426vOxcOQzStRMEA5fSIy0ACWYIxriUBChJrpXSQ9+VrsMe5HQ1QmVAyj4hBQa513fu+rMV69KW3KiLBQDKA8VAjmSOzQDAFCAFm0OR5MpiAKQndUgPNjr3h1wXdXerUNexu288pOsTpAoDUu8rxhR0KbmSDNIh5pAhiXEp3ViOBARz1SzXG+0wJUFSwtXamWIcgIQgJXUpuWTM0ZligJRMCuaeROshgAQJAFCcSQMkQXEAUF4AkiUBCWUCYOhOmOYpEgayU0cBYFGQhDTdMWGpRh5dP0MMAO\/h+ulaG64Sj+7xSf2dujMzKKYUpXRZgupqNdbzJyQxBe66uiUJkMMlTEfjEsQgwQQ8khgjghQgSVJ1xTS+3G1EdkfkugXouoTUrwviPcZfMCUlMU1yTQAQCR0AdAGmIFhv0+0eq7gmwBRTjBTBZhIAP8CTZO\/ikkpR1+CQBGzJpEzFEXVAcmUzSChNggtuQzF3Honie4NdygulEVOABEswOLoAKQ3S6BoKCeYGiCQp5s6vYI4kcOF2PXPcJQdAUWo1SkoZ9FCMXNuSHMABGJQBpcl9C2Dc3SEYkpwhtb9ci5pxqXEpdWV1jZgmSHPcUCfcDd49Il0xun1PTqq77j8VZN1Hy6QDVYP0ORUPZXzT8tQ+y6QP3xRKKdMw44m4y+jgZgByzt2u2W64EvsuxX8eDyEi27I0w2DEFTgHs6VN0DTGOFLB3z70oQ9fHwRQj1QbBim73PAcXalYAFLBkL2aXErdYT0VCAnam55ESvbQMBiDI1N+UEY9N6piilzv+z5aJlPdYc6Ut9VNbWKKddUTSyaZdFVQxUgxKE3s7XbxVS2PDjwc+6pErq3CJJRbUyKl29WKYW+dy5ehWK+edEkpxdbNxpGQgJDueymPMvbRucGgQK5Kp6AITO2NaXRZShzYR72W1JXikgo7uMk\/rtUH9NT0v7Ya0HXClCD7XjVzc24kCdZjwEkywbruyAqSQF2XL5lUYJIkmGTKtbsE3On+J1MmsV8nK8Wph+OJAUwxKN69wLqyBHUoBvRa6iqZcs0tLkkSePcEuPlpXwc9Lbe9RyuApERqjkgx1dOwUWxvSwC3Rxg53acCoJi70Nylkto4CowUFKWsfd7jbKzLvHSDDEzJ7iXKJANJkszdsmqvqS+7r7T7Qtzrp1SEBFBdK4fcXaClGId7WoypJZoKsIC6J2gvIz1LBTzdMFjKVcHUV\/UD6EMf+tCHfxmu4WrZllIqHA47jmOaZjKZdDm+lVKGbkgl96PU06iHvdt7P0ki3fQoJR2lGDEJ0pnR\/Sk7gFNlP7G6\/+acCyFisVh3Tz18cxu9D334tqBXfxIpaJIAuG38ldIVpewPpQgQJBVSWhXcfyqCgrTcxmtSKQjlbljmHthbGbhigMawVzF1wXqER9xUJQBdcYmur3S946YAcVe1o67vS8ZgdL0j2QEsEEU9bw57z7+P7x17TYiUAqpSInexPqP7ElQqpwWQku89QY\/i5pQrXyCl0TIQFDHJ3SwrJYlAGgegVCoGAjfp3nUqKzAbAMiNbyi3zx2H1qWrat1XQSmZ3HcEU9h7EqVS5ySZmn8Cfcl8Ut2fdU9OyupwVcce+iVR6jMCAVy5ZOEKSktlT3UdL1Nap5bygTNIJRUxpiSQKpFnkN3idV8O9s6M7GXNpsSAa4FQt6wgBg3U1YaJAGjcnWtGihS5o70XXSuCgL1BvL3LRCkhejM094vadz0xiKBxd7C762RStU8EgNzZcRs6Ks2NDbk\/A4i9VwDDNfVc+1wqd3b3muhubRVTDAqKSdkj5zBlCFGX9t9lqioIKCgQpJ6SYd9hJeV2sQMpaMKte5JdNoKQUDYgQCAOIvcdBTeZEEA34yO5SWhufUzXiVMjplK7hlLX2+Vc2Gco+\/DfhL74Rh\/+rehW5l2CFPe\/3T2yicjqrXmm9nXWJZHbA0gqoi+zYKTuuwc4tufXhRDdZBr\/9Ef70IdDGD02AFM9tXAX+zksu7Scbu8v6+1TFz2P7HKW\/0vVqD1k2O\/brOd7X+lb7U5P\/yfoxSXPerq6exNA7vfGfn70fawaJvdPAz2Q2NQj5PKVl7avSBKE3saE7euw\/wZQdOA52nfGewrz5WBCl\/H21Uk4+66afybzgSTrOnBfHf3Ah3bnoSn65y6tr5Bl36tmX\/qru3yit43yZfuZ7b+09tt3Xzk+vazk1P\/3Cz3ts7++dOkkFUF8yWbv\/bQHEOBfXnt96EMf+vAfwzewB5j6uhHzA8FNC9N1PRAI\/H+dqA996MMBwHrZ1b2995+Cor2vPnw9\/Ofn6yCvkJ5C\/J\/xUf1fkuV\/A6w7dNmHPvShD\/9noM2cOfOrv0FEREpKqZRi7BvfmnvGQ5LJpGEYQohoNPr1maf70Ic+9KEPfehDH\/rQhz4cYvh\/tn1oWEmTI3oAAAAASUVORK5CYII=","width":1069}
%---

```

---

## b.常用函数\1.拓补信息提取函数\dijkstra.m

```matlab
%[text] # dijkstra算法
%[text] 优化后的迪杰斯特拉最短路算法
%[text] \[path, totalCost\] = dijkstra( netCostMatrix, s, d)
%[text] 使用 MATLAB 内建的图算法函数进行计算，效率高于手动实现。
%[text] 输入:
%[text]         netCostMatrix - 邻接成本矩阵 (n x n)。 netCostMatrix(i, j) 是从节点 i到节点 j 的成本。如果两节点之间没有直接连接，使用 Inf。迪杰斯特拉算法要求成本为非负数。
%[text]         s                     - 起始节点索引 (整数，从 1 到 n)。
%[text]         d                     - 目标节点索引 (整数，从 1 到 n)。
%[text] 输出:
%[text]         shortestPath   - 包含最短路径上节点索引的行向量。如果不存在路径，则为空向量 \[\]。
%[text]         totalCost         - 最短路径的总成本。如果不存在路径，则为 Inf。
%[text] 
function [shortestPath, totalCost] = dijkstra(netCostMatrix, s, d)
%[text] ## 1. 获取节点数量
n = size(netCostMatrix, 1);
%[text] ## 2. 创建 MATLAB 图对象
%[text] 确保成本是非负的，迪杰斯特拉算法的要求。如果存在负成本，shortestpath函数可能会发出警告或产生不正确的结果（需要 Bellman-Ford 或 SPFA）。
if any(netCostMatrix(:) < 0 & isfinite(netCostMatrix(:)))
    warning('输入成本矩阵包含负值，迪杰斯特拉算法可能无法找到正确的最短路径。');
end
%[text] MATLAB 的 shortestpath 函数直接在 graph 或 digraph 对象上操作。
%[text] 我们使用 digraph (有向图) 因为成本矩阵通常表示有向边。
%[text] 成本矩阵中的 Inf 值会被 graph/digraph 函数自动识别为无连接。
%[text] 节点索引默认为 1 到 n。
% 创建有向图对象 G，使用 netCostMatrix 作为边的权重矩阵。
G = digraph(netCostMatrix);
%[text] ## 3.使用 MATLAB 内建的 shortestpath 函数
%[text] 这个函数针对非负权重的图高效地实现了迪杰斯特拉算法。
%[text] 它返回从 s 到 d 的路径上的节点序列以及该路径的总成本。
%[text] 如果 s 和 d 相同，返回 s 和 0。
%[text] 如果没有从 s 到 d 的路径，shortestpath 返回一个空向量 \[\] 作为路径，
%[text] 并返回 Inf 作为成本，这与原始代码逻辑一致。
[pathNodes, pathCost] = shortestpath(G, s, d);
%[text] ## 4.. 赋值输出变量
shortestPath = pathNodes;
totalCost = pathCost;
end
%[text] 
%[text] 
%[text] 原始代码中计算 farthestPrevHop 和 farthestNextHop 的部分
%[text] 与核心的最短路径计算无关，且未作为函数的输出，因此已移除。
%[text] 这两个变量可能用于其他特定目的（如通信范围计算），如果需要，
%[text] 应在调用此最短路径函数后，根据得出的最短路径信息单独计算。
%[text] 
%[text] 原始代码中的迪杰斯特拉主循环 (查找未访问的最近节点和松弛边)
%[text] 由于使用了内建函数已完成此任务，该循环被省略。
%[text] 原循环的复杂度为 O(n^2)，而内建 shortestpath 函数通常使用更高效的
%[text] 数据结构（如斐波那契堆或二叉堆），其复杂度更接近 O(E log V) 或 O(E + V log V)，
%[text] 其中 V 是节点数，E 是边数。对于稀疏图，这比 O(V^2) 快得多；
%[text] 对于稠密图 (E ~ V^2)，虽然理论复杂度可能接近，但内建函数的底层实现
%[text] 通常经过高度优化，在实际性能上仍有优势。

%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\1.拓补信息提取函数\refactorKPathsToCellStruct.m

```matlab
%[text] # refactorKPathsToCellStruct(KPaths)
%[text] 把K短路存的好看些
function KPathsNew = refactorKPathsToCellStruct(KPaths)
% 将原 KPaths(i,j) 里矩阵形式的K条路径，重构为：
%   KPathsNew{i,j} = K×1 struct数组
% struct字段：paths, pathshops, link_ids（可选保留 pathdistance）
%
% 原结构假设：
%   KPaths(i,j).paths       (K × node_num) 0填充
%   KPaths(i,j).pathshops   (1 × K)
%   KPaths(i,j).link_ids    (K × node_num) 0填充
%   KPaths(i,j).pathindex   标量（实际K）
%   KPaths(i,j).pathdistance(1 × K) 可选

    node_num = size(KPaths, 1);
    KPathsNew = cell(node_num, node_num);

    for i = 1:node_num
        for j = 1:node_num
            info = KPaths(i, j);

            % 有些(i,j)可能没有路径
            if ~isfield(info, 'pathindex') || info.pathindex <= 0
                KPathsNew{i, j} = struct('paths', {}, 'pathshops', {}, 'link_ids', {});
                continue;
            end

            K = info.pathindex;

            % 预分配 struct 数组（每个元素一条最短路）
            routes = repmat(struct('paths', [], 'pathshops', 0, 'link_ids', []), K, 1);

            for k = 1:K
                hops = info.pathshops(k);
                routes(k).pathshops = hops;

                % paths：长度 hops+1（节点数）
                if hops > 0
                    pn = info.paths(k, 1:hops+1);
                    routes(k).paths = pn(pn > 0);   % 去0更干净
                else
                    routes(k).paths = [];
                end

                % link_ids：长度 hops（链路数）
                if hops > 0 && isfield(info, 'link_ids')
                    lk = info.link_ids(k, 1:hops);
                    routes(k).link_ids = lk(lk > 0);
                else
                    routes(k).link_ids = [];
                end
            end

            KPathsNew{i, j} = routes;
        end
    end
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\1.拓补信息提取函数\topology_link_new.m

```matlab
%[text] # topology\_link\_new
%[text] 
%[text] 对topology\_link函数的优化实现
%[text] 
function [link, linksum] = topology_link_new(Net_topo)
    % 1. 构造逻辑掩码：找出所有有效链路位置
    mask = (Net_topo ~= 0) & ~isinf(Net_topo);             % :contentReference[oaicite:0]{index=0} :contentReference[oaicite:1]{index=1}

    % 2. 统计链路总数
    linksum = nnz(mask);                                    % nnz 直接计数非零项 :contentReference[oaicite:2]{index=2}

    % 3. 找出行列下标
    [row, col] = find(mask);                                % find 返回所有满足条件的位置 :contentReference[oaicite:3]{index=3}

    % 4. 预分配结果矩阵并批量赋值
    link = zeros(size(Net_topo));                           
    ind = sub2ind(size(Net_topo), row, col);                % sub2ind 将 (row,col) 转为线性索引 :contentReference[oaicite:4]{index=4}
    link(ind) = 1:linksum;                                  % 向量化赋值

    % 5. 转置link使得其与原代码结果相同，便于后期纠错
    link = link.'; 
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\2.请求生成函数\generate_requests.m

```matlab
%[text] # generate\_request：多播请求生成
%[text] 
%[text] 此函数每次运行，生成requests\_num个带时延约束的多播业务
%[text]  输入参量：
%[text] - id：请求id
%[text] - nodes：节点信息 \
%[text] 输出参量：
%[text] - requests：（1\*业务数）的结构体，包含字段：id,source,dest,vnf,bw\_origin,，cpu\_origin，nr\_origin，时延 \
function requests = generate_requests(requests_num,nodes, ...
    destNode_count, vnftype_num, vnf_num, ...
    maxbw, minbw, maxnr, minnr, maxt, mint)

% —— 每一组业务，先"预分配"好结构体数组 ——
requests(1, requests_num) = struct( ...
        'id',            [], ...
        'source',        [], ...    
        'dest',          [], ...
        'vnf',           [], ...
        'bandwidth',     [], ...
        'cpu',           [], ...
        'memory',        [], ...
        'max_delay',     [], ...
        'vnf_deadline',  [] ...
);

for i = 1:requests_num % 对每组多播请求
    node_num = length(nodes);

    % === 源 / 宿节点 ===
    temp_num = destNode_count + 1;
    temp = randperm(node_num, temp_num);

    source = temp(1);          % 源节点
    dest   = temp(2:end);      % 目的节点集合
    clear temp;

    % === VNF 集合 ===
    temp = randperm(vnftype_num);
    vnf  = temp(1:vnf_num);
    clear temp;

    % === 资源需求 ===
    bw_origin     = randi([minbw,maxbw],1,1);
    cpu_origin    = randi([minnr,maxnr],1,1);
    memory_origin = randi([minnr,maxnr],1,1);

    % === 端到端最大容忍时延 ===
    max_delay = randi([mint,maxt],1,1);




    % === 每个 VNF 的局部 deadline 设计 ===
    % slice 依然是平均切片，建议先保留小数精度，在赋值时再取整
    slice = max_delay / vnf_num; 
    
    vnf_deadline = zeros(destNode_count, vnf_num);
    
    for d = 1:destNode_count
        for k = 1:vnf_num
            if k == vnf_num
                % 最后一个 VNF：必须强制等于 max_delay
                % 这是为了保证整条链绝对不超时
                vnf_deadline(d,k) = max_delay;
            else
                % 中间 VNF：给予 4/3 的宽限 (Relaxation)
                % 公式：平均时间 * k * 1.33
                relaxed_val = k * slice * 4 / 3;
                
                % 是中间节点，deadline不能超过总时延 max_delay
                % 使用 min 函数进行截断 (Clamping)
                vnf_deadline(d,k) = min(relaxed_val, max_delay);
                
                % 仿真系统只能接受整数时间片
                vnf_deadline(d,k) = floor(vnf_deadline(d,k));
            end
        end
    end






    

    % === 填结构体 ===
    requests(i).id        = i;
    requests(i).source    = source;
    requests(i).dest      = dest;
    requests(i).vnf       = vnf;
    requests(i).bandwidth  = bw_origin;
    requests(i).cpu       = cpu_origin;
    requests(i).memory    = memory_origin;
    requests(i).max_delay = max_delay;
    requests(i).vnf_deadline = vnf_deadline;     % 新增：每个目的节点、每个 VNF 的局部 deadline

end
end




%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\2.请求生成函数\sortRequestByDeadline.m

```matlab
%[text] # sortRequestByDeadline
%[text] 将多播请求按照最长可接受时延从小到大排序
function sortedRequests = sortRequestByDeadline(requests)
% sortRequestByDeadline
% 根据 request.max_delay 从小到大排序请求集合
%
% 输入：
%   requests — 1×N 的结构体数组，每个含字段 max_delay
%
% 输出：
%   sortedRequests — 按时延升序排序后的结构体数组

    % 取出所有请求的 max_delay
    delays = [requests.max_delay];

    % 获取排序索引（升序）
    [~, idx] = sort(delays, 'ascend');

    % 按排序索引重新排列结构体数组
    sortedRequests = requests(idx);
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\0.公共优化组件\FixedTreePlan.m

```matlab
%[text] # FixedTreePlan
function treePlan = FixedTreePlan(sortedRequests, plan, links)
% BuildTreePlan
% 作用：对每个请求 i，基于 plan(i) 的 placeLinks/vnfNode 合并修正成一棵合法多播树，
%      并输出 treePlan(i).placeLinks 和 treePlan(i).vnfNode
%
% 输入：
%   sortedRequests(i): 至少含 .id .source .dest .bandwidth
%   plan(i):           至少含 .placeLinks (dest_num×*) / .vnfNode (dest_num×vnf_num)
%   links(eid):        至少含 .source .dest .bandwidth(至少可索引到(1))
%
% 输出：
%   treePlan(i):
%     .req_id
%     .placeLinks   1×M
%     .vnfNode      dest_num×vnf_num

treePlan = repmat(struct( ...
    'req_id',     0, ...
    'placeLinks', [], ...
    'vnfNode',    [] ...
), numel(plan), 1);

for i = 1:numel(plan)
    req = sortedRequests(i);

    [placeLinks, vnfNodeFixed] = FixMulticastTree(req, plan(i), links);

    treePlan(i).req_id     = req.id;
    treePlan(i).placeLinks = placeLinks;
    treePlan(i).vnfNode    = vnfNodeFixed;
end

end % ====== BuildTreePlan ======



% ========================================================================
% ====================== 本文件内：修正多播树核心函数 ======================
% ========================================================================
function [placeLinks, vnfNodeFixed] = FixMulticastTree(req, onePlan, links)
% FixMulticastTree
% 输出：
%   placeLinks: 修正后多播树链路ID集合（1×M）
%   vnfNodeFixed: 修正后的 VNF 放置矩阵（dest_num×vnf_num）

src   = req.source;
dests = req.dest(req.dest > 0);
dest_num = numel(dests);

vnfNodeFixed = onePlan.vnfNode;
vnf_num = size(vnfNodeFixed, 2);

% ---------- A. 从方案里抽出用到的边，得到"候选树" ----------
allEids = unique(onePlan.placeLinks(onePlan.placeLinks > 0));

u = arrayfun(@(eid) links(eid).source, allEids);
v = arrayfun(@(eid) links(eid).dest,   allEids);

G = digraph(u, v);
G.Edges.eid = allEids(:);

% ---------- 资源消耗（用于删边时对比大小） ----------
costMap = inf(1, numel(links));
for k = 1:numel(allEids)
    eid = allEids(k);

    bwAvail = links(eid).bandwidth(1);
    if bwAvail <= 0
        costMap(eid) = inf; % 防除0
    else
        costMap(eid) = req.bandwidth / bwAvail;
    end
end

% ---------- B. 去环：保持 src 到所有 dest 连通的前提下删边 ----------
while ~isdag(G)
    cycEids = findOneCycleEids(G);
    [~, ord] = sort(costMap(cycEids), 'descend');

    removed = false;
    for t = 1:numel(ord)
        eidRemove = cycEids(ord(t));
        eidx = find(G.Edges.eid == eidRemove, 1);
        if isempty(eidx)
            continue; % 极端兜底：该边已不在图中（可能前面已删）
        end

        G2 = rmedge(G, eidx);
        if all(~isinf(distances(G2, src, dests)))
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
            % 如果找不到，直接跳出避免死循环
            break;
        end
    end
end

% ---------- C. 进一步变成"树"：每个节点最多一个父边（入度<=1） ----------
indeg = indegree(G);
for n = 1:numnodes(G)
    if n == src, continue; end
    if indeg(n) > 1
        inIdx  = inedges(G, n);
        inEids = G.Edges.eid(inIdx);

        % 注意：rmedge 会导致边索引重排，所以不能用“提前缓存的 edgeIdx”循环删除
        % 这里改为按 eid（linkId）逐次定位并删除，避免“边索引越界”错误
        [~, keepPos] = min(costMap(inEids));
        keepEid = inEids(keepPos);

        rmEids = setdiff(inEids, keepEid); % 需要尝试移除的 eid 集合
        [~, rmOrd] = sort(costMap(rmEids), 'descend');

        for t = 1:numel(rmOrd)
            eidRemove = rmEids(rmOrd(t));
            eidx = find(G.Edges.eid == eidRemove, 1);
            if isempty(eidx)
                continue; % 可能前面已被删除
            end

            G2 = rmedge(G, eidx);
            if all(~isinf(distances(G2, src, dests)))
                G = G2;
            end
        end
    end
end

% ---------- D. 生成树深度 + 每个目的在树上的路径 ----------
depth = inf(numnodes(G), 1);
depth(src) = 0;

queue = src;
head = 1;
while head <= numel(queue)
    x = queue(head); head = head + 1;
    ch = successors(G, x);
    for kk = 1:numel(ch)
        y = ch(kk);
        if isinf(depth(y))
            depth(y) = depth(x) + 1;
            queue(end+1) = y; %#ok<AGROW>
        end
    end
end

paths = cell(dest_num, 1);
for di = 1:dest_num
    paths{di} = shortestpath(G, src, dests(di));
end

% ---------- E. VNF 合法性：保证每个目的的每级VNF节点在该目的树路径上 ----------
for di = 1:dest_num
    p = paths{di};
    L = numel(p);

    for vnf_idx = 1:vnf_num
        n0 = vnfNodeFixed(di, vnf_idx);
        if ~any(p == n0)
            hopIdx = ceil(vnf_idx * (L-1) / vnf_num); % 1..(L-1)
            pos = 1 + hopIdx;                          % 跳过源
            vnfNodeFixed(di, vnf_idx) = p(pos);
        end
    end
end

% ---------- F. VNF 去重：按每个目的路径向源对齐 + 保序 ----------
for vnf_idx = 1:vnf_num
    cand = unique(vnfNodeFixed(:, vnf_idx));

    for di = 1:dest_num
        p = paths{di};

        % 最早深度约束（保序）
        if vnf_idx == 1
            minDepth = depth(src) + 1;
        else
            minDepth = depth(vnfNodeFixed(di, vnf_idx-1));
        end

        feasible = cand(ismember(cand, p) & depth(cand) >= minDepth);

        % ---- 修正点：feasible 可能为空，原代码会报错 ----
        if isempty(feasible)
            % 兜底：在自己的路径 p 上找第一个满足深度约束的节点
            idx = find(depth(p) + 0 >= minDepth, 1, 'first');  % +0 避免某些类型问题
            if isempty(idx)
                vnfNodeFixed(di, vnf_idx) = p(end);
            else
                vnfNodeFixed(di, vnf_idx) = p(idx);
            end
        else
            [~, pos] = min(depth(feasible));
            vnfNodeFixed(di, vnf_idx) = feasible(pos);
        end
    end
end

% ---------- 输出：树链路集合 ----------
placeLinks = G.Edges.eid(:).';

end % ====== FixMulticastTree ======



% ========================================================================
% ================= 子函数：在有向图里找一条环上的 eid 集合 ================
% ========================================================================
function cycEids = findOneCycleEids(G)
N = numnodes(G);
E = numedges(G);

endNodes = G.Edges.EndNodes;
eids     = G.Edges.eid;

adj  = cell(N,1);
adjE = cell(N,1);
for i = 1:E
    a = endNodes(i,1);
    b = endNodes(i,2);
    adj{a}(end+1)  = b;
    adjE{a}(end+1) = eids(i);
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
            v = adj{u}(kk);
            eid = adjE{u}(kk);

            if ~visited(v)
                parentN(v) = u;
                parentE(v) = eid;
                [found, cyc] = dfs(v);
                if found
                    onstack(u) = false;
                    return;
                end
            elseif onstack(v)
                % 回边 u->v，回溯构造环上的 eid
                cyc = eid;
                x = u;
                while x ~= v
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


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\0.公共优化组件\generateDeployPlan.m

```matlab
%[text] # generateDeployPlan
%[text] **为合法的多播树生成部署顺序**
function deployPlan = generateDeployPlan(sortedRequests, FixedPlan, links)
% generateDeployPlan（纯部署方案版：不生成时间t）
%
% 输入：
%   sortedRequests : 排序后的请求集合（1×N结构体）
%   treePlan       : Step4 输出（每个请求：placeLinks + vnfNode）
%   links          : 物理链路结构体（links(e).source / links(e).dest）
%   nodes          : 这里不使用（保留是为了不改你外部调用）
%
% 输出 deployPlan 结构（不含t）：
% deployPlan(req_idx).id
% deployPlan(req_idx).treeproject(dest_idx).dest_id
% deployPlan(req_idx).treeproject(dest_idx).vnf_project(v).vnfid
% deployPlan(req_idx).treeproject(dest_idx).vnf_project(v).placeVnfLinks
% deployPlan(req_idx).treeproject(dest_idx).vnf_project(v).placeVnfNode
% deployPlan(req_idx).treeproject(dest_idx).final_links  % 最后一个VNF到dest的链路（若VNF在dest则为空）

req_num = numel(FixedPlan);

deployPlan = repmat(struct('req_id', 0, 'treeproject', []), req_num, 1);

for req_idx = 1:req_num
    req = sortedRequests(req_idx);

    % 先设置req_id，即使后续失败也有记录
    deployPlan(req_idx).req_id = req.id;

    src      = req.source;
    dests    = req.dest(req.dest > 0);
    dest_num = numel(dests);

    vnf_ids  = req.vnf;
    vnf_num  = numel(vnf_ids);

    placeLinks = FixedPlan(req_idx).placeLinks(:).';   % 1×M
    vnfNode   = FixedPlan(req_idx).vnfNode;          % dest_num×vnf_num
    
    % 过滤掉无效的链路ID（0或负数）
    placeLinks = placeLinks(placeLinks > 0);
    
    % 如果没有有效链路，创建空的treeproject并跳过
    if isempty(placeLinks)
        % 创建空的treeproject结构
        treeproject = repmat(struct('dest_id', 0, 'vnf_project', [], 'final_links', []), dest_num, 1);
        for di = 1:dest_num
            treeproject(di).dest_id = dests(di);
            treeproject(di).vnf_project = repmat(struct('vnfid', 0, 'placeVnfLinks', [], 'placeVnfNode', 0), vnf_num, 1);
        end
        deployPlan(req_idx).treeproject = treeproject;
        continue;
    end

    % --- 用 placeLinks 构造这棵树的有向图 ---
    s = arrayfun(@(eid) links(eid).source, placeLinks);
    t = arrayfun(@(eid) links(eid).dest,   placeLinks);

    G = digraph(s, t);
    G.Edges.eid = placeLinks(:);   % 给每条"树边"挂上真实链路ID

    % --- 逐个目的节点生成 vnf_project ---
    treeproject = repmat(struct('dest_id', 0, 'vnf_project', [], 'final_links', []), dest_num, 1);

    for di = 1:dest_num
        dest_id = dests(di);
        treeproject(di).dest_id = dest_id;

        % 初始化空的vnf_project
        vnf_project = repmat(struct( ...
            'vnfid', 0, ...
            'placeVnfLinks', [], ...
            'placeVnfNode', 0 ...
        ), vnf_num, 1);

        % 目的节点在树上的路径（节点序列 + 边索引序列）
        try
            [nodePath, ~, edgeIdx] = shortestpath(G, src, dest_id);
        catch
            % 找不到路径，使用空的vnf_project
            treeproject(di).vnf_project = vnf_project;
            continue;
        end
        
        % 检查路径是否有效
        if isempty(nodePath) || isempty(edgeIdx)
            treeproject(di).vnf_project = vnf_project;
            continue;
        end
        
        linkPath = G.Edges.eid(edgeIdx).';  % 与 nodePath 对齐：linkPath(k)连接 nodePath(k)->nodePath(k+1)

        % 该 dest 的 VNF 放置节点序列
        vNodes = vnfNode(di, :);

        % startPos：当前段起点在 nodePath 的位置（第1段从 src 开始）
        startPos = 1;

        for v = 1:vnf_num
            place_node_id = vNodes(v);
            vnf_project(v).vnfid = vnf_ids(v);
            vnf_project(v).placeVnfNode = place_node_id;
            
            % 检查place_node_id是否有效
            if place_node_id <= 0
                vnf_project(v).placeVnfLinks = [];
                continue;
            end

            % 在 nodePath 上找到 place_node_id 的位置（保证顺序：从 startPos 往后找）
            endPosRel = find(nodePath(startPos:end) == place_node_id, 1);
            
            if isempty(endPosRel)
                % 找不到节点，可能vnfNode与placeLinks不匹配
                vnf_project(v).placeVnfLinks = [];
                continue;
            end
            
            endPos = endPosRel + startPos - 1;

            % 该 VNF 对应的链路段：nodePath(startPos) -> nodePath(endPos)
            if endPos > startPos && endPos-1 <= numel(linkPath)
                place_link_ids = linkPath(startPos : endPos-1);
            else
                place_link_ids = [];   % 同节点部署，无需走链路（保留空即可）
            end

            vnf_project(v).placeVnfLinks = place_link_ids;

            % 下一段从当前 VNF 节点继续
            startPos = endPos;
        end

        treeproject(di).vnf_project = vnf_project;

        % --- 计算最后一跳：从最后一个 VNF 节点到 dest 的链路 ---
        last_vnf_node = vNodes(vnf_num);
        if last_vnf_node == dest_id || last_vnf_node <= 0
            % 最后一个 VNF 就在 dest 上，或无效，无需额外链路
            treeproject(di).final_links = [];
        else
            % 需要从最后一个 VNF 节点走到 dest
            % startPos 已经指向最后一个 VNF 在 nodePath 中的位置
            % dest_id 在 nodePath 的最后一个位置
            destPos = numel(nodePath);
            if destPos > startPos && destPos-1 <= numel(linkPath)
                treeproject(di).final_links = linkPath(startPos : destPos-1);
            else
                treeproject(di).final_links = [];
            end
        end
    end

    deployPlan(req_idx).treeproject = treeproject;
end
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\0.公共优化组件\initNecessaryStructure.m

```matlab
%[text] # 初始化部署阶段必要的数据结构
function [fail_log, consume, nodes,plan] = initNecessaryStructure(sortedRequests, nodes)
%INITNECESSARYSTRUCTURE  初始化部署阶段必要的数据结构（含节点FIFO工作状态表）
%   nodes(n).work_status.req_id   : T×1，0=空闲，非0=忙（忙时存该任务的 req_id）
%   nodes(n).work_status.dest_id  : T×1，忙时存 dest_id
%   nodes(n).work_status.vnf_id   : T×1，忙时存 vnf_id
%   nodes(n).work_status.vnf_idx  : T×1，忙时存 vnf_idx（便于调试）
%   nodes(n).work_status.dest_idx : T×1，忙时存 dest_idx（便于调试）
%
% 同时维护：
%   nodes(n).free_flag : 标量，指向"当前时间轴上最早空闲的时间片索引"
%                       （实现上等价于 find(req_id==0,1,'first')）
% -------------------------------------------------------------------------
%
% 输入：
%   sortedRequests : 排序后的请求数组（struct array）
%   nodes          : 节点数组（struct array），至少需要 nodes(n).cpu 是 T×1
%
% 输出：
%   fail_log, consume, nodes : 初始化后的结构体
%

    requestNum = max([sortedRequests.id]);  % consume 按真实 req_id 索引

    % ---------------- fail_log：空结构体 ----------------
    % 说明：add_fail_row() 会往里面追加记录，这里只需要保证字段存在即可。
    fail_log = struct( ...
        'req_id',        {}, ...
        'dest_idx',      {}, ...
        'dest_id',       {}, ...
        'vnf_idx',       {}, ...
        'place_node_id', {}, ...
        'failed_link',   {}, ...
        'lack_bw',       {}, ...
        'lack_cpu',      {}, ...
        'lack_mem',      {}, ...
        'unschedulable', {}, ...
        'time_out',      {}  ...
    );

    % ---------------- consume：按 req_id 索引的消耗统计 ----------------
    % 主结构字段：accepted, cpu_consume, memory_consume, bandwidth_consume, delay_consume, e2eConsume
    % e2eConsume 是按 dest_id 索引的结构体数组，用于记录每个目的节点分支的详细消耗
    
    % 为每个请求预分配 e2eConsume
    e2eConsumeEmpty = struct( ...
        'dest_id',           [], ...
        'vnf_project',       [], ...   % 与 sortedPlan 的 vnfNode 对应
        'cpu_consume',       0, ...
        'memory_consume',    0, ...
        'bandwidth_consume', 0, ...
        'delay_consume',     0, ...
        'vnfconsume',        [] ...    % 结构体数组，记录每个 VNF 的详细消耗
    );
    
    consume = struct( ...
        'req_id',            num2cell(1:requestNum), ...          % 请求ID（方便索引和查询）
        'accepted',          num2cell(zeros(1,requestNum)), ...  % 1=接收,0=拒绝
        'cpu_consume',       num2cell(zeros(1,requestNum)), ...
        'memory_consume',    num2cell(zeros(1,requestNum)), ...
        'bandwidth_consume', num2cell(zeros(1,requestNum)), ...
        'delay_consume',     num2cell(zeros(1,requestNum)), ...
        'e2eConsume',        repmat({e2eConsumeEmpty}, 1, requestNum) ...  % 每个请求一个结构体数组
    );

    % ---------------- 节点 FIFO：work_status 初始化 ----------------
    T = size(nodes(1).cpu, 1);  % 通常为1500

    for n = 1:numel(nodes)
        nodes(n).work_status = struct();
        nodes(n).work_status.req_id   = zeros(T, 1);
        nodes(n).work_status.dest_id  = zeros(T, 1);
        nodes(n).work_status.vnf_id   = zeros(T, 1);
        nodes(n).work_status.vnf_idx  = zeros(T, 1);
        nodes(n).work_status.dest_idx = zeros(T, 1);

        % free_flag 指向"最早空闲时间片"
        nodes(n).free_flag = 1;
    end

    % ---------------- plan 初始化 ----------------
    % 初始化为一个 0x0 的结构体数组，但预先定义好字段名。
    % 这样在后续代码中可以直接使用 plan(end+1) = newPlan 而不会报字段不匹配错误。
    plan = struct( ...
        'req_id',    {}, ...
        'placeLinks', {}, ...
        'vnfNode',    {}  ...
    );




end






%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\0.公共优化组件\plotTree.m

```matlab
%[text] # 绘制示意多播树
function fullFilePath = plotTree(sortedPlan, req_id, links,reqs, saveDir)
% plotTree(deployPlan, req_id, links)
% 只使用固定字段名：
%   deployPlan(i).req.id / .source / .dest
%   deployPlan(i).treeproject(tp).vnf_project(vp).vnfid
%   deployPlan(i).treeproject(tp).vnf_project(vp).placeVnfLinks
%   deployPlan(i).treeproject(tp).vnf_project(vp).placeVnfNode
%
% 输出：
%   fullFilePath: 保存的 svg 完整路径

    % ===================== 1) 定位对应请求条目 =====================
    req_idx = find([sortedPlan.req_id] == req_id, 1);
    req = reqs(req_idx);

    % ===================== 2) 汇总整棵树的链路 treelink + VNF标注信息 =====================
    TP = sortedPlan(req_idx).treeproject;

    treelink = [];              % 整棵树使用到的链路ID集合
    vnfNodeList = [];           % 记录每个 VNF 部署节点
    vnfIdList   = [];           % 记录对应 VNF ID（与 vnfNodeList 一一对应）

    for tp = 1:numel(TP)
        V = TP(tp).vnf_project;
        for vp = 1:numel(V)
            % 合并链路
            if ~isempty(V(vp).placeVnfLinks)
                treelink = [treelink, V(vp).placeVnfLinks(:)']; %#ok<AGROW>
            end

            % 收集VNF部署节点与VNF类型
            if ~isempty(V(vp).placeVnfNode)
                vnfNodeList(end+1) = V(vp).placeVnfNode; %#ok<AGROW>
                vnfIdList(end+1)   = V(vp).vnfid;        %#ok<AGROW>
            end
        end
        
        % 【关键修复】合并 final_links（从最后一个VNF到目的节点的链路）
        if isfield(TP(tp), 'final_links') && ~isempty(TP(tp).final_links)
            treelink = [treelink, TP(tp).final_links(:)']; %#ok<AGROW>
        end
    end

    treelink = unique(treelink(treelink > 0));
    if isempty(treelink)
        error('req_id=%d 的 treelink 为空（placeVnfLinks 全空/全0），无法绘图。', req_idx);
    end

    % ===================== 3) 构图：从链路ID得到 s,t =====================
    s = arrayfun(@(id) links(id).source, treelink);
    t = arrayfun(@(id) links(id).dest,   treelink);

    % 图包含所有潜在节点：边端点 + source + dest + VNF节点
    all_nodes = [s(:); t(:); req.source; req.dest(req.dest > 0)'; vnfNodeList(:)];
    max_id = max(all_nodes);

    G = digraph(s, t, [], max_id);

    % 关键：Name=原始ID字符串，避免 rmnode 后索引错位
    G.Nodes.Name = string(1:numnodes(G))';

    % 存边ID用于显示标签
    G.Edges.ID = treelink(:);

    % 删除孤立节点（不在树上的节点）
    deg0 = (indegree(G) + outdegree(G) == 0);
    if any(deg0)
        G = rmnode(G, find(deg0));
    end

    % ===================== 4) 绘图 =====================
    f = figure('Color', 'w', ...
        'Name', ['Request ', num2str(req.id), ' Multicast Tree'], ...
        'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.7]);

    p = plot(G, 'Layout', 'layered', ...
        'NodeColor', [0.6 0.6 0.6], 'MarkerSize', 6, ...
        'LineWidth', 1.2, 'ArrowSize', 10);

    % 显示链路ID作为边标签
    p.EdgeLabel = string(G.Edges.ID);

    % ===================== 5) 高亮 Source =====================
    srcNode = req.source;
    srcIdx = findnode(G, string(srcNode));
    if srcIdx > 0
        highlight(p, srcIdx, 'NodeColor', 'r', 'MarkerSize', 10, 'Marker', 's');
        text(p.XData(srcIdx), p.YData(srcIdx)+0.15, 'Source', ...
            'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end

    % ===================== 6) 高亮 Destinations =====================
    destNodes = req.dest(req.dest > 0);
    for i = 1:numel(destNodes)
        dNode = destNodes(i);
        dIdx = findnode(G, string(dNode));
        if dIdx > 0
            highlight(p, dIdx, 'NodeColor', 'r', 'MarkerSize', 10, 'Marker', 'p');
            text(p.XData(dIdx), p.YData(dIdx)-0.15, ['D', num2str(i)], ...
                'Color', 'r', 'FontSize', 8, 'HorizontalAlignment', 'center');
        end
    end

    % ===================== 7) 标注 VNF：按节点聚合 vnfid =====================
    % 把 "同一节点上的多个 vnfid" 聚合成一个标签
    uniqueVnfNodes = unique(vnfNodeList(vnfNodeList > 0));

    for ii = 1:numel(uniqueVnfNodes)
        node_id = uniqueVnfNodes(ii);
        nodeIdx = findnode(G, string(node_id));
        if nodeIdx == 0, continue; end

        % 该节点部署的VNF类型集合
        deployed_vnf_types = unique(vnfIdList(vnfNodeList == node_id));
        if isempty(deployed_vnf_types), continue; end

        vnf_str = sprintf('%d,', deployed_vnf_types);
        label_text = ['\color{blue}VNF: ', vnf_str(1:end-1)];

        text(p.XData(nodeIdx), p.YData(nodeIdx)+0.2, label_text, ...
            'FontWeight', 'bold', 'FontSize', 9, 'HorizontalAlignment', 'center');

        % 让VNF节点更醒目一点（你也可以再加 NodeColor，但我按你原风格只放大）
        highlight(p, nodeIdx, 'MarkerSize', 8);
    end

    title(['Multicast Service Function Chain Tree (Req ID: ', num2str(req.id), ')']);
    axis off;

    % ===================== 8) 保存 SVG =====================
    % 构造完整的文件路径（将 req_id 转为字符串并加上后缀）
    if ~exist(saveDir, 'dir'), mkdir(saveDir); end
    fileName = sprintf('MulticastTree_Req_%d.svg', req.id);
    fullFilePath = fullfile(saveDir, fileName);

    try
        exportgraphics(f, fullFilePath, 'ContentType', 'vector'); % 推荐：矢量
    catch
        saveas(f, fullFilePath); % 兼容老版本MATLAB
    end

    fprintf('多播树示意图已保存至: %s\n', fullFilePath);
end



%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\1.最短路优先算法\generateDeployPlanWithoutTree.m

```matlab
%[text] # generateDeployPlanWithoutTree
%[text] 直接根据 plan 生成部署方案（跳过 treePlan），用于对比
function deployPlan = generateDeployPlanWithoutTree(sortedRequests, plan, links)
% generateDeployPlan_Direct：直接根据 plan 生成部署方案（跳过 treePlan）
%
% 输入：
%   sortedRequests : 排序后的请求集合
%   plan           : Step3 输出的 plan 结构体（含 placeLinks, vnfNode）
%   links          : 物理链路结构体
%
% 输出：
%   deployPlan     : 分段部署指令，与原版输出格式完全一致

    req_num = numel(plan);
    
    % 初始化输出结构
    deployPlan = repmat(struct('req_id', 0, 'treeproject', []), req_num, 1);

    for req_idx = 1:req_num
        req = sortedRequests(req_idx);
        
        % 基础信息
        src      = req.source;
        dests    = req.dest(req.dest > 0);
        dest_num = numel(dests);
        
        vnf_ids  = req.vnf;
        vnf_num  = numel(vnf_ids);
        
        % 从 plan 中提取当前请求的放置信息
        % 注意：Step3 的 plan 中，placeLinks 是 dest_num × max_hops 的矩阵
        currentPlanLinks = plan(req_idx).placeLinks; 
        currentPlanVnf   = plan(req_idx).vnfNode;
        
        % --- 逐个目的节点生成 vnf_project ---
        treeproject = repmat(struct('dest_id', 0, 'vnf_project', [], 'final_links', []), dest_num, 1);

        for di = 1:dest_num
            dest_id = dests(di);
            treeproject(di).dest_id = dest_id;

            % 1. 获取该目的节点的完整链路序列 (Link Path)
            % 过滤掉填充的 0
            rawLinks = currentPlanLinks(di, :);
            linkPath = rawLinks(rawLinks > 0); 
            
            % 2. 根据链路序列推导节点序列 (Node Path) [关键步骤]
            % 因为 plan 里的 linkPath 是有序的，我们可以顺藤摸瓜
            if isempty(linkPath)
                % 特殊情况：源即目的
                nodePath = src;
            else
                nodePath = zeros(1, length(linkPath) + 1);
                nodePath(1) = src;
                currNode = src;
                for k = 1:length(linkPath)
                    eid = linkPath(k);
                    % 判断链路方向：找到与 currNode 相连的另一端
                    if links(eid).source == currNode
                        nextNode = links(eid).dest;
                    elseif links(eid).dest == currNode
                        nextNode = links(eid).source; % 双向链路容错
                    else
                        error('链路不连续：Link %d 不连接 Node %d', eid, currNode);
                    end
                    nodePath(k+1) = nextNode;
                    currNode = nextNode;
                end
            end

            % 3. 获取该 dest 的 VNF 放置节点
            vNodes = currentPlanVnf(di, :);

            % 4. 初始化 VNF 项目结构
            vnf_project = repmat(struct( ...
                'vnfid', 0, ...
                'placeVnfLinks', [], ...
                'placeVnfNode', 0 ...
            ), vnf_num, 1);

            % 5. 路径切分逻辑 (与原版保持一致)
            startPos = 1; % 当前段起点在 nodePath 的位置

            for v = 1:vnf_num
                place_node_id = vNodes(v);
                
                % 在 nodePath 上找到 place_node_id 的位置
                % find(..., 1) 找第一个匹配项，确保按顺序推进
                relPos = find(nodePath(startPos:end) == place_node_id, 1);
                
                if isempty(relPos)
                    % 容错：如果 VNF 节点不在路径上（理论上 Step3 保证了在路径上）
                    warning('Req %d Dest %d: VNF节点 %d 不在路径上', req.id, dest_id, place_node_id);
                    endPos = startPos;
                else
                    endPos = relPos + startPos - 1;
                end

                % 截取对应的链路段
                if endPos > startPos
                    % 节点索引 i 到 i+1 对应的链路索引是 i
                    place_link_ids = linkPath(startPos : endPos-1);
                else
                    place_link_ids = []; 
                end

                vnf_project(v).vnfid         = vnf_ids(v);
                vnf_project(v).placeVnfLinks = place_link_ids;
                vnf_project(v).placeVnfNode  = place_node_id;

                % 更新起点
                startPos = endPos;
            end

            treeproject(di).vnf_project = vnf_project;

            % --- 计算最后一跳：从最后一个 VNF 节点到 dest 的链路 ---
            last_vnf_node = vNodes(vnf_num);
            if last_vnf_node == dest_id
                % 最后一个 VNF 就在 dest 上，无需额外链路
                treeproject(di).final_links = [];
            else
                % 需要从最后一个 VNF 节点走到 dest
                % startPos 已经指向最后一个 VNF 在 nodePath 中的位置
                % dest_id 在 nodePath 的最后一个位置
                destPos = numel(nodePath);
                if destPos > startPos && ~isempty(linkPath)
                    treeproject(di).final_links = linkPath(startPos : destPos-1);
                else
                    treeproject(di).final_links = [];
                end
            end
        end

        deployPlan(req_idx).req_id = req.id;
        deployPlan(req_idx).treeproject = treeproject;
    end
end

%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\1.最短路优先算法\noFixPlan.m

```matlab
%[text] # noFixPlan
%[text] 不做任何处理，直接返回原计划，用于对比
function FixedPlan = noFixPlan(reqs, plan, links) 
% NoFixPlan: 不做任何处理，直接返回原计划
FixedPlan = plan;
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\1.最短路优先算法\shortestPathFirstWithLoadBalancing.m

```matlab
%[text] # shortestPathFirstWithLoadBalancing
%[text] 最短路优先+负载均衡的多播SFC部署方案生成
%[text] 
%[text] ## 输入参数说明
%[text] - requests: 请求集合
%[text] - KPathsNew: cell数组格式的K条最短路，KPathsNew{src,d}为K×1 struct数组
%[text] - links: 链路结构体
%[text] - nodes: 节点结构体
%[text] - plan: 初始化的部署方案
%[text] - deployMethodCfg: 部署方法配置（此算法未使用，保持接口一致性）

function plan = shortestPathFirstWithLoadBalancing(requests, KPathsNew, links, nodes, plan, deployMethodCfg)
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
        
        % 取第一条最短路（最优路径）
        firstRoute = routes(1);
    
        % 最短路跳数（可用放置节点数）
        hops = firstRoute.pathshops;
        
        if hops <= 0
            warning('请求%d: 源%d到目的%d的路径跳数为0', req.id, src, d);
            continue;
        end
        
        % 获取链路序列（KPathsNew格式已去0）
        linkIds = firstRoute.link_ids;
        
        % 记录 src->dest 的链路序列
        actualHops = numel(linkIds);
        newPlan.placeLinks(di, 1:actualHops) = linkIds;
    
        % 获取节点序列（KPathsNew格式已去0）
        pathNodes = firstRoute.paths;
    
        % VNF 放置：沿途节点按序；节点不够则尽量向前均匀放置（前序节点）
        for v = 1:vnf_num
            idx = ceil(v * hops / vnf_num);          % idx ∈ [1, hops]
            pos = 1 + idx;                  % 映射到 pathNodes 的位置（跳过src）
            if pos <= numel(pathNodes)
            newPlan.vnfNode(di, v) = pathNodes(pos);
            else
                % 如果位置超出，使用最后一个节点
                newPlan.vnfNode(di, v) = pathNodes(end);
            end
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


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\2.节点资源贪心\nodeFirst.m

```matlab
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

```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\ResourceAndDelayAware.m

```matlab
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

```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\ResourceAndDelayAwareOnline.m

```matlab
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
% 1. 为每个目的节点选择前candLinkNum条最短路
% 2. 对每条路径，使用rdaLinkAndNodeChoice计算最佳VNF放置
% 3. 返回所有有效的候选方案

    candPlans = [];
    src = req.source;
    dests = req.dest(req.dest > 0);
    
    % 为每个目的节点收集候选路径方案
    destPathPlans = cell(destNum, 1);
    
    for dest_idx = 1:destNum
        d = dests(dest_idx);
        Pathinfo = KPathsNew{src, d};
        
        if isempty(Pathinfo)
            % 没有可用路径，使用空方案
            destPathPlans{dest_idx} = [];
            continue;
        end
        
        % 【改进】先用 calcPathScore 对所有路径进行预评估，选取得分最高的K条
        % 而不是简单地选取前K条最短路
        pathScoreStruct = calcPathScore(Pathinfo, linkFreq, links, req, 1, deployMethodCfg);
        
        % calcPathScore 返回的结果已按 totalScore 降序排列
        % 选取前candLinkNum条得分最高的路径
        numPaths = min(candLinkNum, numel(pathScoreStruct));
        pathPlans = repmat(struct('pathLinks', [], 'vnfNodes', [], 'pathScore', 0), numPaths, 1);
        
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
            
            % 计算该路径的VNF放置（使用calcNodeScore进行评分）
            vnfNodes = computeVnfPlacement(route, nodes, links, req, nodeFreq, linkFreq, ...
                                          dest_idx, destNum, vnfNum, candNodeNum, deployMethodCfg);
            
            pathPlans(pathIdx).pathLinks = pathLinks(:).';
            pathPlans(pathIdx).vnfNodes = vnfNodes;
            
            % 【复用】直接使用 calcPathScore 已计算的得分
            pathPlans(pathIdx).pathScore = pathScoreStruct(pathIdx).totalScore;
        end
        
        destPathPlans{dest_idx} = pathPlans;
    end
    
    % 组合各目的节点的方案生成完整的多播方案
    % 简化策略：每个目的节点取最佳路径，形成一个完整方案
    % 更复杂的策略可以枚举组合，但会导致方案数爆炸
    
    % 策略1：每个目的节点使用各自的最佳路径（形成candLinkNum个方案）
    for candIdx = 1:candLinkNum
        newPlan = struct( ...
            'req_id',       req.id, ...
            'placeLinks',   zeros(destNum, linkNum), ...
            'vnfNode',      zeros(destNum, vnfNum), ...
            'totalScore',   0, ...      % 【新增】记录已计算的总得分
            'destScores',   zeros(destNum, 1) ... % 【新增】各目的节点得分
        );
        
        validPlan = true;
        totalScoreSum = 0;
        
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
                newPlan.destScores(dest_idx) = -inf;  % fallback方案得分最低
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
                
                % 【记录已计算的得分】
                newPlan.destScores(dest_idx) = pathPlan.pathScore;
                totalScoreSum = totalScoreSum + pathPlan.pathScore;
            end
        end
        
        % 【汇总总得分】
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

```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\1.找所有候选路径\calcPathScore.m

```matlab
%[text] # calcPathScore
%[text] 计算链路综合评价
%[text] =归一化共享度评分+归一化拥塞评分+归一化时延评分
function pathScoreStruct = calcPathScore(Pathinfo, linkFreq, links, req, t0, deployMethodCfg)

   
    shareWeight = deployMethodCfg.shareWeight;
    congWeight = deployMethodCfg.congWeight;
    delayWeight = deployMethodCfg.delayWeight;

    linkFreq = linkFreq(:);
    K = length(Pathinfo);

    % 结果结构体：先存 raw 指标，再存 norm 指标与总分
    pathScoreStruct = repmat(struct( ...
        'k', [], 'hops', [], ...
        'shareScore', [], 'congScore', [], 'delayScore', [], ...
        'shareNorm', [], 'congNorm', [], 'delayNorm', [], ...
        'totalScore', []), K, 1);

    for k = 1:K
        hops = Pathinfo(k).pathshops;

        pathScoreStruct(k).k    = k;
        pathScoreStruct(k).hops = hops;

        % 无效路径
        if hops <= 0
            pathScoreStruct(k).shareScore = -inf;
            pathScoreStruct(k).congScore  = inf;
            pathScoreStruct(k).delayScore = inf;
            continue;
        end

        lk = Pathinfo(k).link_ids;
        lk = lk(lk > 0);

        if isempty(lk)
            pathScoreStruct(k).shareScore = -inf;
            pathScoreStruct(k).congScore  = inf;
            pathScoreStruct(k).delayScore = inf;
            continue;
        end

        % ---------- 1) raw 共享潜力：越大越好 ----------
        shareScore = mean(linkFreq(lk));

        % ---------- 2) raw 拥堵：越小越好 ----------
        t = t0;
        congSum = 0;

        for ei = 1:numel(lk)
            e = lk(ei);

            usedFlag = links(e).request(t, req.id);
            bw_t = links(e).bandwidth(t);

            if bw_t <= 0
                cong = inf;
            elseif usedFlag == 1
                cong = 0;
            else
                cong = req.bandwidth / bw_t;
            end

            congSum = congSum + cong;

            dly_t = links(e).delay(t);
            t = t + dly_t;
        end

        congScore = congSum / hops;

        % ---------- 3) raw 时延满足：越小越好 ----------
        % 时延得分:6指的是3个vnf按照基础时延进行部署的时间
        delayScore = (t + 6) / req.max_delay;

        pathScoreStruct(k).shareScore = shareScore;
        pathScoreStruct(k).congScore  = congScore;
        pathScoreStruct(k).delayScore = delayScore;
    end

    % ==================== 同集合 min-max 归一化 ====================
    shareVec = [pathScoreStruct.shareScore].';
    congVec  = [pathScoreStruct.congScore].';
    delayVec = [pathScoreStruct.delayScore].';

    % 有效掩码（只对有限值做归一化）
    validShare = isfinite(shareVec);
    validCong  = isfinite(congVec);
    validDelay = isfinite(delayVec);

    shareNorm = nan(K,1);
    congNorm  = nan(K,1);
    delayNorm = nan(K,1);

    shareNorm(validShare) = minmax01(shareVec(validShare));
    congNorm(validCong)   = minmax01(congVec(validCong));
    delayNorm(validDelay) = minmax01(delayVec(validDelay));

    % 写回结构体 + 计算总分
    for k = 1:K
        pathScoreStruct(k).shareNorm = shareNorm(k);
        pathScoreStruct(k).congNorm  = congNorm(k);
        pathScoreStruct(k).delayNorm = delayNorm(k);

        % share：越大越好（直接加）
        % cong/delay：越小越好（用 1 - norm 变成"越大越好"的形式）
        if isfinite(shareNorm(k)) && isfinite(congNorm(k)) && isfinite(delayNorm(k))
            pathScoreStruct(k).totalScore = ...
                shareWeight * shareNorm(k) + ...
                congWeight  * (1 - congNorm(k)) + ...
                delayWeight     * (1 - delayNorm(k));
        else
            pathScoreStruct(k).totalScore = -inf;
        end
    end

    % ==================== 排序：totalScore 降序；并列 hops 升序 ====================
    totalScores = [pathScoreStruct.totalScore].';
    hopsVec     = [pathScoreStruct.hops].';
    [~, order]  = sortrows([-totalScores, hopsVec], [1 2]);
    pathScoreStruct = pathScoreStruct(order);

end

%[text] 
%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\1.找所有候选路径\calcSharePotental.m

```matlab
%[text] # calcSharePotental
%[text] 对单个多播请求，统计 source -\> 每个 dest 的 K 条最短路中
%[text] 各个节点、各条链路在所有路径中的出现频率。
function [nodeFreq, linkFreq] = calcSharePotental(reqs, KPathsNew, links, nodes)
% calcSharePotental (for Scheme A: KPathsNew is a cell)
% 对单个多播请求，统计 source -> 每个 dest 的 K 条最短路中
% 各个节点、各条链路在所有路径中的出现频率。
%
% 输入：
%   reqs      : 一个多播请求结构体（包含 source, dest）
%   KPathsNew : cell 数组，KPathsNew{src,d} 为 K×1 struct数组（每个元素一条最短路）
%              每条最短路结构体字段：
%                - paths     : 节点序列（已去0）
%                - pathshops : 跳数 hops
%                - link_ids  : 链路序列（已去0）
%   links     : 物理链路结构体数组，含字段 id
%   nodes     : 物理节点结构体数组，含字段 id
%
% 输出：
%   nodeFreq(i) : 节点 i 在所有 considered 路径中出现次数
%   linkFreq(e) : 链路 id = e 在所有 considered 路径中出现次数

    % 源节点、目的节点集合
    src   = reqs.source;
    dests = reqs.dest(:).';   % 转成行向量，方便遍历

    % 最大 id，用于初始化频率向量长度
    max_link_id = max([links.id]);
    max_node_id = max([nodes.id]);

    nodeFreq = zeros(max_node_id, 1);
    linkFreq = zeros(max_link_id, 1);

    % 遍历每个目的节点
    for d = dests
        if d <= 0
            continue; % 过滤掉填充的0目的节点
        end

        % 取出 src->d 的 K 条最短路（K×1 struct数组）
        routes = KPathsNew{src, d};

        if isempty(routes)
            continue;
        end

        % 遍历每条最短路
        for k = 1:numel(routes)
            hops = routes(k).pathshops;
            if hops <= 0
                continue;
            end

            % ---------- 节点出现频率 ----------
            % routes(k).paths 已经是去0后的节点序列
            path_nodes = routes(k).paths;
            if ~isempty(path_nodes)
                nodeFreq(path_nodes) = nodeFreq(path_nodes) + 1;
            end

            % ---------- 链路出现频率 ----------
            % routes(k).link_ids 已经是去0后的链路序列
            path_links = routes(k).link_ids;
            if ~isempty(path_links)
                linkFreq(path_links) = linkFreq(path_links) + 1;
            end
        end
    end
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\1.找所有候选路径\minmax01.m

```matlab
% ---------- 辅助函数：min-max 归一化到 [0,1] ----------
function y = minmax01(x)
    xmin = min(x);
    xmax = max(x);
    if abs(xmax - xmin) < 1e-12
        y = ones(size(x));   % 全部相同就都设为1（或0都行）
    else
        y = (x - xmin) ./ (xmax - xmin);
    end
end
```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\2.找所有候选节点\calcNodeScore.m

```matlab
%[text] # calcNodeScore
%[text] 计算候选路径上各节点的综合评价得分
%[text] 
%[text] ## 算法思路
%[text] 对于给定的候选路径，评估路径上所有候选节点（除源节点外）部署当前VNF的综合得分。
%[text] 
%[text] ## 评价指标
%[text] 1. cpu_consume: 归一化CPU消耗率（越小越好）- 若VNF可共享则为0
%[text] 2. memory_consume: 归一化内存消耗率（越小越好）- 若VNF可共享则为0
%[text] 3. bandwidth_consume: 到达该节点的链路带宽消耗（越小越好）- 若链路已共享则为0
%[text] 4. delay_consume: 到达该节点的时延（越小越好）
%[text] 5. share_score: 共享潜力得分（越大越好），表示未来被其他目的节点共享的可能性
%[text] 6. queue_score: 排队等待成本（越小越好）- 真实反映节点排队压力
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
    
    % 排队成本权重（如果配置中有则使用，否则默认为2.0）
    if isfield(deployMethodCfg, 'queueWeight')
        queueWeight = deployMethodCfg.queueWeight;
    else
        queueWeight = 1.0;  % 默认权重较高，体现排队压力
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
        'delayScore',     [], ...      % 时延指标（越小越好）
        'shareScore',     [], ...      % 共享潜力（越大越好）
        'queueScore',     [], ...      % 排队等待成本（越小越好）
        ... % 排队详情
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
        'queueNorm',      [], ...
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
    shareDecayWeight = max(1 - (destIdx - 1) / max(destNum, 1), 0.1);
    
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
            cpu_avail = node.cpu(currentTime);
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
            mem_avail = node.mem(currentTime);
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
            t_safe = min(max(arriveTime, 1), size(node.delay, 1));
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
        nodeScoreStruct(i).delayScore = totalDelay / max(req.max_delay, 1);
        
        % ========== 5. 排队成本评分（越小越好） ==========
        % 排队成本直接反映节点的拥挤程度
        % waitTime越大，说明该节点越繁忙，应该避免
        nodeScoreStruct(i).queueScore = waitTime;
        
        % ========== 6. 共享潜力评分（越大越好） ==========
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
        nodeScoreStruct(i).shareScore = (nodeShare + linkShare) * shareDecayWeight;
    end
    
    % ==================== 归一化处理 ====================
    % 提取各指标向量
    cpuVec = [nodeScoreStruct.cpuScore].';
    memVec = [nodeScoreStruct.memScore].';
    bwVec = [nodeScoreStruct.bwScore].';
    delayVec = [nodeScoreStruct.delayScore].';
    shareVec = [nodeScoreStruct.shareScore].';
    queueVec = [nodeScoreStruct.queueScore].';
    
    % 有效性掩码
    validCpu = isfinite(cpuVec);
    validMem = isfinite(memVec);
    validBw = isfinite(bwVec);
    validDelay = isfinite(delayVec);
    validShare = isfinite(shareVec);
    validQueue = isfinite(queueVec);
    
    % 归一化
    cpuNorm = nan(numCandNodes, 1);
    memNorm = nan(numCandNodes, 1);
    bwNorm = nan(numCandNodes, 1);
    delayNorm = nan(numCandNodes, 1);
    shareNorm = nan(numCandNodes, 1);
    queueNorm = nan(numCandNodes, 1);
    
    cpuNorm(validCpu) = minmax01(cpuVec(validCpu));
    memNorm(validMem) = minmax01(memVec(validMem));
    bwNorm(validBw) = minmax01(bwVec(validBw));
    delayNorm(validDelay) = minmax01(delayVec(validDelay));
    shareNorm(validShare) = minmax01(shareVec(validShare));
    queueNorm(validQueue) = minmax01(queueVec(validQueue));
    
    % 写回结构体并计算总分
    for i = 1:numCandNodes
        nodeScoreStruct(i).cpuNorm = cpuNorm(i);
        nodeScoreStruct(i).memNorm = memNorm(i);
        nodeScoreStruct(i).bwNorm = bwNorm(i);
        nodeScoreStruct(i).delayNorm = delayNorm(i);
        nodeScoreStruct(i).shareNorm = shareNorm(i);
        nodeScoreStruct(i).queueNorm = queueNorm(i);
        
        if nodeScoreStruct(i).isValid && ...
           isfinite(cpuNorm(i)) && isfinite(memNorm(i)) && ...
           isfinite(bwNorm(i)) && isfinite(delayNorm(i)) && ...
           isfinite(shareNorm(i)) && isfinite(queueNorm(i))
            
            % 综合评分公式：
            % - 资源消耗（越小越好）：使用 (1 - norm) 转换为"越大越好"
            % - 时延（越小越好）：使用 (1 - norm) 转换为"越大越好"
            % - 排队成本（越小越好）：使用 (1 - norm) 转换为"越大越好"
            % - 共享潜力（越大越好）：直接使用 norm
            %
            % 【关键改进】排队成本权重较高，促使VNF分散部署
            nodeScoreStruct(i).totalScore = ...
                congWeight * (1 - cpuNorm(i)) + ...
                congWeight * (1 - memNorm(i)) + ...
                congWeight * (1 - bwNorm(i)) + ...
                delayWeight * (1 - delayNorm(i)) + ...
                queueWeight * (1 - queueNorm(i)) + ...  % 排队成本越低越好
                shareWeight * shareNorm(i);
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

```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\3.计算多播部署方案的综合评价\planEvaluate.m

```matlab
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

```

---

## b.常用函数\3.部署方案生成\9.资源与时延感知算法\5.源到单个目的节点函数\rdaLinkAndNodeChoice.m

```matlab
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

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\add_fail_row.m

```matlab
%[text] # add\_fail\_row
%[text] 记录不可部署的vnf信息
function fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, ...
                                 failed_node, failed_link, ...
                                 lack_cpu, lack_mem, lack_bw, timeout, unsched)

    n = numel(fail_log) + 1;

    fail_log(n).req_id         = req.id;
    fail_log(n).dest_idx       = dest_idx;
    fail_log(n).vnf_idx        = vnf_idx;
    fail_log(n).place_node_id    = failed_node;
    fail_log(n).failed_link    = failed_link;

    fail_log(n).lack_cpu       = double(lack_cpu);
    fail_log(n).lack_mem       = double(lack_mem);
    fail_log(n).lack_bw = double(lack_bw);
    fail_log(n).time_out      = double(timeout);
    fail_log(n).unschedulable  = double(unsched);
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\deploy_requests.m

```matlab
%[text] # deploy\_requests
%[text] 部署多播请求集，记录资源消耗和服务拒绝原因
%[text] 快速测试
% req_idx = 1;%1
% dest_idx = 1;%27
% vnf_idx = 1;%4
%[text] 
function [nodes, links, requests, consume, fail_log] = deploy_requests( ...
    nodes, links, requests, sortedPlan, consume, fail_log)

%DEPLOY_REQUESTS_TRANSACTIONAL  步骤6：逐请求部署（带事务回滚）
%
% 【功能】
%   对 deployPlan 中的每个请求（req_idx）做完整的多播分支部署：
%     - 对每个 dest 分支，从 t_now=1 开始依次部署 vnf1..vnfK
%     - 每次部署一个 VNF 调用：deploy_vnf(...)
%
%   若该请求任一分支任一 VNF 部署失败：
%     - 回滚 nodes / links / consume(req_id)
%     - consume(req_id).accepted = 0
%     - fail_log 只保留该请求的"第一个失败点"记录
%
%   若全部成功：
%     - consume(req_id).accepted = 1
%
% 【输入】
%   nodes, links      : 当前网络状态（会被更新）
%   requests          : 请求数组
%   deployPlan        : 每个 req_idx 的部署方案（treeproject / vnf_project）
%   consume, fail_log : 统计结构
%
% 【输出】
%   nodes, links, requests, consume, fail_log : 更新后的系统状态与统计
%
% 【注意】
%   1) 本函数假设 deployPlan 与 requests 的顺序/长度一致：
%        deployPlan(i) 对应 requests(i)
%   2) 本函数只负责"请求级事务控制"，具体链路/节点逻辑在 deploy_vnf 内部完成。
%

    for req_idx = 1:numel(sortedPlan)

        % 当前请求（req_idx 是 requests 的索引）
        req    = requests(req_idx);
        req_id = req.id;

        % ===================== 事务快照（用于回滚） =====================
        nodes0   = nodes;
        links0   = links;
        consume0 = consume(req_id);
        failLen0 = numel(fail_log);

        request_failed = false;

        % 有效目的节点列表（去掉 0）
        dests    = req.dest(req.dest > 0);
        dest_num = numel(dests);
        vnf_num  = numel(req.vnf);

        % 记录每个分支的结束时间（用于计算端到端时延）
        branch_end_time = zeros(dest_num, 1);

        % 初始化本请求的 e2eConsume 数组（按目的节点索引）
        e2eConsume_arr = repmat(struct( ...
            'dest_id',           0, ...
            'vnf_project',       [], ...
            'cpu_consume',       0, ...
            'memory_consume',    0, ...
            'bandwidth_consume', 0, ...
            'delay_consume',     0, ...
            'vnfconsume',        [] ...
        ), dest_num, 1);

        % ===================== 遍历每个多播分支 =====================
        for dest_idx = 1:dest_num

            % 每个分支从 t=1 开始（上一跳/上一VNF离开时间）
            t_now = 1;
            
            % 初始化本分支的目的节点信息
            e2eConsume_arr(dest_idx).dest_id = dests(dest_idx);
            e2eConsume_arr(dest_idx).vnf_project = sortedPlan(req_idx).treeproject(dest_idx).vnf_project;
            
            % 初始化本分支的 vnfconsume 数组
            vnfconsume_arr = [];

            % ========== 顺序部署 vnf1..vnfK（不做EDF，只做FIFO排队） ==========
            for vnf_idx = 1:vnf_num

                item = sortedPlan(req_idx).treeproject(dest_idx).vnf_project(vnf_idx);

                [nodes, links, requests, fail_log, success, consume, leaveNodeTime, vnf_consume] = ...
                    deploy_vnf(nodes, links, requests, ...
                               req_idx, dest_idx, vnf_idx, ...
                               item.placeVnfNode, item.placeVnfLinks, t_now, ...
                               fail_log, consume);

                if success == 0
                    request_failed = true;
                    break;  % break vnf loop
                end
                
                % 记录本次VNF部署的消耗
                if isempty(vnfconsume_arr)
                    vnfconsume_arr = vnf_consume;
                else
                    vnfconsume_arr(end+1) = vnf_consume;
                end
                
                % 累加到本分支的消耗
                e2eConsume_arr(dest_idx).cpu_consume = e2eConsume_arr(dest_idx).cpu_consume + vnf_consume.cpu_consume;
                e2eConsume_arr(dest_idx).memory_consume = e2eConsume_arr(dest_idx).memory_consume + vnf_consume.memory_consume;
                e2eConsume_arr(dest_idx).bandwidth_consume = e2eConsume_arr(dest_idx).bandwidth_consume + vnf_consume.bandwidth_consume;
                e2eConsume_arr(dest_idx).delay_consume = e2eConsume_arr(dest_idx).delay_consume + vnf_consume.delay_consume;

                % 下一段VNF的起始时间 = 本段离开时间（含排队等待）
                t_now = leaveNodeTime;
            end
            
            % 记录本分支的 vnfconsume 数组
            if ~request_failed
                e2eConsume_arr(dest_idx).vnfconsume = vnfconsume_arr;
            end

            % ========== 最后一跳：从最后一个 VNF 节点到 dest ==========
            % 如果最后一个 VNF 不在 dest 上，需要执行最后一段链路传输
            if ~request_failed && isfield(sortedPlan(req_idx).treeproject(dest_idx), 'final_links')
                final_links = sortedPlan(req_idx).treeproject(dest_idx).final_links;
                if ~isempty(final_links)
                    % 检查链路共享标志
                    usedFlag = zeros(numel(final_links), 1);
                    for k = 1:numel(final_links)
                        e = final_links(k);
                        usedFlag(k) = links(e).request(t_now, req_id);
                    end

                    % 执行链路资源检查与更新
                    [links, lack_bw, time_out, arriveDestTime, consume, failed_link, final_link_consume] = ...
                        linkResourceCheckAndUpdate(links, final_links, req_id, req, t_now, req.bandwidth, usedFlag, consume);

                    if lack_bw
                        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_num+1, 0, failed_link, 0,0,1,0,0);
                        request_failed = true;
                    elseif time_out
                        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_num+1, 0, failed_link, 0,0,0,1,0);
                        request_failed = true;
                    else
                        t_now = arriveDestTime;
                        % 累加最后一跳的带宽和时延消耗到本分支
                        e2eConsume_arr(dest_idx).bandwidth_consume = e2eConsume_arr(dest_idx).bandwidth_consume + final_link_consume.bandwidth_consume;
                        e2eConsume_arr(dest_idx).delay_consume = e2eConsume_arr(dest_idx).delay_consume + final_link_consume.delay_consume;
                    end
                end
            end

            % 记录该分支的结束时间（到达 dest 的时间）
            if ~request_failed
                branch_end_time(dest_idx) = t_now;
            end

            if request_failed
                break;  % break dest loop
            end
        end

        % ===================== 成功/失败收尾 =====================
        if request_failed
            % 回滚：当作这个请求从没发生
            nodes = nodes0;
            links = links0;

            consume(req_id) = consume0;
            consume(req_id).accepted = 0;

            % fail_log：只保留"第一个失败点"
            if numel(fail_log) > failLen0 + 1
                fail_log = fail_log(1:failLen0+1);
            end

        else
            consume(req_id).accepted = 1;
            % 记录分支结束时间和端到端时延到 requests 结构体
            requests(req_idx).branch_end_time = branch_end_time;
            requests(req_idx).e2e_delay = max(branch_end_time) - 1;  % 减1是因为从t=1开始
            
            % 记录详细的 e2eConsume 到 consume 结构
            consume(req_id).e2eConsume = e2eConsume_arr;
        end
    end
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\deploy_vnf.m

```matlab
function [nodes, links, requests, fail_log, success, consume, leaveNodeTime, vnf_consume] = deploy_vnf( ...
    nodes, links, requests, ...
    req_idx, dest_idx, vnf_idx, ...
    place_node_id, place_link_ids, t, ...
    fail_log, consume)
%DEPLOY_VNF  在时间片 t 为多播请求的一个分支部署一个VNF（含节点内FIFO排队）
%
% 该函数对应《实验构思251226版.md》中"步骤6：部署"。
% 你原来的 deploy_vnf 做了两件事：
%   (1) 链路：带宽共享 + 资源检查 + 更新（linkResourceCheckAndUpdate）
%   (2) 节点：VNF共享 + 资源检查 + 更新（nodeResourceCheckAndUpdate）
%
% 本次重构不改变总体流程，只把"节点侧"替换为：
%   - 带资源预留的 FIFO 排队模型
%   - 处理时延采用方案A：在 arriveNodeTime 时刻决定，并在排队期间保持不变
%
% 输入：
%   nodes, links, requests : 当前系统状态（会被原地更新）
%   dest_idx, vnf_idx     : 第几个目的节点、第几个VNF
%   place_node_id         : 本VNF部署的节点
%   place_link_ids        : 到达该节点所经过的链路列表
%   t                     : 分支当前时间（上一跳/上一VNF的离开时间）
%   fail_log, consume     : 统计结构
%
% 输出：
%   success      : 1=成功，0=失败
%   leaveNodeTime: 该 VNF 在节点处理完（含排队等待）的离开时间
%   vnf_consume  : 本次VNF部署的具体消耗（结构体），字段包括：
%                  vnfid, placeVnfLinks, placeVnfNode, cpu_consume,
%                  memory_consume, bandwidth_consume, delay_consume

    % 默认失败
    success = 0;
    leaveNodeTime = t;
    
    % 初始化本次VNF部署的消耗结构
    vnf_consume = struct( ...
        'vnfid',             0, ...
        'placeVnfLinks',     [], ...
        'placeVnfNode',      0, ...
        'cpu_consume',       0, ...
        'memory_consume',    0, ...
        'bandwidth_consume', 0, ...
        'delay_consume',     0 ...
    );

    % ---------- 请求与资源需求 ----------
    req      = requests(req_idx);
    req_id   = req.id;            % 真实请求ID（用于 consume、共享标记）
    vnf_id   = req.vnf(vnf_idx);
    bw_need  = req.bandwidth;
    cpu_need = req.cpu;
    mem_need = req.memory;
    
    % 记录VNF基本信息
    vnf_consume.vnfid = vnf_id;
    vnf_consume.placeVnfLinks = place_link_ids;
    vnf_consume.placeVnfNode = place_node_id;

    % ==============================================================
    % 1) 链路阶段：带宽共享 + 链路资源检查与更新
    % ==============================================================
    usedFlag = zeros(numel(place_link_ids), 1);
    for k = 1:numel(place_link_ids)
        e = place_link_ids(k);
        usedFlag(k) = links(e).request(t, req_id);  % 用 req_id 做共享维度
    end

    [links, lack_bw, time_out, arriveNodeTime, consume, failed_link, link_consume] = ...
        linkResourceCheckAndUpdate(links, place_link_ids, req_id, req, t, bw_need, usedFlag, consume);

    if lack_bw
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, 0, failed_link, 0,0,1,0,0);
        return;
    end
    if time_out
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, 0, failed_link, 0,0,0,1,0);
        return;
    end

    % ==============================================================
    % 2) 节点阶段：VNF共享优先 + FIFO排队 + 资源预留
    % ==============================================================
    [nodes, lack_cpu, lack_mem, time_out, leaveNodeTime, consume, node_consume] = ...
        nodeResourceCheckAndUpdate(nodes, place_node_id, ...
                                   req, req_id, dest_idx, vnf_idx, vnf_id, ...
                                   arriveNodeTime, cpu_need, mem_need, consume);

    if lack_cpu
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, place_node_id, 0, 1,0,0,0,0);
        return;
    end
    if lack_mem
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, place_node_id, 0, 0,1,0,0,0);
        return;
    end
    if time_out
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, place_node_id, 0, 0,0,0,1,0);
        return;
    end

    % ==============================================================
    % 3) 成功：整合本次VNF部署的消耗信息
    % ==============================================================
    vnf_consume.cpu_consume = node_consume.cpu_consume;
    vnf_consume.memory_consume = node_consume.memory_consume;
    vnf_consume.bandwidth_consume = link_consume.bandwidth_consume;
    vnf_consume.delay_consume = link_consume.delay_consume + node_consume.delay_consume;
    
    success = 1;
end

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\linkResourceCheckAndUpdate.m

```matlab
%[text] # linkResourceCheckAndUpdate
%[text] 在进行资源检查时，要求按时间逐个链路检查资源是否符合要求：
%[text] 情景：在1时刻，为请求1的第2个目的节点（16-6）放置vnf8， 节点16-6的最短路是16-13-8-7-4-6 ，测试将其放在8号节点上，经过的链路编号\[48,36\]，假设48号链路在t时刻时延为links(48).delay(t)；
%[text] 链路检查示例：
%[text] 检查1~（1+links(48).delay(1)）时间片内，links(48).bandwith(t)是否均大于bw\_need 检查\[1+links(48).delay(1))\]~\[1+links(48).delay(1)+links(36).delay(1+links(48).delay(1))\]时间片内，links(36).bandwith(t)是否均大于bw\_need 
function [links, lack_bw, time_out, arriveNodeTime, consume, failed_link, link_consume] = ...
    linkResourceCheckAndUpdate(links, place_link_ids, req_id, req, t, bw_need, usedFlag, consume)
% linkResourceCheckAndUpdate
% 按"时间片+链路时延"逐条检查带宽，并根据共享/不共享更新链路带宽。
% 输入：
%   links：链路结构体数组，含字段 bandwidth(Tx1)，delay(Tx1)
%   place_link_ids：本次经过的链路编号向量，如[48 36]
%   t:起始时间片
%   bw_need:该请求在此路径上的带宽需求
%   usedFlag：共享标志
%           可以是标量：0=本请求在这些链路上还没占带宽；1=已经占过（完全共享）
%           -也可以是与 place_link_ids 同尺寸的向量，对每条链路单独指定
%
% 输出：
% links资源更新后的链路结构体数组
% lack_bw是否存在带宽不足
% time_out是否时间超出仿真范围
% arriveNodeTime ：通过所有链路后，到达目标节点的时间片

    lack_bw        = false;
    time_out       = false;
    arriveNodeTime = t;
    failed_link    = 0;
    
    % 初始化当次链路消耗结构（记录本次VNF部署的链路资源消耗）
    link_consume = struct( ...
        'bandwidth_consume', 0, ...   % 本次链路带宽消耗（共享时为0）
        'delay_consume',     0 ...    % 本次链路时延消耗
    );

    if isempty(place_link_ids)
        return;
    end

    % 假设所有链路的时间片长度一致，最大时间片取第一个链路的长度(1500)
    T_link = size(links(1).bandwidth, 1);
    t_curr = t;

    
    for idx = 1:numel(place_link_ids)
        e = place_link_ids(idx);
        share_this_link = usedFlag(idx);

        % 若超过仿真总时长，把 t_curr 截断
        if t_curr > T_link
            time_out    = true;
            failed_link = e;
            arriveNodeTime = T_link;
            return;
        end

        delay_e = links(e).delay(t_curr);
        t_end   = t_curr + delay_e;

        % 若超过仿真总时长，把 t_end 截断
        if t_end > T_link
            time_out    = true;
            failed_link = e;
            arriveNodeTime = T_link;
            return;
        end

        % % 若超过请求最大时延，拒绝该请求
        if t_end > req.max_delay
            time_out    = true;
            failed_link = e;
            arriveNodeTime = T_link;
            return;
        end

        if ~share_this_link
            % 带宽资源约束检查：从 t_curr 到 T_link
            for tau = t_curr:T_link
                if links(e).bandwidth(tau) < bw_need
                    lack_bw     = true;
                    failed_link = e;
                    arriveNodeTime = t_end;
                    return;
                end
            end
            % 更新资源消耗（总消耗 + 本次消耗）
            consume(req_id).bandwidth_consume = consume(req_id).bandwidth_consume + bw_need;
            link_consume.bandwidth_consume = link_consume.bandwidth_consume + bw_need;
            
            % 更新链路资源与链路时延
            for tau = t_curr:T_link
                links(e).bandwidth(tau) = links(e).bandwidth(tau) - bw_need;
                links(e).request(tau, req_id) = 1;

                % 动态时延：带宽越紧张，时延越大
                cap = links(e).bandwidth_cap;
                free = links(e).bandwidth(tau);
                free_rate = max(free/cap, 0.001);
                links(e).delay(tau) = round(links(e).base_delay / free_rate);
            end
        end
        % 无论是否共享，都要累加本次链路的时延消耗
        % （共享链路也会有传输时延）

        % 如果该链路已经是共享链路，无需检查资源约束，更新消耗和时延
        t_curr = t_end;
    end
    % 所有链路都检查完，当前时间就是到达节点时间
    arriveNodeTime = t_curr;
    
    % 计算本次链路时延消耗
    link_delay = arriveNodeTime - t;
    consume(req_id).delay_consume = consume(req_id).delay_consume + link_delay;
    link_consume.delay_consume = link_delay;
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\1.节点资源排队及其辅助函数\check_node_reservation.m

```matlab
%[text] # check\_node\_reservation
%[text] 检查从 arriveTime 到 T\_node 的 cpu/mem 是否够用
function [lack_cpu, lack_mem] = check_node_reservation(node, arriveTime, cpu_need, mem_need)
%CHECK_NODE_RESERVATION  检查从 arriveTime 到 T_node 的 cpu/mem 是否够用
%
% 资源预留语义（与你原代码一致）：
%   一旦接收/部署，资源在后续整个窗口都被占用，不会释放。

    lack_cpu = false;
    lack_mem = false;

    T_node = size(node.cpu, 1);
    for tau = arriveTime:T_node
        if node.cpu(tau) < cpu_need
            lack_cpu = true;
            return;
        end
        if node.mem(tau) < mem_need
            lack_mem = true;
            return;
        end
    end
end

%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\1.节点资源排队及其辅助函数\fifo_find_start_time.m

```matlab
%[text] # fifo\_find\_start\_time
function [startTime, waitTime, ok] = fifo_find_start_time(node, arriveTime, proc_duration)
%FIFO_FIND_START_TIME  FIFO/FCFS：为任务寻找一个"真实可用"的开始时间
%
% 【MOD-3】你指出的关键问题是正确的：
%   仅用 start=max(arrive, free_flag) 不能保证后续 proc_duration 个时间片都空闲，
%   也不能利用时间轴上的空闲间隙。
%
% 因此这里改为：
%   - 从 arriveTime 开始往后扫，寻找最早的连续空闲窗口（长度=proc_duration）
%   - 空闲判定基于 work_status.req_id == 0
%
% 这是一种"first-fit on timeline"的实现。
%
% 输出：
%   startTime : 找到的实际开始时间
%   waitTime  : startTime - arriveTime
%   ok        : 是否找到（找不到说明超出仿真时域）

    T = numel(node.work_status.req_id);

    % 处理时长为0：等价于无需占用处理窗口（start=arrive）
    if proc_duration == 0
        startTime = arriveTime;
        waitTime  = 0;
        ok = true;
        return;
    end

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

%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\1.节点资源排队及其辅助函数\find_shared_ready_time.m

```matlab
%[text] # find\_shared\_ready\_time
%[text] 查找"共享实例"在该节点的 ready 时间
function ready_time = find_shared_ready_time(node, req_id, vnf_id)
%FIND_SHARED_READY_TIME  查找"共享实例"在该节点的 ready 时间
%
% 【MOD-2】共享语义：如果该节点上已经出现过 (req_id, vnf_id) 的任务，
%       则认为该VNF实例存在/正在部署，ready 时间取最早完成时刻 min(t_end)。
%
% 返回：
%   ready_time = []  表示不可共享
%   ready_time = k   表示该实例从时间 k 起 ready（到达早于k则需要等待）

    ready_time = [];

    if isempty(node.tasks)
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

```

---

## b.常用函数\5.sfc映射\1.按序部署方式\1.节点资源排队及其辅助函数\nodeResourceCheckAndUpdate.m

```matlab
function [nodes, lack_cpu, lack_mem, time_out, leaveNodeTime, consume, node_consume] = ...
    nodeResourceCheckAndUpdate(nodes, place_node_id, ...
                               req, req_id, dest_idx, vnf_idx, vnf_id, ...
                               arriveNodeTime, cpu_need, mem_need, consume)
%NODERESOURCECHECKANDUPDATE  节点侧：VNF共享 + FIFO排队 + 资源预留 + 动态时延（方案A）
%
% 本函数是"步骤6：部署"里节点侧的核心更新逻辑。
% 节点一次只能处理一个任务（单机），并在节点内部按 FIFO 规则排队。
% 处理时延（proc_duration）在"到达时刻 arriveNodeTime"就确定，
%          排队只会增加等待时间，不会改变本次任务的处理时长。
% leaveNodeTime 的定义：
%   leaveNodeTime = actual_start_time + proc_duration
% 其中：
%   actual_start_time >= arriveNodeTime（如果节点忙，就需要等待）
% --------------------------------------------------------------------------
% VNF共享时：不消耗新资源，但必须等待"共享实例部署完成(ready)"才能继续。
%         - ready_time 从 nodes(place_node_id).tasks 中找到同 req_id + vnf_id 的最早 t_end。
%         - leaveNodeTime = max(arriveNodeTime, ready_time)
%         - 并且：新部署时 nodes.vnf 的"可共享标记"从 leaveNodeTime 开始写入（而不是 arriveNodeTime）
%           这样语义更一致：实例部署完成后才可共享。
%
% FIFO 的 actual_start_time 不能简单用 max(arrive, free_flag)：
%         需要确保 [start, start+proc_duration) 这段时间窗口确实空闲。
%         若不空闲，则向后寻找"最早的、长度足够的空闲时间段"（first-fit）。
% --------------------------------------------------------------------------
%
% 输入/输出含义与原函数保持一致：
%   lack_cpu/lack_mem/time_out 只要有一个为 true，则视为该节点部署失败（由上层回滚）
%

    lack_cpu = false;
    lack_mem = false;
    time_out = false;
    leaveNodeTime = arriveNodeTime;
    
    % 初始化当次节点消耗结构（记录本次VNF部署的节点资源消耗）
    node_consume = struct( ...
        'cpu_consume',    0, ...   % 本次节点CPU消耗（共享时为0）
        'memory_consume', 0, ...   % 本次节点内存消耗（共享时为0）
        'delay_consume',  0 ...    % 本次节点时延消耗（包括排队+处理）
    );

    node = nodes(place_node_id);
    T_node = size(node.cpu, 1);  % 仿真最大时间片（通常1500）

    % ---------------- 0) 到达越界：直接TIMEOUT ----------------
    if arriveNodeTime > T_node
        time_out = true;
        leaveNodeTime = T_node;
        return;
    end

    % ======================================================================
    % 1) VNF共享检查（最高优先级）
    % ======================================================================
    % 若当前节点有可共享的vnf，等到共享实例成功被处理即可前往下一节点。
    % ready 的判定：在该节点 tasks 中找到 (req_id, vnf_id) 对应的最早 t_end。
    ready_time = find_shared_ready_time(node, req_id, vnf_id);

    if ~isempty(ready_time)
        % 共享：不扣新资源、不占用处理窗口；但必须等到实例 ready
        leaveNodeTime = max(arriveNodeTime, ready_time);

        % TIMEOUT 判断
        if leaveNodeTime > T_node || leaveNodeTime > req.vnf_deadline(dest_idx, vnf_idx)
            time_out = true;
            return;
        end

        % 把"等待共享实例ready"的时间计入时延消耗（等待=leave-arrive，因为处理时长=0）
        node_delay = leaveNodeTime - arriveNodeTime;
        consume(req_id).delay_consume = consume(req_id).delay_consume + node_delay;
        
        % 共享情况下：CPU/内存消耗为0，只记录时延
        node_consume.cpu_consume = 0;
        node_consume.memory_consume = 0;
        node_consume.delay_consume = node_delay;

        return;
    end

    % ======================================================================
    % 2) 计算处理时长（方案A：到达即确定）
    % ======================================================================
    proc_duration = node.delay(arriveNodeTime);

    % ======================================================================
    % 3) FIFO排队：找到一个真实可用的处理窗口 [start, start+proc_duration)
    % ======================================================================
    [actual_start_time, wait_duration, ok] = fifo_find_start_time(node, arriveNodeTime, proc_duration);

    if ~ok
        % 找不到长度足够的空闲窗口，等价于"离开时间会超出仿真区间"
        time_out = true;
        leaveNodeTime = T_node;
        return;
    end

    leaveNodeTime = actual_start_time + proc_duration;

    % ======================================================================
    % 4) 超时判定（deadline + 仿真时域）
    % ======================================================================
    if leaveNodeTime > T_node
        time_out = true;
        leaveNodeTime = T_node;
        return;
    end
    if leaveNodeTime > req.vnf_deadline(dest_idx, vnf_idx)
        time_out = true;
        return;
    end

    % ======================================================================
    % 5) 资源检查（资源预留：arriveNodeTime ~ T_node）
    % ======================================================================
    % 注意：这是你原框架的"资源预留"语义：
    %   一旦该 VNF 在该节点接入成功，从 arriveNodeTime 起到仿真结束都占用CPU/MEM（不释放）。
    [lack_cpu, lack_mem] = check_node_reservation(node, arriveNodeTime, cpu_need, mem_need);
    if lack_cpu || lack_mem
        return;
    end

    % ======================================================================
    % 6) 提交资源扣减 + 动态时延更新
    % ======================================================================
    [nodes, consume] = commit_node_reservation(nodes, place_node_id, arriveNodeTime, cpu_need, mem_need, consume, req_id);

    % 把本次任务的"排队+处理"计入时延消耗
    node_delay = leaveNodeTime - arriveNodeTime;
    consume(req_id).delay_consume = consume(req_id).delay_consume + node_delay;
    
    % 记录本次VNF部署的节点消耗
    node_consume.cpu_consume = cpu_need;
    node_consume.memory_consume = mem_need;
    node_consume.delay_consume = node_delay;

    % ======================================================================
    % 7) 写入"可共享VNF"标记（从 ready 时刻开始）
    % ======================================================================
    % 【MOD-2】原先是从 arriveNodeTime 开始标记，这会导致"实例还没部署完就被共享"的矛盾。
    % 这里改为从 leaveNodeTime 开始标记，表示：部署完成后才可共享。
    nodes = mark_vnf_shareable(nodes, place_node_id, leaveNodeTime, req_id, vnf_id);

    % ======================================================================
    % 8) 维护 FIFO 工作状态表（work_status）与 free_flag
    % ======================================================================
    % 【MOD-1】work_status 改为结构体列向量，忙区间用半开区间 [start, leave)
    nodes = mark_work_status(nodes, place_node_id, actual_start_time, leaveNodeTime, ...
                             req_id, req.dest(dest_idx), dest_idx, vnf_idx, vnf_id);

    % 【MOD-3】free_flag 表示"当前时间轴上最早空闲的时间片索引"
    ff = find(nodes(place_node_id).work_status.req_id == 0, 1, 'first');
    if isempty(ff)
        ff = T_node + 1;  % 全忙：指向仿真结束之后
    end
    nodes(place_node_id).free_flag = ff;

    % ======================================================================
    % 9) 记录任务 tasks（用于后续统计/调度）
    % ======================================================================
    nodes = append_task(nodes, place_node_id, req, dest_idx, vnf_idx, vnf_id, actual_start_time, leaveNodeTime);
end




function [nodes, consume] = commit_node_reservation(nodes, node_id, arriveTime, cpu_need, mem_need, consume, req_id)
%COMMIT_NODE_RESERVATION  扣除 arriveTime:T_node 的资源，并更新 nodes.delay(t)

    T_node = size(nodes(node_id).cpu, 1);

    % consume：资源消耗只加一次（与你原版本一致）
    consume(req_id).cpu_consume    = consume(req_id).cpu_consume + cpu_need;
    consume(req_id).memory_consume = consume(req_id).memory_consume + mem_need;

    for tau = arriveTime:T_node
        nodes(node_id).cpu(tau) = nodes(node_id).cpu(tau) - cpu_need;
        nodes(node_id).mem(tau) = nodes(node_id).mem(tau) - mem_need;

        % 动态节点时延：CPU越紧张，处理越慢（沿用你原有形式）
        cap = nodes(node_id).cpu_cap;
        free = nodes(node_id).cpu(tau);
        free_rate = max(free / cap, 0.001);
        nodes(node_id).delay(tau) = round(nodes(node_id).base_delay / free_rate);
    end
end

function nodes = mark_vnf_shareable(nodes, node_id, readyTime, req_id, vnf_id)
%MARK_VNF_SHAREABLE  将该VNF实例标记为"从 readyTime 起可共享"
%
% nodes(node_id).vnf : T×requestNum×slot
% 这里沿用"slot"存放多个vnf实例id的做法：
%   - 若已存在同 vnf_id 的 slot，则复用该 slot
%   - 否则找第一个 0 slot 写入

    T_node = size(nodes(node_id).vnf, 1);

    if readyTime > T_node
        return;
    end

    vnf_row = squeeze(nodes(node_id).vnf(readyTime, req_id, :)).';
    slot = find(vnf_row == vnf_id, 1);
    if isempty(slot)
        slot = find(vnf_row == 0, 1);
    end
    if isempty(slot)
        % 若 slot 都满了，按你原逻辑其实应视为不可部署；
        % 但这里保持简单：直接占用第1个slot覆盖（你也可改为失败）
        slot = 1;
    end

    nodes(node_id).vnf(readyTime:T_node, req_id, slot) = vnf_id;
end

function nodes = mark_work_status(nodes, node_id, startTime, leaveTime, req_id, dest_id, dest_idx, vnf_idx, vnf_id)
%MARK_WORK_STATUS  在 work_status[startTime, leaveTime) 标记"正在处理"的任务
%
% 【MOD-1】使用直观结构体列向量：
%   work_status.req_id(t) = req_id
%   work_status.dest_id(t)= dest_id
%   work_status.vnf_id(t) = vnf_id
%   work_status.vnf_idx(t)= vnf_idx
%   work_status.dest_idx(t)=dest_idx
%
% 忙碌区间使用半开区间 [start, leave)：
%   - 任务处理用时 proc_duration
%   - leave = start + proc_duration
%   - 下一任务允许从 leave 开始

    if leaveTime <= startTime
        return;
    end

    t1 = startTime;
    t2 = leaveTime - 1;

    nodes(node_id).work_status.req_id(t1:t2)   = req_id;
    nodes(node_id).work_status.dest_id(t1:t2)  = dest_id;
    nodes(node_id).work_status.vnf_id(t1:t2)   = vnf_id;
    nodes(node_id).work_status.vnf_idx(t1:t2)  = vnf_idx;
    nodes(node_id).work_status.dest_idx(t1:t2) = dest_idx;
end

function nodes = append_task(nodes, node_id, req, dest_idx, vnf_idx, vnf_id, t_start, t_end)
%APPEND_TASK  追加一条任务记录到 nodes(node_id).tasks（struct数组）
%
% tasks 字段示例：
%   req_id, dest_idx, dest_id, vnf_idx, vnf_id, t_start, t_end

    dest_id = req.dest(dest_idx);

    newTask = struct( ...
        'req_id',   req.id, ...
        'dest_idx', dest_idx, ...
        'dest_id',  dest_id, ...
        'vnf_idx',  vnf_idx, ...
        'vnf_id',   vnf_id, ...
        't_start',  t_start, ...
        't_end',    t_end ...
    );

    if isempty(nodes(node_id).tasks)
        nodes(node_id).tasks = newTask;
    else
        nodes(node_id).tasks(end+1) = newTask;
    end
end


%[appendix]{"version":"1.0"}
%---

```

---

## b.常用函数\6.结果绘制\runThesisResultPlots.m

```matlab
function allMetrics = runThesisResultPlots(methods, outDir, cfg)
%RUNTHESISRESULTPLOTS  一键生成论文需要的结果图（多方法对比）
%
% 输入：
%   methods : struct 数组，每个元素至少包含：
%             .name, .nodes, .links, .requests, .consume, .fail_log
%             （可通过 loadMethodResultsFromPaths() 快速构造）
%   outDir  : 输出目录（会自动创建）
%   cfg     : getPlotCfg() 返回的配置（可省略）
%
% 输出：
%   allMetrics : 汇总结构（同时也会另存为 allMetrics.mat）
%
% 你将得到多张 svg 图：
%   1) Fig_AcceptanceRate.svg
%   2) Fig_AvgE2EDelay_vs_Success.svg
%   3) Fig_AvgSlackRatio_vs_Success.svg  (或 SlackAbs)
%   4) Fig_AvgCPUConsume_vs_Success.svg
%   5) Fig_AvgMemoryConsume_vs_Success.svg
%   6) Fig_AvgBandwidthConsume_vs_Success.svg
%   7) Fig_VNFSharingGainRatio_vs_Success.svg
%   8) Fig_CumulativeResourceConsume.svg  (累计资源消耗，含CPU/内存/带宽)
%   9) Fig_FailureBreakdownDistribution.svg
%  10) Fig_GanttChart_{MethodName}.svg  (每个方法一张)
%
% Excel 数据导出：
%   - Data_CumulativeResourceConsume.xlsx (累计资源消耗明细)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    if nargin < 2 || isempty(outDir)
        outDir = fullfile(pwd, 'thesis_plots_output');
    end
    ensure_dir(outDir);

    allMetrics = struct();

    % ---------- QoS ----------
    allMetrics.acceptanceRate = plot_acceptance_rate_curve(methods, outDir, cfg);
    allMetrics.avgE2EDelay    = plot_avg_e2e_delay_vs_success(methods, outDir, cfg);
    allMetrics.avgSlack       = plot_avg_slack_vs_success(methods, outDir, cfg);

    % ---------- Resource Efficiency ----------
    allMetrics.avgCPU         = plot_avg_cpu_consume_vs_success(methods, outDir, cfg);
    allMetrics.avgMemory      = plot_avg_memory_consume_vs_success(methods, outDir, cfg);
    allMetrics.avgBandwidth   = plot_avg_bandwidth_consume_vs_success(methods, outDir, cfg);
    allMetrics.vnfShareGain   = plot_vnf_sharing_gain_ratio_vs_success(methods, outDir, cfg);
    allMetrics.cumulativeConsume = plot_cumulative_resource_consume(methods, outDir, cfg);

    % ---------- System Stability ----------
    allMetrics.failureBreakdown = plot_failure_breakdown_distribution(methods, outDir, cfg);

    % ---------- Gantt Charts (每个方法单独绘制) ----------
    allMetrics.ganttCharts = cell(numel(methods), 1);
    for m = 1:numel(methods)
        allMetrics.ganttCharts{m} = plot_gantt_chart(methods(m).nodes, outDir, cfg, methods(m).name);
    end

    % 汇总保存（方便你后续做表格/写论文）
    if cfg.saveMat
        save(fullfile(outDir, 'AllMetrics_Summary.mat'), 'allMetrics', 'cfg');
    end
    
    % ========== 导出Excel数据（便于制图） ==========
    try
        exportMetricsToExcel(allMetrics, methods, outDir);
    catch ME
        warning(ME.identifier, '导出Excel失败: %s', ME.message);
    end
end

```

---

## b.常用函数\6.结果绘制\1.工具函数\ensure_dir.m

```matlab
function ensure_dir(dirPath)
%ENSURE_DIR  若文件夹不存在则创建
    if ~exist(dirPath, 'dir')
        mkdir(dirPath);
    end
end

```

---

## b.常用函数\6.结果绘制\1.工具函数\exportMetricsToExcel.m

```matlab
function exportMetricsToExcel(allMetrics, methods, outDir)
%EXPORTMETRICSTOEXCEL 将所有指标数据导出为Excel文件
%
% 输入：
%   allMetrics : runThesisResultPlots 返回的指标结构
%   methods    : 方法结构数组
%   outDir     : 输出目录
%
% 输出：
%   在 outDir 下生成 AllMetrics_Data.xlsx，包含多个Sheet
%   每个Sheet包含完整的曲线数据，便于论文制图

    xlsxPath = fullfile(outDir, 'AllMetrics_Data.xlsx');
    
    % 删除已有文件
    if isfile(xlsxPath)
        delete(xlsxPath);
    end
    
    methodNames = {methods.name}.';
    M = numel(methods);
    
    fprintf('正在导出指标数据到Excel...\n');
    
    %% ========== 1. 接受率变化曲线 ==========
    if isfield(allMetrics, 'acceptanceRate') && ~isempty(allMetrics.acceptanceRate)
        metric = allMetrics.acceptanceRate;
        
        % 找到最长的序列长度
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x));
        end
        
        % 创建数据矩阵（x轴 + 各方法的接受率）
        data = NaN(maxLen, M*2 + 1);  % [x, 方法1_累计接受, 方法1_接受率, ...]
        
        % 第一列为请求序号（使用第一个有效方法的x）
        for m = 1:M
            if numel(metric.methods(m).x) == maxLen
                data(:, 1) = metric.methods(m).x(:);
                break;
            end
        end
        if all(isnan(data(:,1)))
            data(:, 1) = (1:maxLen).';
        end
        
        varNames = {'请求序号'};
        for m = 1:M
            len = numel(metric.methods(m).x);
            data(1:len, 2*m) = metric.methods(m).cum_accept(:);
            data(1:len, 2*m+1) = metric.methods(m).acc_rate(:);
            varNames{end+1} = [methodNames{m}, '_累计接受'];
            varNames{end+1} = [methodNames{m}, '_接受率'];
        end
        
        T = array2table(data, 'VariableNames', varNames);
        writetable(T, xlsxPath, 'Sheet', '接受率曲线');
        fprintf('  √ 接受率曲线\n');
    end
    
    %% ========== 2. 平均端到端时延变化曲线 ==========
    if isfield(allMetrics, 'avgE2EDelay') && ~isempty(allMetrics.avgE2EDelay)
        metric = allMetrics.avgE2EDelay;
        
        % 找到最长的序列长度
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).e2e_delay_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_e2e_delay(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次时延'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '端到端时延曲线');
            fprintf('  √ 端到端时延曲线\n');
        end
    end
    
    %% ========== 3. 平均松弛比变化曲线 ==========
    if isfield(allMetrics, 'avgSlack') && ~isempty(allMetrics.avgSlack)
        metric = allMetrics.avgSlack;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).slack_abs_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_slack(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次裕量'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '松弛比曲线');
            fprintf('  √ 松弛比曲线\n');
        end
    end
    
    %% ========== 4. CPU资源消耗变化曲线 ==========
    if isfield(allMetrics, 'avgCPU') && ~isempty(allMetrics.avgCPU)
        metric = allMetrics.avgCPU;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).cpu_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_cpu(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次CPU'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', 'CPU消耗曲线');
            fprintf('  √ CPU消耗曲线\n');
        end
    end
    
    %% ========== 5. 内存资源消耗变化曲线 ==========
    if isfield(allMetrics, 'avgMemory') && ~isempty(allMetrics.avgMemory)
        metric = allMetrics.avgMemory;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).mem_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_mem(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次内存'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '内存消耗曲线');
            fprintf('  √ 内存消耗曲线\n');
        end
    end
    
    %% ========== 6. 带宽资源消耗变化曲线 ==========
    if isfield(allMetrics, 'avgBandwidth') && ~isempty(allMetrics.avgBandwidth)
        metric = allMetrics.avgBandwidth;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).bw_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_bw(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次带宽'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '带宽消耗曲线');
            fprintf('  √ 带宽消耗曲线\n');
        end
    end
    
    %% ========== 7. VNF共享增益变化曲线 ==========
    if isfield(allMetrics, 'vnfShareGain') && ~isempty(allMetrics.vnfShareGain)
        metric = allMetrics.vnfShareGain;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).gain_ratio_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_gain_ratio(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次增益'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', 'VNF共享增益曲线');
            fprintf('  √ VNF共享增益曲线\n');
        end
    end
    
    %% ========== 8. 综合汇总表（最终值） ==========
    varNames = {'方法'};
    tableData = methodNames;
    
    if isfield(allMetrics, 'acceptanceRate')
        finalRates = zeros(M, 1);
        totalAccepted = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.acceptanceRate.methods(m).acc_rate)
                finalRates(m) = allMetrics.acceptanceRate.methods(m).acc_rate(end);
                totalAccepted(m) = allMetrics.acceptanceRate.methods(m).cum_accept(end);
            end
        end
        tableData = [tableData, num2cell(finalRates), num2cell(totalAccepted)];
        varNames = [varNames, {'最终接受率', '接受请求数'}];
    end
    
    if isfield(allMetrics, 'avgE2EDelay')
        avgDelays = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.avgE2EDelay.methods(m).avg_e2e_delay)
                avgDelays(m) = allMetrics.avgE2EDelay.methods(m).avg_e2e_delay(end);
            end
        end
        tableData = [tableData, num2cell(avgDelays)];
        varNames{end+1} = '平均时延';
    end
    
    if isfield(allMetrics, 'avgSlack')
        avgSlacks = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.avgSlack.methods(m).avg_slack)
                avgSlacks(m) = allMetrics.avgSlack.methods(m).avg_slack(end);
            end
        end
        tableData = [tableData, num2cell(avgSlacks)];
        varNames{end+1} = '平均裕量比';
    end
    
    if isfield(allMetrics, 'avgCPU')
        avgCPU = zeros(M, 1);
        avgMem = zeros(M, 1);
        avgBW = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.avgCPU.methods(m).avg_cpu)
                avgCPU(m) = allMetrics.avgCPU.methods(m).avg_cpu(end);
            end
            if ~isempty(allMetrics.avgMemory.methods(m).avg_mem)
                avgMem(m) = allMetrics.avgMemory.methods(m).avg_mem(end);
            end
            if ~isempty(allMetrics.avgBandwidth.methods(m).avg_bw)
                avgBW(m) = allMetrics.avgBandwidth.methods(m).avg_bw(end);
            end
        end
        tableData = [tableData, num2cell(avgCPU), num2cell(avgMem), num2cell(avgBW)];
        varNames = [varNames, {'平均CPU', '平均内存', '平均带宽'}];
    end
    
    if isfield(allMetrics, 'vnfShareGain')
        avgGain = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.vnfShareGain.methods(m).avg_gain_ratio)
                avgGain(m) = allMetrics.vnfShareGain.methods(m).avg_gain_ratio(end);
            end
        end
        tableData = [tableData, num2cell(avgGain)];
        varNames{end+1} = 'VNF共享增益';
    end
    
    if isfield(allMetrics, 'failureBreakdown')
        totalFail = allMetrics.failureBreakdown.totalFail;
        tableData = [tableData, num2cell(totalFail)];
        varNames{end+1} = '失败总数';
    end
    
    T = cell2table(tableData, 'VariableNames', varNames);
    writetable(T, xlsxPath, 'Sheet', '综合汇总');
    fprintf('  √ 综合汇总\n');
    
    fprintf('✓ 所有指标数据已导出到: %s\n', xlsxPath);
end

```

---

## b.常用函数\6.结果绘制\1.工具函数\loadMethodResultsFromPaths.m

```matlab
function methods = loadMethodResultsFromPaths(resultPaths, methodNames, cfg)
%LOADMETHODRESULTSFROMPATHS  从多个 result.mat 路径加载方法结果
%
% 用法示例：
%   paths = { ...
%       'c.输出\\4.资源消耗与失败日志\\...\\SPFresult.mat', ...
%       'c.输出\\4.资源消耗与失败日志\\...\\RDAresult.mat'};
%   names = {'SPF','RDA'};
%   methods = loadMethodResultsFromPaths(paths, names);
%
% 输出 methods(i) 字段：
%   .name(用于图例显示), .raw_name(原始方法名), .nodes, .links, .requests, .consume, .fail_log

    if nargin < 2 || isempty(methodNames)
        methodNames = cell(size(resultPaths));
        for i = 1:numel(resultPaths)
            [~, base, ~] = fileparts(resultPaths{i});
            methodNames{i} = base;
        end
    end

    if nargin < 3
        cfg = struct();
    end

    methods = repmat(struct('name','', 'raw_name','', 'nodes',[], 'links',[], 'requests',[], 'consume',[], 'fail_log',[]), numel(resultPaths), 1);

    for i = 1:numel(resultPaths)
        S = load(resultPaths{i});

        % 只依赖 sfcMapping 保存的 5 个核心变量
        raw = methodNames{i};
        methods(i).raw_name = raw;

        % 应用图例显示名映射（如果提供）
        dispName = raw;
        if isfield(cfg, 'methodDisplayNames')
            try
                if isa(cfg.methodDisplayNames, 'containers.Map') && isKey(cfg.methodDisplayNames, raw)
                    dispName = cfg.methodDisplayNames(raw);
                end
            catch
                % 容错：cfg.methodDisplayNames 不是 Map 或其他异常时，退回 raw
                dispName = raw;
            end
        end
        methods(i).name = dispName;

        methods(i).nodes    = S.nodes;
        methods(i).links    = S.links;
        methods(i).requests = S.requests;
        methods(i).consume  = S.consume;
        methods(i).fail_log = S.fail_log;
    end

    % 处理“映射后重名”的情况（仅在必要时）
    if isfield(cfg, 'disambiguateDuplicateLegendNames') && cfg.disambiguateDuplicateLegendNames
        names = {methods.name};
        [u, ~, ic] = unique(names);
        cnt = accumarray(ic(:), 1);
        dupIdx = find(cnt > 1);
        if ~isempty(dupIdx)
            for k = 1:numel(dupIdx)
                dn = u{dupIdx(k)};
                idxs = find(strcmp(names, dn));
                if numel(idxs) <= 1
                    continue;
                end
                % 尽量只对 RDA 这类“合并显示名”做区分
                for j = 1:numel(idxs)
                    ii = idxs(j);
                    raw = methods(ii).raw_name;
                    if contains(raw, 'Online')
                        methods(ii).name = sprintf('%s(Online)', dn);
                    elseif contains(raw, 'ResourceAndDelayAware')
                        methods(ii).name = sprintf('%s(Offline)', dn);
                    else
                        methods(ii).name = sprintf('%s(%d)', dn, j);
                    end
                end
            end
        end
    end
end

```

---

## b.常用函数\6.结果绘制\1.工具函数\save_svg.m

```matlab
function save_svg(figHandle, savePath, background)
%SAVE_SVG  保存 svg（优先 exportgraphics，兼容旧版本用 print）
%
% figHandle : figure 句柄
% savePath  : 例如 fullfile(outDir, 'xxx.svg')
% background: 'none' 或 'white'

    if nargin < 3
        background = 'none';
    end

    % 保证目录存在
    [saveDir,~,~] = fileparts(savePath);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end

    % exportgraphics 更稳定（矢量）
    if exist('exportgraphics', 'file') == 2
        exportgraphics(figHandle, savePath, ...
            'ContentType', 'vector', ...
            'BackgroundColor', background);
    else
        % 兼容老版本 MATLAB
        set(figHandle, 'PaperPositionMode', 'auto');
        print(figHandle, savePath, '-dsvg');
    end
end

```

---

## b.常用函数\6.结果绘制\2.计算指标\collectTaskCountByReq.m

```matlab
function taskCount = collectTaskCountByReq(nodes, maxReqId)
%COLLECTTASKCOUNTBYREQ  统计每个 req_id 的 tasks 数量（跨所有节点）
%
% 说明：
%   - nodes(n).tasks 是 struct 数组，字段包含 req_id 等。
%   - 本函数把所有节点的 tasks.req_id 拉平后计数。
%
% 输出：
%   taskCount(req_id) = 该请求在全网“实际部署的 VNF 实例（tasks）”数量

    allReqIds = [];
    for n = 1:numel(nodes)
        if isfield(nodes(n), 'tasks') && ~isempty(nodes(n).tasks)
            allReqIds = [allReqIds; [nodes(n).tasks.req_id].']; %#ok<AGROW>
        end
    end

    if isempty(allReqIds)
        taskCount = zeros(maxReqId, 1);
        return;
    end

    taskCount = accumarray(allReqIds, 1, [maxReqId, 1], @sum, 0);
end

```

---

## b.常用函数\6.结果绘制\2.计算指标\extractAcceptedInfo.m

```matlab
function [req_ids, acceptedFlag, accepted_req_ids] = extractAcceptedInfo(requests, consume)
%EXTRACTACCEPTEDINFO  根据 requests 的部署顺序提取“是否接收”序列
%
% 输入：
%   requests : sfcMapping 运行后保存的 requests（通常是 sortedRequests）
%   consume  : initNecessaryStructure 初始化并在部署中更新
%
% 输出：
%   req_ids          : N×1，请求ID（按 requests 的顺序）
%   acceptedFlag     : N×1，0/1
%   accepted_req_ids : A×1，所有 accepted 的请求ID（按出现顺序）

    req_ids = [requests.id].';

    N = numel(req_ids);
    acceptedFlag = zeros(N,1);
    for i = 1:N
        rid = req_ids(i);
        acceptedFlag(i) = consume(rid).accepted;
    end

    accepted_req_ids = req_ids(acceptedFlag == 1);
end

```

---

## b.常用函数\6.结果绘制\2.计算指标\extractDetailedConsumeInfo.m

```matlab
function detailInfo = extractDetailedConsumeInfo(consume, req_id)
%EXTRACTDETAILEDCONSUMEINFO  提取指定请求的详细消耗信息
%
% 输入：
%   consume : sfcMapping 运行后保存的 consume 结构体数组
%   req_id  : 请求ID
%
% 输出：
%   detailInfo : 结构体，包含：
%     .req_id           : 请求ID
%     .accepted         : 是否被接受 (0/1)
%     .cpu_consume      : 总CPU消耗
%     .memory_consume   : 总内存消耗
%     .bandwidth_consume: 总带宽消耗
%     .delay_consume    : 总时延消耗
%     .e2eConsume       : 按目的节点分组的详细消耗（结构体数组）
%       每个e2eConsume元素包含：
%         .dest_id           : 目的节点ID
%         .vnf_project       : VNF部署方案（与sortedPlan对应）
%         .cpu_consume       : 本分支CPU消耗
%         .memory_consume    : 本分支内存消耗
%         .bandwidth_consume : 本分支带宽消耗
%         .delay_consume     : 本分支时延消耗
%         .vnfconsume        : 本分支各VNF的详细消耗（结构体数组）
%           每个vnfconsume元素包含：
%             .vnfid             : VNF ID
%             .placeVnfLinks     : 经过的链路列表
%             .placeVnfNode      : 部署的节点ID
%             .cpu_consume       : 本VNF的CPU消耗（共享时为0）
%             .memory_consume    : 本VNF的内存消耗（共享时为0）
%             .bandwidth_consume : 本VNF的带宽消耗（共享时为0）
%             .delay_consume     : 本VNF的时延消耗
%
% 示例用法：
%   % 查看请求23的详细消耗
%   info = extractDetailedConsumeInfo(consume, 23);
%   disp(info);
%
%   % 查看请求23第一个目的节点的各VNF消耗
%   if info.accepted && ~isempty(info.e2eConsume)
%       disp(info.e2eConsume(1).vnfconsume);
%   end

    detailInfo = struct();
    
    if req_id > numel(consume) || req_id < 1
        warning('请求ID %d 超出范围', req_id);
        detailInfo.req_id = req_id;
        return;
    end
    
    c = consume(req_id);
    
    % 使用consume中存储的req_id（如果存在），否则使用传入的req_id
    if isfield(c, 'req_id')
        detailInfo.req_id = c.req_id;
    else
        detailInfo.req_id = req_id;
    end
    
    detailInfo.accepted = c.accepted;
    detailInfo.cpu_consume = c.cpu_consume;
    detailInfo.memory_consume = c.memory_consume;
    detailInfo.bandwidth_consume = c.bandwidth_consume;
    detailInfo.delay_consume = c.delay_consume;
    
    % 检查是否存在e2eConsume字段
    if isfield(c, 'e2eConsume')
        detailInfo.e2eConsume = c.e2eConsume;
    else
        detailInfo.e2eConsume = [];
    end
end

```

---

## b.常用函数\6.结果绘制\2.计算指标\getE2EDelayForRequest.m

```matlab
function [e2e_delay, sourceTag] = getE2EDelayForRequest(nodes, req, req_id)
%GETE2EDELAYFORREQUEST  计算单个请求的端到端时延
%
% 端到端时延 e2e_delay 的定义：
%   e2e_delay = max(每个 dest 分支的最后一个 VNF 完成时间) - 1
%   （减1是因为部署从 t=1 开始）
%
% 数据来源优先级：
%   1) requests 里已记录的字段（由 deploy_requests 在成功部署时写入）：
%        - req.e2e_delay        (标量，最准确)
%        - req.branch_end_time  (dest_num×1)
%   2) 回退：从 nodes.tasks 估计（共享分支可能不准确）
%
% 输出：
%   e2e_delay : 标量（可能为 NaN 表示无法计算）
%   sourceTag : 字符串，表示本次使用了哪个来源

    % ---------- 1) 优先：req 里直接有 e2e_delay ----------
    if isfield(req, 'e2e_delay') && ~isempty(req.e2e_delay) && req.e2e_delay > 0
        e2e_delay = req.e2e_delay;
        sourceTag = "requests.e2e_delay";
        return;
    end

    % ---------- 2) 次优：req 里有 branch_end_time ----------
    if isfield(req, 'branch_end_time') && ~isempty(req.branch_end_time) && any(req.branch_end_time > 0)
        e2e_delay = max(req.branch_end_time(:)) - 1;  % 减1是因为从t=1开始
        sourceTag = "requests.branch_end_time";
        return;
    end

    % ---------- 3) 回退：从 nodes.tasks 估计 ----------
    % 注意：如果启用了 VNF 共享，共享分支不会写入 tasks 记录，
    %       因此这种方式可能低估真实的端到端时延。
    e2e_delay = NaN;
    sourceTag = "nodes.tasks";

    if isempty(nodes)
        return;
    end

    dests = req.dest(req.dest > 0);
    dest_num = numel(dests);
    vnf_num  = numel(req.vnf);

    % 收集所有节点中属于该 req_id 的 tasks
    branch_end = NaN(dest_num, 1);

    for n = 1:numel(nodes)
        if ~isfield(nodes(n), 'tasks') || isempty(nodes(n).tasks)
            continue;
        end

        tk = nodes(n).tasks;
        % 只保留该 req_id 的记录
        maskReq = ([tk.req_id] == req_id);
        if ~any(maskReq)
            continue;
        end

        tk = tk(maskReq);

        % 逐 dest_idx 找最后一个 VNF 的 t_end
        for di = 1:dest_num
            maskDest = ([tk.dest_idx] == di) & ([tk.vnf_idx] == vnf_num);
            if any(maskDest)
                t_end_candidates = max([tk(maskDest).t_end]);
                % 保留最大值（处理多节点情况）
                if isnan(branch_end(di)) || t_end_candidates > branch_end(di)
                    branch_end(di) = t_end_candidates;
                end
            end
        end
    end

    if all(isnan(branch_end))
        % 完全无法估计
        e2e_delay = NaN;
        return;
    end

    % 取有效分支的最大结束时间，减1得到端到端时延
    e2e_delay = max(branch_end(~isnan(branch_end))) - 1;
end

```

---

## b.常用函数\6.结果绘制\2.计算指标\printDetailedConsumeTable.m

```matlab
function printDetailedConsumeTable(consume, req_ids)
%PRINTDETAILEDCONSUMETABLE  打印请求的详细消耗信息表格
%
% 输入：
%   consume : sfcMapping 运行后保存的 consume 结构体数组
%   req_ids : 要打印的请求ID数组（可选，默认打印所有已接受的请求）
%
% 输出：
%   控制台打印格式化的消耗信息表格
%
% 示例用法：
%   % 打印所有已接受请求的消耗
%   printDetailedConsumeTable(consume);
%
%   % 打印指定请求的消耗
%   printDetailedConsumeTable(consume, [23, 41, 22]);

    if nargin < 2 || isempty(req_ids)
        % 找出所有已接受的请求ID
        req_ids = [];
        for i = 1:numel(consume)
            if consume(i).accepted == 1
                % 优先使用consume中存储的req_id
                if isfield(consume, 'req_id') && ~isempty(consume(i).req_id)
                    req_ids(end+1) = consume(i).req_id;
                else
                    req_ids(end+1) = i;
                end
            end
        end
    end
    
    fprintf('\n========== 请求消耗汇总表 ==========\n');
    fprintf('%-8s %-10s %-12s %-15s %-18s %-15s\n', ...
        'req_id', 'accepted', 'cpu_consume', 'memory_consume', 'bandwidth_consume', 'delay_consume');
    fprintf('%s\n', repmat('-', 1, 80));
    
    for i = 1:numel(req_ids)
        rid = req_ids(i);
        if rid > numel(consume) || rid < 1
            continue;
        end
        c = consume(rid);
        fprintf('%-8d %-10d %-12.2f %-15.2f %-18.2f %-15.2f\n', ...
            rid, c.accepted, c.cpu_consume, c.memory_consume, c.bandwidth_consume, c.delay_consume);
    end
    
    % 打印详细的e2eConsume信息
    fprintf('\n');
    for i = 1:numel(req_ids)
        rid = req_ids(i);
        if rid > numel(consume) || rid < 1
            continue;
        end
        c = consume(rid);
        
        if ~isfield(c, 'e2eConsume') || isempty(c.e2eConsume)
            continue;
        end
        
        if c.accepted == 0
            continue;
        end
        
        fprintf('\n========== 请求 %d 的分支详细消耗 ==========\n', rid);
        fprintf('%-10s %-12s %-15s %-18s %-15s\n', ...
            'dest_id', 'cpu_consume', 'memory_consume', 'bandwidth_consume', 'delay_consume');
        fprintf('%s\n', repmat('-', 1, 70));
        
        for d = 1:numel(c.e2eConsume)
            e = c.e2eConsume(d);
            if e.dest_id == 0
                continue;
            end
            fprintf('%-10d %-12.2f %-15.2f %-18.2f %-15.2f\n', ...
                e.dest_id, e.cpu_consume, e.memory_consume, e.bandwidth_consume, e.delay_consume);
        end
        
        % 打印每个分支的VNF详细消耗
        for d = 1:numel(c.e2eConsume)
            e = c.e2eConsume(d);
            if e.dest_id == 0 || isempty(e.vnfconsume)
                continue;
            end
            
            fprintf('\n  --- 目的节点 %d 的VNF详细消耗 ---\n', e.dest_id);
            fprintf('  %-8s %-15s %-12s %-12s %-15s %-18s %-15s\n', ...
                'vnfid', 'placeVnfNode', 'cpu_consume', 'mem_consume', 'bw_consume', 'delay_consume', 'placeVnfLinks');
            fprintf('  %s\n', repmat('-', 1, 95));
            
            for v = 1:numel(e.vnfconsume)
                vnf = e.vnfconsume(v);
                if isempty(vnf.placeVnfLinks)
                    linksStr = '[]';
                else
                    linksStr = sprintf('[%s]', strjoin(string(vnf.placeVnfLinks), ','));
                end
                fprintf('  %-8d %-15d %-12.2f %-12.2f %-15.2f %-18.2f %s\n', ...
                    vnf.vnfid, vnf.placeVnfNode, vnf.cpu_consume, vnf.memory_consume, ...
                    vnf.bandwidth_consume, vnf.delay_consume, linksStr);
            end
        end
    end
    
    fprintf('\n');
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_acceptance_rate_curve.m

```matlab
function metric = plot_acceptance_rate_curve(methods, outDir, cfg)
%PLOT_ACCEPTANCE_RATE_CURVE  请求接受率变化曲线（多方法对比）
%
% 输入：
%   methods : struct 数组，每个元素至少包含：
%             .name, .requests, .consume
%   outDir  : 输出目录（svg 与 mat 都会存这里）
%   cfg     : getPlotCfg() 返回的配置
%
% 输出：
%   metric : 用于画图的指标变量（也会被保存为 mat）

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'acceptance_rate_curve';
    metric.methods = repmat(struct('name','', 'x',[], 'acc_rate',[], 'cum_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        req_ids = [methods(m).requests.id].';
        N = numel(req_ids);

        accepted = zeros(N,1);
        for i = 1:N
            rid = req_ids(i);
            accepted(i) = methods(m).consume(rid).accepted;
        end

        cumAccept = cumsum(accepted);
        accRate = cumAccept ./ (1:N).';

        metric.methods(m).name       = methods(m).name;
        metric.methods(m).x          = (1:N).';
        metric.methods(m).acc_rate   = accRate;
        metric.methods(m).cum_accept = cumAccept;
    end

    % ===================== 2) 绘图 =====================
    fig = figure('Visible', cfg.figVisible);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x, metric.methods(m).acc_rate, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('请求序号（按部署顺序）');
    ylabel('累计接受率');
    title('请求接受率变化曲线');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AcceptanceRate.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_AcceptanceRate.mat'), 'metric');
    end

    close(fig);
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_avg_bandwidth_consume_vs_success.m

```matlab
function metric = plot_avg_bandwidth_consume_vs_success(methods, outDir, cfg)
%PLOT_AVG_BANDWIDTH_CONSUME_VS_SUCCESS  平均 Bandwidth 资源消耗随成功部署数量变化（多方法对比）
%
% 定义：
%   对每个成功请求：bw_i = consume(req_id).bandwidth_consume
%   曲线：y(k) = mean(bw_1 ... bw_k)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_bandwidth_consume_vs_success';
    metric.methods = repmat(struct('name','', 'x_success',[], 'avg_bw',[], 'bw_per_accept',[], 'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);

        A = numel(accepted_req_ids);
        bw = zeros(A,1);
        for k = 1:A
            rid = accepted_req_ids(k);
            bw(k) = methods(m).consume(rid).bandwidth_consume;
        end

        x = (1:A).';
        avg_bw = cumsum(bw) ./ x;

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).avg_bw = avg_bw;
        metric.methods(m).bw_per_accept = bw;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘图 =====================
    fig = figure('Visible', cfg.figVisible);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_bw, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均带宽消耗');
    title('平均带宽消耗');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AvgBandwidthConsume_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_AvgBandwidthConsume_vs_Success.mat'), 'metric');
    end

    close(fig);
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_avg_cpu_consume_vs_success.m

```matlab
function metric = plot_avg_cpu_consume_vs_success(methods, outDir, cfg)
%PLOT_AVG_CPU_CONSUME_VS_SUCCESS  平均 CPU 资源消耗随成功部署数量变化（多方法对比）
%
% 定义：
%   对每个成功请求：cpu_i = consume(req_id).cpu_consume
%   曲线：y(k) = mean(cpu_1 ... cpu_k)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_cpu_consume_vs_success';
    metric.methods = repmat(struct('name','', 'x_success',[], 'avg_cpu',[], 'cpu_per_accept',[], 'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);

        A = numel(accepted_req_ids);
        cpu = zeros(A,1);
        for k = 1:A
            rid = accepted_req_ids(k);
            cpu(k) = methods(m).consume(rid).cpu_consume;
        end

        x = (1:A).';
        avg_cpu = cumsum(cpu) ./ x;

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).avg_cpu = avg_cpu;
        metric.methods(m).cpu_per_accept = cpu;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘图 =====================
    fig = figure('Visible', cfg.figVisible);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_cpu, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均CPU资源消耗');
    title('平均CPU资源消耗');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AvgCPUConsume_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_AvgCPUConsume_vs_Success.mat'), 'metric');
    end

    close(fig);
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_avg_e2e_delay_vs_success.m

```matlab
function metric = plot_avg_e2e_delay_vs_success(methods, outDir, cfg)
%PLOT_AVG_E2E_DELAY_VS_SUCCESS  平均端到端时延 vs 已成功部署SFC数量（多方法对比）
%
% 端到端时延计算：
%   e2e_delay = max(branch_end_time) - 1
%   其中 branch_end_time(dest_idx) 是"该请求第 dest 个分支最后一个 VNF 完成的时间"。
%   deploy_requests 在成功部署时会自动记录 requests.e2e_delay 和 requests.branch_end_time。
%
% 输入：
%   methods : struct 数组，每个元素至少包含：
%             .name, .nodes, .requests, .consume
%   outDir  : 输出目录
%   cfg     : 配置（getPlotCfg）

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_e2e_delay_vs_success';
    metric.methods = repmat(struct( ...
        'name','', ...
        'x_success',[], ...
        'avg_e2e_delay',[], ...
        'e2e_delay_per_accept',[], ...
        'req_id_per_accept',[], ...
        'e2e_source',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [req_ids, acceptedFlag, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);
        A = numel(accepted_req_ids);

        e2e_delay = NaN(A,1);
        srcTag    = strings(A,1);

        % 逐“成功请求”计算 e2e_delay
        for k = 1:A
            rid = accepted_req_ids(k);
            % 在 requests 中找到该 rid 对应的 req 结构
            idx = find(req_ids == rid, 1);
            req = methods(m).requests(idx);

            [e2e_delay(k), srcTag(k)] = getE2EDelayForRequest(methods(m).nodes, req, rid);
        end

        % 过滤掉 NaN（无法计算的点）
        valid = ~isnan(e2e_delay);
        e2e_delay_valid = e2e_delay(valid);
        srcTag_valid    = srcTag(valid);
        req_valid       = accepted_req_ids(valid);

        x = (1:numel(e2e_delay_valid)).';
        avg_delay = cumsum(e2e_delay_valid) ./ x;

        metric.methods(m).name               = methods(m).name;
        metric.methods(m).x_success          = x;
        metric.methods(m).avg_e2e_delay      = avg_delay;
        metric.methods(m).e2e_delay_per_accept = e2e_delay_valid;
        metric.methods(m).req_id_per_accept    = req_valid;
        metric.methods(m).e2e_source           = srcTag_valid;
    end

    % ===================== 2) 绘图 =====================
    fig = figure('Visible', cfg.figVisible);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_e2e_delay, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均端到端时延');
    title('平均端到端时延随成功部署数量变化');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AvgE2EDelay_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_AvgE2EDelay_vs_Success.mat'), 'metric');
    end

    close(fig);
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_avg_memory_consume_vs_success.m

```matlab
function metric = plot_avg_memory_consume_vs_success(methods, outDir, cfg)
%PLOT_AVG_MEMORY_CONSUME_VS_SUCCESS  平均 Memory 资源消耗随成功部署数量变化（多方法对比）
%
% 定义：
%   对每个成功请求：mem_i = consume(req_id).memory_consume
%   曲线：y(k) = mean(mem_1 ... mem_k)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_memory_consume_vs_success';
    metric.methods = repmat(struct('name','', 'x_success',[], 'avg_mem',[], 'mem_per_accept',[], 'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);

        A = numel(accepted_req_ids);
        mem = zeros(A,1);
        for k = 1:A
            rid = accepted_req_ids(k);
            mem(k) = methods(m).consume(rid).memory_consume;
        end

        x = (1:A).';
        avg_mem = cumsum(mem) ./ x;

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).avg_mem = avg_mem;
        metric.methods(m).mem_per_accept = mem;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘图 =====================
    fig = figure('Visible', cfg.figVisible);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_mem, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均内存资源消耗');
    title('平均内存资源消耗');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AvgMemoryConsume_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_AvgMemoryConsume_vs_Success.mat'), 'metric');
    end

    close(fig);
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_avg_slack_vs_success.m

```matlab
function metric = plot_avg_slack_vs_success(methods, outDir, cfg)
%PLOT_AVG_SLACK_VS_SUCCESS  平均时延满足度“裕量”随成功部署数量变化（多方法对比）
%
% 定义：
%   对每个成功请求：
%     e2e_delay = 端到端时延（推荐来自 requests.e2e_delay 或 branch_end_time）
%     slack_abs = max_delay - e2e_delay
%     slack_ratio = (max_delay - e2e_delay) / max_delay
%
% 作图：
%   cfg.slackMode = 'ratio' : y 轴画 slack_ratio 的累计平均
%   cfg.slackMode = 'abs'   : y 轴画 slack_abs 的累计平均

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_slack_vs_success';
    metric.slackMode   = cfg.slackMode;
    metric.methods = repmat(struct( ...
        'name','', ...
        'x_success',[], ...
        'avg_slack',[], ...
        'slack_abs_per_accept',[], ...
        'slack_ratio_per_accept',[], ...
        'req_id_per_accept',[], ...
        'e2e_source',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [req_ids, acceptedFlag, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);
        A = numel(accepted_req_ids);

        slack_abs   = NaN(A,1);
        slack_ratio = NaN(A,1);
        srcTag      = strings(A,1);

        for k = 1:A
            rid = accepted_req_ids(k);
            idx = find(req_ids == rid, 1);
            req = methods(m).requests(idx);

            [e2e_delay, srcTag(k)] = getE2EDelayForRequest(methods(m).nodes, req, rid);

            if isnan(e2e_delay) || ~isfield(req, 'max_delay') || isempty(req.max_delay)
                slack_abs(k)   = NaN;
                slack_ratio(k) = NaN;
            else
                slack_abs(k) = req.max_delay - e2e_delay;
                slack_ratio(k) = (req.max_delay - e2e_delay) / req.max_delay;
            end
        end

        % 过滤 NaN
        valid = ~isnan(slack_ratio);
        slack_abs_v   = slack_abs(valid);
        slack_ratio_v = slack_ratio(valid);
        srcTag_v      = srcTag(valid);
        req_v         = accepted_req_ids(valid);

        x = (1:numel(req_v)).';

        if strcmpi(cfg.slackMode, 'abs')
            y = cumsum(slack_abs_v) ./ x;
        else
            y = cumsum(slack_ratio_v) ./ x;
        end

        metric.methods(m).name                 = methods(m).name;
        metric.methods(m).x_success            = x;
        metric.methods(m).avg_slack            = y;
        metric.methods(m).slack_abs_per_accept   = slack_abs_v;
        metric.methods(m).slack_ratio_per_accept = slack_ratio_v;
        metric.methods(m).req_id_per_accept      = req_v;
        metric.methods(m).e2e_source             = srcTag_v;
    end

    % ===================== 2) 绘图 =====================
    fig = figure('Visible', cfg.figVisible);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_slack, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');

    if strcmpi(cfg.slackMode, 'abs')
        ylabel('平均裕量时延（max\_delay - e2e\_delay）');
        title('平均裕量时延随成功部署数量变化');
        figName = 'Fig_AvgSlackAbs_vs_Success.svg';
        matName = 'Metric_AvgSlackAbs_vs_Success.mat';
    else
        ylabel('平均裕量比例（(max\_delay - e2e\_delay)/max\_delay）');
        title('平均裕量比例随成功部署数量变化');
        figName = 'Fig_AvgSlackRatio_vs_Success.svg';
        matName = 'Metric_AvgSlackRatio_vs_Success.mat';
    end

    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, figName), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, matName), 'metric');
    end

    close(fig);
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_cumulative_resource_consume.m

```matlab
function metric = plot_cumulative_resource_consume(methods, outDir, cfg)
%PLOT_CUMULATIVE_RESOURCE_CONSUME  累计资源消耗随成功部署数量变化（多方法对比）
%
% 功能：
%   绘制随成功部署请求数增加，CPU、内存、带宽的累计消耗曲线
%   同时导出数据到Excel文件
%
% 定义：
%   对每个成功请求 k：
%     cumCpu(k) = sum(cpu_1 ... cpu_k)
%     cumMem(k) = sum(mem_1 ... mem_k)
%     cumBw(k)  = sum(bw_1  ... bw_k)
%
% 输入：
%   methods : 结构体数组，每个元素包含：
%     .name     : 方法名称
%     .requests : 请求数组
%     .consume  : 消耗数组
%   outDir  : 输出目录
%   cfg     : 绘图配置（可选）
%
% 输出：
%   metric  : 包含计算结果的结构体

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'cumulative_resource_consume';
    metric.methods = repmat(struct('name','', 'x_success',[], ...
        'cum_cpu',[], 'cum_mem',[], 'cum_bw',[], ...
        'cpu_per_accept',[], 'mem_per_accept',[], 'bw_per_accept',[], ...
        'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算各方法的累计消耗 =====================
    for m = 1:numel(methods)
        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);

        A = numel(accepted_req_ids);
        cpu = zeros(A,1);
        mem = zeros(A,1);
        bw  = zeros(A,1);
        
        for k = 1:A
            rid = accepted_req_ids(k);
            cpu(k) = methods(m).consume(rid).cpu_consume;
            mem(k) = methods(m).consume(rid).memory_consume;
            bw(k)  = methods(m).consume(rid).bandwidth_consume;
        end

        x = (1:A).';
        cum_cpu = cumsum(cpu);
        cum_mem = cumsum(mem);
        cum_bw  = cumsum(bw);

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).cum_cpu = cum_cpu;
        metric.methods(m).cum_mem = cum_mem;
        metric.methods(m).cum_bw  = cum_bw;
        metric.methods(m).cpu_per_accept = cpu;
        metric.methods(m).mem_per_accept = mem;
        metric.methods(m).bw_per_accept  = bw;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘制三个子图 =====================
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, 1400, 400]);
    
    colors = lines(numel(methods));
    methodNames = {methods.name};

    % ---------- 子图1: 累计CPU消耗 ----------
    subplot(1, 3, 1);
    hold on;
    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).cum_cpu, ...
             'LineWidth', cfg.lineWidth, 'Color', colors(m,:));
    end
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('累计 CPU 消耗');
    title('累计 CPU 消耗');
    legend(methodNames, 'Location', 'northwest');

    % ---------- 子图2: 累计内存消耗 ----------
    subplot(1, 3, 2);
    hold on;
    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).cum_mem, ...
             'LineWidth', cfg.lineWidth, 'Color', colors(m,:));
    end
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('累计内存消耗');
    title('累计内存消耗');
    legend(methodNames, 'Location', 'northwest');

    % ---------- 子图3: 累计带宽消耗 ----------
    subplot(1, 3, 3);
    hold on;
    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).cum_bw, ...
             'LineWidth', cfg.lineWidth, 'Color', colors(m,:));
    end
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('累计带宽消耗');
    title('累计带宽消耗');
    legend(methodNames, 'Location', 'northwest');

    sgtitle('累计资源消耗随成功部署数量变化', 'FontSize', cfg.fontSize + 2);

    % ===================== 3) 保存图形 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_CumulativeResourceConsume.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_CumulativeResourceConsume.mat'), 'metric');
    end

    % ===================== 4) 导出Excel =====================
    try
        exportCumulativeToExcel(metric, outDir);
        fprintf('累计资源消耗数据已导出到 Excel\n');
    catch ME
        warning(ME.identifier, '%s', ME.message);
    end

    close(fig);
end

function exportCumulativeToExcel(metric, outDir)
%EXPORTCUMULATIVETOEXCEL 导出累计资源消耗数据到Excel
    
    xlsxFile = fullfile(outDir, 'Data_CumulativeResourceConsume.xlsx');
    
    % 找出最大成功数（用于对齐列）
    maxSuccess = 0;
    for m = 1:numel(metric.methods)
        maxSuccess = max(maxSuccess, numel(metric.methods(m).x_success));
    end
    
    if maxSuccess == 0
        warning('没有成功部署的请求，跳过Excel导出');
        return;
    end
    
    numMethods = numel(metric.methods);
    
    % ========== Sheet 1: 累计CPU消耗 ==========
    header = cell(1, numMethods + 1);
    header{1} = '成功部署数';
    for m = 1:numMethods
        header{m+1} = metric.methods(m).name;
    end
    
    dataMatrix = cell(maxSuccess, numMethods + 1);
    for k = 1:maxSuccess
        dataMatrix{k, 1} = k;
        for m = 1:numMethods
            if k <= numel(metric.methods(m).cum_cpu)
                dataMatrix{k, m+1} = metric.methods(m).cum_cpu(k);
            else
                dataMatrix{k, m+1} = '';
            end
        end
    end
    
    T_cpu = cell2table([header; dataMatrix]);
    writetable(T_cpu, xlsxFile, 'Sheet', '累计CPU消耗', 'WriteVariableNames', false);
    
    % ========== Sheet 2: 累计内存消耗 ==========
    dataMatrix = cell(maxSuccess, numMethods + 1);
    for k = 1:maxSuccess
        dataMatrix{k, 1} = k;
        for m = 1:numMethods
            if k <= numel(metric.methods(m).cum_mem)
                dataMatrix{k, m+1} = metric.methods(m).cum_mem(k);
            else
                dataMatrix{k, m+1} = '';
            end
        end
    end
    
    T_mem = cell2table([header; dataMatrix]);
    writetable(T_mem, xlsxFile, 'Sheet', '累计内存消耗', 'WriteVariableNames', false);
    
    % ========== Sheet 3: 累计带宽消耗 ==========
    dataMatrix = cell(maxSuccess, numMethods + 1);
    for k = 1:maxSuccess
        dataMatrix{k, 1} = k;
        for m = 1:numMethods
            if k <= numel(metric.methods(m).cum_bw)
                dataMatrix{k, m+1} = metric.methods(m).cum_bw(k);
            else
                dataMatrix{k, m+1} = '';
            end
        end
    end
    
    T_bw = cell2table([header; dataMatrix]);
    writetable(T_bw, xlsxFile, 'Sheet', '累计带宽消耗', 'WriteVariableNames', false);
    
    % ========== Sheet 4: 每请求资源消耗明细 ==========
    % 创建详细的每请求消耗表格
    allRows = {};
    for m = 1:numMethods
        methodName = metric.methods(m).name;
        A = numel(metric.methods(m).req_id_per_accept);
        for k = 1:A
            row = {methodName, k, metric.methods(m).req_id_per_accept(k), ...
                   metric.methods(m).cpu_per_accept(k), ...
                   metric.methods(m).mem_per_accept(k), ...
                   metric.methods(m).bw_per_accept(k)};
            allRows = [allRows; row]; %#ok<AGROW>
        end
    end
    
    if ~isempty(allRows)
        detailHeader = {'方法名称', '成功序号', '请求ID', 'CPU消耗', '内存消耗', '带宽消耗'};
        T_detail = cell2table([detailHeader; allRows]);
        writetable(T_detail, xlsxFile, 'Sheet', '每请求消耗明细', 'WriteVariableNames', false);
    end
    
    fprintf('数据已导出到: %s\n', xlsxFile);
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_failure_breakdown_distribution.m

```matlab
function metric = plot_failure_breakdown_distribution(methods, outDir, cfg)
%PLOT_FAILURE_BREAKDOWN_DISTRIBUTION  拒绝分布(FBD)：按失败原因统计（分组柱状图）
%
% 失败原因（不含"不可调度"）：
%   - 超时           : fail_log.time_out
%   - 链路资源不足   : fail_log.lack_bw
%   - CPU不足        : fail_log.lack_cpu
%   - 内存不足       : fail_log.lack_mem
%
% 作图：分组柱状图（类似用户提供的图片）
%   - X轴：失败原因类别
%   - 每个类别下有多个方法的柱子并排
%   - Y轴：失败次数

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    % 失败原因（不含"不可调度"）
    reasonNames = {'超时', '链路资源不足', 'CPU不足', '内存不足'};
    reasonNamesEng = {'Timeout', 'BandwidthInsufficient', 'CPUInsufficient', 'MemoryInsufficient'};
    R = numel(reasonNames);
    M = numel(methods);

    countMat = zeros(M, R);  % 每行是一个方法，每列是一种失败原因
    totalFail = zeros(M, 1);

    % ===================== 1) 统计 =====================
    for m = 1:M
        fl = methods(m).fail_log;

        if isempty(fl)
            totalFail(m) = 0;
            continue;
        end

        totalFail(m) = numel(fl);

        % --- 字段名兼容 ---
        bwField = pickField(fl, {'lack_bw', 'lack_bandwidth'});
        toField = pickField(fl, {'time_out', 'TIMEOUT'});

        toCnt  = sum([fl.(toField)] == 1);    % 超时
        bwCnt  = sum([fl.(bwField)] == 1);    % 链路资源不足
        cpuCnt = sum([fl.lack_cpu] == 1);     % CPU不足
        memCnt = sum([fl.lack_mem] == 1);     % 内存不足

        % 顺序：超时, 链路资源不足, CPU不足, 内存不足
        countMat(m, :) = [toCnt, bwCnt, cpuCnt, memCnt];
    end

    % 计算比例（可选）
    ratioMat = zeros(M, R);
    for m = 1:M
        if totalFail(m) > 0
            ratioMat(m, :) = countMat(m, :) / totalFail(m);
        end
    end

    % 构建metric结构
    metric = struct();
    metric.metric_name = 'failure_breakdown_distribution';
    metric.reasonNames = reasonNames;
    metric.reasonNamesEng = reasonNamesEng;
    metric.methodNames = {methods.name};
    metric.countMat    = countMat;    % M×R 矩阵：方法×原因
    metric.ratioMat    = ratioMat;
    metric.totalFail   = totalFail;

    % ===================== 2) 绘图：分组柱状图 =====================
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, 800, 500]);

    % 转置矩阵：bar() 的分组柱状图需要 R×M 矩阵
    % 每行是一个类别（失败原因），每列是一个方法
    dataForBar = countMat.';  % R×M
    
    b = bar(dataForBar, 'grouped');
    
    % 设置颜色
    colors = [
        0.3020 0.6863 0.2902;   % 绿色 - 方法1
        0.9961 0.4980 0.0549;   % 橙色 - 方法2  
        0.8510 0.3255 0.3098;   % 红色 - 方法3
        0.4000 0.7608 0.6471;   % 青色 - 方法4
        0.5529 0.6275 0.7961;   % 蓝灰 - 方法5
    ];
    for k = 1:min(M, size(colors, 1))
        b(k).FaceColor = colors(k, :);
    end
    
    % 在柱子上方显示数值
    for k = 1:M
        xtips = b(k).XEndPoints;
        ytips = b(k).YEndPoints;
        labels = string(b(k).YData);
        text(xtips, ytips, labels, 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', 'FontSize', 10);
    end

    % 设置图形属性
    set(gca, 'FontSize', cfg.fontSize);
    xticks(1:R);
    xticklabels(reasonNames);
    ylabel('失败次数', 'FontSize', cfg.fontSize);
    xlabel('失败原因', 'FontSize', cfg.fontSize);
    title('失败原因分布 (Failure Breakdown)', 'FontSize', cfg.fontSize + 2);
    legend({methods.name}, 'Location', 'northeast', 'FontSize', cfg.fontSize - 1);
    grid on;
    box on;

    % ===================== 3) 保存图形 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_FailureBreakdownDistribution.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_FailureBreakdownDistribution.mat'), 'metric');
    end

    % ===================== 4) 导出Excel =====================
    xlsxPath = fullfile(outDir, 'Data_FailureBreakdownDistribution.xlsx');
    exportFailureToExcel(metric, xlsxPath);
    fprintf('  失败分布数据已导出到: %s\n', xlsxPath);

    close(fig);
end

function fieldName = pickField(S, candidates)
%PICKFIELD  在 struct(数组) S 中从候选字段里挑一个存在的字段
    fieldName = candidates{1};
    for i = 1:numel(candidates)
        if isfield(S, candidates{i})
            fieldName = candidates{i};
            return;
        end
    end
end

function exportFailureToExcel(metric, xlsxPath)
%EXPORTFAILURETOEXCEL 将失败分布数据导出为Excel
%
% 输出格式（便于制图）：
%   Sheet1: 失败次数
%       行：方法名
%       列：失败原因
%   Sheet2: 失败比例
%       行：方法名
%       列：失败原因

    methodNames = metric.methodNames(:);
    reasonNames = metric.reasonNames(:).';
    
    % Sheet1: 失败次数
    countTable = array2table(metric.countMat, ...
        'VariableNames', metric.reasonNamesEng, ...
        'RowNames', methodNames);
    
    % Sheet2: 失败比例
    ratioTable = array2table(metric.ratioMat, ...
        'VariableNames', metric.reasonNamesEng, ...
        'RowNames', methodNames);
    
    % 删除已有文件（避免追加问题）
    if isfile(xlsxPath)
        delete(xlsxPath);
    end
    
    % 写入Excel
    writetable(countTable, xlsxPath, 'Sheet', '失败次数', 'WriteRowNames', true);
    writetable(ratioTable, xlsxPath, 'Sheet', '失败比例', 'WriteRowNames', true);
    
    % 添加总失败数
    totalTable = table(methodNames, metric.totalFail, ...
        'VariableNames', {'方法', '总失败数'});
    writetable(totalTable, xlsxPath, 'Sheet', '总览');
end

```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_gantt_chart.m

```matlab
function metric = plot_gantt_chart(nodes, outDir, cfg, methodName)
%PLOT_GANTT_CHART  绘制节点任务甘特图
%
% 根据 nodes.tasks 绘制甘特图，展示各节点上 VNF 任务的执行时间段。
% 每个色块显示 "sfc{req_id}" 和 "vnf{vnf_id}"。
%
% 输入：
%   nodes      : 节点数组（包含 tasks 字段）
%   outDir     : 输出目录（svg 与 mat 都会存这里）
%   cfg        : getPlotCfg() 返回的配置（可选）
%   methodName : 方法名称（用于文件命名，可选）
%
% 输出：
%   metric : 用于画图的指标变量（也会被保存为 mat）

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    if nargin < 4 || isempty(methodName)
        methodName = 'Method';
    end
    ensure_dir(outDir);

    % ===================== 1) 收集所有任务 =====================
    allTasks = [];
    for n = 1:numel(nodes)
        if ~isfield(nodes(n), 'tasks') || isempty(nodes(n).tasks)
            continue;
        end
        for t = 1:numel(nodes(n).tasks)
            task = nodes(n).tasks(t);
            task.node_id = n;  % 记录节点ID
            if isempty(allTasks)
                allTasks = task;
            else
                allTasks(end+1) = task; %#ok<AGROW>
            end
        end
    end

    if isempty(allTasks)
        warning('plot_gantt_chart: 没有找到任何任务记录');
        metric = struct();
        metric.metric_name = 'gantt_chart';
        metric.tasks = [];
        return;
    end

    % ===================== 1.5) 时间轴统一从0开始 =====================
    % 说明：你的数据里从1开始是为了Matlab测试方便；作图时统一平移到从0开始更直观
    t0 = min([allTasks.t_start]);
    if ~isempty(t0) && isfinite(t0) && t0 ~= 0
        for i = 1:numel(allTasks)
            allTasks(i).t_start = allTasks(i).t_start - t0;
            allTasks(i).t_end   = allTasks(i).t_end   - t0;
        end
    end

    % 保存指标
    metric = struct();
    metric.metric_name = 'gantt_chart';
    metric.methodName = methodName;
    metric.tasks = allTasks;
    metric.node_ids = unique([allTasks.node_id]);
    metric.time_shift_to_zero = t0; % 记录平移量（原始时间 - t0）

    % ===================== 2) 绘图准备 =====================
    % 获取所有涉及的节点
    node_ids = unique([allTasks.node_id]);
    num_nodes = numel(node_ids);
    
    % 获取所有请求ID用于生成颜色映射
    req_ids = unique([allTasks.req_id]);
    num_reqs = numel(req_ids);
    
    % 生成颜色映射（每个请求一个颜色）
    if num_reqs <= 10
        colors = lines(num_reqs);
    else
        colors = hsv(num_reqs);
    end
    req_color_map = containers.Map(req_ids, num2cell(colors, 2));

    % ===================== 3) 绘制甘特图 =====================
    % 让甘特图更“宽”，以便色块上的文字全部使用“一行显示”
    % 尺寸随最大完成时间/节点数自适应（像素）
    all_times = [[allTasks.t_start], [allTasks.t_end]];
    t_max = max(all_times);
    px_per_time = 25;            % 每单位时间对应的像素宽度（越大越宽）
    fig_w = max(1400, round(px_per_time * t_max));
    fig_h = max(650,  round(26 * num_nodes + 220));

    fig = figure('Visible', cfg.figVisible, 'Units', 'pixels', 'Position', [50, 50, fig_w, fig_h]);
    set(fig, 'PaperPositionMode', 'auto'); % 保存svg时使用当前窗口大小
    hold on;

    bar_height = 0.8;  % 色块高度
    
    for i = 1:numel(allTasks)
        task = allTasks(i);
        
        % 找到该节点在 y 轴的位置
        y_pos = find(node_ids == task.node_id, 1);
        
        % 任务时间
        t_start = task.t_start;
        t_end = task.t_end;
        duration = t_end - t_start;
        
        if duration <= 0
            continue;
        end
        
        % 获取颜色
        color = req_color_map(task.req_id);
        
        % 绘制矩形
        rectangle('Position', [t_start, y_pos - bar_height/2, duration, bar_height], ...
                  'FaceColor', color, ...
                  'EdgeColor', 'k', ...
                  'LineWidth', 0.5);
        
        % 添加标签：所有色块统一只显示一行（req_id/vnf_id）
        % 依赖更宽的画布提升可读性；极短任务仍可能拥挤，但保持“一行规则”一致
        label_x = t_start + duration/2;
        label_y = y_pos;

        % 根据色块宽度粗略调节字号（仍保持单行）
        if duration >= 4
            fs = 8;
        elseif duration >= 2
            fs = 7;
        else
            fs = 6;
        end

        text(label_x, label_y, sprintf('%d/%d', task.req_id, task.vnf_id), ...
             'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', ...
             'FontSize', fs, ...
             'Clipping', 'on', ...
             'Color', getContrastColor(color));
    end

    % ===================== 4) 设置坐标轴 =====================
    % Y轴
    ylim([0.5, num_nodes + 0.5]);
    yticks(1:num_nodes);
    yticklabels(arrayfun(@num2str, node_ids, 'UniformOutput', false));
    ylabel('节点');

    % X轴
    xlim([0, t_max * 1.05]);
    xlabel('完成时间');

    % 其他设置
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    title(sprintf('任务甘特图 - %s', methodName));
    
    % 添加图例说明
    annotation('textbox', [0.75, 0.02, 0.2, 0.05], ...
               'String', '色块标注: 请求ID/VNF类型ID', ...
               'EdgeColor', 'none', ...
               'FontSize', 8, ...
               'HorizontalAlignment', 'right');

    hold off;

    % ===================== 5) 保存 =====================
    figName = sprintf('Fig_GanttChart_%s.svg', methodName);
    matName = sprintf('Metric_GanttChart_%s.mat', methodName);
    
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, figName), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, matName), 'metric');
    end

    close(fig);
end

function textColor = getContrastColor(bgColor)
%GETCONTRASTCOLOR  根据背景色返回对比文字颜色（黑或白）
    luminance = 0.299 * bgColor(1) + 0.587 * bgColor(2) + 0.114 * bgColor(3);
    if luminance > 0.5
        textColor = [0, 0, 0];  % 黑色
    else
        textColor = [1, 1, 1];  % 白色
    end
end


```

---

## b.常用函数\6.结果绘制\3.绘图函数\plot_vnf_sharing_gain_ratio_vs_success.m

```matlab
function metric = plot_vnf_sharing_gain_ratio_vs_success(methods, outDir, cfg)
%PLOT_VNF_SHARING_GAIN_RATIO_VS_SUCCESS  VNF共享增益比随成功部署数量变化（多方法对比）
%
% 你给出的定义：
%   理论无共享（每个目的节点单独一条链）所需 VNF 数量：
%       vnf_theory = dest_num * vnf_num
%   实际部署的 VNF 实例数量：
%       vnf_actual = 该 req_id 在 nodes.tasks 中出现的次数
%   增益比：
%       gain_ratio = (vnf_theory - vnf_actual) / vnf_theory
%
% 输出曲线：
%   y(k) = mean(gain_ratio_1 ... gain_ratio_k)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'vnf_sharing_gain_ratio_vs_success';
    metric.methods = repmat(struct( ...
        'name','', ...
        'x_success',[], ...
        'avg_gain_ratio',[], ...
        'gain_ratio_per_accept',[], ...
        'vnf_theory_per_accept',[], ...
        'vnf_actual_per_accept',[], ...
        'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        req_ids = [methods(m).requests.id].';
        maxReqId = max(req_ids);

        taskCount = collectTaskCountByReq(methods(m).nodes, maxReqId);

        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);
        A = numel(accepted_req_ids);

        gain_ratio = zeros(A,1);
        vnf_theory = zeros(A,1);
        vnf_actual = zeros(A,1);

        for k = 1:A
            rid = accepted_req_ids(k);
            idx = find(req_ids == rid, 1);
            req = methods(m).requests(idx);

            dest_num = numel(req.dest(req.dest > 0));
            vnf_num  = numel(req.vnf);

            vnf_theory(k) = dest_num * vnf_num;
            vnf_actual(k) = taskCount(rid);

            if vnf_theory(k) == 0
                gain_ratio(k) = 0;
            else
                gain_ratio(k) = (vnf_theory(k) - vnf_actual(k)) / vnf_theory(k);
            end
        end

        x = (1:A).';
        avg_gain = cumsum(gain_ratio) ./ x;

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).avg_gain_ratio = avg_gain;
        metric.methods(m).gain_ratio_per_accept = gain_ratio;
        metric.methods(m).vnf_theory_per_accept = vnf_theory;
        metric.methods(m).vnf_actual_per_accept = vnf_actual;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘图 =====================
    fig = figure('Visible', cfg.figVisible);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_gain_ratio, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均 VNF 共享增益比');
    title('VNF共享增益比随成功部署数量变化');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_VNFSharingGainRatio_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_VNFSharingGainRatio_vs_Success.mat'), 'metric');
    end

    close(fig);
end

```

---

