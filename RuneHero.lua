local addonName, RH = ... ;

local runePowerStatusBar;
local runePowerStatusBarDark;
local runePowerStatusBarText;
local cooldowns = {};

local RUNETYPEC_BLOOD = 1;
local RUNETYPEC_FROST = 2;
local RUNETYPEC_UNHOLY = 3;
local RUNETYPEC_DEATH = 4;
local RUNETYPEC_COOLDOWN = 5;

--Reference /FrameXML/RuneFrame.lua -- https://searchcode.com/codesearch/view/78334991/
local runeTextures = {
    [RUNETYPEC_BLOOD] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Blood",
    [RUNETYPEC_UNHOLY] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Unholy",
    [RUNETYPEC_FROST] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Frost",
    [RUNETYPEC_DEATH] = "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-Death",
}

local runeColors = {
    [RUNETYPEC_BLOOD] = {0.65, 0, 0, 1},
    [RUNETYPEC_UNHOLY] = {0, 0.65, 0, 1},
    [RUNETYPEC_FROST] = {0, 0.3, 1.0, 1},
    [RUNETYPEC_DEATH] = {0.8, 0.2, 1.0, 1},
    [RUNETYPEC_COOLDOWN] = {1, 1, 1, 1}
}

local cooldownRuneColors = {
    [RUNETYPEC_BLOOD] = {0.325, 0, 0, 1},
    [RUNETYPEC_UNHOLY] = {0, 0.325, 0, 1},
    [RUNETYPEC_FROST] = {0, 0.15, 0.5, 1},
    [RUNETYPEC_DEATH] = {0.4, 0.1, 0.5, 1},
    [RUNETYPEC_COOLDOWN] = {0.5, 0.5, 0.5, 1}
}

local offset = 15;
local start = -85;

local runeY = {
	[1] = start,
	[2] = start-offset,
	[5] = start-offset*2, -- In wotlk classic, frost and unholy are swapped in the UI
	[6] = start-offset*3,
	[3] = start-offset*4,
	[4] = start-offset*5,
    [7] = start-offset*6-10, -- Ability cooldowns below
    [8] = start+offset+14  -- Ability cooldowns above
}

local watchedSpells = {
    [43265] = true, -- death and decay (rank 1)
    [49936] = true, -- death and decay (rank 2)
    [49937] = true, -- death and decay (rank 3)
    [49938] = true, -- death and decay (rank 4)
    [57330] = true, -- horn of winter (rank 1)
    [57623] = true, -- horn of winter (rank 2)
    [55233] = true, -- vamp blood
    [49016] = true, -- unholy frenzy
    [45529] = true, -- blood tap
    [28982] = true, -- rune tap
    [48792] = true, -- ibf
    [49158] = true, -- corpse explosion (rank 1)
    [51325] = true, -- corpse explosion (rank 2)
    [51326] = true, -- corpse explosion (rank 3)
    [51327] = true, -- corpse explosion (rank 4)
    [51328] = true, -- corpse explosion (rank 5)
    [47568] = true, -- empower rune weapon
    [61999] = true, -- raise ally
    [48707] = true, -- ams
    [48743] = true, -- death pact
    [56222] = true, -- dark command (taunt)
    [47476] = true, -- strangulate
    [46584] = true, -- raise dead
    [49576] = true, -- death grip
    [47528] = true, -- mind freeze
    [42650] = true, -- army of the dead
    [49039] = true, -- lichborne
    [49796] = true, -- deathchill
    [49203] = true, -- hungering cold
    [49184] = true, -- howling blast (rank 1)
    [51409] = true, -- howling blast (rank 2)
    [51410] = true, -- howling blast (rank 3)
    [51411] = true, -- howling blast (rank 4)
    [51052] = true, -- amz
    [63560] = true, -- ghoul frenzy
    [49206] = true, -- summon gargoyle
    [49028] = true, -- dancing rune weapon
    [49005] = true, -- mark of blood
    [49222] = true, -- bone shield
    [51271] = true, -- unbreakable armor
}

