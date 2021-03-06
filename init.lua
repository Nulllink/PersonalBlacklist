local _, core = ...; -- Namespace
local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
local L = LibStub("AceLocale-3.0"):GetLocale("PBL")

local addon = LibStub("AceAddon-3.0"):NewAddon("PBL", "AceConsole-3.0")
local pblLDB = LibStub("LibDataBroker-1.1"):NewDataObject("PBL!", {
	type = "data source",
	text = "PBL!",
	icon = "Interface\\AddOns\\PersonalBlacklist\\media\\newIcon.blp",
	OnTooltipShow = function(tooltip)
          tooltip:SetText("Personal BlackList")
          tooltip:AddLine("(PBL)", 1, 1, 1)
          tooltip:Show()
     end,
	OnClick = function() PBL_MinimapButton_OnClick() end,
})
local icon = LibStub("LibDBIcon-1.0")

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("PBL_", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})
	icon:Register("PBL!", pblLDB, self.db.profile.minimap)
	self:RegisterChatCommand("PBL", "CommandThePBL")
end

function addon:CommandThePBL()
	self.db.profile.minimap.hide = not self.db.profile.minimap.hide
	if self.db.profile.minimap.hide then
		icon:Hide("PBL!")
	else
		icon:Show("PBL!")
	end
end

--------------------------------------
-- Custom Slash Command
--------------------------------------
core.commands = {
	["show"] = core.Config.Toggle, -- this is a function (no knowledge of Config object)
	
	["help"] = function()
		print(" ");
		core:Print(L["commandsListChat"]..":")
		core:Print("|cff00cc66/pbl show|r - "..L["commandShowChat"]);
		core:Print("|cff00cc66/pbl help|r - shows help info");
		--core:Print("|cff00cc66/pbl ban|r - add a player to the ban list");
		--core:Print("|cff00cc66/pbl unban|r - removes a player from the ban list");
		core:Print("|cff00cc66/pbl banlist|r - "..L["commandBanListChat"]);
		print(" ");
	end,

	["ban"] = function()
		--core.Config.addBan();
	end;

	['unban'] = function()
		--core.Config.removeBan();
	end;

	['banlist'] = function()
		core.Config.checkBanList();
	end;

};

