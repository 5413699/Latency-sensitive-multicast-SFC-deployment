function [nodes, links, requests, consume, fail_log] = execute_deploy_pipeline( ...
        requests, sortedRequests, nodes, links, KPathsNew, method_cfg)
%EXECUTE_DEPLOY_PIPELINE  统一部署流水线（在线/离线/未来RL）
%
%   [nodes, links, requests, consume, fail_log] = execute_deploy_pipeline(...)
%
% 根据 method_cfg.online_mode 自动选择在线或离线流程。
% 核心算法函数通过 feval 调用，签名与旧代码完全一致。

    % ====== 构造传给算法函数的 deploy_cfg ======
    deploy_cfg = struct();
    deploy_cfg.deployFunc = char(method_cfg.deploy_func);
    deploy_cfg.FixedFunc  = char(method_cfg.fixed_func);
    deploy_cfg.sortedFunc = char(method_cfg.sorted_func);

    % 合并算法参数（candLinkNum, shareWeight 等）
    skip_fields = {'method_name','display_name','deploy_func','requests_type', ...
                   'fixed_func','sorted_func','online_mode','param_group','topo_name'};
    fnames = fieldnames(method_cfg);
    for i = 1:numel(fnames)
        fn = fnames{i};
        if ~ismember(fn, skip_fields) && ~isfield(deploy_cfg, fn)
            deploy_cfg.(fn) = method_cfg.(fn);
        end
    end

    % ====== 选择请求集 ======
    req_type = char(method_cfg.requests_type);
    if strcmp(req_type, 'sortedRequests')
        reqs = sortedRequests;
    else
        reqs = requests;
    end

    % ====== 初始化必要结构 ======
    [fail_log, consume, nodes, plan] = initNecessaryStructure(reqs, nodes);

    online_mode = false;
    if isfield(method_cfg, 'online_mode')
        online_mode = logical(method_cfg.online_mode);
    end

    % ====== 根据模式选择流程 ======
    if online_mode
        % ===== 在线模式 =====
        fprintf('    [部署] 在线模式: %s\n', deploy_cfg.deployFunc);

        [plan, nodes, links, consume, fail_log, ~] = feval( ...
            deploy_cfg.deployFunc, ...
            reqs, KPathsNew, links, nodes, ...
            plan, consume, fail_log, deploy_cfg);

        feval(deploy_cfg.FixedFunc, reqs, plan, links);
        feval(deploy_cfg.sortedFunc, reqs, ...
              feval(deploy_cfg.FixedFunc, reqs, plan, links), links);

        requests = reqs;

    % ===== 未来扩展：强化学习模式 =====
    % elseif isfield(method_cfg, 'rl_mode') && method_cfg.rl_mode
    %     [plan, nodes, links, consume, fail_log] = rl_deploy( ...
    %         reqs, KPathsNew, links, nodes, plan, consume, fail_log, deploy_cfg);
    %     requests = reqs;

    else
        % ===== 离线模式 =====
        fprintf('    [部署] 离线模式: %s\n', deploy_cfg.deployFunc);

        plan = feval(deploy_cfg.deployFunc, ...
                     reqs, KPathsNew, links, nodes, plan, deploy_cfg);

        fixedPlan = feval(deploy_cfg.FixedFunc, reqs, plan, links);
        sortedPlan = feval(deploy_cfg.sortedFunc, reqs, fixedPlan, links);

        [nodes, links, reqs, consume, fail_log] = deploy_requests( ...
            nodes, links, reqs, sortedPlan, consume, fail_log);

        requests = reqs;
    end
end
