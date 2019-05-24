JunkDump = {}

local function print(txt)
	EA_ChatWindow.Print(towstring(txt))
end

local langStrings = {}
local JDitemList = {}
local JDitemCraftingList = {}
local JDreportList = {}
local JDStartMoney = 0
local JDshowMoney = 0
local TestModeList = {}
local TestModeCraftingList = {}
local TestModeHighLightColor = {r = 255, g = 0, b = 0}
local ClearHighLightColor = {r = 255, g = 255, b = 255}
local AddonVersion = L"1.2.2"

JunkDump.CharacterNameString = "Default" --GameData.Player.name
JunkDump.ServerNameString = "Default" --GameData.Account.ServerName

local TestModeSlotMarker = {}
local TestModeCraftingSlotMarker = {}
local slotMarker = {}
local craftingSlotMarker = {}
local slotHook

local defaultsettings =
{
	Version = 1.51, -- Incase I add more options.
	RarityThreshold = 1, -- 1:Grey, 2:White, 3:Green, 4:Blue, 5:Purple, 6:Orange
	ItemExceptions = {}, -- Array of stuff Not to sell
	ItemAdditions = {}, -- Array of stuff to sell thats not in the rarity
	ShowItemsReport = 0, -- Set if you want a list of items sold, to show up in the report.
	ShowGoldReport = 1, -- Set if you want the total amount of gold obtained from the sale to show up.
	BagMode = 0, --Sets it to Bag Mode. Sells an entire bag.
	BagModeBag = 1, --Which bag to process.
	SellApoth = 0, --Sell Apothecary Items
	SellTalisman = 0, --Sell Talisman items
	SellCultivation = 0, --SellCultivation Items
	SellSalvaging = 0, --SellSalvaging
	ApothMax = 250, --Max Level threshold for Apoth
	TalismanMax = 250, --Max Level threshold for Talisman Making
	CultivationMax = 250, --Max Level threshold for Cultivation
	SalvagingMax = 250, --Max Level threshold for Salvaging
	IgnoreProfessionRarity = 0, --Sell all rarities of a profession.
	FirstRun = 0
}

function JunkDump.Initialize()
	--Check for saved settings, and setup the rest.
	JunkDump.CharacterNameString = "Default" --WStringToString(JunkDump.RemoveGenderGrammarMarkup(JunkDump.CharacterNameString))
	JunkDump.ServerNameString = "Default" --WStringToString(GameData.Account.ServerName)
	
	if not JunkDumpSettings then
		JunkDumpSettings = {}
		JunkDumpSettings[""..JunkDump.ServerNameString..""] = {}
		JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""] = {}
		for k,v in pairs(defaultsettings) do
			JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""][k] = v
		end
	
	elseif not JunkDumpSettings[""..JunkDump.ServerNameString..""] then
		JunkDumpSettings[""..JunkDump.ServerNameString..""] = {}
		JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""] = {}
		for k,v in pairs(defaultsettings) do
			JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""][k] = v
		end
		
	elseif not JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""] then
		JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""] = {}
		for k,v in pairs(defaultsettings) do
			JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""][k] = v
		end
	end
	
	if JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].Version < defaultsettings.Version then
		for k,v in pairs(defaultsettings) do
			if not JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""][k] then JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""][k] = v end
		end
		JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].Version = defaultsettings.Version
	end

	if LibSlash.IsSlashCmdRegistered("jd") then
		print(langStrings[1])
	else
		LibSlash.RegisterWSlashCmd("jd", function(args) JunkDump.SlashHandler(args) end)
	end
	LibSlash.RegisterWSlashCmd("junkdump", function(args) JunkDump.SlashHandler(args) end)
	
	CreateWindow("JunkDumpButtonWin", true)
	WindowClearAnchors("JunkDumpButtonWin")
	WindowAddAnchor("JunkDumpButtonWin", "topright", "EA_Window_InteractionStoreTitleBar", "topright", -35, -10)
	WindowSetParent("JunkDumpButtonWin","EA_Window_InteractionStore")
	ButtonSetText("JunkDumpButtonWin", L"Sell Junk")
	
	slotHook = EA_Window_Backpack.EquipmentLButtonDown
    EA_Window_Backpack.EquipmentLButtonDown = JunkDump.InventoryLButtonDown
	

	JunkDump.StartListeners()
	
	JunkDump.resetSlotMarkers()
	
	d("JunkDump Loaded...") 
	langStrings = JunkDumpLocalization.getMainStrings(SystemData.Settings.Language.active)
	print(L"" .. langStrings[2] .. AddonVersion .. langStrings[3])
	
