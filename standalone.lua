local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

if getgenv and getgenv().TerUniversalHubConnections then
for _, conn in ipairs(getgenv().TerUniversalHubConnections) do
pcall(function() conn:Disconnect() end)
end
end
local activeConnections = {}
if getgenv then
getgenv().TerUniversalHubConnections = activeConnections
end

local function trackConn(conn)
table.insert(activeConnections, conn)
return conn
end

local Hub = {}
Hub.NametagsEnabled = true
Hub.RedOutlineEnabled = true
Hub.ItemEspEnabled = false
Hub.FovOnlyLock = false
Hub.WallCheckEnabled = false
Hub.LockHolding = false
Hub.LockBind = "F"
Hub.AimPartMode = "Head"
Hub.TargetPriority = "Crosshair" -- "Crosshair" หรือ "Distance"
Hub.CurrentTarget = nil
Hub.TrackedModels = {}
Hub.ActiveGuis = {}
Hub.ActiveHighlights = {}
Hub.TrackedItems = {}
Hub.ActiveItemGuis = {}
Hub.MaxLockDistance = 160
Hub.MaxItemEspDistance = 120
Hub.LockSmoothness = 0.24
Hub.FOVRadius = 120

local CONFIG_FILE = "TerUniversalHub_Config.json"

local PlaceProfiles = {
[122446657157717] = {
WallCheckEnabled = true,
AimPartMode = "Head",
TargetPriority = "Crosshair",
MaxLockDistance = 200,
},
[126042865144779] = {
WallCheckEnabled = false,
AimPartMode = "Head",
TargetPriority = "Distance",
MaxLockDistance = 160,
},
}

local function applyPlaceDefaultProfile()
local profile = PlaceProfiles[game.PlaceId]
if not profile then return end
if type(profile.WallCheckEnabled) == "boolean" then Hub.WallCheckEnabled = profile.WallCheckEnabled end
if type(profile.AimPartMode) == "string" then Hub.AimPartMode = profile.AimPartMode end
if type(profile.TargetPriority) == "string" then Hub.TargetPriority = profile.TargetPriority end
if tonumber(profile.MaxLockDistance) then Hub.MaxLockDistance = tonumber(profile.MaxLockDistance) end
end

applyPlaceDefaultProfile()

local function canUseFileIo()
return typeof(writefile) == "function" and typeof(readfile) == "function"
end

local function saveConfig()
if not canUseFileIo() then return end
local payload = {
NametagsEnabled = Hub.NametagsEnabled,
RedOutlineEnabled = Hub.RedOutlineEnabled,
ItemEspEnabled = Hub.ItemEspEnabled,
FovOnlyLock = Hub.FovOnlyLock,
WallCheckEnabled = Hub.WallCheckEnabled,
LockBind = Hub.LockBind,
AimPartMode = Hub.AimPartMode,
TargetPriority = Hub.TargetPriority,
MaxLockDistance = Hub.MaxLockDistance,
MaxItemEspDistance = Hub.MaxItemEspDistance,
LockSmoothness = Hub.LockSmoothness,
FOVRadius = Hub.FOVRadius,
}
pcall(function()
writefile(CONFIG_FILE, HttpService:JSONEncode(payload))
end)
end

local function loadConfig()
if not canUseFileIo() then return end
if typeof(isfile) == "function" and not isfile(CONFIG_FILE) then return end
local ok, raw = pcall(readfile, CONFIG_FILE)
if not ok or not raw then return end
local decodedOk, data = pcall(function()
return HttpService:JSONDecode(raw)
end)
if not decodedOk or type(data) ~= "table" then return end

if type(data.NametagsEnabled) == "boolean" then Hub.NametagsEnabled = data.NametagsEnabled end
if type(data.RedOutlineEnabled) == "boolean" then Hub.RedOutlineEnabled = data.RedOutlineEnabled end
if type(data.ItemEspEnabled) == "boolean" then Hub.ItemEspEnabled = data.ItemEspEnabled end
if type(data.FovOnlyLock) == "boolean" then Hub.FovOnlyLock = data.FovOnlyLock end
if type(data.WallCheckEnabled) == "boolean" then Hub.WallCheckEnabled = data.WallCheckEnabled end
if type(data.LockBind) == "string" then Hub.LockBind = data.LockBind end
if type(data.AimPartMode) == "string" then Hub.AimPartMode = data.AimPartMode end
if type(data.TargetPriority) == "string" then Hub.TargetPriority = data.TargetPriority end
if tonumber(data.MaxLockDistance) then Hub.MaxLockDistance = tonumber(data.MaxLockDistance) end
if tonumber(data.MaxItemEspDistance) then Hub.MaxItemEspDistance = tonumber(data.MaxItemEspDistance) end
if tonumber(data.LockSmoothness) then Hub.LockSmoothness = tonumber(data.LockSmoothness) end
if tonumber(data.FOVRadius) then Hub.FOVRadius = math.clamp(tonumber(data.FOVRadius), 50, 400) end
end

loadConfig()

