function exportMetricsToExcel(allMetrics, methods, outDir, topoName)
%EXPORTMETRICSTOEXCEL 将所有指标数据导出为Excel文件
%
% 输入：
%   allMetrics : runThesisResultPlots 返回的指标结构
%   methods    : 方法结构数组
%   outDir     : 输出目录
%   topoName   : 拓扑名称（可选，用于记录实验参数）
%
% 输出：
%   在 outDir 下生成 AllMetrics_Data.xlsx，包含多个Sheet
%   每个Sheet包含完整的曲线数据，便于论文制图
%   包含"实验参数"Sheet记录本次实验的配置信息

    if nargin < 4 || isempty(topoName)
        topoName = 'US_Backbone';  % 默认拓扑
    end

    xlsxPath = fullfile(outDir, 'AllMetrics_Data.xlsx');
    
    % 删除已有文件
    if isfile(xlsxPath)
        delete(xlsxPath);
    end
    
    methodNames = {methods.name}.';
    M = numel(methods);
    
    fprintf('正在导出指标数据到Excel...\n');
    
    %% ========== 0. 实验参数记录 ==========
    try
        exportExperimentParams(xlsxPath, topoName, methodNames);
        fprintf('  √ 实验参数\n');
    catch ME
        warning('导出实验参数失败: %s', ME.message);
    end
    
    %% ========== 1. 阻塞率变化曲线 ==========
    if isfield(allMetrics, 'blockingRate') && ~isempty(allMetrics.blockingRate)
        metric = allMetrics.blockingRate;
        
        % 找到最长的序列长度
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x));
        end
        
        % 创建数据矩阵（x轴 + 各方法的阻塞率）
        data = NaN(maxLen, M*2 + 1);  % [x, 方法1_累计阻塞, 方法1_阻塞率, ...]
        
        % 第一列为请求序号（使用第一个有效方法的x）
        for m = 1:M
            if numel(metric.methods(m).x) == maxLen
                data(:, 1) = metric.methods(m).x(:);
                break;
            end
        end
        if all(isnan(data(:,1)))
            data(:, 1) = (1:maxLen).';
        end
        
        varNames = {'请求序号'};
        for m = 1:M
            len = numel(metric.methods(m).x);
            data(1:len, 2*m) = metric.methods(m).cum_block(:);
            data(1:len, 2*m+1) = metric.methods(m).block_rate(:);
            varNames{end+1} = [methodNames{m}, '_累计阻塞'];
            varNames{end+1} = [methodNames{m}, '_阻塞率'];
        end
        
        T = array2table(data, 'VariableNames', varNames);
        writetable(T, xlsxPath, 'Sheet', '阻塞率曲线');
        fprintf('  √ 阻塞率曲线\n');
    end
    
    %% ========== 2. 平均端到端时延变化曲线 ==========
    if isfield(allMetrics, 'avgE2EDelay') && ~isempty(allMetrics.avgE2EDelay)
        metric = allMetrics.avgE2EDelay;
        
        % 找到最长的序列长度
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).e2e_delay_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_e2e_delay(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次时延'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '端到端时延曲线');
            fprintf('  √ 端到端时延曲线\n');
        end
    end
    
    %% ========== 3. 平均松弛比变化曲线 ==========
    if isfield(allMetrics, 'avgSlack') && ~isempty(allMetrics.avgSlack)
        metric = allMetrics.avgSlack;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).slack_abs_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_slack(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次裕量'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '松弛比曲线');
            fprintf('  √ 松弛比曲线\n');
        end
    end
    
    %% ========== 4. CPU资源消耗变化曲线 ==========
    if isfield(allMetrics, 'avgCPU') && ~isempty(allMetrics.avgCPU)
        metric = allMetrics.avgCPU;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).cpu_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_cpu(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次CPU'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', 'CPU消耗曲线');
            fprintf('  √ CPU消耗曲线\n');
        end
    end
    
    %% ========== 5. 内存资源消耗变化曲线 ==========
    if isfield(allMetrics, 'avgMemory') && ~isempty(allMetrics.avgMemory)
        metric = allMetrics.avgMemory;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).mem_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_mem(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次内存'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '内存消耗曲线');
            fprintf('  √ 内存消耗曲线\n');
        end
    end
    
    %% ========== 6. 带宽资源消耗变化曲线 ==========
    if isfield(allMetrics, 'avgBandwidth') && ~isempty(allMetrics.avgBandwidth)
        metric = allMetrics.avgBandwidth;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).bw_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_bw(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次带宽'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', '带宽消耗曲线');
            fprintf('  √ 带宽消耗曲线\n');
        end
    end
    
    %% ========== 7. VNF共享增益变化曲线 ==========
    if isfield(allMetrics, 'vnfShareGain') && ~isempty(allMetrics.vnfShareGain)
        metric = allMetrics.vnfShareGain;
        
        maxLen = 0;
        for m = 1:M
            maxLen = max(maxLen, numel(metric.methods(m).x_success));
        end
        
        if maxLen > 0
            data = NaN(maxLen, M*2 + 1);
            data(:, 1) = (1:maxLen).';
            
            varNames = {'成功部署数'};
            for m = 1:M
                len = numel(metric.methods(m).x_success);
                if len > 0
                    data(1:len, 2*m) = metric.methods(m).gain_ratio_per_accept(:);
                    data(1:len, 2*m+1) = metric.methods(m).avg_gain_ratio(:);
                end
                varNames{end+1} = [methodNames{m}, '_单次增益'];
                varNames{end+1} = [methodNames{m}, '_累计平均'];
            end
            
            T = array2table(data, 'VariableNames', varNames);
            writetable(T, xlsxPath, 'Sheet', 'VNF共享增益曲线');
            fprintf('  √ VNF共享增益曲线\n');
        end
    end
    
    %% ========== 8. 综合汇总表（最终值） ==========
    varNames = {'方法'};
    tableData = methodNames;
    
    if isfield(allMetrics, 'blockingRate')
        finalBlockRates = zeros(M, 1);
        totalBlocked = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.blockingRate.methods(m).block_rate)
                finalBlockRates(m) = allMetrics.blockingRate.methods(m).block_rate(end);
                totalBlocked(m) = allMetrics.blockingRate.methods(m).cum_block(end);
            end
        end
        tableData = [tableData, num2cell(finalBlockRates), num2cell(totalBlocked)];
        varNames = [varNames, {'最终阻塞率', '阻塞请求数'}];
    end
    
    if isfield(allMetrics, 'avgE2EDelay')
        avgDelays = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.avgE2EDelay.methods(m).avg_e2e_delay)
                avgDelays(m) = allMetrics.avgE2EDelay.methods(m).avg_e2e_delay(end);
            end
        end
        tableData = [tableData, num2cell(avgDelays)];
        varNames{end+1} = '平均时延';
    end
    
    if isfield(allMetrics, 'avgSlack')
        avgSlacks = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.avgSlack.methods(m).avg_slack)
                avgSlacks(m) = allMetrics.avgSlack.methods(m).avg_slack(end);
            end
        end
        tableData = [tableData, num2cell(avgSlacks)];
        varNames{end+1} = '平均裕量比';
    end
    
    if isfield(allMetrics, 'avgCPU')
        avgCPU = zeros(M, 1);
        avgMem = zeros(M, 1);
        avgBW = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.avgCPU.methods(m).avg_cpu)
                avgCPU(m) = allMetrics.avgCPU.methods(m).avg_cpu(end);
            end
            if ~isempty(allMetrics.avgMemory.methods(m).avg_mem)
                avgMem(m) = allMetrics.avgMemory.methods(m).avg_mem(end);
            end
            if ~isempty(allMetrics.avgBandwidth.methods(m).avg_bw)
                avgBW(m) = allMetrics.avgBandwidth.methods(m).avg_bw(end);
            end
        end
        tableData = [tableData, num2cell(avgCPU), num2cell(avgMem), num2cell(avgBW)];
        varNames = [varNames, {'平均CPU', '平均内存', '平均带宽'}];
    end
    
    if isfield(allMetrics, 'vnfShareGain')
        avgGain = zeros(M, 1);
        for m = 1:M
            if ~isempty(allMetrics.vnfShareGain.methods(m).avg_gain_ratio)
                avgGain(m) = allMetrics.vnfShareGain.methods(m).avg_gain_ratio(end);
            end
        end
        tableData = [tableData, num2cell(avgGain)];
        varNames{end+1} = 'VNF共享增益';
    end
    
    if isfield(allMetrics, 'failureBreakdown')
        totalFail = allMetrics.failureBreakdown.totalFail;
        tableData = [tableData, num2cell(totalFail)];
        varNames{end+1} = '失败总数';
    end
    
    T = cell2table(tableData, 'VariableNames', varNames);
    writetable(T, xlsxPath, 'Sheet', '综合汇总');
    fprintf('  √ 综合汇总\n');
    
    fprintf('✓ 所有指标数据已导出到: %s\n', xlsxPath);
