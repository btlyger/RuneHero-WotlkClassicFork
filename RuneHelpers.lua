-- RuneHero Helper Methods
local addonName, RH = ... ;

function RH.ShineFadeIn(self)
    if self.shining then
        return
    end
    local fadeInfo={
    mode = "IN",
    timeToFade = 0.5,
    finishedFunc = RuneButtonC_ShineFadeOut,
    finishedArg1 = self,
    }
    self.shining=true;
    UIFrameFade(self, fadeInfo);
end

function RH.ShineFadeOut(self, fadeTime)
    self.shining=false;
    if fadeTime then
        UIFrameFadeOut(self, fadeTime);
    else
        UIFrameFadeOut(self, 0.5);
    end
end

