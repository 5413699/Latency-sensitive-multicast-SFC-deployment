function plot_acceptance_rate_bar(compare_tbl, outDir, cfg)
%PLOT_ACCEPTANCE_RATE_BAR  接受率柱状图（双模式）
%
%   plot_acceptance_rate_bar()                       -- 独立运行
%   plot_acceptance_rate_bar(compare_tbl, outDir, cfg)  -- 批量调用
%
% 从"方法对比汇总"数据中筛选 acceptance_rate 指标，绘制分组柱状图。

    if nargin < 1 || isempty(compare_tbl)
        plot_xlsx = fullfile('c.输出', '绘图数据.xlsx');
        compare_tbl = readtable(plot_xlsx, 'Sheet','方法对比汇总', 'TextType','string');
    end
    if nargin < 3 || isempty(cfg)
        try cfg = read_global_cfg(); catch; cfg = default_cfg(); end
    end
    if nargin < 2 || isempty(outDir)
        outDir = cfg.outDir;
    end
    ensure_dir(outDir);

    data = compare_tbl(compare_tbl.metric_name == "acceptance_rate", :);
    if isempty(data); warning('无 acceptance_rate 数据'); return; end

    method_names = unique(data.display_name, 'stable');
    M = numel(method_names);

    means = zeros(M, 1);
    errs  = zeros(M, 1);
    for i = 1:M
        row = data(data.display_name == method_names(i), :);
        if ~isempty(row)
            means(i) = row.mean(1);
            errs(i)  = row.std(1);
        end
    end

    [figW, figH] = calcFigureSize('bar', cellstr(method_names), cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100 100 figW figH]);

    b = bar(means);
    hold on;
    errorbar(1:M, means, errs, 'k', 'LineStyle','none', 'LineWidth',1.2);

    b.FaceColor = 'flat';
    colors = lines(M);
    for i = 1:M
        b.CData(i,:) = colors(i,:);
    end

    set(gca, 'FontSize', cfg.fontSize);
    xticks(1:M);
    xticklabels(cellstr(method_names));
    ylabel('接受率');
    title('请求接受率对比');
    grid on; box on;

    for i = 1:M
        text(i, means(i) + errs(i) + 0.01, sprintf('%.3f', means(i)), ...
            'HorizontalAlignment','center', 'FontSize', cfg.fontSize - 1);
    end

    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AcceptanceRate_Bar.svg'), cfg.svgBackground);
    end
    close(fig);
end

function cfg = default_cfg()
    cfg = struct('figVisible','off','lineWidth',1.8,'fontSize',12, ...
                 'saveSvg',true,'svgBackground','none','slackMode','ratio', ...
                 'outDir',fullfile('c.输出','5.结果图保存'),'saveMat',false);
end
