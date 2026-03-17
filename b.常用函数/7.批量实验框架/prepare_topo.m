function [topo_data, topo_cache] = prepare_topo(topo_cfg, topo_cache)
%PREPARE_TOPO  生成/缓存拓扑数据
%
%   [topo_data, topo_cache] = prepare_topo(topo_cfg)
%   [topo_data, topo_cache] = prepare_topo(topo_cfg, topo_cache)
%
% 输入：
%   topo_cfg   -- struct，含 topo_name, topo_func, minm, maxm, minc, maxc, minb, maxb
%   topo_cache -- struct（可选），用于在批量实验中缓存已生成的拓扑
%
% 输出：
%   topo_data  -- struct: .nodes, .links, .KPaths, .KPathsNew
%   topo_cache -- 更新后的缓存

    if nargin < 2 || isempty(topo_cache)
        topo_cache = struct();
    end

    topo_name = char(topo_cfg.topo_name);
    cache_field = matlab.lang.makeValidName(topo_name);

    % 命中缓存则直接返回
    if isfield(topo_cache, cache_field)
        topo_data = topo_cache.(cache_field);
        fprintf('  [拓扑] %s - 命中缓存\n', topo_name);
        return;
    end

    fprintf('  [拓扑] %s - 生成中...\n', topo_name);

    topo_func = char(topo_cfg.topo_func);
    topo = feval(topo_func);
    [link, ~] = topology_link_new(topo);
    nodes = Node_model(topo, topo_cfg.minm, topo_cfg.maxm, topo_cfg.minc, topo_cfg.maxc);
    links = Link_model(link, topo_cfg.minb, topo_cfg.maxb);

    % KPaths 智能加载
    kpath_path = fullfile('c.输出', '1.拓补信息', sprintf('%s_10Path.mat', topo_name));
    topo_info_path = fullfile('c.输出', '1.拓补信息', sprintf('%s_topoinfo.mat', topo_name));

    kpath_candidates = {
        kpath_path, ...
        fullfile('a.输入', '2.整理后的拓补信息', sprintf('%s_KPath.mat', topo_name)), ...
        fullfile('a.输入', '2.整理后的拓补信息', sprintf('%s_topoinfo.mat', topo_name))
    };

    KPathsLoaded = false;
    for i = 1:numel(kpath_candidates)
        if isfile(kpath_candidates{i})
            try
                ld = load(kpath_candidates{i});
                if isfield(ld, 'KPaths')
                    KPaths = ld.KPaths;
                    if isfield(ld, 'KPathsNew')
                        KPathsNew = ld.KPathsNew;
                    else
                        KPathsNew = refactorKPathsToCellStruct(KPaths);
                    end
                    KPathsLoaded = true;
                    fprintf('    已加载 KPaths: %s\n', kpath_candidates{i});
                    break;
                end
            catch
            end
        end
    end

    if ~KPathsLoaded
        fprintf('    计算 KPaths（可能耗时较长）...\n');
        KPaths = KPathsGenerater(topo, link, 10);
        KPathsNew = refactorKPathsToCellStruct(KPaths);
    end

    % 保存拓扑数据供后续使用
    ensure_dir_for_file(kpath_path);
    ensure_dir_for_file(topo_info_path);
    save(kpath_path, 'KPaths', 'KPathsNew');
    save(topo_info_path, 'KPaths', 'nodes', 'links', 'KPathsNew');

    topo_data.nodes     = nodes;
    topo_data.links     = links;
    topo_data.KPaths    = KPaths;
    topo_data.KPathsNew = KPathsNew;

    topo_cache.(cache_field) = topo_data;
    fprintf('    拓扑 %s 准备完成\n', topo_name);
end

function ensure_dir_for_file(filepath)
    [p, ~, ~] = fileparts(filepath);
    if ~isempty(p) && ~isfolder(p)
        mkdir(p);
    end
end
