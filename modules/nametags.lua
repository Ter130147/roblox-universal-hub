local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Nametags = {}
Nametags.Enabled = false
Nametags.ActiveGuis = {}
Nametags.Connections = {}

local function createTag(player, character)
if player == LocalPlayer then return end

local head = character:WaitForChild("Head", 5)
if not head then return end

local old = head:FindFirstChild("MapNametag")
if old then old:Destroy() end

local billboard = Instance.new("BillboardGui")
billboard.Name = "MapNametag"
billboard.Adornee = head
billboard.Size = UDim2.new(0, 160, 0, 36)
billboard.StudsOffset = Vector3.new(0, 2.5, 0)
billboard.AlwaysOnTop = true
billboard.MaxDistance = 1000
billboard.Enabled = Nametags.Enabled
billboard.Parent = head

local label = Instance.new("TextLabel")
label.Name = "PlayerName"
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = player.DisplayName .. " (@" .. player.Name .. ")"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0.2
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Parent = billboard

Nametags.ActiveGuis[player] = billboard
end

local function bindPlayer(player)
if player == LocalPlayer then return end

if player.Character then
task.spawn(createTag, player, player.Character)
end

local charConn = player.CharacterAdded:Connect(function(character)
createTag(player, character)
end)

Nametags.Connections[player] = charConn
end

function Nametags.Init()
for _, player in ipairs(Players:GetPlayers()) do
bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)

Players.PlayerRemoving:Connect(function(player)
if Nametags.Connections[player] then
Nametags.Connections[player]:Disconnect()
Nametags.Connections[player] = nil
end
Nametags.ActiveGuis[player] = nil
end)
end

function Nametags.SetEnabled(state)
Nametags.Enabled = state
for _, gui in pairs(Nametags.ActiveGuis) do
if gui and gui.Parent then
gui.Enabled = state
end
end
end

return Nametags