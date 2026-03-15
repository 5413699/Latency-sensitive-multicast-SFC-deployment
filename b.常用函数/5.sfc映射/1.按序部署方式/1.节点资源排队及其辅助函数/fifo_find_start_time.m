%[text] # fifo\_find\_start\_time
function [startTime, waitTime, ok] = fifo_find_start_time(node, arriveTime, proc_duration)
%FIFO_FIND_START_TIME  FIFO/FCFS：为任务寻找一个"真实可用"的开始时间
%
% 【MOD-3】你指出的关键问题是正确的：
%   仅用 start=max(arrive, free_flag) 不能保证后续 proc_duration 个时间片都空闲，
%   也不能利用时间轴上的空闲间隙。
%
% 因此这里改为：
%   - 从 arriveTime 开始往后扫，寻找最早的连续空闲窗口（长度=proc_duration）
%   - 空闲判定基于 work_status.req_id == 0
%
% 这是一种"first-fit on timeline"的实现。
%
% 输出：
%   startTime : 找到的实际开始时间
%   waitTime  : startTime - arriveTime
%   ok        : 是否找到（找不到说明超出仿真时域）

    T = numel(node.work_status.req_id);

    % 处理时长为0：等价于无需占用处理窗口（start=arrive）
    if proc_duration == 0
        startTime = arriveTime;
        waitTime  = 0;
        ok = true;
        return;
    end

    latestStart = T - proc_duration + 1;
    if arriveTime > latestStart
        ok = false;
        startTime = T;
        waitTime = 0;
        return;
    end

    busy = node.work_status.req_id;  % 0=空闲，非0=忙

    startTime = 0;
    ok = false;

    % 从 arriveTime 开始向后找长度足够的空闲段
    for t = arriveTime:latestStart
        if all(busy(t:t+proc_duration-1) == 0)
            startTime = t;
            ok = true;
            break;
        end
    end

    if ~ok
        startTime = T;
        waitTime = 0;
        return;
    end

    waitTime = startTime - arriveTime;
end

%[appendix]{"version":"1.0"}
%---
