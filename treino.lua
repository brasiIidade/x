local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local hs = cr(game:GetService("HttpService"))
local tcs = cr(game:GetService("TextChatService"))
local rep = cr(game:GetService("ReplicatedStorage"))
local vim = cr(game:GetService("VirtualInputManager"))
local ts = cr(game:GetService("TweenService"))
local cg = cr(game:GetService("CoreGui"))
local uis = cr(game:GetService("UserInputService"))

local lp = cr(plrs.LocalPlayer)
local cam = cr(ws.CurrentCamera)

local unp = table.unpack or unpack
local env = getgenv()

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end

-- [[ TAS ]] --
local stEnums = {}
for _, e in ipairs(Enum.HumanoidStateType:GetEnumItems()) do stEnums[e.Value] = e end

local gh = gethui or function() return cg end
if gh():FindFirstChild(".") then gh():FindFirstChild("."):Destroy() end
local ui = Instance.new("ScreenGui")
ui.Name, ui.ResetOnSpawn, ui.Parent = ".", false, gh()

local tas_fDir = "michigun.xyz/tas"
if writefile and not isfolder(tas_fDir) then makefolder(tas_fDir) end

env.TAS = env.TAS or {}
local tas = env.TAS

tas.Loaded      = tas.Loaded or {}
tas.Selection   = tas.Selection or {}
tas.Recording   = false
tas.ReqPlay     = false
tas.RecFrames   = {}
tas.CurrentName = ""
tas.RecConn     = nil
tas.IsReady     = true
tas.LastJump    = false
tas.ActRad      = 0.8
tas.ActH        = 1.5
tas.ActAng      = 10
tas.ColorBot    = Color3.fromRGB(0, 255, 0)
tas.ColorPath   = Color3.fromRGB(0, 255, 0)
tas.VisualOpacity = 0

local function extractName(path)
    return path:match("([^/\\]+)%.json$")
end

local function filePath(name)
    return tas_fDir .. "/" .. name .. ".json"
end

local function sNotif(t, m)
    if tas.NotifyFunc then tas.NotifyFunc(t .. ": " .. m, 3, "lucide:info") end
end

local function stpMov()
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.AutoRotate = true; h:Move(Vector3.zero) end
    releaseAll()
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    if tg then
        tg.Enabled = false
        task.spawn(function() for i = 1, 10 do if tg then tg.Enabled = true end task.wait(0.1) end end)
    end
end

local function chkPlay()
    local ip = false
    for _, d in pairs(tas.Loaded) do if d.Playing then ip = true; break end end
    if tas.UpdateButtonState then tas.UpdateButtonState(ip) end
end

local keysDown = {}

local function pressKey(code)
    if not keysDown[code] then
        keysDown[code] = true
        keypress(code)
    end
end

local function releaseKey(code)
    if keysDown[code] then
        keysDown[code] = false
        keyrelease(code)
    end
end

local function releaseAll()
    for code in pairs(keysDown) do
        keysDown[code] = false
        keyrelease(code)
    end
end

local function capFr()
    local c = lp.Character
    local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
    local anims = {}
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            table.insert(anims, {
                id       = track.Animation.AnimationId,
                pos      = track.TimePosition,
                speed    = track.Speed,
                weight   = track.WeightCurrent,
            })
        end
    end

    return {
        cf    = { hrp.CFrame:GetComponents() },
        vel   = { hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z },
        jump  = hum.Jump,
        state = hum:GetState().Value,
        anims = anims,
    }
end