local LockKeyOptions = {
{ label = "ปุ่ม F", value = "F", keyCode = Enum.KeyCode.F, userInputType = Enum.UserInputType.Keyboard },
{ label = "คลิกขวา (RMB)", value = "RMB", keyCode = nil, userInputType = Enum.UserInputType.MouseButton2 },
{ label = "ปุ่ม E", value = "E", keyCode = Enum.KeyCode.E, userInputType = Enum.UserInputType.Keyboard },
{ label = "ปุ่ม Q", value = "Q", keyCode = Enum.KeyCode.Q, userInputType = Enum.UserInputType.Keyboard },
{ label = "ปุ่ม X", value = "X", keyCode = Enum.KeyCode.X, userInputType = Enum.UserInputType.Keyboard },
{ label = "ปุ่ม C", value = "C", keyCode = Enum.KeyCode.C, userInputType = Enum.UserInputType.Keyboard },
}

local AimPartOptions = {
{ label = "หัว (Head)", value = "Head" },
{ label = "ลำตัว (HRP)", value = "HumanoidRootPart" },
}

local PriorityOptions = {
{ label = "ใกล้เป้าเล็ง", value = "Crosshair" },
{ label = "ใกล้ตัวละคร", value = "Distance" },
}

local SmoothnessOptions = {
{ label = "นุ่ม (0.14)", value = 0.14 },
{ label = "กลาง (0.24)", value = 0.24 },
{ label = "ไว (0.45)", value = 0.45 },
{ label = "ตรง (1.00)", value = 1.00 },
}

local DistanceOptions = {
{ label = "100 Studs", value = 100 },
{ label = "160 Studs", value = 160 },
{ label = "250 Studs", value = 250 },
{ label = "400 Studs", value = 400 },
}

local ItemDistanceOptions = {
{ label = "50m", value = 50 },
{ label = "120m", value = 120 },
{ label = "300m", value = 300 },
}

local function findOptionLabel(options, value, fallback)
for _, opt in ipairs(options) do
if opt.value == value then
return opt.label
end
end
return fallback
end

local function getActiveBindConfig()
for _, opt in ipairs(LockKeyOptions) do
if opt.value == Hub.LockBind then
return opt
end
end
return LockKeyOptions[1]
end

local function isBindCurrentlyHeld()
local cfg = getActiveBindConfig()
if cfg.value == "RMB" then
return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
elseif cfg.keyCode then
return UserInputService:IsKeyDown(cfg.keyCode)
end
return false
end

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

local function isIgnoredContainer(instance)
if not instance then return true end
local full = instance:GetFullName()
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

local function getCustomTeamTag(instance)
if not instance then return nil end
local attrTeam = instance:GetAttribute("Team") or instance:GetAttribute("TeamName") or instance:GetAttribute("Faction")
if attrTeam ~= nil then return tostring(attrTeam) end
local parent = instance.Parent
while parent and parent ~= workspace do
local nameLower = string.lower(parent.Name)
if string.find(nameLower, "team") or string.find(nameLower, "red") or string.find(nameLower, "blue") or string.find(nameLower, "green") then
return parent.Name
end
parent = parent.Parent
end
return nil
end

local function isTeammate(player, model)
if not player or player == LocalPlayer then return false end

if #Teams:GetTeams() > 0 then
if LocalPlayer.Team ~= nil and player.Team ~= nil then
return player.Team == LocalPlayer.Team
end
if not LocalPlayer.Neutral and not player.Neutral then
return player.TeamColor == LocalPlayer.TeamColor
end
return false
end

local myTag = getCustomTeamTag(LocalPlayer.Character) or getCustomTeamTag(LocalPlayer)
local theirTag = getCustomTeamTag(model) or getCustomTeamTag(player)
if myTag and theirTag then
return myTag == theirTag
end

return false
end

local function getTagColor(player, model)
if isTeammate(player, model) then
return Color3.fromRGB(60, 255, 110)
else
return Color3.fromRGB(255, 65, 65)
end
end

local function cleanupModel(model)
local gui = Hub.ActiveGuis[model]
if gui and gui.Parent then gui:Destroy() end
Hub.ActiveGuis[model] = nil

local hl = Hub.ActiveHighlights[model]
if hl and hl.Parent then hl:Destroy() end
Hub.ActiveHighlights[model] = nil

Hub.TrackedModels[model] = nil
end

local function getItemDisplayPart(obj)
if not obj or not obj.Parent or isIgnoredContainer(obj) then return nil end
if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then return nil end
if obj:FindFirstChildOfClass("Humanoid") then return nil end

local hasInteract = obj:FindFirstChildOfClass("ClickDetector", true) ~= nil
or obj:FindFirstChildOfClass("ProximityPrompt", true) ~= nil
or obj:IsA("Tool")

local isItemFolder = false
local cur = obj.Parent
while cur and cur ~= workspace do
local n = string.lower(cur.Name)
if string.find(n, "item") or string.find(n, "drop") or string.find(n, "loot") or string.find(n, "pickup") or string.find(n, "weapon") or string.find(n, "gun") then
isItemFolder = true
break
end
cur = cur.Parent
end

if not hasInteract and not isItemFolder then
return nil
end

if obj:IsA("BasePart") then
return obj
elseif obj:IsA("Model") then
return obj.PrimaryPart or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
elseif obj:IsA("Tool") then
return obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
end
return nil
end

