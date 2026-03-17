function [requests, sortedRequests] = prepare_requests(req_cfg, topo_name, request_set_id, nodes, seed)
%PREPARE_REQUESTS  加载或生成请求集
%
%   [requests, sortedRequests] = prepare_requests(req_cfg, topo_name, request_set_id, nodes)
%   [requests, sortedRequests] = prepare_requests(req_cfg, topo_name, request_set_id, nodes, seed)
%
% 优先从 c.输出/2.请求信息/{topo}/request/request{N}.mat 加载；
% 不存在时按 seed 生成并保存。

    topo_name = char(topo_name);
    req_dir = fullfile('c.输出', '2.请求信息', topo_name, 'request');
    sorted_dir = fullfile('c.输出', '2.请求信息', topo_name, 'sortedRequest');

    req_file = fullfile(req_dir, sprintf('request%d.mat', request_set_id));
    sorted_file = fullfile(sorted_dir, sprintf('sortedRequest%d.mat', request_set_id));

    if isfile(req_file) && isfile(sorted_file)
        ld1 = load(req_file);
        requests = ld1.requests;
        ld2 = load(sorted_file);
        sortedRequests = ld2.sortedRequests;
        fprintf('  [请求] 已加载请求集 %d (共 %d 个请求)\n', request_set_id, numel(requests));
        return;
    end

    % 生成新请求
    if nargin >= 5 && ~isempty(seed)
        rng(seed);
    end

    fprintf('  [请求] 生成请求集 %d...\n', request_set_id);
    requests = generate_requests( ...
        req_cfg.requests_num, nodes, ...
        req_cfg.destNode_count, req_cfg.vnftype_num, req_cfg.vnf_num, ...
        req_cfg.maxbw, req_cfg.minbw, req_cfg.maxnr, req_cfg.minnr, ...
        req_cfg.maxt, req_cfg.mint);

    sortedRequests = sortRequestByDeadline(requests);

    % 保存
    if ~isfolder(req_dir); mkdir(req_dir); end
    if ~isfolder(sorted_dir); mkdir(sorted_dir); end
    save(req_file, 'requests');
    save(sorted_file, 'sortedRequests');
    fprintf('    请求集 %d 已生成并保存 (%d 个请求)\n', request_set_id, numel(requests));
end
