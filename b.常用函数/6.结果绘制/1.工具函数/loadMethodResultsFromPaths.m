function methods = loadMethodResultsFromPaths(resultPaths, methodNames, cfg)
%LOADMETHODRESULTSFROMPATHS  从多个 result.mat 路径加载方法结果
%
% 用法示例：
%   paths = { ...
%       'c.输出\\4.资源消耗与失败日志\\...\\SPFresult.mat', ...
%       'c.输出\\4.资源消耗与失败日志\\...\\RDAresult.mat'};
%   names = {'SPF','RDA'};
%   methods = loadMethodResultsFromPaths(paths, names);
%
% 输出 methods(i) 字段：
%   .name(用于图例显示), .raw_name(原始方法名), .nodes, .links, .requests, .consume, .fail_log

    if nargin < 2 || isempty(methodNames)
        methodNames = cell(size(resultPaths));
        for i = 1:numel(resultPaths)
            [~, base, ~] = fileparts(resultPaths{i});
            methodNames{i} = base;
        end
    end

    if nargin < 3
        cfg = struct();
    end

    methods = repmat(struct('name','', 'raw_name','', 'nodes',[], 'links',[], 'requests',[], 'consume',[], 'fail_log',[]), numel(resultPaths), 1);

    for i = 1:numel(resultPaths)
        S = load(resultPaths{i});

        % 只依赖 sfcMapping 保存的 5 个核心变量
        raw = methodNames{i};
        methods(i).raw_name = raw;

        % 应用图例显示名映射（如果提供）
        dispName = raw;
        if isfield(cfg, 'methodDisplayNames')
            try
                if isa(cfg.methodDisplayNames, 'containers.Map') && isKey(cfg.methodDisplayNames, raw)
                    dispName = cfg.methodDisplayNames(raw);
                end
            catch
                % 容错：cfg.methodDisplayNames 不是 Map 或其他异常时，退回 raw
                dispName = raw;
            end
        end
        methods(i).name = dispName;

        methods(i).nodes    = S.nodes;
        methods(i).links    = S.links;
        methods(i).requests = S.requests;
        methods(i).consume  = S.consume;
        methods(i).fail_log = S.fail_log;
    end

    % 处理“映射后重名”的情况（仅在必要时）
    if isfield(cfg, 'disambiguateDuplicateLegendNames') && cfg.disambiguateDuplicateLegendNames
        names = {methods.name};
        [u, ~, ic] = unique(names);
        cnt = accumarray(ic(:), 1);
        dupIdx = find(cnt > 1);
        if ~isempty(dupIdx)
            for k = 1:numel(dupIdx)
                dn = u{dupIdx(k)};
                idxs = find(strcmp(names, dn));
                if numel(idxs) <= 1
                    continue;
                end
                % 尽量只对 RDA 这类“合并显示名”做区分
                for j = 1:numel(idxs)
                    ii = idxs(j);
                    raw = methods(ii).raw_name;
                    if contains(raw, 'Online')
                        methods(ii).name = sprintf('%s(Online)', dn);
                    elseif contains(raw, 'ResourceAndDelayAware')
                        methods(ii).name = sprintf('%s(Offline)', dn);
                    else
                        methods(ii).name = sprintf('%s(%d)', dn, j);
                    end
                end
            end
        end
    end
end
