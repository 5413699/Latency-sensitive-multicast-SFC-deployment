function result = run_single_experiment(experiment_case, topo_cache)
%RUN_SINGLE_EXPERIMENT  运行单次实验
%
%   result = run_single_experiment(experiment_case)
%   result = run_single_experiment(experiment_case, topo_cache)
%
% 输入：
%   experiment_case -- build_experiment_cases 生成的单个 case struct
%   topo_cache      -- 拓扑缓存 struct（可选）
%
% 输出：
%   result -- struct:
%     .metrics     -- collect_experiment_metrics 返回的指标
%     .topo_cache  -- 更新后的拓扑缓存
%     .elapsed     -- 耗时(秒)
%     .status      -- 'success' 或 'error'
%     .error_msg   -- 错误信息（成功时为空）

    if nargin < 2 || isempty(topo_cache)
        topo_cache = struct();
    end

    result = struct();
    result.topo_cache = topo_cache;
    result.status = 'error';
    result.error_msg = '';

    t_start = tic;

    try
        ec = experiment_case;
        fprintf('\n======== 实验 %s ========\n', ec.case_id);
        fprintf('  拓扑=%s, 方法=%s(%s), 参数组=%s, 请求集=%d, 重复=%d\n', ...
            ec.topo_name, ec.display_name, ec.method_name, ...
            ec.param_group, ec.request_set_id, ec.repeat_id);

        % 1) 准备拓扑
        [topo_data, topo_cache] = prepare_topo(ec.topo_cfg, topo_cache);

        % 2) 准备请求
        [requests, sortedRequests] = prepare_requests( ...
            ec.req_cfg, ec.topo_name, ec.request_set_id, ...
            topo_data.nodes, ec.seed);

        % 3) 执行部署流水线（深拷贝 nodes/links 避免污染缓存）
        nodes_copy = topo_data.nodes;
        links_copy = topo_data.links;

        [nodes_out, links_out, requests_out, consume, fail_log] = ...
            execute_deploy_pipeline( ...
                requests, sortedRequests, ...
                nodes_copy, links_copy, topo_data.KPathsNew, ...
                ec.method_cfg);

        % 4) 收集指标
        metrics = collect_experiment_metrics(requests_out, nodes_out, consume, fail_log);

        result.metrics = metrics;
        result.topo_cache = topo_cache;
        result.elapsed = toc(t_start);
        result.status = 'success';

        fprintf('  实验完成: 接受率=%.1f%%, 耗时=%.1fs\n', ...
            metrics.summary.acceptance_rate * 100, result.elapsed);

    catch ME
        result.elapsed = toc(t_start);
        result.error_msg = sprintf('%s: %s', ME.identifier, ME.message);
        fprintf('  实验失败: %s\n', result.error_msg);
    end
end
