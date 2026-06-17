local module = {}

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicateRemote = RS.Remotes.Replicate

local Helper = require(SSS.Server.Modules.HelperModule)
local StateHandler = require(RS.Shared.Modules.StateHandler)

local PB_Window = 0.1

module.Activated = function(player)
    local character = player.Character
    if StateHandler.GetState(character,"CantAnything") then return end
    if StateHandler.GetState(character,"Stunned") then return end
    if StateHandler.GetState(character,"M1") then return end

    Helper.SetSpeed(character,3,nil)
    StateHandler.SetState(character,"Blocking",true,9999999)

    -- Activate perfect block window
    StateHandler.SetState(character,"PerfectBlocking",true,PB_Window)
end

module.Deactivated = function(player)
    local character = player.Character
    if StateHandler.GetState(character,"Blocking") then
        Helper.ResetSpeed(character)
        if StateHandler.GetState(character, "PerfectBlocking") then
            StateHandler.RemoveStates(character,"PerfectBlocking")
        end
        StateHandler.RemoveStates(character,"Blocking")
    end
end

return module