RuneHero_Saved = {
	anchor = "BOTTOM",
	parent = "UIParent",
	rel = "BOTTOM",
	x = 0;
	y = 135;
	scale = 7;
	runeX = 65;
	scrollWidth = 260;
	blade = "runeblade";
	runebladeSelectorTitle = "Runeblade";
    desaturateRunes = true;
    showCooldowns = true;
    cooldownsAbove = false;
};

--
-- RuneButton
--

function RuneButtonC_OnLoad (self)
	RuneFrameC_AddRune(RuneFrameC, self);
	
	self.rune = getglobal(self:GetName().."Rune");
	self.border = getglobal(self:GetName().."Border");
	self.texture = getglobal(self:GetName().."BorderTexture");
	self.bg = getglobal(self:GetName().."BG");
    self.shineTexture = getglobal(self:GetName().."ShineTexture");

	RuneButtonC_Update(self);

	self:SetScript("OnUpdate", RuneButtonC_OnUpdate);

	--self:SetFrameLevel( self:GetFrameLevel() + 2*self:GetID() );
	--self.border:SetFrameLevel( self:GetFrameLevel() + 1 );
end

function RuneButtonC_OnUpdate (self, elapsed)
    local runeId = self:GetID()
    
    if runeId == nil then
        return
    end
    
    local runeType = GetRuneType(runeId);
	local start, duration, r = GetRuneCooldown(runeId);

	if (r) then
		self:SetPoint("TOPLEFT", "RuneFrameC", "TOPLEFT", RuneHero_Saved.runeX, runeY[runeId]);
        
        if (runeType ~= nil and RuneHero_Saved.desaturateRunes) then
            self.texture:SetVertexColor(unpack(runeColors[runeType]));
        end
	else
		local remain = -1;
		if (duration ~= nil and start ~= nil) then
			remain = (duration - GetTime() + start) / duration;
		end
		
        if (runeType ~= nil and RuneHero_Saved.desaturateRunes) then
            self.texture:SetVertexColor(unpack(cooldownRuneColors[runeType]));
        end
        
		if ( remain < 0) then 
			self:SetPoint("TOPLEFT", "RuneFrameC", "TOPLEFT", RuneHero_Saved.runeX, runeY[runeId] );
		elseif ( remain > 1) then
			self:SetPoint("TOPLEFT", "RuneFrameC", "TOPLEFT", RuneHero_Saved.runeX + RuneHero_Saved.scrollWidth, runeY[runeId] );
		else
			self:SetPoint("TOPLEFT", "RuneFrameC", "TOPLEFT", RuneHero_Saved.runeX + remain*RuneHero_Saved.scrollWidth, runeY[runeId] );
		end
	end
end

function RuneButtonC_Update (self, runeIndex, dontFlash)

    -- Disable rune frame if not a death knight.
    local _, class = UnitClass("player");
    
    if ( class ~= "DEATHKNIGHT" ) then
        self:Hide();
    end

    if (runeIndex ~= nil) then
        local runeType = GetRuneType(runeIndex);
        
        if (runeType ~= nil) then
            if (not dontFlash and self.rune.runeType ~= runeType) then
                --RuneButtonC_ShineFadeIn(self.shineTexture)
            end
        
            self.rune:SetTexture(runeTextures[runeType]);
            self.rune.runeType = runeType
            self.texture:SetTexture("Interface\\AddOns\\RuneHero\\textures\\Ring-test.tga");
            self.texture:SetVertexColor(unpack(runeColors[runeType]));
        end
    end
        
    self.bg:SetVertexColor(.2,.2,.2,1);

    self.rune:SetWidth(25);
    self.rune:SetHeight(25);
    
    self.bg:SetWidth(17);
    self.bg:SetHeight(17);

    self.border:SetWidth(29);
    self.border:SetHeight(29);
    
end

function RuneButtonC_Event (rune, runeIndex, isEnergized)
    local start, duration, runeReady = GetRuneCooldown(runeIndex);

    if not runeReady then
        RuneButtonC_ShineFadeOut(rune.shineTexture, 0)
    else
        RuneButtonC_ShineFadeIn(rune.shineTexture)
    end
end

function RuneButtonC_ShineFadeIn(self)
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

