local function safeInvoke(fn, ...)
if type(fn) == "function" then
return pcall(fn, ...)
end
return false
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local function attachGuiToTopLayer(guiObj)
guiObj.ResetOnSpawn = false
guiObj.DisplayOrder = 2147483647
guiObj.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mounted = false
if typeof(gethui) == "function" then
local okHost, host = pcall(gethui)
if okHost and host then
local okSet = pcall(function()
guiObj.Parent = host
end)
if okSet and guiObj.Parent == host then
mounted = true
end
end
end

if not mounted then
local okCore = pcall(function()
guiObj.Parent = CoreGui
end)
if not okCore or not guiObj.Parent then
guiObj.Parent = PlayerGui
end
end
end

local KEY_API_URL = "https://ter-key-api.copter2700.workers.dev"
local KEY_CACHE_FILE = "TerUniversalHub_Key.json"
local HEARTBEAT_INTERVAL = 1200

local function canUseFileIo()
return typeof(writefile) == "function" and typeof(readfile) == "function"
end

local function clearSavedKey()
if canUseFileIo() and typeof(delfile) == "function" then
pcall(function()
if typeof(isfile) ~= "function" or isfile(KEY_CACHE_FILE) then
delfile(KEY_CACHE_FILE)
end
end)
end
end

local function loadSavedKey()
if not canUseFileIo() then return "" end
if typeof(isfile) == "function" and not isfile(KEY_CACHE_FILE) then return "" end
local ok, raw = pcall(readfile, KEY_CACHE_FILE)
if not ok or not raw then return "" end
local decOk, data = pcall(function()
return HttpService:JSONDecode(raw)
end)
if decOk and type(data) == "table" and type(data.key) == "string" then
return string.upper(string.gsub(data.key, "%s+", ""))
end
return ""
end

local function saveVerifiedKey(keyStr)
if not canUseFileIo() then return end
pcall(function()
writefile(KEY_CACHE_FILE, HttpService:JSONEncode({ key = keyStr, savedAt = os.time() }))
end)
end

local function getDeviceHwid()
local ok, id = pcall(function()
return RbxAnalyticsService:GetClientId()
end)
if ok and type(id) == "string" and #id > 0 then
return id
end
return tostring(LocalPlayer.UserId) .. "-" .. tostring(game.PlaceId)
end

local function httpGetBody(url)
if typeof(request) == "function" then
local ok, res = pcall(request, { Url = url, Method = "GET" })
if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
return true, res.Body
end
end
if syn and type(syn.request) == "function" then
local ok, res = pcall(syn.request, { Url = url, Method = "GET" })
if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
return true, res.Body
end
end
local okGet, body = pcall(function()
return game:HttpGet(url)
end)
if okGet and type(body) == "string" and #body > 0 then
return true, body
end
return false, "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ตรวจสอบ Key ได้"
end

local function verifyKeyRemote(rawKey)
local cleanKey = string.upper(string.gsub(tostring(rawKey or ""), "%s+", ""))
if #cleanKey < 4 then
return false, "กรุณากรอก Key ก่อนใช้งาน", nil
end
local hwid = getDeviceHwid()
local url = string.format(
"%s/verify?key=%s&hwid=%s",
KEY_API_URL,
HttpService:UrlEncode(cleanKey),
HttpService:UrlEncode(hwid)
)
local okHttp, body = httpGetBody(url)
if not okHttp then
return false, body, nil
end
local decOk, data = pcall(function()
return HttpService:JSONDecode(body)
end)
if not decOk or type(data) ~= "table" then
return false, "รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง", nil
end
if data.ok == true then
return true, tostring(data.message or "ผ่านการตรวจสอบ"), data
end
return false, tostring(data.message or "Key ไม่ถูกต้องหรือหมดอายุ"), data
end

local function promptForValidKey(onAuthorized)
local oldKeyGui = PlayerGui:FindFirstChild("TerUniversalHubKeyGui")
if oldKeyGui then oldKeyGui:Destroy() end

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "TerUniversalHubKeyGui"
keyGui.ResetOnSpawn = false
keyGui.DisplayOrder = 10000
keyGui.Parent = PlayerGui

local card = Instance.new("Frame")
card.Size = UDim2.new(0, 340, 0, 236)
card.Position = UDim2.new(0.5, -170, 0.5, -118)
card.BackgroundColor3 = Color3.fromRGB(22, 10, 15)
card.BorderSizePixel = 0
card.Active = true
card.Parent = keyGui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
local cStroke = Instance.new("UIStroke", card)
cStroke.Color = Color3.fromRGB(205, 35, 50)
cStroke.Thickness = 2

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(115, 15, 24)
topBar.BorderSizePixel = 0
topBar.Parent = card
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "UNIVERSAL 3D HUB • KEY"
title.TextColor3 = Color3.fromRGB(255, 240, 240)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack
title.TextSize = 14
title.Parent = topBar

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -28, 0, 40)
inputBox.Position = UDim2.new(0, 14, 0, 56)
inputBox.BackgroundColor3 = Color3.fromRGB(40, 14, 20)
inputBox.PlaceholderText = "กรอก Key เช่น TER-XXXX-XXXX-XXXX"
inputBox.PlaceholderColor3 = Color3.fromRGB(175, 130, 135)
inputBox.Text = loadSavedKey()
inputBox.TextColor3 = Color3.fromRGB(255, 245, 245)
inputBox.Font = Enum.Font.GothamBold
inputBox.TextSize = 13
inputBox.ClearTextOnFocus = false
inputBox.Parent = card
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local boxStroke = Instance.new("UIStroke", inputBox)
boxStroke.Color = Color3.fromRGB(140, 28, 40)
boxStroke.Thickness = 1.3

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -28, 0, 32)
statusLbl.Position = UDim2.new(0, 14, 0, 102)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "กรุณากรอก Key เพื่อตรวจสอบสิทธิ์และผูกเครื่อง (HWID)"
statusLbl.TextColor3 = Color3.fromRGB(230, 195, 195)
statusLbl.TextWrapped = true
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 11
statusLbl.Parent = card

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(1, -28, 0, 40)
submitBtn.Position = UDim2.new(0, 14, 0, 146)
submitBtn.BackgroundColor3 = Color3.fromRGB(205, 28, 44)
submitBtn.Text = "ยืนยัน Key"
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Font = Enum.Font.GothamBlack
submitBtn.TextSize = 13
submitBtn.AutoButtonColor = false
submitBtn.Parent = card
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 10)

local copyHwidBtn = Instance.new("TextButton")
copyHwidBtn.Size = UDim2.new(1, -28, 0, 28)
copyHwidBtn.Position = UDim2.new(0, 14, 0, 194)
copyHwidBtn.BackgroundColor3 = Color3.fromRGB(58, 16, 24)
copyHwidBtn.Text = "คัดลอก HWID เครื่องนี้"
copyHwidBtn.TextColor3 = Color3.fromRGB(245, 200, 205)
copyHwidBtn.Font = Enum.Font.GothamBold
copyHwidBtn.TextSize = 11
copyHwidBtn.Parent = card
Instance.new("UICorner", copyHwidBtn).CornerRadius = UDim.new(0, 8)