local function cleanupItemEsp(obj)
local gui = Hub.ActiveItemGuis[obj]
if gui and gui.Parent then gui:Destroy() end
Hub.ActiveItemGuis[obj] = nil
Hub.TrackedItems[obj] = nil
end

local function clearAllItemEsp()
for obj in pairs(Hub.TrackedItems) do
cleanupItemEsp(obj)
end
for _, desc in ipairs(workspace:GetDescendants()) do
if desc.Name == "MapItemTag" then
pcall(function() desc:Destroy() end)
end
end
end

local function attachItemTag(obj)
if not obj or not obj.Parent then return end
local anchorPart = getItemDisplayPart(obj)
if not anchorPart then return end

local existingGui = Hub.ActiveItemGuis[obj]
if not existingGui or not existingGui.Parent then
local old = anchorPart:FindFirstChild("MapItemTag")
if old then old:Destroy() end

local billboard = Instance.new("BillboardGui")
billboard.Name = "MapItemTag"
billboard.Adornee = anchorPart
billboard.Size = UDim2.new(0, 150, 0, 28)
billboard.StudsOffset = Vector3.new(0, 1.8, 0)
billboard.AlwaysOnTop = true
billboard.MaxDistance = Hub.MaxItemEspDistance
billboard.Parent = anchorPart

local label = Instance.new("TextLabel")
label.Name = "ItemName"
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = tostring(obj:GetAttribute("ItemName") or obj.Name)
label.TextColor3 = Color3.fromRGB(255, 215, 75)
label.TextStrokeTransparency = 0.15
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Parent = billboard

Hub.ActiveItemGuis[obj] = billboard
existingGui = billboard
end

existingGui.Adornee = anchorPart
existingGui.MaxDistance = Hub.MaxItemEspDistance
existingGui.Enabled = Hub.ItemEspEnabled
Hub.TrackedItems[obj] = true
end

local function scanMapItems()
if not Hub.ItemEspEnabled then
clearAllItemEsp()
return
end

for obj in pairs(Hub.TrackedItems) do
if not obj or not obj.Parent or not getItemDisplayPart(obj) then
cleanupItemEsp(obj)
else
attachItemTag(obj)
end
end

for _, desc in ipairs(workspace:GetDescendants()) do
if desc:IsA("Tool") or desc:IsA("ClickDetector") or desc:IsA("ProximityPrompt") then
local candidate = desc:IsA("Tool") and desc or desc.Parent
if candidate then
attachItemTag(candidate)
end
elseif desc:IsA("Model") or desc:IsA("BasePart") then
if getItemDisplayPart(desc) then
attachItemTag(desc)
end
end
end
end

local function clearAllEsp()
for model in pairs(Hub.TrackedModels) do
cleanupModel(model)
end
for _, desc in ipairs(workspace:GetDescendants()) do
if desc.Name == "EnemyRedOutline" or desc.Name == "MapNametag" then
pcall(function() desc:Destroy() end)
end
end
clearAllItemEsp()
end

local function updateNametagStats(model, billboard, hum, rootPart)
local statsLbl = billboard:FindFirstChild("StatsLine")
if not statsLbl then return end
local hp = hum and math.max(0, math.floor(hum.Health)) or 0
local maxHp = hum and math.max(1, math.floor(hum.MaxHealth)) or 100
local distMeters = 0
local myChar = LocalPlayer.Character
local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
if myRoot and rootPart then
distMeters = math.floor((rootPart.Position - myRoot.Position).Magnitude * 0.28)
end
statsLbl.Text = string.format("[%d/%d HP | %dm]", hp, maxHp, distMeters)
end

local function attachVisualsToModel(model)
if not model or not model:IsA("Model") then return end
if isOwnCharacter(model) or isIgnoredContainer(model) then return end

local hum = model:FindFirstChildOfClass("Humanoid")
local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
local rootPart = model:FindFirstChild("HumanoidRootPart") or head
if not hum or not head then return end

local plr = getPlayerFromModel(model)
local friendly = isTeammate(plr, model)

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
if existingHl.Adornee ~= model then
existingHl.Adornee = model
end
existingHl.Enabled = Hub.RedOutlineEnabled
end

local existingGui = Hub.ActiveGuis[model]
if not existingGui or not existingGui.Parent then
local oldTag = head:FindFirstChild("MapNametag")
if oldTag then oldTag:Destroy() end

local billboard = Instance.new("BillboardGui")
billboard.Name = "MapNametag"
billboard.Adornee = head
billboard.Size = UDim2.new(0, 185, 0, 46)
billboard.StudsOffset = Vector3.new(0, 2.8, 0)
billboard.AlwaysOnTop = true
billboard.MaxDistance = 2500
billboard.Parent = head

local label = Instance.new("TextLabel")
label.Name = "PlayerName"
label.Size = UDim2.new(1, 0, 0.56, 0)
label.Position = UDim2.new(0, 0, 0, 0)
label.BackgroundTransparency = 1
label.Text = plr and (plr.DisplayName .. " (@" .. plr.Name .. ")") or model.Name
label.TextStrokeTransparency = 0.1
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.Parent = billboard

