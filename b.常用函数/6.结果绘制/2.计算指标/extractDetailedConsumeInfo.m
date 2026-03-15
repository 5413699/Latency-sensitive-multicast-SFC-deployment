function detailInfo = extractDetailedConsumeInfo(consume, req_id)
%EXTRACTDETAILEDCONSUMEINFO  提取指定请求的详细消耗信息
%
% 输入：
%   consume : sfcMapping 运行后保存的 consume 结构体数组
%   req_id  : 请求ID
%
% 输出：
%   detailInfo : 结构体，包含：
%     .req_id           : 请求ID
%     .accepted         : 是否被接受 (0/1)
%     .cpu_consume      : 总CPU消耗
%     .memory_consume   : 总内存消耗
%     .bandwidth_consume: 总带宽消耗
%     .delay_consume    : 总时延消耗
%     .e2eConsume       : 按目的节点分组的详细消耗（结构体数组）
%       每个e2eConsume元素包含：
%         .dest_id           : 目的节点ID
%         .vnf_project       : VNF部署方案（与sortedPlan对应）
%         .cpu_consume       : 本分支CPU消耗
%         .memory_consume    : 本分支内存消耗
%         .bandwidth_consume : 本分支带宽消耗
%         .delay_consume     : 本分支时延消耗
%         .vnfconsume        : 本分支各VNF的详细消耗（结构体数组）
%           每个vnfconsume元素包含：
%             .vnfid             : VNF ID
%             .placeVnfLinks     : 经过的链路列表
%             .placeVnfNode      : 部署的节点ID
%             .cpu_consume       : 本VNF的CPU消耗（共享时为0）
%             .memory_consume    : 本VNF的内存消耗（共享时为0）
%             .bandwidth_consume : 本VNF的带宽消耗（共享时为0）
%             .delay_consume     : 本VNF的时延消耗
%
% 示例用法：
%   % 查看请求23的详细消耗
%   info = extractDetailedConsumeInfo(consume, 23);
%   disp(info);
%
%   % 查看请求23第一个目的节点的各VNF消耗
%   if info.accepted && ~isempty(info.e2eConsume)
%       disp(info.e2eConsume(1).vnfconsume);
%   end

    detailInfo = struct();
    
    if req_id > numel(consume) || req_id < 1
        warning('请求ID %d 超出范围', req_id);
        detailInfo.req_id = req_id;
        return;
    end
    
    c = consume(req_id);
    
    % 使用consume中存储的req_id（如果存在），否则使用传入的req_id
    if isfield(c, 'req_id')
        detailInfo.req_id = c.req_id;
    else
        detailInfo.req_id = req_id;
    end
    
    detailInfo.accepted = c.accepted;
    detailInfo.cpu_consume = c.cpu_consume;
    detailInfo.memory_consume = c.memory_consume;
    detailInfo.bandwidth_consume = c.bandwidth_consume;
    detailInfo.delay_consume = c.delay_consume;
    
    % 检查是否存在e2eConsume字段
    if isfield(c, 'e2eConsume')
        detailInfo.e2eConsume = c.e2eConsume;
    else
        detailInfo.e2eConsume = [];
    end
end