copyHwidBtn.MouseButton1Click:Connect(function()
local myHwid = getDeviceHwid()
if typeof(setclipboard) == "function" then
pcall(setclipboard, myHwid)
statusLbl.TextColor3 = Color3.fromRGB(130, 225, 255)
statusLbl.Text = "คัดลอก HWID แล้ว: " .. tostring(myHwid)
else
statusLbl.TextColor3 = Color3.fromRGB(255, 190, 110)
statusLbl.Text = "HWID: " .. tostring(myHwid)
end
end)

local busy = false
local function attemptVerify(candidateKey)
if busy then return end
busy = true
submitBtn.Text = "กำลังตรวจสอบ..."
statusLbl.TextColor3 = Color3.fromRGB(255, 225, 130)
statusLbl.Text = "กำลังตรวจสอบ Key กับเซิร์ฟเวอร์..."

local clean = string.upper(string.gsub(tostring(candidateKey or ""), "%s+", ""))
local ok, msg, info = verifyKeyRemote(clean)
busy = false

if ok then
saveVerifiedKey(clean)
local hrs = (info and info.hoursLeft) and tostring(info.hoursLeft) or nil
statusLbl.TextColor3 = Color3.fromRGB(90, 255, 140)
statusLbl.Text = "สำเร็จ: " .. msg .. (hrs and (" (เหลือ ~" .. hrs .. " ชม.)") or "")
task.wait(0.35)
if keyGui and keyGui.Parent then keyGui:Destroy() end
onAuthorized(clean, hrs)
else
submitBtn.Text = "ยืนยัน Key"
statusLbl.TextColor3 = Color3.fromRGB(255, 95, 95)
statusLbl.Text = msg
end
end

submitBtn.MouseButton1Click:Connect(function()
attemptVerify(inputBox.Text)
end)

inputBox.FocusLost:Connect(function(enterPressed)
if enterPressed then
attemptVerify(inputBox.Text)
end
end)

local saved = loadSavedKey()
if #saved >= 4 then
task.spawn(attemptVerify, saved)
end
end

local function startMainHub(activeKey, initialHoursLeft)
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

local PalettePresets = {
{ label = "แดงเข้ม", color = Color3.fromRGB(220, 38, 56) },
{ label = "ฟ้าสว่าง", color = Color3.fromRGB(56, 189, 248) },
{ label = "เหลืองทอง", color = Color3.fromRGB(250, 204, 21) },
{ label = "เขียวสด", color = Color3.fromRGB(74, 222, 128) },
}

local Hub = {}
Hub.NametagsEnabled = false
Hub.RedOutlineEnabled = false
Hub.ItemEspEnabled = false
Hub.FovOnlyLock = false
Hub.WallCheckEnabled = false
Hub.LockHolding = false
Hub.LockBind = "F"
Hub.AimPartMode = "Head"
Hub.TargetPriority = "Crosshair"
Hub.CurrentTarget = nil
Hub.TrackedModels = {}
Hub.ActiveGuis = {}
Hub.ActiveHighlights = {}
Hub.ActiveBoxes = {}
Hub.TrackedItems = {}
Hub.ActiveItemGuis = {}
Hub.DrawTags = {}
Hub.LastEspCount = 0
Hub.MaxLockDistance = 160
Hub.MaxItemEspDistance = 120
Hub.LockSmoothness = 0.24
Hub.FOVRadius = 120
Hub.EspColor = Color3.fromRGB(220, 38, 56)
Hub.FovColor = Color3.fromRGB(56, 189, 248)

local CONFIG_FILE = "TerUniversalHub_Config.json"

