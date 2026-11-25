local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local CombatHelper = {}
CombatHelper.FOVRadius = 120
CombatHelper.PredictionTime = 0.05

-- 1. ตรวจจับสิ่งกีดขวาง (Line-of-Sight / Wall Check) ระหว่าง originPos กับ targetPart
function CombatHelper.HasLineOfSight(originPos, targetPart, ignoreList)
if not originPos or not targetPart then return false end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local exclude = { LocalPlayer.Character, targetPart.Parent }
if ignoreList then
for _, item in ipairs(ignoreList) do
table.insert(exclude, item)
end
end
params.FilterDescendantsInstances = exclude

local direction = targetPart.Position - originPos
local result = workspace:Raycast(originPos, direction, params)
return result == nil
end

-- 2. คำนวณจุดดักหน้าเป้าหมายที่กำลังเคลื่อนที่ (Velocity Prediction)
function CombatHelper.PredictPosition(targetPart, leadTime)
if not targetPart then return nil end
local t = leadTime or CombatHelper.PredictionTime
local velocity = targetPart.AssemblyLinearVelocity or Vector3.zero
return targetPart.Position + (velocity * t)
end

-- 3. สร้างวงแหวน FOV / เป้าเล็งบน ScreenGui สำหรับแสดงขอบเขตบนหน้าจอ
function CombatHelper.CreateFOVCircle(parentGui, radius)
local r = radius or CombatHelper.FOVRadius
local existing = parentGui:FindFirstChild("FOVCircleRing")
if existing then existing:Destroy() end

local ring = Instance.new("Frame")
ring.Name = "FOVCircleRing"
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.new(0.5, 0, 0.5, 0)
ring.Size = UDim2.new(0, r * 2, 0, r * 2)
ring.BackgroundTransparency = 1
ring.Visible = false
ring.ZIndex = 15
ring.Parent = parentGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = ring

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 70, 90)
stroke.Thickness = 1.6
stroke.Transparency = 0.25
stroke.Parent = ring

return ring
end

function CombatHelper.SetFOVRadius(ring, radius)
CombatHelper.FOVRadius = radius
if ring and ring.Parent then
ring.Size = UDim2.new(0, radius * 2, 0, radius * 2)
end
end

return CombatHelper