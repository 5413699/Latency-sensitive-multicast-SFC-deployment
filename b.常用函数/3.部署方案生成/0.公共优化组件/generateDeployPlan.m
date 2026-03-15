%[text] # generateDeployPlan
%[text] **为合法的多播树生成部署顺序**
function deployPlan = generateDeployPlan(sortedRequests, FixedPlan, links)
% generateDeployPlan（纯部署方案版：不生成时间t）
%
% 输入：
%   sortedRequests : 排序后的请求集合（1×N结构体）
%   treePlan       : Step4 输出（每个请求：placeLinks + vnfNode）
%   links          : 物理链路结构体（links(e).source / links(e).dest）
%   nodes          : 这里不使用（保留是为了不改你外部调用）
%
% 输出 deployPlan 结构（不含t）：
% deployPlan(req_idx).id
% deployPlan(req_idx).treeproject(dest_idx).dest_id
% deployPlan(req_idx).treeproject(dest_idx).vnf_project(v).vnfid
% deployPlan(req_idx).treeproject(dest_idx).vnf_project(v).placeVnfLinks
% deployPlan(req_idx).treeproject(dest_idx).vnf_project(v).placeVnfNode
% deployPlan(req_idx).treeproject(dest_idx).final_links  % 最后一个VNF到dest的链路（若VNF在dest则为空）

req_num = numel(FixedPlan);

deployPlan = repmat(struct('req_id', 0, 'treeproject', []), req_num, 1);

for req_idx = 1:req_num
    req = sortedRequests(req_idx);

    % 先设置req_id，即使后续失败也有记录
    deployPlan(req_idx).req_id = req.id;

    src      = req.source;
    dests    = req.dest(req.dest > 0);
    dest_num = numel(dests);

    vnf_ids  = req.vnf;
    vnf_num  = numel(vnf_ids);

    placeLinks = FixedPlan(req_idx).placeLinks(:).';   % 1×M
    vnfNode   = FixedPlan(req_idx).vnfNode;          % dest_num×vnf_num
    
    % 过滤掉无效的链路ID（0或负数）
    placeLinks = placeLinks(placeLinks > 0);
    
    % 如果没有有效链路，创建空的treeproject并跳过
    if isempty(placeLinks)
        % 创建空的treeproject结构
        treeproject = repmat(struct('dest_id', 0, 'vnf_project', [], 'final_links', []), dest_num, 1);
        for di = 1:dest_num
            treeproject(di).dest_id = dests(di);
            treeproject(di).vnf_project = repmat(struct('vnfid', 0, 'placeVnfLinks', [], 'placeVnfNode', 0), vnf_num, 1);
        end
        deployPlan(req_idx).treeproject = treeproject;
        continue;
    end

    % --- 用 placeLinks 构造这棵树的有向图 ---
    s = arrayfun(@(eid) links(eid).source, placeLinks);
    t = arrayfun(@(eid) links(eid).dest,   placeLinks);

    G = digraph(s, t);
    G.Edges.eid = placeLinks(:);   % 给每条"树边"挂上真实链路ID

    % --- 逐个目的节点生成 vnf_project ---
    treeproject = repmat(struct('dest_id', 0, 'vnf_project', [], 'final_links', []), dest_num, 1);

    for di = 1:dest_num
        dest_id = dests(di);
        treeproject(di).dest_id = dest_id;

        % 初始化空的vnf_project
        vnf_project = repmat(struct( ...
            'vnfid', 0, ...
            'placeVnfLinks', [], ...
            'placeVnfNode', 0 ...
        ), vnf_num, 1);

        % 目的节点在树上的路径（节点序列 + 边索引序列）
        try
            [nodePath, ~, edgeIdx] = shortestpath(G, src, dest_id);
        catch
            % 找不到路径，使用空的vnf_project
            treeproject(di).vnf_project = vnf_project;
            continue;
        end
        
        % 检查路径是否有效
        if isempty(nodePath) || isempty(edgeIdx)
            treeproject(di).vnf_project = vnf_project;
            continue;
        end
        
        linkPath = G.Edges.eid(edgeIdx).';  % 与 nodePath 对齐：linkPath(k)连接 nodePath(k)->nodePath(k+1)

        % 该 dest 的 VNF 放置节点序列
        vNodes = vnfNode(di, :);

        % startPos：当前段起点在 nodePath 的位置（第1段从 src 开始）
        startPos = 1;

        for v = 1:vnf_num
            place_node_id = vNodes(v);
            vnf_project(v).vnfid = vnf_ids(v);
            vnf_project(v).placeVnfNode = place_node_id;
            
            % 检查place_node_id是否有效
            if place_node_id <= 0
                vnf_project(v).placeVnfLinks = [];
                continue;
            end

            % 在 nodePath 上找到 place_node_id 的位置（保证顺序：从 startPos 往后找）
            endPosRel = find(nodePath(startPos:end) == place_node_id, 1);
            
            if isempty(endPosRel)
                % 找不到节点，可能vnfNode与placeLinks不匹配
                vnf_project(v).placeVnfLinks = [];
                continue;
            end
            
            endPos = endPosRel + startPos - 1;

            % 该 VNF 对应的链路段：nodePath(startPos) -> nodePath(endPos)
            if endPos > startPos && endPos-1 <= numel(linkPath)
                place_link_ids = linkPath(startPos : endPos-1);
            else
                place_link_ids = [];   % 同节点部署，无需走链路（保留空即可）
            end

            vnf_project(v).placeVnfLinks = place_link_ids;

            % 下一段从当前 VNF 节点继续
            startPos = endPos;
        end

        treeproject(di).vnf_project = vnf_project;

        % --- 计算最后一跳：从最后一个 VNF 节点到 dest 的链路 ---
        last_vnf_node = vNodes(vnf_num);
        if last_vnf_node == dest_id || last_vnf_node <= 0
            % 最后一个 VNF 就在 dest 上，或无效，无需额外链路
            treeproject(di).final_links = [];
        else
            % 需要从最后一个 VNF 节点走到 dest
            % startPos 已经指向最后一个 VNF 在 nodePath 中的位置
            % dest_id 在 nodePath 的最后一个位置
            destPos = numel(nodePath);
            if destPos > startPos && destPos-1 <= numel(linkPath)
                treeproject(di).final_links = linkPath(startPos : destPos-1);
            else
                treeproject(di).final_links = [];
            end
        end
    end

    deployPlan(req_idx).treeproject = treeproject;
end
end


%[appendix]{"version":"1.0"}
%---
