SSL3P = SSL3P or {}
ssl3pLib = ssl3pLib or {}

local function Inclu(p) return include("ssl3p/" .. p) end
local function AddCS(p) return AddCSLuaFile("ssl3p/" .. p) end
local function IncAdd(p) Inclu(p) AddCS(p) end

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