function RuneButtonC_ShineFadeOut(self, fadeTime)
    self.shining=false;
    if fadeTime then
        UIFrameFadeOut(self, fadeTime);
    else
        UIFrameFadeOut(self, 0.5);
    end
end

--
-- RuneFrame
--

function RuneFrameC_OnLoad (self)

	-- Disable rune frame if not a death knight.
	local _, class = UnitClass("player");
	
	if ( class ~= "DEATHKNIGHT" ) then
		self:Hide();
	end

	if (RuneHero_Saved.scrollWidth < 0) then
		RuneHero_Saved.scrollWidth = 260;
	end

	self:SetFrameLevel(1);
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("RUNE_TYPE_UPDATE");
    self:RegisterEvent("RUNE_POWER_UPDATE");
	--self:RegisterEvent("RUNE_REGEN_UPDATE");
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	self:RegisterEvent("ADDON_LOADED");
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN");

	self:SetScript("OnEvent", RuneFrameC_OnEvent);
	self:SetScript("OnUpdate", RuneFrameC_OnUpdate);
	
	self.runes = {};

end


function RuneFrameC_OnUpdate(self)
	local power = UnitPower("player");
	local maxPower = UnitPowerMax("player");
 
    if maxPower ~= 0 then
        runePowerStatusBar:SetWidth((power/maxPower) * 512)
        RuneStatusBar:SetTexCoord(0, power/maxPower, 0, 1);
    end

	-- Hide RP number indicator if there's no RP
	if ( power > 0) then
		runePowerStatusBarText:SetText( power );
	else
		runePowerStatusBarText:SetText( nil );
	end

end

