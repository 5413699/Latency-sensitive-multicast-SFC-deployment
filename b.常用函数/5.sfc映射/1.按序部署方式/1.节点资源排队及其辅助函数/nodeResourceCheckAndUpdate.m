function [nodes, lack_cpu, lack_mem, time_out, leaveNodeTime, consume, node_consume] = ...
    nodeResourceCheckAndUpdate(nodes, place_node_id, ...
                               req, req_id, dest_idx, vnf_idx, vnf_id, ...
                               arriveNodeTime, cpu_need, mem_need, consume)
%NODERESOURCECHECKANDUPDATE  节点侧：VNF共享 + FIFO排队 + 资源预留 + 动态时延（方案A）
%
% 本函数是"步骤6：部署"里节点侧的核心更新逻辑。
% 节点一次只能处理一个任务（单机），并在节点内部按 FIFO 规则排队。
% 处理时延（proc_duration）在"到达时刻 arriveNodeTime"就确定，
%          排队只会增加等待时间，不会改变本次任务的处理时长。
% leaveNodeTime 的定义：
%   leaveNodeTime = actual_start_time + proc_duration
% 其中：
%   actual_start_time >= arriveNodeTime（如果节点忙，就需要等待）
% --------------------------------------------------------------------------
% VNF共享时：不消耗新资源，但必须等待"共享实例部署完成(ready)"才能继续。
%         - ready_time 从 nodes(place_node_id).tasks 中找到同 req_id + vnf_id 的最早 t_end。
%         - leaveNodeTime = max(arriveNodeTime, ready_time)
%         - 并且：新部署时 nodes.vnf 的"可共享标记"从 leaveNodeTime 开始写入（而不是 arriveNodeTime）
%           这样语义更一致：实例部署完成后才可共享。
%
% FIFO 的 actual_start_time 不能简单用 max(arrive, free_flag)：
%         需要确保 [start, start+proc_duration) 这段时间窗口确实空闲。
%         若不空闲，则向后寻找"最早的、长度足够的空闲时间段"（first-fit）。
% --------------------------------------------------------------------------
%
% 输入/输出含义与原函数保持一致：
%   lack_cpu/lack_mem/time_out 只要有一个为 true，则视为该节点部署失败（由上层回滚）
%

    lack_cpu = false;
    lack_mem = false;
    time_out = false;
    leaveNodeTime = arriveNodeTime;
    
    % 初始化当次节点消耗结构（记录本次VNF部署的节点资源消耗）
    node_consume = struct( ...
        'cpu_consume',    0, ...   % 本次节点CPU消耗（共享时为0）
        'memory_consume', 0, ...   % 本次节点内存消耗（共享时为0）
        'delay_consume',  0 ...    % 本次节点时延消耗（包括排队+处理）
    );

    node = nodes(place_node_id);
    T_node = size(node.cpu, 1);  % 仿真最大时间片（通常1500）

    % ---------------- 0) 到达越界：直接TIMEOUT ----------------
    if arriveNodeTime > T_node
        time_out = true;
        leaveNodeTime = T_node;
        return;
    end

    % ======================================================================
    % 1) VNF共享检查（最高优先级）
    % ======================================================================
    % 若当前节点有可共享的vnf，等到共享实例成功被处理即可前往下一节点。
    % ready 的判定：在该节点 tasks 中找到 (req_id, vnf_id) 对应的最早 t_end。
    ready_time = find_shared_ready_time(node, req_id, vnf_id);

    if ~isempty(ready_time)
        % 共享：不扣新资源、不占用处理窗口；但必须等到实例 ready
        leaveNodeTime = max(arriveNodeTime, ready_time);

        % TIMEOUT 判断
        if leaveNodeTime > T_node || leaveNodeTime > req.vnf_deadline(dest_idx, vnf_idx)
            time_out = true;
            return;
        end

        % 把"等待共享实例ready"的时间计入时延消耗（等待=leave-arrive，因为处理时长=0）
        node_delay = leaveNodeTime - arriveNodeTime;
        consume(req_id).delay_consume = consume(req_id).delay_consume + node_delay;
        
        % 共享情况下：CPU/内存消耗为0，只记录时延
        node_consume.cpu_consume = 0;
        node_consume.memory_consume = 0;
        node_consume.delay_consume = node_delay;

        return;
    end

    % ======================================================================
    % 2) 计算处理时长（方案A：到达即确定）
    % ======================================================================
    proc_duration = node.delay(arriveNodeTime);

    % ======================================================================
    % 3) FIFO排队：找到一个真实可用的处理窗口 [start, start+proc_duration)
    % ======================================================================
    [actual_start_time, wait_duration, ok] = fifo_find_start_time(node, arriveNodeTime, proc_duration);

    if ~ok
        % 找不到长度足够的空闲窗口，等价于"离开时间会超出仿真区间"
        time_out = true;
        leaveNodeTime = T_node;
        return;
    end

    leaveNodeTime = actual_start_time + proc_duration;

    % ======================================================================
    % 4) 超时判定（deadline + 仿真时域）
    % ======================================================================
    if leaveNodeTime > T_node
        time_out = true;
        leaveNodeTime = T_node;
        return;
    end
    if leaveNodeTime > req.vnf_deadline(dest_idx, vnf_idx)
        time_out = true;
        return;
    end

    % ======================================================================
    % 5) 资源检查（资源预留：arriveNodeTime ~ T_node）
    % ======================================================================
    % 注意：这是你原框架的"资源预留"语义：
    %   一旦该 VNF 在该节点接入成功，从 arriveNodeTime 起到仿真结束都占用CPU/MEM（不释放）。
    [lack_cpu, lack_mem] = check_node_reservation(node, arriveNodeTime, cpu_need, mem_need);
    if lack_cpu || lack_mem
        return;
    end

    % ======================================================================
    % 6) 提交资源扣减 + 动态时延更新
    % ======================================================================
    [nodes, consume] = commit_node_reservation(nodes, place_node_id, arriveNodeTime, cpu_need, mem_need, consume, req_id);

    % 把本次任务的"排队+处理"计入时延消耗
    node_delay = leaveNodeTime - arriveNodeTime;
    consume(req_id).delay_consume = consume(req_id).delay_consume + node_delay;
    
    % 记录本次VNF部署的节点消耗
    node_consume.cpu_consume = cpu_need;
    node_consume.memory_consume = mem_need;
    node_consume.delay_consume = node_delay;

    % ======================================================================
    % 7) 写入"可共享VNF"标记（从 ready 时刻开始）
    % ======================================================================
    % 【MOD-2】原先是从 arriveNodeTime 开始标记，这会导致"实例还没部署完就被共享"的矛盾。
    % 这里改为从 leaveNodeTime 开始标记，表示：部署完成后才可共享。
    nodes = mark_vnf_shareable(nodes, place_node_id, leaveNodeTime, req_id, vnf_id);

    % ======================================================================
    % 8) 维护 FIFO 工作状态表（work_status）与 free_flag
    % ======================================================================
    % 【MOD-1】work_status 改为结构体列向量，忙区间用半开区间 [start, leave)
    nodes = mark_work_status(nodes, place_node_id, actual_start_time, leaveNodeTime, ...
                             req_id, req.dest(dest_idx), dest_idx, vnf_idx, vnf_id);

    % 【MOD-3】free_flag 表示"当前时间轴上最早空闲的时间片索引"
    ff = find(nodes(place_node_id).work_status.req_id == 0, 1, 'first');
    if isempty(ff)
        ff = T_node + 1;  % 全忙：指向仿真结束之后
    end
    nodes(place_node_id).free_flag = ff;

    % ======================================================================
    % 9) 记录任务 tasks（用于后续统计/调度）
    % ======================================================================
    nodes = append_task(nodes, place_node_id, req, dest_idx, vnf_idx, vnf_id, actual_start_time, leaveNodeTime);
