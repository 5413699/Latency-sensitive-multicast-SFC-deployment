%[text] # sortRequestByDeadline
%[text] 将多播请求按照最长可接受时延从小到大排序
function sortedRequests = sortRequestByDeadline(requests)
% sortRequestByDeadline
% 根据 request.max_delay 从小到大排序请求集合
%
% 输入：
%   requests — 1×N 的结构体数组，每个含字段 max_delay
%
% 输出：
%   sortedRequests — 按时延升序排序后的结构体数组

    % 取出所有请求的 max_delay
    delays = [requests.max_delay];

    % 获取排序索引（升序）
    [~, idx] = sort(delays, 'ascend');

    % 按排序索引重新排列结构体数组
    sortedRequests = requests(idx);
end


%[appendix]{"version":"1.0"}
%---