-- The event detector
function RuneFrameC_OnEvent (self, event, ...)

	-- Proc detector
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, damageDealt = CombatLogGetCurrentEventInfo();
        local playerName = UnitName("player");
        local applied = subevent == "SPELL_AURA_APPLIED";
        local removed = subevent == "SPELL_AURA_REMOVED";
        local proc = false;
        
		if (spellName == "Death Trance" and sourceName == playerName) then
            proc = true;
			if ( applied ) then
				RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade-proc");
			elseif ( removed ) then
				RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade");
			end
        elseif (spellName == "Killing Machine" and sourceName == playerName) then
            proc = true;
			if ( applied ) then
				RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade-proc");
			elseif ( removed ) then
				RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade");
			end
        elseif (spellName == "Freezing Fog" and sourceName == playerName) then
            proc = true;
            if ( applied ) then
                RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade-proc");
            elseif ( removed ) then
                RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade");
            end
		end
  
        if ( proc ) then
            if ( applied ) then
                runePowerStatusBar:Hide();
            elseif ( removed ) then
                runePowerStatusBar:Show();
            end
        end
	-- Fires when the player enters the world, enters/leaves an instance, respawns at a GY, possibly at any loading screen as well
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		for rune in next, self.runes do
			RuneButtonC_Update(self.runes[rune], rune, true);
		end

	-- Fires when a rune changes to/from a Death rune
	elseif ( event == "RUNE_TYPE_UPDATE" ) then
		for rune in next, self.runes do
			RuneButtonC_Update(self.runes[rune], rune);
		end
        
	-- Fires when the runic power changes
	elseif ( event == "RUNE_POWER_UPDATE" ) then
        local runeIndex, isEnergized = ...;
        
        if (runeIndex >= 1) then
            RuneButtonC_Event(self.runes[runeIndex], runeIndex, isEnergized);
        end
	-- Fires when the rune regen time changes (Retail only)
	elseif ( event == "RUNE_REGEN_UPDATE" ) then
		RuneButtonC_Event();

    -- Fires when a spell cast ends
    elseif ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
        local _, _, spellID = ...
        if ( spellID ~= nil ) then
            local baseCooldown = GetSpellBaseCooldown(spellID) or 0
            if (baseCooldown > 0) then -- queue it up
                if watchedSpells[spellID] == true then
                    CooldownButtonC_LoadSpell(spellID)
                end
            end
        end
        
    elseif ( event == "SPELL_UPDATE_COOLDOWN" ) then

	-- Fires when RuneHero and the saved variables are loaded
	elseif ( event == "ADDON_LOADED"  ) then
	
		local addonName = select(1, ...)
		if ( addonName ~= "RuneHero") then return end
	
		RuneHero_LoadDefaults();
		RuneHero_SetLevels();
		
		-- Load the RuneHero interface options panel
		RH.RuneHero_LoadOptions(self);

		if (RuneHero_Saved.scrollWidth == nil or RuneHero_Saved.scrollWidth < 0) then
			RuneHero_Saved.scrollWidth = 260;
		end

		RuneFrameC:ClearAllPoints();
		RuneFrameC:SetPoint(RuneHero_Saved.anchor, RuneHero_Saved.parent,RuneHero_Saved.rel,RuneHero_Saved.x,RuneHero_Saved.y);
		RuneFrameC:SetScale(RuneHero_Saved.scale);
		
		RuneBlade:SetTexture( strconcat("Interface\\AddOns\\RuneHero\\textures\\", RuneHero_Saved.blade) );
		
		runePowerStatusBar = CreateFrame("Frame", "RuneBladeStatusBar", RuneFrameC);
		runePowerStatusBar:CreateTexture("RuneStatusBar");
		runePowerStatusBar:SetPoint("LEFT", RuneFrameC, "LEFT");
		runePowerStatusBar:SetPoint("TOPLEFT", RuneFrameC, "TOPLEFT");
		runePowerStatusBar:SetFrameLevel(2);
		RuneStatusBar:SetAllPoints();
		RuneStatusBar:SetTexture( strconcat("Interface\\AddOns\\RuneHero\\textures\\", RuneHero_Saved.blade, "-statusbar.tga") );
		
		local runePowerTextFrame = CreateFrame("Frame", nil, UIParent);
        runePowerStatusBarText = runePowerTextFrame:CreateFontString("RuneHeroPowerFrameText", 'OVERLAY');
		runePowerStatusBarText:ClearAllPoints();
		runePowerStatusBarText:SetFontObject( WorldMapTextFont );
		runePowerStatusBarText:SetTextColor(.6,.9,1);
		runePowerStatusBarText:SetPoint("TOP", RuneBlade, "TOP", -30, -20);
		runePowerStatusBarText:SetJustifyH("CENTER");
		runePowerStatusBarText:SetWidth(90);
		runePowerStatusBarText:SetHeight(40);
        runePowerStatusBarText:SetScale(RuneHero_Saved.scale);
  
        RuneHero_ButtonScale(RuneHero_Saved.scale);
		
		DEFAULT_CHAT_FRAME:AddMessage("RuneHero activated! Type '/runehero' to reposition the bar.");
  
        for spellID,_ in pairs(watchedSpells) do
            local start, _, _ = GetSpellCooldown(spellID);
            
            if (start ~= 0) then
                CooldownButtonC_LoadSpell(spellID)
            end
        end
	end
end


function RuneFrameC_AddRune(runeFrameC, rune)
	tinsert(runeFrameC.runes, rune);
end

function RuneFrameC_OnDragStart()
	RuneFrameC:StartMoving();
end

function RuneFrameC_OnDragStop()
	RuneHero_Saved.anchor = "BOTTOMLEFT";
	RuneHero_Saved.parent = "UIParent";
	RuneHero_Saved.rel = "BOTTOMLEFT";
	RuneHero_Saved.x = RuneFrameC:GetLeft();
	RuneHero_Saved.y = RuneFrameC:GetBottom();
	RuneFrameC:StopMovingOrSizing();

	RuneHero_SetLevels();
end

--
-- CooldownButton
--

function CooldownButtonC_OnLoad (self)
    self.texture = getglobal(self:GetName().."Texture");
    self.shineTexture = getglobal(self:GetName().."ShineTexture");
    
    self:SetScript("OnUpdate", CooldownButtonC_OnUpdate);
end

