function [req_ids, acceptedFlag, accepted_req_ids] = extractAcceptedInfo(requests, consume)
%EXTRACTACCEPTEDINFO  根据 requests 的部署顺序提取“是否接收”序列
%
% 输入：
%   requests : sfcMapping 运行后保存的 requests（通常是 sortedRequests）
%   consume  : initNecessaryStructure 初始化并在部署中更新
%
% 输出：
%   req_ids          : N×1，请求ID（按 requests 的顺序）
%   acceptedFlag     : N×1，0/1
%   accepted_req_ids : A×1，所有 accepted 的请求ID（按出现顺序）

    req_ids = [requests.id].';

    N = numel(req_ids);
    acceptedFlag = zeros(N,1);
    for i = 1:N
        rid = req_ids(i);
        acceptedFlag(i) = consume(rid).accepted;
    end

    accepted_req_ids = req_ids(acceptedFlag == 1);
end
