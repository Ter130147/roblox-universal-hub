local Utils = {}

function Utils.Log(msg, enabled)
    if enabled then
        print("[Universal] " .. tostring(msg))
    end
end

function Utils.GetHumanoid(player)
    local char = player and player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    return hum
end

return Utils