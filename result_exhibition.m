%% 论文图表绘制主入口
% 所有绘图函数位于 d.论文图表绘制/ 目录。
% 本脚本仅负责：加载论文数据 → 调用绘图函数。
% ======== 0. 环境初始化 ========
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'd.论文图表绘制')));

% ---- 保存 ----
xlsxPath = fullfile(currentDir, 'd.论文图表绘制', '论文数据.xlsx');
savePath = fullfile(currentDir, 'c.输出', '6.论文图');

%% 1.1 方法对比实验 - 阻塞率 vs 服务到达率
% Sheet: "1.1 方法对比实验阻塞率"
% 列: Arrival Ratio | RDA | NIF | STB | RSA
data11 = readtable(xlsxPath, 'Sheet', '1.1 方法对比实验阻塞率', ...
    'VariableNamingRule', 'preserve');
plot_method_blocking(data11, savePath);

%% 1.2.1 方法对比实验 - CPU 利用率 vs 服务到达率
data121 = readtable(xlsxPath, 'Sheet', '1.2.1 方法对比实验CPU利用率', ...
    'VariableNamingRule', 'preserve');
plot_method_cpu_util(data121, savePath);

%% 1.2.2 方法对比实验 - 内存利用率 vs 服务到达率
data122 = readtable(xlsxPath, 'Sheet', '1.2.2 方法对比实验内存利用率', ...
    'VariableNamingRule', 'preserve');
plot_method_mem_util(data122, savePath);

%% 1.2.3 方法对比实验 - 带宽利用率 vs 服务到达率
data123 = readtable(xlsxPath, 'Sheet', '1.2.3 方法对比实验带宽利用率', ...
    'VariableNamingRule', 'preserve');
plot_method_bw_util(data123, savePath);

%% 2.1 共享权重消融实验 - 阻塞率 vs 服务到达率
% Sheet: "2.1共享权重消融实验阻塞率"
% 列: Arrival Ratio | With share weighting | Without share weighting
data21 = readtable(xlsxPath, 'Sheet', '2.1共享权重消融实验阻塞率', ...
    'VariableNamingRule', 'preserve');
plot_share_weight_blocking(data21, savePath);

%% 3.1 时延权重消融实验 - 阻塞率 vs 服务到达率
% Sheet: "3.1时延权重消融实验阻塞率"
% 列: Arrival Ratio | With delay weighting | Without delay weighting
data31 = readtable(xlsxPath, 'Sheet', '3.1时延权重消融实验阻塞率', ...
    'VariableNamingRule', 'preserve');
plot_delay_weight_blocking(data31, savePath);