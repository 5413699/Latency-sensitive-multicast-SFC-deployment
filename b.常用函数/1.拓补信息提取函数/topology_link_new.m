%[text] # topology\_link\_new
%[text] 
%[text] 对topology\_link函数的优化实现
%[text] 
function [link, linksum] = topology_link_new(Net_topo)
    % 1. 构造逻辑掩码：找出所有有效链路位置
    mask = (Net_topo ~= 0) & ~isinf(Net_topo);             % :contentReference[oaicite:0]{index=0} :contentReference[oaicite:1]{index=1}

    % 2. 统计链路总数
    linksum = nnz(mask);                                    % nnz 直接计数非零项 :contentReference[oaicite:2]{index=2}

    % 3. 找出行列下标
    [row, col] = find(mask);                                % find 返回所有满足条件的位置 :contentReference[oaicite:3]{index=3}

    % 4. 预分配结果矩阵并批量赋值
    link = zeros(size(Net_topo));                           
    ind = sub2ind(size(Net_topo), row, col);                % sub2ind 将 (row,col) 转为线性索引 :contentReference[oaicite:4]{index=4}
    link(ind) = 1:linksum;                                  % 向量化赋值

    % 5. 转置link使得其与原代码结果相同，便于后期纠错
    link = link.'; 
end


%[appendix]{"version":"1.0"}
%---
