-- Written By: Kip Potter (a.k.a Mythraun [Fury] - Level 80 Deathnight - Stonemaul)
-- Modified By: Azuredrak0 (a.k.a Drokin) - added Mitigation stats (block, armor, HP) to the window

-- Global version variable...
AVOIDANCE_VERSION = "1.0.1.0.C";

-- Other globals.
Avoidance_Settings = {};
Avoidance_salv = {};

-- Locals.
local frame;

--------------------------------------------------------------------------------
-- Handles loading the add-on.
--------------------------------------------------------------------------------
function Avoidance_OnLoad(Self)
	DEFAULT_CHAT_FRAME:AddMessage(format("Avoidance v%s loaded.", AVOIDANCE_VERSION));
	
	-- Register the game slash commands necessary for our functionality
	SLASH_AVOIDANCE1 = "/avoid";
	SLASH_AVOIDANCE2 = "/avoidance";
	SlashCmdList["AVOIDANCE"] = Avoidance_SlashCommand;
	
	-- Register the events.
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("UNIT_STATS");
	this:RegisterEvent("UNIT_AURA");
	this:RegisterEvent("UNIT_DEFENSE");
	this:RegisterEvent("PLAYER_LOGIN");
	this:RegisterEvent("PLAYER_AURAS_CHANGED"); 
end

--------------------------------------------------------------------------------
-- Shows the command (command-line parameters) options for avoidance.
--------------------------------------------------------------------------------
function Avoidance_ShowCommands()
	DEFAULT_CHAT_FRAME:AddMessage("Avoidance command options:");
	if (frame:IsShown()) then
		DEFAULT_CHAT_FRAME:AddMessage("  show [true] - Shows the avoidance window.");
		DEFAULT_CHAT_FRAME:AddMessage("  hide [false] - Hides the avoidance window.");
	else
		DEFAULT_CHAT_FRAME:AddMessage("  show [false] - Shows the avoidance window.");
		DEFAULT_CHAT_FRAME:AddMessage("  hide [true] - Hides the avoidance window.");
	end
	
	if (Avoidance_Settings.EnableDebugging) then
		DEFAULT_CHAT_FRAME:AddMessage("  debugon  [true] - Enables displaying debug information to the chat window.");
		DEFAULT_CHAT_FRAME:AddMessage("  debugoff [false] - Disables displaying debug information to the chat window.");
	else
		DEFAULT_CHAT_FRAME:AddMessage("  debugon  [false] - Enables displaying debug information to the chat window.");
		DEFAULT_CHAT_FRAME:AddMessage("  debugoff [true] - Disables displaying debug information to the chat window.");
	end
	DEFAULT_CHAT_FRAME:AddMessage("  ver - Shows the installed version of Avoidance.");
	DEFAULT_CHAT_FRAME:AddMessage("  resetframe - Resets the Avoidance frame to it's default position.");
	DEFAULT_CHAT_FRAME:AddMessage("  /avoid off will remove savlation when cast on you.");
	DEFAULT_CHAT_FRAME:AddMessage("  /avoid on will keep savlation when cast on you.");
end

--------------------------------------------------------------------------------
-- Handles the slash commands '/avoid' and '/avoidance'.
--------------------------------------------------------------------------------
function Avoidance_SlashCommand(msg)
	if (msg == "ver") then
		DEFAULT_CHAT_FRAME:AddMessage(format("Avoidance Version: %s", AVOIDANCE_VERSION));
	elseif (msg == "show") then
		if (not frame:IsShown()) then
			frame:Show();
		end
	elseif (msg == "hide") then
		if (frame:IsShown()) then
			frame:Hide();
		end
	elseif (msg == "debugon") then
		Avoidance_Settings.EnableDebugging = true;
	elseif (msg == "debugoff") then
		Avoidance_Settings.EnableDebugging = false;
	elseif (msg == "resetframe") then
		frame:ClearAllPoints();
		frame:SetPoint("CENTER", WorldFrame, 0, 0);
		frame:Show();
	elseif (msg == "on") then
		Avoidance_salv = 1
		DEFAULT_CHAT_FRAME:AddMessage("salvation will be removed");
	elseif (msg == "off") then
		Avoidance_salv = 0
		DEFAULT_CHAT_FRAME:AddMessage("salvation will NOT be removed");
	else
		Avoidance_ShowCommands();
	end
