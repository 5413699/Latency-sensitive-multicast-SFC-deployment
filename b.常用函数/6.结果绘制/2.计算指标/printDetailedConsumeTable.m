function printDetailedConsumeTable(consume, req_ids)
%PRINTDETAILEDCONSUMETABLE  打印请求的详细消耗信息表格
%
% 输入：
%   consume : sfcMapping 运行后保存的 consume 结构体数组
%   req_ids : 要打印的请求ID数组（可选，默认打印所有已接受的请求）
%
% 输出：
%   控制台打印格式化的消耗信息表格
%
% 示例用法：
%   % 打印所有已接受请求的消耗
%   printDetailedConsumeTable(consume);
%
%   % 打印指定请求的消耗
%   printDetailedConsumeTable(consume, [23, 41, 22]);

    if nargin < 2 || isempty(req_ids)
        % 找出所有已接受的请求ID
        req_ids = [];
        for i = 1:numel(consume)
            if consume(i).accepted == 1
                % 优先使用consume中存储的req_id
                if isfield(consume, 'req_id') && ~isempty(consume(i).req_id)
                    req_ids(end+1) = consume(i).req_id;
                else
                    req_ids(end+1) = i;
                end
            end
        end
    end
    
    fprintf('\n========== 请求消耗汇总表 ==========\n');
    fprintf('%-8s %-10s %-12s %-15s %-18s %-15s\n', ...
        'req_id', 'accepted', 'cpu_consume', 'memory_consume', 'bandwidth_consume', 'delay_consume');
    fprintf('%s\n', repmat('-', 1, 80));
    
    for i = 1:numel(req_ids)
        rid = req_ids(i);
        if rid > numel(consume) || rid < 1
            continue;
        end
        c = consume(rid);
        fprintf('%-8d %-10d %-12.2f %-15.2f %-18.2f %-15.2f\n', ...
            rid, c.accepted, c.cpu_consume, c.memory_consume, c.bandwidth_consume, c.delay_consume);
    end
    
    % 打印详细的e2eConsume信息
    fprintf('\n');
    for i = 1:numel(req_ids)
        rid = req_ids(i);
        if rid > numel(consume) || rid < 1
            continue;
        end
        c = consume(rid);
        
        if ~isfield(c, 'e2eConsume') || isempty(c.e2eConsume)
            continue;
        end
        
        if c.accepted == 0
            continue;
        end
        
        fprintf('\n========== 请求 %d 的分支详细消耗 ==========\n', rid);
        fprintf('%-10s %-12s %-15s %-18s %-15s\n', ...
            'dest_id', 'cpu_consume', 'memory_consume', 'bandwidth_consume', 'delay_consume');
        fprintf('%s\n', repmat('-', 1, 70));
        
        for d = 1:numel(c.e2eConsume)
            e = c.e2eConsume(d);
            if e.dest_id == 0
                continue;
            end
            fprintf('%-10d %-12.2f %-15.2f %-18.2f %-15.2f\n', ...
                e.dest_id, e.cpu_consume, e.memory_consume, e.bandwidth_consume, e.delay_consume);
        end
        
        % 打印每个分支的VNF详细消耗
        for d = 1:numel(c.e2eConsume)
            e = c.e2eConsume(d);
            if e.dest_id == 0 || isempty(e.vnfconsume)
                continue;
            end
            
            fprintf('\n  --- 目的节点 %d 的VNF详细消耗 ---\n', e.dest_id);
            fprintf('  %-8s %-15s %-12s %-12s %-15s %-18s %-15s\n', ...
                'vnfid', 'placeVnfNode', 'cpu_consume', 'mem_consume', 'bw_consume', 'delay_consume', 'placeVnfLinks');
            fprintf('  %s\n', repmat('-', 1, 95));
            
            for v = 1:numel(e.vnfconsume)
                vnf = e.vnfconsume(v);
                if isempty(vnf.placeVnfLinks)
                    linksStr = '[]';
                else
                    linksStr = sprintf('[%s]', strjoin(string(vnf.placeVnfLinks), ','));
                end
                fprintf('  %-8d %-15d %-12.2f %-12.2f %-15.2f %-18.2f %s\n', ...
                    vnf.vnfid, vnf.placeVnfNode, vnf.cpu_consume, vnf.memory_consume, ...
                    vnf.bandwidth_consume, vnf.delay_consume, linksStr);
            end
        end
    end
    
    fprintf('\n');
end