--[[	if JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].FirstRun == 0 then
		DialogManager.MakeOneButtonDialog(
			L"Due to big changes in 1.0, all settings for JunkDump "..
			L"have been cleared and reset. Please see curse for important info.",
			L"Ok", nil)
		JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].FirstRun = 1
    end--]]
end

-- function found in moth for gendermarkup removal... 
function JunkDump.RemoveGenderGrammarMarkup( input ) -- | pattern courtesy of Aiiane 
 
	if type( input ) == "string" then 
		pattern = ("([^^]+)^?([^^]*)") 
	end 
 
	if type( input ) == "wstring" then 
		pattern = (L"([^^]+)^?([^^]*)") 
	end 
 
	local normal, control = input:match( pattern ) 
	if control then 
		return normal 
	else 
		return input 
	end 
end 

function JunkDump.InventoryLButtonDown(slot, flags)
	if flags == 12 then
		JunkDump.ProcessExceptions(slot)
	elseif flags == 40 then
		JunkDump.ProcessAdditions(slot)
	else
		slotHook(slot, flags)
	end
end

function JunkDump.ProcessExceptions(slot)
	itemData = GetInventoryItemData()
	itemName = itemData[slot].name
	if JunkDump.checkExceptions(itemName) then
		JunkDump.removeFromArrayByName(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions, itemName)
		print(L"" .. langStrings[4] .. itemName .. langStrings[5])
	else
		table.insert(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions, itemName)
		print(L"" .. langStrings[6] .. JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions[table.getn(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions)] .. langStrings[7])
	end
end

function JunkDump.ProcessAdditions(slot)
	itemData = GetInventoryItemData()
	itemName = itemData[slot].name
	
	if JunkDump.checkAdditions(itemName) then
		JunkDump.removeFromArrayByName(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions, itemName)
		print(L"" .. langStrings[4] .. itemName .. langStrings[8])
	else
		table.insert(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions, itemName)
		print(L"" .. langStrings[6] .. JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions[table.getn(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions)] .. langStrings[9])
	end
end

function JunkDump.SlashHandler(args)
	local opt, val = args:match(L"([a-z0-9]+)[ ]?(.*)")

	if not opt then
		print(langStrings[27])
		print(langStrings[28])
		print(langStrings[29])
		--print(langStrings[30])
		print(langStrings[31])
		
	elseif opt == L"exceptions" then
		local opt2, val2 = val:match(L"([a-z0-9]+)[ ]?(.*)")
		if opt2 == L"list" then
			print(langStrings[10])
			for k,v in pairs(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions) do
				print(k..L". "..v)
			end
			
		elseif opt2 == L"del" then
			print(L"" .. langStrings[4] .. JunkDump.removeFromArray(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions, val2) .. langStrings[5])
			
		else
			print(langStrings[10])
			for k,v in pairs(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions) do
				print(k..L". "..v)
			end

		end

	elseif opt == L"additions" then
		local opt2, val2 = val:match(L"([a-z0-9]+)[ ]?(.*)")
		if opt2 == L"list" then
			print(langStrings[11])
			for k,v in pairs(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions) do
				print(k..L". "..v)
			end

		elseif opt2 == L"del" then
			print(L"" .. langStrings[4] .. JunkDump.removeFromArray(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions, val2) .. langStrings[8])
			
		else
			print(langStrings[11])
			for k,v in pairs(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions) do
				print(k..L". "..v)
			end
		end
		