end

--------------------------------------------------------------------------------
-- Shows the avoidance breakdown.
--------------------------------------------------------------------------------
function Avoidance_ShowAvoidance(msg)
	local baseDefense,armorDefense=UnitDefense("player");
	local defenseContrib = (baseDefense + armorDefense - UnitLevel("player") * 5) / 25;

	-- Calculate total avoidance.
	local baseAvoidance = 5;
	local dodge = GetDodgeChance();
	local parry = GetParryChance();
	local totalAvoidance = baseAvoidance + defenseContrib + dodge + parry;

	-- Calculat mitigation stats
	local block = GetBlockChance();
	local playerLevel = UnitLevel("player");
	local base, effectiveArmor = UnitArmor("player");
	local armorReduction = effectiveArmor/((85 * playerLevel) + 400);
	armorReduction = (armorReduction/(armorReduction + 1))*100;
	local maxHealth = UnitHealthMax("player");
	
	-- TODO: Check for shield, and if present, add block chance, otherwise don't add block chance.
	-- TODO: Should we check for a weapon for parry chance?
	-- TODO: Remove block from /avoid and add /mitigation
	
	if (msg == "min") then
		print(format("Total avoidance: %.2f%%", totalAvoidance));
	else
		if (Avoidance_Settings.EnableDebugging) then
			print("Total Avoidance Breakdown");			
			print(format("  Base avoidance : %.2f%%", baseAvoidance));
			print(format("  Def. avoidance : %.2f%%", defenseContrib));
			print(format("  Dodge : %.2f%%", dodge));
			print(format("  Parry : %.2f%%", parry));
			print(format("Total Avoidance : %.2f%%", totalAvoidance));
			print(format("Block Chance : %.2f%%", block));
			print(format("Armor: %d(%.1f%%)", effectiveArmor, armorReduction));
			print(format("HP: %d", maxHealth));
		end
		AvoidanceBaseText:SetText(format("%002.2f%% - base avoidance", baseAvoidance));
		AvoidanceDefText:SetText(format("%002.2f%% - avoid. from defense", defenseContrib));
		AvoidanceDodgeText:SetText(format("%002.2f%% - dodge", dodge));
		AvoidanceParryText:SetText(format("%002.2f%% - parry", parry));
		AvoidanceTotalText:SetText(format("%002.2f%% - TOTAL AVOIDANCE", totalAvoidance));
		AvoidanceBlockText:SetText(format("%002.2f%% - block", block));
		AvoidanceArmorText:SetText(format("%d(%002.1f%%) - armor", effectiveArmor,armorReduction));
		AvoidanceHPText:SetText(format("%d - MAX HP", maxHealth));
	end
end

