%[text] # calcPathScore
%[text] 计算链路综合评价
%[text] =归一化共享度评分+归一化拥塞评分+归一化时延评分
function pathScoreStruct = calcPathScore(Pathinfo, linkFreq, links, req, t0, deployMethodCfg, destIdx, destNum)

    if nargin < 7 || isempty(destIdx), destIdx = 1; end
    if nargin < 8 || isempty(destNum), destNum = 1; end

    shareWeight = deployMethodCfg.shareWeight;
    congWeight = deployMethodCfg.congWeight;
    delayWeight = deployMethodCfg.delayWeight;

    if isfield(deployMethodCfg, 'shareDecayMin')
        shareDecayMin = deployMethodCfg.shareDecayMin;
    else
        shareDecayMin = 0;
    end
    shareDecayWeight = max(1 - (destIdx - 1) / max(destNum, 1), shareDecayMin);

    linkFreq = linkFreq(:);
    K = length(Pathinfo);

    % 结果结构体：先存 raw 指标，再存 norm 指标与总分
    pathScoreStruct = repmat(struct( ...
        'k', [], 'hops', [], ...
        'shareScore', [], 'congScore', [], 'delayScore', [], ...
        'shareNorm', [], 'congNorm', [], 'delayNorm', [], ...
        'totalScore', []), K, 1);

    for k = 1:K
        hops = Pathinfo(k).pathshops;

        pathScoreStruct(k).k    = k;
        pathScoreStruct(k).hops = hops;

        % 无效路径
        if hops <= 0
            pathScoreStruct(k).shareScore = -inf;
            pathScoreStruct(k).congScore  = inf;
            pathScoreStruct(k).delayScore = inf;
            continue;
        end

        lk = Pathinfo(k).link_ids;
        lk = lk(lk > 0);

        if isempty(lk)
            pathScoreStruct(k).shareScore = -inf;
            pathScoreStruct(k).congScore  = inf;
            pathScoreStruct(k).delayScore = inf;
            continue;
        end

        % ---------- 1) raw 共享潜力：越大越好 ----------
        shareScore = mean(linkFreq(lk));

        % ---------- 2) raw 拥堵：越小越好 ----------
        t = t0;
        congSum = 0;

        for ei = 1:numel(lk)
            e = lk(ei);

            usedFlag = links(e).request(t, req.id);
            bw_t = links(e).bandwidth(t);

            if bw_t <= 0
                cong = inf;
            elseif usedFlag == 1
                cong = 0;
            else
                cong = req.bandwidth / bw_t;
            end

            congSum = congSum + cong;

            dly_t = links(e).delay(t);
            t = t + dly_t;
        end

        congScore = congSum / hops;

        % ---------- 3) raw 时延满足：越小越好 ----------
        % 时延得分:6指的是3个vnf按照基础时延进行部署的时间
        delayScore = (t + 6) / req.max_delay;

        pathScoreStruct(k).shareScore = shareScore;
        pathScoreStruct(k).congScore  = congScore;
        pathScoreStruct(k).delayScore = delayScore;
    end

    % ==================== 同集合 min-max 归一化 ====================
    shareVec = [pathScoreStruct.shareScore].';
    congVec  = [pathScoreStruct.congScore].';
    delayVec = [pathScoreStruct.delayScore].';

    % 有效掩码（只对有限值做归一化）
    validShare = isfinite(shareVec);
    validCong  = isfinite(congVec);
    validDelay = isfinite(delayVec);

    shareNorm = nan(K,1);
    congNorm  = nan(K,1);
    delayNorm = nan(K,1);

    shareNorm(validShare) = minmax01(shareVec(validShare));
    congNorm(validCong)   = minmax01(congVec(validCong));
    delayNorm(validDelay) = minmax01(delayVec(validDelay));

    % 写回结构体 + 计算总分
    for k = 1:K
        pathScoreStruct(k).shareNorm = shareNorm(k);
        pathScoreStruct(k).congNorm  = congNorm(k);
        pathScoreStruct(k).delayNorm = delayNorm(k);

        % share：越大越好（直接加）
        % cong/delay：越小越好（用 1 - norm 变成"越大越好"的形式）
        if isfinite(shareNorm(k)) && isfinite(congNorm(k)) && isfinite(delayNorm(k))
            pathScoreStruct(k).totalScore = ...
                shareWeight * shareDecayWeight * shareNorm(k) + ...
                congWeight  * (1 - congNorm(k)) + ...
                delayWeight * (1 - delayNorm(k));
        else
            pathScoreStruct(k).totalScore = -inf;
        end
    end

    % ==================== 排序：totalScore 降序；并列 hops 升序 ====================
    totalScores = [pathScoreStruct.totalScore].';
    hopsVec     = [pathScoreStruct.hops].';
    [~, order]  = sortrows([-totalScores, hopsVec], [1 2]);
    pathScoreStruct = pathScoreStruct(order);

end

%[text] 
%[text] 
%[text] 

%[appendix]{"version":"1.0"}
%---