local statsLbl = Instance.new("TextLabel")
statsLbl.Name = "StatsLine"
statsLbl.Size = UDim2.new(1, 0, 0.42, 0)
statsLbl.Position = UDim2.new(0, 0, 0.56, 0)
statsLbl.BackgroundTransparency = 1
statsLbl.Text = "[100/100 HP | 0m]"
statsLbl.TextColor3 = Color3.fromRGB(255, 235, 160)
statsLbl.TextStrokeTransparency = 0.2
statsLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
statsLbl.Font = Enum.Font.GothamBold
statsLbl.TextScaled = true
statsLbl.Parent = billboard

Hub.ActiveGuis[model] = billboard
existingGui = billboard
end

if existingGui.Adornee ~= head then
existingGui.Adornee = head
end
existingGui.Enabled = Hub.NametagsEnabled
local lbl = existingGui:FindFirstChild("PlayerName")
if lbl then
lbl.TextColor3 = getTagColor(plr, model)
end
updateNametagStats(model, existingGui, hum, rootPart)

Hub.TrackedModels[model] = true
end

local function refreshAllTracked()
for model in pairs(Hub.TrackedModels) do
if not model or not model.Parent or not model:FindFirstChildOfClass("Humanoid") then
cleanupModel(model)
else
attachVisualsToModel(model)
end
end
end

local function scanInitialModels()
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
refreshAllTracked()
saveConfig()
end

function Hub.SetNametags(state)
Hub.NametagsEnabled = state == true
refreshAllTracked()
saveConfig()
end

function Hub.SetItemEsp(state)
Hub.ItemEspEnabled = state == true
scanMapItems()
saveConfig()
end

function Hub.ResetEsp()
clearAllEsp()
scanInitialModels()
if Hub.ItemEspEnabled then
scanMapItems()
end
end

trackConn(RunService.Heartbeat:Connect(function()
if not Hub.NametagsEnabled then return end
for model, gui in pairs(Hub.ActiveGuis) do
if model and model.Parent and gui and gui.Parent then
local hum = model:FindFirstChildOfClass("Humanoid")
local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
updateNametagStats(model, gui, hum, root)
end
end
end))

trackConn(workspace.DescendantAdded:Connect(function(desc)
if desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") then
task.defer(attachVisualsToModel, desc.Parent)
elseif Hub.ItemEspEnabled then
if desc:IsA("Tool") or desc:IsA("ClickDetector") or desc:IsA("ProximityPrompt") then
local candidate = desc:IsA("Tool") and desc or desc.Parent
if candidate then
task.defer(attachItemTag, candidate)
end
elseif desc:IsA("Model") or desc:IsA("BasePart") then
if getItemDisplayPart(desc) then
task.defer(attachItemTag, desc)
end
end
end
end))

trackConn(workspace.DescendantRemoving:Connect(function(desc)
if desc:IsA("Model") and Hub.TrackedModels[desc] then
cleanupModel(desc)
elseif desc:IsA("Humanoid") and desc.Parent and desc.Parent:IsA("Model") and Hub.TrackedModels[desc.Parent] then
cleanupModel(desc.Parent)
elseif Hub.TrackedItems[desc] then
cleanupItemEsp(desc)
end
end))

for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
trackConn(plr.CharacterAdded:Connect(function(char)
task.defer(attachVisualsToModel, char)
end))
trackConn(plr:GetPropertyChangedSignal("Team"):Connect(refreshAllTracked))
trackConn(plr:GetPropertyChangedSignal("TeamColor"):Connect(refreshAllTracked))
trackConn(plr.AttributeChanged:Connect(refreshAllTracked))
end
end

trackConn(Players.PlayerAdded:Connect(function(plr)
if plr ~= LocalPlayer then
trackConn(plr.CharacterAdded:Connect(function(char)
task.defer(attachVisualsToModel, char)
end))
trackConn(plr:GetPropertyChangedSignal("Team"):Connect(refreshAllTracked))
trackConn(plr:GetPropertyChangedSignal("TeamColor"):Connect(refreshAllTracked))
trackConn(plr.AttributeChanged:Connect(refreshAllTracked))
end
end))

trackConn(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshAllTracked))
trackConn(LocalPlayer:GetPropertyChangedSignal("TeamColor"):Connect(refreshAllTracked))
trackConn(LocalPlayer.AttributeChanged:Connect(refreshAllTracked))

scanInitialModels()
if Hub.ItemEspEnabled then
scanMapItems()
end

local lockConn = nil
local lockStatusUpdater = nil
local closeAllDropdowns = nil
local updateLockIndicator = nil

local function stopLockLoop()
Hub.LockHolding = false
Hub.CurrentTarget = nil
if lockConn then
lockConn:Disconnect()
lockConn = nil
end
if lockStatusUpdater then
lockStatusUpdater(false)
end
if updateLockIndicator then
updateLockIndicator(nil)
end
end

local function bindLocalCharacterSafety(char)
if not char then return end
stopLockLoop()
local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
if hum then
trackConn(hum.Died:Connect(stopLockLoop))
end
end

if LocalPlayer.Character then
task.spawn(bindLocalCharacterSafety, LocalPlayer.Character)
end
trackConn(LocalPlayer.CharacterAdded:Connect(function(char)
task.spawn(bindLocalCharacterSafety, char)
end))

