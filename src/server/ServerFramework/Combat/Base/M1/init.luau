local module = {}

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicateRemote = RS.Remotes.Replicate

local Helper = require(SSS.Server.Modules.HelperModule)
local StateHandler = require(RS.Shared.Modules.StateHandler)
local AnimationHandler = require(RS.Shared.Modules.AnimationHandler)

local hitboxDelay = 0.25
local hitboxDuration = .1
local guardbreak = false
local dmg = 5

local comboResetTime = 1.5
local comboResetTasks = {}

function module.ServerCheck(player)
    local character = player.Character
    if not character then return end

    local humrp = character:FindFirstChild("HumanoidRootPart")
    if not humrp then return end
    
    local isBusy
    local decision
    
    if StateHandler.GetState(character,"M1") then isBusy = true
    elseif StateHandler.GetState(character,"CantAnything") then isBusy = true
    elseif StateHandler.GetState(character,"Blocking") then isBusy = true
    elseif StateHandler.GetState(character,"Stunned") then isBusy = true
    end

    if isBusy then
        decision = "Declined"
        ReplicateRemote:FireClient(player, {
            Type = "Combat",
            Action = "M1",
            Func = "ServerResponse"
        }, player, decision)
        return
    end
    StateHandler.SetState(character,"CantAnything",true,0.5)

    local Combo = StateHandler.GetState(character,"Combo")
    if Combo == nil then
        Combo = 1
        StateHandler.SetState(character,"Combo",1,31536000)
    elseif Combo == 1 then
        StateHandler.SetState(character,"Combo",2,31536000)
        Combo = 2
    elseif Combo == 2 then
        StateHandler.SetState(character,"Combo",3,31536000)
        Combo = 3
    elseif Combo == 3 then
        StateHandler.SetState(character,"Combo",1,31536000)
        Combo = 1
    end

    if comboResetTasks[character] then
        task.cancel(comboResetTasks[character])
    end

    comboResetTasks[character] = task.delay(comboResetTime, function()
        StateHandler.RemoveStates(character, "Combo")
        comboResetTasks[character] = nil
    end)

    --/ Hitbox Side
    
    Helper.SetSpeed(character,4,16)
    task.delay(hitboxDelay,function()
        Helper.ResetSpeed(character)
    end)
    task.wait(hitboxDelay)

    StateHandler.SetState(character,"M1",true,hitboxDuration)

    local hitbox = script.Hitbox:Clone()
    hitbox.CFrame = humrp.CFrame * CFrame.new(0, 0, -1.5)
    hitbox.Parent = workspace.Hitboxes
    hitbox.Owner.Value = tostring(character.Name)
    hitbox.AttackName.Value = "M1"

    local cframe = hitbox.CFrame
    local size = hitbox.Size

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {hitbox, character}
    params.MaxParts = 200

    local results = workspace:GetPartBoundsInBox(cframe, size, params)

    local alreadyHit = {}

    for _, part in ipairs(results) do
        local targetCharacter = part:FindFirstAncestorOfClass("Model")
        if targetCharacter and not alreadyHit[targetCharacter] then
            local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
            local isPlayer = Players:GetPlayerFromCharacter(targetCharacter)
            local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
            local attackerHRP = character:FindFirstChild("HumanoidRootPart")
            if humanoid and (not isPlayer or isPlayer ~= player) then
                alreadyHit[targetCharacter] = true

                if StateHandler.GetState(targetCharacter,"IFRAMES") then
                    print("IFRAMES")
                    continue
                end

                local function DoAttack(extradmg,KnockbackDistance)
                    if not targetHRP or not attackerHRP then return end

                    local direction = (targetHRP.Position - attackerHRP.Position).Unit
                    if StateHandler.GetState(character,"Combo") == 3 then
                        Helper.ApplyKnockback(targetCharacter, direction,35, 0.2)
                    else
                        Helper.ApplyKnockback(targetCharacter, direction,KnockbackDistance, 0.2)
                    end
                    StateHandler.SetStun(targetCharacter,true,0.6,2)
                    targetCharacter:FindFirstChild("Humanoid"):TakeDamage(dmg + extradmg)
                end

                if StateHandler.GetState(targetCharacter,"PerfectBlocking") then
                    if not targetHRP or not attackerHRP then continue end

                    local toAttacker = (attackerHRP.Position - targetHRP.Position).Unit
                    local forward = targetHRP.CFrame.LookVector
                    local dot = forward:Dot(toAttacker)
                    local blockAngleThreshold = 0.5 -- about 60 degrees cone in front

                    if dot > blockAngleThreshold then
                        ReplicateRemote:FireAllClients({
                            Type = "Combat",
                            Action = "M1",
                            Func = "PerfectBlocked"
                        },character,targetCharacter)
                        StateHandler.SetStun(character,true,1.5,2)
                        StateHandler.SetState(character,"CantAnything",true,1.5)
                    else
                        StateHandler.RemoveStates(targetCharacter, "PerfectBlocking")
                        ReplicateRemote:FireAllClients({
                            Type = "Combat",
                            Action = "M1",
                            Func = "Hit"
                        },character,targetCharacter)
                        DoAttack(0,5)
                    end
                elseif StateHandler.GetState(targetCharacter,"M1") then
                    Helper.RemoveHitboxesByNameForCharacter(targetCharacter,"M1")
                    alreadyHit[targetCharacter] = true
                    DoAttack(0,5)

                elseif StateHandler.GetState(targetCharacter,"M2") then
                    Helper.RemoveHitboxesByNameForCharacter(targetCharacter,"M2")
                    alreadyHit[targetCharacter] = true
                    DoAttack(0,5)

                elseif StateHandler.GetState(targetCharacter,"Blocking") then
                    if targetHRP and attackerHRP then
                        local toAttacker = (attackerHRP.Position - targetHRP.Position).Unit
                        local forward = targetHRP.CFrame.LookVector
                        local dot = forward:Dot(toAttacker)
                        local blockAngleThreshold = 0.5 -- about 60 degrees cone in front

                        if dot > blockAngleThreshold then
                            if guardbreak then
                                StateHandler.SetStun(targetCharacter,true,1.5,2)
                                StateHandler.RemoveStates(targetCharacter,"Blocking")
                                AnimationHandler.StopAnim(targetCharacter,"","rbxassetid://76287441828355")
                                targetCharacter:FindFirstChild("Humanoid"):TakeDamage(dmg + 5)
                            else
                                ReplicateRemote:FireAllClients({
                                    Type = "Combat",
                                    Action = "M1",
                                    Func = "Blocked"
                                },character,targetCharacter)
                            end
                        else
                            ReplicateRemote:FireAllClients({
                                Type = "Combat",
                                Action = "M1",
                                Func = "Hit"
                            },character,targetCharacter)
                            DoAttack(0,5)
                        end
                    end

                else
                    ReplicateRemote:FireAllClients({
                        Type = "Combat",
                        Action = "M1",
                        Func = "Hit"
                    },character,targetCharacter)
                    DoAttack(0,5)
                end
            end
        end
    end
    Debris:AddItem(hitbox, hitboxDuration)
end

return module