local PlaceProfiles = {
[122446657157717] = {
WallCheckEnabled = false,
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

local function colorToTbl(c)
return { r = math.floor(c.R * 255), g = math.floor(c.G * 255), b = math.floor(c.B * 255) }
end

local function tblToColor(t, fallback)
if type(t) == "table" and tonumber(t.r) and tonumber(t.g) and tonumber(t.b) then
return Color3.fromRGB(tonumber(t.r), tonumber(t.g), tonumber(t.b))
end
return fallback
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
EspColor = colorToTbl(Hub.EspColor),
FovColor = colorToTbl(Hub.FovColor),
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

if type(data.LockBind) == "string" then Hub.LockBind = data.LockBind end
if type(data.AimPartMode) == "string" then Hub.AimPartMode = data.AimPartMode end
if type(data.TargetPriority) == "string" then Hub.TargetPriority = data.TargetPriority end
if tonumber(data.MaxLockDistance) then Hub.MaxLockDistance = tonumber(data.MaxLockDistance) end
if tonumber(data.MaxItemEspDistance) then Hub.MaxItemEspDistance = tonumber(data.MaxItemEspDistance) end
if tonumber(data.LockSmoothness) then Hub.LockSmoothness = tonumber(data.LockSmoothness) end
if tonumber(data.FOVRadius) then Hub.FOVRadius = math.clamp(tonumber(data.FOVRadius), 50, 400) end
Hub.EspColor = tblToColor(data.EspColor, Hub.EspColor)
Hub.FovColor = tblToColor(data.FovColor, Hub.FovColor)
end

loadConfig()

local LockKeyOptions = {
{ label = "ปุ่ม F", value = "F", keyCode = Enum.KeyCode.F },
{ label = "คลิกขวา (RMB)", value = "RMB", keyCode = nil },
{ label = "ปุ่ม E", value = "E", keyCode = Enum.KeyCode.E },
{ label = "ปุ่ม Q", value = "Q", keyCode = Enum.KeyCode.Q },
{ label = "ปุ่ม X", value = "X", keyCode = Enum.KeyCode.X },
{ label = "ปุ่ม C", value = "C", keyCode = Enum.KeyCode.C },
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

local function nameLooksLikeItem(name)
local n = string.lower(tostring(name or ""))
return string.find(n, "case", 1, true)
or string.find(n, "gun", 1, true)
or string.find(n, "weapon", 1, true)
or string.find(n, "knife", 1, true)
or string.find(n, "rifle", 1, true)
or string.find(n, "sniper", 1, true)
or string.find(n, "sword", 1, true)
or string.find(n, "loot", 1, true)
or string.find(n, "drop", 1, true)
or string.find(n, "pickup", 1, true)
or string.find(n, "crate", 1, true)
or string.find(n, "pistol", 1, true)
or string.find(n, "shotgun", 1, true)
or string.find(n, "item", 1, true)
end

local function itemMaxStuds()
local meters = tonumber(Hub.MaxItemEspDistance) or 120
return math.clamp(meters / 0.28, 40, 8000)
end

local function getEspLayer()
if Hub.EspLayer and Hub.EspLayer.Parent == PlayerGui then
return Hub.EspLayer
end
if Hub.EspLayer then
pcall(function() Hub.EspLayer:Destroy() end)
end
local layer = Instance.new("ScreenGui")
layer.Name = "TerEspLayer"
layer.ResetOnSpawn = false
layer.IgnoreGuiInset = true
layer.DisplayOrder = 50
layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
layer.Parent = PlayerGui
Hub.EspLayer = layer
Hub.EspBin = layer
return layer
end

local function getItemDisplayPart(obj)
if not obj or not obj.Parent or isIgnoredContainer(obj) then return nil end
if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then return nil end
if obj:FindFirstChildOfClass("Humanoid") or obj:FindFirstChildWhichIsA("Humanoid", true) then return nil end

local hasInteract = obj:FindFirstChildOfClass("ClickDetector", true) ~= nil
or obj:FindFirstChildOfClass("ProximityPrompt", true) ~= nil
or obj:IsA("Tool")

local isItemFolder = false
local cur = obj.Parent
while cur and cur ~= workspace do
local n = string.lower(cur.Name)
if string.find(n, "item", 1, true) or string.find(n, "drop", 1, true) or string.find(n, "loot", 1, true) or string.find(n, "pickup", 1, true) or string.find(n, "weapon", 1, true) or string.find(n, "gun", 1, true) then
isItemFolder = true
break
end
cur = cur.Parent
end

if not hasInteract and not isItemFolder and not nameLooksLikeItem(obj.Name) then
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
if Hub.EspBin then
for _, child in ipairs(Hub.EspBin:GetChildren()) do
if child.Name == "MapItemTag" then
pcall(function() child:Destroy() end)
end
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
billboard.LightInfluence = 0
billboard.MaxDistance = itemMaxStuds()
billboard.Parent = getEspLayer()

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
existingGui.MaxDistance = itemMaxStuds()
existingGui.Enabled = Hub.ItemEspEnabled == true
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

local espEntries = {}

local function removeEspFromModel(model)
local entry = espEntries[model]
if entry then
if entry.highlight and entry.highlight.Parent then
pcall(function() entry.highlight:Destroy() end)
end
if entry.billboard and entry.billboard.Parent then
pcall(function() entry.billboard:Destroy() end)
end
espEntries[model] = nil
end
if model then
for _, child in ipairs(model:GetChildren()) do
if child.Name == "TerHubEspHighlight" or child.Name == "TerHubEspBillboard" then
pcall(function() child:Destroy() end)
end
end
end
end

local function clearAllEsp()
for model in pairs(espEntries) do
removeEspFromModel(model)
end
espEntries = {}
for _, desc in ipairs(workspace:GetDescendants()) do
if desc.Name == "TerHubEspHighlight" or desc.Name == "TerHubEspBillboard" or desc.Name == "MapNametag" or desc.Name == "RedOutline" then
pcall(function() desc:Destroy() end)
end
end
end

local function getEspAnchorPart(model)
if not model then return nil end
return model:FindFirstChild("Head")
or model:FindFirstChild("HumanoidRootPart")
or model:FindFirstChild("UpperTorso")
or model:FindFirstChild("Torso")
or model:FindFirstChildWhichIsA("BasePart", true)
end

local function getEspTargets()
local list = {}
local seen = {}

local function tryAdd(m, labelOverride)
if not m or not m:IsA("Model") or seen[m] then return end
if isOwnCharacter(m) then return end
local hum = m:FindFirstChildOfClass("Humanoid") or m:FindFirstChildWhichIsA("Humanoid", true)
if hum and hum.Health <= 0 then return end
local anchor = getEspAnchorPart(m)
if not anchor then return end
seen[m] = true
table.insert(list, { model = m, hum = hum, anchor = anchor, label = labelOverride or m.Name })
end

for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and plr.Character then
local displayName = (plr.DisplayName and plr.DisplayName ~= "" and plr.DisplayName ~= plr.Name)
and (plr.DisplayName .. " (@" .. plr.Name .. ")")
or plr.Name
tryAdd(plr.Character, displayName)
end
end

local worldFolder = workspace:FindFirstChild("World")
if worldFolder then
for _, desc in ipairs(worldFolder:GetDescendants()) do
if desc.Name == "Entities" then
for _, ent in ipairs(desc:GetChildren()) do
if ent:IsA("Model") then
tryAdd(ent, ent.Name)
end
end
end
end
end

return list
end

local function buildEspVisuals(item)
local model = item.model
local anchor = item.anchor
if not model or not model.Parent or not anchor or not anchor.Parent then return end

removeEspFromModel(model)

local hl = nil
if Hub.RedOutlineEnabled then
hl = Instance.new("Highlight")
hl.Name = "TerHubEspHighlight"
hl.Adornee = model
hl.FillColor = Hub.EspColor
hl.OutlineColor = Hub.EspColor
hl.FillTransparency = 0.65
hl.OutlineTransparency = 0
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
hl.Parent = model
end

local bb = nil
if Hub.NametagsEnabled then
bb = Instance.new("BillboardGui")
bb.Name = "TerHubEspBillboard"
bb.Adornee = anchor
bb.Size = UDim2.new(0, 180, 0, 38)
bb.StudsOffset = Vector3.new(0, 2.6, 0)
bb.AlwaysOnTop = true
bb.MaxDistance = 400
bb.Parent = model

local nameLbl = Instance.new("TextLabel")
nameLbl.Name = "PlayerName"
nameLbl.Size = UDim2.new(1, 0, 0, 18)
nameLbl.Position = UDim2.new(0, 0, 0, 0)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = item.label
nameLbl.TextColor3 = Hub.EspColor
nameLbl.TextStrokeTransparency = 0.2
nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 13
nameLbl.Parent = bb

local statsLbl = Instance.new("TextLabel")
statsLbl.Name = "StatsLine"
statsLbl.Size = UDim2.new(1, 0, 0, 18)
statsLbl.Position = UDim2.new(0, 0, 0, 18)
statsLbl.BackgroundTransparency = 1
statsLbl.Text = "[100/100 HP | 0m]"
statsLbl.TextColor3 = Color3.fromRGB(255, 235, 130)
statsLbl.TextStrokeTransparency = 0.2
statsLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
statsLbl.Font = Enum.Font.GothamBold
statsLbl.TextSize = 12
statsLbl.Parent = bb
end

espEntries[model] = {
highlight = hl,
billboard = bb,
hum = item.hum,
anchor = anchor,
label = item.label
}
end

local function refreshAllTracked()
if not Hub.RedOutlineEnabled and not Hub.NametagsEnabled then
clearAllEsp()
return
end
local targets = getEspTargets()
local activeSet = {}
for _, item in ipairs(targets) do
activeSet[item.model] = true
buildEspVisuals(item)
end
for model in pairs(espEntries) do
if not activeSet[model] or not model.Parent then
removeEspFromModel(model)
end
end
end

local function syncEspVisualsNow()
if not Hub.RedOutlineEnabled and not Hub.NametagsEnabled then
clearAllEsp()
return
end
refreshAllTracked()
local myChar = LocalPlayer.Character
local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head"))
for model, entry in pairs(espEntries) do
if not model or not model.Parent or not entry.anchor or not entry.anchor.Parent then
removeEspFromModel(model)
elseif type(entry) == "table" then
if entry.highlight then
entry.highlight.Enabled = (Hub.RedOutlineEnabled == true)
entry.highlight.FillColor = Hub.EspColor
entry.highlight.OutlineColor = Hub.EspColor
end
if entry.billboard then
entry.billboard.Enabled = (Hub.NametagsEnabled == true)
local nameLbl = entry.billboard:FindFirstChild("PlayerName")
if nameLbl then nameLbl.TextColor3 = Hub.EspColor end
local statsLbl = entry.billboard:FindFirstChild("StatsLine")
if statsLbl then
local hum = entry.hum
local hp = hum and math.max(0, math.floor(hum.Health)) or 100
local maxHp = hum and math.max(1, math.floor(hum.MaxHealth)) or 100
local distMeters = 0
if myRoot then
distMeters = math.floor((entry.anchor.Position - myRoot.Position).Magnitude * 0.28)
end
statsLbl.Text = string.format("[%d/%d HP | %dm]", hp, maxHp, distMeters)
end
end
end
end
end

Hub.SetRedOutline = function(enabled)
Hub.RedOutlineEnabled = (enabled == true)
syncEspVisualsNow()
saveConfig()
end

Hub.SetNametags = function(enabled)
Hub.NametagsEnabled = (enabled == true)
syncEspVisualsNow()
saveConfig()
end

Hub.SetItemEsp = function(enabled)
Hub.ItemEspEnabled = (enabled == true)
scanMapItems()
saveConfig()
end

Hub.ResetEsp = function()
clearAllEsp()
clearAllItemEsp()
if Hub.RedOutlineEnabled or Hub.NametagsEnabled then
refreshAllTracked()
end
if Hub.ItemEspEnabled then
scanMapItems()
end
end

local lastEspScan = 0
trackConn(RunService.Heartbeat:Connect(function()
if not Hub.RedOutlineEnabled and not Hub.NametagsEnabled then
return
end
local now = os.clock()
if now - lastEspScan >= 1.2 then
lastEspScan = now
refreshAllTracked()
end

local myChar = LocalPlayer.Character
local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Head"))

for model, entry in pairs(espEntries) do
if not model or not model.Parent or not entry.anchor or not entry.anchor.Parent then
removeEspFromModel(model)
else
if entry.highlight then
entry.highlight.Enabled = Hub.RedOutlineEnabled == true
entry.highlight.FillColor = Hub.EspColor
entry.highlight.OutlineColor = Hub.EspColor
end
if entry.billboard then
entry.billboard.Enabled = Hub.NametagsEnabled == true
local nameLbl = entry.billboard:FindFirstChild("PlayerName")
if nameLbl then
nameLbl.TextColor3 = Hub.EspColor
end
local statsLbl = entry.billboard:FindFirstChild("StatsLine")
if statsLbl then
local hum = entry.hum
local hp = hum and math.max(0, math.floor(hum.Health)) or 100
local maxHp = hum and math.max(1, math.floor(hum.MaxHealth)) or 100
local distMeters = 0
if myRoot then
distMeters = math.floor((entry.anchor.Position - myRoot.Position).Magnitude * 0.28)
end
statsLbl.Text = string.format("[%d/%d HP | %dm]", hp, maxHp, distMeters)
end
end
end
end
end))

local function isWithinFov(worldPos)
if not Hub.FovOnlyLock then return true end
local vp, onScreen = Camera:WorldToViewportPoint(worldPos)
if not onScreen or vp.Z <= 0 then return false end
local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
local pt = Vector2.new(vp.X, vp.Y)
return (pt - center).Magnitude <= (tonumber(Hub.FOVRadius) or 120)
end

local function getScreenCenterDistance(worldPos)
local vp, onScreen = Camera:WorldToViewportPoint(worldPos)
if not onScreen or vp.Z <= 0 then return nil end
local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
return (Vector2.new(vp.X, vp.Y) - center).Magnitude
end

local function isVisibleFromCamera(model, worldPos)
if not Hub.WallCheckEnabled then return true end
local origin = Camera.CFrame.Position
local dir = worldPos - origin
if dir.Magnitude <= 0.01 then return true end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local ignoreList = {}
if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
params.FilterDescendantsInstances = ignoreList
local res = workspace:Raycast(origin, dir, params)
if not res then return true end
return model and res.Instance and res.Instance:IsDescendantOf(model)
end

local function getAimPartFromModel(model)
if not model or not model.Parent then return nil end
if Hub.AimPartMode == "HumanoidRootPart" then
return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
end
return model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
end

local function getNearestTarget()
local char = LocalPlayer.Character
local root = char and (char:FindFirstChild("HumanoidRootPart", true) or char:FindFirstChild("Head", true))
local originPos = root and root.Position or Camera.CFrame.Position

local bestPart = nil
local bestScore = math.huge

for _, item in ipairs(getEspTargets()) do
local model = item.model
if model and model.Parent then
local plr = getPlayerFromModel(model)
if not isTeammate(plr, model) then
local aimPart = getAimPartFromModel(model)
if aimPart and aimPart:IsA("BasePart") and isWithinFov(aimPart.Position) and isVisibleFromCamera(model, aimPart.Position) then
local worldDist = (aimPart.Position - originPos).Magnitude
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

local LOCK_STEP_NAME = "TerUniversalHubHeadLockStep"
local lockConn = nil
local lockStatusUpdater = nil
local updateLockIndicator = nil
local closeAllDropdowns = nil

local function stopLockLoop()
Hub.LockHolding = false
Hub.CurrentTarget = nil
pcall(function()
RunService:UnbindFromRenderStep(LOCK_STEP_NAME)
end)
pcall(function()
RunService:UnbindFromRenderStep(LOCK_STEP_NAME .. "Post")
end)
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

local function startLockHold()
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

pcall(function()
RunService:UnbindFromRenderStep(LOCK_STEP_NAME)
end)
pcall(function()
RunService:UnbindFromRenderStep(LOCK_STEP_NAME .. "Post")
end)

local function stepAimLock(dt)
if not isBindCurrentlyHeld() then
stopLockLoop()
return
end
local char = LocalPlayer.Character
local root = char and (char:FindFirstChild("HumanoidRootPart", true) or char:FindFirstChild("Head", true))
local cur = Hub.CurrentTarget
local targetModel = cur and cur:FindFirstAncestorOfClass("Model")
local aimPart = getAimPartFromModel(targetModel)

if not targetModel or not aimPart or not aimPart.Parent or not isWithinFov(aimPart.Position) or not isVisibleFromCamera(targetModel, aimPart.Position) then
local nextTarget = getNearestTarget()
if nextTarget then
Hub.CurrentTarget = nextTarget
aimPart = nextTarget
else
stopLockLoop()
return
end
end

local originPos = root and root.Position or Camera.CFrame.Position
if (aimPart.Position - originPos).Magnitude > Hub.MaxLockDistance then
stopLockLoop()
return
end

Hub.CurrentTarget = aimPart
if updateLockIndicator then
updateLockIndicator(aimPart)
end

local stepDt = math.clamp(tonumber(dt) or (1 / 60), 0.001, 0.05)
local smoothFactor = math.clamp(tonumber(Hub.LockSmoothness) or 0.24, 0.05, 1)
local alpha = (smoothFactor >= 0.99) and 1 or (1 - math.exp(-(smoothFactor * 60) * stepDt))

local camPos = Camera.CFrame.Position
local aimPos = aimPart.Position
local delta = aimPos - camPos
if delta.Magnitude > 0.001 then
local desiredLook = delta.Unit
local blendedLook = Camera.CFrame.LookVector:Lerp(desiredLook, alpha)
if blendedLook.Magnitude > 0.0001 then
Camera.CFrame = CFrame.lookAt(camPos, camPos + blendedLook.Unit)
end
end
end

RunService:BindToRenderStep(LOCK_STEP_NAME, Enum.RenderPriority.Camera.Value + 2, stepAimLock)
RunService:BindToRenderStep(LOCK_STEP_NAME .. "Post", Enum.RenderPriority.Last.Value, stepAimLock)
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
fovStroke.Color = Hub.FovColor
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

local miniBtn = Instance.new("TextButton")
miniBtn.Name = "MiniToggle3D"
miniBtn.Size = UDim2.new(0, 56, 0, 56)
miniBtn.Position = UDim2.new(0, 20, 0.5, -28)
miniBtn.BackgroundColor3 = Color3.fromRGB(28, 12, 16)
miniBtn.Text = "TER"
miniBtn.TextColor3 = Color3.fromRGB(255, 240, 242)
miniBtn.Font = Enum.Font.GothamBlack
miniBtn.TextSize = 16
miniBtn.Active = true
miniBtn.Modal = true
miniBtn.AutoButtonColor = false
miniBtn.ZIndex = 200
miniBtn.Parent = screenGui
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 12)
local miniStroke = Instance.new("UIStroke", miniBtn)
miniStroke.Color = Color3.fromRGB(210, 35, 52)
miniStroke.Thickness = 1.8

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel3D"
mainFrame.Size = UDim2.new(0, 520, 0, 370)
mainFrame.Position = UDim2.new(0.5, -260, 0.5, -185)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.ZIndex = 150
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(52, 52, 62)
mainStroke.Thickness = 1.4

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
header.BorderSizePixel = 0
header.Active = true
header.ZIndex = 8
header.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 190, 0, 20)
titleLabel.Position = UDim2.new(0, 14, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "UNIVERSAL 3D HUB"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 14
titleLabel.ZIndex = 10
titleLabel.Parent = header

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(0, 220, 0, 15)
subLabel.Position = UDim2.new(0, 14, 0, 24)
subLabel.BackgroundTransparency = 1
subLabel.Text = "PlaceId: " .. tostring(game.PlaceId) .. " • Key Active"
subLabel.TextColor3 = Color3.fromRGB(145, 145, 160)
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Font = Enum.Font.GothamMedium
subLabel.TextSize = 10
subLabel.ZIndex = 10
subLabel.Parent = header

local keyBadge = Instance.new("TextLabel")
keyBadge.Size = UDim2.new(0, 96, 0, 24)
keyBadge.Position = UDim2.new(1, -162, 0.5, -12)
keyBadge.BackgroundColor3 = Color3.fromRGB(32, 34, 42)
keyBadge.Text = initialHoursLeft and ("เหลือ " .. tostring(initialHoursLeft) .. " ชม.") or "KEY OK"
keyBadge.TextColor3 = Color3.fromRGB(120, 250, 160)
keyBadge.Font = Enum.Font.GothamBold
keyBadge.TextSize = 11
keyBadge.ZIndex = 12
keyBadge.Parent = header
Instance.new("UICorner", keyBadge).CornerRadius = UDim.new(0, 6)

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 54, 0, 26)
hideBtn.Position = UDim2.new(1, -64, 0.5, -13)
hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
hideBtn.Text = "ซ่อน"
hideBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 11
hideBtn.Active = true
hideBtn.Modal = true
hideBtn.ZIndex = 14
hideBtn.Parent = header
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 7)