local function getAimPartFromModel(model)
if not model or isOwnCharacter(model) or isIgnoredContainer(model) then return nil end
local hum = model:FindFirstChildOfClass("Humanoid")
if not hum or hum.Health <= 0 then return nil end

if Hub.AimPartMode == "HumanoidRootPart" then
return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
else
return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end
end

local function getScreenCenterDistance(worldPos)
local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
if not onScreen or screenPos.Z <= 0 then return nil end
local viewportSize = Camera.ViewportSize
local center = Vector2.new(viewportSize.X * 0.5, viewportSize.Y * 0.5)
local pt = Vector2.new(screenPos.X, screenPos.Y)
return (pt - center).Magnitude
end

local function isWithinFov(worldPos)
if not Hub.FovOnlyLock then return true end
local centerDist = getScreenCenterDistance(worldPos)
if not centerDist then return false end
return centerDist <= Hub.FOVRadius
end

local function isVisibleFromCamera(targetModel, targetPos)
if not Hub.WallCheckEnabled then return true end
local origin = Camera.CFrame.Position
local direction = targetPos - origin
if direction.Magnitude <= 0.01 then return true end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local ignoreList = { Camera }
if LocalPlayer.Character then
table.insert(ignoreList, LocalPlayer.Character)
end
local worldFolder = workspace:FindFirstChild("World")
if worldFolder then
local hlFolder = worldFolder:FindFirstChild("Highlight")
if hlFolder then table.insert(ignoreList, hlFolder) end
end
local rootHighlight = workspace:FindFirstChild("Highlight")
if rootHighlight then table.insert(ignoreList, rootHighlight) end
params.FilterDescendantsInstances = ignoreList

local result = workspace:Raycast(origin, direction, params)
if not result then return true end
if targetModel and result.Instance:IsDescendantOf(targetModel) then
return true
end
return false
end

local function getNearestTarget()
local char = LocalPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
if not root then return nil end

local bestPart = nil
local bestScore = math.huge

for model in pairs(Hub.TrackedModels) do
if model and model.Parent and not isOwnCharacter(model) and not isIgnoredContainer(model) then
local plr = getPlayerFromModel(model)
if not isTeammate(plr, model) then
local aimPart = getAimPartFromModel(model)
if aimPart and isWithinFov(aimPart.Position) and isVisibleFromCamera(model, aimPart.Position) then
local worldDist = (aimPart.Position - root.Position).Magnitude
if worldDist <= Hub.MaxLockDistance then
local score = worldDist
if Hub.TargetPriority == "Crosshair" then
local cDist = getScreenCenterDistance(aimPart.Position)
score = cDist or math.huge
end
if score < bestScore then
bestScore = score
bestPart = aimPart
end
end
end
end
end
end

return bestPart
end

local function startLockHold()
if not isBindCurrentlyHeld() then return end
local target = getNearestTarget()
if not target then
stopLockLoop()
return
end

Hub.LockHolding = true
Hub.CurrentTarget = target
if lockStatusUpdater then
lockStatusUpdater(true)
end

if lockConn then
lockConn:Disconnect()
lockConn = nil
end

lockConn = trackConn(RunService.RenderStepped:Connect(function()
if not isBindCurrentlyHeld() then
stopLockLoop()
return
end
local char = LocalPlayer.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local cur = Hub.CurrentTarget
local targetModel = cur and cur.Parent
local aimPart = getAimPartFromModel(targetModel)

if not root or not targetModel or not aimPart or not isWithinFov(aimPart.Position) or not isVisibleFromCamera(targetModel, aimPart.Position) then
local nextTarget = getNearestTarget()
if nextTarget then
Hub.CurrentTarget = nextTarget
aimPart = nextTarget
else
stopLockLoop()
return
end
end

if (aimPart.Position - root.Position).Magnitude > Hub.MaxLockDistance then
stopLockLoop()
return
end

Hub.CurrentTarget = aimPart
if updateLockIndicator then
updateLockIndicator(aimPart)
end
local camPos = Camera.CFrame.Position
local lookCFrame = CFrame.lookAt(camPos, aimPart.Position)
Camera.CFrame = Camera.CFrame:Lerp(lookCFrame, Hub.LockSmoothness)
end))
end

local function makeDraggable(dragHandle, targetFrame)
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

trackConn(dragHandle.InputBegan:Connect(function(input)
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
end))

trackConn(dragHandle.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end))

trackConn(UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
targetFrame.Position = UDim2.new(
startPos.X.Scale,
startPos.X.Offset + delta.X,
startPos.Y.Scale,
startPos.Y.Offset + delta.Y
)
end
end))
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

local function updateFovRingSize()
fovRing.Size = UDim2.new(0, Hub.FOVRadius * 2, 0, Hub.FOVRadius * 2)
end

local targetMarker = Instance.new("Frame")
targetMarker.Name = "LockedTargetMarker"
targetMarker.AnchorPoint = Vector2.new(0.5, 0.5)
targetMarker.Size = UDim2.new(0, 18, 0, 18)
targetMarker.BackgroundColor3 = Color3.fromRGB(255, 45, 65)
targetMarker.BackgroundTransparency = 0.25
targetMarker.BorderSizePixel = 0
targetMarker.Active = false
targetMarker.Visible = false
targetMarker.ZIndex = 22
targetMarker.Parent = screenGui
Instance.new("UICorner", targetMarker).CornerRadius = UDim.new(1, 0)
local markerStroke = Instance.new("UIStroke", targetMarker)
markerStroke.Color = Color3.fromRGB(255, 255, 255)
markerStroke.Thickness = 1.5

