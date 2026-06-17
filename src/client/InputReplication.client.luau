local CAS = game:GetService("ContextActionService")
local EncodingService = game:GetService("EncodingService")
local PlaceAssetIdsService = game:GetService("PlaceAssetIdsService")
local RS = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local ReplicateRemote = RS.Remotes:WaitForChild("Replicate")
local ReplicationFolder = RS:WaitForChild("LocalHandler")

local loadedClientModules = {}

local typeToStringValue = {
    Combat = "playerCombatType",
    Ability = "playerSkillSet"
}

local function getClientModule(actionType, functionName)
    local typeConversion = typeToStringValue[actionType]
    local equipped = player:FindFirstChild(typeConversion)
    
    local folderName = equipped.Value
    local typeFolder = ReplicationFolder:FindFirstChild(actionType)
    local actionFolder = typeFolder:FindFirstChild(folderName)
    local moduleScript = actionFolder:FindFirstChild(functionName)

    loadedClientModules[actionType] = loadedClientModules[actionType] or {}
    loadedClientModules[actionType][folderName] = loadedClientModules[actionType][folderName] or {}
    loadedClientModules[actionType][folderName][functionName] = loadedClientModules[actionType][folderName][functionName] or require(moduleScript)

    return loadedClientModules[actionType][folderName][functionName]
end

local function callClientFunction(actionType, moduleName, functionName, ...) -- Can send through extra data with the ...
    local clientModule = getClientModule(actionType, moduleName)

    if clientModule and typeof(clientModule[functionName]) == "function" then
        clientModule[functionName](...)
    else
        warn(`Function "{functionName}" not found in client module "{moduleName}"`)
    end
end

local function onInput(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        if actionName == "M1Input" then
            callClientFunction("Combat", "M1", "OnM1Activated")

        elseif actionName == "M2Input" then
            callClientFunction("Combat", "M2", "OnM2Activated")

        elseif actionName == "BlockInput" then
            callClientFunction("Combat", "Block", "Block")
        end

    elseif inputState == Enum.UserInputState.End then
        if actionName == "BlockInput" then
            callClientFunction("Combat", "Block", "Unblock")
        end
    end
end

local function bindInputs()
    CAS:BindAction("M1Input", onInput, false, 
        Enum.UserInputType.MouseButton1
    )

    CAS:BindAction("M2Input", onInput, false, 
        Enum.KeyCode.R
    )

    CAS:BindAction("BlockInput", onInput, false, 
        Enum.KeyCode.F
    )
end

bindInputs()