local function HandleSlashCommands(str)	
	if (#str == 0) then	
		-- User just entered "/at" with no additional args.
		core.commands.help();
		return;		
	end	
	
	local args = {};
	for _, arg in ipairs({ string.split(' ', str) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
	end
	
	local path = core.commands; -- required for updating found table.
	
	for id, arg in ipairs(args) do
		if (#arg > 0) then -- if string length is greater than 0.
			arg = arg:lower();			
			if (path[arg]) then
				if (type(path[arg]) == "function") then				
					-- all remaining args passed to our function!
					path[arg](select(id + 1, unpack(args))); 
					return;					
				elseif (type(path[arg]) == "table") then				
					path = path[arg]; -- another sub-table found!
				end
			else
				-- does not exist!
				core.commands.help();
				return;
			end
		end
	end
end

function core:Print(...)
    local hex = select(4, self.Config:GetThemeColor());
    local prefix = string.format("|cff%s%s|r", hex:upper(), "Personal Black List:");	
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

-- WARNING: self automatically becomes events frame!
function core:init(event, name)
	if (name ~= "PersonalBlacklist") then return end 

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end
	
	----------------------------------
	-- Register Slash Commands!
	----------------------------------

	SLASH_PersonalBlacklist1 = "/pbl";
	SlashCmdList.PersonalBlacklist = HandleSlashCommands;

	if(not PBL_) then
		PBL_ = {
			bans = {
				ban_name = {},
				ban_reason = {},
				ban_category = {},
				ban_categories = {},
				ban_reasons = {},
			 }
		} 
	end

	if(not PBL_.bans) then PBL_.bans = { }; end
	if(not PBL_.bans.ban_name) then PBL_.bans.ban_name = { }; end
	if(not PBL_.bans.ban_reason) then PBL_.bans.ban_reason = { }; end
	if(not PBL_.bans.ban_category) then PBL_.bans.ban_category = { }; end
	
	if(not PBL_.bans.ban_categories) then PBL_.bans.ban_categories = { }; end
	if(not PBL_.bans.ban_reasons) then PBL_.bans.ban_reasons = { }; end

	PBL_.bans.ban_categories = {
		L["dropDownCat"],
		L["dropDownAll"],
		L["dropDownGuild"],
		L["dropDownRaid"],
		L["dropDownMythic"],
		L["dropDownPvP"],
		L["dropDownWorld"]
	};
	PBL_.bans.ban_reasons = {
		L["dropDownRea"],
		L["dropDownAll"],
		L["dropDownQuit"],
		L["dropDownToxic"],
		L["dropDownBadDPS"],
		L["dropDownBadHeal"],
		L["dropDownBadTank"],
		L["dropDownBadPlayer"],
		L["dropDownAFK"],
		L["dropDownNinja"],
		L["dropDownSpam"],
		L["dropDownScam"],
		L["dropDownRac"]
	};

	StaticPopupDialogs.CONFIRM_LEAVE_IGNORE = {
		text = "%s",
		button1 = L["confirmYesBtn"],
		button2 = L["confirmNoBtn"],
		OnAccept = LeaveParty,
		whileDead = 1, hideOnEscape = 1, showAlert = 1,
	}

	local f = CreateFrame("Frame");

	function f:OnEvent(event)
		if event == "GROUP_ROSTER_UPDATE" then
			C_Timer.After(2, function()
				local pjs = {};
				for i=1, GetNumGroupMembers() do
					local name,realm = UnitName("party".. i);
					if name then
						if (not realm) or (realm == " ") or (realm == "") then realm = GetRealmName(); end
						local fullName = strupper(name.."-"..realm);
						for j=1, table.getn(PBL_.bans.ban_name) do
							if PBL_.bans.ban_name[j] == fullName then -- found an ignored player
								pjs[table.getn(pjs) + 1] = fullName
							end	
						end
					end						
				end
				if table.getn(pjs) ~= 0 then
					text = ""
					for j=1, table.getn(pjs) do
						text = text..pjs[j].."\n"
					end
					if table.getn(pjs) > 1 then
						text = text..L["confirmMultipleTxt"]
					else
						text = text..L["confirmSingleTxt"]
					end
					StaticPopup_Show("CONFIRM_LEAVE_IGNORE", text);
				end

			end)
		end
	end



GameTooltip:HookScript("OnTooltipSetUnit", function(self)
	local name, unit = self:GetUnit()
	if UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and not UnitIsUnit(unit, "party") then
		local name, realm = UnitName(unit)
		name = name .. "-" .. (realm or GetRealmName())
		if has_value(PBL_.bans.ban_name, strupper(name)) then		
				self:AddLine("PBL Blacklisted!", 1, 0, 0, true)	
		end
	end
end)

local hooked = { }

local function OnLeaveHook(self)
		GameTooltip:Hide();
end

hooksecurefunc("LFGListApplicationViewer_UpdateResults", function(self)
	local buttons = self.ScrollFrame.buttons
	for i = 1, #buttons do
		local button = buttons[i]
		if not hooked[button] then
			if button.applicantID and button.Members then
				for j = 1, #button.Members do
					local b = button.Members[j]
					if not hooked[b] then
						hooked[b] = 1
						b:HookScript("OnEnter", function()
							local appID = button.applicantID;
							local name = C_LFGList.GetApplicantMemberInfo(appID, 1);
							if not string.match(name, "-") then
								name = name.."-"..GetRealmName();
							end
							if has_value(PBL_.bans.ban_name, strupper(name)) then			
								GameTooltip:AddLine("PBL Blacklisted!",1,0,0,true);
								GameTooltip:Show();
							end
						end
						)
						b:HookScript("OnLeave", OnLeaveHook)
					end
				end
			end
		end
	end
end)

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
							
	
function PBL_MinimapButton_OnClick()
	 core.commands.show();
end


	f:RegisterEvent("GROUP_ROSTER_UPDATE");
	f:SetScript("OnEvent", f.OnEvent);

end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.init);