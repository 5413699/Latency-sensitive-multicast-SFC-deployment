%[text] # check\_node\_reservation
%[text] 检查从 arriveTime 到 T\_node 的 cpu/mem 是否够用
function [lack_cpu, lack_mem] = check_node_reservation(node, arriveTime, cpu_need, mem_need)
%CHECK_NODE_RESERVATION  检查从 arriveTime 到 T_node 的 cpu/mem 是否够用
%
% 资源预留语义（与你原代码一致）：
%   一旦接收/部署，资源在后续整个窗口都被占用，不会释放。

    lack_cpu = false;
    lack_mem = false;

    T_node = size(node.cpu, 1);
    for tau = arriveTime:T_node
        if node.cpu(tau) < cpu_need
            lack_cpu = true;
            return;
        end
        if node.mem(tau) < mem_need
            lack_mem = true;
            return;
        end
    end
end

%[appendix]{"version":"1.0"}
%---