function CooldownButtonC_LoadSpell(spellID)
    if not RuneHero_Saved.showCooldowns then
        return
    end
    
    local name, rank, icon = GetSpellInfo(spellID);
    
    if icon == nil then
        return
    elseif cooldowns[spellID] ~= nil then
        --DEFAULT_CHAT_FRAME:AddMessage("Reusing Spell Frame "..name.." using texture "..spellID);
        cooldowns[spellID].spellID = spellID;
        cooldowns[spellID].endTime = nil;
        cooldowns[spellID].shouldEndTime = nil;
        cooldowns[spellID].fullDuration = nil;
        cooldowns[spellID]:Show();
    else
        --DEFAULT_CHAT_FRAME:AddMessage("Creating Spell Frame "..name.." using texture "..spellID);
        local button = CreateFrame("Button", strconcat("RHCDButton", name), UIParent, "CooldownButtonTemplateC");
        button:SetScale(RuneHero_Saved.scale);
        button.texture:SetTexture(icon);
        button.spellID = spellID;
        
        cooldowns[spellID] = button;
    end
end

function CooldownButtonC_OnUpdate (self, elapsed)
    if not RuneHero_Saved.showCooldowns or self.spellID == nil then
        self:Hide();
        return
    end
    
    local spellID = self.spellID
    local start, duration, enabled = GetSpellCooldown(spellID);
    
    if self.endTime ~= nil then
        if (GetTime() - self.endTime > 1) then
            self.spellID = nil
        end
        return
    end
    
    --DEFAULT_CHAT_FRAME:AddMessage("Spell "..spellID.." start "..start.." duration "..duration.." enabled "..enabled)
    
    local cooldownYPosition = runeY[7]
    if RuneHero_Saved.cooldownsAbove then
        cooldownYPosition = runeY[8]
    end
    
    local cooldownFinished = false;
    if (start == 0) then
        cooldownFinished = true;
    else
        local remain = -1;
        
        if (duration ~= nil) then
            if self.shouldEndTime ~= nil and self.fullDuration ~= nil then
                remain = (self.shouldEndTime - GetTime()) / self.fullDuration;
            elseif (start ~= nil) then
                self.shouldEndTime = duration + start
                self.fullDuration = duration
                
                -- Shortest cooldowns on top
                if duration < 200 then
                    self:SetFrameLevel(300-duration)
                else
                    self:SetFrameLevel(100)
                end
                
                remain = (duration - GetTime() + start) / duration;
                
                if (runeType ~= nil and RuneHero_Saved.desaturateRunes) then
                    self.texture:SetVertexColor(unpack(cooldownRuneColors[RUNETYPEC_COOLDOWN]));
                end
            end
        end
        
        if ( remain < 0) then
            cooldownFinished = true;
        elseif ( remain > 1) then
            self:SetPoint("TOPLEFT", "RuneFrameC", "TOPLEFT", RuneHero_Saved.runeX - 3 + RuneHero_Saved.scrollWidth, cooldownYPosition );
        else
            self:SetPoint("TOPLEFT", "RuneFrameC", "TOPLEFT", RuneHero_Saved.runeX - 3 + remain*RuneHero_Saved.scrollWidth, cooldownYPosition );
        end
    end
    
    if cooldownFinished then
        self:SetPoint("TOPLEFT", "RuneFrameC", "TOPLEFT", RuneHero_Saved.runeX - 3, cooldownYPosition);
        
        if (runeType ~= nil and RuneHero_Saved.desaturateRunes) then
            self.texture:SetVertexColor(unpack(runeColors[RUNETYPEC_COOLDOWN]));
        end
        
        self.endTime = GetTime();
        self.shouldEndTime = nil;
        self.fullDuration = nil;
        RH.ShineFadeIn(self.shineTexture);
    end
end

--
-- Helpers
--

function RuneHero_ButtonScale(scale)
	RuneButtonIndividual1C:SetScale(scale);
	RuneButtonIndividual2C:SetScale(scale);
	RuneButtonIndividual3C:SetScale(scale);
	RuneButtonIndividual4C:SetScale(scale);
	RuneButtonIndividual5C:SetScale(scale);
	RuneButtonIndividual6C:SetScale(scale);
 
    local runePowerText = getglobal("RuneHeroPowerFrameText");
    if runePowerText ~= nil then
        runePowerText:SetScale(scale);
    end
    
    for spellID,cdButton in pairs(cooldowns) do
        cdButton:SetScale(scale);
    end
