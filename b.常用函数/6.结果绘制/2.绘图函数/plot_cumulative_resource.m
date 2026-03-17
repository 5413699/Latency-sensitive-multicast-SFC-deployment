function plot_cumulative_resource(curve_tbl, outDir, cfg)
%PLOT_CUMULATIVE_RESOURCE  累计资源消耗（CPU/内存/带宽 三子图，双模式）
%
%   plot_cumulative_resource()                           -- 独立运行
%   plot_cumulative_resource(curve_tbl, outDir, cfg)     -- 批量调用

    if nargin < 1 || isempty(curve_tbl)
        plot_xlsx = fullfile('c.输出', '绘图数据.xlsx');
        curve_tbl = readtable(plot_xlsx, 'Sheet','逐请求曲线', 'TextType','string');
    end
    if nargin < 3 || isempty(cfg)
        try cfg = read_global_cfg(); catch; cfg = default_cfg(); end
    end
    if nargin < 2 || isempty(outDir)
        outDir = cfg.outDir;
    end
    ensure_dir(outDir);

    fields = {'cum_cpu_mean','cum_mem_mean','cum_bw_mean'};
    titles = {'累计 CPU 消耗','累计内存消耗','累计带宽消耗'};

    for f = 1:numel(fields)
        if ~ismember(fields{f}, curve_tbl.Properties.VariableNames)
            warning('逐请求曲线中未找到 %s 列', fields{f}); return;
        end
    end

    method_names = unique(curve_tbl.display_name, 'stable');
    M = numel(method_names);

    [figW, figH] = calcFigureSize('subplot3', cellstr(method_names), cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100 100 figW figH]);
    colors = lines(M);

    for sp = 1:3
        subplot(1, 3, sp);
        hold on;
        for m = 1:M
            mask = curve_tbl.display_name == method_names(m);
            grp  = curve_tbl(mask, :);
            plot(grp.success_index, grp.(fields{sp}), ...
                 'LineWidth', cfg.lineWidth, 'Color', colors(m,:));
        end
        grid on;
        set(gca, 'FontSize', cfg.fontSize);
        xlabel('已成功部署的 SFC 数量');
        ylabel(titles{sp});
        title(titles{sp});
        legend(cellstr(method_names), 'Location', 'northwest');
    end

    sgtitle('累计资源消耗随成功部署数量变化', 'FontSize', cfg.fontSize + 2);

    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_CumulativeResourceConsume.svg'), cfg.svgBackground);
    end
    close(fig);
end

function cfg = default_cfg()
    cfg = struct('figVisible','off','lineWidth',1.8,'fontSize',12, ...
                 'saveSvg',true,'svgBackground','none','slackMode','ratio', ...
                 'outDir',fullfile('c.输出','5.结果图保存'),'saveMat',false);
end
