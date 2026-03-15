function taskCount = collectTaskCountByReq(nodes, maxReqId)
%COLLECTTASKCOUNTBYREQ  统计每个 req_id 的 tasks 数量（跨所有节点）
%
% 说明：
%   - nodes(n).tasks 是 struct 数组，字段包含 req_id 等。
%   - 本函数把所有节点的 tasks.req_id 拉平后计数。
%
% 输出：
%   taskCount(req_id) = 该请求在全网“实际部署的 VNF 实例（tasks）”数量

    allReqIds = [];
    for n = 1:numel(nodes)
        if isfield(nodes(n), 'tasks') && ~isempty(nodes(n).tasks)
            allReqIds = [allReqIds; [nodes(n).tasks.req_id].']; %#ok<AGROW>
        end
    end

    if isempty(allReqIds)
        taskCount = zeros(maxReqId, 1);
        return;
    end

    taskCount = accumarray(allReqIds, 1, [maxReqId, 1], @sum, 0);
end