updateLockIndicator = function(aimPart)
if not aimPart or not aimPart.Parent then
targetMarker.Visible = false
return
end
local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
if not onScreen or screenPos.Z <= 0 then
targetMarker.Visible = false
return
end
targetMarker.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
targetMarker.Visible = true
end

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
toggleUiBtn.Modal = true
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
miniBtn.Modal = true
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
shadowFrame.Size = UDim2.new(0, 360, 0, 620)
shadowFrame.Position = UDim2.new(0.5, -174, 0.5, -302)
shadowFrame.BackgroundColor3 = Color3.fromRGB(22, 3, 6)
shadowFrame.BorderSizePixel = 0
shadowFrame.Active = false
shadowFrame.ZIndex = 4
shadowFrame.Parent = screenGui
Instance.new("UICorner", shadowFrame).CornerRadius = UDim.new(0, 16)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel3D"
mainFrame.Size = UDim2.new(0, 360, 0, 620)
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -310)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 10, 14)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false
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
hideBtn.Modal = true
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
listHolder.ClipsDescendants = false
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

local modalButtons = { toggleUiBtn, miniBtn, hideBtn }
local dropdownMenus = {}

closeAllDropdowns = function()
for _, menu in ipairs(dropdownMenus) do
if menu and menu.Parent then
menu.Visible = false
end
end
end

local function setPanelVisible(visible)
mainFrame.Visible = visible
shadowFrame.Visible = visible
toggleUiBtn.Text = visible and "ซ่อน UI" or "เปิด UI"
if not visible and closeAllDropdowns then
closeAllDropdowns()
end
for _, btn in ipairs(modalButtons) do
if btn and btn.Parent then
btn.Modal = visible
end
end
if visible then
UserInputService.MouseIconEnabled = true
end
end

local function unloadHub()
stopLockLoop()
clearAllEsp()
for _, conn in ipairs(activeConnections) do
pcall(function() conn:Disconnect() end)
end
table.clear(activeConnections)
if getgenv then
getgenv().TerUniversalHubConnections = nil
end
if screenGui and screenGui.Parent then
screenGui:Destroy()
end
end

trackConn(hideBtn.MouseButton1Click:Connect(function()
setPanelVisible(false)
end))

trackConn(toggleUiBtn.MouseButton1Click:Connect(function()
setPanelVisible(not mainFrame.Visible)
end))

trackConn(miniBtn.MouseButton1Click:Connect(function()
setPanelVisible(not mainFrame.Visible)
end))

trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
setPanelVisible(not mainFrame.Visible)
return
end
if not gameProcessed and isBindCurrentlyHeld() then
startLockHold()
end
end))

trackConn(UserInputService.InputEnded:Connect(function(input)
if not isBindCurrentlyHeld() then
stopLockLoop()
end
end))

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
switchBtn.Modal = true
switchBtn.AutoButtonColor = false
switchBtn.ZIndex = 20
switchBtn.Parent = row
Instance.new("UICorner", switchBtn).CornerRadius = UDim.new(0, 8)
local switchStroke = Instance.new("UIStroke", switchBtn)
switchStroke.Color = state and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(110, 45, 55)
switchStroke.Thickness = 1.5

table.insert(modalButtons, switchBtn)

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

trackConn(switchBtn.MouseButton1Click:Connect(function()
state = not state
refreshVisual(true)
if callback then callback(state) end
end))

refreshVisual(false)
if state and callback then
task.spawn(callback, true)
end
end

local function addFovSlider(minVal, maxVal, currentVal, onChanged)
local val = math.clamp(currentVal, minVal, maxVal)

local row = Instance.new("Frame")
row.Name = "FovSliderRow"
row.Size = UDim2.new(1, 0, 0, 52)
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
label.Size = UDim2.new(0.65, -14, 0, 22)
label.Position = UDim2.new(0, 14, 0, 4)
label.BackgroundTransparency = 1
label.Active = false
label.Text = "ขนาดวงเล็ง FOV"
label.TextColor3 = Color3.fromRGB(245, 235, 235)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.ZIndex = 10
label.Parent = row

local valLabel = Instance.new("TextLabel")
valLabel.Size = UDim2.new(0.35, -14, 0, 22)
valLabel.Position = UDim2.new(0.65, 0, 0, 4)
valLabel.BackgroundTransparency = 1
valLabel.Active = false
valLabel.Text = tostring(math.floor(val)) .. " px"
valLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
valLabel.TextXAlignment = Enum.TextXAlignment.Right
valLabel.Font = Enum.Font.GothamBlack
valLabel.TextSize = 12
valLabel.ZIndex = 10
valLabel.Parent = row

local track = Instance.new("TextButton")
track.Size = UDim2.new(1, -28, 0, 14)
track.Position = UDim2.new(0, 14, 0, 30)
track.BackgroundColor3 = Color3.fromRGB(22, 7, 10)
track.Text = ""
track.Active = true
track.Modal = true
track.AutoButtonColor = false
track.ZIndex = 15
track.Parent = row
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

