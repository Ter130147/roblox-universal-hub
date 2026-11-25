local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local Hub = {}
Hub.NametagsEnabled = true
Hub.RedOutlineEnabled = true
Hub.LockOnEnabled = false
Hub.CurrentTarget = nil
Hub.TrackedModels = {}
Hub.ActiveGuis = {}
Hub.ActiveHighlights = {}
Hub.MaxLockDistance = 160
Hub.LockSmoothness = 0.24
Hub.FOVRadius = 120

local function isOwnCharacter(model)
if not model then return true end
if LocalPlayer.Character and (model == LocalPlayer.Character or model:IsDescendantOf(LocalPlayer.Character)) then
return true
end
if model.Name == LocalPlayer.Name then
return true
end
return false
end

local function isIgnoredContainer(model)
if not model then return true end
local full = model:GetFullName()
if string.find(full, "Workspace%.Camera") then return true end
if string.find(full, "Workspace%._Temp") then return true end
if string.find(full, "HighlightHolder") then return true end
return false
end

local function getPlayerFromModel(model)
local plr = Players:GetPlayerFromCharacter(model)
if plr then return plr end
for _, p in ipairs(Players:GetPlayers()) do
if p.Name == model.Name then
return p
end
end
return nil
end

local function isTeammate(player)
if not player or player == LocalPlayer then return false end
if LocalPlayer.Team ~= nil and player.Team ~= nil then
return player.Team == LocalPlayer.Team
end
if not LocalPlayer.Neutral and not player.Neutral then
return player.TeamColor == LocalPlayer.TeamColor
end
return false
end

local function getTagColor(player)
if isTeammate(player) then
return Color3.fromRGB(60, 255, 110)
else
return Color3.fromRGB(255, 65, 65)
end
end

local function attachVisualsToModel(model)
if not model or not model:IsA("Model") then return end
if isOwnCharacter(model) or isIgnoredContainer(model) then return end

local hum = model:FindFirstChildOfClass("Humanoid")
local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
if not hum or not head then return end

local plr = getPlayerFromModel(model)
local friendly = isTeammate(plr)

-- 1. โครงสีแดงเห็นทั้งตัว (Highlight) สำหรับฝ่ายตรงข้าม/ศัตรู
local existingHl = Hub.ActiveHighlights[model]
if friendly then
if existingHl and existingHl.Parent then existingHl:Destroy() end
Hub.ActiveHighlights[model] = nil
else
if not existingHl or not existingHl.Parent then
local oldHl = model:FindFirstChild("EnemyRedOutline")
if oldHl then oldHl:Destroy() end

local hl = Instance.new("Highlight")
hl.Name = "EnemyRedOutline"
hl.Adornee = model
hl.FillColor = Color3.fromRGB(255, 30, 30)
hl.FillTransparency = 0.68
hl.OutlineColor = Color3.fromRGB(255, 80, 80)
hl.OutlineTransparency = 0
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hl.Parent = model
Hub.ActiveHighlights[model] = hl
existingHl = hl
end
existingHl.Adornee = model
existingHl.Enabled = Hub.RedOutlineEnabled
end

-- 2. ป้ายชื่อเหนือตัวละครแยกสี (ทีมเขียว / ศัตรูแดง)
local existingGui = Hub.ActiveGuis[model]
if not existingGui or not existingGui.Parent then
local oldTag = head:FindFirstChild("MapNametag")
if oldTag then oldTag:Destroy() end

local billboard = Instance.new("BillboardGui")
billboard.Name = "MapNametag"
billboard.Adornee = head
billboard.Size = UDim2.new(0, 175, 0, 36)
billboard.StudsOffset = Vector3.new(0, 2.6, 0)
billboard.AlwaysOnTop = true
billboard.MaxDistance = 2500
billboard.Parent = head

local label = Instance.new("TextLabel")
label.Name = "PlayerName"
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = plr and (plr.DisplayName .. " (@" .. plr.Name .. ")") or model.Name
label.TextStrokeTransparency = 0.1
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.Parent = billboard

Hub.ActiveGuis[model] = billboard
existingGui = billboard
end

existingGui.Adornee = head
existingGui.Enabled = Hub.NametagsEnabled
local lbl = existingGui:FindFirstChild("PlayerName")
if lbl then
lbl.TextColor3 = getTagColor(plr)
end

Hub.TrackedModels[model] = true
end

local function scanAndRefreshAll()
for model, gui in pairs(Hub.ActiveGuis) do
if not model or not model.Parent or not gui or not gui.Parent then
if gui and gui.Parent then gui:Destroy() end
Hub.ActiveGuis[model] = nil
local hl = Hub.ActiveHighlights[model]
if hl and hl.Parent then hl:Destroy() end
Hub.ActiveHighlights[model] = nil
Hub.TrackedModels[model] = nil
end
end

