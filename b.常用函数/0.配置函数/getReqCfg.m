%[text] # getReqCfg
%[text] 根据拓补名获取请求配置
function cfg = getReqCfg(topoName)
    cfg = struct();
    switch topoName
        case "US_Backbone"
            % 生成的请求路径名前缀
            cfg.requestsDir   = "c.输出\2.请求信息\US_Backbone\request";
            % 用于测试的请求
            cfg.requestPath   = "c.输出\2.请求信息\US_Backbone\request\request1";
            % 生成的按时延排序的请求路径名前缀
            cfg.sortedRequestsDir   = "c.输出\2.请求信息\US_Backbone\sortedRequest";
            % 用于测试的按时延排序的请求
            cfg.sortedRequestsPath   = "c.输出\2.请求信息\US_Backbone\sortedRequest\sortedRequest1";

            % 多播结构
            cfg.destNode_count     = 5;    % 每个请求的目的节点数
        
            % 请求集合规模
            cfg.requests_set_index = 20;   % 生成多少组请求集合
            cfg.requests_num       = 100;  % 每组多少个请求（强耦合参数，不建议改）
        
            % SFC / VNF 参数
            cfg.vnftype_num = 8;   % VNF 类型总数
            cfg.vnf_num     = 3;   % 每个请求使用的 VNF 数
        
            % 请求资源需求范围
            cfg.maxbw = 8; cfg.minbw = 2;     % 带宽
            cfg.maxnr = 4;  cfg.minnr = 1;     % 节点资源
            cfg.maxt  = 250; cfg.mint  = 100;    % 最大时延

        case "Abilene"
            % 生成的请求路径名前缀
            cfg.requestsDir   = "c.输出\2.请求信息\Abilene\request";
            % 用于测试的请求
            cfg.requestPath   = "c.输出\2.请求信息\Abilene\request\request1";
            % 生成的按时延排序的请求路径名前缀
            cfg.sortedRequestsDir   = "c.输出\2.请求信息\Abilene\sortedRequest";
            % 用于测试的按时延排序的请求
            cfg.sortedRequestsPath   = "c.输出\2.请求信息\Abilene\sortedRequest\sortedRequest1";
            
            % 多播结构
            cfg.destNode_count     = 5;    % 每个请求的目的节点数
        
            % 请求集合规模
            cfg.requests_set_index = 20;   % 生成多少组请求集合
            cfg.requests_num       = 100;  % 每组多少个请求（强耦合参数，不建议改）
        
            % SFC / VNF 参数
            cfg.vnftype_num = 8;   % VNF 类型总数
            cfg.vnf_num     = 3;   % 每个请求使用的 VNF 数
        
            % 请求资源需求范围
            cfg.maxbw = 24; cfg.minbw = 6;     % 带宽
            cfg.maxnr = 4;  cfg.minnr = 1;     % 节点资源
            cfg.maxt  = 100; cfg.mint  = 50;    % 最大时延

        otherwise
            error("未知拓补：%s（请用 US_Backbone 或 Abilene）", topoName);
    end
end





%[appendix]{"version":"1.0"}
%---
