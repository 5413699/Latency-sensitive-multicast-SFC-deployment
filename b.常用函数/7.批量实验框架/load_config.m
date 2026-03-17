function cfg = load_config(xlsx_path)
%LOAD_CONFIG  从批量实验配置 xlsx 读取全部配置
%
%   cfg = load_config()
%   cfg = load_config('a.输入/批量实验配置.xlsx')
%
% 输出 cfg 结构体：
%   .experiments  -- table (Sheet "实验组合")
%   .topos        -- table (Sheet "拓扑配置")
%   .requests     -- table (Sheet "请求配置")
%   .methods      -- table (Sheet "方法配置")
%   .param_groups -- table (Sheet "方法参数组")
%   .global       -- struct (Sheet "全局设置", key-value -> struct)
%   .xlsx_path    -- string

    if nargin < 1 || isempty(xlsx_path)
        xlsx_path = fullfile('a.输入', '批量实验配置.xlsx');
    end

    if ~isfile(xlsx_path)
        fprintf('配置文件不存在，正在生成默认配置: %s\n', xlsx_path);
        create_default_config_xlsx(xlsx_path);
    end

    opts = {'TextType','string'};

    cfg.experiments  = readtable(xlsx_path, 'Sheet','实验组合',  opts{:});
    cfg.topos        = readtable(xlsx_path, 'Sheet','拓扑配置',  opts{:});
    cfg.requests     = readtable(xlsx_path, 'Sheet','请求配置',  opts{:});
    cfg.methods      = readtable(xlsx_path, 'Sheet','方法配置',  opts{:});
    cfg.param_groups = readtable(xlsx_path, 'Sheet','方法参数组', opts{:});

    global_tbl = readtable(xlsx_path, 'Sheet','全局设置', opts{:});
    cfg.global = struct();
    for i = 1:height(global_tbl)
        k = char(global_tbl.key(i));
        v = global_tbl.value(i);
        num = str2double(v);
        if ~isnan(num)
            cfg.global.(k) = num;
        else
            cfg.global.(k) = char(v);
        end
    end

    cfg.xlsx_path = xlsx_path;
end