--[[	elseif opt == L"profiles" then
		local opt2, val2 = val:match(L"([a-z0-9]+)[ ]?(.*)")
		if opt2 == L"copy" then
			local opt3, val3 = val2:match(L"([^ ]+) (.*)")
			opt3 = WStringToString(opt3)
			val3 = WStringToString(val3)
			print(JunkDump.copySettings(val3, opt3))
		
		elseif opt2 == L"del" then
			local opt3, val3 = val2:match(L"([^ ]+) (.*)")
			opt3 = WStringToString(opt3)
			val3 = WStringToString(val3)
			print(JunkDump.delSettings(val3, opt3))
			
		elseif opt2 == L"reset" then
			print(JunkDump.resetSettings())
		
		elseif opt2 == L"list" then
			for k,v in pairs(JunkDumpSettings) do
				for k2,v2 in pairs(JunkDumpSettings[k]) do
					print(L"[JunkDump] "..StringToWString(k)..L" - "..StringToWString(k2))
				end
			end
		else
			print(langStrings[12])
		end
		--]]
	elseif opt == L"options" then
		JunkDumpOptions.Show()

	else
		print(langStrings[12])
	end
end

--[[ function JunkDump.copySettings(server, name)
	if not JunkDumpSettings[""..server..""] then
		return L"[JunkDump] " .. langStrings[13]
	elseif not JunkDumpSettings[""..server..""][""..name..""] then
		return L"[JunkDump] " .. langStrings[14]
	else
		for k,v in pairs(JunkDumpSettings[""..server..""][""..name..""]) do
			JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""][k] = v
		end
		return L"[JunkDump] " .. langStrings[15] ..towstring(name).. langStrings[16] ..towstring(server).. langStrings[17]
	end
end

function JunkDump.delSettings(server, name)
	if not JunkDumpSettings[""..server..""] then
		return L"[JunkDump] " .. langStrings[13]
	elseif not JunkDumpSettings[""..server..""][""..name..""] then
		return L"[JunkDump] " .. langStrings[14]
	else
		JunkDumpSettings[""..server..""][""..name..""] = nil
		return L"[JunkDump] " .. langStrings[18] ..towstring(name).. langStrings[19] ..towstring(server).. langStrings[20]
	end
end

function JunkDump.resetSettings()
	if not JunkDumpSettings[""..server..""] then
		return L"[JunkDump] " .. langStrings[13]
	elseif not JunkDumpSettings[""..server..""][""..name..""] then
		return L"[JunkDump] " .. langStrings[14]
	else
		for k,v in pairs(defaultsettings) do
			JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""][k] = v
		end
		return langStrings[21]
	end
end --]]

function JunkDump.StartListeners()
	RegisterEventHandler("JunkDump", SystemData.Events.INTERACT_SHOW_STORE, "JunkDump.processBackpack")
	RegisterEventHandler("JunkDump", SystemData.Events.INTERACT_DONE, "JunkDump.Finalize")
end

function JunkDump.removeFromArray(array, value)
	value = tonumber(WStringToString(value))
	if value > 0 and value <= #array then
			temp = array[value]
			table.remove(array, value)
			return temp
	end
	return langStrings[22]
end

function JunkDump.removeFromArrayByName(array, value)
	for k,v in pairs(array) do
		if v == value then
			temp = array[k]
			table.remove(array, k)
			return temp
		end
	end
	return langStrings[22]
end

function JunkDump.Finalize()
	if #JDitemList == 0 and JDshowMoney == 1 then
		JunkDump.showMeDaMoney()
	end
	JDshowMoney = 0
	JDitemList = {}
	JDreportList = {}
	JunkDump.resetSlotMarkers()
end

function JunkDump.resetSlotMarkers()
	for i=1,GameData.Player.numBackpackSlots do
		slotMarker[i] = 0
	end
end

function JunkDump.resetCraftingSlotMarkers()
	for i=1,GameData.Player.numCraftingSlots*16+16 do
		craftingSlotMarker[i] = 0
	end
end

function JunkDump.resetTestModeSlotMarkers()
	for i=1,GameData.Player.numBackpackSlots do
		TestModeSlotMarker[i] = 0
		TestModeCraftingSlotMarker[i] = 0
	end
end

function JunkDump.resetTestModeCraftingSlotMarkers()
	for i=1,GameData.Player.numCraftingSlots*16+16 do
		TestModeCraftingSlotMarker[i] = 0
	end
end

function JunkDump.JunkBackpack()
	JDStartMoney = Player.GetMoney()
	JunkDump.doTheSale()
end

