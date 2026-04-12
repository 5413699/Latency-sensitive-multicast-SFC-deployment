function save_svg(figHandle, savePath, background)
%SAVE_SVG  保存 svg（优先 exportgraphics，兼容旧版本用 print）
%
% figHandle : figure 句柄
% savePath  : 例如 fullfile(outDir, 'xxx.svg')
% background: 'none' 或 'white'

    if nargin < 3
        background = 'none';
    end

    %#region agent log
    useEg = (exist('exportgraphics', 'file') == 2);
    vis = ''; rdr = '';
    try, vis = char(string(get(figHandle, 'Visible'))); catch, vis = 'err'; end
    try, rdr = char(string(get(figHandle, 'Renderer'))); catch, rdr = 'err'; end
    v = ver('MATLAB');
    rel = ''; if ~isempty(v), rel = v.Release; end
    agent_dbg_ndjson_(struct( ...
        'sessionId', 'cae06b', 'runId', 'pre-fix', 'hypothesisId', 'H1_entry', ...
        'location', 'save_svg:entry', 'message', 'save_svg enter', ...
        'data', struct('matlabRelease', rel, 'useExportGraphics', useEg, ...
        'figVisible', vis, 'figRenderer', rdr, 'background', char(string(background)), ...
        'saveName', char(string(getfield_safe_name_(savePath)))), ...
        'timestamp', agent_dbg_ts_ms_()));
    %#endregion

    % 保证目录存在
    [saveDir,~,~] = fileparts(savePath);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end

    % exportgraphics 更稳定（矢量）
    if exist('exportgraphics', 'file') == 2
        %#region agent log
        t0 = tic;
        agent_dbg_ndjson_(struct( ...
            'sessionId', 'cae06b', 'runId', 'pre-fix', 'hypothesisId', 'H2_exportgraphics', ...
            'location', 'save_svg:before_exportgraphics', 'message', 'before exportgraphics', ...
            'data', struct('elapsedSinceEntry', 0), ...
            'timestamp', agent_dbg_ts_ms_()));
        %#endregion
        exportgraphics(figHandle, savePath, ...
            'ContentType', 'vector', ...
            'BackgroundColor', background);
        %#region agent log
        agent_dbg_ndjson_(struct( ...
            'sessionId', 'cae06b', 'runId', 'pre-fix', 'hypothesisId', 'H3_after_ok', ...
            'location', 'save_svg:after_exportgraphics', 'message', 'after exportgraphics', ...
            'data', struct('seconds', toc(t0)), ...
            'timestamp', agent_dbg_ts_ms_()));
        %#endregion
    else
        % 兼容老版本 MATLAB
        set(figHandle, 'PaperPositionMode', 'auto');
        %#region agent log
        t0 = tic;
        agent_dbg_ndjson_(struct( ...
            'sessionId', 'cae06b', 'runId', 'pre-fix', 'hypothesisId', 'H2_print_branch', ...
            'location', 'save_svg:before_print', 'message', 'before print -dsvg', ...
            'data', struct('paperPosMode', 'auto'), ...
            'timestamp', agent_dbg_ts_ms_()));
        %#endregion
        print(figHandle, savePath, '-dsvg');
        %#region agent log
        agent_dbg_ndjson_(struct( ...
            'sessionId', 'cae06b', 'runId', 'pre-fix', 'hypothesisId', 'H3_after_ok', ...
            'location', 'save_svg:after_print', 'message', 'after print -dsvg', ...
            'data', struct('seconds', toc(t0)), ...
            'timestamp', agent_dbg_ts_ms_()));
        %#endregion
    end
end

function nm = getfield_safe_name_(p)
    [~, nm, ~] = fileparts(p);
end

function ms = agent_dbg_ts_ms_()
    try
        ms = javaMethod('currentTimeMillis', 'java.lang.System');
    catch
        ms = round(now * 86400000);
    end
end

function agent_dbg_ndjson_(payload)
%#region agent log
    logPath = fullfile(pwd, 'debug-cae06b.log');
    try
        fid = fopen(logPath, 'a');
        if fid < 1, return; end
        fprintf(fid, '%s\n', jsonencode(payload));
        fclose(fid);
    catch
    end
%#endregion
end
