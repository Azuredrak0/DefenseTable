-- Written By: Azuredrak0 (a.k.a Drokin - Level 60 Warden, Shaman Tank)
-- Code partially based on Avoidance mod written by Kip Potter

-- Global version variable...
DefenseTable_VERSION = "0.9";

-- Other globals.
local DefenseTable_Settings = {};
local DefenseTable_salv = {};
local targetLVL = 63;

-- Locals.
local frame;

--------------------------------------------------------------------------------
-- Handles loading the add-on.
--------------------------------------------------------------------------------
function DefenseTable_OnLoad(Self)
	DEFAULT_CHAT_FRAME:AddMessage(format("DefenseTable v%s loaded.", DefenseTable_VERSION));
	
	-- Register the game slash commands necessary for our functionality
	SLASH_DefenseTable1 = "/defensetable";
	SLASH_DefenseTable2 = "/dt";
	SlashCmdList["DefenseTable"] = DefenseTable_SlashCommand;
	
	-- Register the events.
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("UNIT_STATS");
	this:RegisterEvent("UNIT_AURA");
	this:RegisterEvent("UNIT_DEFENSE");
	this:RegisterEvent("PLAYER_LOGIN");
	this:RegisterEvent("PLAYER_AURAS_CHANGED"); 
	this:RegisterEvent("UNIT_INVENTORY_CHANGED"); 
end

--------------------------------------------------------------------------------
-- Shows the command (command-line parameters) options for DefenseTable.
--------------------------------------------------------------------------------
function DefenseTable_ShowCommands()
	DEFAULT_CHAT_FRAME:AddMessage("DefenseTable command options:");
	if (frame:IsShown()) then
		DEFAULT_CHAT_FRAME:AddMessage("  show [true] - Shows window.");
		DEFAULT_CHAT_FRAME:AddMessage("  hide [false] - Hides window.");
	else
		DEFAULT_CHAT_FRAME:AddMessage("  show [false] - Shows window.");
		DEFAULT_CHAT_FRAME:AddMessage("  hide [true] - Hides window.");
	end
	
	if (DefenseTable_Settings.EnableDebugging) then
		DEFAULT_CHAT_FRAME:AddMessage("  debugon  [true] - Enables displaying debug information to the chat window.");
		DEFAULT_CHAT_FRAME:AddMessage("  debugoff [false] - Disables displaying debug information to the chat window.");
	else
		DEFAULT_CHAT_FRAME:AddMessage("  debugon  [false] - Enables displaying debug information to the chat window.");
		DEFAULT_CHAT_FRAME:AddMessage("  debugoff [true] - Disables displaying debug information to the chat window.");
	end
	DEFAULT_CHAT_FRAME:AddMessage("  tar60 - set target level to 60 (default).");
	DEFAULT_CHAT_FRAME:AddMessage("  tar63 - set target level to 63.");
	DEFAULT_CHAT_FRAME:AddMessage("  ver - Shows the installed version of DefenseTable.");
	DEFAULT_CHAT_FRAME:AddMessage("  resetframe - Resets the DefenseTable frame to it's default position.");
	DEFAULT_CHAT_FRAME:AddMessage("  /avoid off will remove savlation when cast on you.");
	DEFAULT_CHAT_FRAME:AddMessage("  /avoid on will keep savlation when cast on you.");
end

--------------------------------------------------------------------------------
-- Handles the slash commands '/dt' and '/DefenseTable'.
--------------------------------------------------------------------------------
function DefenseTable_SlashCommand(msg)
	if (msg == "ver") then
		DEFAULT_CHAT_FRAME:AddMessage(format("DefenseTable Version: %s", DefenseTable_VERSION));
	elseif (msg == "show") then
		if (not frame:IsShown()) then
			frame:Show();
		end
	elseif (msg == "hide") then
		if (frame:IsShown()) then
			frame:Hide();
		end
	elseif (msg == "tlvl60") then
		targetLVL = 60;
		DEFAULT_CHAT_FRAME:AddMessage(format("Target level set to 60."));
	elseif (msg == "tlvl63") then
		targetLVL = 63;
		DEFAULT_CHAT_FRAME:AddMessage(format("Target level set to 63 (Raid bosses)."));
	elseif (msg == "debugon") then
		DefenseTable_Settings.EnableDebugging = true;
	elseif (msg == "debugoff") then
		DefenseTable_Settings.EnableDebugging = false;
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
		DefenseTable_ShowCommands();
	end
end

