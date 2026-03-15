function cfg = getPlotCfg(topoName)
%GETPLOTCFG  结果绘图的统一配置（论文作图用）
%
% 用法：
%   cfg = getPlotCfg();            % 默认配置，不按拓扑过滤
%   cfg = getPlotCfg('US_Backbone'); % 只绘制 US_Backbone 拓扑的结果
%   cfg = getPlotCfg('Abilene');     % 只绘制 Abilene 拓扑的结果
%
% 输出 cfg 常用字段：
%   ---------- 路径与过滤 ----------
%   cfg.topoFilter    : 拓扑过滤关键字（匹配文件路径，留空则不过滤）
%   cfg.autoScan      : 是否自动扫描 baseResultDir 下的 *result.mat
%   cfg.baseResultDir : 结果目录（相对于项目根目录）
%   cfg.outDir        : 输出目录（相对于项目根目录）
%
%   ---------- 绘图外观 ----------
%   cfg.figVisible    : 'on' or 'off'（建议 'off'，批量画图更快）
%   cfg.lineWidth     : 曲线线宽
%   cfg.fontSize      : 字体大小
%
%   ---------- 保存选项 ----------
%   cfg.saveSvg       : 是否保存 svg
%   cfg.saveMat       : 是否保存 mat（保存用于作图的指标变量）
%   cfg.svgBackground : svg 保存时的背景（'none' 更适合论文排版）
%
%   ---------- 指标计算 ----------
%   cfg.slackMode     : 'ratio' 画"裕量比例" 或 'abs' 画"裕量时延"
%   cfg.e2eSource     : 'auto'（自动优先使用 requests.e2e_delay/branch_end_time）
%
% 说明：
%   - 本配置控制"数据来源/过滤"与"画图/保存"策略，不会改变你的实验逻辑。

    cfg = struct();

    % ==================== 路径与过滤 ====================
    % 拓扑过滤：只保留文件路径中包含此关键字的结果（大小写不敏感）
    % 留空 "" 则不做过滤
    if nargin < 1 || isempty(topoName)
        cfg.topoFilter = "";
    else
        cfg.topoFilter = string(topoName);
    end

    % 是否自动扫描 baseResultDir 下的所有 *result.mat
    cfg.autoScan = true;

    % 结果目录（相对于项目根目录）
    cfg.baseResultDir = fullfile('c.输出', '4.资源消耗与失败日志');

    % 输出目录（相对于项目根目录）
    cfg.outDir =  fullfile('c.输出', '5.结果图保存');

    % ==================== 绘图外观 ====================
    % 图是否可见（批量出图推荐 off）
    cfg.figVisible = 'off';

    % 外观
    cfg.lineWidth = 1.8;
    cfg.fontSize  = 12;
    
    % ==================== 图形尺寸（确保图例完整显示） ====================
    % 单图尺寸（用于大多数单曲线对比图）
    cfg.figWidth  = 800;   % 图形宽度（像素）
    cfg.figHeight = 600;   % 图形高度（像素）
    
    % 宽图尺寸（用于多子图横向排列，如累计资源消耗）
    cfg.figWidthWide  = 1500;  % 宽图宽度
    cfg.figHeightWide = 520;   % 宽图高度（需足够容纳主标题+子标题+x轴标签）
    
    % 柱状图尺寸（用于失败分布等）
    cfg.figWidthBar  = 900;
    cfg.figHeightBar = 550;

    % ==================== 保存选项 ====================
    cfg.saveSvg = true;
    cfg.saveMat = true;

    % svg 保存时的背景（'none' 更适合论文排版）
    cfg.svgBackground = 'none';

    % ==================== 指标计算 ====================
    % 裕量曲线：ratio 更适合不同 max_delay 的请求做公平比较
    cfg.slackMode = 'ratio';   % 'ratio' or 'abs'

    % 端到端时延来源
    %   auto：优先 requests(i).e2e_delay 或 requests(i).branch_end_time；
    %         若没有，再尝试用 nodes.tasks 估计。
    cfg.e2eSource = 'auto';

    % ==================== 方法显示名（图例） ====================
    % 说明：
    % - resultPlot.m 会扫描 result.mat 文件名得到方法名（如 nodeFirst）
    % - 这里提供一个“方法名 -> 图例显示名”的映射，用于统一论文图例命名
    % - 你后续要添加新方法时，只需要：
    %   1) 在 cfg.methodDisplayNames 里加一条映射（raw 方法名 -> 你想显示的图例名）
    %   2) 若你只想画特定几种方法，再在 cfg.compareMethods 里加入该 raw 方法名即可
    %
    % 统一图例命名：
    %   nodeFirst                       -> NIF
    %   shortestPathFirstWithLoadBalancing -> STB
    %   ResourceAndDelayAware(Online)   -> RDA
    %   RSA                             -> RSA
    cfg.methodDisplayNames = containers.Map( ...
        {'nodeFirst', ...
        'shortestPathFirstWithLoadBalancing', ...
        'ResourceAndDelayAware', ...
        'ResourceAndDelayAwareOnline', ...
        'RSA'}, ...
        {'NIF', ...
        'STB', ...
        'RDA', ...
        'RDA', ...
        'RSA'} ...
    );

    % ==================== 对比方法筛选与顺序（可选） ====================
    % 若非空，则 resultPlot.m 会：
    % - 只保留这些方法（白名单）
    % - 并按这里给定的顺序排列（保证图例顺序稳定）
    %
    % 【重要】RDA 放在第一位，确保在图例中排第一
    % 方法顺序：RDA -> NIF -> STB -> RSA
    cfg.compareMethods = { ...
        'ResourceAndDelayAwareOnline', ...
        'nodeFirst', ...
        'shortestPathFirstWithLoadBalancing', ...
        'RSA'
    };

    % 若映射后出现重复名称（例如同时加载 ResourceAndDelayAware 和 ResourceAndDelayAwareOnline 都会变成 RDA），
    % 是否自动加后缀做区分（仅在必要时触发）
    cfg.disambiguateDuplicateLegendNames = true;
end
