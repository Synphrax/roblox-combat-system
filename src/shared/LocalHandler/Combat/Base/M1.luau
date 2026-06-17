local module = {}

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local ServerRemote = RS.Remotes.Server
local Assets = RS:FindFirstChild("Assets")
local Sounds = Assets and Assets:FindFirstChild("Sounds")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local AnimationHandler = require(RS.Shared.Modules.AnimationHandler)

-- Config
local comboResetTime = 1.5
local comboMax = 4

local animIds = {
    "rbxassetid://126033672292873", -- Right hook
    "rbxassetid://73763577846518", -- Left hook
    "rbxassetid://126033672292873", -- Right hook again
    "rbxassetid://99128033964453" -- Final uppercut (left)
}

local combo = 0
local cooldown = 0
local comboResetTask = nil
local canAttack = true

local function resetCombo()
    print("Combo reset triggered")
    
    combo = 0
    canAttack = true
    comboResetTask = nil
end

function module.OnM1Activated()
    if not canAttack then return end

    if character:GetAttribute("CantAnything") then return end
    if character:GetAttribute("Stunned") then return end
    if character:GetAttribute("Blocking") then return end
    canAttack = false

    combo = (combo % comboMax) + 1
    local animId = animIds[combo]
    if animId then
        AnimationHandler.LoadAnim(character, "M1", animId, nil, false, Enum.AnimationPriority.Action4)
    end

    if comboResetTask then
        task.cancel(comboResetTask)
        comboResetTask = nil
    end

    comboResetTask = task.delay(comboResetTime, resetCombo)
    ServerRemote:FireServer({Type = "Combat", Action = "M1", Func = "ServerCheck"})

    if combo == 4 then
        task.wait(cooldown + 1)
    else
        task.wait(cooldown)
    end

    canAttack = true
end

function module.ServerResponse(player, response)
    if response == "Declined" then
        AnimationHandler.StopAnim(character, "M1", animIds[combo])
        print(response)
    end
end

module.Hit = function(oCharacter, eCharacter)
    if Sounds and Sounds:FindFirstChild("PunchHit") then
        Sounds.PunchHit:Play()
    end
    local HitFX = RS.Assets.FX.HitFX.Attachment:Clone()
    HitFX.Parent = eCharacter:FindFirstChild("Torso")
    for i,v in ipairs(HitFX:GetChildren()) do
        v:Emit(4)
    end
    Debris:AddItem(HitFX,.5)
end

module.Blocked = function(oCharacter, eCharacter)
    if Sounds and Sounds:FindFirstChild("BlockedHit") then
        Sounds.BlockedHit:Play()
    end
    local HitFX = RS.Assets.FX.BlockFX.Attachment:Clone()
    HitFX.Parent = eCharacter:FindFirstChild("Torso")
    for i,v in ipairs(HitFX:GetChildren()) do
        v:Emit(4)
    end
    Debris:AddItem(HitFX,.5)
end

module.PerfectBlocked = function(oCharacter, eCharacter)
    if Sounds and Sounds:FindFirstChild("PerfectBlock") then
        Sounds.PerfectBlock:Play()
    end
    local HitFX = RS.Assets.FX.PBFX.Attachment:Clone()
    HitFX.Parent = eCharacter:FindFirstChild("Torso")
    for i,v in ipairs(HitFX:GetChildren()) do
        v:Emit(4)
    end
    Debris:AddItem(HitFX,.5)
end

return module
