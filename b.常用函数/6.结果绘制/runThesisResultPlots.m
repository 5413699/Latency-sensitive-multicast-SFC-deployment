function allMetrics = runThesisResultPlots(methods, outDir, cfg)
%RUNTHESISRESULTPLOTS  一键生成论文需要的结果图（多方法对比）
%
% 输入：
%   methods : struct 数组，每个元素至少包含：
%             .name, .nodes, .links, .requests, .consume, .fail_log
%             （可通过 loadMethodResultsFromPaths() 快速构造）
%   outDir  : 输出目录（会自动创建）
%   cfg     : getPlotCfg() 返回的配置（可省略）
%
% 输出：
%   allMetrics : 汇总结构（同时也会另存为 allMetrics.mat）
%
% 你将得到多张 svg 图：
%   1) Fig_AcceptanceRate.svg
%   2) Fig_AvgE2EDelay_vs_Success.svg
%   3) Fig_AvgSlackRatio_vs_Success.svg  (或 SlackAbs)
%   4) Fig_AvgCPUConsume_vs_Success.svg
%   5) Fig_AvgMemoryConsume_vs_Success.svg
%   6) Fig_AvgBandwidthConsume_vs_Success.svg
%   7) Fig_VNFSharingGainRatio_vs_Success.svg
%   8) Fig_CumulativeResourceConsume.svg  (累计资源消耗，含CPU/内存/带宽)
%   9) Fig_FailureBreakdownDistribution.svg
%  10) Fig_GanttChart_{MethodName}.svg  (每个方法一张)
%
% Excel 数据导出：
%   - Data_CumulativeResourceConsume.xlsx (累计资源消耗明细)

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    if nargin < 2 || isempty(outDir)
        outDir = fullfile(pwd, 'thesis_plots_output');
    end
    ensure_dir(outDir);

    allMetrics = struct();

    % ---------- QoS ----------
    allMetrics.blockingRate = plot_blocking_rate_curve(methods, outDir, cfg);
    allMetrics.avgE2EDelay    = plot_avg_e2e_delay_vs_success(methods, outDir, cfg);
    allMetrics.avgSlack       = plot_avg_slack_vs_success(methods, outDir, cfg);

    % ---------- Resource Efficiency ----------
    allMetrics.avgCPU         = plot_avg_cpu_consume_vs_success(methods, outDir, cfg);
    allMetrics.avgMemory      = plot_avg_memory_consume_vs_success(methods, outDir, cfg);
    allMetrics.avgBandwidth   = plot_avg_bandwidth_consume_vs_success(methods, outDir, cfg);
    allMetrics.vnfShareGain   = plot_vnf_sharing_gain_ratio_vs_success(methods, outDir, cfg);
    allMetrics.cumulativeConsume = plot_cumulative_resource_consume(methods, outDir, cfg);

    % ---------- System Stability ----------
    allMetrics.failureBreakdown = plot_failure_breakdown_distribution(methods, outDir, cfg);

    % ---------- Gantt Charts (每个方法单独绘制) ----------
    allMetrics.ganttCharts = cell(numel(methods), 1);
    for m = 1:numel(methods)
        allMetrics.ganttCharts{m} = plot_gantt_chart(methods(m).nodes, outDir, cfg, methods(m).name);
    end

    % 汇总保存（方便你后续做表格/写论文）
    if cfg.saveMat
        save(fullfile(outDir, 'AllMetrics_Summary.mat'), 'allMetrics', 'cfg');
    end
    
    % ========== 导出Excel数据（便于制图） ==========
    try
        % 获取拓扑名称（从配置中提取）
        if isfield(cfg, 'topoFilter') && ~isempty(cfg.topoFilter) && strlength(cfg.topoFilter) > 0
            topoName = char(cfg.topoFilter);
        else
            topoName = 'US_Backbone';  % 默认拓扑
        end
        exportMetricsToExcel(allMetrics, methods, outDir, topoName);
    catch ME
        warning(ME.identifier, '导出Excel失败: %s', ME.message);
    end
end
