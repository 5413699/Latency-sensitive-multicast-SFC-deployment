function [e2e_delay, sourceTag] = getE2EDelayForRequest(nodes, req, req_id)
%GETE2EDELAYFORREQUEST  计算单个请求的端到端时延
%
% 端到端时延 e2e_delay 的定义：
%   e2e_delay = max(每个 dest 分支的最后一个 VNF 完成时间) - 1
%   （减1是因为部署从 t=1 开始）
%
% 数据来源优先级：
%   1) requests 里已记录的字段（由 deploy_requests 在成功部署时写入）：
%        - req.e2e_delay        (标量，最准确)
%        - req.branch_end_time  (dest_num×1)
%   2) 回退：从 nodes.tasks 估计（共享分支可能不准确）
%
% 输出：
%   e2e_delay : 标量（可能为 NaN 表示无法计算）
%   sourceTag : 字符串，表示本次使用了哪个来源

    % ---------- 1) 优先：req 里直接有 e2e_delay ----------
    if isfield(req, 'e2e_delay') && ~isempty(req.e2e_delay) && req.e2e_delay > 0
        e2e_delay = req.e2e_delay;
        sourceTag = "requests.e2e_delay";
        return;
    end

    % ---------- 2) 次优：req 里有 branch_end_time ----------
    if isfield(req, 'branch_end_time') && ~isempty(req.branch_end_time) && any(req.branch_end_time > 0)
        e2e_delay = max(req.branch_end_time(:)) - 1;  % 减1是因为从t=1开始
        sourceTag = "requests.branch_end_time";
        return;
    end

    % ---------- 3) 回退：从 nodes.tasks 估计 ----------
    % 注意：如果启用了 VNF 共享，共享分支不会写入 tasks 记录，
    %       因此这种方式可能低估真实的端到端时延。
    e2e_delay = NaN;
    sourceTag = "nodes.tasks";

    if isempty(nodes)
        return;
    end

    dests = req.dest(req.dest > 0);
    dest_num = numel(dests);
    vnf_num  = numel(req.vnf);

    % 收集所有节点中属于该 req_id 的 tasks
    branch_end = NaN(dest_num, 1);

    for n = 1:numel(nodes)
        if ~isfield(nodes(n), 'tasks') || isempty(nodes(n).tasks)
            continue;
        end

        tk = nodes(n).tasks;
        % 只保留该 req_id 的记录
        maskReq = ([tk.req_id] == req_id);
        if ~any(maskReq)
            continue;
        end

        tk = tk(maskReq);

        % 逐 dest_idx 找最后一个 VNF 的 t_end
        for di = 1:dest_num
            maskDest = ([tk.dest_idx] == di) & ([tk.vnf_idx] == vnf_num);
            if any(maskDest)
                t_end_candidates = max([tk(maskDest).t_end]);
                % 保留最大值（处理多节点情况）
                if isnan(branch_end(di)) || t_end_candidates > branch_end(di)
                    branch_end(di) = t_end_candidates;
                end
            end
        end
    end

    if all(isnan(branch_end))
        % 完全无法估计
        e2e_delay = NaN;
        return;
    end

    % 取有效分支的最大结束时间，减1得到端到端时延
    e2e_delay = max(branch_end(~isnan(branch_end))) - 1;
end
