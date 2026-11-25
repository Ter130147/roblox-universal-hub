-- Universal Entrypoint with 3D Dark Red UI
local Core = require(script.Parent.core.utils)
local Config = require(script.Parent.config)
local UIModule = require(script.Parent.ui.init)
local Nametags = require(script.Parent.modules.nametags)
local LockOn = require(script.Parent.modules.lock_on)

Core.Log("Booting Universal 3D Hub...", Config.Debug)

Nametags.Init()
LockOn.BindRightClick()

local ui = UIModule.Create("UNIVERSAL 3D HUB")

ui.AddToggle("แสดงชื่อทั้งแมพ (Nametags)", true, function(enabled)
Nametags.SetEnabled(enabled)
end)

ui.AddToggle("ล็อกเป้าศัตรู (Lock-On)", false, function(enabled)
LockOn.SetActive(enabled)
end)