local sideBar = Instance.new("Frame")
sideBar.Name = "SideNav"
sideBar.Size = UDim2.new(0, 134, 1, -44)
sideBar.Position = UDim2.new(0, 0, 0, 44)
sideBar.BackgroundColor3 = Color3.fromRGB(19, 19, 24)
sideBar.BorderSizePixel = 0
sideBar.ZIndex = 8
sideBar.Parent = mainFrame

local sideLayout = Instance.new("UIListLayout", sideBar)
sideLayout.Padding = UDim.new(0, 6)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local sidePad = Instance.new("UIPadding", sideBar)
sidePad.PaddingTop = UDim.new(0, 10)
sidePad.PaddingLeft = UDim.new(0, 8)
sidePad.PaddingRight = UDim.new(0, 8)

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Name = "ContentScroll"
contentScroll.Size = UDim2.new(1, -142, 1, -52)
contentScroll.Position = UDim2.new(0, 138, 0, 48)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 4
contentScroll.ScrollBarImageColor3 = Color3.fromRGB(210, 35, 52)
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.ClipsDescendants = true
contentScroll.Active = true
contentScroll.ZIndex = 8
contentScroll.Parent = mainFrame

local modalButtons = { miniBtn, hideBtn }
local dropdownMenus = {}
local navPages = {}
local navButtons = {}
local isUnloading = false

