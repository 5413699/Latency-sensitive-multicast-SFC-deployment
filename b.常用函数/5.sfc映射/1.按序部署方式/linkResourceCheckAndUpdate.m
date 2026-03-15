%[text] # linkResourceCheckAndUpdate
%[text] 在进行资源检查时，要求按时间逐个链路检查资源是否符合要求：
%[text] 情景：在1时刻，为请求1的第2个目的节点（16-6）放置vnf8， 节点16-6的最短路是16-13-8-7-4-6 ，测试将其放在8号节点上，经过的链路编号\[48,36\]，假设48号链路在t时刻时延为links(48).delay(t)；
%[text] 链路检查示例：
%[text] 检查1~（1+links(48).delay(1)）时间片内，links(48).bandwith(t)是否均大于bw\_need 检查\[1+links(48).delay(1))\]~\[1+links(48).delay(1)+links(36).delay(1+links(48).delay(1))\]时间片内，links(36).bandwith(t)是否均大于bw\_need 
function [links, lack_bw, time_out, arriveNodeTime, consume, failed_link, link_consume] = ...
    linkResourceCheckAndUpdate(links, place_link_ids, req_id, req, t, bw_need, usedFlag, consume)
% linkResourceCheckAndUpdate
% 按"时间片+链路时延"逐条检查带宽，并根据共享/不共享更新链路带宽。
% 输入：
%   links：链路结构体数组，含字段 bandwidth(Tx1)，delay(Tx1)
%   place_link_ids：本次经过的链路编号向量，如[48 36]
%   t:起始时间片
%   bw_need:该请求在此路径上的带宽需求
%   usedFlag：共享标志
%           可以是标量：0=本请求在这些链路上还没占带宽；1=已经占过（完全共享）
%           -也可以是与 place_link_ids 同尺寸的向量，对每条链路单独指定
%
% 输出：
% links资源更新后的链路结构体数组
% lack_bw是否存在带宽不足
% time_out是否时间超出仿真范围
% arriveNodeTime ：通过所有链路后，到达目标节点的时间片

    lack_bw        = false;
    time_out       = false;
    arriveNodeTime = t;
    failed_link    = 0;
    
    % 初始化当次链路消耗结构（记录本次VNF部署的链路资源消耗）
    link_consume = struct( ...
        'bandwidth_consume', 0, ...   % 本次链路带宽消耗（共享时为0）
        'delay_consume',     0 ...    % 本次链路时延消耗
    );

    if isempty(place_link_ids)
        return;
    end

    % 假设所有链路的时间片长度一致，最大时间片取第一个链路的长度(1500)
    T_link = size(links(1).bandwidth, 1);
    t_curr = t;

    
    for idx = 1:numel(place_link_ids)
        e = place_link_ids(idx);
        share_this_link = usedFlag(idx);

        % 若超过仿真总时长，把 t_curr 截断
        if t_curr > T_link
            time_out    = true;
            failed_link = e;
            arriveNodeTime = T_link;
            return;
        end

        delay_e = links(e).delay(t_curr);
        t_end   = t_curr + delay_e;

        % 若超过仿真总时长，把 t_end 截断
        if t_end > T_link
            time_out    = true;
            failed_link = e;
            arriveNodeTime = T_link;
            return;
        end

        % % 若超过请求最大时延，拒绝该请求
        if t_end > req.max_delay
            time_out    = true;
            failed_link = e;
            arriveNodeTime = T_link;
            return;
        end

        if ~share_this_link
            % 带宽资源约束检查：从 t_curr 到 T_link
            for tau = t_curr:T_link
                if links(e).bandwidth(tau) < bw_need
                    lack_bw     = true;
                    failed_link = e;
                    arriveNodeTime = t_end;
                    return;
                end
            end
            % 更新资源消耗（总消耗 + 本次消耗）
            consume(req_id).bandwidth_consume = consume(req_id).bandwidth_consume + bw_need;
            link_consume.bandwidth_consume = link_consume.bandwidth_consume + bw_need;
            
            % 更新链路资源与链路时延
            for tau = t_curr:T_link
                links(e).bandwidth(tau) = links(e).bandwidth(tau) - bw_need;
                links(e).request(tau, req_id) = 1;

                % 动态时延：带宽越紧张，时延越大
                cap = links(e).bandwidth_cap;
                free = links(e).bandwidth(tau);
                free_rate = max(free/cap, 0.001);
                links(e).delay(tau) = round(links(e).base_delay / free_rate);
            end
        end
        % 无论是否共享，都要累加本次链路的时延消耗
        % （共享链路也会有传输时延）

        % 如果该链路已经是共享链路，无需检查资源约束，更新消耗和时延
        t_curr = t_end;
    end
    % 所有链路都检查完，当前时间就是到达节点时间
    arriveNodeTime = t_curr;
    
    % 计算本次链路时延消耗
    link_delay = arriveNodeTime - t;
    consume(req_id).delay_consume = consume(req_id).delay_consume + link_delay;
    link_consume.delay_consume = link_delay;
end


%[appendix]{"version":"1.0"}
%---