function JunkDump.processBackpack()
	BpData = GetInventoryItemData()
	CBpData = GetCraftingItemData()
	if(#JDitemList > 0) then
		temp = JDitemList[1]
		table.remove(JDitemList, 1)
		if(temp[2] == EA_Window_Backpack.TYPE_INVENTORY) then
			JunkDump.SellItem(temp[2], temp[1], BpData)
		elseif(temp[2] == EA_Window_Backpack.TYPE_CRAFTING) then
			JunkDump.SellItem(temp[2], temp[1], CBpData)
		end
	elseif #JDitemList <= 0 then
		JunkDump.resetSlotMarkers()
		JunkDump.resetCraftingSlotMarkers()
	end
end

function JunkDump.SellItem(backpackType, inventorySlot, BpData)
	GameData.InteractStoreData.CurrentItemIndex = inventorySlot
    GameData.InteractStoreData.NumItems = BpData[inventorySlot].stackCount
    GameData.InteractStoreData.CurrentBackpackIndex = backpackType
    BroadcastEvent( SystemData.Events.INTERACT_SELL_ITEM )
end

function JunkDump.doTheSale()
	BpData = GetInventoryItemData()
	CBpData = GetCraftingItemData()
	if(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagMode == 0) then
		for i=JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].RarityThreshold,1,-1 do
			for k,v in pairs(BpData) do
				if slotMarker[k] == 0 then
					if JunkDump.checkAdditions(BpData[k].name) and JunkDump.defaultChecks(BpData[k]) and slotMarker[k] ~= 1 then
						tempItem = {k, EA_Window_Backpack.TYPE_INVENTORY}
						table.insert(JDitemList, tempItem)
						table.insert(JDreportList, BpData[k].name)
						slotMarker[k] = 1
					elseif (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].IgnoreProfessionRarity == 1 and JunkDump.professionChecks2(BpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and not(JunkDump.dyeCheck(BpData[k])) and slotMarker[k] ~= 1) and not(JunkDump.checkExceptions(BpData[k].name)) then
						tempItem = {k, EA_Window_Backpack.TYPE_INVENTORY}
						table.insert(JDitemList, tempItem)
						table.insert(JDreportList, BpData[k].name)
						slotMarker[k] = 1
					elseif (JunkDump.runAllChecks(BpData[k], i) and JunkDump.professionChecks(BpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and slotMarker[k] ~= 1) then
						tempItem = {k, EA_Window_Backpack.TYPE_INVENTORY}
						table.insert(JDitemList, tempItem)
						table.insert(JDreportList, BpData[k].name)
						slotMarker[k] = 1
					end
				end
			end
		end
	end
	if(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagMode == 0) then
		for i=JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].RarityThreshold,1,-1 do
			for k,v in pairs(CBpData) do
				if slotMarker[k] == 0 then
					if JunkDump.checkAdditions(CBpData[k].name) and JunkDump.defaultChecks(CBpData[k]) and craftingSlotMarker[k] ~= 1 then
						tempItem = {k, EA_Window_Backpack.TYPE_CRAFTING}
						table.insert(JDitemList, tempItem)
						table.insert(JDreportList, CBpData[k].name)
						craftingSlotMarker[k] = 1
					elseif (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].IgnoreProfessionRarity == 1 and JunkDump.professionChecks2(CBpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and not(JunkDump.dyeCheck(CBpData[k])) and craftingSlotMarker[k] ~= 1) and not(JunkDump.checkExceptions(CBpData[k].name)) then
						tempItem = {k, EA_Window_Backpack.TYPE_CRAFTING}
						table.insert(JDitemList, tempItem)
						table.insert(JDreportList, CBpData[k].name)
						craftingSlotMarker[k] = 1
					elseif (JunkDump.runAllChecks(CBpData[k], i) and JunkDump.professionChecks(CBpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and craftingSlotMarker[k] ~= 1) then
						tempItem = {k, EA_Window_Backpack.TYPE_CRAFTING}
						table.insert(JDitemList, tempItem)
						table.insert(JDreportList, CBpData[k].name)
						craftingSlotMarker[k] = 1
					end
				end
			end
		end
	end
	if(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagMode == 1) then
		endBagSlot = JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagModeBag * 16
		startBagSlot = endBagSlot - 15
		for i=startBagSlot,endBagSlot do
			if (BpData[i].uniqueID ~= 0 and BpData[i].sellPrice ~= 0) then
					table.insert(JDitemList, i)
					table.insert(JDreportList, BpData[i].name)
					slotMarker[i] = 1
			end
		end
	end
	JDshowMoney = 1
	JunkDump.processBackpack()
end

function JunkDump.runAllChecks(itemData, rarity)
	local defaultCheck = false
	local rarityEqual = false
	if (itemData.rarity == rarity) then
		rarityEqual = true
	end
	if JunkDump.defaultChecks(itemData) then
		defaultCheck = true
	end
	if defaultCheck == false then
		return false
	end
	if JunkDump.checkExceptions(itemData.name) and defaultCheck then
		return false
	end
	if JunkDump.checkIfMount(itemData.uniqueID) and defaultCheck then
		return false
	end
	if JunkDump.dyeCheck(itemData) and defaultCheck then
		return false
	end
	if not(rarityEqual) then
		return false
	end
	return true
end

function JunkDump.defaultChecks(itemData)
	if itemData.uniqueID ~= 0 and itemData.sellPrice ~= 0 then
		return true
	end
	return false
end

function JunkDump.professionChecks(itemData)
	CraftData = CraftingSystem.GetCraftingData(itemData)
	if CraftData[1] == 4 and (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellApoth == 0 or itemData.craftingSkillRequirement > JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ApothMax) then
		return false
	end
	if CraftData[1] == 5 and (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellTalisman == 0 or itemData.craftingSkillRequirement > JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].TalismanMax) then
		return false
	end
	if itemData.cultivationType > 0 and (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellCultivation == 0 or itemData.craftingSkillRequirement > JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].CultivationMax) then
		return false
	end
	if CraftData[1] == 6 and  (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellSalvaging == 0 or itemData.craftingSkillRequirement > JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SalvagingMax) then
		return false
	end
	return true