end




function [nodes, consume] = commit_node_reservation(nodes, node_id, arriveTime, cpu_need, mem_need, consume, req_id)
%COMMIT_NODE_RESERVATION  扣除 arriveTime:T_node 的资源，并更新 nodes.delay(t)

    T_node = size(nodes(node_id).cpu, 1);

    % consume：资源消耗只加一次（与你原版本一致）
    consume(req_id).cpu_consume    = consume(req_id).cpu_consume + cpu_need;
    consume(req_id).memory_consume = consume(req_id).memory_consume + mem_need;

    for tau = arriveTime:T_node
        nodes(node_id).cpu(tau) = nodes(node_id).cpu(tau) - cpu_need;
        nodes(node_id).mem(tau) = nodes(node_id).mem(tau) - mem_need;

        % 动态节点时延：CPU越紧张，处理越慢（沿用你原有形式）
        cap = nodes(node_id).cpu_cap;
        free = nodes(node_id).cpu(tau);
        free_rate = max(free / cap, 0.001);
        nodes(node_id).delay(tau) = round(nodes(node_id).base_delay / free_rate);
    end
end

function nodes = mark_vnf_shareable(nodes, node_id, readyTime, req_id, vnf_id)
%MARK_VNF_SHAREABLE  将该VNF实例标记为"从 readyTime 起可共享"
%
% nodes(node_id).vnf : T×requestNum×slot
% 这里沿用"slot"存放多个vnf实例id的做法：
%   - 若已存在同 vnf_id 的 slot，则复用该 slot
%   - 否则找第一个 0 slot 写入

    T_node = size(nodes(node_id).vnf, 1);

    if readyTime > T_node
        return;
    end

    vnf_row = squeeze(nodes(node_id).vnf(readyTime, req_id, :)).';
    slot = find(vnf_row == vnf_id, 1);
    if isempty(slot)
        slot = find(vnf_row == 0, 1);
    end
    if isempty(slot)
        % 若 slot 都满了，按你原逻辑其实应视为不可部署；
        % 但这里保持简单：直接占用第1个slot覆盖（你也可改为失败）
        slot = 1;
    end

    nodes(node_id).vnf(readyTime:T_node, req_id, slot) = vnf_id;
