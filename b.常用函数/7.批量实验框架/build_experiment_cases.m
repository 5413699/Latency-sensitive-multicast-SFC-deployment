function cases = build_experiment_cases(cfg)
%BUILD_EXPERIMENT_CASES  将配置展开为实验案例数组
%
%   cases = build_experiment_cases(cfg)
%
% 输入：cfg -- load_config 返回的配置结构体
% 输出：cases -- struct 数组，每个元素代表一次待执行的实验

    cases = struct([]);
    idx = 0;

    for row = 1:height(cfg.experiments)
        exp = cfg.experiments(row, :);

        enabled = parse_scalar_number(exp.enabled, 1);
        if enabled == 0
            continue;
        end

        group_id    = excel_field_to_char(exp.group_id, 'group');
        topo_name   = excel_field_to_char(exp.topo_name, 'topo');
        method_name = excel_field_to_char(exp.method_name, 'method');
        param_group = excel_field_to_char(exp.param_group, 'default');
        repeat_count = parse_scalar_number(exp.repeat_count, 1);

        req_ids = parse_request_set_ids(exp.request_set_ids);
        if isempty(req_ids)
            warning('实验组 "%s" 的 request_set_ids 为空或格式非法，跳过', group_id);
            continue;
        end

        % 查找对应的拓扑配置
        topo_mask = cfg.topos.topo_name == string(topo_name);
        if ~any(topo_mask)
            warning('拓扑 "%s" 在拓扑配置中未找到，跳过', topo_name);
            continue;
        end
        topo_row = cfg.topos(topo_mask, :);
        topo_cfg = table2struct(topo_row(1,:));

        % 查找对应的请求配置
        req_mask = cfg.requests.topo_name == string(topo_name);
        if ~any(req_mask)
            warning('拓扑 "%s" 在请求配置中未找到，跳过', topo_name);
            continue;
        end
        req_row = cfg.requests(req_mask, :);
        req_cfg = table2struct(req_row(1,:));

        % 查找对应的方法配置
        method_mask = cfg.methods.method_name == string(method_name);
        if ~any(method_mask)
            warning('方法 "%s" 在方法配置中未找到，跳过', method_name);
            continue;
        end
        method_row = cfg.methods(method_mask, :);
        method_cfg = table2struct(method_row(1,:));

        % 查找对应的参数组（可能不存在 -> 无额外参数）
        pg_mask = cfg.param_groups.method_name == string(method_name) & ...
                  cfg.param_groups.param_group == string(param_group);
        if any(pg_mask)
            pg_row = cfg.param_groups(pg_mask, :);
            pg = table2struct(pg_row(1,:));
            pg_fields = fieldnames(pg);
            for fi = 1:numel(pg_fields)
                fn = pg_fields{fi};
                if ~strcmp(fn, 'method_name') && ~strcmp(fn, 'param_group')
                    method_cfg.(fn) = pg.(fn);
                end
            end
        end

        seed_base = 42;
        if isfield(cfg.global, 'rng_seed_base')
            seed_base = cfg.global.rng_seed_base;
        end

        % 展开: request_set_id x repeat
        for ri = 1:numel(req_ids)
            for rep = 1:repeat_count
                idx = idx + 1;

                disp_name = excel_field_to_char(method_cfg.display_name, method_name);
                topo_abbr = topo_name(1:min(3, numel(topo_name)));
                case_id = sprintf('%s_%s_%s_%s_R%d_rep%d', ...
                    group_id, topo_abbr, disp_name, param_group, ...
                    req_ids(ri), rep);

                seed = seed_base + req_ids(ri) * 1000 + rep;

                c = struct();
                c.case_id        = case_id;
                c.group_id       = group_id;
                c.topo_name      = topo_name;
                c.method_name    = method_name;
                c.display_name   = disp_name;
                c.param_group    = param_group;
                c.request_set_id = req_ids(ri);
                c.repeat_id      = rep;
                c.seed           = seed;
                c.topo_cfg       = topo_cfg;
                c.req_cfg        = req_cfg;
                c.method_cfg     = method_cfg;
                c.global_cfg     = cfg.global;

                if isempty(cases)
                    cases = c;
                else
                    cases(idx) = c;
                end
            end
        end
    end

    if isempty(cases)
        warning('没有启用的实验组合');
        cases = struct([]);
    else
        fprintf('已展开 %d 个实验案例\n', numel(cases));
    end
end

function s = excel_field_to_char(raw, fallback)
%EXCEL_FIELD_TO_CHAR  将表格/Excel 读入的单元格转为可用于 sprintf 的 char
%   空单元格在 readtable(...,'TextType','string') 下会变成 string 的 <missing>，
%   直接传入 sprintf 会报错，此处统一成非 missing 的 char。

    if nargin < 2
        fallback = '';
    end
    fb = char(string(fallback));

    if iscell(raw) && ~isempty(raw)
        raw = raw{1};
    end

    if isempty(raw) && ~(isstring(raw) || iscategorical(raw))
        s = fb;
        return;
    end

    t = string(raw);
    if ~isscalar(t)
        t = t(1);
    end
    if ismissing(t) || strtrim(t) == ""
        s = fb;
    else
        s = char(strtrim(t));
    end
end

function value = parse_scalar_number(raw, default_value)
    if nargin < 2
        default_value = NaN;
    end

    if isnumeric(raw) || islogical(raw)
        value = double(raw);
    elseif isstring(raw) || ischar(raw)
        value = str2double(string(raw));
    elseif iscell(raw) && ~isempty(raw)
        value = parse_scalar_number(raw{1}, default_value);
    else
        value = default_value;
    end

    if isempty(value) || isnan(value)
        value = default_value;
    end
end

function req_ids = parse_request_set_ids(raw)
    if isnumeric(raw) || islogical(raw)
        req_ids = double(raw(:)).';
        req_ids = req_ids(~isnan(req_ids));
        return;
    end

    if iscell(raw) && ~isempty(raw)
        raw = raw{1};
    end

    if ismissing(raw) || isempty(raw)
        req_ids = [];
        return;
    end

    raw_str = strtrim(char(string(raw)));
    if isempty(raw_str)
        req_ids = [];
        return;
    end

    parts = regexp(raw_str, '[,，\s]+', 'split');
    req_ids = str2double(parts);
    req_ids = req_ids(~isnan(req_ids));
end
