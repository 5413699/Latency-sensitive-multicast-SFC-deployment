function metric = plot_vnf_sharing_gain_ratio_vs_success(methods, outDir, cfg)
%PLOT_VNF_SHARING_GAIN_RATIO_VS_SUCCESS  VNF共享增益比随成功部署数量变化（多方法对比）
%
% 你给出的定义：
%   理论无共享（每个目的节点单独一条链）所需 VNF 数量：
%       vnf_theory = dest_num * vnf_num
%   实际部署的 VNF 实例数量：
%       vnf_actual = 该 req_id 在 nodes.tasks 中出现的次数
%   增益比：
%       gain_ratio = (vnf_theory - vnf_actual) / vnf_theory
%
% 输出曲线：
%   y(k) = mean(gain_ratio_1 ... gain_ratio_k)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'vnf_sharing_gain_ratio_vs_success';
    metric.methods = repmat(struct( ...
        'name','', ...
        'x_success',[], ...
        'avg_gain_ratio',[], ...
        'gain_ratio_per_accept',[], ...
        'vnf_theory_per_accept',[], ...
        'vnf_actual_per_accept',[], ...
        'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算 =====================
    for m = 1:numel(methods)
        req_ids = [methods(m).requests.id].';
        maxReqId = max(req_ids);

        taskCount = collectTaskCountByReq(methods(m).nodes, maxReqId);

        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);
        A = numel(accepted_req_ids);

        gain_ratio = zeros(A,1);
        vnf_theory = zeros(A,1);
        vnf_actual = zeros(A,1);

        for k = 1:A
            rid = accepted_req_ids(k);
            idx = find(req_ids == rid, 1);
            req = methods(m).requests(idx);

            dest_num = numel(req.dest(req.dest > 0));
            vnf_num  = numel(req.vnf);

            vnf_theory(k) = dest_num * vnf_num;
            vnf_actual(k) = taskCount(rid);

            if vnf_theory(k) == 0
                gain_ratio(k) = 0;
            else
                gain_ratio(k) = (vnf_theory(k) - vnf_actual(k)) / vnf_theory(k);
            end
        end

        x = (1:A).';
        avg_gain = cumsum(gain_ratio) ./ x;

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).avg_gain_ratio = avg_gain;
        metric.methods(m).gain_ratio_per_accept = gain_ratio;
        metric.methods(m).vnf_theory_per_accept = vnf_theory;
        metric.methods(m).vnf_actual_per_accept = vnf_actual;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘图 =====================
    [figW, figH] = calcFigureSize('single', {methods.name}, cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, figW, figH]);
    hold on;

    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).avg_gain_ratio, 'LineWidth', cfg.lineWidth);
    end

    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('平均 VNF 共享增益比');
    title('VNF共享增益比随成功部署数量变化');
    legend({methods.name}, 'Location', 'best');

    % ===================== 3) 保存 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_VNFSharingGainRatio_vs_Success.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_VNFSharingGainRatio_vs_Success.mat'), 'metric');
    end

    close(fig);
end
