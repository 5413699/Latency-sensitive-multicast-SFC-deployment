function gcfg = read_global_cfg(xlsx_path)
%READ_GLOBAL_CFG  从批量实验配置 xlsx 读取全局绘图参数
%
%   gcfg = read_global_cfg()
%   gcfg = read_global_cfg('a.输入/批量实验配置.xlsx')
%
% 供各绘图函数在无参独立运行时使用，避免加载完整 cfg。

    if nargin < 1 || isempty(xlsx_path)
        xlsx_path = fullfile('a.输入', '批量实验配置.xlsx');
    end

    tbl = readtable(xlsx_path, 'Sheet','全局设置', 'TextType','string');
    gcfg = struct();
    for i = 1:height(tbl)
        k = char(tbl.key(i));
        v = tbl.value(i);
        num = str2double(v);
        if ~isnan(num)
            gcfg.(k) = num;
        else
            gcfg.(k) = char(v);
        end
    end

    % 绘图函数需要的标准字段名映射
    if isfield(gcfg, 'fig_visible')
        gcfg.figVisible = gcfg.fig_visible;
    else
        gcfg.figVisible = 'off';
    end
    if isfield(gcfg, 'line_width')
        gcfg.lineWidth = gcfg.line_width;
    else
        gcfg.lineWidth = 1.8;
    end
    if isfield(gcfg, 'font_size')
        gcfg.fontSize = gcfg.font_size;
    else
        gcfg.fontSize = 12;
    end
    if isfield(gcfg, 'fig_width')
        gcfg.figWidth = gcfg.fig_width;
    else
        gcfg.figWidth = 800;
    end
    if isfield(gcfg, 'fig_height')
        gcfg.figHeight = gcfg.fig_height;
    else
        gcfg.figHeight = 600;
    end
    if isfield(gcfg, 'save_svg')
        gcfg.saveSvg = logical(gcfg.save_svg);
    else
        gcfg.saveSvg = true;
    end
    if isfield(gcfg, 'svg_background')
        gcfg.svgBackground = gcfg.svg_background;
    else
        gcfg.svgBackground = 'none';
    end
    if ~isfield(gcfg, 'slack_mode')
        gcfg.slack_mode = 'ratio';
    end
    gcfg.slackMode = gcfg.slack_mode;

    if ~isfield(gcfg, 'output_dir')
        gcfg.output_dir = 'c.输出';
    end
    gcfg.outDir = fullfile(gcfg.output_dir, '5.结果图保存');
    gcfg.saveMat = false;
end
