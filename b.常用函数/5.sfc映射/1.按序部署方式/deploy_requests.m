%[text] # deploy\_requests
%[text] 部署多播请求集，记录资源消耗和服务拒绝原因
%[text] 快速测试
% req_idx = 1;%1
% dest_idx = 1;%27
% vnf_idx = 1;%4
%[text] 
function [nodes, links, requests, consume, fail_log] = deploy_requests( ...
    nodes, links, requests, sortedPlan, consume, fail_log)

%DEPLOY_REQUESTS_TRANSACTIONAL  步骤6：逐请求部署（带事务回滚）
%
% 【功能】
%   对 deployPlan 中的每个请求（req_idx）做完整的多播分支部署：
%     - 对每个 dest 分支，从 t_now=1 开始依次部署 vnf1..vnfK
%     - 每次部署一个 VNF 调用：deploy_vnf(...)
%
%   若该请求任一分支任一 VNF 部署失败：
%     - 回滚 nodes / links / consume(req_id)
%     - consume(req_id).accepted = 0
%     - fail_log 只保留该请求的"第一个失败点"记录
%
%   若全部成功：
%     - consume(req_id).accepted = 1
%
% 【输入】
%   nodes, links      : 当前网络状态（会被更新）
%   requests          : 请求数组
%   deployPlan        : 每个 req_idx 的部署方案（treeproject / vnf_project）
%   consume, fail_log : 统计结构
%
% 【输出】
%   nodes, links, requests, consume, fail_log : 更新后的系统状态与统计
%
% 【注意】
%   1) 本函数假设 deployPlan 与 requests 的顺序/长度一致：
%        deployPlan(i) 对应 requests(i)
%   2) 本函数只负责"请求级事务控制"，具体链路/节点逻辑在 deploy_vnf 内部完成。
%

    for req_idx = 1:numel(sortedPlan)

        % 当前请求（req_idx 是 requests 的索引）
        req    = requests(req_idx);
        req_id = req.id;

        % ===================== 事务快照（用于回滚） =====================
        nodes0   = nodes;
        links0   = links;
        consume0 = consume(req_id);
        failLen0 = numel(fail_log);

        request_failed = false;

        % 有效目的节点列表（去掉 0）
        dests    = req.dest(req.dest > 0);
        dest_num = numel(dests);
        vnf_num  = numel(req.vnf);

        % 记录每个分支的结束时间（用于计算端到端时延）
        branch_end_time = zeros(dest_num, 1);

        % 初始化本请求的 e2eConsume 数组（按目的节点索引）
        e2eConsume_arr = repmat(struct( ...
            'dest_id',           0, ...
            'vnf_project',       [], ...
            'cpu_consume',       0, ...
            'memory_consume',    0, ...
            'bandwidth_consume', 0, ...
            'delay_consume',     0, ...
            'vnfconsume',        [] ...
        ), dest_num, 1);

        % ===================== 遍历每个多播分支 =====================
        for dest_idx = 1:dest_num

            % 每个分支从 t=1 开始（上一跳/上一VNF离开时间）
            t_now = 1;
            
            % 初始化本分支的目的节点信息
            e2eConsume_arr(dest_idx).dest_id = dests(dest_idx);
            e2eConsume_arr(dest_idx).vnf_project = sortedPlan(req_idx).treeproject(dest_idx).vnf_project;
            
            % 初始化本分支的 vnfconsume 数组
            vnfconsume_arr = [];

            % ========== 顺序部署 vnf1..vnfK（不做EDF，只做FIFO排队） ==========
            for vnf_idx = 1:vnf_num

                item = sortedPlan(req_idx).treeproject(dest_idx).vnf_project(vnf_idx);

                [nodes, links, requests, fail_log, success, consume, leaveNodeTime, vnf_consume] = ...
                    deploy_vnf(nodes, links, requests, ...
                               req_idx, dest_idx, vnf_idx, ...
                               item.placeVnfNode, item.placeVnfLinks, t_now, ...
                               fail_log, consume);

                if success == 0
                    request_failed = true;
                    break;  % break vnf loop
                end
                
                % 记录本次VNF部署的消耗
                if isempty(vnfconsume_arr)
                    vnfconsume_arr = vnf_consume;
                else
                    vnfconsume_arr(end+1) = vnf_consume;
                end
                
                % 累加到本分支的消耗
                e2eConsume_arr(dest_idx).cpu_consume = e2eConsume_arr(dest_idx).cpu_consume + vnf_consume.cpu_consume;
                e2eConsume_arr(dest_idx).memory_consume = e2eConsume_arr(dest_idx).memory_consume + vnf_consume.memory_consume;
                e2eConsume_arr(dest_idx).bandwidth_consume = e2eConsume_arr(dest_idx).bandwidth_consume + vnf_consume.bandwidth_consume;
                e2eConsume_arr(dest_idx).delay_consume = e2eConsume_arr(dest_idx).delay_consume + vnf_consume.delay_consume;

                % 下一段VNF的起始时间 = 本段离开时间（含排队等待）
                t_now = leaveNodeTime;
            end
            
            % 记录本分支的 vnfconsume 数组
            if ~request_failed
                e2eConsume_arr(dest_idx).vnfconsume = vnfconsume_arr;
            end

            % ========== 最后一跳：从最后一个 VNF 节点到 dest ==========
            % 如果最后一个 VNF 不在 dest 上，需要执行最后一段链路传输
            if ~request_failed && isfield(sortedPlan(req_idx).treeproject(dest_idx), 'final_links')
                final_links = sortedPlan(req_idx).treeproject(dest_idx).final_links;
                if ~isempty(final_links)
                    % 检查链路共享标志
                    usedFlag = zeros(numel(final_links), 1);
                    for k = 1:numel(final_links)
                        e = final_links(k);
                        usedFlag(k) = links(e).request(t_now, req_id);
                    end

                    % 执行链路资源检查与更新
                    [links, lack_bw, time_out, arriveDestTime, consume, failed_link, final_link_consume] = ...
                        linkResourceCheckAndUpdate(links, final_links, req_id, req, t_now, req.bandwidth, usedFlag, consume);

                    if lack_bw
                        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_num+1, 0, failed_link, 0,0,1,0,0);
                        request_failed = true;
                    elseif time_out
                        fail_log = add_fail_row(fail_log, req, dest_idx, vnf_num+1, 0, failed_link, 0,0,0,1,0);
                        request_failed = true;
                    else
                        t_now = arriveDestTime;
                        % 累加最后一跳的带宽和时延消耗到本分支
                        e2eConsume_arr(dest_idx).bandwidth_consume = e2eConsume_arr(dest_idx).bandwidth_consume + final_link_consume.bandwidth_consume;
                        e2eConsume_arr(dest_idx).delay_consume = e2eConsume_arr(dest_idx).delay_consume + final_link_consume.delay_consume;
                    end
                end
            end

            % 记录该分支的结束时间（到达 dest 的时间）
            if ~request_failed
                branch_end_time(dest_idx) = t_now;
            end

            if request_failed
                break;  % break dest loop
            end
        end

        % ===================== 成功/失败收尾 =====================
        if request_failed
            % 回滚：当作这个请求从没发生
            nodes = nodes0;
            links = links0;

            consume(req_id) = consume0;
            consume(req_id).accepted = 0;

            % fail_log：只保留"第一个失败点"
            if numel(fail_log) > failLen0 + 1
                fail_log = fail_log(1:failLen0+1);
            end

        else
            consume(req_id).accepted = 1;
            % 记录分支结束时间和端到端时延到 requests 结构体
            requests(req_idx).branch_end_time = branch_end_time;
            requests(req_idx).e2e_delay = max(branch_end_time) - 1;  % 减1是因为从t=1开始
            
            % 记录详细的 e2eConsume 到 consume 结构
            consume(req_id).e2eConsume = e2eConsume_arr;
        end
    end
end


%[appendix]{"version":"1.0"}
%---
