local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local LockOn = {}
LockOn.Enabled = false
LockOn.CurrentTarget = nil
LockOn.MaxDistance = 80
LockOn.Smoothness = 0.2
LockOn.TargetFolderName = "Enemies" -- ชื่อโฟลเดอร์เก็บ NPC/ศัตรูใน Workspace ของแมพคุณ

local renderConn = nil

local function getNearestEnemy()
local char = LocalPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
if not root then return nil end

local enemiesFolder = workspace:FindFirstChild(LockOn.TargetFolderName)
if not enemiesFolder then return nil end

local nearestRoot = nil
local shortestDist = LockOn.MaxDistance

for _, npc in ipairs(enemiesFolder:GetChildren()) do
local hum = npc:FindFirstChildOfClass("Humanoid")
local npcRoot = npc:FindFirstChild("HumanoidRootPart")
if hum and hum.Health > 0 and npcRoot then
local dist = (npcRoot.Position - root.Position).Magnitude
if dist < shortestDist then
shortestDist = dist
nearestRoot = npcRoot
end
end
end

return nearestRoot
end

function LockOn.SetActive(state)
LockOn.Enabled = state
if state then
LockOn.CurrentTarget = getNearestEnemy()
if not LockOn.CurrentTarget then
LockOn.Enabled = false
return
end

if renderConn then renderConn:Disconnect() end
renderConn = RunService.RenderStepped:Connect(function()
local target = LockOn.CurrentTarget
local targetHum = target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
if not target or not target.Parent or not targetHum or targetHum.Health <= 0 then
LockOn.SetActive(false)
return
end

local camPos = Camera.CFrame.Position
local lookCFrame = CFrame.lookAt(camPos, target.Position)
Camera.CFrame = Camera.CFrame:Lerp(lookCFrame, LockOn.Smoothness)
end)
else
LockOn.CurrentTarget = nil
if renderConn then
renderConn:Disconnect()
renderConn = nil
end
end
end

function LockOn.BindRightClick()
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end
if input.UserInputType == Enum.UserInputType.MouseButton2 then
LockOn.SetActive(not LockOn.Enabled)
end
end)
end

return LockOn