for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and plr.Character then
attachVisualsToModel(plr.Character)
end
end

local worldFolder = workspace:FindFirstChild("World")
if worldFolder then
for _, desc in ipairs(worldFolder:GetDescendants()) do
if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then
attachVisualsToModel(desc.Parent)
end
end
end
end

function Hub.SetRedOutline(state)
Hub.RedOutlineEnabled = state == true
scanAndRefreshAll()
end

function Hub.SetNametags(state)
Hub.NametagsEnabled = state == true
scanAndRefreshAll()
end

task.spawn(function()
while true do
scanAndRefreshAll()
task.wait(1)
end
end)

-- ระบบล็อกเป้า
local lockConn = nil
local lockToggleController = nil

local function getNearestTarget()
local char = LocalPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
if not root then return nil end

local nearestPart = nil
local shortestDist = Hub.MaxLockDistance

for model, _ in pairs(Hub.TrackedModels) do
if model and model.Parent and not isOwnCharacter(model) and not isIgnoredContainer(model) then
local plr = getPlayerFromModel(model)
if not isTeammate(plr) then
local hum = model:FindFirstChildOfClass("Humanoid")
local aimPart = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
if hum and hum.Health > 0 and aimPart then
local dist = (aimPart.Position - root.Position).Magnitude
if dist < shortestDist then
shortestDist = dist
nearestPart = aimPart
end
end
end
end
end

return nearestPart
end

function Hub.SetLockOn(state)
Hub.LockOnEnabled = state == true
if Hub.LockOnEnabled then
Hub.CurrentTarget = getNearestTarget()
if not Hub.CurrentTarget then
Hub.LockOnEnabled = false
if lockToggleController then lockToggleController.SetSilent(false) end
return
end
if lockConn then lockConn:Disconnect() end
lockConn = RunService.RenderStepped:Connect(function()
local target = Hub.CurrentTarget
local targetHum = target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
if not target or not target.Parent or not targetHum or targetHum.Health <= 0 then
Hub.SetLockOn(false)
if lockToggleController then lockToggleController.SetSilent(false) end
return
end
local camPos = Camera.CFrame.Position
local lookCFrame = CFrame.lookAt(camPos, target.Position)
Camera.CFrame = Camera.CFrame:Lerp(lookCFrame, Hub.LockSmoothness)
end)
else
Hub.CurrentTarget = nil
if lockConn then
lockConn:Disconnect()
lockConn = nil
end
end
end

-- UI 3D Dark Red + ปุ่มเปิด/ปิด/ซ่อน UI + ปลดล็อกเมาส์ขณะเปิดหน้าต่าง
local function makeDraggable(dragHandle, targetFrame)
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

dragHandle.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = targetFrame.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
dragging = false
end
end)
end
end)

dragHandle.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)

UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
targetFrame.Position = UDim2.new(
startPos.X.Scale,
startPos.X.Offset + delta.X,
startPos.Y.Scale,
startPos.Y.Offset + delta.Y
)
end
end)
end

local function applySweepEffect(parentFrame)
local sweep = Instance.new("Frame")
sweep.Name = "SweepGlow"
sweep.Size = UDim2.new(0.35, 0, 1.8, 0)
sweep.Position = UDim2.new(-0.5, 0, -0.4, 0)
sweep.Rotation = 22
sweep.BackgroundColor3 = Color3.fromRGB(255, 110, 110)
sweep.BackgroundTransparency = 0.72
sweep.BorderSizePixel = 0
sweep.Active = false
sweep.ZIndex = parentFrame.ZIndex + 1
sweep.Parent = parentFrame

local grad = Instance.new("UIGradient")
grad.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.5, 0.25),
NumberSequenceKeypoint.new(1, 1),
})
grad.Parent = sweep

task.spawn(function()
while sweep and sweep.Parent do
sweep.Position = UDim2.new(-0.5, 0, -0.4, 0)
local tween = TweenService:Create(
sweep,
TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
{ Position = UDim2.new(1.3, 0, -0.4, 0) }
)
tween:Play()
tween.Completed:Wait()
task.wait(1.6)
end
end)
end

local oldGui = PlayerGui:FindFirstChild("Universal3DRedHub")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Universal3DRedHub"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local fovRing = Instance.new("Frame")
fovRing.Name = "FOVCircleRing"
fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
fovRing.Position = UDim2.new(0.5, 0, 0.5, 0)
fovRing.Size = UDim2.new(0, Hub.FOVRadius * 2, 0, Hub.FOVRadius * 2)
fovRing.BackgroundTransparency = 1
fovRing.Active = false
fovRing.Visible = false
fovRing.ZIndex = 15
fovRing.Parent = screenGui
Instance.new("UICorner", fovRing).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovRing)
fovStroke.Color = Color3.fromRGB(255, 70, 90)
fovStroke.Thickness = 1.6
fovStroke.Transparency = 0.25

