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

    tc = NaN;
    tm = NaN;
    tbw = NaN;
    if isfield(ec, 'topo_total_cpu_cap')
        tc = ec.topo_total_cpu_cap;
    end
    if isfield(ec, 'topo_total_mem_cap')
        tm = ec.topo_total_mem_cap;
    end
    if isfield(ec, 'topo_total_link_bw_cap')
        tbw = ec.topo_total_link_bw_cap;
    end

    % ====== Sheet 1: 实验元数据 ======
    meta = table( ...
        string(ec.case_id), string(ec.group_id), string(ec.topo_name), ...
        tc, tm, tbw, ...
        string(ec.method_name), string(ec.display_name), string(ec.param_group), ...
        ec.request_set_id, ec.repeat_id, ec.seed, ...
        string(datetime('now')), elapsed, string(status), ...
        'VariableNames', {'case_id','group_id','topo_name', ...
        'topo_total_cpu_cap','topo_total_mem_cap','topo_total_link_bw_cap', ...
        'method_name','display_name','param_group','request_set_id','repeat_id','seed', ...
        'run_timestamp','elapsed_seconds','status'});

    append_to_sheet(xlsx_path, '实验元数据', meta);

    % ====== Sheet 2: 汇总指标 ======
    s = ensure_summary_struct(metrics, ec, status);
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
    pr = ensure_per_request_table(metrics);
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
            [existing, tbl] = align_tables_for_vertcat(existing, tbl);
            tbl = [existing; tbl];
        catch
            % Sheet 不存在，直接写
        end
    end
    writetable(tbl, xlsx_path, 'Sheet', sheet_name);
end

function [A, B] = align_tables_for_vertcat(A, B)
%ALIGN_TABLES_FOR_VERTCAT  统一列名与顺序，便于与旧版汇总表追加合并
    if width(A) == 0 || width(B) == 0
        return;
    end
    va = A.Properties.VariableNames;
    vb = B.Properties.VariableNames;
    allv = [va, vb(~ismember(vb, va))];
    A = pad_table_missing_vars(A, allv, B);
    B = pad_table_missing_vars(B, allv, A);
    A = A(:, allv);
    B = B(:, allv);
end

function T = pad_table_missing_vars(T, allv, refT)
    for i = 1:numel(allv)
        vn = allv{i};
        if ismember(vn, T.Properties.VariableNames)
            continue;
        end
        if ismember(vn, refT.Properties.VariableNames) && height(refT) >= 1
            fill0 = default_missing_like(refT.(vn)(1, :));
        else
            fill0 = NaN;
        end
        T.(vn) = repmat(fill0, height(T), 1);
    end
end

function m = default_missing_like(x)
    if isempty(x)
        m = NaN;
        return;
    end
    if isnumeric(x)
        m = NaN(1, size(x, 2));
    elseif islogical(x)
        m = false(1, size(x, 2));
    elseif isstring(x)
        m = strings(1, size(x, 2));
        m(:) = "";
    elseif isdatetime(x)
        m = NaT(1, size(x, 2));
    elseif iscell(x)
        m = {''};
    else
        m = NaN;
    end
end

function s = ensure_summary_struct(metrics, experiment_case, status)
    default_total = 0;
    if isfield(experiment_case, 'req_cfg') && isfield(experiment_case.req_cfg, 'requests_num')
        default_total = double(experiment_case.req_cfg.requests_num);
    end

    s = struct( ...
        'total_requests', default_total, ...
        'accepted_count', 0, ...
        'rejected_count', default_total, ...
        'acceptance_rate', 0, ...
        'avg_cpu', 0, ...
        'avg_memory', 0, ...
        'avg_bandwidth', 0, ...
        'avg_e2e_delay', 0, ...
        'avg_slack_ratio', 0, ...
        'total_cpu', 0, ...
        'total_memory', 0, ...
        'total_bandwidth', 0, ...
        'vnf_sharing_gain', 0, ...
        'fail_lack_bw', 0, ...
        'fail_lack_cpu', 0, ...
        'fail_lack_mem', 0, ...
        'fail_timeout', 0, ...
        'fail_unschedulable', 0);

    if isfield(metrics, 'summary') && isstruct(metrics.summary)
        src = metrics.summary;
        fn = fieldnames(s);
        for i = 1:numel(fn)
            if isfield(src, fn{i}) && ~isempty(src.(fn{i}))
                s.(fn{i}) = src.(fn{i});
            end
        end
    end

    if strcmp(char(string(status)), 'success')
        s.rejected_count = max(s.total_requests - s.accepted_count, 0);
        if s.total_requests > 0
            s.acceptance_rate = s.accepted_count / s.total_requests;
        end
    end
end

function pr = ensure_per_request_table(metrics)
    var_names = {'case_id','req_id','deploy_order','accepted', ...
        'cpu_consume','memory_consume','bandwidth_consume','e2e_delay', ...
        'max_delay','slack_ratio','dest_count','vnf_count','vnf_gain'};
    pr = table(strings(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
        zeros(0,1), zeros(0,1), zeros(0,1), NaN(0,1), ...
        zeros(0,1), NaN(0,1), zeros(0,1), zeros(0,1), NaN(0,1), ...
        'VariableNames', var_names);

    if isfield(metrics, 'per_request') && istable(metrics.per_request)
        src = metrics.per_request;
        if all(ismember(var_names, src.Properties.VariableNames))
            pr = src(:, var_names);
        end
    end
end
