%[text] # KPathsGenerater
%[text] 并行计算所有节点对的 K 条最短路径

function Paths = KPathsGenerater(bone_topo, link, K)
% computeKShortestPaths  并行计算所有节点对的 K 条最短路径
%   Paths = computeKShortestPaths(bone_topo, link, K)
%   输入：
%     bone_topo — 网络拓扑的代价矩阵 (node_num×node_num)
%     link      — 对应的链路编号矩阵 (node_num×node_num)
%     K         — 每对节点需计算的最短路径条数
%   输出：
%     Paths     — node_num×node_num 的结构体数组，
%                 每个元素包含 fields:
%                   .paths         (K×node_num)  节点序列
%                   .pathshops     (1×K)         跳数
%                   .pathsdistance (1×K)         距离/代价
%                   .pathindex     scalar        实际路径数
%                   .link_ids      (K×node_num)  链路 ID 序列

    tStart = tic;                  % 启动总计时
    node_num = size(bone_topo,1);

    % 显式启动并行池，使用 'Processes' 配置文件
    if isempty(gcp('nocreate'))
        parpool('Processes');
    end

    % 将大矩阵封装为 Constant，避免 parfor 中重复传输
    C_topo = parallel.pool.Constant(bone_topo);
    C_link = parallel.pool.Constant(link);

    % 结构体模板，预分配所有字段
    temp.paths         = zeros(K, node_num);
    temp.pathshops     = zeros(1, K);
    temp.pathsdistance = zeros(1, K);
    temp.pathindex     = 0;
    temp.link_ids      = zeros(K, node_num);

    % 预分配结构体数组 Paths
    Paths(node_num, node_num) = temp;  %#ok<AGROW>

    fprintf('并行计算 %d-最短路径，节点数：%d ...\n', K, node_num);

    % 外层 parfor：按源节点并行
    parfor src = 1:node_num
        topo = C_topo.Value; 
        lmat = C_link.Value;
        for dst = 1:node_num
            P = temp;  % 从模板拷贝
            if src ~= dst
                % 调用 K 最短路核心算法
                [SP_cell, cost_vec] = KShortestPath_new(topo, src, dst, K);

                nPaths = numel(SP_cell);
                P.pathindex = nPaths;

                % 填充节点序列与跳数
                for p = 1:nPaths
                    nodes = SP_cell{p};
                    P.paths(p,1:numel(nodes)) = nodes;
                    P.pathshops(p) = numel(nodes) - 1;
                end
                P.pathsdistance(1:nPaths) = cost_vec;

                % 填充链路 ID
                for p = 1:nPaths
                    for h = 1:P.pathshops(p)
                        u = P.paths(p,h); 
                        v = P.paths(p,h+1);
                        P.link_ids(p,h) = lmat(u,v);
                    end
                end
            end
            Paths(src,dst) = P;
        end
    end

    totalTime = toc(tStart);
    fprintf('运行时间为 %.2f s.\n', totalTime);
end


%[appendix]{"version":"1.0"}
%---
