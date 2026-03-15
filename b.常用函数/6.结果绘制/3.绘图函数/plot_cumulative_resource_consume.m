function metric = plot_cumulative_resource_consume(methods, outDir, cfg)
%PLOT_CUMULATIVE_RESOURCE_CONSUME  累计资源消耗随成功部署数量变化（多方法对比）
%
% 功能：
%   绘制随成功部署请求数增加，CPU、内存、带宽的累计消耗曲线
%   同时导出数据到Excel文件
%
% 定义：
%   对每个成功请求 k：
%     cumCpu(k) = sum(cpu_1 ... cpu_k)
%     cumMem(k) = sum(mem_1 ... mem_k)
%     cumBw(k)  = sum(bw_1  ... bw_k)
%
% 输入：
%   methods : 结构体数组，每个元素包含：
%     .name     : 方法名称
%     .requests : 请求数组
%     .consume  : 消耗数组
%   outDir  : 输出目录
%   cfg     : 绘图配置（可选）
%
% 输出：
%   metric  : 包含计算结果的结构体

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    ensure_dir(outDir);

    metric = struct();
    metric.metric_name = 'cumulative_resource_consume';
    metric.methods = repmat(struct('name','', 'x_success',[], ...
        'cum_cpu',[], 'cum_mem',[], 'cum_bw',[], ...
        'cpu_per_accept',[], 'mem_per_accept',[], 'bw_per_accept',[], ...
        'req_id_per_accept',[]), numel(methods), 1);

    % ===================== 1) 计算各方法的累计消耗 =====================
    for m = 1:numel(methods)
        [~, ~, accepted_req_ids] = extractAcceptedInfo(methods(m).requests, methods(m).consume);

        A = numel(accepted_req_ids);
        cpu = zeros(A,1);
        mem = zeros(A,1);
        bw  = zeros(A,1);
        
        for k = 1:A
            rid = accepted_req_ids(k);
            cpu(k) = methods(m).consume(rid).cpu_consume;
            mem(k) = methods(m).consume(rid).memory_consume;
            bw(k)  = methods(m).consume(rid).bandwidth_consume;
        end

        x = (1:A).';
        cum_cpu = cumsum(cpu);
        cum_mem = cumsum(mem);
        cum_bw  = cumsum(bw);

        metric.methods(m).name = methods(m).name;
        metric.methods(m).x_success = x;
        metric.methods(m).cum_cpu = cum_cpu;
        metric.methods(m).cum_mem = cum_mem;
        metric.methods(m).cum_bw  = cum_bw;
        metric.methods(m).cpu_per_accept = cpu;
        metric.methods(m).mem_per_accept = mem;
        metric.methods(m).bw_per_accept  = bw;
        metric.methods(m).req_id_per_accept = accepted_req_ids;
    end

    % ===================== 2) 绘制三个子图 =====================
    [figW, figH] = calcFigureSize('subplot3', {methods.name}, cfg);
    fig = figure('Visible', cfg.figVisible, 'Position', [100, 100, figW, figH]);
    
    colors = lines(numel(methods));
    methodNames = {methods.name};

    % ---------- 子图1: 累计CPU消耗 ----------
    subplot(1, 3, 1);
    hold on;
    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).cum_cpu, ...
             'LineWidth', cfg.lineWidth, 'Color', colors(m,:));
    end
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('累计 CPU 消耗');
    title('累计 CPU 消耗');
    legend(methodNames, 'Location', 'northwest');

    % ---------- 子图2: 累计内存消耗 ----------
    subplot(1, 3, 2);
    hold on;
    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).cum_mem, ...
             'LineWidth', cfg.lineWidth, 'Color', colors(m,:));
    end
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('累计内存消耗');
    title('累计内存消耗');
    legend(methodNames, 'Location', 'northwest');

    % ---------- 子图3: 累计带宽消耗 ----------
    subplot(1, 3, 3);
    hold on;
    for m = 1:numel(methods)
        plot(metric.methods(m).x_success, metric.methods(m).cum_bw, ...
             'LineWidth', cfg.lineWidth, 'Color', colors(m,:));
    end
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    xlabel('已成功部署的 SFC 数量');
    ylabel('累计带宽消耗');
    title('累计带宽消耗');
    legend(methodNames, 'Location', 'northwest');

    sgtitle('累计资源消耗随成功部署数量变化', 'FontSize', cfg.fontSize + 2);

    % ===================== 3) 保存图形 =====================
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, 'Fig_CumulativeResourceConsume.svg'), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, 'Metric_CumulativeResourceConsume.mat'), 'metric');
    end

    % ===================== 4) 导出Excel =====================
    try
        exportCumulativeToExcel(metric, outDir);
        fprintf('累计资源消耗数据已导出到 Excel\n');
    catch ME
        warning(ME.identifier, '%s', ME.message);
    end

    close(fig);