local function refreshCanvasForPage(pageFrame)
if not pageFrame or not pageFrame.Visible then return end
local layoutObj = pageFrame:FindFirstChildOfClass("UIListLayout")
if layoutObj then
contentScroll.CanvasSize = UDim2.new(0, 0, 0, layoutObj.AbsoluteContentSize.Y + 14)
end
end

local function switchPage(pageId)
for id, frame in pairs(navPages) do
frame.Visible = (id == pageId)
end
for id, btn in pairs(navButtons) do
local active = (id == pageId)
btn.BackgroundColor3 = active and Color3.fromRGB(205, 28, 44) or Color3.fromRGB(26, 26, 33)
btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 185, 200)
end
contentScroll.CanvasPosition = Vector2.new(0, 0)
task.defer(function()
refreshCanvasForPage(navPages[pageId])
end)
end

for idx, navItem in ipairs({
{ id = "Aim", label = "ต่อสู้ (Aim)" },
{ id = "ESP", label = "มองเห็น (ESP)" },
{ id = "System", label = "ระบบ / Key" },
}) do
local nBtn = Instance.new("TextButton")
nBtn.Size = UDim2.new(1, 0, 0, 34)
nBtn.LayoutOrder = idx
nBtn.BackgroundColor3 = (idx == 1) and Color3.fromRGB(205, 28, 44) or Color3.fromRGB(26, 26, 33)
nBtn.Text = navItem.label
nBtn.TextColor3 = (idx == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 185, 200)
nBtn.TextXAlignment = Enum.TextXAlignment.Left
nBtn.Font = Enum.Font.GothamBold
nBtn.TextSize = 12
nBtn.Active = true
nBtn.Modal = true
nBtn.AutoButtonColor = false
nBtn.ZIndex = 12
nBtn.Parent = sideBar
Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 8)
local nPad = Instance.new("UIPadding", nBtn)
nPad.PaddingLeft = UDim.new(0, 10)
table.insert(modalButtons, nBtn)
navButtons[navItem.id] = nBtn

