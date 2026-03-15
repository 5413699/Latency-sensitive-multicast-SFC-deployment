%[text] # KShortestPath\_new
%[text] kShortestPath优化实现
%[text] K最短路算法 (Yen's Algorithm)
%[text] 经过优化的版本，主要减少了netCostMatrix的重复复制。
%[text] 严格保证输入输出与原始版本一致。
function [shortestPaths, totalCosts] = KShortestPath_new(netCostMatrix, source, destination, k_paths)


% 输入参数校验
if source > size(netCostMatrix,1) || destination > size(netCostMatrix,1) || source <= 0 || destination <= 0
    warning('源节点或目标节点不在网络成本矩阵范围内，或索引无效。');
    shortestPaths={}; % 返回空cell数组以保持一致性
    totalCosts=[];
    return;
end

if k_paths <= 0
    shortestPaths={};
    totalCosts=[];
    return;
end

%---------------------INITIALIZATION---------------------
k=1; % 已找到的最短路径计数

% P: 存储所有已生成候选路径的单元格数组。
%    P{path_id, 1} = path_vector (路径向量)
%    P{path_id, 2} = cost (路径成本)
P = {}; 

% S: 存储生成对应P中路径所使用的偏离顶点(spur node)。
%    S(path_id) = spur_node_value (偏离顶点的节点编号)
S = []; % 将根据path_id动态增长

% X: 候选路径池 (Yen算法中的B集合)。
%    X是一个列单元格数组, 每个单元格是 {path_id_in_P; path_vector; path_cost}
X = {}; 

shortestPaths = {}; % 存储最终找到的k条最短路径
totalCosts = [];    % 存储最终k条最短路径的成本

% 1. 计算从源到目标的第一条最短路径 (k=1)
[path1, cost1] = dijkstra(netCostMatrix, source, destination); % 假设 dijkstra 函数已存在且可用

if isempty(path1)
    % 如果没有路径，则直接返回空的shortestPaths和totalCosts
    return; 
else
    path_number_counter = 1; % P中路径的唯一编号生成器
    
    P{path_number_counter,1} = path1; 
    P{path_number_counter,2} = cost1; 
    
    % current_P_path_number 指向 P 中那条作为当前第 k 条最短路径 (或生成下一批候选路径的基础路径) 的路径的编号
    current_P_path_number = path_number_counter; 
    
    % 对于第一条最短路径，其“偏离顶点”可以认为是源节点本身。
    % 这是Yen算法中用于确定下一轮偏离起始点的一种常见处理方式。
    if path_number_counter > length(S) % 确保S数组足够大 (MATLAB会自动扩展)
        S(path_number_counter) = 0; % 仅为演示，MATLAB会自动处理
    end
    S(path_number_counter) = path1(1); % 记录偏离顶点
    
    shortestPaths{k} = path1;
    totalCosts(k) = cost1;
    
    % X 初始为空。它将在主循环中被填充新的候选路径，并从中选择下一条最短路径。
    % 原始代码在这里将第一个路径的信息放入X，但其管理方式略有不同。
    % 严格遵循原始代码：X在主循环内填充和选择。
    % current_P_path_number (对应原current_P) 是关键，它指向P中最新的最短路径。
end

% 创建 netCostMatrix 的一个工作副本。这是主要的优化点。
% 所有临时的图修改将在这个副本上进行，并在每次Dijkstra调用后恢复。
temp_netCostMatrix = netCostMatrix; 

%--------------------MAIN LOOP------------------------
% 当已找到的路径数 k 小于要求的 k_paths，并且候选池X中还有路径时继续。
% (注意：原始代码的X判空在while条件中，这里在循环末尾选取前判断)
while (k < k_paths)
    
    % path_k_minus_1 是 P_k-1, 即上一条加入 shortestPaths 的路径。
    % 它的路径向量存储在 P{current_P_path_number, 1}。
    % 这是原始代码中的 P_ (P下划线)。
    path_k_minus_1_vector = P{current_P_path_number, 1}; 
    
    % w 是用于生成 path_k_minus_1 的偏离顶点。
    % 这是原始代码中的 w = S(current_P)。
    spur_node_value_for_pk_minus_1 = S(current_P_path_number);
    
    % 在 path_k_minus_1_vector 中找到 spur_node_value_for_pk_minus_1 的索引。
    % 原始代码使用一个for循环查找，这里用find等效替换。
    w_idx_in_pk_minus_1 = find(path_k_minus_1_vector == spur_node_value_for_pk_minus_1, 1, 'first');
    
    if isempty(w_idx_in_pk_minus_1)
        % 理论上不应发生，如果S和P被正确维护。
        warning('KShortestPath:SpurNodeNotFound', '在基础路径中未找到预期的偏离顶点。算法可能存在问题。');
        break; % 终止循环
    end

    % 迭代 path_k_minus_1_vector：从 w_idx_in_pk_minus_1 开始，到倒数第二个节点，
    % 依次作为新的偏离顶点 (current_spur_node) 来生成候选路径。
    % 这是原始代码中的 for index_dev_vertex = w_index_in_path : length(P_) - 1
    for dev_node_idx_in_path = w_idx_in_pk_minus_1 : (length(path_k_minus_1_vector) - 1)
        
        current_spur_node = path_k_minus_1_vector(dev_node_idx_in_path); % 当前迭代的偏离顶点
        root_path = path_k_minus_1_vector(1:dev_node_idx_in_path);       % 从源到当前偏离顶点的路径段 (根路径)
        
        % 计算 root_path 的成本 (从原始 netCostMatrix 计算，确保准确)
        cost_root_path = 0;
        if length(root_path) > 1 % 根路径至少包含一条边
            for i_cost = 1:(length(root_path)-1)
                cost_root_path = cost_root_path + netCostMatrix(root_path(i_cost), root_path(i_cost+1));
            end
        end

        % ---- 管理对 temp_netCostMatrix 的修改 ----
        % modifications 列表用于存储对 temp_netCostMatrix 所做的临时修改信息。
        % 每个条目是 {row, col, original_cost}, 用于后续恢复。
        modifications = {}; 
        
        % 规则 1: "移除" root_path 中在 current_spur_node 之前的所有节点。
        %         通过将其所有出入边权重在 temp_netCostMatrix 中设为 Inf 实现。
        nodes_in_root_path_before_spur = root_path(1:(dev_node_idx_in_path-1));
        for i_rem_node = 1:length(nodes_in_root_path_before_spur)
            node_to_isolate = nodes_in_root_path_before_spur(i_rem_node);
            
            % 隔离节点的出边 (设置行为Inf)
            for col = 1:size(temp_netCostMatrix, 2)
                if temp_netCostMatrix(node_to_isolate, col) ~= inf
                    modifications{end+1} = {node_to_isolate, col, temp_netCostMatrix(node_to_isolate, col)};
                    temp_netCostMatrix(node_to_isolate, col) = inf;
                end
            end
            % 隔离节点的入边 (设置列为Inf)
            for row = 1:size(temp_netCostMatrix, 1)
                if temp_netCostMatrix(row, node_to_isolate) ~= inf
                    % 避免重复记录 (node_to_isolate, node_to_isolate) 如果它已被出边处理。
                    % 简单起见，允许记录，恢复时正确即可。原代码是直接整行整列赋值。
                    modifications{end+1} = {row, node_to_isolate, temp_netCostMatrix(row, node_to_isolate)};
                    temp_netCostMatrix(row, node_to_isolate) = inf;
                end
            end
        end
        
        % 规则 2: "移除" 从 current_spur_node 出发的，且与已找到的某条最短路径
        % (shortestPaths中的路径) 或当前基础路径 (path_k_minus_1_vector) 共享相同 root_path 的边。
        % 这是原始代码中 SP_sameSubPath 变量收集的路径所对应的边的移除逻辑。
        
        % 收集所有与当前 root_path 匹配的、需要移除其从 current_spur_node 出发的下一条边的路径。
        paths_sharing_root = {};
        paths_sharing_root{1} = path_k_minus_1_vector; % 当前基础路径本身总是要考虑
        
        for sp_idx = 1:length(shortestPaths) % 遍历所有已确定的最短路径
            A_path = shortestPaths{sp_idx};
            
            % 检查此 A_path 是否与 path_k_minus_1_vector 相同 (避免重复处理)
            is_same_as_pk_minus_1 = false;
            if isequal(A_path, path_k_minus_1_vector)
                is_same_as_pk_minus_1 = true;
            end

            % 如果A_path与基础路径不同，且长度足够，且共享相同的根路径
            if ~is_same_as_pk_minus_1 && length(A_path) >= dev_node_idx_in_path
                if isequal(A_path(1:dev_node_idx_in_path), root_path)
                    paths_sharing_root{end+1} = A_path;
                end
            end
        end
        
        % 对收集到的这些共享根路径的路径，移除它们从 current_spur_node 出发的下一条边。
        for psr_idx = 1:length(paths_sharing_root)
            path_to_check = paths_sharing_root{psr_idx};
            if (dev_node_idx_in_path + 1) <= length(path_to_check) % 确保路径在偏离点后还有节点
                edge_u = path_to_check(dev_node_idx_in_path);       % 应等于 current_spur_node
                edge_v_next = path_to_check(dev_node_idx_in_path + 1); % 偏离点后的下一个节点
                
                if temp_netCostMatrix(edge_u, edge_v_next) ~= inf % 如果边还未被移除
                    modifications{end+1} = {edge_u, edge_v_next, temp_netCostMatrix(edge_u, edge_v_next)};
                    temp_netCostMatrix(edge_u, edge_v_next) = inf;
                end
            end
        end
        
        % 从 current_spur_node 到 destination 在修改后的图上运行 Dijkstra 算法，寻找偏离路径段。
        [spur_path_segment, cost_spur_segment] = dijkstra(temp_netCostMatrix, current_spur_node, destination);
        
        % ---- 还原 temp_netCostMatrix ----
        % 将之前修改的边恢复为其原始成本。
        for i_mod = 1:length(modifications)
            mod_info = modifications{i_mod};
            temp_netCostMatrix(mod_info{1}, mod_info{2}) = mod_info{3};
        end
        
        if ~isempty(spur_path_segment) % 如果找到了有效的偏离路径段
            % 构造完整的新候选路径：连接 root_path (不含尾部spur_node) 和 spur_path_segment
            new_candidate_path_vector = [root_path(1:end-1), spur_path_segment];
            new_candidate_cost = cost_root_path + cost_spur_segment;
            
            % 遵循原始代码逻辑：不在此处对 P 或 X 中的路径序列进行显式去重检查。
            % Yen算法的边移除规则旨在避免在 *shortestPaths* 集合中产生重复路径。
            % 不同的生成历史（即不同的path_number_counter）即使产生相同序列的路径，
            % 在P和X中也被视为不同条目。
            
            path_number_counter = path_number_counter + 1; % 为新路径分配唯一ID
            P{path_number_counter,1} = new_candidate_path_vector;
            P{path_number_counter,2} = new_candidate_cost;
            
            if path_number_counter > length(S) % 扩展S数组 (MATLAB会自动处理)
                 S(path_number_counter) = 0; 
            end
            S(path_number_counter) = current_spur_node; % 记录生成此路径的偏离顶点
            
            % 将新候选路径 {ID, 向量, 成本} 添加到候选池 X
            % X 是一个列单元格数组, 每个单元格是 {path_id_in_P; path_vector; path_cost}
            X{end+1,1} = {path_number_counter; new_candidate_path_vector; new_candidate_cost};
        end      
    end % 结束偏离顶点 (dev_node_idx_in_path) 的循环
    
    % 检查候选池 X 是否为空。如果为空，则没有更多路径可供选择。
    if isempty(X)
        break; % 终止主 while 循环
    end
    
    % 从 X 中选择成本最低的路径。
    % 保持原始代码的平局处理方式：如果成本相同，则选择在 X 中索引较小者（即较早加入或上次重组后位置靠前者）。
    min_X_cost = X{1}{3}; % 取第一个候选路径的成本作为初始最小值
    min_X_idx  = 1;       % 取第一个候选路径的索引作为初始最小索引
    
    for x_entry_idx = 2:size(X,1) % 遍历 X 中其余的候选路径
        if X{x_entry_idx}{3} < min_X_cost
            min_X_cost = X{x_entry_idx}{3};
            min_X_idx  = x_entry_idx;
        end
    end
    
    % 获取选中路径的信息，它在P中的ID是关键
    chosen_path_info_from_X = X{min_X_idx};
    chosen_path_id_in_P = chosen_path_info_from_X{1};

    % 将选中的路径添加到 shortestPaths 结果集中
    k = k + 1;
    shortestPaths{k} = P{chosen_path_id_in_P, 1}; % 从P中按ID取出路径向量
    totalCosts(k) = P{chosen_path_id_in_P, 2};    % 从P中按ID取出路径成本
    
    % 更新 current_P_path_number，它将是下一次迭代生成候选路径的基础路径的ID。
    current_P_path_number = chosen_path_id_in_P; 
    
    % 从 X 中移除已选中的路径。
    X(min_X_idx,:) = []; % 按行删除 (因为X是列单元格数组)
    
    % 原始代码在 while 条件中有 size_X ~= 0，并在内部有 if size_X > 0。
    % 这里的 isempty(X) 检查和循环结构已等效处理了这些条件。
    % 当 k == k_paths 时，下一次循环的 while (k < k_paths) 条件将不满足，循环自然终止。

end % 结束主 while 循环 (k < k_paths 或 X 为空)

end % 结束 kShortestPath 函数


%[appendix]{"version":"1.0"}
%---
