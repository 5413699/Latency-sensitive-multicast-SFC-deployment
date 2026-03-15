function metric = plot_blocking_rate_curve(methods, outDir, cfg)
%PLOT_BLOCKING_RATE_CURVE  请求阻塞率变化曲线（多方法对比）
%
% 定义：
%   阻塞率 = 1 - 接受率 = 累计拒绝数 / 累计请求数
%
% 输入：
%   methods : struct 数组，每个元素至少包含：
%             .name, .requests, .consume
%   outDir  : 输出目录（svg 与 mat 都会存这里）
%   cfg     : getPlotCfg() 返回的配置
%
% 输出：
%   metric : 用于画图的指标变量（也会被保存为 mat）

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'blocking_rate_curve';
    metric.methods = repmat(struct('name','', 'x',[], 'block_rate',[], 'acc_rate',[], 'cum_block',[], 'cum_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        req_ids = [methods(m).requests.id].';
        N = numel(req_ids);

        accepted = zeros(N,1);
        for i = 1:N
            rid = req_ids(i);
            accepted(i) = methods(m).consume(rid).accepted;
        end

        cumAccept = cumsum(accepted);
        cumBlock  = (1:N).' - cumAccept;  % 累计阻塞数 = 累计请求数 - 累计接受数
        accRate   = cumAccept ./ (1:N).';
        blockRate = 1 - accRate;          % 阻塞率 = 1 - 接受率

        metric.methods(m).name       = methods(m).name;
        metric.methods(m).x          = (1:N).';
        metric.methods(m).block_rate = blockRate;
        metric.methods(m).acc_rate   = accRate;
        metric.methods(m).cum_block  = cumBlock;
        metric.methods(m).cum_accept = cumAccept;
    end

    % ===================== 2) 绘图 =====================
    [figW, figH] = calcFigureSize('single', {methods.name}, cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, figW, figH]);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x, metric.methods(m).block_rate, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('请求序号（按部署顺序）');
    ylabel('累计阻塞率');
    title('请求阻塞率变化曲线');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_BlockingRate.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_BlockingRate.mat'), 'metric');
    end

    close(fig);
end