end

function RuneHero_SetLevels()

	RuneFrameC:SetFrameLevel(1);

	RuneFrameC.runes[1]:SetFrameLevel(20);
	RuneFrameC.runes[1]:SetFrameLevel(21);

	RuneFrameC.runes[2]:SetFrameLevel(30);
	RuneFrameC.runes[2]:SetFrameLevel(31);

	RuneFrameC.runes[5]:SetFrameLevel(40); -- In wotlk classic, unholy and frost are swapped in the UI
	RuneFrameC.runes[5]:SetFrameLevel(41);

	RuneFrameC.runes[6]:SetFrameLevel(50);
	RuneFrameC.runes[6]:SetFrameLevel(51);

	RuneFrameC.runes[3]:SetFrameLevel(60);
	RuneFrameC.runes[3]:SetFrameLevel(61);

	RuneFrameC.runes[4]:SetFrameLevel(70);
	RuneFrameC.runes[4]:SetFrameLevel(71);

end

function RuneHero_LoadDefaults() 

	if (RuneHero_Saved.anchor == nil) then
		RuneHero_Saved.anchor = "BOTTOM";
	end
	if (RuneHero_Saved.parent == nil) then
		RuneHero_Saved.parent = "UIParent";
	end
	if (RuneHero_Saved.rel == nil) then
		RuneHero_Saved.rel = "BOTTOM";
	end
	if (RuneHero_Saved.x == nil) then
		RuneHero_Saved.x = 0;
	end
	if (RuneHero_Saved.y == nil) then
		RuneHero_Saved.y = 135;
	end
	if (RuneHero_Saved.scale == nil) then
		RuneHero_Saved.scale = 1;
	end
	if (RuneHero_Saved.runeX == nil) then
		RuneHero_Saved.runeX = 65;
	end
	if (RuneHero_Saved.scrollWidth == nil) then
		RuneHero_Saved.scrollWidth = 260;
	end
	if (RuneHero_Saved.blade == nil) then
		RuneHero_Saved.blade = "runeblade";
	end
     if (RuneHero_Saved.desaturateRunes == nil) then
        RuneHero_Saved.desaturateRunes = true;
    end
end


function RuneHero_SlashCommand(cmd)

