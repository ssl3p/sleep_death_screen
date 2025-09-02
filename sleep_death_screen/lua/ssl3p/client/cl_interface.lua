ssl3pLib = ssl3pLib or {}

if not ssl3pLib.RespX then
    local BASE_W, BASE_H = 1920, 1080

    function ssl3pLib.RespX(x)
        return math.floor((ScrW() / BASE_W) * (tonumber(x) or 0))
    end

    function ssl3pLib.RespY(y)
        return math.floor((ScrH() / BASE_H) * (tonumber(y) or 0))
    end

    local _fontCache, _weightMap = {}, { Light = 300, Regular = 400, Medium = 500, Bold = 700, Black = 900 }

    local function fontKey(size, weight)
        return string.format("ssl3pCompat_%d_%s", size, tostring(weight or "Regular"))
    end

    function ssl3pLib:Font(size, weightName)
        size = tonumber(size) or 16
        weightName = weightName or "Regular"
        local key = fontKey(size, weightName)
        if not _fontCache[key] then
            surface.CreateFont(key, {
                font = "Montserrat",
                size = size,
                weight = _weightMap[weightName] or 400,
                antialias = true,
                extended = true,
            })
            _fontCache[key] = true
        end
        return key
    end

    function ssl3pLib.DrawMaterial(x, y, w, h, matOrPath, col)
        if not matOrPath then return end
        local mat = isstring(matOrPath) and Material(matOrPath, "smooth") or matOrPath
        surface.SetDrawColor(col or color_white)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(x, y, w, h)
    end

    function ssl3pLib:Sound(name)
        local map = { Hover = "common/NULL.wav", Click = "ssl3p/click.wav" }
        if map[name] then surface.PlaySound(map[name]) end
    end
end

local PRX, PRY = ssl3pLib.RespX, ssl3pLib.RespY
local CFG = ssl3pDeath and ssl3pDeath.Config or {}

local C = {
    Primary = Color(0, 160, 255),
    PrimaryDim = Color(0, 120, 210),
    BG = Color(15, 17, 22, 230),
    Panel = Color(25, 27, 32, 255),
    PanelInner = Color(18, 20, 26, 255),
    Text = Color(240, 244, 255, 255),
    Muted = Color(160, 175, 195, 255),
    Shadow = Color(0, 0, 0, 180)
}

local PANEL_BLUR = Material("pp/blurscreen")
local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(PANEL_BLUR)
    for i = 1, 3 do
        PANEL_BLUR:SetFloat("$blur", (i / 3) * (amount or 6))
        PANEL_BLUR:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end
end

local skullMat
local function GetSkull()
    if not skullMat then skullMat = Material(CFG.SkullPath or "sleep_librairies/skull.png", "smooth") end
    return skullMat
end

ssl3pDeath = ssl3pDeath or {}
ssl3pDeath.UI = ssl3pDeath.UI or {}

