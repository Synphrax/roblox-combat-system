local RS = game:GetService("ReplicatedStorage")
local ServerRemote = RS.Remotes.Server

-- Module cache
local LoadedModules = {}

local typeToStringValue = {
	Combat = "playerCombatType",
	Ability = "playerSkillSet",
	Misc = "Misc"
}

ServerRemote.OnServerEvent:Connect(function(player, data, ...)
	local actionType = data.Type
	local moduleName = data.Action
	local funcName = data.Func

	local rootFolder = script:FindFirstChild(actionType)
	local stringValueName = typeToStringValue[actionType]
	if not rootFolder or not stringValueName then
		warn(`Invalid server action type "{actionType}"`)
		return
	end

	local folderNameValue = player:FindFirstChild(stringValueName)
	if not folderNameValue then
		warn(`Missing "{stringValueName}" on player "{player.Name}"`)
		return
	end

	local folderName = folderNameValue.Value
	local actionFolder = rootFolder:FindFirstChild(folderName)
	if not actionFolder then
		warn(`Folder "{folderName}" not found under server action "{actionType}"`)
		return
	end

	local module = actionFolder:FindFirstChild(moduleName)
	if not module then
		warn(`Module "{moduleName}" not found under server action folder "{folderName}"`)
		return
	end

	LoadedModules[player] = LoadedModules[player] or {}
	LoadedModules[player][actionType] = LoadedModules[player][actionType] or {}
	LoadedModules[player][actionType][folderName] = LoadedModules[player][actionType][folderName] or {}
	LoadedModules[player][actionType][folderName][moduleName] = LoadedModules[player][actionType][folderName][moduleName] or require(module)

	local moduleTable = LoadedModules[player][actionType][folderName][moduleName]

	if typeof(moduleTable[funcName]) == "function" then
		moduleTable[funcName](player, ...)
	else
		warn(`Function "{funcName}" not found in module "{moduleName}"`)
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	LoadedModules[player] = nil
end)
