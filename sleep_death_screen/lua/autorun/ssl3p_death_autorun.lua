SSL3P = SSL3P or {}
ssl3pLib = ssl3pLib or {}

local function Inclu(p) return include("ssl3p/" .. p) end
local function AddCS(p) return AddCSLuaFile("ssl3p/" .. p) end
local function IncAdd(p) Inclu(p) AddCS(p) end

if not ssl3pLib.RespX then
    local BASE_W, BASE_H = 1920, 1080
    function ssl3pLib.RespX(x) return math.floor((ScrW() / 1920) * (tonumber(x) or 0)) end
    function ssl3pLib.RespY(y) return math.floor((ScrH() / 1080) * (tonumber(y) or 0)) end
    local _fontCache, _weightMap = {}, { Light=300, Regular=400, Medium=500, Bold=700, Black=900 }
    local function fontKey(size, weight) return string.format("ssl3pCompat_%d_%s", size, tostring(weight or "Regular")) end
    function ssl3pLib:Font(size, weightName)
        size = tonumber(size) or 16; weightName = weightName or "Regular"
        local key = fontKey(size, weightName)
        if not _fontCache[key] then
            surface.CreateFont(key, { font = "Montserrat", size = size, weight = _weightMap[weightName] or 400, antialias = true, extended = true })
            _fontCache[key] = true
        end
        return key
    end
    function ssl3pLib.DrawMaterial(x, y, w, h, matOrPath, col)
        if not matOrPath then return end
        local mat = isstring(matOrPath) and Material(matOrPath, "smooth") or matOrPath
        surface.SetDrawColor(col or color_white) surface.SetMaterial(mat) surface.DrawTexturedRect(x, y, w, h)
    end
    function ssl3pLib:Sound(name)
        local map = { Hover = "ui/buttonrollover.wav", Click = "ui/buttonclickrelease.wav" }
        if map[name] then surface.PlaySound(map[name]) end
    end
end

IncAdd("config.lua")

if SERVER then
    AddCS("client/cl_interface.lua")
    IncAdd("server/sv_hooks.lua")

    if resource and resource.AddSingleFile then
        resource.AddSingleFile("materials/sleep_librairies/skull.png")
    end
else
    Inclu("client/cl_interface.lua")
end