local function appFr(f, hrp, hum)
    if not f or not hrp or not hum then return end

    if f.cf then
        hrp.CFrame = CFrame.new(f.cf[1],f.cf[2],f.cf[3],f.cf[4],f.cf[5],f.cf[6],f.cf[7],f.cf[8],f.cf[9],f.cf[10],f.cf[11],f.cf[12])
    end
    if f.vel then hrp.AssemblyLinearVelocity = Vector3.new(f.vel[1], f.vel[2], f.vel[3]) end

    if f.jump ~= tas.LastJump then
        if f.jump then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            pressKey(0x20)
        else
            releaseKey(0x20)
        end
        tas.LastJump = f.jump
    end

    local recSt = stEnums[f.state]
    if recSt and recSt ~= Enum.HumanoidStateType.Jumping then
        if hum:GetState() ~= recSt then hum:ChangeState(recSt) end
        hum.AutoRotate = false
    end

    local vel = f.vel and Vector3.new(f.vel[1], f.vel[2], f.vel[3]) or Vector3.zero
    local hvel = Vector3.new(vel.X, 0, vel.Z)
    local moving = hvel.Magnitude > 0.1

    if moving then
        local localVel = hrp.CFrame:VectorToObjectSpace(hvel).Unit
        local fwd  = localVel.Z < -0.3
        local back = localVel.Z >  0.3
        local left = localVel.X < -0.3
        local rght = localVel.X >  0.3

        if fwd  then pressKey(0x57)  else releaseKey(0x57)  end
        if back then pressKey(0x53)  else releaseKey(0x53)  end
        if left then pressKey(0x41)  else releaseKey(0x41)  end
        if rght then pressKey(0x44)  else releaseKey(0x44)  end
    else
        releaseKey(0x57)
        releaseKey(0x53)
        releaseKey(0x41)
        releaseKey(0x44)
    end
end

local function mkVp(worldPos, sz)
    local vpf, vpc = Instance.new("ViewportFrame"), Instance.new("Camera")
    vpf.Parent, vpf.BackgroundTransparency, vpf.Size, vpf.ZIndex = ui, 1, UDim2.new(0, 150, 0, 150), 10
    vpc.Parent = vpf
    local cl = Instance.new("Part")
    cl.Size, cl.Anchored, cl.CanCollide = sz, true, false
    cl.Transparency = 0
    cl.Material     = Enum.Material.Neon
    cl.CFrame       = CFrame.new()
    cl.Parent       = vpf
    local mx = math.max(sz.X, sz.Y, sz.Z)
    vpc.CFrame = CFrame.new(0, mx, mx * 2.5) * CFrame.Angles(math.rad(-20), math.rad(180), 0)
    local active = true
    local cnn = rs.Stepped:Connect(function()
        if not active then return end
        local ps, vs = cam:WorldToScreenPoint(worldPos)
        vpf.Position = UDim2.fromOffset(ps.X - 75, ps.Y - 75)
        vpf.Visible  = vs
        cl.CFrame    = CFrame.Angles(0, tick() % (math.pi * 2), 0)
    end)
    return { Frame = vpf, Connection = cnn, Deactivate = function() active = false end }
end

local function clrTas(n, playingOnly)
    local d = tas.Loaded[n]
    if not d then return end

    if d.PlayConn then d.PlayConn:Disconnect(); d.PlayConn = nil end
    if d.Playing  then stpMov() end
    d.Playing = false

    if not playingOnly then
        if d.MarkerConn then d.MarkerConn:Disconnect(); d.MarkerConn = nil end
        if d.Adornments then
            for _, a in ipairs(d.Adornments) do if a and a.Parent then a:Destroy() end end
        end
        if d.Viewports then
            for _, v in ipairs(d.Viewports) do
                if v.Deactivate then v.Deactivate() end
                if v.Connection then v.Connection:Disconnect() end
                if v.Frame      then v.Frame:Destroy() end
            end
        end
        if d.PathParts then
            for _, p in ipairs(d.PathParts) do if p then p:Destroy() end end
        end
        d.Viewports, d.PathParts, d.Adornments, d.Waiting = {}, {}, {}, false
    end

    chkPlay()
end

local function bldPth(fs)
    local pts = {}
    if not fs or #fs < 2 then return pts end
    for i = 1, #fs - 1 do
        if fs[i].cf and fs[i+1].cf then
            local sp  = Vector3.new(fs[i].cf[1],   fs[i].cf[2],   fs[i].cf[3])
            local ep  = Vector3.new(fs[i+1].cf[1], fs[i+1].cf[2], fs[i+1].cf[3])
            local dst = (ep - sp).Magnitude
            if dst > 0.05 then
                local pt = Instance.new("CylinderHandleAdornment")
                pt.Radius       = 0.05
                pt.Height       = dst
                pt.CFrame       = CFrame.new(sp:Lerp(ep, 0.5), ep)
                pt.Color3       = tas.ColorPath
                pt.Transparency = tas.VisualOpacity
                pt.Adornee      = ws.Terrain
                pt.ZIndex       = 0
                pt.Parent       = ws.Terrain
                table.insert(pts, pt)
            end
        end
    end
    return pts
