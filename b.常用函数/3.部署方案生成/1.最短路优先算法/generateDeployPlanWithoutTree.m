%[text] # generateDeployPlanWithoutTree
%[text] 直接根据 plan 生成部署方案（跳过 treePlan），用于对比
function deployPlan = generateDeployPlanWithoutTree(sortedRequests, plan, links)
% generateDeployPlan_Direct：直接根据 plan 生成部署方案（跳过 treePlan）
%
% 输入：
%   sortedRequests : 排序后的请求集合
%   plan           : Step3 输出的 plan 结构体（含 placeLinks, vnfNode）
%   links          : 物理链路结构体
%
% 输出：
%   deployPlan     : 分段部署指令，与原版输出格式完全一致

    req_num = numel(plan);
    
    % 初始化输出结构
    deployPlan = repmat(struct('req_id', 0, 'treeproject', []), req_num, 1);

    for req_idx = 1:req_num
        req = sortedRequests(req_idx);
        
        % 基础信息
        src      = req.source;
        dests    = req.dest(req.dest > 0);
        dest_num = numel(dests);
        
        vnf_ids  = req.vnf;
        vnf_num  = numel(vnf_ids);
        
        % 从 plan 中提取当前请求的放置信息
        % 注意：Step3 的 plan 中，placeLinks 是 dest_num × max_hops 的矩阵
        currentPlanLinks = plan(req_idx).placeLinks; 
        currentPlanVnf   = plan(req_idx).vnfNode;
        
        % --- 逐个目的节点生成 vnf_project ---
        treeproject = repmat(struct('dest_id', 0, 'vnf_project', [], 'final_links', []), dest_num, 1);

        for di = 1:dest_num
            dest_id = dests(di);
            treeproject(di).dest_id = dest_id;

            % 1. 获取该目的节点的完整链路序列 (Link Path)
            % 过滤掉填充的 0
            rawLinks = currentPlanLinks(di, :);
            linkPath = rawLinks(rawLinks > 0); 
            
            % 2. 根据链路序列推导节点序列 (Node Path) [关键步骤]
            % 因为 plan 里的 linkPath 是有序的，我们可以顺藤摸瓜
            if isempty(linkPath)
                % 特殊情况：源即目的
                nodePath = src;
            else
                nodePath = zeros(1, length(linkPath) + 1);
                nodePath(1) = src;
                currNode = src;
                for k = 1:length(linkPath)
                    eid = linkPath(k);
                    % 判断链路方向：找到与 currNode 相连的另一端
                    if links(eid).source == currNode
                        nextNode = links(eid).dest;
                    elseif links(eid).dest == currNode
                        nextNode = links(eid).source; % 双向链路容错
                    else
                        error('链路不连续：Link %d 不连接 Node %d', eid, currNode);
                    end
                    nodePath(k+1) = nextNode;
                    currNode = nextNode;
                end
            end

            % 3. 获取该 dest 的 VNF 放置节点
            vNodes = currentPlanVnf(di, :);

            % 4. 初始化 VNF 项目结构
            vnf_project = repmat(struct( ...
                'vnfid', 0, ...
                'placeVnfLinks', [], ...
                'placeVnfNode', 0 ...
            ), vnf_num, 1);

            % 5. 路径切分逻辑 (与原版保持一致)
            startPos = 1; % 当前段起点在 nodePath 的位置

            for v = 1:vnf_num
                place_node_id = vNodes(v);
                
                % 在 nodePath 上找到 place_node_id 的位置
                % find(..., 1) 找第一个匹配项，确保按顺序推进
                relPos = find(nodePath(startPos:end) == place_node_id, 1);
                
                if isempty(relPos)
                    % 容错：如果 VNF 节点不在路径上（理论上 Step3 保证了在路径上）
                    warning('Req %d Dest %d: VNF节点 %d 不在路径上', req.id, dest_id, place_node_id);
                    endPos = startPos;
                else
                    endPos = relPos + startPos - 1;
                end

                % 截取对应的链路段
                if endPos > startPos
                    % 节点索引 i 到 i+1 对应的链路索引是 i
                    place_link_ids = linkPath(startPos : endPos-1);
                else
                    place_link_ids = []; 
                end

                vnf_project(v).vnfid         = vnf_ids(v);
                vnf_project(v).placeVnfLinks = place_link_ids;
                vnf_project(v).placeVnfNode  = place_node_id;

                % 更新起点
                startPos = endPos;
            end

            treeproject(di).vnf_project = vnf_project;

            % --- 计算最后一跳：从最后一个 VNF 节点到 dest 的链路 ---
            last_vnf_node = vNodes(vnf_num);
            if last_vnf_node == dest_id
                % 最后一个 VNF 就在 dest 上，无需额外链路
                treeproject(di).final_links = [];
            else
                % 需要从最后一个 VNF 节点走到 dest
                % startPos 已经指向最后一个 VNF 在 nodePath 中的位置
                % dest_id 在 nodePath 的最后一个位置
                destPos = numel(nodePath);
                if destPos > startPos && ~isempty(linkPath)
                    treeproject(di).final_links = linkPath(startPos : destPos-1);
                else
                    treeproject(di).final_links = [];
                end
            end
        end

        deployPlan(req_idx).req_id = req.id;
        deployPlan(req_idx).treeproject = treeproject;
    end
end

%[appendix]{"version":"1.0"}
%---
