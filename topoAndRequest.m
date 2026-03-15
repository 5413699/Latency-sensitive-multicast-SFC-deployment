%[text] # 1.生成拓补与请求信息
clc; clear;
%[text] ## %% 1) 导入路径
currentDir = pwd;
addpath(genpath(fullfile(currentDir, 'a.输入')));
addpath(genpath(fullfile(currentDir, 'b.常用函数')));
%[text] ## %% 2) 选择拓补（只改这一行）
topoName = "US_Backbone";
% topoName = "Abilene";   % "US_Backbone" 或 "Abilene"
%[text] ## %% 3) 配置表：不同拓补只在这里写一次
topocfg = getTopoCfg(topoName);
reqCfg = getReqCfg(topoName);
%[text] ## %% 4) 生成拓补相关数据并保存
topo = feval(topocfg.topoFunc);                  % 等价于 Abilene() / US_Backbone()
[link, link_num] = topology_link_new(topo);
nodes = Node_model(topo, topocfg.minm, topocfg.maxm, topocfg.minc, topocfg.maxc);
links = Link_model(link, topocfg.minb, topocfg.maxb);

%% ========== KPaths 智能加载（避免重复计算） ==========
% 检测已有 KPaths 数据的候选路径（按优先级排序）
kpathCandidates = {
    topocfg.kpathPath, ...                                          % 1. c.输出/1.拓补信息/xxx_10Path.mat
    fullfile('a.输入', '2.整理后的拓补信息', sprintf('%s_KPath.mat', topoName)), ...  % 2. a.输入/xxx_KPath.mat
    fullfile('a.输入', '2.整理后的拓补信息', sprintf('%s_topoinfo.mat', topoName))    % 3. 备选：topoinfo中可能包含KPaths
};

KPathsLoaded = false;
for i = 1:numel(kpathCandidates) %[output:group:18c60525]
    candidatePath = kpathCandidates{i};
    if isfile(candidatePath)
        fprintf('检测到已有 KPaths 数据: %s\n', candidatePath); %[output:0428d193]
        try
            loadedData = load(candidatePath);
            % 检查是否包含 KPaths 或 KPathsNew
            if isfield(loadedData, 'KPaths')
                KPaths = loadedData.KPaths;
                if isfield(loadedData, 'KPathsNew')
                    KPathsNew = loadedData.KPathsNew;
                else
                    fprintf('  重新生成 KPathsNew（cell格式）...\n');
                    KPathsNew = refactorKPathsToCellStruct(KPaths);
                end
                KPathsLoaded = true;
                fprintf('✓ 已加载 KPaths（跳过重新计算，节省时间）\n'); %[output:545a1158]
                break;
            end
        catch ME
            fprintf('  加载失败: %s，尝试下一个候选...\n', ME.message);
        end
    end
end %[output:group:18c60525]

% 如果没有找到已有数据，则重新计算
if ~KPathsLoaded
    fprintf('未检测到已有 KPaths 数据，开始计算（可能需要较长时间）...\n');
    KPaths = KPathsGenerater(topo, link, 10);
    KPathsNew = refactorKPathsToCellStruct(KPaths);
    fprintf('✓ KPaths 计算完成\n');
end

%% ========== 保存拓补数据 ==========
if ~exist(fileparts(topocfg.topoInfoPath), 'dir'); mkdir(fileparts(topocfg.topoInfoPath)); end
if ~exist(fileparts(topocfg.kpathPath), 'dir');    mkdir(fileparts(topocfg.kpathPath));    end

save(topocfg.kpathPath, 'KPaths','KPathsNew');
save(topocfg.topoInfoPath, 'KPaths','nodes','links','KPathsNew');
fprintf('✓ 已保存拓补（%s） 时间：%s\n', topoName, string(datetime("now"))); %[output:5d823082]
%[text] ## %% 5) 生成请求相关数据并保存
load(topocfg.topoInfoPath);     % 得到 nodes / links / KPaths

if ~exist(reqCfg.requestsDir, 'dir'); mkdir(reqCfg.requestsDir); end
if ~exist(reqCfg.sortedRequestsDir, 'dir'); mkdir(reqCfg.sortedRequestsDir); end


for requests_round = 1:reqCfg.requests_set_index 
    requests = generate_requests( ...
        reqCfg.requests_num, nodes, ...
        reqCfg.destNode_count, reqCfg.vnftype_num, reqCfg.vnf_num, ...
        reqCfg.maxbw, reqCfg.minbw, reqCfg.maxnr, reqCfg.minnr, reqCfg.maxt, reqCfg.mint);

    filepath = fullfile(reqCfg.requestsDir, sprintf('request%d.mat', requests_round));
    save(filepath, 'requests');

    % 生成按照时延排序后的请求
    sortedRequests = sortRequestByDeadline(requests);
    filepath = fullfile(reqCfg.sortedRequestsDir, sprintf('sortedRequest%d.mat', requests_round));
    save(filepath, 'sortedRequests');

end
fprintf('✓ 已保存请求（%s） 时间：%s\n', topoName, string(datetime("now"))); %[output:72dfc9e5]

%[text] ## 
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":30.3}
%---
%[output:0428d193]
%   data: {"dataType":"text","outputData":{"text":"检测到已有 KPaths 数据: c.输出\\1.拓补信息\\US_Backbone_10Path.mat\n","truncated":false}}
%---
%[output:545a1158]
%   data: {"dataType":"text","outputData":{"text":"✓ 已加载 KPaths（跳过重新计算，节省时间）\n","truncated":false}}
%---
%[output:5d823082]
%   data: {"dataType":"text","outputData":{"text":"✓ 已保存拓补（US_Backbone） 时间：2026-01-21 17:43:59\n","truncated":false}}
%---
%[output:72dfc9e5]
%   data: {"dataType":"text","outputData":{"text":"✓ 已保存请求（US_Backbone） 时间：2026-01-21 17:44:00\n","truncated":false}}
%---