end


%% ========== 辅助函数：导出实验参数 ==========
function exportExperimentParams(xlsxPath, topoName, methodNames)
%EXPORTEXPERIMENTPARAMS 导出实验参数到Excel的"实验参数"Sheet
%
% 记录内容：
%   1. 拓扑配置（getTopoCfg）
%   2. 请求配置（getReqCfg）
%   3. 各部署方法配置（getDeployMethodCfg）

    params = {};  % {参数类别, 参数名, 参数值}
    
    % ========== 1. 基本信息 ==========
    params(end+1, :) = {'基本信息', '实验时间', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'))};
    params(end+1, :) = {'基本信息', '拓扑名称', char(topoName)};
    params(end+1, :) = {'基本信息', '对比方法数', num2str(numel(methodNames))};
    params(end+1, :) = {'基本信息', '对比方法列表', strjoin(methodNames, ', ')};
    
    % ========== 2. 拓扑配置 ==========
    try
        topoCfg = getTopoCfg(topoName);
        params(end+1, :) = {'拓扑配置', '拓扑函数', topoCfg.topoFunc};
        params(end+1, :) = {'拓扑配置', '节点内存范围', sprintf('[%d, %d]', topoCfg.minm, topoCfg.maxm)};
        params(end+1, :) = {'拓扑配置', '节点CPU范围', sprintf('[%d, %d]', topoCfg.minc, topoCfg.maxc)};
        params(end+1, :) = {'拓扑配置', '链路带宽范围', sprintf('[%d, %d]', topoCfg.minb, topoCfg.maxb)};
    catch
        params(end+1, :) = {'拓扑配置', '状态', '获取失败'};
    end
    
    % ========== 3. 请求配置 ==========
    try
        reqCfg = getReqCfg(topoName);
        params(end+1, :) = {'请求配置', '目的节点数', num2str(reqCfg.destNode_count)};
        params(end+1, :) = {'请求配置', '请求集合数', num2str(reqCfg.requests_set_index)};
        params(end+1, :) = {'请求配置', '每组请求数', num2str(reqCfg.requests_num)};
        params(end+1, :) = {'请求配置', 'VNF类型总数', num2str(reqCfg.vnftype_num)};
        params(end+1, :) = {'请求配置', '每请求VNF数', num2str(reqCfg.vnf_num)};
        params(end+1, :) = {'请求配置', '带宽需求范围', sprintf('[%d, %d]', reqCfg.minbw, reqCfg.maxbw)};
        params(end+1, :) = {'请求配置', '节点资源需求范围', sprintf('[%d, %d]', reqCfg.minnr, reqCfg.maxnr)};
        params(end+1, :) = {'请求配置', '最大时延范围', sprintf('[%d, %d]', reqCfg.mint, reqCfg.maxt)};
    catch
        params(end+1, :) = {'请求配置', '状态', '获取失败'};
    end
    
    % ========== 4. 各部署方法配置 ==========
    for i = 1:numel(methodNames)
        methodName = methodNames{i};
        try
            methodCfg = getDeployMethodCfg(methodName, topoName);
            category = sprintf('方法配置-%s', methodCfg.displayName);
            
            params(end+1, :) = {category, '方法原名', methodName};
            params(end+1, :) = {category, '显示名称', methodCfg.displayName};
            params(end+1, :) = {category, '部署函数', methodCfg.deployFunc};
            params(end+1, :) = {category, '请求类型', methodCfg.requestsType};
            params(end+1, :) = {category, '多播树修复函数', methodCfg.FixedFunc};
            
            % RDA特有参数
            if isfield(methodCfg, 'candLinkNum')
                params(end+1, :) = {category, '候选路径数', num2str(methodCfg.candLinkNum)};
            end
            if isfield(methodCfg, 'candNodeNum')
                params(end+1, :) = {category, '候选节点数', num2str(methodCfg.candNodeNum)};
            end
            if isfield(methodCfg, 'shareWeight')
                params(end+1, :) = {category, '共享权重', num2str(methodCfg.shareWeight)};
            end
            if isfield(methodCfg, 'congWeight')
                params(end+1, :) = {category, '拥塞权重', num2str(methodCfg.congWeight)};
            end
            if isfield(methodCfg, 'delayWeight')
                params(end+1, :) = {category, '时延权重', num2str(methodCfg.delayWeight)};
            end
            if isfield(methodCfg, 'onlineMode')
                params(end+1, :) = {category, '在线模式', mat2str(methodCfg.onlineMode)};
            end
        catch
            params(end+1, :) = {sprintf('方法配置-%s', methodName), '状态', '获取失败'};
        end
    end
    
    % ========== 写入Excel ==========
    T = cell2table(params, 'VariableNames', {'参数类别', '参数名称', '参数值'});
    writetable(T, xlsxPath, 'Sheet', '实验参数');
end