local page = Instance.new("Frame")
page.Name = navItem.id .. "Page"
page.Size = UDim2.new(1, -6, 0, 0)
page.AutomaticSize = Enum.AutomaticSize.Y
page.BackgroundTransparency = 1
page.Visible = (idx == 1)
page.ZIndex = 8
page.Parent = contentScroll

local pLayout = Instance.new("UIListLayout", page)
pLayout.Padding = UDim.new(0, 10)
pLayout.SortOrder = Enum.SortOrder.LayoutOrder
pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
if page.Visible then
contentScroll.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 14)
end
end)

navPages[navItem.id] = page

trackConn(nBtn.MouseButton1Click:Connect(function()
if closeAllDropdowns then closeAllDropdowns() end
switchPage(navItem.id)
end))
end

closeAllDropdowns = function()
for _, menu in ipairs(dropdownMenus) do
if menu and menu.Parent then
menu.Visible = false
end
end
end

local function setPanelVisible(visible)
mainFrame.Visible = visible
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
if isUnloading then return end
isUnloading = true
stopLockLoop()
clearAllEsp()
clearAllItemEsp()
if Hub.EspLayer then
pcall(function() Hub.EspLayer:Destroy() end)
Hub.EspLayer = nil
Hub.EspBin = nil
elseif Hub.EspBin then
pcall(function() Hub.EspBin:Destroy() end)
Hub.EspBin = nil
end
for _, menu in ipairs(dropdownMenus) do
if menu and menu.Parent then menu:Destroy() end
end
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

trackConn(GuiService.MenuOpened:Connect(function()
if closeAllDropdowns then closeAllDropdowns() end
mainFrame.Visible = false
end))
trackConn(GuiService.MenuClosed:Connect(function()
UserInputService.MouseIconEnabled = true
end))

makeDraggable(header, mainFrame)
makeDraggable(miniBtn, miniBtn)

local function createCard(parentPage, cardTitle, subText, orderIndex)
local card = Instance.new("Frame")
card.Name = cardTitle .. "Card"
card.Size = UDim2.new(1, 0, 0, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
card.LayoutOrder = orderIndex or 1
card.BackgroundColor3 = Color3.fromRGB(23, 23, 29)
card.BorderSizePixel = 0
card.ZIndex = 9
card.Parent = parentPage
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", card)
stroke.Color = Color3.fromRGB(46, 46, 58)
stroke.Thickness = 1

local topRow = Instance.new("Frame")
topRow.Size = UDim2.new(1, 0, 0, 42)
topRow.BackgroundTransparency = 1
topRow.ZIndex = 10
topRow.Parent = card

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -60, 0, 20)
titleLbl.Position = UDim2.new(0, 12, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = cardTitle
titleLbl.TextColor3 = Color3.fromRGB(245, 245, 250)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.ZIndex = 11
titleLbl.Parent = topRow

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(1, -60, 0, 14)
subLbl.Position = UDim2.new(0, 12, 0, 24)
subLbl.BackgroundTransparency = 1
subLbl.Text = subText or "พร้อมใช้งาน"
subLbl.TextColor3 = Color3.fromRGB(145, 145, 165)
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Font = Enum.Font.GothamMedium
subLbl.TextSize = 10
subLbl.ZIndex = 11
subLbl.Parent = topRow

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 28, 0, 24)
collapseBtn.Position = UDim2.new(1, -38, 0.5, -12)
collapseBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
collapseBtn.Text = "^"
collapseBtn.TextColor3 = Color3.fromRGB(210, 210, 225)
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 12
collapseBtn.Active = true
collapseBtn.Modal = true
collapseBtn.ZIndex = 12
collapseBtn.Parent = topRow
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 6)
table.insert(modalButtons, collapseBtn)

local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -20, 0, 0)
body.Position = UDim2.new(0, 10, 0, 44)
body.AutomaticSize = Enum.AutomaticSize.Y
body.BackgroundTransparency = 1
body.ZIndex = 10
body.Parent = card

local bLayout = Instance.new("UIListLayout", body)
bLayout.Padding = UDim.new(0, 6)
bLayout.SortOrder = Enum.SortOrder.LayoutOrder

local bPad = Instance.new("UIPadding", body)
bPad.PaddingBottom = UDim.new(0, 10)

local expanded = true
trackConn(collapseBtn.MouseButton1Click:Connect(function()
expanded = not expanded
body.Visible = expanded
collapseBtn.Text = expanded and "^" or "v"
task.defer(function()
refreshCanvasForPage(parentPage)
end)
end))

return body, subLbl
end

local function addCapsuleToggle(parentCard, labelText, hintText, defaultState, orderIdx, callback)
local state = defaultState == true
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, hintText and 42 or 34)
row.LayoutOrder = orderIdx or 1
row.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
row.BorderSizePixel = 0
row.ZIndex = 11
row.Parent = parentCard
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -66, 0, 18)
lbl.Position = UDim2.new(0, 10, 0, hintText and 4 or 8)
lbl.BackgroundTransparency = 1
lbl.Text = labelText
lbl.TextColor3 = Color3.fromRGB(240, 240, 248)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 12
lbl.ZIndex = 12
lbl.Parent = row

if hintText then
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -66, 0, 14)
hint.Position = UDim2.new(0, 10, 0, 22)
hint.BackgroundTransparency = 1
hint.Text = hintText
hint.TextColor3 = Color3.fromRGB(135, 135, 155)
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 10
hint.ZIndex = 12
hint.Parent = row
end

local pill = Instance.new("TextButton")
pill.Size = UDim2.new(0, 42, 0, 22)
pill.Position = UDim2.new(1, -52, 0.5, -11)
pill.BackgroundColor3 = state and Color3.fromRGB(210, 28, 44) or Color3.fromRGB(55, 55, 68)
pill.Text = ""
pill.Active = true
pill.Modal = true
pill.AutoButtonColor = false
pill.ZIndex = 15
pill.Parent = row
Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
table.insert(modalButtons, pill)

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 16, 0, 16)
knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
knob.BorderSizePixel = 0
knob.ZIndex = 16
knob.Parent = pill
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local function applyState(anim)
local targetBg = state and Color3.fromRGB(210, 28, 44) or Color3.fromRGB(55, 55, 68)
local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
if anim then
TweenService:Create(pill, TweenInfo.new(0.14), { BackgroundColor3 = targetBg }):Play()
TweenService:Create(knob, TweenInfo.new(0.14), { Position = targetPos }):Play()
else
pill.BackgroundColor3 = targetBg
knob.Position = targetPos
end
end

trackConn(pill.MouseButton1Click:Connect(function()
state = not state
applyState(true)
if callback then callback(state) end
end))

applyState(false)
end

local function addSliderRow(parentCard, labelText, suffix, minVal, maxVal, currentVal, orderIdx, onChanged)
local val = math.clamp(currentVal, minVal, maxVal)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 44)
row.LayoutOrder = orderIdx or 1
row.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
row.BorderSizePixel = 0
row.ZIndex = 11
row.Parent = parentCard
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.65, -10, 0, 18)
lbl.Position = UDim2.new(0, 10, 0, 4)
lbl.BackgroundTransparency = 1
lbl.Text = labelText
lbl.TextColor3 = Color3.fromRGB(240, 240, 248)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 12
lbl.ZIndex = 12
lbl.Parent = row

