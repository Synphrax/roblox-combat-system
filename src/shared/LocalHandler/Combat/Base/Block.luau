local module = {}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TS = game:GetService("TweenService")
local ServerRemote = RS.Remotes.Server
local Sounds = RS.Assets.Sounds

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local AnimationHandler = require(RS.Shared.Modules.AnimationHandler)

local ServerRemote = RS.Remotes.Server

local animId = "rbxassetid://98547343672589"

function module.Block ()
    if character:GetAttribute("CantAnything") then return end
    if character:GetAttribute("Stunned") then return end

    AnimationHandler.LoadAnim(character, "Blocking", animId, nil, false)
    ServerRemote:FireServer({Type = "Combat",Action = "Block",Func = "Activated",})
end

function module.Unblock ()
    AnimationHandler.StopAnim(character,"Blocking",animId)
    ServerRemote:FireServer({Type = "Combat",Action = "Block",Func = "Deactivated",})
end

return module