table.insert(modalButtons, track)

local fill = Instance.new("Frame")
fill.Size = UDim2.new((val - minVal) / (maxVal - minVal), 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(210, 28, 42)
fill.BorderSizePixel = 0
fill.Active = false
fill.ZIndex = 16
fill.Parent = track
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local sliding = false

local function applyRatio(ratio)
local clamped = math.clamp(ratio, 0, 1)
local newVal = math.floor(minVal + (maxVal - minVal) * clamped)
val = newVal
fill.Size = UDim2.new((val - minVal) / (maxVal - minVal), 0, 1, 0)
valLabel.Text = tostring(val) .. " px"
if onChanged then onChanged(val) end
end

trackConn(track.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
sliding = true
local ratio = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
applyRatio(ratio)
end
end))

trackConn(UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
if sliding then
sliding = false
saveConfig()
end
end
end))

trackConn(UserInputService.InputChanged:Connect(function(input)
if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local ratio = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
applyRatio(ratio)
end
end))

if onChanged then onChanged(val) end
end

local function addDropdownRow(rowName, labelText, options, defaultText, zBase, onSelect)
local row = Instance.new("Frame")
row.Name = rowName
row.Size = UDim2.new(1, 0, 0, 48)
row.BackgroundColor3 = Color3.fromRGB(38, 12, 18)
row.BorderSizePixel = 0
row.Active = false
row.ZIndex = zBase
row.Parent = listHolder
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
local rowStroke = Instance.new("UIStroke", row)
rowStroke.Color = Color3.fromRGB(120, 22, 32)
rowStroke.Thickness = 1.4

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -138, 1, 0)
label.Position = UDim2.new(0, 14, 0, 0)
label.BackgroundTransparency = 1
label.Active = false
label.Text = labelText
label.TextColor3 = Color3.fromRGB(245, 235, 235)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.ZIndex = zBase + 1
label.Parent = row

local statusBadge = nil
if rowName == "LockBindRow" then
statusBadge = Instance.new("TextLabel")
statusBadge.Size = UDim2.new(0, 56, 0, 24)
statusBadge.Position = UDim2.new(1, -184, 0.5, -12)
statusBadge.BackgroundColor3 = Color3.fromRGB(55, 22, 28)
statusBadge.Text = "ปล่อย"
statusBadge.TextColor3 = Color3.fromRGB(220, 190, 190)
statusBadge.Font = Enum.Font.GothamBlack
statusBadge.TextSize = 11
statusBadge.ZIndex = zBase + 2
statusBadge.Parent = row
Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 6)

lockStatusUpdater = function(isLocked)
statusBadge.Text = isLocked and "ล็อกอยู่" or "ปล่อย"
statusBadge.BackgroundColor3 = isLocked and Color3.fromRGB(210, 28, 42) or Color3.fromRGB(55, 22, 28)
statusBadge.TextColor3 = isLocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 190, 190)
end
end

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(0, 114, 0, 30)
dropdownBtn.Position = UDim2.new(1, -124, 0.5, -15)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(85, 14, 22)
dropdownBtn.Text = defaultText .. " ▾"
dropdownBtn.TextColor3 = Color3.fromRGB(255, 240, 240)
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextSize = 11
dropdownBtn.Active = true
dropdownBtn.Modal = true
dropdownBtn.AutoButtonColor = false
dropdownBtn.ZIndex = zBase + 5
dropdownBtn.Parent = row
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)
local ddStroke = Instance.new("UIStroke", dropdownBtn)
ddStroke.Color = Color3.fromRGB(215, 55, 70)
ddStroke.Thickness = 1.4

table.insert(modalButtons, dropdownBtn)

local menuFrame = Instance.new("Frame")
menuFrame.Name = rowName .. "Menu"
menuFrame.Size = UDim2.new(0, 114, 0, #options * 28 + 6)
menuFrame.Position = UDim2.new(1, -124, 1, 4)
menuFrame.BackgroundColor3 = Color3.fromRGB(30, 9, 14)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Active = true
menuFrame.ZIndex = zBase + 40
menuFrame.Parent = row
Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 8)
local menuStroke = Instance.new("UIStroke", menuFrame)
menuStroke.Color = Color3.fromRGB(220, 60, 75)
menuStroke.Thickness = 1.5

table.insert(dropdownMenus, menuFrame)

local menuLayout = Instance.new("UIListLayout", menuFrame)
menuLayout.Padding = UDim.new(0, 2)
menuLayout.SortOrder = Enum.SortOrder.LayoutOrder

local menuPad = Instance.new("UIPadding", menuFrame)
menuPad.PaddingTop = UDim.new(0, 3)
menuPad.PaddingBottom = UDim.new(0, 3)
menuPad.PaddingLeft = UDim.new(0, 3)
menuPad.PaddingRight = UDim.new(0, 3)

for _, opt in ipairs(options) do
local optBtn = Instance.new("TextButton")
optBtn.Size = UDim2.new(1, 0, 0, 26)
optBtn.BackgroundColor3 = Color3.fromRGB(52, 14, 20)
optBtn.Text = opt.label
optBtn.TextColor3 = Color3.fromRGB(250, 235, 235)
optBtn.Font = Enum.Font.GothamBold
optBtn.TextSize = 11
optBtn.Active = true
optBtn.Modal = true
optBtn.AutoButtonColor = false
optBtn.ZIndex = zBase + 45
optBtn.Parent = menuFrame
Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 6)

