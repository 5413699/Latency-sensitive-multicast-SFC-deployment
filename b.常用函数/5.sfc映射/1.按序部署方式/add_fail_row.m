%[text] # add\_fail\_row
%[text] 记录不可部署的vnf信息
function fail_log = add_fail_row(fail_log, req, dest_idx, vnf_idx, ...
                                 failed_node, failed_link, ...
                                 lack_cpu, lack_mem, lack_bw, timeout, unsched)

    n = numel(fail_log) + 1;

    fail_log(n).req_id         = req.id;
    fail_log(n).dest_idx       = dest_idx;
    fail_log(n).vnf_idx        = vnf_idx;
    fail_log(n).place_node_id    = failed_node;
    fail_log(n).failed_link    = failed_link;

    fail_log(n).lack_cpu       = double(lack_cpu);
    fail_log(n).lack_mem       = double(lack_mem);
    fail_log(n).lack_bw = double(lack_bw);
    fail_log(n).time_out      = double(timeout);
    fail_log(n).unschedulable  = double(unsched);
end


%[appendix]{"version":"1.0"}
%---