local valLbl = Instance.new("TextLabel")
valLbl.Size = UDim2.new(0.35, -10, 0, 18)
valLbl.Position = UDim2.new(0.65, 0, 0, 4)
valLbl.BackgroundTransparency = 1
valLbl.Text = tostring(math.floor(val)) .. (suffix or "")
valLbl.TextColor3 = Color3.fromRGB(255, 110, 125)
valLbl.TextXAlignment = Enum.TextXAlignment.Right
valLbl.Font = Enum.Font.GothamBold
valLbl.TextSize = 11
valLbl.ZIndex = 12
valLbl.Parent = row

local track = Instance.new("TextButton")
track.Size = UDim2.new(1, -20, 0, 10)
track.Position = UDim2.new(0, 10, 0, 26)
track.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
track.Text = ""
track.Active = true
track.Modal = true
track.AutoButtonColor = false
track.ZIndex = 14
track.Parent = row
Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
table.insert(modalButtons, track)

local fill = Instance.new("Frame")
fill.Size = UDim2.new((val - minVal) / (maxVal - minVal), 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(210, 28, 44)
fill.BorderSizePixel = 0
fill.ZIndex = 15
fill.Parent = track
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local sliding = false
local function setRatio(r)
local c = math.clamp(r, 0, 1)
val = math.floor(minVal + (maxVal - minVal) * c)
fill.Size = UDim2.new((val - minVal) / (maxVal - minVal), 0, 1, 0)
valLbl.Text = tostring(val) .. (suffix or "")
if onChanged then onChanged(val) end
end

trackConn(track.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
sliding = true
setRatio((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
end
end))
trackConn(UserInputService.InputEnded:Connect(function(input)
if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
sliding = false
saveConfig()
end
end))
trackConn(UserInputService.InputChanged:Connect(function(input)
if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
setRatio((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1))
end
end))

if onChanged then onChanged(val) end
end

local function addDropdown(parentCard, rowName, labelText, options, defaultText, orderIdx, onSelect)
local row = Instance.new("Frame")
row.Name = rowName
row.Size = UDim2.new(1, 0, 0, 34)
row.LayoutOrder = orderIdx or 1
row.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
row.BorderSizePixel = 0
row.ZIndex = 11
row.Parent = parentCard
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -134, 1, 0)
lbl.Position = UDim2.new(0, 10, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = labelText
lbl.TextColor3 = Color3.fromRGB(240, 240, 248)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 12
lbl.ZIndex = 12
lbl.Parent = row

if rowName == "LockBindRow" then
local badge = Instance.new("TextLabel")
badge.Size = UDim2.new(0, 50, 0, 20)
badge.Position = UDim2.new(1, -174, 0.5, -10)
badge.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
badge.Text = "ปล่อย"
badge.TextColor3 = Color3.fromRGB(200, 200, 215)
badge.Font = Enum.Font.GothamBold
badge.TextSize = 10
badge.ZIndex = 13
badge.Parent = row
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)
lockStatusUpdater = function(locked)
badge.Text = locked and "ล็อกอยู่" or "ปล่อย"
badge.BackgroundColor3 = locked and Color3.fromRGB(210, 28, 44) or Color3.fromRGB(45, 45, 56)
badge.TextColor3 = Color3.fromRGB(255, 255, 255)
end
end

local ddBtn = Instance.new("TextButton")
ddBtn.Size = UDim2.new(0, 126, 0, 24)
ddBtn.Position = UDim2.new(1, -134, 0.5, -12)
ddBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 54)
ddBtn.Text = defaultText .. " <>"
ddBtn.TextColor3 = Color3.fromRGB(245, 245, 252)
ddBtn.Font = Enum.Font.GothamBold
ddBtn.TextSize = 11
ddBtn.Active = true
ddBtn.Modal = true
ddBtn.AutoButtonColor = false
ddBtn.ZIndex = 15
ddBtn.Parent = row
Instance.new("UICorner", ddBtn).CornerRadius = UDim.new(0, 6)
table.insert(modalButtons, ddBtn)

local currentIdx = 1
for i, opt in ipairs(options) do
if opt.label == defaultText then
currentIdx = i
break
end
end

ddBtn.Text = options[currentIdx].label .. " <>"

trackConn(ddBtn.MouseButton1Click:Connect(function()
currentIdx = (currentIdx % #options) + 1
local chosen = options[currentIdx]
ddBtn.Text = chosen.label .. " <>"
if onSelect then onSelect(chosen.value) end
saveConfig()
end))
end

local function addColorRow(parentCard, labelText, currentColor, orderIdx, onPick)
local picked = currentColor
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 34)
row.LayoutOrder = orderIdx or 1
row.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
row.BorderSizePixel = 0
row.ZIndex = 11
row.Parent = parentCard
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.55, -10, 1, 0)
lbl.Position = UDim2.new(0, 10, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = labelText
lbl.TextColor3 = Color3.fromRGB(240, 240, 248)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 12
lbl.ZIndex = 12
lbl.Parent = row

local swatchHolder = Instance.new("Frame")
swatchHolder.Size = UDim2.new(0, 108, 0, 22)
swatchHolder.Position = UDim2.new(1, -118, 0.5, -11)
swatchHolder.BackgroundTransparency = 1
swatchHolder.ZIndex = 12
swatchHolder.Parent = row

local sLayout = Instance.new("UIListLayout", swatchHolder)
sLayout.FillDirection = Enum.FillDirection.Horizontal
sLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
sLayout.Padding = UDim.new(0, 6)

for _, preset in ipairs(PalettePresets) do
local swBtn = Instance.new("TextButton")
swBtn.Size = UDim2.new(0, 20, 0, 20)
swBtn.BackgroundColor3 = preset.color
swBtn.Text = ""
swBtn.Active = true
swBtn.Modal = true
swBtn.AutoButtonColor = false
swBtn.ZIndex = 15
swBtn.Parent = swatchHolder
Instance.new("UICorner", swBtn).CornerRadius = UDim.new(0, 5)
local swStroke = Instance.new("UIStroke", swBtn)
swStroke.Color = Color3.fromRGB(255, 255, 255)
swStroke.Thickness = (math.abs(picked.R - preset.color.R) < 0.03 and math.abs(picked.G - preset.color.G) < 0.03 and math.abs(picked.B - preset.color.B) < 0.03) and 1.8 or 0
table.insert(modalButtons, swBtn)

trackConn(swBtn.MouseButton1Click:Connect(function()
picked = preset.color
for _, child in ipairs(swatchHolder:GetChildren()) do
if child:IsA("TextButton") then
local st = child:FindFirstChildOfClass("UIStroke")
if st then
st.Thickness = (child == swBtn) and 1.8 or 0
end
end
end
if onPick then onPick(picked) end
saveConfig()
end))
end
end

local function addActionRow(parentCard, labelText, btnText, bgColor, orderIdx, callback)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 36)
row.LayoutOrder = orderIdx or 1
row.BackgroundColor3 = Color3.fromRGB(29, 29, 36)
row.BorderSizePixel = 0
row.ZIndex = 11
row.Parent = parentCard
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -104, 1, 0)
lbl.Position = UDim2.new(0, 10, 0, 0)
lbl.BackgroundTransparency = 1
lbl.Text = labelText
lbl.TextColor3 = Color3.fromRGB(240, 240, 248)
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 12
lbl.ZIndex = 12
lbl.Parent = row

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 84, 0, 24)
btn.Position = UDim2.new(1, -94, 0.5, -12)
btn.BackgroundColor3 = bgColor or Color3.fromRGB(205, 28, 44)
btn.Text = btnText
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 11
btn.Active = true
btn.Modal = true
btn.AutoButtonColor = false
btn.ZIndex = 15
btn.Parent = row
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
table.insert(modalButtons, btn)

