function metric = plot_avg_bandwidth_consume_vs_success(methods, outDir, cfg)
%PLOT_AVG_BANDWIDTH_CONSUME_VS_SUCCESS  平均 Bandwidth 资源消耗随成功部署数量变化（多方法对比）
%
% 定义：
%   对每个成功请求：bw_i = consume(req_id).bandwidth_consume
%   曲线：y(k) = mean(bw_1 ... bw_k)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_bandwidth_consume_vs_success';
    metric.methods = repmat(struct('name','', 'x_success',[], 'avg_bw',[], 'bw_per_accept',[], 'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);

        A = numel(accepted_req_ids);
        bw = zeros(A,1);
        for k = 1:A
            rid = accepted_req_ids(k);
            bw(k) = methods(m).consume(rid).bandwidth_consume;
        end

        x = (1:A).';
        avg_bw = cumsum(bw) ./ x;

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).avg_bw = avg_bw;
        metric.methods(m).bw_per_accept = bw;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘图 =====================
    [figW, figH] = calcFigureSize('single', {methods.name}, cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, figW, figH]);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_bw, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均带宽消耗');
    title('平均带宽消耗');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AvgBandwidthConsume_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_AvgBandwidthConsume_vs_Success.mat'), 'metric');
    end

    close(fig);
end
