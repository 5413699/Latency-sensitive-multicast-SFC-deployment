function metric = plot_avg_e2e_delay_vs_success(methods, outDir, cfg)
%PLOT_AVG_E2E_DELAY_VS_SUCCESS  平均端到端时延 vs 已成功部署SFC数量（多方法对比）
%
% 端到端时延计算：
%   e2e_delay = max(branch_end_time) - 1
%   其中 branch_end_time(dest_idx) 是"该请求第 dest 个分支最后一个 VNF 完成的时间"。
%   deploy_requests 在成功部署时会自动记录 requests.e2e_delay 和 requests.branch_end_time。
%
% 输入：
%   methods : struct 数组，每个元素至少包含：
%             .name, .nodes, .requests, .consume
%   outDir  : 输出目录
%   cfg     : 配置（getPlotCfg）

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'avg_e2e_delay_vs_success';
    metric.methods = repmat(struct( ...
        'name','', ...
        'x_success',[], ...
        'avg_e2e_delay',[], ...
        'e2e_delay_per_accept',[], ...
        'req_id_per_accept',[], ...
        'e2e_source',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        [req_ids, acceptedFlag, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);
        A = numel(accepted_req_ids);

        e2e_delay = NaN(A,1);
        srcTag    = strings(A,1);

        % 逐“成功请求”计算 e2e_delay
        for k = 1:A
            rid = accepted_req_ids(k);
            % 在 requests 中找到该 rid 对应的 req 结构
            idx = find(req_ids == rid, 1);
            req = methods(m).requests(idx);

            [e2e_delay(k), srcTag(k)] = getE2EDelayForRequest(methods(m).nodes, req, rid);
        end

        % 过滤掉 NaN（无法计算的点）
        valid = ~isnan(e2e_delay);
        e2e_delay_valid = e2e_delay(valid);
        srcTag_valid    = srcTag(valid);
        req_valid       = accepted_req_ids(valid);

        x = (1:numel(e2e_delay_valid)).';
        avg_delay = cumsum(e2e_delay_valid) ./ x;

        metric.methods(m).name               = methods(m).name;
        metric.methods(m).x_success          = x;
        metric.methods(m).avg_e2e_delay      = avg_delay;
        metric.methods(m).e2e_delay_per_accept = e2e_delay_valid;
        metric.methods(m).req_id_per_accept    = req_valid;
        metric.methods(m).e2e_source           = srcTag_valid;
    end

    % ===================== 2) 绘图 =====================
    [figW, figH] = calcFigureSize('single', {methods.name}, cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, figW, figH]);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_e2e_delay, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均端到端时延');
    title('平均端到端时延随成功部署数量变化');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_AvgE2EDelay_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_AvgE2EDelay_vs_Success.mat'), 'metric');
    end

    close(fig);
end
