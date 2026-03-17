%RUN_BATCH_EXPERIMENTS  批量实验主入口
%
% 用法：直接运行本脚本，或在命令行调用:
%   run_batch_experiments
%
% 流程：
%   1. 读取 a.输入/批量实验配置.xlsx
%   2. 展开全部实验组合
%   3. 逐个运行实验（支持断点续跑）
%   4. 结果写入 c.输出/实验结果汇总.xlsx
%   5. 聚合统计 -> c.输出/绘图数据.xlsx
%   6. 从绘图数据出图 -> c.输出/5.结果图保存/

clc;
fprintf('========================================\n');
fprintf('  MATLAB VNF 仿真平台 \n');
fprintf('========================================\n\n');

% ====== 0) 环境初始化 ======
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'a.输入')));
addpath(genpath(fullfile(currentDir, 'b.常用函数')));

% ====== 1) 读取配置 ======
xlsx_path = fullfile('a.输入', '批量实验配置.xlsx');
fprintf('[1/6] 读取配置: %s\n', xlsx_path);
cfg = load_config(xlsx_path);

% ====== 2) 展开实验组合 ======
fprintf('[2/6] 展开实验组合...\n');
cases = build_experiment_cases(cfg);
total = numel(cases);

if total == 0
    fprintf('没有需要运行的实验，退出。\n');
    return;
end

% ====== 3) 断点续跑：检查已完成的实验 ======
output_dir = cfg.global.output_dir;
summary_xlsx = fullfile(output_dir, cfg.global.summary_xlsx);
plot_data_xlsx = fullfile(output_dir, cfg.global.plot_data_xlsx);

completed_ids = {};
if isfile(summary_xlsx)
    try
        meta_tbl = readtable(summary_xlsx, 'Sheet', '实验元数据', 'TextType', 'string');
        success_mask = meta_tbl.status == "success";
        completed_ids = cellstr(meta_tbl.case_id(success_mask));
        fprintf('  发现 %d 个已完成实验（将跳过）\n', numel(completed_ids));
    catch
    end
end

% ====== 4) 逐个运行实验 ======
fprintf('[3/6] 开始运行实验 (共 %d 个)...\n', total);
topo_cache = struct();
success_count = 0;
skip_count = 0;
fail_count = 0;
total_timer = tic;

for i = 1:total
    c = cases(i);

    if ismember(c.case_id, completed_ids)
        skip_count = skip_count + 1;
        fprintf('  [%d/%d] 跳过已完成: %s\n', i, total, c.case_id);
        continue;
    end

    result = run_single_experiment(c, topo_cache);
    topo_cache = result.topo_cache;

    % 写入结果
    if strcmp(result.status, 'success')
        write_experiment_result(c, result.metrics, result.elapsed, result.status, summary_xlsx);
        success_count = success_count + 1;
    else
        empty_metrics = struct('summary', struct(), 'per_request', table(), 'fail_summary', struct());
        write_experiment_result(c, empty_metrics, result.elapsed, result.status, summary_xlsx);
        fail_count = fail_count + 1;
    end

    fprintf('  进度: %d/%d (成功=%d, 失败=%d, 跳过=%d)\n', ...
        i, total, success_count, fail_count, skip_count);
end

total_elapsed = toc(total_timer);
fprintf('\n[4/6] 全部实验完成！成功=%d, 失败=%d, 跳过=%d, 总耗时=%.1fs\n', ...
    success_count, fail_count, skip_count, total_elapsed);

% ====== 5) 聚合统计 ======
fprintf('[5/6] 计算绘图数据...\n');
try
    compute_plot_data(summary_xlsx, plot_data_xlsx);
    fprintf('  绘图数据已写入: %s\n', plot_data_xlsx);
catch ME
    fprintf('  计算绘图数据失败: %s\n', ME.message);
end

% ====== 6) 出图 ======
fprintf('[6/6] 生成图表...\n');
try
    plot_from_xlsx(plot_data_xlsx, cfg.global);
    fprintf('  图表生成完成\n');
catch ME
    fprintf('  绘图失败: %s\n', ME.message);
end

fprintf('\n========================================\n');
fprintf('  批量实验全部完成！\n');
fprintf('  结果文件: %s\n', summary_xlsx);
fprintf('  绘图数据: %s\n', plot_data_xlsx);
fprintf('========================================\n');
