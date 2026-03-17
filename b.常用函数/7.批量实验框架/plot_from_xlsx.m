function plot_from_xlsx(plot_xlsx, cfg)
%PLOT_FROM_XLSX  主绘图入口：从绘图数据 xlsx 一键生成全部图表
%
%   plot_from_xlsx()
%   plot_from_xlsx(plot_xlsx)
%   plot_from_xlsx(plot_xlsx, cfg)

    if nargin < 1 || isempty(plot_xlsx)
        plot_xlsx = fullfile('c.输出', '绘图数据.xlsx');
    end

    if nargin < 2 || isempty(cfg)
        try
            cfg = read_global_cfg();
        catch
            cfg = struct('figVisible','off','lineWidth',1.8,'fontSize',12, ...
                         'saveSvg',true,'svgBackground','none','slackMode','ratio', ...
                         'outDir',fullfile('c.输出','5.结果图保存'),'saveMat',false);
        end
    end

    cfg = normalize_plot_cfg(cfg);

    if ~isfile(plot_xlsx)
        error('绘图数据文件不存在: %s\n请先运行 compute_plot_data', plot_xlsx);
    end

    outDir = cfg.outDir;
    ensure_dir(outDir);

    opts = {'TextType','string'};
    compare_tbl = readtable(plot_xlsx, 'Sheet','方法对比汇总', opts{:});
    curve_tbl   = readtable(plot_xlsx, 'Sheet','逐请求曲线',   opts{:});
    fail_tbl    = readtable(plot_xlsx, 'Sheet','失败分布',     opts{:});

    fprintf('\n========== 开始绘图 ==========\n');

    fprintf('[1/7] 接受率柱状图...\n');
    plot_acceptance_rate_bar(compare_tbl, outDir, cfg);

    fprintf('[2/7] 平均资源消耗曲线...\n');
    metric_list = {'avg_cpu','avg_mem','avg_bw','avg_delay','avg_slack'};
    label_list  = {'平均CPU资源消耗','平均内存资源消耗','平均带宽消耗', ...
                   '平均端到端时延','平均裕量比例'};
    for i = 1:numel(metric_list)
        plot_avg_metric_vs_success(curve_tbl, metric_list{i}, label_list{i}, outDir, cfg);
    end

    fprintf('[3/7] 阻塞率曲线...\n');
    plot_blocking_rate_curve(curve_tbl, outDir, cfg);

    fprintf('[4/7] 累计资源消耗...\n');
    plot_cumulative_resource(curve_tbl, outDir, cfg);

    fprintf('[5/7] 失败分布...\n');
    plot_failure_distribution(fail_tbl, outDir, cfg);

    fprintf('[6/7] VNF共享增益...\n');
    plot_vnf_sharing_gain(curve_tbl, outDir, cfg);

    fprintf('[7/7] 甘特图跳过（需运行时 nodes 数据）\n');

    fprintf('========== 全部绘图完成 ==========\n');
    fprintf('输出目录: %s\n', outDir);
end

function cfg = normalize_plot_cfg(cfg)
    if ~isfield(cfg, 'figVisible')
        if isfield(cfg, 'fig_visible')
            cfg.figVisible = cfg.fig_visible;
        else
            cfg.figVisible = 'off';
        end
    end

    if ~isfield(cfg, 'lineWidth')
        if isfield(cfg, 'line_width')
            cfg.lineWidth = cfg.line_width;
        else
            cfg.lineWidth = 1.8;
        end
    end

    if ~isfield(cfg, 'fontSize')
        if isfield(cfg, 'font_size')
            cfg.fontSize = cfg.font_size;
        else
            cfg.fontSize = 12;
        end
    end

    if ~isfield(cfg, 'figWidth')
        if isfield(cfg, 'fig_width')
            cfg.figWidth = cfg.fig_width;
        else
            cfg.figWidth = 800;
        end
    end

    if ~isfield(cfg, 'figHeight')
        if isfield(cfg, 'fig_height')
            cfg.figHeight = cfg.fig_height;
        else
            cfg.figHeight = 600;
        end
    end

    if ~isfield(cfg, 'saveSvg')
        if isfield(cfg, 'save_svg')
            cfg.saveSvg = logical(cfg.save_svg);
        else
            cfg.saveSvg = true;
        end
    end

    if ~isfield(cfg, 'svgBackground')
        if isfield(cfg, 'svg_background')
            cfg.svgBackground = cfg.svg_background;
        else
            cfg.svgBackground = 'none';
        end
    end

    if ~isfield(cfg, 'slackMode')
        if isfield(cfg, 'slack_mode')
            cfg.slackMode = cfg.slack_mode;
        else
            cfg.slackMode = 'ratio';
        end
    end

    if ~isfield(cfg, 'output_dir')
        cfg.output_dir = 'c.输出';
    end

    if ~isfield(cfg, 'outDir')
        cfg.outDir = fullfile(cfg.output_dir, '5.结果图保存');
    end

    if ~isfield(cfg, 'saveMat')
        if isfield(cfg, 'save_mat')
            cfg.saveMat = logical(cfg.save_mat);
        else
            cfg.saveMat = false;
        end
    end
end
