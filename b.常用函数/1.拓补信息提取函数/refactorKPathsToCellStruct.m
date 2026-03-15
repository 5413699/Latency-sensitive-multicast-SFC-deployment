%[text] # refactorKPathsToCellStruct(KPaths)
%[text] 把K短路存的好看些
function KPathsNew = refactorKPathsToCellStruct(KPaths)
% 将原 KPaths(i,j) 里矩阵形式的K条路径，重构为：
%   KPathsNew{i,j} = K×1 struct数组
% struct字段：paths, pathshops, link_ids（可选保留 pathdistance）
%
% 原结构假设：
%   KPaths(i,j).paths       (K × node_num) 0填充
%   KPaths(i,j).pathshops   (1 × K)
%   KPaths(i,j).link_ids    (K × node_num) 0填充
%   KPaths(i,j).pathindex   标量（实际K）
%   KPaths(i,j).pathdistance(1 × K) 可选

    node_num = size(KPaths, 1);
    KPathsNew = cell(node_num, node_num);

    for i = 1:node_num
        for j = 1:node_num
            info = KPaths(i, j);

            % 有些(i,j)可能没有路径
            if ~isfield(info, 'pathindex') || info.pathindex <= 0
                KPathsNew{i, j} = struct('paths', {}, 'pathshops', {}, 'link_ids', {});
                continue;
            end

            K = info.pathindex;

            % 预分配 struct 数组（每个元素一条最短路）
            routes = repmat(struct('paths', [], 'pathshops', 0, 'link_ids', []), K, 1);

            for k = 1:K
                hops = info.pathshops(k);
                routes(k).pathshops = hops;

                % paths：长度 hops+1（节点数）
                if hops > 0
                    pn = info.paths(k, 1:hops+1);
                    routes(k).paths = pn(pn > 0);   % 去0更干净
                else
                    routes(k).paths = [];
                end

                % link_ids：长度 hops（链路数）
                if hops > 0 && isfield(info, 'link_ids')
                    lk = info.link_ids(k, 1:hops);
                    routes(k).link_ids = lk(lk > 0);
                else
                    routes(k).link_ids = [];
                end
            end

            KPathsNew{i, j} = routes;
        end
    end
end


%[appendix]{"version":"1.0"}
%---
