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
deployMethodName = 'ResourceAndDelayAwareOnline';
% deployMethodName = 'nodeFirst'; 
% deployMethodName = 'shortestPathFirstWithLoadBalancing'; 
% deployMethodName = 'RSA'; 

%[text] ## 3) 加载配置
topocfg = getTopoCfg(topoName);
reqCfg = getReqCfg(topoName);
deployMethodCfg = getDeployMethodCfg(deployMethodName,topoName);

% 确保结果目录存在（避免首次运行 RSA 等新方法时 save 报错）
ensure_parent_dir(deployMethodCfg.resultPath);

%[text] ## 4）根据模式进行映射
if isfield(deployMethodCfg, 'onlineMode') && deployMethodCfg.onlineMode %[output:group:3738a4a0]
    %% ========== 在线模式：部署已完成，直接加载结果 ==========
    fprintf('检测到在线模式: %s\n', deployMethodName); %[output:2c4f6933]
    fprintf('在线模式已在 deployAndDispatchPlan.m 中完成部署。\n'); %[output:533e3d23]
    
    % 检查结果文件是否存在
    if isfile(deployMethodCfg.resultPath)
        fprintf('正在加载已有结果: %s\n', deployMethodCfg.resultPath); %[output:23ba8fdf]
        load(deployMethodCfg.resultPath);
        fprintf('✓ 已加载在线模式结果\n'); %[output:55c7b29a]
        
        % 显示部署统计
        if exist('deployStats', 'var')
            fprintf('======== 部署统计 ========\n'); %[output:151b2ce9]
            fprintf('总请求数: %d\n', deployStats.total_requests); %[output:5565ee92]
            fprintf('接受请求: %d (%.1f%%)\n', deployStats.accepted_requests, ... %[output:35c589f3]
                    100*deployStats.accepted_requests/deployStats.total_requests); %[output:35c589f3]
            fprintf('拒绝请求: %d (%.1f%%)\n', deployStats.rejected_requests, ... %[output:569cc69d]
                    100*deployStats.rejected_requests/deployStats.total_requests); %[output:569cc69d]
        end
    else
        error('在线模式结果文件不存在: %s\n请先运行 deployAndDispatchPlan.m', deployMethodCfg.resultPath);
    end
else
    %% ========== 离线模式：执行传统的SFC映射 ==========
    fprintf('使用离线模式: %s\n', deployMethodName);
    
    load(topocfg.topoInfoPath);     % 得到 nodes / links / KPaths
    load(reqCfg.requestPath);       % 得到原始请求集合
    load(reqCfg.sortedRequestsPath);% 得到按最大可容忍时延排序好的请求集合
    load(deployMethodCfg.sortedPlanPath);% 得到最终的部署计划,初始化的consume, fail_log
    
    requests = eval(deployMethodCfg.requestsType);
    [nodes, links, requests, consume, fail_log] = deploy_requests( ...
        nodes, links, requests, sortedPlan, consume, fail_log);

    save(deployMethodCfg.resultPath,'nodes', 'links', 'requests', 'consume', 'fail_log'); 
    fprintf('✓ 离线模式结果已保存: %s\n', deployMethodCfg.resultPath);
end %[output:group:3738a4a0]

fprintf('✓ 完成（时间：%s）\n', string(datetime("now"))); %[output:4a6ead27]

function ensure_parent_dir(filePath)
%ENSURE_PARENT_DIR Ensure parent folder for a file path exists.
    if nargin < 1 || isempty(filePath)
        return;
    end
    [p, ~, ~] = fileparts(filePath);
    if ~isempty(p) && ~isfolder(p)
        mkdir(p);
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":33}
%---
%[output:2c4f6933]
%   data: {"dataType":"text","outputData":{"text":"检测到在线模式: ResourceAndDelayAwareOnline\n","truncated":false}}
%---
%[output:533e3d23]
%   data: {"dataType":"text","outputData":{"text":"在线模式已在 deployAndDispatchPlan.m 中完成部署。\n","truncated":false}}
%---
%[output:23ba8fdf]
%   data: {"dataType":"text","outputData":{"text":"正在加载已有结果: c.输出\\4.资源消耗与失败日志\\9.在线资源与时延感知算法\\US_Backbone\\ResourceAndDelayAwareOnlineResult.mat\n","truncated":false}}
%---
%[output:55c7b29a]
%   data: {"dataType":"text","outputData":{"text":"✓ 已加载在线模式结果\n","truncated":false}}
%---
%[output:151b2ce9]
%   data: {"dataType":"text","outputData":{"text":"======== 部署统计 ========\n","truncated":false}}
%---
%[output:5565ee92]
%   data: {"dataType":"text","outputData":{"text":"总请求数: 100\n","truncated":false}}
%---
%[output:35c589f3]
%   data: {"dataType":"text","outputData":{"text":"接受请求: 96 (96.0%)\n","truncated":false}}
%---
%[output:569cc69d]
%   data: {"dataType":"text","outputData":{"text":"拒绝请求: 4 (4.0%)\n","truncated":false}}
%---
%[output:4a6ead27]
%   data: {"dataType":"text","outputData":{"text":"✓ 完成（时间：2026-01-21 17:46:54）\n","truncated":false}}
%---
