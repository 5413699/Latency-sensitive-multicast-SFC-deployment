%[text] # generate\_request：多播请求生成
%[text] 
%[text] 此函数每次运行，生成requests\_num个带时延约束的多播业务
%[text]  输入参量：
%[text] - id：请求id
%[text] - nodes：节点信息 \
%[text] 输出参量：
%[text] - requests：（1\*业务数）的结构体，包含字段：id,source,dest,vnf,bw\_origin,，cpu\_origin，nr\_origin，时延 \
function requests = generate_requests(requests_num,nodes, ...
    destNode_count, vnftype_num, vnf_num, ...
    maxbw, minbw, maxnr, minnr, maxt, mint)

% —— 每一组业务，先"预分配"好结构体数组 ——
requests(1, requests_num) = struct( ...
        'id',            [], ...
        'source',        [], ...    
        'dest',          [], ...
        'vnf',           [], ...
        'bandwidth',     [], ...
        'cpu',           [], ...
        'memory',        [], ...
        'max_delay',     [], ...
        'vnf_deadline',  [] ...
);

for i = 1:requests_num % 对每组多播请求
    node_num = length(nodes);

    % === 源 / 宿节点 ===
    temp_num = destNode_count + 1;
    temp = randperm(node_num, temp_num);

    source = temp(1);          % 源节点
    dest   = temp(2:end);      % 目的节点集合
    clear temp;

    % === VNF 集合 ===
    temp = randperm(vnftype_num);
    vnf  = temp(1:vnf_num);
    clear temp;

    % === 资源需求 ===
    bw_origin     = randi([minbw,maxbw],1,1);
    cpu_origin    = randi([minnr,maxnr],1,1);
    memory_origin = randi([minnr,maxnr],1,1);

    % === 端到端最大容忍时延 ===
    max_delay = randi([mint,maxt],1,1);




    % === 每个 VNF 的局部 deadline 设计 ===
    % slice 依然是平均切片，建议先保留小数精度，在赋值时再取整
    slice = max_delay / vnf_num; 
    
    vnf_deadline = zeros(destNode_count, vnf_num);
    
    for d = 1:destNode_count
        for k = 1:vnf_num
            if k == vnf_num
                % 最后一个 VNF：必须强制等于 max_delay
                % 这是为了保证整条链绝对不超时
                vnf_deadline(d,k) = max_delay;
            else
                % 中间 VNF：给予 4/3 的宽限 (Relaxation)
                % 公式：平均时间 * k * 1.33
                relaxed_val = k * slice * 4 / 3;
                
                % 是中间节点，deadline不能超过总时延 max_delay
                % 使用 min 函数进行截断 (Clamping)
                vnf_deadline(d,k) = min(relaxed_val, max_delay);
                
                % 仿真系统只能接受整数时间片
                vnf_deadline(d,k) = floor(vnf_deadline(d,k));
            end
        end
    end






    

    % === 填结构体 ===
    requests(i).id        = i;
    requests(i).source    = source;
    requests(i).dest      = dest;
    requests(i).vnf       = vnf;
    requests(i).bandwidth  = bw_origin;
    requests(i).cpu       = cpu_origin;
    requests(i).memory    = memory_origin;
    requests(i).max_delay = max_delay;
    requests(i).vnf_deadline = vnf_deadline;     % 新增：每个目的节点、每个 VNF 的局部 deadline

end
end




%[appendix]{"version":"1.0"}
%---
