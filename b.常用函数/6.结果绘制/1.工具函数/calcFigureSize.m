function [figWidth, figHeight] = calcFigureSize(plotType, methodNames, cfg)
%CALCFIGURESIZE 根据绘图内容动态计算合适的图形尺寸
%
% 输入：
%   plotType    : 绘图类型
%                 'single'   - 单曲线图（如接受率、时延等）
%                 'subplot3' - 三子图横向排列（如累计资源消耗）
%                 'bar'      - 柱状图（如失败分布）
%   methodNames : 方法名称列表（cell数组或string数组）
%   cfg         : 绘图配置（可选，用于获取基础尺寸）
%
% 输出：
%   figWidth    : 建议的图形宽度（像素）
%   figHeight   : 建议的图形高度（像素）
%
% 动态调整逻辑：
%   - 基于方法数量调整高度（更多图例需要更多空间）
%   - 基于方法名称长度调整宽度（长名称需要更多空间）
%   - 确保最小尺寸以保证可读性

    if nargin < 3 || isempty(cfg)
        try
            cfg = read_global_cfg();
        catch
            cfg = struct();
        end
    end
    if ~isfield(cfg, 'figWidth');     cfg.figWidth     = 800;  end
    if ~isfield(cfg, 'figHeight');    cfg.figHeight    = 600;  end
    if ~isfield(cfg, 'figWidthWide'); cfg.figWidthWide = 1500; end
    if ~isfield(cfg, 'figWidthBar');  cfg.figWidthBar  = 900;  end
    if ~isfield(cfg, 'figHeightBar'); cfg.figHeightBar = 550;  end
    
    % 转换为cell数组
    if isstring(methodNames)
        methodNames = cellstr(methodNames);
    end
    
    numMethods = numel(methodNames);
    
    % 计算最长方法名称的字符数
    maxNameLen = 0;
    for i = 1:numMethods
        maxNameLen = max(maxNameLen, strlength(string(methodNames{i})));
    end
    
    % ==================== 根据类型计算尺寸 ====================
    switch lower(plotType)
        case 'single'
            % 单曲线图：基础 800x600，根据内容调整
            baseWidth  = cfg.figWidth;
            baseHeight = cfg.figHeight;
            
            % 宽度调整：长名称需要更宽的图例空间
            widthBonus = max(0, (maxNameLen - 10) * 8);  % 超过10字符后每字符+8像素
            
            % 高度调整：更多方法需要更高的图例
            heightBonus = max(0, (numMethods - 4) * 25);  % 超过4个方法后每个+25像素
            
            figWidth  = baseWidth + widthBonus;
            figHeight = baseHeight + heightBonus;
            
            % 最小尺寸保证
            figWidth  = max(figWidth, 700);
            figHeight = max(figHeight, 500);
            
        case 'subplot3'
            % 三子图横向：需要足够高度容纳主标题、子标题、图例和x轴标签
            baseWidth  = cfg.figWidthWide;
            baseHeight = 520;  % 增加基础高度，确保x轴标签完整显示
            
            % 宽度调整：三个图例都需要空间
            widthBonus = max(0, (maxNameLen - 8) * 15);
            
            % 高度调整：图例在图内，方法多时需要更高
            heightBonus = max(0, (numMethods - 4) * 30);
            
            figWidth  = baseWidth + widthBonus;
            figHeight = baseHeight + heightBonus;
            
            % 最小尺寸
            figWidth  = max(figWidth, 2000);
            figHeight = max(figHeight, 600);
            
        case 'bar'
            % 柱状图：基础 900x550，柱子数量影响宽度
            baseWidth  = cfg.figWidthBar;
            baseHeight = cfg.figHeightBar;
            
            % 宽度调整：更多方法意味着更多柱子
            widthBonus = max(0, (numMethods - 4) * 40);
            
            % 高度调整：图例高度
            heightBonus = max(0, (numMethods - 4) * 20);
            
            % 名称长度也影响宽度（x轴标签）
            widthBonus = widthBonus + max(0, (maxNameLen - 10) * 10);
            
            figWidth  = baseWidth + widthBonus;
            figHeight = baseHeight + heightBonus;
            
            % 最小尺寸
            figWidth  = max(figWidth, 750);
            figHeight = max(figHeight, 450);
            
        otherwise
            % 默认：使用单图尺寸
            figWidth  = cfg.figWidth;
            figHeight = cfg.figHeight;
    end
    
    % ==================== 上限保护（避免过大） ====================
    figWidth  = min(figWidth, 2000);
    figHeight = min(figHeight, 1200);
end
