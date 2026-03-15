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
    [figW, figH] = calcFigureSize('bar', {methods.name}, cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, figW, figH]);

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
