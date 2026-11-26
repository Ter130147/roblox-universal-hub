local baseUrl = "https://raw.githubusercontent.com/Ter130147/roblox-universal-hub/main/standalone.lua"
local okTime, nowVal = pcall(function() return tick() end)
local url = (okTime and nowVal) and (baseUrl .. "?t=" .. tostring(nowVal)) or baseUrl
local okFetch, body = pcall(function() return game:HttpGet(url) end)
if not okFetch or not body or body == "" then
body = game:HttpGet(baseUrl)
end
loadstring(body)()