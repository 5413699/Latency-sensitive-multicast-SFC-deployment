function plot_failure_distribution(fail_tbl, outDir, cfg)
%PLOT_FAILURE_DISTRIBUTION  失败原因分布分组柱状图（双模式）
%
%   plot_failure_distribution()                          -- 独立运行
%   plot_failure_distribution(fail_tbl, outDir, cfg)     -- 批量调用
%
% 从"失败分布"数据中按方法、失败类型绘制分组柱状图。

    if nargin < 1 || isempty(fail_tbl)
        plot_xlsx = fullfile('c.输出', '绘图数据.xlsx');
        fail_tbl = readtable(plot_xlsx, 'Sheet','失败分布', 'TextType','string');
    end
    if nargin < 3 || isempty(cfg)
        try cfg = read_global_cfg(); catch; cfg = default_cfg(); end
    end
    if nargin < 2 || isempty(outDir)
        outDir = cfg.outDir;
    end
    ensure_dir(outDir);

    if isempty(fail_tbl); warning('无失败分布数据'); return; end

    method_names = unique(fail_tbl.display_name, 'stable');
    fail_types   = unique(fail_tbl.fail_type, 'stable');
    M = numel(method_names);
    R = numel(fail_types);

    type_labels_cn = containers.Map( ...
        {'lack_bw','lack_cpu','lack_mem','timeout','unschedulable'}, ...
        {'链路资源不足','CPU不足','内存不足','超时','不可调度'});

    countMat = zeros(M, R);
    for m = 1:M
        for r = 1:R
            mask = fail_tbl.display_name == method_names(m) & ...
                   fail_tbl.fail_type == fail_types(r);
            rows = fail_tbl(mask, :);
            if ~isempty(rows)
                countMat(m, r) = rows.count_mean(1);
            end
        end
    end

    reason_labels = cell(R, 1);
    for r = 1:R
        ft = char(fail_types(r));
        if type_labels_cn.isKey(ft)
            reason_labels{r} = type_labels_cn(ft);
        else
            reason_labels{r} = ft;
        end
    end

    [figW, figH] = calcFigureSize('bar', cellstr(method_names), cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100 100 figW figH]);

    dataForBar = countMat.';
    b = bar(dataForBar, 'grouped');

    preset_colors = [
        0.3020 0.6863 0.2902;
        0.9961 0.4980 0.0549;
        0.8510 0.3255 0.3098;
        0.4000 0.7608 0.6471;
        0.5529 0.6275 0.7961;
    ];
    for k = 1:min(M, size(preset_colors, 1))
        b(k).FaceColor = preset_colors(k, :);
    end

    for k = 1:M
        xtips = b(k).XEndPoints;
        ytips = b(k).YEndPoints;
        labels = string(round(b(k).YData, 1));
        text(xtips, ytips, labels, 'HorizontalAlignment','center', ...
            'VerticalAlignment','bottom', 'FontSize', 10);
    end

    set(gca, 'FontSize', cfg.fontSize);
    xticks(1:R);
    xticklabels(reason_labels);
    ylabel('失败次数', 'FontSize', cfg.fontSize);
    xlabel('失败原因', 'FontSize', cfg.fontSize);
    title('失败原因分布', 'FontSize', cfg.fontSize + 2);
    legend(cellstr(method_names), 'Location','northeast', 'FontSize', cfg.fontSize - 1);
    grid on; box on;

    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_FailureDistribution.svg'), cfg.svgBackground);
    end
    close(fig);
end

function cfg = default_cfg()
    cfg = struct('figVisible','off','lineWidth',1.8,'fontSize',12, ...
                 'saveSvg',true,'svgBackground','none','slackMode','ratio', ...
                 'outDir',fullfile('c.输出','5.结果图保存'),'saveMat',false);
end
