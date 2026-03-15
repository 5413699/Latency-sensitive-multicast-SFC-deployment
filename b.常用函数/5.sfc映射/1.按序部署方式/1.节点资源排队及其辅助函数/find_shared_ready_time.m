%[text] # find\_shared\_ready\_time
%[text] 查找"共享实例"在该节点的 ready 时间
function ready_time = find_shared_ready_time(node, req_id, vnf_id)
%FIND_SHARED_READY_TIME  查找"共享实例"在该节点的 ready 时间
%
% 【MOD-2】共享语义：如果该节点上已经出现过 (req_id, vnf_id) 的任务，
%       则认为该VNF实例存在/正在部署，ready 时间取最早完成时刻 min(t_end)。
%
% 返回：
%   ready_time = []  表示不可共享
%   ready_time = k   表示该实例从时间 k 起 ready（到达早于k则需要等待）

    ready_time = [];

    if isempty(node.tasks)
        return;
    end

    % tasks 是 struct array：字段包括 req_id, vnf_id, t_end
    mask = ([node.tasks.req_id] == req_id) & ([node.tasks.vnf_id] == vnf_id);
    if any(mask)
        ready_time = min([node.tasks(mask).t_end]);
    end
end


%[appendix]{"version":"1.0"}
%---
