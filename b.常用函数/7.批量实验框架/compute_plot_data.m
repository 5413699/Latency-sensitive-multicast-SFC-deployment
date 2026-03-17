function compute_plot_data(summary_xlsx, plot_xlsx)
%COMPUTE_PLOT_DATA  从实验结果汇总 xlsx 聚合统计，生成绘图数据 xlsx
%
%   compute_plot_data()
%   compute_plot_data(summary_xlsx, plot_xlsx)
%
% 读取 实验结果汇总.xlsx 的三个 sheet，按 (topo_name, display_name, param_group)
% 分组，对多次重复实验计算 mean/std/CI95，写入 绘图数据.xlsx。

    if nargin < 1 || isempty(summary_xlsx)
        summary_xlsx = fullfile('c.输出', '实验结果汇总.xlsx');
    end
    if nargin < 2 || isempty(plot_xlsx)
        plot_xlsx = fullfile('c.输出', '绘图数据.xlsx');
    end

    if ~isfile(summary_xlsx)
        error('实验结果汇总文件不存在: %s', summary_xlsx);
    end

    opts = {'TextType','string'};
    meta_tbl    = readtable(summary_xlsx, 'Sheet','实验元数据', opts{:});
    summary_tbl = readtable(summary_xlsx, 'Sheet','汇总指标',   opts{:});
    detail_tbl  = readtable(summary_xlsx, 'Sheet','请求级明细', opts{:});

    % 只保留成功的实验
    success_mask = meta_tbl.status == "success";
    meta_ok = meta_tbl(success_mask, :);
    ok_ids = meta_ok.case_id;
    summary_ok = summary_tbl(ismember(summary_tbl.case_id, ok_ids), :);
    detail_ok  = detail_tbl(ismember(detail_tbl.case_id, ok_ids), :);

    % 为 summary 和 detail 添加分组字段
    group_cols = {'topo_name','display_name','param_group'};
    summary_joined = join_with_meta(summary_ok, meta_ok, group_cols);
    detail_joined  = join_with_meta(detail_ok, meta_ok, group_cols);

    % ====== Sheet 1: 方法对比汇总 ======
    fprintf('  计算方法对比汇总...\n');
    compare_tbl = compute_summary_sheet(summary_joined);

    % ====== Sheet 2: 逐请求曲线 ======
    fprintf('  计算逐请求曲线...\n');
    curve_tbl = compute_curve_sheet(detail_joined);

    % ====== Sheet 3: 失败分布 ======
    fprintf('  计算失败分布...\n');
    fail_tbl = compute_failure_sheet(summary_joined);

    % ====== 写入 ======
    if isfile(plot_xlsx)
        delete(plot_xlsx);
    end
    [p,~,~] = fileparts(plot_xlsx);
    if ~isempty(p) && ~isfolder(p); mkdir(p); end

    writetable(compare_tbl, plot_xlsx, 'Sheet','方法对比汇总');
    writetable(curve_tbl,   plot_xlsx, 'Sheet','逐请求曲线');
    writetable(fail_tbl,    plot_xlsx, 'Sheet','失败分布');

    fprintf('  绘图数据已写入: %s\n', plot_xlsx);
end

