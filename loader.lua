-- Universal Entrypoint
local Core = require(script.Parent.core.utils)
local Config = require(script.Parent.config)
local Nametags = require(script.Parent.modules.nametags)

Core.Log("Booting universal module...", Config.Debug)

Nametags.Init()
Nametags.SetEnabled(true)