function metrics = collect_experiment_metrics(requests, nodes, consume, fail_log)
%COLLECT_EXPERIMENT_METRICS  从实验结果中提取全部指标
%
%   metrics = collect_experiment_metrics(requests, nodes, consume, fail_log)
%
% 输出：
%   metrics.summary      -- 1x1 struct (汇总指标)
%   metrics.per_request  -- table (每请求明细)
%   metrics.fail_summary -- struct (按失败类型统计)

    metrics = struct();
    req_ids = [requests.id].';
    N = numel(req_ids);
    max_rid = max(req_ids);

    % ====== 汇总指标 ======
    accepted_flags = zeros(N, 1);
    for i = 1:N
        rid = req_ids(i);
        if rid <= numel(consume)
            accepted_flags(i) = consume(rid).accepted;
        end
    end
    accepted_req_ids = req_ids(accepted_flags == 1);
    A = numel(accepted_req_ids);

    s = struct();
    s.total_requests  = N;
    s.accepted_count  = A;
    s.rejected_count  = N - A;
    s.acceptance_rate = A / max(N, 1);

    % 提取 accepted 请求的资源消耗
    cpu_vals = zeros(A, 1);
    mem_vals = zeros(A, 1);
    bw_vals  = zeros(A, 1);
    e2e_vals = NaN(A, 1);
    slack_vals = NaN(A, 1);

    for k = 1:A
        rid = accepted_req_ids(k);
        cpu_vals(k) = consume(rid).cpu_consume;
        mem_vals(k) = consume(rid).memory_consume;
        bw_vals(k)  = consume(rid).bandwidth_consume;

        idx = find(req_ids == rid, 1);
        req = requests(idx);
        e2e_vals(k) = compute_e2e_delay(nodes, req, rid);

        if ~isnan(e2e_vals(k)) && isfield(req, 'max_delay') && req.max_delay > 0
            slack_vals(k) = (req.max_delay - e2e_vals(k)) / req.max_delay;
        end
    end

    s.avg_cpu       = safe_mean(cpu_vals);
    s.avg_memory    = safe_mean(mem_vals);
    s.avg_bandwidth = safe_mean(bw_vals);
    s.avg_e2e_delay = safe_mean(e2e_vals(~isnan(e2e_vals)));
    s.avg_slack_ratio = safe_mean(slack_vals(~isnan(slack_vals)));
    s.total_cpu     = sum(cpu_vals);
    s.total_memory  = sum(mem_vals);
    s.total_bandwidth = sum(bw_vals);

    % VNF 共享增益
    task_count = collect_task_count(nodes, max_rid);
    gain_ratios = zeros(A, 1);
    for k = 1:A
        rid = accepted_req_ids(k);
        idx = find(req_ids == rid, 1);
        req = requests(idx);
        dest_num = numel(req.dest(req.dest > 0));
        vnf_num  = numel(req.vnf);
        theory = dest_num * vnf_num;
        actual = task_count(rid);
        if theory > 0
            gain_ratios(k) = (theory - actual) / theory;
        end
    end
    s.vnf_sharing_gain = safe_mean(gain_ratios);

    % ====== 失败统计 ======
    fs = struct();
    fs.fail_lack_bw = 0;
    fs.fail_lack_cpu = 0;
    fs.fail_lack_mem = 0;
    fs.fail_timeout = 0;
    fs.fail_unschedulable = 0;

    if ~isempty(fail_log)
        if isfield(fail_log, 'lack_bw')
            fs.fail_lack_bw = sum([fail_log.lack_bw] == 1);
        elseif isfield(fail_log, 'lack_bandwidth')
            fs.fail_lack_bw = sum([fail_log.lack_bandwidth] == 1);
        end
        if isfield(fail_log, 'lack_cpu')
            fs.fail_lack_cpu = sum([fail_log.lack_cpu] == 1);
        end
        if isfield(fail_log, 'lack_mem')
            fs.fail_lack_mem = sum([fail_log.lack_mem] == 1);
        end
        if isfield(fail_log, 'time_out')
            fs.fail_timeout = sum([fail_log.time_out] == 1);
        elseif isfield(fail_log, 'TIMEOUT')
            fs.fail_timeout = sum([fail_log.TIMEOUT] == 1);
        end
        if isfield(fail_log, 'unschedulable')
            fs.fail_unschedulable = sum([fail_log.unschedulable] == 1);
        end
    end

    s.fail_lack_bw = fs.fail_lack_bw;
    s.fail_lack_cpu = fs.fail_lack_cpu;
    s.fail_lack_mem = fs.fail_lack_mem;
    s.fail_timeout = fs.fail_timeout;
    s.fail_unschedulable = fs.fail_unschedulable;

    metrics.summary = s;
    metrics.fail_summary = fs;

    % ====== 每请求明细 ======
    pr_case_id    = strings(N, 1);
    pr_req_id     = zeros(N, 1);
    pr_order      = zeros(N, 1);
    pr_accepted   = zeros(N, 1);
    pr_cpu        = zeros(N, 1);
    pr_mem        = zeros(N, 1);
    pr_bw         = zeros(N, 1);
    pr_e2e        = NaN(N, 1);
    pr_max_delay  = zeros(N, 1);
    pr_slack      = NaN(N, 1);
    pr_dest_count = zeros(N, 1);
    pr_vnf_count  = zeros(N, 1);
    pr_vnf_gain   = NaN(N, 1);

    for i = 1:N
        rid = req_ids(i);
        pr_req_id(i) = rid;
        pr_order(i)  = i;

        if rid <= numel(consume)
            pr_accepted(i) = consume(rid).accepted;
            pr_cpu(i)      = consume(rid).cpu_consume;
            pr_mem(i)      = consume(rid).memory_consume;
            pr_bw(i)       = consume(rid).bandwidth_consume;
        end

        req = requests(i);
        pr_dest_count(i) = numel(req.dest(req.dest > 0));
        pr_vnf_count(i)  = numel(req.vnf);

        if isfield(req, 'max_delay')
            pr_max_delay(i) = req.max_delay;
        end

        if pr_accepted(i)
            pr_e2e(i) = compute_e2e_delay(nodes, req, rid);
            if ~isnan(pr_e2e(i)) && pr_max_delay(i) > 0
                pr_slack(i) = (pr_max_delay(i) - pr_e2e(i)) / pr_max_delay(i);
            end
            theory = pr_dest_count(i) * pr_vnf_count(i);
            actual = task_count(rid);
            if theory > 0
                pr_vnf_gain(i) = (theory - actual) / theory;
            else
                pr_vnf_gain(i) = 0;
            end
        end
    end

    metrics.per_request = table(pr_case_id, pr_req_id, pr_order, pr_accepted, ...
        pr_cpu, pr_mem, pr_bw, pr_e2e, pr_max_delay, pr_slack, ...
        pr_dest_count, pr_vnf_count, pr_vnf_gain, ...
        'VariableNames', {'case_id','req_id','deploy_order','accepted', ...
        'cpu_consume','memory_consume','bandwidth_consume','e2e_delay', ...
        'max_delay','slack_ratio','dest_count','vnf_count','vnf_gain'});