--------------------------------------------------------------------------------
-- Shows the defensive stats breakdown.
--------------------------------------------------------------------------------
function DefenseTable_ShowAvoidance(msg)
	--targetLVL = GetTargetLevel();
	local baseDefense,armorDefense=UnitDefense("player");
	local defenseContrib = (baseDefense + armorDefense - UnitLevel("player") * 5) / 25;
	local defenseBonus = (baseDefense + armorDefense - UnitLevel("player") * 5) * .04;

	-- Calculate total avoidance.
	local baseAvoidance = 5 + defenseBonus+((UnitLevel("player")-targetLVL)*.02);
	local dodge = GetDodgeChance()+((UnitLevel("player")-targetLVL)*.02);
	local parry = GetParryChance()+((UnitLevel("player")-targetLVL)*.02);
	local totalAvoidance = baseAvoidance + dodge + parry;

	-- Calculate mitigation stats
	local block = GetBlockChance()+((UnitLevel("player")-targetLVL)*.02);
	local playerLevel = UnitLevel("player");
	local base, effectiveArmor = UnitArmor("player");
	local armorReduction = effectiveArmor/((85 * playerLevel) + 400);
	armorReduction = (armorReduction/(armorReduction + 1))*100;
	local maxHealth = UnitHealthMax("player");
	local avoidanceStack = baseAvoidance + dodge + parry + block;

	-- Calculate chance to be hit
	local crush = 0;
	if targetLVL == 63 then
		crush = 15
	end
	local crit = 5 - defenseBonus-((UnitLevel("player")-targetLVL)*.02);
	if crit <= 0 then
		crit = 0
	end		
	local hit = 75

	if avoidanceStack > 100 then
		crush = 0;
		crit = 0;
		hit = 0;
	end

	if (avoidanceStack + crush) > 100 then
		crush = 100 - avoidanceStack;
		crit = 0;
		hit = 0;
	end
	if (avoidanceStack + crush + crit) > 100 then
		crit = 100 - avoidanceStack - crush;
		hit = 0;
	end
	if (avoidanceStack + crush + crit + hit) > 100 then
		hit = 100 - avoidanceStack - crush - crit;
	end
	
	-- TODO: Check for shield, and if present, add block chance, otherwise don't add block chance.
	-- TODO: Should we check for a weapon for parry chance?
	-- TODO: Remove block from /avoid and add /mitigation
	
	if (msg == "min") then
		print(format("Total avoidance: %.2f%%", totalAvoidance));
	else
		if (DefenseTable_Settings.EnableDebugging) then
			--print("");			
			print(format("  Base avoidance : %.2f%%", baseAvoidance));
			--print(format("  Def. avoidance : %.2f%%", defenseContrib));
			print(format("  Dodge : %.2f%%", dodge));
			print(format("  Parry : %.2f%%", parry));
			print(format("  Block : %.2f%%", block));
			print(format("    crushed : %.2f%%", crush));
			print(format("    critted : %.2f%%", crit));
			print(format("    hit : %.2f%%", hit));
			print(format("Dodge + Parry : %.2f%%", totalAvoidance));
			print(format("Armor: %d(%.1f%%)", effectiveArmor, armorReduction));
			print(format("HP: %d", maxHealth));
		end
		DefenseTableTitle:SetText(format("L%d - Defense Table breakdown", targetLVL));
		DefenseTableBaseText:SetText(format("%002.2f%% - base avoidance", baseAvoidance));
		--DefenseTableDefText:SetText(format("%002.2f%% - avoid. from defense", defenseContrib));
		DefenseTableDodgeText:SetText(format("%002.2f%% - dodge", dodge));
		DefenseTableParryText:SetText(format("%002.2f%% - parry", parry));
		DefenseTableBlockText:SetText(format("%002.2f%% - block", block));
		DefenseTableCrushText:SetText(format("   %002.2f%% - crushed", crush));
		DefenseTableCritText:SetText(format("   %002.2f%% - critted", crit));
		DefenseTableHitText:SetText(format("   %002.2f%% - hit", hit));
		DefenseTableTotalText:SetText(format("%002.2f%% - base + Dodge + Parry", totalAvoidance));
		DefenseTableArmorText:SetText(format("%d(%002.1f%%) - armor", effectiveArmor,armorReduction));
		DefenseTableHPText:SetText(format("%d - MAX HP", maxHealth));
	end
end