% ========================================================================
function out = join_with_meta(tbl, meta, cols)
    key_map = containers.Map(cellstr(meta.case_id), (1:height(meta))');
    n = height(tbl);
    for c = 1:numel(cols)
        col = cols{c};
        vals = strings(n, 1);
        for i = 1:n
            cid = char(tbl.case_id(i));
            if key_map.isKey(cid)
                vals(i) = meta.(col)(key_map(cid));
            end
        end
        tbl.(col) = vals;
    end
    out = tbl;
end

% ========================================================================
function tbl = compute_summary_sheet(data)
    metrics = {'acceptance_rate','avg_cpu','avg_memory','avg_bandwidth', ...
               'avg_e2e_delay','avg_slack_ratio','total_cpu','total_memory', ...
               'total_bandwidth','vnf_sharing_gain'};

    [G, topo_groups, display_groups, param_groups] = findgroups( ...
        data.topo_name, data.display_name, data.param_group);

    nG = numel(topo_groups);

    rows = {};
    for g = 1:nG
        mask = G == g;
        for mi = 1:numel(metrics)
            mn = metrics{mi};
            if ~ismember(mn, data.Properties.VariableNames); continue; end
            vals = data.(mn)(mask);
            vals = vals(~isnan(vals));
            [m, s, lo, hi, n] = stat_summary(vals);
            rows{end+1} = {topo_groups(g), display_groups(g), param_groups(g), ...
                           string(mn), m, s, lo, hi, n}; %#ok<AGROW>
        end
    end

    if isempty(rows)
        tbl = table();
        return;
    end
    tbl = cell2table(vertcat(rows{:}), 'VariableNames', ...
        {'topo_name','display_name','param_group','metric_name', ...
         'mean','std','ci95_lo','ci95_hi','n'});
end

% ========================================================================
function tbl = compute_curve_sheet(detail)
    [G, topo_groups, display_groups, param_groups] = findgroups( ...
        detail.topo_name, detail.display_name, detail.param_group);
    nG = numel(topo_groups);

    all_rows = {};
    for g = 1:nG
        mask = G == g;
        grp = detail(mask, :);
        case_ids = unique(grp.case_id);
        R = numel(case_ids);

        % 为每个 case 计算逐成功曲线
        curves = cell(R, 1);
        for r = 1:R
            cdata = grp(grp.case_id == case_ids(r), :);
            cdata = sortrows(cdata, 'deploy_order');
            curves{r} = compute_single_curve(cdata);
        end

        % 对齐到最大长度并聚合
        max_len = max(cellfun(@(c) size(c, 1), curves));
        if max_len == 0; continue; end

        fields = curves{1}.Properties.VariableNames;
        nf = numel(fields);
        mat = NaN(max_len, nf, R);
        for r = 1:R
            L = size(curves{r}, 1);
            for fi = 1:nf
                mat(1:L, fi, r) = curves{r}.(fields{fi});
            end
        end

        for k = 1:max_len
            row = {topo_groups(g), display_groups(g), param_groups(g), k};
            for fi = 1:nf
                vals = squeeze(mat(k, fi, :));
                vals = vals(~isnan(vals));
                if isempty(vals)
                    row = [row, {NaN, NaN}]; %#ok<AGROW>
                else
                    row = [row, {mean(vals), std_safe(vals)}]; %#ok<AGROW>
                end
            end
            all_rows{end+1} = row; %#ok<AGROW>
        end
    end

    if isempty(all_rows)
        tbl = table();
        return;
    end

    fields = curves{1}.Properties.VariableNames;
    col_names = {'topo_name','display_name','param_group','success_index'};
    for fi = 1:numel(fields)
        fn = fields{fi};
        col_names{end+1} = [fn '_mean']; %#ok<AGROW>
        col_names{end+1} = [fn '_std'];  %#ok<AGROW>
    end
    tbl = cell2table(vertcat(all_rows{:}), 'VariableNames', col_names);
end

% ========================================================================
function curve = compute_single_curve(cdata)
    N = height(cdata);
    acc_mask = cdata.accepted == 1;
    acc_data = cdata(acc_mask, :);
    A = height(acc_data);

    if A == 0
        curve = table();
        return;
    end

    cpu = acc_data.cpu_consume;
    mem = acc_data.memory_consume;
    bw  = acc_data.bandwidth_consume;

    avg_cpu = cumsum(cpu) ./ (1:A)';
    avg_mem = cumsum(mem) ./ (1:A)';
    avg_bw  = cumsum(bw)  ./ (1:A)';
    cum_cpu = cumsum(cpu);
    cum_mem = cumsum(mem);
    cum_bw  = cumsum(bw);

    % e2e delay (handle NaN)
    delay = acc_data.e2e_delay;
    delay_clean = delay; delay_clean(isnan(delay_clean)) = 0;
    valid_d = double(~isnan(delay));
    avg_delay = cumsum(delay_clean) ./ max(cumsum(valid_d), 1);

    % slack
    slack = acc_data.slack_ratio;
    slack_clean = slack; slack_clean(isnan(slack_clean)) = 0;
    valid_s = double(~isnan(slack));
    avg_slack = cumsum(slack_clean) ./ max(cumsum(valid_s), 1);

    % block rate at success_index
    deploy_orders = acc_data.deploy_order;
    block_rate = 1 - (1:A)' ./ deploy_orders;

    % vnf sharing gain
    vnf_gain = NaN(A, 1);
    if ismember('vnf_gain', acc_data.Properties.VariableNames)
        vg = acc_data.vnf_gain;
        vg_clean = vg; vg_clean(isnan(vg_clean)) = 0;
        valid_v = double(~isnan(vg));
        vnf_gain = cumsum(vg_clean) ./ max(cumsum(valid_v), 1);
    end

    curve = table(avg_cpu, avg_mem, avg_bw, avg_delay, avg_slack, ...
                  cum_cpu, cum_mem, cum_bw, block_rate, vnf_gain);
end

% ========================================================================
function tbl = compute_failure_sheet(data)
    fail_types = {'fail_lack_bw','fail_lack_cpu','fail_lack_mem', ...
                  'fail_timeout','fail_unschedulable'};
    type_labels = ["lack_bw","lack_cpu","lack_mem","timeout","unschedulable"];

    [G, topo_groups, display_groups, param_groups] = findgroups( ...
        data.topo_name, data.display_name, data.param_group);
    nG = numel(topo_groups);

    rows = {};
    for g = 1:nG
        mask = G == g;
        for fi = 1:numel(fail_types)
            fn = fail_types{fi};
            if ~ismember(fn, data.Properties.VariableNames); continue; end
            vals = data.(fn)(mask);
            vals = vals(~isnan(vals));
            rows{end+1} = {topo_groups(g), display_groups(g), param_groups(g), type_labels(fi), ...
                           mean_safe(vals), std_safe(vals)}; %#ok<AGROW>
        end
    end

    if isempty(rows)
        tbl = table();
        return;
    end
    tbl = cell2table(vertcat(rows{:}), 'VariableNames', ...
        {'topo_name','display_name','param_group','fail_type','count_mean','count_std'});
end

% ========================================================================
function [m, s, lo, hi, n] = stat_summary(vals)
    n = numel(vals);
    if n == 0
        m = NaN; s = NaN; lo = NaN; hi = NaN;
    elseif n == 1
        m = vals(1); s = 0; lo = m; hi = m;
    else
        m = mean(vals);
        s = std(vals);
        se = s / sqrt(n);
        lo = m - 1.96 * se;
        hi = m + 1.96 * se;
    end
end

function s = std_safe(vals)
    if numel(vals) < 2; s = 0; else; s = std(vals); end
end

function m = mean_safe(vals)
    if isempty(vals); m = 0; else; m = mean(vals); end
end

