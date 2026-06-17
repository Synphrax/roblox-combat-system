local module = {}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

module.Anims = {}

local function getAnimator(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn(`No Humanoid found for animation on "{character.Name}"`)
        return nil
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator", humanoid)
        animator.Name = "Animator"
    end

    return animator
end

function module.LoadAnim(character, _type, animId, keyframeCallback, isLooped, priority)
    if not character or not _type or not animId then return end

    local animator = getAnimator(character)
    if not animator then return end

	local animation = Instance.new("Animation")
	animation.AnimationId = animId
    
	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not success then
		warn(`Failed to load animation "{animId}": {track}`)
		animation:Destroy()
		return
	end

	track.Priority = priority or Enum.AnimationPriority.Action
	track.Looped = isLooped == true

	module.Anims[character] = module.Anims[character] or {}
    module.Anims[character][_type] = module.Anims[character][_type] or {}

    local connections = {}

    if keyframeCallback then
        table.insert(connections, track.KeyframeReached:Connect(function(markerName)
            keyframeCallback(markerName)
        end))   
    end

    table.insert(connections, track.Stopped:Connect(function()
        module.RemoveAnim(character, _type, animId)
    end))

    module.Anims[character][_type][animId] = {
        Track = track,
        Connections = connections
    }

	track:Play()
	animation:Destroy()

    if not isLooped then
        Debris:AddItem(track, track.Length + 1)
    end
end

function module.GetAnims(character, animType)
    if not module.Anims[character] then return {} end

    if animType then
        return module.Anims[character][animType] or {}
    end

    return module.Anims[character]
end

function module.IsAnim(character, _type, animId)
    local entry = module.Anims[character] and module.Anims[character][_type] and module.Anims[character][_type][animId]
    return entry and entry.Track and entry.Track.IsPlaying or false
end

function module.RemoveAnim(character, _type, animId)
    local animData = module.Anims[character] and module.Anims[character][_type] and module.Anims[character][_type][animId]

    if animData then
        if animData.Track then
            animData.Track:Stop()
            animData.Track:Destroy()
        end

        if animData.Connections then
            for _, conn in ipairs(animData.Connections) do
                if conn.Connected then
                    conn:Disconnect()
                end
            end
        end

        module.Anims[character][_type][animId] = nil

        -- Cleanup empty tables
        if next(module.Anims[character][_type]) == nil then
            module.Anims[character][_type] = nil
        end
        if next(module.Anims[character]) == nil then
            module.Anims[character] = nil
        end
    end
end

function module.StopAnim(character, _type, animId)
    if not module.Anims[character] then return end

    if _type == "ALL" then
        for typeKey, anims in pairs(module.Anims[character]) do
            for id in pairs(anims) do
                module.RemoveAnim(character, typeKey, id)
            end
        end
    else
        if animId then
            module.RemoveAnim(character, _type, animId)
        else
            for id in pairs(module.Anims[character][_type] or {}) do
                module.RemoveAnim(character, _type, id)
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    local character = player.Character or player:FindFirstChild("Character")

    if module.Anims[character] then
        module.StopAnim(character, "ALL")
        module.Anims[character] = nil
    end
end)

local preloaded = {}

function module.PreloadAnimations(character, animList)
    local animator = getAnimator(character)
    if not animator then return end

    for _, animId in ipairs(animList) do
        if not preloaded[animId] then
            local animation = Instance.new("Animation")
            animation.AnimationId = animId

            game:GetService("ContentProvider"):PreloadAsync({ animation })

            local track = animator:LoadAnimation(animation)
            track:AdjustSpeed(0)
            track:Play()
            track:Stop()

            animation:Destroy()
            preloaded[animId] = true
        end
    end
end

local AnimationIdsToPreload = {
    -- M1 Hit: right,left & final (left uppercut)
    "rbxassetid://126033672292873",--[[0.52 Contact]] "rbxassetid://73763577846518",--[[0.4 Contact]] "rbxassetid://99128033964453",--[[0.5 Contact]]

    -- M2
    "rbxassetid://136321404367319",--[[0.42 Contact]]

    -- Block, Blocked hit, Block break
    "rbxassetid://98547343672589", "rbxassetid://119835869255663",

    -- Knockback (right shoulder, left shoulder)
    "rbxassetid://79341608180382", "rbxassetid://104415609575637"
}

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid")
        task.wait(0.1)
        module.PreloadAnimations(character, AnimationIdsToPreload)
    end)

    player.CharacterRemoving:Connect(function(oldCharacter)
        -- Clean animations for old chatacter when player resets
        if module.Anims[oldCharacter] then
            module.StopAnim(oldCharacter, "ALL")
            module.Anims[oldCharacter] = nil
        end
    end)
end)

return module
