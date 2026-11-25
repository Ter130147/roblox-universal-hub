local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local ADS = {}
ADS.DefaultFOV = 70
ADS.ZoomFOV = 45
ADS.DefaultSensitivity = 1
ADS.ZoomSensitivity = 0.45
ADS.TweenTime = 0.18

local currentTween = nil

local function setZoom(isZooming)
if currentTween then
currentTween:Cancel()
end

local targetFOV = isZooming and ADS.ZoomFOV or ADS.DefaultFOV
UserInputService.MouseDeltaSensitivity = isZooming and ADS.ZoomSensitivity or ADS.DefaultSensitivity

local info = TweenInfo.new(ADS.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
currentTween = TweenService:Create(Camera, info, { FieldOfView = targetFOV })
currentTween:Play()
end

function ADS.BindHoldRightClick()
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end
if input.UserInputType == Enum.UserInputType.MouseButton2 then
setZoom(true)
end
end)

UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton2 then
setZoom(false)
end
end)
end

return ADS