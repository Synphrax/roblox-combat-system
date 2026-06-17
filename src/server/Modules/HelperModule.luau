local module = {}

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local RP = game:GetService("ReplicatedStorage")

local StateHandler = require(RP.Modules.StateHandler)

local originalSpeeds = {}

local function cleanupCharacter(character)
	originalSpeeds[character] = nil
end

local function onCharacterRemoving(character)
	cleanupCharacter(character)
end

local function onPlayerRemoving(player)
	if player.Character then
		cleanupCharacter(player.Character)
	end
	originalSpeeds[player] = nil
end

function module.SetSpeed(character, speed, optionalPrevSpeed)
	if not character then return warn("No character.") end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then warn("No humanoid.") return end

	if not originalSpeeds[character] then
		originalSpeeds[character] = optionalPrevSpeed or humanoid.WalkSpeed
	end

	humanoid.WalkSpeed = speed

	if not character.AncestryChanged or not character:GetAttribute("SpeedCleanupConnected") then
		character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				onCharacterRemoving(character)
			end
		end)
		character:SetAttribute("SpeedCleanupConnected", true)
	end
end

function module.ResetSpeed(character)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- TODO: Check states here before resetting

	if originalSpeeds[character] then
		humanoid.WalkSpeed = 16
		originalSpeeds[character] = nil
	end
end

function module.ApplyKnockback(character, direction, strength, duration)
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	direction = direction.Unit
	local velocity = direction * strength

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.Velocity = velocity
	bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVel.P = 10000
	bodyVel.Name = "KnockbackForce"
	bodyVel.Parent = root

	game:GetService("Debris"):AddItem(bodyVel, duration or 0.2)
end

function module.RemoveHitboxesByNameForCharacter(character, attackName)
	local hitboxesFolder = workspace:FindFirstChild("Hitboxes")
	if not hitboxesFolder then return end

	local characterName = character.Name

	for _, hitbox in pairs(hitboxesFolder:GetChildren()) do
		if hitbox:IsA("BasePart") and hitbox:FindFirstChild("AttackName") and hitbox:FindFirstChild("Owner") then
			if hitbox.AttackName.Value == attackName and hitbox.Owner.Value == characterName then
				hitbox:Destroy()
			end
		end
	end
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

return module