end

function JunkDump.professionChecks2(itemData)
	CraftData = CraftingSystem.GetCraftingData(itemData)
	if CraftData[1] == 4 and JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellApoth == 1 and itemData.craftingSkillRequirement <= JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ApothMax then
		return true
	end
	if CraftData[1] == 5 and JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellTalisman == 1 and itemData.craftingSkillRequirement <= JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].TalismanMax then
		return true
	end
	if itemData.cultivationType > 0 and JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellCultivation == 1 and itemData.craftingSkillRequirement <= JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].CultivationMax then
		return true
	end
	if CraftData[1] == 6 and  JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SellSalvaging == 1 and itemData.craftingSkillRequirement <= JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].SalvagingMax then
		return true
	end
	return false
end

function JunkDump.dyeCheck(itemData)
	itemName = itemData.name
	itemName = WStringToString(itemName)
	temp, isDye = itemName:match("(.*)[ ](Dye)")
	if (isDye == "Dye") then
		return true
	end
	return false
end

function JunkDump.showMeDaMoney()
	EndMoney = Player.GetMoney()
	totalMoney = EndMoney - JDStartMoney
	if(totalMoney > 0) then
		stringMoney = MoneyFrame.FormatMoneyString(totalMoney)..L"."
	else
		stringMoney = L"no money."
	end
	stringOfItems = L""
	for k,v in pairs(JDreportList) do
		if k ~= #JDreportList then
			stringOfItems = stringOfItems..v..L", "
		else
			stringOfItems = stringOfItems..v..L"."
		end
	end
	if JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ShowItemsReport == 1 then
		print(L"[JunkDump] "..langStrings[23]..stringOfItems)
	end
	if JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ShowGoldReport == 1 then
		print(L"[JunkDump] "..langStrings[24]..stringMoney)
	end
	JDreportList = {}
end

function JunkDump.checkExceptions(itemName)
	for i,v in pairs(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemExceptions) do
		if v == itemName then
			return true
		end
	end
	return false
end

function JunkDump.checkAdditions(itemName)
	for i,v in pairs(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].ItemAdditions) do
		if v == itemName then
			return true
		end
	end
	return false
end

