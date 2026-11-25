local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UI = {}
UI.Toggles = {}

-- ช่วยทำ Frame ให้ลากย้ายได้ทั้งเมาส์และทัชสกรีน
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

-- เอฟเฟกต์แสงกวาดผ่านปุ่ม/แถบ (Sweep Effect) แบบไม่พัง
local function applySweepEffect(parentFrame)
local sweep = Instance.new("Frame")
sweep.Name = "SweepGlow"
sweep.Size = UDim2.new(0.35, 0, 1.8, 0)
sweep.Position = UDim2.new(-0.5, 0, -0.4, 0)
sweep.Rotation = 22
sweep.BackgroundColor3 = Color3.fromRGB(255, 110, 110)
sweep.BackgroundTransparency = 0.72
sweep.BorderSizePixel = 0
sweep.ZIndex = parentFrame.ZIndex + 5
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

function UI.Create(titleText)
local oldGui = PlayerGui:FindFirstChild("Universal3DRedHub")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Universal3DRedHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- ปุ่มย่อ/เปิด UI แบบลอย 3D สีแดงเข้ม
local miniBtn = Instance.new("TextButton")
miniBtn.Name = "MiniToggle3D"
miniBtn.Size = UDim2.new(0, 62, 0, 62)
miniBtn.Position = UDim2.new(0, 24, 0.5, -31)
miniBtn.BackgroundColor3 = Color3.fromRGB(95, 12, 18)
miniBtn.Text = "TER"
miniBtn.TextColor3 = Color3.fromRGB(255, 235, 235)
miniBtn.Font = Enum.Font.GothamBlack
miniBtn.TextSize = 18
miniBtn.AutoButtonColor = false
miniBtn.ZIndex = 20
miniBtn.Parent = screenGui

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 14)
miniCorner.Parent = miniBtn

local miniStroke = Instance.new("UIStroke")
miniStroke.Color = Color3.fromRGB(255, 65, 65)
miniStroke.Thickness = 2
miniStroke.Parent = miniBtn

local miniGrad = Instance.new("UIGradient")
miniGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 20, 30)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 5, 10)),
})
miniGrad.Rotation = 135
miniGrad.Parent = miniBtn

applySweepEffect(miniBtn)

-- เงาฐาน 3D ด้านหลังหน้าต่างหลัก
local shadowFrame = Instance.new("Frame")
shadowFrame.Name = "MainShadow3D"
shadowFrame.Size = UDim2.new(0, 330, 0, 340)
shadowFrame.Position = UDim2.new(0.5, -159, 0.5, -162)
shadowFrame.BackgroundColor3 = Color3.fromRGB(22, 3, 6)
shadowFrame.BorderSizePixel = 0
shadowFrame.ZIndex = 4
shadowFrame.Parent = screenGui

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 16)
shadowCorner.Parent = shadowFrame

-- หน้าต่างหลัก 3D Dark Red
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel3D"
mainFrame.Size = UDim2.new(0, 330, 0, 340)
mainFrame.Position = UDim2.new(0.5, -165, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 10, 14)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.ZIndex = 6
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(190, 30, 45)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 10, 16)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 9, 13)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 5, 8)),
})
mainGrad.Rotation = 145
mainGrad.Parent = mainFrame

-- แถบหัวข้อ (Drag Handle)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(110, 14, 22)
header.BorderSizePixel = 0
header.ClipsDescendants = true
header.ZIndex = 8
header.Parent = mainFrame

local headerGrad = Instance.new("UIGradient")
headerGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 20, 32)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 8, 14)),
})
headerGrad.Rotation = 90
headerGrad.Parent = header

applySweepEffect(header)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = titleText or "UNIVERSAL 3D HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 240, 240)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 16
titleLabel.ZIndex = 10
titleLabel.Parent = header

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 56, 0, 28)
hideBtn.Position = UDim2.new(1, -68, 0.5, -14)
hideBtn.BackgroundColor3 = Color3.fromRGB(45, 7, 11)
hideBtn.Text = "ซ่อน"
hideBtn.TextColor3 = Color3.fromRGB(255, 190, 190)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 12
hideBtn.ZIndex = 10
hideBtn.Parent = header

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 8)
hideCorner.Parent = hideBtn

local hideStroke = Instance.new("UIStroke")
hideStroke.Color = Color3.fromRGB(220, 50, 65)
hideStroke.Thickness = 1.2
hideStroke.Parent = hideBtn

-- พื้นที่รายการปุ่มเปิด-ปิดแต่ละฟังก์ชัน
local listHolder = Instance.new("ScrollingFrame")
listHolder.Name = "FunctionList"
listHolder.Size = UDim2.new(1, -24, 1, -64)
listHolder.Position = UDim2.new(0, 12, 0, 56)
listHolder.BackgroundTransparency = 1
listHolder.ScrollBarThickness = 4
listHolder.ScrollBarImageColor3 = Color3.fromRGB(210, 35, 50)
listHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
listHolder.ZIndex = 8
listHolder.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = listHolder

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
listHolder.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
end)

-- ซิงก์ตำแหน่งเงา 3D ตามหน้าต่างหลัก
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
end

hideBtn.MouseButton1Click:Connect(function()
setPanelVisible(false)
end)

miniBtn.MouseButton1Click:Connect(function()
setPanelVisible(not mainFrame.Visible)
end)

makeDraggable(header, mainFrame)
makeDraggable(miniBtn, miniBtn)

-- ฟังก์ชันเพิ่มสวิตช์เปิด-ปิดแยกตามแต่ละฟังก์ชัน
function UI.AddToggle(labelText, defaultState, callback)
local state = defaultState == true

local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 48)
row.BackgroundColor3 = Color3.fromRGB(38, 12, 18)
row.BorderSizePixel = 0
row.ZIndex = 9
row.Parent = listHolder

local rowCorner = Instance.new("UICorner")
rowCorner.CornerRadius = UDim.new(0, 12)
rowCorner.Parent = row

local rowStroke = Instance.new("UIStroke")
rowStroke.Color = Color3.fromRGB(120, 22, 32)
rowStroke.Thickness = 1.4
rowStroke.Parent = row

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -86, 1, 0)
label.Position = UDim2.new(0, 14, 0, 0)
label.BackgroundTransparency = 1
label.Text = labelText
label.TextColor3 = Color3.fromRGB(245, 235, 235)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Font = Enum.Font.GothamBold
label.TextSize = 14
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
switchBtn.AutoButtonColor = false
switchBtn.ZIndex = 11
switchBtn.Parent = row

local switchCorner = Instance.new("UICorner")
switchCorner.CornerRadius = UDim.new(0, 8)
switchCorner.Parent = switchBtn

local switchStroke = Instance.new("UIStroke")
switchStroke.Color = state and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(110, 45, 55)
switchStroke.Thickness = 1.5
switchStroke.Parent = switchBtn

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
if callback then
callback(state)
end
end)

refreshVisual(false)
if state and callback then
task.spawn(callback, true)
end

UI.Toggles[labelText] = {
Set = function(newState)
state = newState == true
refreshVisual(true)
if callback then
callback(state)
end
end,
Get = function()
return state
end,
}

return UI.Toggles[labelText]
end

return UI
end

return UI