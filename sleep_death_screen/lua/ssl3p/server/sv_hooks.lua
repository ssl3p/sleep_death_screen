util.AddNetworkString("open_ds")
util.AddNetworkString("close_ds")
util.AddNetworkString("action_ds")

local CFG = SSL3P and SSL3P.Config or {}
local TIMER = SSL3P.Config.Timer

local function OpenFor(ply, remaining)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local now = CurTime()
    local dur = math.max(0, tonumber(remaining or TIMER) or 0)
    ply._SSL3PUnlock = now + dur
    net.Start("open_ds")
        net.WriteUInt(math.Clamp(dur, 0, 65535), 16)
    net.Send(ply)
end

local function CloseFor(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("close_ds")
    net.Send(ply)
end

hook.Add("PlayerDeath", "ds_open", function(victim, inflictor, attacker)
    timer.Simple(0, function() 
        if IsValid(victim) then OpenFor(victim, TIMER) end
    end)
end)

hook.Add("CanPlayerSuicide", "ds_blocksuicide", function(ply)
    local unlock = ply._SSL3PUnlock or 0
    if CurTime() < unlock then return false end
end)

hook.Add("PlayerDeathThink", "ds_blockthink", function(ply)
    local unlock = ply._SSL3PUnlock or 0
    if CurTime() < unlock then
        return false
    end
end)

hook.Add("PlayerSpawn", "ds_close", function(ply)
    local unlock = ply._SSL3PUnlock or 0
    if CurTime() < unlock then

        CloseFor(ply)
        ply._SSL3PUnlock = nil
        return
    else
        CloseFor(ply)
        ply._SSL3PUnlock = nil
    end
end)

net.Receive("action_ds", function(len, ply)
    if not IsValid(ply) then return end
    local action = net.ReadString() or ""

    if action == "respawn" then

        local unlock = ply._SSL3PUnlock or 0
        if CurTime() >= unlock then
            if not ply:Alive() then ply:Spawn() end
            CloseFor(ply)
        else

        end
    elseif action == "timeout" then

    elseif action == "face" then
        CloseFor(ply)
    end
end)
