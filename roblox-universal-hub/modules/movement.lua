local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Utils = require(script.Parent.Parent.core.utils)

local Movement = {}

function Movement.EnableSprint(sprintSpeed, normalSpeed)
    local player = Players.LocalPlayer
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.LeftShift then
            local hum = Utils.GetHumanoid(player)
            if hum then hum.WalkSpeed = sprintSpeed end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftShift then
            local hum = Utils.GetHumanoid(player)
            if hum then hum.WalkSpeed = normalSpeed end
        end
    end)
end

return Movement