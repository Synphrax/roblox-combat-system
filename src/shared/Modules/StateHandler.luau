local module = {}

local states = {}
local stunTimers = {}

function module.ReturnStates(character)
	return states[character]
end

function module.GetState(character, stateKey)
	if states[character] then
		return states[character][stateKey]
	end

	return nil
end

function module.SetState(character, stateKey, value, duration)
	if not states[character] then
		states[character] = {}
	end

	states[character][stateKey] = value
    if character then
        character:SetAttribute(stateKey, value)
    end

    if duration and type(duration) == "number" then
        task.delay(duration, function()
            if states[character] then
                states[character][stateKey] = nil

                if character then
                    character:SetAttribute(stateKey, nil)
                end

                if next(states[character]) == nil then
                    states[character] = nil
                end
            end
        end)
    end
end

function module.SetStun(character, value, duration, stunSpeed)
    if not character or not character:FindFirstChild("Humanoid") then return end

    local humanoid = character.Humanoid

    if not states[character] then
        states[character] = {}
    end

    if value then
        states[character]["Stunned"] = true
        character:SetAttribute("Stunned", true)

        if not states[character].OriginalWalkSpeed then
            states[character].OriginalWalkSpeed = humanoid.WalkSpeed
        end

        humanoid.WalkSpeed = stunSpeed or 0

        local endTime = time() + duration

        if stunTimers[character] then
            stunTimers[character].EndTime = math.max(stunTimers[character].EndTime, endTime)
        else
            stunTimers[character] = { EndTime = endTime }

            coroutine.wrap(function()
                while stunTimers[character] and time() < stunTimers[character].EndTime do
                    task.wait(0.1)
                end

                if states[character] then
                    states[character]["Stunned"] = nil
                    character:SetAttribute("Stunned", nil)

                    if character:FindFirstChild("Humanoid") then
                        local h = character.Humanoid
                        h.WalkSpeed = states[character].OriginalWalkSpeed or 16
                    end

                    states[character].OriginalWalkSpeed = nil

                    if next(states[character]) == nil then
                        states[character] = nil
                    end
                end

                stunTimers[character] = nil
            end)()
        end
    else
        states[character]["Stunned"] = nil
        character:SetAttribute("Stunned", nil)

        if character:FindFirstChild("Humanoid") then
            local h = character.Humanoid
            h.WalkSpeed = states[character].OriginalWalkSpeed or 16
        end

        states[character].OriginalWalkSpeed = nil
        stunTimers[character] = nil

        if next(states[character]) == nil then
            states[character] = nil
        end
    end
end

function module.RemoveStates(character, stateKey)
    if not states[character] then return end

    if stateKey then
        states[character][stateKey] = nil
        
        if character then
            character:SetAttribute(stateKey, nil)
        end

        if next(states[character]) == nil then
            states[character] = nil
        end
    else
        for key in pairs(states[character]) do
            if character then
                character:SetAttribute(key, nil)
            end
        end
        states[character] = nil
    end
end

function module.ClearAllStates()
    for character in pairs(states) do
        for key in pairs(states[character]) do
            if character then
                character:SetAttribute(key, nil)
            end
        end
        states[character] = nil
    end
    for character in pairs(stunTimers) do
        stunTimers[character] = nil
    end
end

game.Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        for key in pairs(states[player.Character] or {}) do
            player.Character:SetAttribute(key, nil)
        end

        states[player.Character] = nil
        stunTimers[player.Character] = nil
    end
end)

return module
