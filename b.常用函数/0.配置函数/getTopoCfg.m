%[text] # 拓补信息配置
%[text] 此函数的详细说明。
function cfg = getTopoCfg(topoName)
    cfg = struct();
    switch topoName
        case "US_Backbone"
            cfg.topoFunc = 'US_Backbone';
            cfg.topoInfoPath = "c.输出\1.拓补信息\US_Backbone_topoinfo.mat";
            cfg.kpathPath    = "c.输出\1.拓补信息\US_Backbone_10Path.mat";


            cfg.minm = 80; cfg.maxm = 120;
            cfg.minc = 80; cfg.maxc = 120;
            cfg.minb = 160; cfg.maxb = 320;

        case "Abilene"
            cfg.topoFunc = 'Abilene';
            cfg.topoInfoPath = "c.输出\1.拓补信息\Abilene_topoinfo.mat";
            cfg.kpathPath    = "c.输出\1.拓补信息\Abilene_10Path.mat";


            cfg.minm = 40; cfg.maxm = 80;
            cfg.minc = 40; cfg.maxc = 80;
            cfg.minb = 100; cfg.maxb = 200;

        otherwise
            error("未知拓补：%s（请用 US_Backbone 或 Abilene）", topoName);
    end
end




%[appendix]{"version":"1.0"}
%---