end

% ====== 内部辅助函数 ======

function e2e = compute_e2e_delay(nodes, req, req_id)
    if isfield(req, 'e2e_delay') && ~isempty(req.e2e_delay) && req.e2e_delay > 0
        e2e = req.e2e_delay;
        return;
    end
    if isfield(req, 'branch_end_time') && ~isempty(req.branch_end_time) && any(req.branch_end_time > 0)
        e2e = max(req.branch_end_time(:)) - 1;
        return;
    end
    e2e = estimate_from_tasks(nodes, req, req_id);
end

function e2e = estimate_from_tasks(nodes, req, req_id)
    e2e = NaN;
    if isempty(nodes); return; end

    dests = req.dest(req.dest > 0);
    vnf_num = numel(req.vnf);
    branch_end = NaN(numel(dests), 1);

    for n = 1:numel(nodes)
        if ~isfield(nodes(n), 'tasks') || isempty(nodes(n).tasks); continue; end
        tk = nodes(n).tasks;
        mask = [tk.req_id] == req_id;
        if ~any(mask); continue; end
        tk = tk(mask);
        for di = 1:numel(dests)
            m2 = [tk.dest_idx] == di & [tk.vnf_idx] == vnf_num;
            if any(m2)
                t_end = max([tk(m2).t_end]);
                if isnan(branch_end(di)) || t_end > branch_end(di)
                    branch_end(di) = t_end;
                end
            end
        end
    end

    if ~all(isnan(branch_end))
        e2e = max(branch_end(~isnan(branch_end))) - 1;
    end
end

function tc = collect_task_count(nodes, max_rid)
    all_ids = [];
    for n = 1:numel(nodes)
        if isfield(nodes(n), 'tasks') && ~isempty(nodes(n).tasks)
            all_ids = [all_ids; [nodes(n).tasks.req_id].']; %#ok<AGROW>
        end
    end
    if isempty(all_ids)
        tc = zeros(max_rid, 1);
    else
        tc = accumarray(all_ids, 1, [max_rid, 1], @sum, 0);
    end
end

function v = safe_mean(x)
    if isempty(x); v = 0; else; v = mean(x); end
end