trackConn(btn.MouseButton1Click:Connect(function()
closeAllDropdowns()
if callback then callback() end
end))
end

local aimPage = navPages.Aim
local espPage = navPages.ESP
local sysPage = navPages.System

local lockCard, lockSub = createCard(aimPage, "ล็อกเป้า (Aimbot)", "สถานะ: พร้อมใช้งาน", 1)
addCapsuleToggle(lockCard, "ล็อกกล้องอัตโนมัติ", "กดปุ่มล็อกค้างเพื่อติดตามเป้าหมาย", false, 1, function(enabled)
lockSub.Text = enabled and "สถานะ: เปิดโหมดล็อก" or "สถานะ: รอกดปุ่ม"
end)
addDropdown(lockCard, "LockBindRow", "ปุ่มล็อกเป้า", LockKeyOptions, findOptionLabel(LockKeyOptions, Hub.LockBind, "ปุ่ม F"), 2, function(val)
stopLockLoop()
Hub.LockBind = val
end)
addDropdown(lockCard, "AimPartRow", "จุดที่เล็ง", AimPartOptions, findOptionLabel(AimPartOptions, Hub.AimPartMode, "หัว (Head)"), 3, function(val)
Hub.AimPartMode = val
end)
addDropdown(lockCard, "PriorityRow", "ลำดับความสำคัญเป้า", PriorityOptions, findOptionLabel(PriorityOptions, Hub.TargetPriority, "ใกล้เป้าเล็ง"), 4, function(val)
Hub.TargetPriority = val
end)
addSliderRow(lockCard, "วง FOV เล็ง (พิกเซล)", " px", 50, 400, Hub.FOVRadius, 5, function(r)
Hub.FOVRadius = r
updateFovRingSize()
end)
addSliderRow(lockCard, "ระยะล็อกสูงสุด", " Studs", 50, 500, Hub.MaxLockDistance, 6, function(d)
Hub.MaxLockDistance = d
end)
addDropdown(lockCard, "SmoothRow", "ความนุ่มการเล็ง", SmoothnessOptions, findOptionLabel(SmoothnessOptions, Hub.LockSmoothness, "กลาง (0.24)"), 7, function(val)
Hub.LockSmoothness = tonumber(val) or 0.24
end)
addCapsuleToggle(lockCard, "แสดงวง FOV", "แสดงขอบเขตวงเล็งบนหน้าจอ", false, 8, function(enabled)
fovRing.Visible = enabled
end)
addCapsuleToggle(lockCard, "ล็อกเฉพาะในวง FOV", "กรองเป้าที่อยู่นอกวง FOV ออก", Hub.FovOnlyLock, 9, function(enabled)
Hub.FovOnlyLock = enabled
if enabled then fovRing.Visible = true end
saveConfig()
end)
addCapsuleToggle(lockCard, "เช็กกำแพงก่อนล็อก", "เล็งเฉพาะเป้าที่มองเห็นได้จริง", Hub.WallCheckEnabled, 10, function(enabled)
Hub.WallCheckEnabled = enabled
saveConfig()
end)
addColorRow(lockCard, "สีวง FOV", Hub.FovColor, 11, function(col)
Hub.FovColor = col
fovStroke.Color = col
end)

local espCard, espSub = createCard(espPage, "มองเห็น (ESP)", "สถานะ: พร้อมใช้งาน", 1)
addCapsuleToggle(espCard, "โครงศัตรู (Outline)", "เน้นกรอบตัวละครศัตรูทะลุกำแพง", Hub.RedOutlineEnabled, 1, function(enabled)
Hub.SetRedOutline(enabled)
espSub.Text = (Hub.RedOutlineEnabled or Hub.NametagsEnabled) and "สถานะ: เปิด ESP" or "สถานะ: ปิดอยู่"
end)
addCapsuleToggle(espCard, "แสดงชื่อ HP และระยะ", "แสดงป้ายชื่อ พลังชีวิต และระยะห่าง", Hub.NametagsEnabled, 2, function(enabled)
Hub.SetNametags(enabled)
espSub.Text = (Hub.RedOutlineEnabled or Hub.NametagsEnabled) and "สถานะ: เปิด ESP" or "สถานะ: ปิดอยู่"
end)
addCapsuleToggle(espCard, "แสดงชื่อไอเทมตามแมพ", "แสดงป้ายไอเทมและจุดเก็บในแมพ", Hub.ItemEspEnabled, 3, function(enabled)
Hub.SetItemEsp(enabled)
end)
addDropdown(espCard, "ItemDistRow", "ระยะแสดงชื่อไอเทม", ItemDistanceOptions, findOptionLabel(ItemDistanceOptions, Hub.MaxItemEspDistance, "120m"), 4, function(val)
Hub.MaxItemEspDistance = tonumber(val) or 120
scanMapItems()
end)
addColorRow(espCard, "สี ESP ศัตรู", Hub.EspColor, 5, function(col)
Hub.EspColor = col
syncEspVisualsNow()
end)
addActionRow(espCard, "ล้างและสแกน ESP ใหม่", "รีเซ็ต ESP", Color3.fromRGB(205, 28, 44), 6, function()
Hub.ResetEsp()
end)

local sysCard = createCard(sysPage, "ระบบและ Key", "เชื่อมต่อ ter-key-api + HWID", 1)
addActionRow(sysCard, "ล้าง Key ที่จำไว้และกรอกใหม่", "ล้าง Key", Color3.fromRGB(205, 28, 44), 1, function()
clearSavedKey()
unloadHub()
promptForValidKey(startMainHub)
end)
addActionRow(sysCard, "ปิดสคริปต์และลบ UI ออกจากเกม", "Unload", Color3.fromRGB(70, 22, 28), 2, function()
unloadHub()
end)

task.spawn(function()
while not isUnloading and screenGui and screenGui.Parent do
task.wait(HEARTBEAT_INTERVAL)
if isUnloading or not screenGui or not screenGui.Parent then break end
local ok, _, info = verifyKeyRemote(activeKey)
if not ok then
clearSavedKey()
unloadHub()
promptForValidKey(startMainHub)
break
elseif info and info.hoursLeft then
keyBadge.Text = "เหลือ " .. tostring(info.hoursLeft) .. " ชม."
end
end
end)
end

promptForValidKey(startMainHub)