util.AddNetworkString("ssl3p_death_open")
util.AddNetworkString("ssl3p_death_close")
util.AddNetworkString("ssl3p_death_action")

local CFG = ssl3pDeath and ssl3pDeath.Config or {}
local TIMER = ssl3pDeath.Config.Timer

local function OpenFor(ply, remaining)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local now = CurTime()
    local dur = math.max(0, tonumber(remaining or TIMER) or 0)
    ply._ssl3pDeathUnlock = now + dur
    net.Start("ssl3p_death_open")
        net.WriteUInt(math.Clamp(dur, 0, 65535), 16)
    net.Send(ply)
end

local function CloseFor(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("ssl3p_death_close")
    net.Send(ply)
end

hook.Add("PlayerDeath", "ssl3p_deathscreen_open", function(victim, inflictor, attacker)
    timer.Simple(0, function() 
        if IsValid(victim) then OpenFor(victim, TIMER) end
    end)
end)

hook.Add("CanPlayerSuicide", "ssl3p_deathscreen_blocksuicide", function(ply)
    local unlock = ply._ssl3pDeathUnlock or 0
    if CurTime() < unlock then return false end
end)

hook.Add("PlayerDeathThink", "ssl3p_deathscreen_blockthink", function(ply)
    local unlock = ply._ssl3pDeathUnlock or 0
    if CurTime() < unlock then
        return false
    end
end)

hook.Add("PlayerSpawn", "ssl3p_deathscreen_close", function(ply)
    local unlock = ply._ssl3pDeathUnlock or 0
    if CurTime() < unlock then

        CloseFor(ply)
        ply._ssl3pDeathUnlock = nil
        return
    else
        CloseFor(ply)
        ply._ssl3pDeathUnlock = nil
    end
end)

net.Receive("ssl3p_death_action", function(len, ply)
    if not IsValid(ply) then return end
    local action = net.ReadString() or ""

    if action == "respawn" then

        local unlock = ply._ssl3pDeathUnlock or 0
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
