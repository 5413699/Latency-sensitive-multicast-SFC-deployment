function plot_avg_metric_vs_success(curve_tbl, metric_field, y_label, outDir, cfg)
%PLOT_AVG_METRIC_VS_SUCCESS  平均指标随成功部署数量变化（统一模板）
%
%   plot_avg_metric_vs_success()                                              -- 独立运行（默认 avg_cpu）
%   plot_avg_metric_vs_success(curve_tbl, 'avg_cpu', '平均CPU消耗', outDir, cfg) -- 批量调用
%
% metric_field 支持: avg_cpu, avg_mem, avg_bw, avg_delay, avg_slack

    if nargin < 1 || isempty(curve_tbl)
        plot_xlsx = fullfile('c.输出', '绘图数据.xlsx');
        curve_tbl = readtable(plot_xlsx, 'Sheet','逐请求曲线', 'TextType','string');
    end
    if nargin < 2 || isempty(metric_field)
        metric_field = 'avg_cpu';
    end
    if nargin < 3 || isempty(y_label)
        label_map = containers.Map( ...
            {'avg_cpu','avg_mem','avg_bw','avg_delay','avg_slack'}, ...
            {'平均CPU资源消耗','平均内存资源消耗','平均带宽消耗','平均端到端时延','平均裕量比例'});
        if label_map.isKey(metric_field)
            y_label = label_map(metric_field);
        else
            y_label = metric_field;
        end
    end
    if nargin < 5 || isempty(cfg)
        try cfg = read_global_cfg(); catch; cfg = default_cfg(); end
    end
    if nargin < 4 || isempty(outDir)
        outDir = cfg.outDir;
    end
    ensure_dir(outDir);

    mean_col = [metric_field '_mean'];
    std_col  = [metric_field '_std'];

    if ~ismember(mean_col, curve_tbl.Properties.VariableNames)
        warning('逐请求曲线中未找到 %s 列', mean_col);
        return;
    end

    method_names = unique(curve_tbl.display_name, 'stable');
    M = numel(method_names);

    [figW, figH] = calcFigureSize('single', cellstr(method_names), cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100 100 figW figH]);
    hold on;

    for m = 1:M
        mask = curve_tbl.display_name == method_names(m);
        grp  = curve_tbl(mask, :);
        x    = grp.success_index;
        y    = grp.(mean_col);
        plot(x, y, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel(y_label);
    title(y_label);
    legend(cellstr(method_names), 'Location', 'best');

    fig_name = sprintf('Fig_%s_vs_Success.svg', metric_field);
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, fig_name), cfg.svgBackground);
    end
    close(fig);
end

function cfg = default_cfg()
    cfg = struct('figVisible','off','lineWidth',1.8,'fontSize',12, ...
                 'saveSvg',true,'svgBackground','none','slackMode','ratio', ...
                 'outDir',fullfile('c.输出','5.结果图保存'),'saveMat',false);
end