--------------------------------------------------------------------------------
-- Creates the Avoidance frame.
--------------------------------------------------------------------------------
function DefenseTable_CreateFrame()
	if (frame == nil) then
		frame = CreateFrame("Button", "DefenseTableFrame", UIParent);
	end
	
	if (DefenseTable_Settings.Pos == nil) then
		frame:SetPoint("CENTER", 0, 200);
	else
		frame:SetPoint(DefenseTable_Settings.Pos, DefenseTable_Settings.PosX, DefenseTable_Settings.PosY);
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
	
	DefenseTableTitle = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableTitle:SetPoint("TOPLEFT", 10, y);
	DefenseTableTitle:SetText("L0(00.00%) - Defense Table breakdown");
	
	y = y - 13;
	DefenseTableBaseText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableBaseText:SetPoint("TOPLEFT", 10, y);
	DefenseTableBaseText:SetText("00.00% - base avoidance");
	
	--y = y - 13;
	--AvoidanceDefText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	--AvoidanceDefText:SetPoint("TOPLEFT", 10, y);
	--AvoidanceDefText:SetText("00.00% - avoid. from defense");
	
	y = y - 13;
	DefenseTableDodgeText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableDodgeText:SetPoint("TOPLEFT", 10, y);
	DefenseTableDodgeText:SetText("00.00% - dodge");
	
	y = y - 13;
	DefenseTableParryText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableParryText:SetPoint("TOPLEFT", 10, y);
	DefenseTableParryText:SetText("00.00% - parry");
	
	y = y - 13;
	DefenseTableBlockText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableBlockText:SetPoint("TOPLEFT", 10, y);
	DefenseTableBlockText:SetText("00.00% - block");

	y = y - 13;
	DefenseTableCrushText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableCrushText:SetPoint("TOPLEFT", 10, y);
	DefenseTableCrushText:SetText("   00.00% - crushed");

	y = y - 13;
	DefenseTableCritText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableCritText:SetPoint("TOPLEFT", 10, y);
	DefenseTableCritText:SetText("   00.00% - critted");

	y = y - 13;
	DefenseTableHitText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableHitText:SetPoint("TOPLEFT", 10, y);
	DefenseTableHitText:SetText("   00.00% - hit");
	
	y = y - 13;
	DefenseTableDashesText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableDashesText:SetPoint("TOPLEFT", 10, y);
	DefenseTableDashesText:SetText("-------------------------");
	
	y = y - 13;
	DefenseTableTotalText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableTotalText:SetPoint("TOPLEFT", 10, y);
	DefenseTableTotalText:SetText("00.00% - base + Dodge + Parry");
		
	y = y - 13;
	DefenseTableArmorText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableArmorText:SetPoint("TOPLEFT", 10, y);
	DefenseTableArmorText:SetText("0(00.00%) - armor");

	y = y - 13;
	DefenseTableHPText = frame:CreateFontString(nil, nil, "GameFontNormalSmall");
	DefenseTableHPText:SetPoint("TOPLEFT", 10, y);
	DefenseTableHPText:SetText("0(00.00%) - HP");
	
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
		DefenseTable_Settings.Pos, DefenseTable_Settings.PosX, DefenseTable_Settings.PosY = "BOTTOMLEFT",
		frame:GetLeft(), frame:GetBottom()
		end
	);
	DefenseTable_ShowAvoidance(nil);
end

--------------------------------------------------------------------------------
-- Resets avoidance.
-----------------------------------------------------------------------
function DefenseTable_Reset()
	DefenseTable_ShowAvoidance(nil);
end

--------------------------------------------------------------------------------
-- Fires when an event we are listening to is fired.
--------------------------------------------------------------------------------
function DefenseTable_OnEvent()
	if (event == "VARIABLES_LOADED") then
		DefenseTable_CreateFrame();
	elseif (event == "UNIT_STATS") then
		DefenseTable_ShowAvoidance("stats");		
	elseif (event == "UNITDEFENSE") then
		DefenseTable_ShowAvoidance("defense");
	elseif (event == "UNIT_INVENTORY_CHANGED") then
		DefenseTable_ShowAvoidance("equip");
	elseif (event == "UNIT_AURA") then
		DefenseTable_ShowAvoidance("aura");
	elseif (event == "PLAYER_LOGIN") then
			DEFAULT_CHAT_FRAME:AddMessage("use /avoid for commands");
-- 			hide window on log in and set salv remove to off
			frame:Show();
			Avoidance_salv = 0;
	elseif (event == "PLAYER_AURAS_CHANGED") then
			if (Avoidance_salv == 1) then
			DefenseTable_CancelSalvationBuff();
			end
	end
	
	if (DefenseTable_Show == 0) then
		frame:Show();
		DefenseTable_Show = 1;
	end
end

-- salv remover
function DefenseTable_CancelSalvationBuff()
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

-- function GetTargetLevel()
  -- local targetUnit = UnitName("target");
  -- if (targetUnit == nil) then
    -- return nil;
  -- end

  -- local targetLevel = UnitLevel(targetUnit);
  -- if (targetLevel == nil) then
    -- return nil;
  -- end

  -- return targetLevel;
-- end