function JunkDump.checkIfMount(itemId)
	mountIdTable = {}
	--Boars
	mountIdTable[208017] = true; mountIdTable[208016] = true; mountIdTable[208015] = true; mountIdTable[186818] = true; mountIdTable[186817] = true;
	mountIdTable[186816] = true; mountIdTable[186815] = true; mountIdTable[186814] = true; mountIdTable[186813] = true;
	--Wolves
	mountIdTable[208011] = true; mountIdTable[208010] = true; mountIdTable[208009] = true; mountIdTable[186812] = true; mountIdTable[186811] = true;
	mountIdTable[186810] = true; mountIdTable[186809] = true; mountIdTable[186808] = true; mountIdTable[186807] = true;
	--Chaos Horses
	mountIdTable[208028] = true; mountIdTable[208026] = true; mountIdTable[208025] = true; mountIdTable[186830] = true; mountIdTable[186829] = true;
	mountIdTable[186828] = true; mountIdTable[186827] = true; mountIdTable[186826] = true; mountIdTable[186825] = true;
	--Cold Ones
	mountIdTable[208040] = true; mountIdTable[208039] = true; mountIdTable[208037] = true; mountIdTable[186842] = true; mountIdTable[186841] = true;
	mountIdTable[186840] = true; mountIdTable[186839] = true; mountIdTable[186838] = true; mountIdTable[186837] = true;
	--Copters
	mountIdTable[208005] = true; mountIdTable[208004] = true; mountIdTable[208003] = true; mountIdTable[186806] = true; mountIdTable[186805] = true;
	mountIdTable[186804] = true; mountIdTable[186803] = true; mountIdTable[186802] = true; mountIdTable[186801] = true;
	--Horses
	mountIdTable[208023] = true; mountIdTable[208022] = true; mountIdTable[208021] = true; mountIdTable[186824] = true; mountIdTable[186823] = true;
	mountIdTable[186822] = true; mountIdTable[186821] = true; mountIdTable[186820] = true; mountIdTable[186819] = true;
	--Fancy Horses
	mountIdTable[208034] = true; mountIdTable[208033] = true; mountIdTable[208031] = true; mountIdTable[186836] = true; mountIdTable[186835] = true;
	mountIdTable[186834] = true; mountIdTable[186833] = true; mountIdTable[186832] = true; mountIdTable[186831] = true;
	--Magus Hoverboards
	mountIdTable[186843] = true; mountIdTable[186844] = true; mountIdTable[186845] = true; mountIdTable[186852] = true; mountIdTable[208045] = true;
	mountIdTable[208046] = true; mountIdTable[208047] = true; 
	--Manticore/Griffon
	mountIdTable[207287] = true; mountIdTable[207388] = true; mountIdTable[207389] = true; mountIdTable[207390] = true; mountIdTable[207391] = true; 
	--Teleport Scrolls
	mountIdTable[65825] = true;

	if mountIdTable[itemId] then
		return true
	else
		return false
	end
end

function JunkDump.getMaxBags()
	return GameData.Player.numBackpackSlots / 16
end

function JunkDump.OnMouseOverButton()
	Tooltips.CreateTextOnlyTooltip("JunkDumpButtonWin") 
	Tooltips.SetTooltipText(1, 1, langStrings[25])
	Tooltips.SetTooltipText(2, 1, langStrings[26])
	Tooltips.Finalize()
	Tooltips.AnchorTooltip(Tooltips.ANCHOR_WINDOW_LEFT)
end

function JunkDump.SetTestModeTint(backpackType, slot, passedHighLightColor)
    local pocketNumber     = EA_Window_Backpack.GetPocketNumberForSlot( backpackType, slot )
	
    if pocketNumber == nil
    then
        return
    end
    
    local pocketWindowName = EA_Window_Backpack.GetPocketName( pocketNumber )
    local buttonGroupWindowName = pocketWindowName.."Buttons"
    local buttonIndex = slot - EA_Window_Backpack.pockets[pocketNumber].firstSlotID + 1

	if DoesWindowExist( buttonGroupWindowName ) == false then
		ERROR(L"SetActionButton failed to find window="..StringToWString(buttonGroupName) )
		return
	end
    ActionButtonGroupSetTintColor(  buttonGroupWindowName, buttonIndex,  passedHighLightColor.r, passedHighLightColor.g, passedHighLightColor.b )
    
end