-- Called twice so that it actually opens to the right menu
-- Would only open to the main Options page with one call
InterfaceOptionsFrame_OpenToCategory(RH.rhOptions.name);
InterfaceOptionsFrame_OpenToCategory(RH.rhOptions.name);
--[[
	if( cmd == 'bottom' ) then
		RuneFrameC:ClearAllPoints();
		RuneFrameC:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 135/RuneFrameC:GetScale() );

		RuneHero_Saved.anchor = "BOTTOM";
		RuneHero_Saved.parent = "UIParent";
		RuneHero_Saved.rel = "BOTTOM";
		RuneHero_Saved.x = 0;
		RuneHero_Saved.y = 135/RuneFrameC:GetScale();

	elseif ( cmd == 'player' ) then
		RuneFrameC:ClearAllPoints();
		RuneFrameC:SetPoint("TOPLEFT", "PlayerFrame", "BOTTOMLEFT", 0 ,0);

		RuneHero_Saved.anchor = "TOPLEFT";
		RuneHero_Saved.parent = "PlayerFrame";
		RuneHero_Saved.rel = "BOTTOMLEFT";
		RuneHero_Saved.x = 0;
		RuneHero_Saved.y = 0;

	elseif (cmd == 'lock' ) then
		RuneButtonIndividual1C:SetMovable(false);
		RuneButtonIndividual1C:RegisterForDrag(nil);
		RuneButtonIndividual1C:SetScript('OnDragStart', nil );
		RuneFrameC:SetClampedToScreen(true);
		DEFAULT_CHAT_FRAME:AddMessage(" RuneHero locked.");

	elseif ( cmd == 'unlock' ) then
		RuneButtonIndividual1C:SetMovable(true);
		RuneButtonIndividual1C:RegisterForDrag('LeftButton');
		RuneButtonIndividual1C:SetScript('OnDragStart', RuneFrameC_OnDragStart );
		RuneButtonIndividual1C:SetScript('OnDragStop', RuneFrameC_OnDragStop );
		RuneFrameC:SetClampedToScreen(true);
		DEFAULT_CHAT_FRAME:AddMessage(" RuneHero unlocked. Click on the top rune icon to drag.");
		
	elseif ( cmd == 'bloodknight' ) then
		RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\bloodknight");
		RuneStatusBar:SetTexture("Interface\\AddOns\\RuneHero\\textures\\bloodknight-statusbar");
		RuneHero_Saved.blade = 'bloodknight';
		
	elseif ( cmd == 'runeblade' ) then
		RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade");
		RuneStatusBar:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade-statusbar");
		RuneHero_Saved.blade = 'runeblade';
	
	elseif ( cmd == 'ashbringer' ) then
		RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\ashbringer");
		RuneStatusBar:SetTexture("Interface\\AddOns\\RuneHero\\textures\\ashbringer-statusbar");
		RuneHero_Saved.blade = 'ashbringer';
		
	elseif ( cmd == 'runeblade2' ) then
		RuneBlade:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade2");
		RuneStatusBar:SetTexture("Interface\\AddOns\\RuneHero\\textures\\runeblade2-statusbar");
		RuneHero_Saved.blade = 'runeblade2';

	elseif (strsub(cmd,1,4) == 'size') then
		local scaleParam = tonumber(strsub(cmd,6));
		if ( scaleParam == nil ) then
			scaleParam = -1;
		else
			scaleParam = scaleParam/7;
		end
		if ( scaleParam <= 10/7 and scaleParam >= 1/7 ) then
			local rawleft =   (  RuneFrameC:GetLeft() + RuneFrameC:GetWidth() *.5)*RuneFrameC:GetScale();
			local rawbottom = (RuneFrameC:GetBottom() + RuneFrameC:GetHeight()*.5)*RuneFrameC:GetScale();
			local postleft =   (rawleft   - scaleParam*RuneFrameC:GetWidth() *.5)*(1/scaleParam);
			local postbottom = (rawbottom - scaleParam*RuneFrameC:GetHeight()*.5)*(1/scaleParam);

			RuneFrameC:ClearAllPoints();
			RuneFrameC:SetScale(scaleParam);
			RuneFrameC:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", postleft, postbottom);

			RuneHero_Saved.anchor = "BOTTOMLEFT";
			RuneHero_Saved.parent = "UIParent";
			RuneHero_Saved.rel = "BOTTOMLEFT";
			RuneHero_Saved.x = postleft;
			RuneHero_Saved.y = postbottom;
			RuneHero_Saved.scale = scaleParam;
			RuneHero_ButtonScale(scaleParam);
		else
			DEFAULT_CHAT_FRAME:AddMessage(" RuneHero: Size must be between 1-10 (Default: 7).");
		end
	elseif ( strsub(cmd,1,6) == 'offset') then
		local offset = tonumber(strsub(cmd,8));
		if (offset ~= nil) then
			RuneHero_Saved.runeX = offset;
		else 
			DEFAULT_CHAT_FRAME:AddMessage(" RuneHero: Offset must be a number.");
		end
	elseif ( strsub(cmd,1,5) == 'width') then
		local width = tonumber(strsub(cmd,7));
		if (width ~= nil) then
			RuneHero_Saved.scrollWidth = width;
		else 
			DEFAULT_CHAT_FRAME:AddMessage(" RuneHero: Width must be a number.");
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(" RuneHero Commands: 'bottom', 'player', 'lock', 'unlock', 'size <1-10>', 'width <#>', 'offset <#>' .");
		DEFAULT_CHAT_FRAME:AddMessage(" To change runeblades: 'runeblade', 'runeblade2', 'ashbringer', 'bloodknight'.");
	end	
	]]
end



-- Slash Command Support
SLASH_RUNEHERO1 = "/runehero";
SLASH_RUNEHERO2 = "/rh";
SlashCmdList["RUNEHERO"] = RuneHero_SlashCommand;
