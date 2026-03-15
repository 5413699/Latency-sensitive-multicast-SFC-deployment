function [nodes, links, requests, fail_log, success, consume, leaveNodeTime, vnf_consume] = deploy_vnf( ...
    nodes, links, requests, ...
    req_idx, dest_idx, vnf_idx, ...
    place_node_id, place_link_ids, t, ...
    fail_log, consume)
%DEPLOY_VNF  在时间片 t 为多播请求的一个分支部署一个VNF（含节点内FIFO排队）
%
% 该函数对应《实验构思251226版.md》中"步骤6：部署"。
% 你原来的 deploy_vnf 做了两件事：
%   (1) 链路：带宽共享 + 资源检查 + 更新（linkResourceCheckAndUpdate）
%   (2) 节点：VNF共享 + 资源检查 + 更新（nodeResourceCheckAndUpdate）
%
% 本次重构不改变总体流程，只把"节点侧"替换为：
%   - 带资源预留的 FIFO 排队模型
%   - 处理时延采用方案A：在 arriveNodeTime 时刻决定，并在排队期间保持不变
%
% 输入：
%   nodes, links, requests : 当前系统状态（会被原地更新）
%   dest_idx, vnf_idx     : 第几个目的节点、第几个VNF
%   place_node_id         : 本VNF部署的节点
%   place_link_ids        : 到达该节点所经过的链路列表
%   t                     : 分支当前时间（上一跳/上一VNF的离开时间）
%   fail_log, consume     : 统计结构
%
% 输出：
%   success      : 1=成功，0=失败
%   leaveNodeTime: 该 VNF 在节点处理完（含排队等待）的离开时间
%   vnf_consume  : 本次VNF部署的具体消耗（结构体），字段包括：
%                  vnfid, placeVnfLinks, placeVnfNode, cpu_consume,
%                  memory_consume, bandwidth_consume, delay_consume

    % 默认失败
    success = 0;
    leaveNodeTime = t;
    
    % 初始化本次VNF部署的消耗结构
    vnf_consume = struct( ...
        'vnfid',             0, ...
        'placeVnfLinks',     [], ...
        'placeVnfNode',      0, ...
        'cpu_consume',       0, ...
        'memory_consume',    0, ...
        'bandwidth_consume', 0, ...
        'delay_consume',     0 ...
    );

    % ---------- 请求与资源需求 ----------
    req      = requests(req_idx);
    req_id   = req.id;            % 真实请求ID（用于 consume、共享标记）
    vnf_id   = req.vnf(vnf_idx);
    bw_need  = req.bandwidth;
    cpu_need = req.cpu;
    mem_need = req.memory;
    
    % 记录VNF基本信息
    vnf_consume.vnfid = vnf_id;
    vnf_consume.placeVnfLinks = place_link_ids;
    vnf_consume.placeVnfNode = place_node_id;

    % ==============================================================
    % 1) 链路阶段：带宽共享 + 链路资源检查与更新
    % ==============================================================
    usedFlag = zeros(numel(place_link_ids), 1);
    for k = 1:numel(place_link_ids)
        e = place_link_ids(k);
        usedFlag(k) = links(e).request(t, req_id);  % 用 req_id 做共享维度
    end

    [links, lack_bw, time_out, arriveNodeTime, consume, failed_link, link_consume] = ...
        linkResourceCheckAndUpdate(links, place_link_ids, req_id, req, t, bw_need, usedFlag, consume);

    if lack_bw
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, 0, failed_link, 0,0,1,0,0);
        return;
    end
    if time_out
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, 0, failed_link, 0,0,0,1,0);
        return;
    end

    % ==============================================================
    % 2) 节点阶段：VNF共享优先 + FIFO排队 + 资源预留
    % ==============================================================
    [nodes, lack_cpu, lack_mem, time_out, leaveNodeTime, consume, node_consume] = ...
        nodeResourceCheckAndUpdate(nodes, place_node_id, ...
                                   req, req_id, dest_idx, vnf_idx, vnf_id, ...
                                   arriveNodeTime, cpu_need, mem_need, consume);

    if lack_cpu
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, place_node_id, 0, 1,0,0,0,0);
        return;
    end
    if lack_mem
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, place_node_id, 0, 0,1,0,0,0);
        return;
    end
    if time_out
        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, place_node_id, 0, 0,0,0,1,0);
        return;
    end

    % ==============================================================
    % 3) 成功：整合本次VNF部署的消耗信息
    % ==============================================================
    vnf_consume.cpu_consume = node_consume.cpu_consume;
    vnf_consume.memory_consume = node_consume.memory_consume;
    vnf_consume.bandwidth_consume = link_consume.bandwidth_consume;
    vnf_consume.delay_consume = link_consume.delay_consume + node_consume.delay_consume;
    
    success = 1;
end
