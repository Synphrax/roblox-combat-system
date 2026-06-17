game.Players.PlayerAdded:Connect(function(player)
    local playerCombatSet = Instance.new("StringValue", player)
    playerCombatSet.Name = "playerCombatType"
    playerCombatSet.Value = "Base"

    local playerSkillSet = Instance.new("StringValue", player)
    playerSkillSet.Name = "playerSkillSet"
    playerSkillSet.Value = "Temp1"
end)