end

local function actTas(n)
    local d = tas.Loaded[n]
    if not d or not d.Frames or #d.Frames == 0 or d.Waiting or d.Playing then return end

    clrTas(n, true)
    d.Waiting = true

    local c  = d.Frames[1].cf
    local cf = CFrame.new(c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12])

    d.Adornments = {}
    local bc, tr = tas.ColorBot, tas.VisualOpacity
    local function mkM(nm, sz, c_frame, isC)
        local p = isC and Instance.new("CylinderHandleAdornment") or Instance.new("BoxHandleAdornment")
        if isC then p.Radius, p.Height = sz.X, sz.Y else p.Size = sz end
        p.Name         = nm
        p.CFrame       = c_frame
        p.Color3       = bc
        p.Transparency = tr
        p.Adornee      = ws.Terrain
        p.ZIndex       = 1
        p.Parent       = ws.Terrain
        table.insert(d.Adornments, p)
        return p
    end
    mkM("Tor", Vector3.new(2, 2, 1), cf,                                                                 false)
    mkM("LLg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2,  0),                                     false)
    mkM("RLg", Vector3.new(1, 2, 1), cf * CFrame.new( 0.5, -2,  0),                                     false)
    mkM("LAm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5,  0,  0),                                     false)
    mkM("RAm", Vector3.new(1, 2, 1), cf * CFrame.new( 1.5, 0.5, -1) * CFrame.Angles(math.rad(90),0,0), false)

    d.Viewports = {}
    table.insert(d.Viewports, mkVp(cf.Position, Vector3.new(2, 2, 1)))
    d.PathParts = bldPth(d.Frames)

    d.MarkerConn = rs.Heartbeat:Connect(function()
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dlt      = hrp.Position - cf.Position
        local horizDst = Vector3.new(dlt.X, 0, dlt.Z).Magnitude
        local vertDst  = math.abs(dlt.Y)
        local dot      = hrp.CFrame.LookVector:Dot(cf.LookVector)

        if horizDst <= tas.ActRad and vertDst <= tas.ActH and dot >= math.cos(math.rad(tas.ActAng)) then
            if d.MarkerConn then d.MarkerConn:Disconnect(); d.MarkerConn = nil end
            if d.Adornments then
                for _, a in ipairs(d.Adornments) do if a and a.Parent then a:Destroy() end end
                d.Adornments = {}
            end
            for _, v in ipairs(d.Viewports) do
                if v.Deactivate then v.Deactivate() end
                if v.Connection then v.Connection:Disconnect() end
                if v.Frame      then v.Frame:Destroy() end
            end
            for _, p in ipairs(d.PathParts) do if p then p:Destroy() end end
            d.Viewports, d.PathParts = {}, {}
            d.Waiting, d.Playing = false, true
            chkPlay()

            local stT       = tick()
            local lastC     = lp.Character
            local cachedHrp = lastC and lastC:FindFirstChild("HumanoidRootPart")
            local cachedHum = lastC and lastC:FindFirstChildOfClass("Humanoid")

            d.PlayConn = rs.Heartbeat:Connect(function()
                local currC = lp.Character
                if currC ~= lastC then
                    lastC       = currC
                    cachedHrp   = currC and currC:FindFirstChild("HumanoidRootPart")
                    cachedHum   = currC and currC:FindFirstChildOfClass("Humanoid")
                end
                local cIdx = math.floor((tick() - stT) * 60) + 1
                if cIdx > #d.Frames then
                    stpMov()
                    if d.PlayConn then d.PlayConn:Disconnect(); d.PlayConn = nil end
                    d.Playing = false
                    chkPlay()
                    return
                end
                appFr(d.Frames[cIdx], cachedHrp, cachedHum)
            end)
        end
    end)
end

tas.UpdateVisuals = function(bC, pC, op)
    if bC ~= nil then tas.ColorBot      = bC end
    if pC ~= nil then tas.ColorPath     = pC end
    if op ~= nil then tas.VisualOpacity = op end
    for _, d in pairs(tas.Loaded) do
        if d.Adornments then
            for _, p in ipairs(d.Adornments) do
                if p and p.Parent then
                    p.Color3       = tas.ColorBot
                    p.Transparency = tas.VisualOpacity
                end
            end
        end
        if d.PathParts then
            for _, p in ipairs(d.PathParts) do
                if p then
                    p.Color3       = tas.ColorPath
                    p.Transparency = tas.VisualOpacity
                end
            end
        end
    end
end

tas.StopRecording = function()
    if not tas.Recording then return end
    tas.Recording = false
    if tas.RecConn then tas.RecConn:Disconnect(); tas.RecConn = nil end
    sNotif("TAS", string.format("Gravação parada (%.2fs)", #tas.RecFrames * (1/60)))
end

tas.StartRecording = function()
    if tas.Recording then return end
    tas.RecFrames, tas.Recording = {}, true
    local acc, idl = 0, 0
    tas.RecConn = rs.Heartbeat:Connect(function(dt)
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then idl = hrp.AssemblyLinearVelocity.Magnitude < 0.2 and idl + dt or 0 end
        if idl >= 1 then tas.StopRecording(); return end
        acc = acc + dt
        while acc >= (1/60) do
            acc = acc - (1/60)
            local f = capFr()
            if f then table.insert(tas.RecFrames, f) end
        end
    end)
    sNotif("TAS", "Gravação iniciada")
end

tas.SaveCurrent = function()
    if not tas.CurrentName or tas.CurrentName == "" or #tas.RecFrames == 0 then return end
    local rj = hs:JSONEncode({ Version = 1, Frames = tas.RecFrames })
    writefile(filePath(tas.CurrentName), rj)
    tas.RecFrames = {}
    return tas.GetSaved()
end

tas.GetSaved = function()
    local out = {}
    if listfiles then
        for _, f in ipairs(listfiles(tas_fDir)) do
            local name = extractName(f)
            if name then out[#out + 1] = name end
        end
    end
    return out
end

tas.UpdateSelection = function(sL)
    tas.Selection = type(sL) ~= "table" and { sL } or sL

    for n in pairs(tas.Loaded) do
        local ok = false
        for _, v in ipairs(tas.Selection) do if v == n then ok = true; break end end
        if not ok then clrTas(n); tas.Loaded[n] = nil end
    end

    task.spawn(function()
        for i, n in ipairs(tas.Selection) do
            if n ~= "" and not tas.Loaded[n] then
                local p = filePath(n)
                if isfile(p) then
                    local raw = readfile(p)
                    local d
                    pcall(function() d = hs:JSONDecode(raw) end)
                    if d and d.Frames then
                        tas.Loaded[n] = { Frames = d.Frames, Viewports = {}, PathParts = {}, Waiting = false, Playing = false }
                    end
                end
            end
            if i % 3 == 0 then task.wait() end
        end
        if tas.ReqPlay then
            for n in pairs(tas.Loaded) do actTas(n) end
        end
    end)
end

tas.DeleteSelected = function()
    if #tas.Selection == 0 then return end
    for _, n in ipairs(tas.Selection) do
        local p = filePath(n)
        if isfile and isfile(p) and delfile then delfile(p) end
        clrTas(n)
        tas.Loaded[n] = nil
    end
    tas.Selection = {}
    return tas.GetSaved()
end

tas.ToggleAll = function(e)
    tas.ReqPlay = e
    if e then
        for n in pairs(tas.Loaded) do actTas(n) end
    else
        for n in pairs(tas.Loaded) do clrTas(n) end
        stpMov()
        chkPlay()
    end
end

tas.ManualStopPlayback = function()
    for n, d in pairs(tas.Loaded) do
        if d.Playing then
            clrTas(n, true)
        end
    end
    chkPlay()
end

local function chCmd(m)
    m = m:lower()
    if m == "/e gravar" then tas.StartRecording()
    elseif m == "/e parar" then tas.StopRecording()
    end
end
if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
    tcs.OnIncomingMessage = function(m)
        if m.TextSource and m.TextSource.UserId == lp.UserId then chCmd(m.Text) end
    end
else
    lp.Chatted:Connect(chCmd)
end


-- jjs
env.JJs = nil
_G.JJs = nil

env.JJs = env.JJs or {}
_G.JJs = env.JJs 

local jjs = env.JJs
jjs.Config = jjs.Config or {
    Running = false,
    StartValue = 1,
    EndValue = 100,
    DelayValue = 3,
    RandomDelay = false,
    RandomMin = 2.5,
    RandomMax = 4,
    JumpEnabled = false,
    SpacingEnabled = false,
    ReverseEnabled = false,
    FinishInTime = false,
    FinishTotalTime = 60,
    Suffix = "!",
    CustomSuffix = "",
    Mode = "Padrão"
}

jjs.State = {
    Running = false,
    Current = 0,
    Total = 0,
    FinishTimestamp = 0
}

local u = {[0]="zero",[1]="um",[2]="dois",[3]="três",[4]="quatro",[5]="cinco",[6]="seis",[7]="sete",[8]="oito",[9]="nove",[10]="dez",[11]="onze",[12]="doze",[13]="treze",[14]="quatorze",[15]="quinze",[16]="dezesseis",[17]="dezessete",[18]="dezoito",[19]="dezenove"}
local t = {[2]="vinte",[3]="trinta",[4]="quarenta",[5]="cinquenta",[6]="sessenta",[7]="setenta",[8]="oitenta",[9]="noventa"}
local h = {[1]="cento",[2]="duzentos",[3]="trezentos",[4]="quatrocentos",[5]="quinhentos",[6]="seiscentos",[7]="setecentos",[8]="oitocentos",[9]="novecentos"}
local ac = {["á"]="Á",["à"]="À",["ã"]="Ã",["â"]="Â",["é"]="É",["ê"]="Ê",["í"]="Í",["ó"]="Ó",["ô"]="Ô",["õ"]="Õ",["ú"]="Ú",["ç"]="Ç"}

-- RemoteChat
local RemoteChat = {}
local Connections = {}
local CurrentChannel
local InputBar = tcs:FindFirstChildOfClass("ChatInputBarConfiguration")

local ChatMethods = {
    [Enum.ChatVersion.LegacyChatService] = function(Message)
        if CurrentChannel then
            CurrentChannel:SendAsync(Message)
            return
        end
        local channels = tcs:FindFirstChild("TextChannels")
        local general = channels and channels:FindFirstChild("RBXGeneral")
        if general then
            general:SendAsync(Message)
            return
        end
        local ChatUI = lp:WaitForChild("PlayerGui", 95):FindFirstChild("Chat")
        if ChatUI then
            local ChatBar = ChatUI:FindFirstChild("ChatBar", true)
            if ChatBar then
                ChatBar:CaptureFocus()
                ChatBar.Text = Message
                ChatBar:ReleaseFocus(true)
            end
        end
    end,
    [Enum.ChatVersion.TextChatService] = function(Message)
        if CurrentChannel then
            CurrentChannel:SendAsync(Message)
        end
    end,
}

function RemoteChat:Send(Message)
    pcall(ChatMethods[tcs.ChatVersion], Message)
end

if InputBar then
    if typeof(InputBar.TargetTextChannel) == "Instance" and InputBar.TargetTextChannel:IsA("TextChannel") then
        CurrentChannel = InputBar.TargetTextChannel
    end
    table.insert(Connections, InputBar.Changed:Connect(function(Prop)
        if Prop == "TargetTextChannel" and typeof(InputBar.TargetTextChannel) == "Instance" and InputBar.TargetTextChannel:IsA("TextChannel") then
            CurrentChannel = InputBar.TargetTextChannel
        end
    end))
end

local function sc(m)
    RemoteChat:Send(tostring(m))
end

-- Extenso
local function up(s)
    local r = ""
    for _, c in utf8.codes(s) do
        local ch = utf8.char(c)
        r = r .. (ac[ch] or string.upper(ch))
    end
    return r
end

local function ph(n)
    if n == 0 then return "" end
    if n == 100 then return "cem" end
    local hv = math.floor(n / 100)
    local rv = n % 100
    local p = {}
    if hv > 0 then table.insert(p, h[hv]) end
    if rv > 0 then
        if #p > 0 then table.insert(p, "e") end
        if rv < 20 then
            table.insert(p, u[rv])
        else
            table.insert(p, t[math.floor(rv/10)])
            local uv = rv % 10
            if uv > 0 then 
                table.insert(p, "e")
                table.insert(p, u[uv]) 
            end
        end
    end
    return table.concat(p, " ")
end

local function nt(n)
    n = tonumber(n)
    if not n or n == 0 then return n == 0 and "ZERO" or "N/A" end
    local g, x = {}, {}
    local temp = n
    while temp > 0 do
        table.insert(g, temp % 1000)
        temp = math.floor(temp / 1000)
    end
    for i = #g, 1, -1 do
        local v = g[i]
        if v ~= 0 then
            local txt = ph(v)
            if i == 2 then txt = (v == 1 and "mil" or txt .. " mil")
            elseif i == 3 then txt = (v == 1 and "um milhão" or txt .. " milhões")
            elseif i == 4 then txt = (v == 1 and "um bilhão" or txt .. " bilhões")
            elseif i == 5 then txt = (v == 1 and "um trilhão" or txt .. " trilhões") end
            table.insert(x, txt)
        end
    end
    return up(table.concat(x, " e "))
end

local function gc()
    local c = lp.Character
    return (c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart")) and c or nil
end

local function aj()
    local c = gc()
    if c then
        local hum = c.Humanoid
        if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function as()
    local c = gc()
    if not c then return end
    local h, r = c.Humanoid, c.HumanoidRootPart
    h.AutoRotate = false
    local nv = Instance.new("NumberValue")
    local tw = ts:Create(nv, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Value = 360 * (math.random(1,2)==1 and 1 or -1)})
    local b = r.CFrame.Rotation
    local cn
    cn = rs.Heartbeat:Connect(function()
        if r and r.Parent then
            r.CFrame = CFrame.new(r.Position) * b * CFrame.Angles(0, math.rad(nv.Value), 0)
        else
            cn:Disconnect()
        end
    end)
    tw.Completed:Connect(function()
        cn:Disconnect()
        nv:Destroy()
        if h then h.AutoRotate = true end
    end)
    tw:Play()
end

jjs.Start = function()
    local c = jjs.Config
    if c.Running then return end
    c.Running = true

    task.spawn(function()
        local s = tonumber(c.StartValue) or 1
        local e = tonumber(c.EndValue) or 100
        local dir = (c.ReverseEnabled and s < e) and -1 or 1
        if c.ReverseEnabled then s, e = e, s end

        local currentMode = c.Mode
        if currentMode == "Padrão" and rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos") then
            currentMode = "JJ (Delta)"
        end

        local tot = math.abs(e - s) + 1
        local cnt = 0
        local ft = c.FinishInTime and ((tonumber(c.FinishTotalTime) or 60) / math.max(1, tot)) or nil

        jjs.State.Running = true
        jjs.State.Total = tot
        jjs.State.Current = 0

        local dt = nil
        if currentMode == "JJ (Delta)" then
            local ch = gc()
            if ch then
                local a = Instance.new("Animation")
                a.AnimationId = "rbxassetid://105471471504794"
                dt = ch.Humanoid:LoadAnimation(a)
                dt.Priority = Enum.AnimationPriority.Action
            end
            local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
            if rm then pcall(function() rm:FireServer("Prepare") rm:FireServer("Start") end) end
        end

        for i = s, e, dir do
            if not c.Running then break end
            cnt = cnt + 1
            jjs.State.Current = i

            local delay = ft or (c.RandomDelay and (math.random(c.RandomMin * 10, c.RandomMax * 10) / 10) or (tonumber(c.DelayValue) or 3))
            jjs.State.FinishTimestamp = tick() + ((tot - cnt) * delay)

            local txt = nt(i)
            local sf = (c.CustomSuffix ~= "") and c.CustomSuffix or c.Suffix
            local fn = c.SpacingEnabled and (txt .. " " .. sf) or (txt .. sf)

            if currentMode == "JJ (Delta)" then
                local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
                if rm then pcall(function() rm:FireServer("Add", 1) end) end
                if dt then dt:Play() end
            elseif currentMode == "Canguru" then
                sc(fn)
                task.wait(0.2)
                pcall(function()
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                    task.wait(0.2)
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                end)
                task.wait(0.1)
                aj()
                task.wait(0.2)
                as()
            else
                sc(fn)
                if c.JumpEnabled then aj() end
            end

            if i ~= e then task.wait(delay) end
        end

        c.Running = false
        jjs.State.Running = false
        if dt then dt:Stop() end
    end)
end

jjs.Stop = function()
    jjs.Config.Running = false
    jjs.State.Running = false
end

-- [[ F3X ]] --
env.F3X = env.F3X or {}
local f3x = env.F3X

f3x.Enabled = false
f3x.SelectedParts = {}
f3x.Highlights = {}
f3x.UndoStack = {}
f3x.RedoStack = {}
f3x.ModifiedParts = {}
f3x.UpdateUI = nil
f3x.NotifyFunc = nil
f3x.IsReady = true

local f3x_fDir = "michigun.xyz/f3x"
if writefile and not isfolder(f3x_fDir) then makefolder(f3x_fDir) end

local hlParent
local function getHlParent()
    if hlParent then return hlParent end
    local s, t = pcall(function() return gethui() end)
    hlParent = (s and t) and t or cg
    return hlParent
end

local function clrHl()
    for _, h in ipairs(f3x.Highlights) do if h then h:Destroy() end end
    table.clear(f3x.Highlights)
end

local function mkHl(p)
    task.defer(function()
        if not p or not p.Parent then return end
        local h = Instance.new("Highlight")
        h.Name = hs:GenerateGUID(false)
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = Color3.fromRGB(0, 255, 255)
        h.Adornee = p
        h.Parent = getHlParent()
        table.insert(f3x.Highlights, h)
    end)
end

f3x.ClearSelection = function()
    table.clear(f3x.SelectedParts)
    clrHl()
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

local function pushU()
    local s = {}
    for _, p in ipairs(f3x.SelectedParts) do s[p] = p.Size end
    table.insert(f3x.UndoStack, s)
    table.clear(f3x.RedoStack)
end

f3x.ApplySize = function(v)
    if #f3x.SelectedParts == 0 then return end
    pushU()
    for _, p in ipairs(f3x.SelectedParts) do
        p.Size = v
        f3x.ModifiedParts[p] = v
    end
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.Undo = function()
    local s = table.remove(f3x.UndoStack)
    if not s then return end
    local r = {}
    for p, sz in pairs(s) do
        r[p] = p.Size
        p.Size = sz
        f3x.ModifiedParts[p] = sz
    end
    table.insert(f3x.RedoStack, r)
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.Redo = function()
    local s = table.remove(f3x.RedoStack)
    if not s then return end
    local u = {}
    for p, sz in pairs(s) do
        u[p] = p.Size
        p.Size = sz
        f3x.ModifiedParts[p] = sz
    end
    table.insert(f3x.UndoStack, u)
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.ListConfigs = function()
    local o = {}
    if listfiles then for _, f in ipairs(listfiles(f3x_fDir)) do if f:sub(-5) == ".json" then o[#o + 1] = f:match("([^/]+)%.json$") end end end
    return o
end

f3x.SaveConfig = function(n)
    if not n or n == "" then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Nome inválido", 3, "lucide:alert-circle") end return nil end
    local d = { PlaceId = game.PlaceId, Parts = {} }
    for p, sz in pairs(f3x.ModifiedParts) do
        if p and p.Parent then
            d.Parts[#d.Parts + 1] = { Path = p:GetFullName(), CFrame = { p.CFrame:GetComponents() }, Size = { sz.X, sz.Y, sz.Z } }
        end
    end
    local rj = hs:JSONEncode(d)
    writefile(f3x_fDir .. "/" .. n .. ".json", rj)
    return f3x.ListConfigs()
end

local function getObj(path)
    local segs = {}
    for s in path:gmatch("[^%.]+") do table.insert(segs, s) end
    local cur = game
    for _, s in ipairs(segs) do
        if s ~= "Game" then
            cur = cur:FindFirstChild(s)
            if not cur then return nil end
        end
    end
    return cur
end

f3x.ApplyConfig = function(n)
    if not n then return end
    local p = f3x_fDir .. "/" .. n .. ".json"
    if not isfile(p) then return end
    local c = readfile(p)
    local d = nil
    
    pcall(function() d = hs:JSONDecode(c) end)

    if not d then return end
    if d.PlaceId ~= game.PlaceId then 
        if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Config de outro mapa", 3, "lucide:alert-circle") end 
        return 
    end

    for _, v in ipairs(d.Parts or {}) do
        local targetCf = CFrame.new(unp(v.CFrame))
        local foundPart = nil

        local obj = getObj(v.Path)
        if obj and obj:IsA("BasePart") and (obj.Position - targetCf.Position).Magnitude < 2 then
            foundPart = obj
        else
            for _, o in ipairs(ws:GetDescendants()) do
                if o:IsA("BasePart") and o:GetFullName() == v.Path then
                    if (o.Position - targetCf.Position).Magnitude < 2 then
                        foundPart = o
                        break
                    end
                end
            end
        end
        
        if foundPart then
            foundPart.Size = Vector3.new(unp(v.Size))
            f3x.ModifiedParts[foundPart] = foundPart.Size
        end
    end
end

f3x.DeleteConfig = function(n)
    if not n then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Nenhuma seleção", 3, "lucide:alert-circle") end return nil end
    delfile(f3x_fDir .. "/" .. n .. ".json")
    return f3x.ListConfigs()
end

f3x.Toggle = function(s)
    f3x.Enabled = s
    if not s then f3x.ClearSelection() end
end

local f3xMouseConn
if lp then
    local ms = lp:GetMouse()
    f3xMouseConn = ms.Button1Down:Connect(function()
        if not f3x.Enabled then return end
        local t = ms.Target
        if not t or not t:IsA("BasePart") then return end
        
        for i, p in ipairs(f3x.SelectedParts) do
            if p == t then
                table.remove(f3x.SelectedParts, i)
                clrHl()
                for _, sp in ipairs(f3x.SelectedParts) do mkHl(sp) end
                if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
                return
            end
        end
        
        if #f3x.SelectedParts > 0 then
            local ref = f3x.SelectedParts[1].Size
            local ts = t.Size
            if math.abs(ref.X - ts.X) > 1 or math.abs(ref.Y - ts.Y) > 1 or math.abs(ref.Z - ts.Z) > 1 then
                return
            end
        end
        
        table.insert(f3x.SelectedParts, t)
        mkHl(t)
        if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
    end)
end

-- [[ ChatGPT / IA ]] --
local HttpRequest = request or http and http.request or http_request or syn and syn.request

_G.ChatGPT = _G.ChatGPT or {}
_G.ChatGPT.History = {}
_G.ChatGPT.LastMessage = ""

local PromptPath = "michigun.xyz/IA.txt"
if not isfile(PromptPath) then writefile(PromptPath, "Você é uma IA útil dentro do Roblox.") end

local Personality = readfile(PromptPath)
_G.ChatGPT.History = {{role = "system", content = Personality}}

local function extractLuaCode(responseText)
    local luaCode = responseText:match("```lua\n?(.-)```") or responseText:match("```\n?(.-)```")
    if luaCode then
        local cleanText = responseText:gsub("```lua\n?.-```", ""):gsub("```\n?.-```", "")
        return luaCode, cleanText
    end
    return nil, responseText
end

_G.ChatGPT.Ask = function(promptText)
    table.insert(_G.ChatGPT.History, {role = "user", content = promptText})

    local success, response = pcall(function()
        return HttpRequest({
            Url = "https://text.pollinations.ai/openai",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = hs:JSONEncode({
                messages = _G.ChatGPT.History,
                model = "openai"
            })
        })
    end)

    if not success or not response then
        return "Erro de conexão com a API.", nil
    end

    local aiText = ""
    local decodeSuccess, decoded = pcall(function() return hs:JSONDecode(response.Body) end)
    
    if decodeSuccess and decoded.choices and decoded.choices[1] then
        aiText = decoded.choices[1].message.content
    else
        aiText = response.Body
    end

    local luaCode, cleanMessage = extractLuaCode(aiText)

    _G.ChatGPT.LastMessage = cleanMessage
    table.insert(_G.ChatGPT.History, {role = "assistant", content = aiText})

    return cleanMessage, luaCode
end

_G.ChatGPT.SendToChat = function(msg)
    if not msg or msg == "" then return end
    
    local msgString = tostring(msg)
    
    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
        local channels = tcs:WaitForChild("TextChannels", 2)
        if channels then
            local target = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildOfClass("TextChannel")
            if target then
                target:SendAsync(msgString)
            end
        end
    else
        local events = rep:FindFirstChild("DefaultChatSystemChatEvents")
        if events then
            local say = events:FindFirstChild("SayMessageRequest")
            if say then
                say:FireServer(msgString, "All")
            end
        end
    end
end