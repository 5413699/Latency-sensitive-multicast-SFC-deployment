function plot_vnf_sharing_gain(curve_tbl, outDir, cfg)
%PLOT_VNF_SHARING_GAIN  VNF共享增益比随成功部署数量变化（双模式）
%
%   plot_vnf_sharing_gain()                              -- 独立运行
%   plot_vnf_sharing_gain(curve_tbl, outDir, cfg)        -- 批量调用

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

    if ~ismember('vnf_gain_mean', curve_tbl.Properties.VariableNames)
        warning('逐请求曲线中未找到 vnf_gain_mean 列'); return;
    end

    method_names = unique(curve_tbl.display_name, 'stable');
    M = numel(method_names);

    [figW, figH] = calcFigureSize('single', cellstr(method_names), cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100 100 figW figH]);
    hold on;

    for m = 1:M
        mask = curve_tbl.display_name == method_names(m);
        grp  = curve_tbl(mask, :);
        plot(grp.success_index, grp.vnf_gain_mean, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均 VNF 共享增益比');
    title('VNF共享增益比随成功部署数量变化');
    legend(cellstr(method_names), 'Location', 'best');

    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_VNFSharingGain_vs_Success.svg'), cfg.svgBackground);
    end
    close(fig);
end

function cfg = default_cfg()
    cfg = struct('figVisible','off','lineWidth',1.8,'fontSize',12, ...
                 'saveSvg',true,'svgBackground','none','slackMode','ratio', ...
                 'outDir',fullfile('c.输出','5.结果图保存'),'saveMat',false);
end
