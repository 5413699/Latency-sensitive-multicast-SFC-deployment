%[text] # 初始化部署阶段必要的数据结构
function [fail_log, consume, nodes,plan] = initNecessaryStructure(sortedRequests, nodes)
%INITNECESSARYSTRUCTURE  初始化部署阶段必要的数据结构（含节点FIFO工作状态表）
%   nodes(n).work_status.req_id   : T×1，0=空闲，非0=忙（忙时存该任务的 req_id）
%   nodes(n).work_status.dest_id  : T×1，忙时存 dest_id
%   nodes(n).work_status.vnf_id   : T×1，忙时存 vnf_id
%   nodes(n).work_status.vnf_idx  : T×1，忙时存 vnf_idx（便于调试）
%   nodes(n).work_status.dest_idx : T×1，忙时存 dest_idx（便于调试）
%
% 同时维护：
%   nodes(n).free_flag : 标量，指向"当前时间轴上最早空闲的时间片索引"
%                       （实现上等价于 find(req_id==0,1,'first')）
% -------------------------------------------------------------------------
%
% 输入：
%   sortedRequests : 排序后的请求数组（struct array）
%   nodes          : 节点数组（struct array），至少需要 nodes(n).cpu 是 T×1
%
% 输出：
%   fail_log, consume, nodes : 初始化后的结构体
%

    requestNum = max([sortedRequests.id]);  % consume 按真实 req_id 索引

    % ---------------- fail_log：空结构体 ----------------
    % 说明：add_fail_row() 会往里面追加记录，这里只需要保证字段存在即可。
    fail_log = struct( ...
        'req_id',        {}, ...
        'dest_idx',      {}, ...
        'dest_id',       {}, ...
        'vnf_idx',       {}, ...
        'place_node_id', {}, ...
        'failed_link',   {}, ...
        'lack_bw',       {}, ...
        'lack_cpu',      {}, ...
        'lack_mem',      {}, ...
        'unschedulable', {}, ...
        'time_out',      {}  ...
    );

    % ---------------- consume：按 req_id 索引的消耗统计 ----------------
    % 主结构字段：accepted, cpu_consume, memory_consume, bandwidth_consume, delay_consume, e2eConsume
    % e2eConsume 是按 dest_id 索引的结构体数组，用于记录每个目的节点分支的详细消耗
    
    % 为每个请求预分配 e2eConsume
    e2eConsumeEmpty = struct( ...
        'dest_id',           [], ...
        'vnf_project',       [], ...   % 与 sortedPlan 的 vnfNode 对应
        'cpu_consume',       0, ...
        'memory_consume',    0, ...
        'bandwidth_consume', 0, ...
        'delay_consume',     0, ...
        'vnfconsume',        [] ...    % 结构体数组，记录每个 VNF 的详细消耗
    );
    
    consume = struct( ...
        'req_id',            num2cell(1:requestNum), ...          % 请求ID（方便索引和查询）
        'accepted',          num2cell(zeros(1,requestNum)), ...  % 1=接收,0=拒绝
        'cpu_consume',       num2cell(zeros(1,requestNum)), ...
        'memory_consume',    num2cell(zeros(1,requestNum)), ...
        'bandwidth_consume', num2cell(zeros(1,requestNum)), ...
        'delay_consume',     num2cell(zeros(1,requestNum)), ...
        'e2eConsume',        repmat({e2eConsumeEmpty}, 1, requestNum) ...  % 每个请求一个结构体数组
    );

    % ---------------- 节点 FIFO：work_status 初始化 ----------------
    T = size(nodes(1).cpu, 1);  % 通常为1500

    for n = 1:numel(nodes)
        nodes(n).work_status = struct();
        nodes(n).work_status.req_id   = zeros(T, 1);
        nodes(n).work_status.dest_id  = zeros(T, 1);
        nodes(n).work_status.vnf_id   = zeros(T, 1);
        nodes(n).work_status.vnf_idx  = zeros(T, 1);
        nodes(n).work_status.dest_idx = zeros(T, 1);

        % free_flag 指向"最早空闲时间片"
        nodes(n).free_flag = 1;
    end

    % ---------------- plan 初始化 ----------------
    % 初始化为一个 0x0 的结构体数组，但预先定义好字段名。
    % 这样在后续代码中可以直接使用 plan(end+1) = newPlan 而不会报字段不匹配错误。
    plan = struct( ...
        'req_id',    {}, ...
        'placeLinks', {}, ...
        'vnfNode',    {}  ...
    );




end






%[appendix]{"version":"1.0"}
%---
