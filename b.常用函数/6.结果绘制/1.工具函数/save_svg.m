function save_svg(figHandle, savePath, background)
%SAVE_SVG  保存 svg（优先 exportgraphics，兼容旧版本用 print）
%
% figHandle : figure 句柄
% savePath  : 例如 fullfile(outDir, 'xxx.svg')
% background: 'none' 或 'white'

    if nargin < 3
        background = 'none';
    end

    % 保证目录存在
    [saveDir,~,~] = fileparts(savePath);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end

    % exportgraphics 更稳定（矢量）
    if exist('exportgraphics', 'file') == 2
        exportgraphics(figHandle, savePath, ...
            'ContentType', 'vector', ...
            'BackgroundColor', background);
    else
        % 兼容老版本 MATLAB
        set(figHandle, 'PaperPositionMode', 'auto');
        print(figHandle, savePath, '-dsvg');
    end
end
