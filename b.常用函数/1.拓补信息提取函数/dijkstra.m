%[text] # dijkstra算法
%[text] 优化后的迪杰斯特拉最短路算法
%[text] \[path, totalCost\] = dijkstra( netCostMatrix, s, d)
%[text] 使用 MATLAB 内建的图算法函数进行计算，效率高于手动实现。
%[text] 输入:
%[text]         netCostMatrix - 邻接成本矩阵 (n x n)。 netCostMatrix(i, j) 是从节点 i到节点 j 的成本。如果两节点之间没有直接连接，使用 Inf。迪杰斯特拉算法要求成本为非负数。
%[text]         s                     - 起始节点索引 (整数，从 1 到 n)。
%[text]         d                     - 目标节点索引 (整数，从 1 到 n)。
%[text] 输出:
%[text]         shortestPath   - 包含最短路径上节点索引的行向量。如果不存在路径，则为空向量 \[\]。
%[text]         totalCost         - 最短路径的总成本。如果不存在路径，则为 Inf。
%[text] 
function [shortestPath, totalCost] = dijkstra(netCostMatrix, s, d)
%[text] ## 1. 获取节点数量
n = size(netCostMatrix, 1);
%[text] ## 2. 创建 MATLAB 图对象
%[text] 确保成本是非负的，迪杰斯特拉算法的要求。如果存在负成本，shortestpath函数可能会发出警告或产生不正确的结果（需要 Bellman-Ford 或 SPFA）。
if any(netCostMatrix(:) < 0 & isfinite(netCostMatrix(:)))
    warning('输入成本矩阵包含负值，迪杰斯特拉算法可能无法找到正确的最短路径。');
end
%[text] MATLAB 的 shortestpath 函数直接在 graph 或 digraph 对象上操作。
%[text] 我们使用 digraph (有向图) 因为成本矩阵通常表示有向边。
%[text] 成本矩阵中的 Inf 值会被 graph/digraph 函数自动识别为无连接。
%[text] 节点索引默认为 1 到 n。
% 创建有向图对象 G，使用 netCostMatrix 作为边的权重矩阵。
G = digraph(netCostMatrix);
%[text] ## 3.使用 MATLAB 内建的 shortestpath 函数
%[text] 这个函数针对非负权重的图高效地实现了迪杰斯特拉算法。
%[text] 它返回从 s 到 d 的路径上的节点序列以及该路径的总成本。
%[text] 如果 s 和 d 相同，返回 s 和 0。
%[text] 如果没有从 s 到 d 的路径，shortestpath 返回一个空向量 \[\] 作为路径，
%[text] 并返回 Inf 作为成本，这与原始代码逻辑一致。
[pathNodes, pathCost] = shortestpath(G, s, d);
%[text] ## 4.. 赋值输出变量
shortestPath = pathNodes;
totalCost = pathCost;
end
%[text] 
%[text] 
%[text] 原始代码中计算 farthestPrevHop 和 farthestNextHop 的部分
%[text] 与核心的最短路径计算无关，且未作为函数的输出，因此已移除。
%[text] 这两个变量可能用于其他特定目的（如通信范围计算），如果需要，
%[text] 应在调用此最短路径函数后，根据得出的最短路径信息单独计算。
%[text] 
%[text] 原始代码中的迪杰斯特拉主循环 (查找未访问的最近节点和松弛边)
%[text] 由于使用了内建函数已完成此任务，该循环被省略。
%[text] 原循环的复杂度为 O(n^2)，而内建 shortestpath 函数通常使用更高效的
%[text] 数据结构（如斐波那契堆或二叉堆），其复杂度更接近 O(E log V) 或 O(E + V log V)，
%[text] 其中 V 是节点数，E 是边数。对于稀疏图，这比 O(V^2) 快得多；
%[text] 对于稠密图 (E ~ V^2)，虽然理论复杂度可能接近，但内建函数的底层实现
%[text] 通常经过高度优化，在实际性能上仍有优势。

%[appendix]{"version":"1.0"}
%---