function JunkDump.TestModeRun()
	BpData = GetInventoryItemData()
	CBpData = GetCraftingItemData()
	if(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagMode == 0) then
		for i=JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].RarityThreshold,1,-1 do
			for k,v in pairs(BpData) do
				if TestModeSlotMarker[k] == 0 then
					if JunkDump.checkAdditions(BpData[k].name) and JunkDump.defaultChecks(BpData[k]) then
						tempTestItem = {k, EA_Window_Backpack.TYPE_INVENTORY}
						table.insert(TestModeList, tempTestItem)
						TestModeSlotMarker[k] = 1
					elseif (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].IgnoreProfessionRarity == 1 and JunkDump.professionChecks2(BpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and not(JunkDump.dyeCheck(BpData[k])) and slotMarker[k] ~= 1) and not(JunkDump.checkExceptions(BpData[k].name)) then
						tempTestItem = {k, EA_Window_Backpack.TYPE_INVENTORY}
						table.insert(TestModeList, tempTestItem)
						TestModeSlotMarker[k] = 1
					elseif (JunkDump.runAllChecks(BpData[k], i) and JunkDump.professionChecks(BpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and slotMarker[k] ~= 1) then
						tempTestItem = {k, EA_Window_Backpack.TYPE_INVENTORY}
						table.insert(TestModeList, tempTestItem)
						TestModeSlotMarker[k] = 1
					end
				end
			end
		end
	end
	if(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagMode == 0) then
		for i=JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].RarityThreshold,1,-1 do
			for k,v in pairs(CBpData) do
				if slotMarker[k] == 0 then
					if JunkDump.checkAdditions(CBpData[k].name) and JunkDump.defaultChecks(CBpData[k]) and TestModeCraftingSlotMarker[k] ~= 1 then
						tempTestItem = {k, EA_Window_Backpack.TYPE_CRAFTING}
						table.insert(TestModeList, tempTestItem)
						TestModeCraftingSlotMarker[k] = 1
					elseif (JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].IgnoreProfessionRarity == 1 and JunkDump.professionChecks2(CBpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and not(JunkDump.dyeCheck(CBpData[k])) and TestModeCraftingSlotMarker[k] ~= 1) and not(JunkDump.checkExceptions(CBpData[k].name)) then
						tempTestItem = {k, EA_Window_Backpack.TYPE_CRAFTING}
						table.insert(TestModeList, tempTestItem)
						TestModeCraftingSlotMarker[k] = 1
					elseif (JunkDump.runAllChecks(CBpData[k], i) and JunkDump.professionChecks(CBpData[k]) and not(EA_Window_Backpack.IsSlotLocked(k)) and TestModeCraftingSlotMarker[k] ~= 1) then
						tempTestItem = {k, EA_Window_Backpack.TYPE_CRAFTING}
						table.insert(TestModeList, tempTestItem)
						TestModeCraftingSlotMarker[k] = 1
					end
				end
			end
		end
	end
	if(JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagMode == 1) then
		endBagSlot = JunkDumpSettings[""..JunkDump.ServerNameString..""][""..JunkDump.CharacterNameString..""].BagModeBag * 16
		startBagSlot = endBagSlot - 15
		for i=startBagSlot,endBagSlot do
			if (BpData[i].uniqueID ~= 0 and BpData[i].sellPrice ~= 0) then
					table.insert(TestModeList, i)
					TestModeSlotMarker[i] = 1
			end
		end
	end
	JunkDump.TestModeHighlight()
end

function JunkDump.TestModeHighlight()
	while #TestModeList > 0 do
		temp = TestModeList[1]
		table.remove(TestModeList, 1)
		JunkDump.SetTestModeTint(temp[2], temp[1], TestModeHighLightColor)
	end
	JunkDump.resetTestModeSlotMarkers()
	JunkDump.resetTestModeCraftingSlotMarkers()
end

function JunkDump.TestModeClear()
	for i=1, GameData.Player.numBackpackSlots do
		JunkDump.SetTestModeTint(EA_Window_Backpack.TYPE_INVENTORY, i, ClearHighLightColor)
	end
	for i=1, GameData.Player.numCraftingSlots*16+16 do
		JunkDump.SetTestModeTint(EA_Window_Backpack.TYPE_CRAFTING, i, ClearHighLightColor)
	end
end