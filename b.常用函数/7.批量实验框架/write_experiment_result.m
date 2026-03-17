function write_experiment_result(experiment_case, metrics, elapsed, status, xlsx_path)
%WRITE_EXPERIMENT_RESULT  追加写入实验结果到汇总 xlsx
%
%   write_experiment_result(experiment_case, metrics, elapsed, status)
%   write_experiment_result(experiment_case, metrics, elapsed, status, xlsx_path)

    if nargin < 5 || isempty(xlsx_path)
        output_dir = 'c.输出';
        if isfield(experiment_case, 'global_cfg') && isfield(experiment_case.global_cfg, 'output_dir')
            output_dir = experiment_case.global_cfg.output_dir;
        end
        xlsx_name = '实验结果汇总.xlsx';
        if isfield(experiment_case, 'global_cfg') && isfield(experiment_case.global_cfg, 'summary_xlsx')
            xlsx_name = experiment_case.global_cfg.summary_xlsx;
        end
        xlsx_path = fullfile(output_dir, xlsx_name);
    end

    ec = experiment_case;

    % ====== Sheet 1: 实验元数据 ======
    meta = table( ...
        string(ec.case_id), string(ec.group_id), string(ec.topo_name), ...
        string(ec.method_name), string(ec.display_name), string(ec.param_group), ...
        ec.request_set_id, ec.repeat_id, ec.seed, ...
        string(datetime('now')), elapsed, string(status), ...
        'VariableNames', {'case_id','group_id','topo_name','method_name', ...
        'display_name','param_group','request_set_id','repeat_id','seed', ...
        'run_timestamp','elapsed_seconds','status'});

    append_to_sheet(xlsx_path, '实验元数据', meta);

    % ====== Sheet 2: 汇总指标 ======
    s = metrics.summary;
    summary = table( ...
        string(ec.case_id), ...
        s.total_requests, s.accepted_count, s.rejected_count, s.acceptance_rate, ...
        s.avg_cpu, s.avg_memory, s.avg_bandwidth, s.avg_e2e_delay, s.avg_slack_ratio, ...
        s.total_cpu, s.total_memory, s.total_bandwidth, s.vnf_sharing_gain, ...
        s.fail_lack_bw, s.fail_lack_cpu, s.fail_lack_mem, s.fail_timeout, s.fail_unschedulable, ...
        'VariableNames', {'case_id', ...
        'total_requests','accepted_count','rejected_count','acceptance_rate', ...
        'avg_cpu','avg_memory','avg_bandwidth','avg_e2e_delay','avg_slack_ratio', ...
        'total_cpu','total_memory','total_bandwidth','vnf_sharing_gain', ...
        'fail_lack_bw','fail_lack_cpu','fail_lack_mem','fail_timeout','fail_unschedulable'});

    append_to_sheet(xlsx_path, '汇总指标', summary);

    % ====== Sheet 3: 请求级明细 ======
    pr = metrics.per_request;
    pr.case_id(:) = string(ec.case_id);
    append_to_sheet(xlsx_path, '请求级明细', pr);

    fprintf('  [结果] 已写入 %s\n', xlsx_path);
end

function append_to_sheet(xlsx_path, sheet_name, tbl)
    [p, ~, ~] = fileparts(xlsx_path);
    if ~isempty(p) && ~isfolder(p)
        mkdir(p);
    end

    if isfile(xlsx_path)
        try
            existing = readtable(xlsx_path, 'Sheet', sheet_name, 'TextType', 'string');
            tbl = [existing; tbl];
        catch
            % Sheet 不存在，直接写
        end
    end
    writetable(tbl, xlsx_path, 'Sheet', sheet_name);
end
