function plot_gantt_chart(nodes, outDir, cfg, methodName)
%PLOT_GANTT_CHART  节点任务甘特图（特殊：需运行时 nodes 数据）
%
%   plot_gantt_chart(nodes)
%   plot_gantt_chart(nodes, outDir, cfg, methodName)
%
% 甘特图需要完整的 nodes struct（含 tasks 字段），不能纯从 xlsx 驱动，
% 但仍支持从 read_global_cfg 获取绘图配置。

    if nargin < 1 || isempty(nodes)
        error('plot_gantt_chart 需要 nodes 结构体作为输入');
    end
    if nargin < 3 || isempty(cfg)
        try cfg = read_global_cfg(); catch; cfg = default_cfg(); end
    end
    if nargin < 2 || isempty(outDir)
        outDir = cfg.outDir;
    end
    if nargin < 4 || isempty(methodName)
        methodName = 'Method';
    end
    ensure_dir(outDir);

    allTasks = [];
    for n = 1:numel(nodes)
        if ~isfield(nodes(n), 'tasks') || isempty(nodes(n).tasks)
            continue;
        end
        for t = 1:numel(nodes(n).tasks)
            task = nodes(n).tasks(t);
            task.node_id = n;
            if isempty(allTasks)
                allTasks = task;
            else
                allTasks(end+1) = task; %#ok<AGROW>
            end
        end
    end

    if isempty(allTasks)
        warning('plot_gantt_chart: 没有找到任何任务记录');
        return;
    end

    t0 = 1;
    for i = 1:numel(allTasks)
        allTasks(i).t_start = allTasks(i).t_start - t0;
        allTasks(i).t_end   = allTasks(i).t_end   - t0;
    end

    node_ids  = unique([allTasks.node_id]);
    num_nodes = numel(node_ids);
    req_ids   = unique([allTasks.req_id]);
    num_reqs  = numel(req_ids);

    if num_reqs <= 10
        colors = lines(num_reqs);
    else
        colors = hsv(num_reqs);
    end
    req_color_map = containers.Map(req_ids, num2cell(colors, 2));

    all_times = [[allTasks.t_start], [allTasks.t_end]];
    t_max = max(all_times);
    px_per_time = 25;
    fig_w = max(1400, round(px_per_time * t_max));
    fig_h = max(650,  round(26 * num_nodes + 220));

    fig = figure('Visible', cfg.figVisible, 'Units','pixels', 'Position',[50 50 fig_w fig_h]);
    set(fig, 'PaperPositionMode', 'auto');
    hold on;

    bar_height = 0.8;
    for i = 1:numel(allTasks)
        task = allTasks(i);
        y_pos = find(node_ids == task.node_id, 1);
        t_start  = task.t_start;
        duration = task.t_end - t_start;
        if duration <= 0; continue; end

        color = req_color_map(task.req_id);
        rectangle('Position', [t_start, y_pos - bar_height/2, duration, bar_height], ...
                  'FaceColor', color, 'EdgeColor','k', 'LineWidth',0.5);

        if duration >= 4;     fs = 8;
        elseif duration >= 2; fs = 7;
        else;                 fs = 6;
        end

        text(t_start + duration/2, y_pos, sprintf('%d/%d', task.req_id, task.vnf_id), ...
             'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
             'FontSize', fs, 'Clipping','on', 'Color', contrast_color(color));
    end

    ylim([0.5, num_nodes + 0.5]);
    yticks(1:num_nodes);
    yticklabels(arrayfun(@num2str, node_ids, 'UniformOutput', false));
    ylabel('节点');
    xlim([0, t_max * 1.05]);
    xlabel('完成时间');
    grid on;
    set(gca, 'FontSize', cfg.fontSize);
    title(sprintf('任务甘特图 - %s', methodName));
    hold off;

    if cfg.saveSvg
        figName = sprintf('Fig_GanttChart_%s.svg', methodName);
        save_svg(fig, fullfile(outDir, figName), cfg.svgBackground);
    end
    close(fig);
end

function tc = contrast_color(bg)
    lum = 0.299*bg(1) + 0.587*bg(2) + 0.114*bg(3);
    if lum > 0.5; tc = [0 0 0]; else; tc = [1 1 1]; end
end

function cfg = default_cfg()
    cfg = struct('figVisible','off','lineWidth',1.8,'fontSize',12, ...
                 'saveSvg',true,'svgBackground','none','slackMode','ratio', ...
                 'outDir',fullfile('c.输出','5.结果图保存'),'saveMat',false);
end
