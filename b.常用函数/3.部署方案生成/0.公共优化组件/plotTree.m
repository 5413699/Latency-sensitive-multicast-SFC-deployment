%[text] # 绘制示意多播树
function fullFilePath = plotTree(sortedPlan, req_id, links,reqs, saveDir)
% plotTree(deployPlan, req_id, links)
% 只使用固定字段名：
%   deployPlan(i).req.id / .source / .dest
%   deployPlan(i).treeproject(tp).vnf_project(vp).vnfid
%   deployPlan(i).treeproject(tp).vnf_project(vp).placeVnfLinks
%   deployPlan(i).treeproject(tp).vnf_project(vp).placeVnfNode
%
% 输出：
%   fullFilePath: 保存的 svg 完整路径

    % ===================== 1) 定位对应请求条目 =====================
    req_idx = find([sortedPlan.req_id] == req_id, 1);
    req = reqs(req_idx);

    % ===================== 2) 汇总整棵树的链路 treelink + VNF标注信息 =====================
    TP = sortedPlan(req_idx).treeproject;

    treelink = [];              % 整棵树使用到的链路ID集合
    vnfNodeList = [];           % 记录每个 VNF 部署节点
    vnfIdList   = [];           % 记录对应 VNF ID（与 vnfNodeList 一一对应）

    for tp = 1:numel(TP)
        V = TP(tp).vnf_project;
        for vp = 1:numel(V)
            % 合并链路
            if ~isempty(V(vp).placeVnfLinks)
                treelink = [treelink, V(vp).placeVnfLinks(:)']; %#ok<AGROW>
            end

            % 收集VNF部署节点与VNF类型
            if ~isempty(V(vp).placeVnfNode)
                vnfNodeList(end+1) = V(vp).placeVnfNode; %#ok<AGROW>
                vnfIdList(end+1)   = V(vp).vnfid;        %#ok<AGROW>
            end
        end
        
        % 【关键修复】合并 final_links（从最后一个VNF到目的节点的链路）
        if isfield(TP(tp), 'final_links') && ~isempty(TP(tp).final_links)
            treelink = [treelink, TP(tp).final_links(:)']; %#ok<AGROW>
        end
    end

    treelink = unique(treelink(treelink > 0));
    if isempty(treelink)
        error('req_id=%d 的 treelink 为空（placeVnfLinks 全空/全0），无法绘图。', req_idx);
    end

    % ===================== 3) 构图：从链路ID得到 s,t =====================
    s = arrayfun(@(id) links(id).source, treelink);
    t = arrayfun(@(id) links(id).dest,   treelink);

    % 图包含所有潜在节点：边端点 + source + dest + VNF节点
    all_nodes = [s(:); t(:); req.source; req.dest(req.dest > 0)'; vnfNodeList(:)];
    max_id = max(all_nodes);

    G = digraph(s, t, [], max_id);

    % 关键：Name=原始ID字符串，避免 rmnode 后索引错位
    G.Nodes.Name = string(1:numnodes(G))';

    % 存边ID用于显示标签
    G.Edges.ID = treelink(:);

    % 删除孤立节点（不在树上的节点）
    deg0 = (indegree(G) + outdegree(G) == 0);
    if any(deg0)
        G = rmnode(G, find(deg0));
    end

    % ===================== 4) 绘图 =====================
    f = figure('Color', 'w', ...
        'Name', ['Request ', num2str(req.id), ' Multicast Tree'], ...
        'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.7]);

    p = plot(G, 'Layout', 'layered', ...
        'NodeColor', [0.6 0.6 0.6], 'MarkerSize', 6, ...
        'LineWidth', 1.2, 'ArrowSize', 10);

    % 显示链路ID作为边标签
    p.EdgeLabel = string(G.Edges.ID);

    % ===================== 5) 高亮 Source =====================
    srcNode = req.source;
    srcIdx = findnode(G, string(srcNode));
    if srcIdx > 0
        highlight(p, srcIdx, 'NodeColor', 'r', 'MarkerSize', 10, 'Marker', 's');
        text(p.XData(srcIdx), p.YData(srcIdx)+0.15, 'Source', ...
            'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end

    % ===================== 6) 高亮 Destinations =====================
    destNodes = req.dest(req.dest > 0);
    for i = 1:numel(destNodes)
        dNode = destNodes(i);
        dIdx = findnode(G, string(dNode));
        if dIdx > 0
            highlight(p, dIdx, 'NodeColor', 'r', 'MarkerSize', 10, 'Marker', 'p');
            text(p.XData(dIdx), p.YData(dIdx)-0.15, ['D', num2str(i)], ...
                'Color', 'r', 'FontSize', 8, 'HorizontalAlignment', 'center');
        end
    end

    % ===================== 7) 标注 VNF：按节点聚合 vnfid =====================
    % 把 "同一节点上的多个 vnfid" 聚合成一个标签
    uniqueVnfNodes = unique(vnfNodeList(vnfNodeList > 0));

    for ii = 1:numel(uniqueVnfNodes)
        node_id = uniqueVnfNodes(ii);
        nodeIdx = findnode(G, string(node_id));
        if nodeIdx == 0, continue; end

        % 该节点部署的VNF类型集合
        deployed_vnf_types = unique(vnfIdList(vnfNodeList == node_id));
        if isempty(deployed_vnf_types), continue; end

        vnf_str = sprintf('%d,', deployed_vnf_types);
        label_text = ['\color{blue}VNF: ', vnf_str(1:end-1)];

        text(p.XData(nodeIdx), p.YData(nodeIdx)+0.2, label_text, ...
            'FontWeight', 'bold', 'FontSize', 9, 'HorizontalAlignment', 'center');

        % 让VNF节点更醒目一点（你也可以再加 NodeColor，但我按你原风格只放大）
        highlight(p, nodeIdx, 'MarkerSize', 8);
    end

    title(['Multicast Service Function Chain Tree (Req ID: ', num2str(req.id), ')']);
    axis off;

    % ===================== 8) 保存 SVG =====================
    % 构造完整的文件路径（将 req_id 转为字符串并加上后缀）
    if ~exist(saveDir, 'dir'), mkdir(saveDir); end
    fileName = sprintf('MulticastTree_Req_%d.svg', req.id);
    fullFilePath = fullfile(saveDir, fileName);

    try
        exportgraphics(f, fullFilePath, 'ContentType', 'vector'); % 推荐：矢量
    catch
        saveas(f, fullFilePath); % 兼容老版本MATLAB
    end

    fprintf('多播树示意图已保存至: %s\n', fullFilePath);
end



%[appendix]{"version":"1.0"}
%---
