function fig = plot_share_weight_blocking(data, savePath, smoothWin)
% PLOT_SHARE_WEIGHT_BLOCKING  共享权重消融实验阻塞率折线图
%
%   fig = plot_share_weight_blocking(data)
%   fig = plot_share_weight_blocking(data, savePath)
%   fig = plot_share_weight_blocking(data, savePath, smoothWin)
%
%   data      : table，必须包含列：
%               [Arrival Ratio, With share weighting, Without share weighting]
%   savePath  : (可选) 图片保存目录；缺省或为空则不保存
%   smoothWin : (可选) Gaussian 平滑窗口长度，默认 7；设为 0 则不平滑
%
%   返回值 fig : figure 句柄，可供调用方进一步修改

if nargin < 2; savePath  = ''; end
if nargin < 3; smoothWin = 7;  end

% ---- 筛选 Arrival Ratio >= 40 的有效数据 ----
mask        = data.("Arrival Ratio") >= 40;
arrivalRate = data.("Arrival Ratio")(mask);
withW       = data.("With share weighting")(mask);
withoutW    = data.("Without share weighting")(mask);

% ---- Gaussian 平滑（保留整体趋势，消除阶梯感）----
if smoothWin > 0
    withW    = smoothdata(withW,    'gaussian', smoothWin);
    withoutW = smoothdata(withoutW, 'gaussian', smoothWin);
end

if isempty(arrivalRate)
    warning('plot_share_weight_blocking: Arrival Ratio >= 40 的数据为空，跳过绘图。');
    fig = figure('Visible','off');
    return;
end

% ---- 图形全局参数（单栏期刊：3.5 英寸宽）----
figW     = 3.5;
figH     = 2.8;
fontSize = 8;
fontName = 'Times New Roman';

fig = figure('Name','Share Weight Ablation - Blocking Rate', 'Color','w', ...
    'Units','inches', 'Position',[1.5, 1.5, figW, figH]);
hold on;

% 标记稀疏化：每 ~10 个点显示一次标记
nStep = max(1, floor(numel(arrivalRate) / 10));
mIdx  = 1 : nStep : numel(arrivalRate);

h1 = plot(arrivalRate, withW, '-o', ...
    'LineWidth', 1.0, 'MarkerSize', 4, ...
    'Color', [0.00 0.45 0.74], 'MarkerFaceColor', [0.00 0.45 0.74], ...
    'MarkerIndices', mIdx, 'DisplayName', 'With share weighting');
h2 = plot(arrivalRate, withoutW, '-s', ...
    'LineWidth', 1.0, 'MarkerSize', 4, ...
    'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10], ...
    'MarkerIndices', mIdx, 'DisplayName', 'Without share weighting');
hold off;

% ---- 坐标轴 ----
xlim([min(arrivalRate), max(arrivalRate)]);

allY   = [withW; withoutW];
yUpper = max(max(allY) * 1.25, 0.05);
ylim([0, yUpper]);

xlabel('Arrival Ratio',  'FontSize', fontSize, 'FontName', fontName);
ylabel('Blocking Ratio', 'FontSize', fontSize, 'FontName', fontName);

% ---- 图例 ----
leg = legend([h1, h2], 'Location', 'northwest', ...
    'FontSize', fontSize, 'FontName', fontName);
leg.Box = 'on';

% ---- 坐标轴样式 ----
grid on;  box on;
ax            = gca;
ax.FontSize   = fontSize;
ax.FontName   = fontName;
ax.LineWidth  = 0.8;
ax.TickDir    = 'out';

% ---- 导出尺寸锁定 ----
set(fig, 'PaperUnits','inches', ...
    'PaperSize',     [figW, figH], ...
    'PaperPosition', [0, 0, figW, figH]);

% ---- 保存 ----
if ~isempty(savePath)
    if ~exist(savePath, 'dir'); mkdir(savePath); end
    baseName = fullfile(savePath, 'Fig_ShareWeightBlocking');
    print(fig, baseName, '-dsvg', '-r0');
    print(fig, baseName, '-dpng', '-r600');
    fprintf('已保存：Fig_ShareWeightBlocking (.svg / .png) → %s\n', savePath);
end
end
