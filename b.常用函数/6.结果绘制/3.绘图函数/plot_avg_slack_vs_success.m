function metric = plot_avg_slack_vs_success(methods, outDir, cfg)
%PLOT_AVG_SLACK_VS_SUCCESS  平均时延满足度“裕量”随成功部署数量变化（多方法对比）
%
% 定义：
%   对每个成功请求：
%     e2e_delay = 端到端时延（推荐来自 requests.e2e_delay 或 branch_end_time）
%     slack_abs = max_delay - e2e_delay
%     slack_ratio = (max_delay - e2e_delay) / max_delay
%
% 作图：
%   cfg.slackMode = 'ratio' : y 轴画 slack_ratio 的累计平均
%   cfg.slackMode = 'abs'   : y 轴画 slack_abs 的累计平均

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_slack_vs_success';
    metric.slackMode   = cfg.slackMode;
    metric.methods = repmat(struct( ...
        'name','', ...
        'x_success',[], ...
        'avg_slack',[], ...
        'slack_abs_per_accept',[], ...
        'slack_ratio_per_accept',[], ...
        'req_id_per_accept',[], ...
        'e2e_source',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [req_ids, acceptedFlag, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);
        A = numel(accepted_req_ids);

        slack_abs   = NaN(A,1);
        slack_ratio = NaN(A,1);
        srcTag      = strings(A,1);

        for k = 1:A
            rid = accepted_req_ids(k);
            idx = find(req_ids == rid, 1);
            req = methods(m).requests(idx);

            [e2e_delay, srcTag(k)] = getE2EDelayForRequest(methods(m).nodes, req, rid);

            if isnan(e2e_delay) || ~isfield(req, 'max_delay') || isempty(req.max_delay)
                slack_abs(k)   = NaN;
                slack_ratio(k) = NaN;
            else
                slack_abs(k) = req.max_delay - e2e_delay;
                slack_ratio(k) = (req.max_delay - e2e_delay) / req.max_delay;
            end
        end

        % 过滤 NaN
        valid = ~isnan(slack_ratio);
        slack_abs_v   = slack_abs(valid);
        slack_ratio_v = slack_ratio(valid);
        srcTag_v      = srcTag(valid);
        req_v         = accepted_req_ids(valid);

        x = (1:numel(req_v)).';

        if strcmpi(cfg.slackMode, 'abs')
            y = cumsum(slack_abs_v) ./ x;
        else
            y = cumsum(slack_ratio_v) ./ x;
        end

        metric.methods(m).name                 = methods(m).name;
        metric.methods(m).x_success            = x;
        metric.methods(m).avg_slack            = y;
        metric.methods(m).slack_abs_per_accept   = slack_abs_v;
        metric.methods(m).slack_ratio_per_accept = slack_ratio_v;
        metric.methods(m).req_id_per_accept      = req_v;
        metric.methods(m).e2e_source             = srcTag_v;
    end

    % ===================== 2) 绘图 =====================
    [figW, figH] = calcFigureSize('single', {methods.name}, cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, figW, figH]);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_slack, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');

    if strcmpi(cfg.slackMode, 'abs')
        ylabel('平均裕量时延');
        title('平均裕量时延随成功部署数量变化');
        figName = 'Fig_AvgSlackAbs_vs_Success.svg';
        matName = 'Metric_AvgSlackAbs_vs_Success.mat';
    else
        ylabel('平均裕量比例');
        title('平均裕量比例随成功部署数量变化');
        figName = 'Fig_AvgSlackRatio_vs_Success.svg';
        matName = 'Metric_AvgSlackRatio_vs_Success.mat';
    end

    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, figName), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, matName), 'metric');
    end

    close(fig);
end