--------------------------------------------------------------------------------
-- Creates the Avoidance frame.
--------------------------------------------------------------------------------
function Avoidance_CreateFrame()
	if (frame == nil) then
		frame = CreateFrame("Button", "AvoidanceFrame", UIParent);
	end
	
	if (Avoidance_Settings.Pos == nil) then
		frame:SetPoint("CENTER", 0, 200);
	else
		frame:SetPoint(Avoidance_Settings.Pos, Avoidance_Settings.PosX, Avoidance_Settings.PosY);
	end
	
	frame:SetHeight(100);
	frame:SetBackdrop(
		{
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
			tile = true,
			tileSize = 16
		}
	);
	frame:SetBackdropColor(0.09, 0.09, 0.19, 0.5);
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1);
	
	-- Title top.
	local y = -6;
	
	AvoidanceTitle = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceTitle:SetPoint("TOPLEFT", 10, y);
	AvoidanceTitle:SetText("Total avoidance breakdown");
	
	y = y - 13;
	AvoidanceBaseText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceBaseText:SetPoint("TOPLEFT", 10, y);
	AvoidanceBaseText:SetText("00.00% - base avoidance");
	
	y = y - 13;
	AvoidanceDefText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceDefText:SetPoint("TOPLEFT", 10, y);
	AvoidanceDefText:SetText("00.00% - avoid. from defense");
	
	y = y - 13;
	AvoidanceDodgeText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceDodgeText:SetPoint("TOPLEFT", 10, y);
	AvoidanceDodgeText:SetText("00.00% - dodge");
	
	y = y - 13;
	AvoidanceParryText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceParryText:SetPoint("TOPLEFT", 10, y);
	AvoidanceParryText:SetText("00.00% - parry");
	
	y = y - 13;
	AvoidanceDashesText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceDashesText:SetPoint("TOPLEFT", 10, y);
	AvoidanceDashesText:SetText("-------------------------");
	
	y = y - 13;
	AvoidanceTotalText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceTotalText:SetPoint("TOPLEFT", 10, y);
	AvoidanceTotalText:SetText("00.00% - TOTAL AVOIDANCE");
	
	y = y - 13;
	AvoidanceBlockText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceBlockText:SetPoint("TOPLEFT", 10, y);
	AvoidanceBlockText:SetText("00.00% - block");
	
	y = y - 13;
	AvoidanceArmorText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceArmorText:SetPoint("TOPLEFT", 10, y);
	AvoidanceArmorText:SetText("0(00.00%) - armor");

	y = y - 13;
	AvoidanceHPText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	AvoidanceHPText:SetPoint("TOPLEFT", 10, y);
	AvoidanceHPText:SetText("0(00.00%) - HP");
	
	y = y - 19;
	frame:SetHeight(y * -1);
	
	frame:SetWidth(175);
--	frame:SetScript("OnClick", function(This) Avoidance_Reset(); end);
	frame:SetMovable(true);
	frame:RegisterForDrag("LeftButton");

--  this fixed by hobbit for turtle wow.
	frame:SetScript("OnDragStart", function() frame:StartMoving(); end);
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		Avoidance_Settings.Pos, Avoidance_Settings.PosX, Avoidance_Settings.PosY = "BOTTOMLEFT",
		frame:GetLeft(), frame:GetBottom()
		end
	);
	Avoidance_ShowAvoidance(nil);
end

--------------------------------------------------------------------------------
-- Resets avoidance.
--------------------------------------------------------------------------------
function Avoidance_Reset()
	Avoidance_ShowAvoidance(nil);
end

--------------------------------------------------------------------------------
-- Fires when an event we are listening to is fired.
--------------------------------------------------------------------------------
function Avoidance_OnEvent()
	if (event == "VARIABLES_LOADED") then
		Avoidance_CreateFrame();
	elseif (event == "UNIT_STATS") then
		Avoidance_ShowAvoidance("stats");
	elseif (event == "UNITDEFENSE") then
		Avoidance_ShowAvoidance("defense");
	elseif (event == "UNIT_AURA") then
		Avoidance_ShowAvoidance("aura");
	elseif (event == "PLAYER_LOGIN") then
			DEFAULT_CHAT_FRAME:AddMessage("use /avoid for commands");
-- 			hide window on log in and set salv remove to off
			frame:Show();
			Avoidance_salv = 0;
	elseif (event == "PLAYER_AURAS_CHANGED") then
			if (Avoidance_salv == 1) then
			Avoid_CancelSalvationBuff();
			end
	end
	
	if (Avoidance_Show == 0) then
		frame:Show();
		Avoidance_Show = 1;
	end
end

-- salv remover
function Avoid_CancelSalvationBuff()
	local buff = {"Spell_Holy_SealOfSalvation", "Spell_Holy_GreaterBlessingofSalvation"}
	local counter = 0
	while GetPlayerBuff(counter) >= 0 do
		local index, untilCancelled = GetPlayerBuff(counter)
		if untilCancelled ~= 1 then
			local i = 1
			while buff[i] do
				if string.find(GetPlayerBuffTexture(index), buff[i]) then
				    DEFAULT_CHAT_FRAME:AddMessage("buff found");
					CancelPlayerBuff(index);
					--UIErrorsFrame:Clear();
					DEFAULT_CHAT_FRAME:AddMessage("Salvation Removed");
					return
				end
				i = i + 1
			end	
		end
		counter = counter + 1
	end
	return nil
end

