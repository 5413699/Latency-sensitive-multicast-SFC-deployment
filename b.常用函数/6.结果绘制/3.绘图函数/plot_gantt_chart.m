function metric = plot_gantt_chart(nodes, outDir, cfg, methodName)
%PLOT_GANTT_CHART  绘制节点任务甘特图
%
% 根据 nodes.tasks 绘制甘特图，展示各节点上 VNF 任务的执行时间段。
% 每个色块显示 "sfc{req_id}" 和 "vnf{vnf_id}"。
%
% 输入：
%   nodes      : 节点数组（包含 tasks 字段）
%   outDir     : 输出目录（svg 与 mat 都会存这里）
%   cfg        : getPlotCfg() 返回的配置（可选）
%   methodName : 方法名称（用于文件命名，可选）
%
% 输出：
%   metric : 用于画图的指标变量（也会被保存为 mat）

    if nargin < 3 || isempty(cfg)
        cfg = getPlotCfg();
    end
    if nargin < 4 || isempty(methodName)
        methodName = 'Method';
    end
    ensure_dir(outDir);

    % ===================== 1) 收集所有任务 =====================
    allTasks = [];
    for n = 1:numel(nodes)
        if ~isfield(nodes(n), 'tasks') || isempty(nodes(n).tasks)
            continue;
        end
        for t = 1:numel(nodes(n).tasks)
            task = nodes(n).tasks(t);
            task.node_id = n;  % 记录节点ID
            if isempty(allTasks)
                allTasks = task;
            else
                allTasks(end+1) = task; %#ok<AGROW>
            end
        end
    end

    if isempty(allTasks)
        warning('plot_gantt_chart: 没有找到任何任务记录');
        metric = struct();
        metric.metric_name = 'gantt_chart';
        metric.tasks = [];
        return;
    end

    % ===================== 1.5) 时间轴统一从0开始 =====================
    % 说明：MATLAB数据从1开始是索引习惯；作图时统一减1使时间从0开始
    t0 = 1;  % 固定减1（MATLAB索引从1开始，实际时间应从0开始）
    for i = 1:numel(allTasks)
        allTasks(i).t_start = allTasks(i).t_start - t0;
        allTasks(i).t_end   = allTasks(i).t_end   - t0;
    end

    % 保存指标
    metric = struct();
    metric.metric_name = 'gantt_chart';
    metric.methodName = methodName;
    metric.tasks = allTasks;
    metric.node_ids = unique([allTasks.node_id]);
    metric.time_shift_to_zero = t0; % 记录平移量（原始时间 - t0）

    % ===================== 2) 绘图准备 =====================
    % 获取所有涉及的节点
    node_ids = unique([allTasks.node_id]);
    num_nodes = numel(node_ids);
    
    % 获取所有请求ID用于生成颜色映射
    req_ids = unique([allTasks.req_id]);
    num_reqs = numel(req_ids);
    
    % 生成颜色映射（每个请求一个颜色）
    if num_reqs <= 10
        colors = lines(num_reqs);
    else
        colors = hsv(num_reqs);
    end
    req_color_map = containers.Map(req_ids, num2cell(colors, 2));

    % ===================== 3) 绘制甘特图 =====================
    % 让甘特图更“宽”，以便色块上的文字全部使用“一行显示”
    % 尺寸随最大完成时间/节点数自适应（像素）
    all_times = [[allTasks.t_start], [allTasks.t_end]];
    t_max = max(all_times);
    px_per_time = 25;            % 每单位时间对应的像素宽度（越大越宽）
    fig_w = max(1400, round(px_per_time * t_max));
    fig_h = max(650,  round(26 * num_nodes + 220));

    fig = figure('Visible', cfg.figVisible, 'Units', 'pixels', 'Position', [50, 50, fig_w, fig_h]);
    set(fig, 'PaperPositionMode', 'auto'); % 保存svg时使用当前窗口大小
    hold on;

    bar_height = 0.8;  % 色块高度
    
    for i = 1:numel(allTasks)
        task = allTasks(i);
        
        % 找到该节点在 y 轴的位置
        y_pos = find(node_ids == task.node_id, 1);
        
        % 任务时间
        t_start = task.t_start;
        t_end = task.t_end;
        duration = t_end - t_start;
        
        if duration <= 0
            continue;
        end
        
        % 获取颜色
        color = req_color_map(task.req_id);
        
        % 绘制矩形
        rectangle('Position', [t_start, y_pos - bar_height/2, duration, bar_height], ...
                  'FaceColor', color, ...
                  'EdgeColor', 'k', ...
                  'LineWidth', 0.5);
        
        % 添加标签：所有色块统一只显示一行（req_id/vnf_id）
        % 依赖更宽的画布提升可读性；极短任务仍可能拥挤，但保持“一行规则”一致
        label_x = t_start + duration/2;
        label_y = y_pos;

        % 根据色块宽度粗略调节字号（仍保持单行）
        if duration >= 4
            fs = 8;
        elseif duration >= 2
            fs = 7;
        else
            fs = 6;
        end

        text(label_x, label_y, sprintf('%d/%d', task.req_id, task.vnf_id), ...
             'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', ...
             'FontSize', fs, ...
             'Clipping', 'on', ...
             'Color', getContrastColor(color));
    end

    % ===================== 4) 设置坐标轴 =====================
    % Y轴
    ylim([0.5, num_nodes + 0.5]);
    yticks(1:num_nodes);
    yticklabels(arrayfun(@num2str, node_ids, 'UniformOutput', false));
    ylabel('节点');

    % X轴
    xlim([0, t_max * 1.05]);
    xlabel('完成时间');

    % 其他设置
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    title(sprintf('任务甘特图 - %s', methodName));
    
    % 添加图例说明
    annotation('textbox', [0.75, 0.02, 0.2, 0.05], ...
               'String', '色块标注: 请求ID/VNF类型ID', ...
               'EdgeColor', 'none', ...
               'FontSize', 8, ...
               'HorizontalAlignment', 'right');

    hold off;

    % ===================== 5) 保存 =====================
    figName = sprintf('Fig_GanttChart_%s.svg', methodName);
    matName = sprintf('Metric_GanttChart_%s.mat', methodName);
    
    if cfg.saveSvg
        save_svg(fig, fullfile(outDir, figName), cfg.svgBackground);
    end
    if cfg.saveMat
        save(fullfile(outDir, matName), 'metric');
    end

    close(fig);
end

function textColor = getContrastColor(bgColor)
%GETCONTRASTCOLOR  根据背景色返回对比文字颜色（黑或白）
    luminance = 0.299 * bgColor(1) + 0.587 * bgColor(2) + 0.114 * bgColor(3);
    if luminance > 0.5
        textColor = [0, 0, 0];  % 黑色
    else
        textColor = [1, 1, 1];  % 白色
    end
end