table.insert(modalButtons, optBtn)

trackConn(optBtn.MouseButton1Click:Connect(function()
dropdownBtn.Text = opt.label .. " ▾"
menuFrame.Visible = false
if onSelect then onSelect(opt.value) end
saveConfig()
end))
end

trackConn(dropdownBtn.MouseButton1Click:Connect(function()
local nextState = not menuFrame.Visible
closeAllDropdowns()
menuFrame.Visible = nextState
end))
end

local function addActionButton(labelText, btnText, bgColor, callback)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 44)
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
label.Size = UDim2.new(1, -110, 1, 0)
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

local actBtn = Instance.new("TextButton")
actBtn.Size = UDim2.new(0, 86, 0, 28)
actBtn.Position = UDim2.new(1, -98, 0.5, -14)
actBtn.BackgroundColor3 = bgColor or Color3.fromRGB(130, 18, 28)
actBtn.Text = btnText
actBtn.TextColor3 = Color3.fromRGB(255, 240, 240)
actBtn.Font = Enum.Font.GothamBlack
actBtn.TextSize = 11
actBtn.Active = true
actBtn.Modal = true
actBtn.AutoButtonColor = false
actBtn.ZIndex = 20
actBtn.Parent = row
Instance.new("UICorner", actBtn).CornerRadius = UDim.new(0, 8)
local actStroke = Instance.new("UIStroke", actBtn)
actStroke.Color = Color3.fromRGB(230, 65, 80)
actStroke.Thickness = 1.3

table.insert(modalButtons, actBtn)

trackConn(actBtn.MouseButton1Click:Connect(function()
closeAllDropdowns()
if callback then callback() end
end))
end

addToggle("โครงศัตรูสีแดง (Red Outline)", Hub.RedOutlineEnabled, function(enabled)
Hub.SetRedOutline(enabled)
end)

addToggle("ชื่อ HP และระยะทั้งแมพ", Hub.NametagsEnabled, function(enabled)
Hub.SetNametags(enabled)
end)

addToggle("แสดงชื่อไอเทมตามแมพ", Hub.ItemEspEnabled, function(enabled)
Hub.SetItemEsp(enabled)
end)

addDropdownRow("ItemDistRow", "ระยะแสดงชื่อไอเทม", ItemDistanceOptions, findOptionLabel(ItemDistanceOptions, Hub.MaxItemEspDistance, "120m"), 20, function(val)
Hub.MaxItemEspDistance = tonumber(val) or 120
scanMapItems()
end)

addToggle("เช็กกำแพงก่อนล็อก (Wall Check)", Hub.WallCheckEnabled, function(enabled)
Hub.WallCheckEnabled = enabled
saveConfig()
end)

addToggle("ล็อกเฉพาะในวงเล็ง FOV", Hub.FovOnlyLock, function(enabled)
Hub.FovOnlyLock = enabled
if enabled then
fovRing.Visible = true
end
saveConfig()
end)

addFovSlider(50, 400, Hub.FOVRadius, function(newRadius)
Hub.FOVRadius = newRadius
updateFovRingSize()
end)

addDropdownRow("LockBindRow", "ปุ่มกดค้างล็อกเป้า", LockKeyOptions, findOptionLabel(LockKeyOptions, Hub.LockBind, "ปุ่ม F"), 18, function(val)
stopLockLoop()
Hub.LockBind = val
end)

addDropdownRow("AimPartRow", "จุดเล็งเป้าหมาย", AimPartOptions, findOptionLabel(AimPartOptions, Hub.AimPartMode, "หัว (Head)"), 16, function(val)
Hub.AimPartMode = val
end)

addDropdownRow("PriorityRow", "ลำดับความสำคัญเป้า", PriorityOptions, findOptionLabel(PriorityOptions, Hub.TargetPriority, "ใกล้เป้าเล็ง"), 15, function(val)
Hub.TargetPriority = val
end)

addDropdownRow("SmoothRow", "ความนุ่มของกล้อง", SmoothnessOptions, findOptionLabel(SmoothnessOptions, Hub.LockSmoothness, "กลาง (0.24)"), 14, function(val)
Hub.LockSmoothness = tonumber(val) or 0.24
end)

addDropdownRow("DistRow", "ระยะล็อกสูงสุด", DistanceOptions, findOptionLabel(DistanceOptions, Hub.MaxLockDistance, "160 Studs"), 12, function(val)
Hub.MaxLockDistance = tonumber(val) or 160
end)

addToggle("แสดงวงเล็ง FOV Ring", false, function(enabled)
fovRing.Visible = enabled
end)

addActionButton("รีเซ็ตป้ายชื่อและโครง ESP", "ล้าง ESP", Color3.fromRGB(130, 18, 28), function()
Hub.ResetEsp()
end)

addActionButton("ปิดสคริปต์และลบ UI ออกจากเกม", "Unload", Color3.fromRGB(75, 10, 15), function()
unloadHub()
end)