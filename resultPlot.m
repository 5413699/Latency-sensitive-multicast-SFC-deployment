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
% 关键：把 cfg 传入，使 cfg.methodDisplayNames 映射生效（图例名将变为 NIF-Greedy / STB / RDA / RSA）
methods = loadMethodResultsFromPaths(resultPaths, methodNames, cfg);

% -------------------- 4) 统一绘图与保存 --------------------
outDir = fullfile(currentDir, cfg.outDir);
allMetrics = runThesisResultPlots(methods, outDir, cfg); %[output:0fbb2529] %[output:670cf32b]

% 额外保存一次总览，便于论文表格或后续分析
save(fullfile(outDir, 'AllMetrics_ForPlots.mat'), 'allMetrics', 'methods', 'cfg', 'resultPaths');
fprintf('✓ 论文结果图与指标已输出到：%s\n', outDir); %[output:5bacc5f2]


%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":32}
%---
%[output:8b39b225]
%   data: {"dataType":"text","outputData":{"text":"找到以下方法的结果文件：\n","truncated":false}}
%---
%[output:213abc6f]
%   data: {"dataType":"text","outputData":{"text":"  1. ResourceAndDelayAwareOnline\n  2. nodeFirst\n  3. shortestPathFirstWithLoadBalancing\n  4. RSA\n","truncated":false}}
%---
%[output:0fbb2529]
%   data: {"dataType":"text","outputData":{"text":"数据已导出到: E:\\50-毕业资料-陈智飞\\02-实验代码\\c.输出\\5.结果图保存\\Data_CumulativeResourceConsume.xlsx\n累计资源消耗数据已导出到 Excel\n  失败分布数据已导出到: E:\\50-毕业资料-陈智飞\\02-实验代码\\c.输出\\5.结果图保存\\Data_FailureBreakdownDistribution.xlsx\n","truncated":false}}
%---
%[output:670cf32b]
%   data: {"dataType":"text","outputData":{"text":"正在导出指标数据到Excel...\n  √ 实验参数\n  √ 阻塞率曲线\n  √ 端到端时延曲线\n  √ 松弛比曲线\n  √ CPU消耗曲线\n  √ 内存消耗曲线\n  √ 带宽消耗曲线\n  √ VNF共享增益曲线\n  √ 综合汇总\n✓ 所有指标数据已导出到: E:\\50-毕业资料-陈智飞\\02-实验代码\\c.输出\\5.结果图保存\\AllMetrics_Data.xlsx\n","truncated":false}}
%---
%[output:5bacc5f2]
%   data: {"dataType":"text","outputData":{"text":"✓ 论文结果图与指标已输出到：E:\\50-毕业资料-陈智飞\\02-实验代码\\c.输出\\5.结果图保存\n","truncated":false}}
%---