-- ปุ่มเปิด/ปิด/ซ่อน UI ด้านบนซ้าย (กดได้ทันที)
local toggleUiBtn = Instance.new("TextButton")
toggleUiBtn.Name = "ToggleMenuButton"
toggleUiBtn.Size = UDim2.new(0, 110, 0, 36)
toggleUiBtn.Position = UDim2.new(0, 24, 0.5, -78)
toggleUiBtn.BackgroundColor3 = Color3.fromRGB(130, 16, 24)
toggleUiBtn.Text = "ซ่อน UI"
toggleUiBtn.TextColor3 = Color3.fromRGB(255, 240, 240)
toggleUiBtn.Font = Enum.Font.GothamBlack
toggleUiBtn.TextSize = 14
toggleUiBtn.Active = true
toggleUiBtn.AutoButtonColor = false
toggleUiBtn.ZIndex = 40
toggleUiBtn.Parent = screenGui
Instance.new("UICorner", toggleUiBtn).CornerRadius = UDim.new(0, 10)
local toggleUiStroke = Instance.new("UIStroke", toggleUiBtn)
toggleUiStroke.Color = Color3.fromRGB(255, 75, 75)
toggleUiStroke.Thickness = 1.8

local miniBtn = Instance.new("TextButton")
miniBtn.Name = "MiniToggle3D"
miniBtn.Size = UDim2.new(0, 62, 0, 62)
miniBtn.Position = UDim2.new(0, 24, 0.5, -31)
miniBtn.BackgroundColor3 = Color3.fromRGB(95, 12, 18)
miniBtn.Text = "TER"
miniBtn.TextColor3 = Color3.fromRGB(255, 235, 235)
miniBtn.Font = Enum.Font.GothamBlack
miniBtn.TextSize = 18
miniBtn.Active = true
miniBtn.AutoButtonColor = false
miniBtn.ZIndex = 30
miniBtn.Parent = screenGui

Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 14)
local miniStroke = Instance.new("UIStroke", miniBtn)
miniStroke.Color = Color3.fromRGB(255, 65, 65)
miniStroke.Thickness = 2

local miniGrad = Instance.new("UIGradient", miniBtn)
miniGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 20, 30)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 5, 10)),
})
miniGrad.Rotation = 135
applySweepEffect(miniBtn)

local shadowFrame = Instance.new("Frame")
shadowFrame.Name = "MainShadow3D"
shadowFrame.Size = UDim2.new(0, 340, 0, 345)
shadowFrame.Position = UDim2.new(0.5, -164, 0.5, -165)
shadowFrame.BackgroundColor3 = Color3.fromRGB(22, 3, 6)
shadowFrame.BorderSizePixel = 0
shadowFrame.Active = false
shadowFrame.ZIndex = 4
shadowFrame.Parent = screenGui
Instance.new("UICorner", shadowFrame).CornerRadius = UDim.new(0, 16)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel3D"
mainFrame.Size = UDim2.new(0, 340, 0, 345)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -172)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 10, 14)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.ZIndex = 6
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(190, 30, 45)
mainStroke.Thickness = 2

local mainGrad = Instance.new("UIGradient", mainFrame)
mainGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 10, 16)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 9, 13)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 5, 8)),
})
mainGrad.Rotation = 145

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(110, 14, 22)
header.BorderSizePixel = 0
header.ClipsDescendants = true
header.Active = true
header.ZIndex = 8
header.Parent = mainFrame

local headerGrad = Instance.new("UIGradient", header)
headerGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 20, 32)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 8, 14)),
})
headerGrad.Rotation = 90
applySweepEffect(header)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Active = false
titleLabel.Text = "UNIVERSAL 3D HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 240, 240)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 16
titleLabel.ZIndex = 12
titleLabel.Parent = header

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 56, 0, 28)
hideBtn.Position = UDim2.new(1, -68, 0.5, -14)
hideBtn.BackgroundColor3 = Color3.fromRGB(45, 7, 11)
hideBtn.Text = "ซ่อน"
hideBtn.TextColor3 = Color3.fromRGB(255, 190, 190)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 12
hideBtn.Active = true
hideBtn.ZIndex = 15
hideBtn.Parent = header
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 8)
local hideStroke = Instance.new("UIStroke", hideBtn)
hideStroke.Color = Color3.fromRGB(220, 50, 65)
hideStroke.Thickness = 1.2

local listHolder = Instance.new("ScrollingFrame")
listHolder.Name = "FunctionList"
listHolder.Size = UDim2.new(1, -24, 1, -64)
listHolder.Position = UDim2.new(0, 12, 0, 56)
listHolder.BackgroundTransparency = 1
listHolder.ScrollBarThickness = 4
listHolder.ScrollBarImageColor3 = Color3.fromRGB(210, 35, 50)
listHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
listHolder.Active = true
listHolder.ZIndex = 8
listHolder.Parent = mainFrame

