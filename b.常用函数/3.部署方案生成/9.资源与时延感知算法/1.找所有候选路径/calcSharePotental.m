%[text] # calcSharePotental
%[text] 对单个多播请求，统计 source -\> 每个 dest 的 K 条最短路中
%[text] 各个节点、各条链路在所有路径中的出现频率。
function [nodeFreq, linkFreq] = calcSharePotental(reqs, KPathsNew, links, nodes)
% calcSharePotental (for Scheme A: KPathsNew is a cell)
% 对单个多播请求，统计 source -> 每个 dest 的 K 条最短路中
% 各个节点、各条链路在所有路径中的出现频率。
%
% 输入：
%   reqs      : 一个多播请求结构体（包含 source, dest）
%   KPathsNew : cell 数组，KPathsNew{src,d} 为 K×1 struct数组（每个元素一条最短路）
%              每条最短路结构体字段：
%                - paths     : 节点序列（已去0）
%                - pathshops : 跳数 hops
%                - link_ids  : 链路序列（已去0）
%   links     : 物理链路结构体数组，含字段 id
%   nodes     : 物理节点结构体数组，含字段 id
%
% 输出：
%   nodeFreq(i) : 节点 i 在所有 considered 路径中出现次数
%   linkFreq(e) : 链路 id = e 在所有 considered 路径中出现次数

    % 源节点、目的节点集合
    src   = reqs.source;
    dests = reqs.dest(:).';   % 转成行向量，方便遍历

    % 最大 id，用于初始化频率向量长度
    max_link_id = max([links.id]);
    max_node_id = max([nodes.id]);

    nodeFreq = zeros(max_node_id, 1);
    linkFreq = zeros(max_link_id, 1);

    % 遍历每个目的节点
    for d = dests
        if d <= 0
            continue; % 过滤掉填充的0目的节点
        end

        % 取出 src->d 的 K 条最短路（K×1 struct数组）
        routes = KPathsNew{src, d};

        if isempty(routes)
            continue;
        end

        % 遍历每条最短路
        for k = 1:numel(routes)
            hops = routes(k).pathshops;
            if hops <= 0
                continue;
            end

            % ---------- 节点出现频率 ----------
            % routes(k).paths 已经是去0后的节点序列
            path_nodes = routes(k).paths;
            if ~isempty(path_nodes)
                nodeFreq(path_nodes) = nodeFreq(path_nodes) + 1;
            end

            % ---------- 链路出现频率 ----------
            % routes(k).link_ids 已经是去0后的链路序列
            path_links = routes(k).link_ids;
            if ~isempty(path_links)
                linkFreq(path_links) = linkFreq(path_links) + 1;
            end
        end
    end
end


%[appendix]{"version":"1.0"}
%---