end

function nodes = mark_work_status(nodes, node_id, startTime, leaveTime, req_id, dest_id, dest_idx, vnf_idx, vnf_id)
%MARK_WORK_STATUS  在 work_status[startTime, leaveTime) 标记"正在处理"的任务
%
% 【MOD-1】使用直观结构体列向量：
%   work_status.req_id(t) = req_id
%   work_status.dest_id(t)= dest_id
%   work_status.vnf_id(t) = vnf_id
%   work_status.vnf_idx(t)= vnf_idx
%   work_status.dest_idx(t)=dest_idx
%
% 忙碌区间使用半开区间 [start, leave)：
%   - 任务处理用时 proc_duration
%   - leave = start + proc_duration
%   - 下一任务允许从 leave 开始

    if leaveTime <= startTime
        return;
    end

    t1 = startTime;
    t2 = leaveTime - 1;

    nodes(node_id).work_status.req_id(t1:t2)   = req_id;
    nodes(node_id).work_status.dest_id(t1:t2)  = dest_id;
    nodes(node_id).work_status.vnf_id(t1:t2)   = vnf_id;
    nodes(node_id).work_status.vnf_idx(t1:t2)  = vnf_idx;
    nodes(node_id).work_status.dest_idx(t1:t2) = dest_idx;
end

function nodes = append_task(nodes, node_id, req, dest_idx, vnf_idx, vnf_id, t_start, t_end)
%APPEND_TASK  追加一条任务记录到 nodes(node_id).tasks（struct数组）
%
% tasks 字段示例：
%   req_id, dest_idx, dest_id, vnf_idx, vnf_id, t_start, t_end

    dest_id = req.dest(dest_idx);

    newTask = struct( ...
        'req_id',   req.id, ...
        'dest_idx', dest_idx, ...
        'dest_id',  dest_id, ...
        'vnf_idx',  vnf_idx, ...
        'vnf_id',   vnf_id, ...
        't_start',  t_start, ...
        't_end',    t_end ...
    );

    if isempty(nodes(node_id).tasks)
        nodes(node_id).tasks = newTask;
    else
        nodes(node_id).tasks(end+1) = newTask;
    end
end


%[appendix]{"version":"1.0"}
%---