local function CreateDigit(w, h)
    local pnl = vgui.Create("Panel")
    pnl:SetSize(w, h)
    pnl.Paint = function(s, pw, ph)
        draw.RoundedBox(PRX(8), 0, 0, pw, ph, C.Panel)
        draw.RoundedBox(PRX(8), PRX(3), PRY(3), pw - PRX(6), ph - PRY(6), C.PanelInner)
        if s.Value ~= nil then
            draw.SimpleText(tostring(s.Value), ssl3pLib:Font(math.min(PRY(48), pw*0.8), "Bold"), pw/2, ph/2, C.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    return pnl
end

local function secondsToHMS(total)
    total = math.max(0, math.floor(total or 0))
    local m = math.floor(total / 60)
    local s = total % 60
    return m, s
end

local function SetDigits(dM1,dM2,dS1,dS2, secs)
    local m, s = secondsToHMS(secs)
    local m1, m2 = math.floor(m / 10), m % 10
    local s1, s2 = math.floor(s / 10), s % 10
    dM1.Value, dM2.Value = m1, m2
    dS1.Value, dS2.Value = s1, s2
end

local function OpenDeathScreen(duration)
    if IsValid(ssl3pDeath.UI.Frame) then ssl3pDeath.UI.Frame:Remove() end

    local frame = vgui.Create("EditablePanel")
    ssl3pDeath.UI.Frame = frame
    frame:SetSize(ScrW(), ScrH())
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame.Paint = function(s, w, h)
        if CFG.EnableBlur ~= false then DrawBlur(s, 6) end
        surface.SetDrawColor(0,0,255,10)
        surface.DrawRect(0, 0, w, h)
    end

    local cont = vgui.Create("Panel", frame)
    cont:SetSize(PRX(900), PRY(600))
    cont:Center()
    cont.Paint = function(s, w, h)
        local mat = GetSkull()
        if mat and not mat:IsError() then
            local iw, ih = PRX(200), PRY(200)
            ssl3pLib.DrawMaterial((w - iw) / 2, PRY(0), iw, ih, mat, color_white)
        end

        local title = (CFG.Title or "YOU ARE") .. " "
        local highlight = (CFG.Highlight or "UNCONSCIOUS")
        local fTitle = ssl3pLib:Font(58, "Black")
        surface.SetFont(fTitle)
        local tw1, _ = surface.GetTextSize(title)
        local tw2, _ = surface.GetTextSize(highlight)
        local total = tw1 + tw2
        local startX = (w - total) / 2
        draw.SimpleText(title, fTitle, startX, PRY(210), C.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(highlight, fTitle, startX + tw1, PRY(210), C.Primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local fSub = ssl3pLib:Font(22, "Medium")
        surface.SetFont(fSub)
        local sub = CFG.Subtitle or ""
        local sw, _ = surface.GetTextSize(sub)
        draw.SimpleText(sub, fSub, (w - sw) / 2, PRY(270), C.Muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local digits = vgui.Create("Panel", cont)
    local spacing = PRX(10)
    local dw, dh = PRX(70), PRY(90)
    local totalW = (dw * 4) + (spacing * 3) + PRX(55) -- MM : SS
    digits:SetSize(totalW, dh)
    digits:SetPos((cont:GetWide() - totalW) / 2, PRY(320))

    local x = 0
    local dM1 = CreateDigit(dw, dh); dM1:SetParent(digits); dM1:SetPos(x, 0); x = x + dw + spacing
    local dM2 = CreateDigit(dw, dh); dM2:SetParent(digits); dM2:SetPos(x, 0); x = x + dw
    local colon = vgui.Create("Panel", digits); colon:SetSize(PRX(20), dh); colon:SetPos(x + spacing, 0); x = x + spacing + PRX(20) + spacing
    colon.Paint = function(s, w, h)
        draw.SimpleText(":", ssl3pLib:Font(48, "Bold"), w/2, h/2 - PRY(4), C.Muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local dS1 = CreateDigit(dw, dh); dS1:SetParent(digits); dS1:SetPos(x, 0); x = x + dw + spacing
    local dS2 = CreateDigit(dw, dh); dS2:SetParent(digits); dS2:SetPos(x, 0)

    local btns = vgui.Create("Panel", cont)
    btns:SetSize(PRX(380), PRY(95))
    btns:SetPos((cont:GetWide() - btns:GetWide()) / 2, PRY(430))

    local function StyledButton(parent, label, icon, cb)
        local b = vgui.Create("DButton", parent)
        b:SetSize(PRX(360), PRY(44))
        b:SetText("")
        b.Paint = function(s, w, h)
            if s:IsHovered() then
                draw.RoundedBox(PRX(8), 0, 0, w, h, C.Primary)
                draw.RoundedBox(PRX(8), PRX(2), PRY(2), w-PRX(4), h-PRY(4), C.PanelInner)
            else
                draw.RoundedBox(PRX(8), 0, 0, w, h, C.Panel)
            end
            draw.SimpleText(icon .. "  " .. label, ssl3pLib:Font(20, "Bold"), PRX(14), h/2, C.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        b.OnCursorEntered = function() ssl3pLib:Sound("Hover") end
        b.DoClick = function(s) ssl3pLib:Sound("Click"); if cb then cb(s) end end
        return b
    end

    local bRespawn = StyledButton(btns, "RESPAWN", "", function(btn)
        if not btn:IsEnabled() then return end
        net.Start("ssl3p_death_action"); net.WriteString("respawn"); net.SendToServer()
    end)
    bRespawn:SetPos(0, 0)
    bRespawn:SetEnabled(false)

    local bFace = StyledButton(btns, "FAIRE UN TICKET", "", function()
        local cmd = (ssl3pDeath and ssl3pDeath.Config and ssl3pDeath.Config.TicketCommand) or "!report"
        if cmd and cmd ~= "" then
            LocalPlayer():ConCommand("say " .. cmd)
        end
    end)
    bFace:SetPos(0, PRY(50))

    frame.Remaining = tonumber(duration) or 0
    SetDigits(dM1,dM2,dS1,dS2, frame.Remaining)

    frame.Think = function(s)
        if not s.NextTick or CurTime() >= s.NextTick then
            s.NextTick = CurTime() + 1
            s.Remaining = math.max(0, (s.Remaining or 0) - 1)
            SetDigits(dM1,dM2,dS1,dS2, s.Remaining)
            if s.Remaining <= 0 then
                if not bRespawn:IsEnabled() then bRespawn:SetEnabled(true) end
                if not s.TimeoutSent then
                    s.TimeoutSent = true
                    net.Start("ssl3p_death_action"); net.WriteString("timeout"); net.SendToServer()
                end
            end
        end
    end
end

net.Receive("ssl3p_death_open", function()
    local duration = net.ReadUInt(16)
    OpenDeathScreen(duration)
end)

net.Receive("ssl3p_death_close", function()
    if IsValid(ssl3pDeath.UI.Frame) then ssl3pDeath.UI.Frame:Remove() end
end)
