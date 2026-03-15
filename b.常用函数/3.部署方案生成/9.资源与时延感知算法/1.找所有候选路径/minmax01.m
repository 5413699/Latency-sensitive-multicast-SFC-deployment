% ---------- 辅助函数：min-max 归一化到 [0,1] ----------
function y = minmax01(x)
    xmin = min(x);
    xmax = max(x);
    if abs(xmax - xmin) < 1e-12
        y = ones(size(x));   % 全部相同就都设为1（或0都行）
    else
        y = (x - xmin) ./ (xmax - xmin);
    end
end