end

function exportCumulativeToExcel(metric, outDir)
%EXPORTCUMULATIVETOEXCEL 导出累计资源消耗数据到Excel
    
    xlsxFile = fullfile(outDir, 'Data_CumulativeResourceConsume.xlsx');
    
    % 找出最大成功数（用于对齐列）
    maxSuccess = 0;
    for m = 1:numel(metric.methods)
        maxSuccess = max(maxSuccess, numel(metric.methods(m).x_success));
    end
    
    if maxSuccess == 0
        warning('没有成功部署的请求，跳过Excel导出');
        return;
    end
    
    numMethods = numel(metric.methods);
    
    % ========== Sheet 1: 累计CPU消耗 ==========
    header = cell(1, numMethods + 1);
    header{1} = '成功部署数';
    for m = 1:numMethods
        header{m+1} = metric.methods(m).name;
    end
    
    dataMatrix = cell(maxSuccess, numMethods + 1);
    for k = 1:maxSuccess
        dataMatrix{k, 1} = k;
        for m = 1:numMethods
            if k <= numel(metric.methods(m).cum_cpu)
                dataMatrix{k, m+1} = metric.methods(m).cum_cpu(k);
            else
                dataMatrix{k, m+1} = '';
            end
        end
    end
    
    T_cpu = cell2table([header; dataMatrix]);
    writetable(T_cpu, xlsxFile, 'Sheet', '累计CPU消耗', 'WriteVariableNames', false);
    
    % ========== Sheet 2: 累计内存消耗 ==========
    dataMatrix = cell(maxSuccess, numMethods + 1);
    for k = 1:maxSuccess
        dataMatrix{k, 1} = k;
        for m = 1:numMethods
            if k <= numel(metric.methods(m).cum_mem)
                dataMatrix{k, m+1} = metric.methods(m).cum_mem(k);
            else
                dataMatrix{k, m+1} = '';
            end
        end
    end
    
    T_mem = cell2table([header; dataMatrix]);
    writetable(T_mem, xlsxFile, 'Sheet', '累计内存消耗', 'WriteVariableNames', false);
    
    % ========== Sheet 3: 累计带宽消耗 ==========
    dataMatrix = cell(maxSuccess, numMethods + 1);
    for k = 1:maxSuccess
        dataMatrix{k, 1} = k;
        for m = 1:numMethods
            if k <= numel(metric.methods(m).cum_bw)
                dataMatrix{k, m+1} = metric.methods(m).cum_bw(k);
            else
                dataMatrix{k, m+1} = '';
            end
        end
    end
    
    T_bw = cell2table([header; dataMatrix]);
    writetable(T_bw, xlsxFile, 'Sheet', '累计带宽消耗', 'WriteVariableNames', false);
    
    % ========== Sheet 4: 每请求资源消耗明细 ==========
    % 创建详细的每请求消耗表格
    allRows = {};
    for m = 1:numMethods
        methodName = metric.methods(m).name;
        A = numel(metric.methods(m).req_id_per_accept);
        for k = 1:A
            row = {methodName, k, metric.methods(m).req_id_per_accept(k), ...
                   metric.methods(m).cpu_per_accept(k), ...
                   metric.methods(m).mem_per_accept(k), ...
                   metric.methods(m).bw_per_accept(k)};
            allRows = [allRows; row]; %#ok<AGROW>
        end
    end
    
    if ~isempty(allRows)
        detailHeader = {'方法名称', '成功序号', '请求ID', 'CPU消耗', '内存消耗', '带宽消耗'};
        T_detail = cell2table([detailHeader; allRows]);
        writetable(T_detail, xlsxFile, 'Sheet', '每请求消耗明细', 'WriteVariableNames', false);
    end
    
    fprintf('数据已导出到: %s\n', xlsxFile);
end