local layout = Instance.new("UIListLayout", listHolder)
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
listHolder.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end)

mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
shadowFrame.Position = UDim2.new(
mainFrame.Position.X.Scale,
mainFrame.Position.X.Offset + 6,
mainFrame.Position.Y.Scale,
mainFrame.Position.Y.Offset + 8
)
end)

local function setPanelVisible(visible)
mainFrame.Visible = visible
shadowFrame.Visible = visible
toggleUiBtn.Text = visible and "ซ่อน UI" or "เปิด UI"
if visible then
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true
end
end

-- ปลดล็อกเคอร์เซอร์เมาส์ตลอดเวลาที่เมนูเปิดอยู่ เพื่อให้ชี้กดปุ่มได้จริงในเกม FPS
RunService.RenderStepped:Connect(function()
if mainFrame.Visible then
if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end
UserInputService.MouseIconEnabled = true
end
end)

hideBtn.MouseButton1Click:Connect(function()
setPanelVisible(false)
end)

toggleUiBtn.MouseButton1Click:Connect(function()
setPanelVisible(not mainFrame.Visible)
end)

miniBtn.MouseButton1Click:Connect(function()
setPanelVisible(not mainFrame.Visible)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
setPanelVisible(not mainFrame.Visible)
elseif not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
local nextState = not Hub.LockOnEnabled
Hub.SetLockOn(nextState)
if lockToggleController then
lockToggleController.SetSilent(Hub.LockOnEnabled)
end
end
end)

makeDraggable(header, mainFrame)
makeDraggable(miniBtn, miniBtn)
makeDraggable(toggleUiBtn, toggleUiBtn)

local function addToggle(labelText, defaultState, callback)
local state = defaultState == true

local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 48)
row.BackgroundColor3 = Color3.fromRGB(38, 12, 18)
row.BorderSizePixel = 0
row.Active = false
row.ZIndex = 9
row.Parent = listHolder
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
local rowStroke = Instance.new("UIStroke", row)
rowStroke.Color = Color3.fromRGB(120, 22, 32)
rowStroke.Thickness = 1.4

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -86, 1, 0)
label.Position = UDim2.new(0, 14, 0, 0)
label.BackgroundTransparency = 1
label.Active = false
label.Text = labelText
label.TextColor3 = Color3.fromRGB(245, 235, 235)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.ZIndex = 10
label.Parent = row

local switchBtn = Instance.new("TextButton")
switchBtn.Size = UDim2.new(0, 62, 0, 30)
switchBtn.Position = UDim2.new(1, -74, 0.5, -15)
switchBtn.BackgroundColor3 = state and Color3.fromRGB(210, 28, 42) or Color3.fromRGB(55, 22, 28)
switchBtn.Text = state and "ON" or "OFF"
switchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
switchBtn.Font = Enum.Font.GothamBlack
switchBtn.TextSize = 12
switchBtn.Active = true
switchBtn.AutoButtonColor = false
switchBtn.ZIndex = 20
switchBtn.Parent = row
Instance.new("UICorner", switchBtn).CornerRadius = UDim.new(0, 8)
local switchStroke = Instance.new("UIStroke", switchBtn)
switchStroke.Color = state and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(110, 45, 55)
switchStroke.Thickness = 1.5

local function refreshVisual(animated)
local targetColor = state and Color3.fromRGB(210, 28, 42) or Color3.fromRGB(55, 22, 28)
local targetBorder = state and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(110, 45, 55)
switchBtn.Text = state and "ON" or "OFF"
if animated then
TweenService:Create(switchBtn, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { BackgroundColor3 = targetColor }):Play()
TweenService:Create(switchStroke, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Color = targetBorder }):Play()
else
switchBtn.BackgroundColor3 = targetColor
switchStroke.Color = targetBorder
end
end

switchBtn.MouseButton1Click:Connect(function()
state = not state
refreshVisual(true)
if callback then callback(state) end
end)

refreshVisual(false)
if state and callback then
task.spawn(callback, true)
end

return {
SetSilent = function(newState)
state = newState == true
refreshVisual(true)
end,
}
end

addToggle("โครงศัตรูสีแดง (Red Outline)", true, function(enabled)
Hub.SetRedOutline(enabled)
end)

addToggle("ชื่อทั้งแมพ (ทีมเขียว / ศัตรูแดง)", true, function(enabled)
Hub.SetNametags(enabled)
end)

lockToggleController = addToggle("ล็อกเป้า (คลิกขวา / ปุ่มนี้)", false, function(enabled)
Hub.SetLockOn(enabled)
end)

addToggle("แสดงวงเล็ง FOV Ring", false, function(enabled)
fovRing.Visible = enabled
end)