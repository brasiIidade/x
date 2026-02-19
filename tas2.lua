local cloneref = cloneref or function(o) return o end
local plrs = cloneref(game:GetService("Players"))
local ws = cloneref(game:GetService("Workspace"))
local rs = cloneref(game:GetService("RunService"))
local hs = cloneref(game:GetService("HttpService"))
local tcs = cloneref(game:GetService("TextChatService"))
local lp = cloneref(plrs.LocalPlayer)
local cam = cloneref(ws.CurrentCamera)

local env = getgenv()
local upk = table.unpack or unpack
local stEn = {}
for _, i in ipairs(Enum.HumanoidStateType:GetEnumItems()) do stEn[i.Value] = i end

local guiName = "."
local gh = gethui or function() return game:GetService("CoreGui") end
local ex = gh():FindFirstChild(guiName)
if ex then ex:Destroy() end

local ui = Instance.new("ScreenGui")
ui.Name, ui.ResetOnSpawn, ui.Parent = guiName, false, gh()

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
local fPath = "michigun.xyz/fp3_Parkours"
if writefile and not isfolder(fPath) then makefolder(fPath) end

env.TAS = env.TAS or {}
local t = env.TAS
t.Loaded, t.Selection, t.Recording, t.ReqPlay, t.RecFrames = {}, {}, false, false, {}
t.CurrentName, t.RecConn, t.IsReady, t.LastJump = "", nil, true, false
t.ActRad, t.ActH, t.ActAng = 1, 1.5, 10

local function notif(ti, m) if t.NotifyFunc then t.NotifyFunc(ti .. ": " .. m, 3, "lucide:info") end end

local function chkPlay()
    local p = false
    for _, d in pairs(t.Loaded) do if d.Playing then p = true break end end
    if t.UpdateButtonState then t.UpdateButtonState(p) end
end

local function stopMov()
    local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if h then h.AutoRotate = true h:Move(Vector3.zero) end
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    if tg then tg.Enabled = false task.delay(1, function() if tg then tg.Enabled = true end end) end
end

local function grnd(p)
    local r = ws:Raycast(p.Position, Vector3.new(0, -3.5, 0), RaycastParams.new())
    return r ~= nil
end

local function cap()
    local c = lp.Character
    local h, r = c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
    if not r or not h then return end
    return { cf = {r.CFrame:GetComponents()}, cm = {cam.CFrame:GetComponents()}, vl = {r.AssemblyLinearVelocity.X, r.AssemblyLinearVelocity.Y, r.AssemblyLinearVelocity.Z}, j = h.Jump, s = h:GetState().Value }
end

local function app(f)
    if not f then return end
    local c = lp.Character
    local h, r = c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
    if not r or not h then return end
    
    if f.cf then r.CFrame = CFrame.new(upk(f.cf)) end
    if f.vl then
        local v = Vector3.new(f.vl[1], f.vl[2], f.vl[3])
        r.AssemblyLinearVelocity = v
        h:Move(v.Magnitude > 0.5 and r.CFrame.LookVector or Vector3.zero, false)
    end
    if f.j ~= t.LastJump then if f.j then h:ChangeState(Enum.HumanoidStateType.Jumping) end t.LastJump = f.j end
    
    local s = stEn[f.s]
    if grnd(r) and math.abs(r.AssemblyLinearVelocity.Y) < 5 and s == Enum.HumanoidStateType.Freefall then s = Enum.HumanoidStateType.Running end
    if f.s == Enum.HumanoidStateType.Climbing.Value then s = Enum.HumanoidStateType.Climbing end
    if s and s ~= Enum.HumanoidStateType.Jumping and h:GetState() ~= s then h:ChangeState(s) end
    h.AutoRotate = false
end

local function visVP(pt)
    local vp, vc = Instance.new("ViewportFrame"), Instance.new("Camera")
    vp.Parent, vp.BackgroundTransparency, vp.Size, vp.ZIndex = ui, 1, UDim2.new(0, 150, 0, 150), 10
    vc.Parent = vp
    local cl = pt:Clone()
    cl.Parent, cl.Transparency, cl.Material, cl.CFrame = vp, 0, Enum.Material.Neon, CFrame.new()
    local md = math.max(cl.Size.X, cl.Size.Y, cl.Size.Z)
    vc.CFrame = CFrame.new(0, md, md * 2.5) * CFrame.Angles(math.rad(-20), math.rad(180), 0)
    
    local cn = rs.Stepped:Connect(function()
        if not pt then return end
        local pos, v = cam:WorldToScreenPoint(pt.Position)
        vp.Position, vp.Visible = UDim2.fromOffset(pos.X - 75, pos.Y - 75), v
        cl.CFrame = CFrame.Angles(0, tick() % (math.pi * 2), 0)
    end)
    return { F = vp, C = cn, P = pt }
end

local function clr(n)
    local d = t.Loaded[n]
    if not d then return end
    if d.MC then d.MC:Disconnect() end
    if d.PC then d.PC:Disconnect() end
    stopMov()
    if d.VF then d.VF:Destroy() end
    if d.VP then for _, v in ipairs(d.VP) do if v.C then v.C:Disconnect() end if v.F then v.F:Destroy() end end end
    if d.PP then for _, p in ipairs(d.PP) do if p then p:Destroy() end end end
    d.VF, d.VP, d.PP, d.W, d.P = nil, {}, {}, false, false
    chkPlay()
end

local function bLn(fs, p)
    local pts = {}
    if not fs or #fs < 2 then return pts end
    for i = 1, #fs - 1 do
        if fs[i].cf and fs[i+1].cf then
            local s, e = Vector3.new(upk(fs[i].cf)), Vector3.new(upk(fs[i+1].cf))
            local d = (e - s).Magnitude
            if d > 0.05 then
                local pt = Instance.new("CylinderHandleAdornment")
                pt.Radius, pt.Height, pt.CFrame, pt.Color3, pt.Transparency, pt.Adornee, pt.ZIndex, pt.Parent = 0.05, d, CFrame.new(s:Lerp(e, 0.5), e), Color3.fromRGB(0, 200, 255), 0.1, ws.Terrain, 0, p
                table.insert(pts, pt)
            end
        end
    end
    return pts
end

local function act(n)
    local d = t.Loaded[n]
    if not d or not d.Frames or #d.Frames == 0 or d.W or d.P then return end
    clr(n)
    d.W = true
    local sF = d.Frames[1]
    local cf = CFrame.new(upk(sF.cf))
    local ct = Instance.new("Folder")
    ct.Name, ct.Parent, d.VF = "_" .. n, gh(), ct

    local function mk(nm, sz, c, cl, tr, cyl)
        local p = cyl and Instance.new("CylinderHandleAdornment") or Instance.new("BoxHandleAdornment")
        if cyl then p.Radius, p.Height = sz.X, sz.Y else p.Size = sz end
        p.Name, p.CFrame, p.Color3, p.Transparency, p.Adornee, p.ZIndex, p.Parent = nm, c, cl, tr or 0.1, ws.Terrain, 1, ct
        return p
    end

    mk("T", Vector3.new(2, 2, 1), cf, Color3.fromRGB(0, 255, 255), 0.02)
    mk("LL", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), Color3.fromRGB(0, 255, 255), 0.02)
    mk("RL", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), Color3.fromRGB(0, 255, 255), 0.02)
    
    local dm = Instance.new("Part")
    dm.Size, dm.CFrame, dm.Transparency, dm.Anchored, dm.CanCollide = Vector3.new(2, 2, 1), cf, 1, true, false
    table.insert(d.VP, visVP(dm))
    d.PP = bLn(d.Frames, ct)

    d.MC = rs.Heartbeat:Connect(function()
        local c = lp.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local dl = r.Position - cf.Position
        local fd = Vector3.new(dl.X, 0, dl.Z).Magnitude
        if fd <= t.ActRad and math.abs(dl.Y) <= t.ActH and r.CFrame.LookVector:Dot(cf.LookVector) >= math.cos(math.rad(t.ActAng)) then
            if d.MC then d.MC:Disconnect() end
            if d.VF then d.VF:Destroy() end
            for _, v in ipairs(d.VP) do if v.C then v.C:Disconnect() end if v.F then v.F:Destroy() end end
            for _, p in ipairs(d.PP) do if p then p:Destroy() end end
            d.W, d.P = false, true
            chkPlay()
            local st = tick()
            d.PC = rs.Heartbeat:Connect(function()
                local te = tick() - st
                local idx = math.floor(te * 60) + 1
                if idx > #d.Frames then stopMov() if d.PC then d.PC:Disconnect() end d.P = false chkPlay() return end
                app(d.Frames[idx])
            end)
        end
    end)
end

t.ToggleAll = function(e)
    t.ReqPlay = e
    if e then for n in pairs(t.Loaded) do act(n) end else for n in pairs(t.Loaded) do clr(n) end stopMov() chkPlay() end
end

t.StopRecording = function()
    if not t.Recording then return end
    t.Recording = false
    if t.RecConn then t.RecConn:Disconnect() t.RecConn = nil end
    notif("TAS", string.format("Gravação parada (%.2fs)", #t.RecFrames * (1/60)))
    if main then main:Open() end
end

t.StartRecording = function()
    if t.Recording then return end
    if main then main:Close() end
    t.RecFrames, t.Recording = {}, true
    local ac, it = 0, 0
    t.RecConn = rs.Heartbeat:Connect(function(dt)
        local c = lp.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then it = r.AssemblyLinearVelocity.Magnitude < 0.2 and it + dt or 0 end
        if it >= 1 then t.StopRecording() return end
        ac = ac + dt
        while ac >= (1/60) do
            ac = ac - (1/60)
            local f = cap()
            if f then table.insert(t.RecFrames, f) end
        end
    end)
    notif("TAS", "Gravação iniciada")
end

local function onChat(m)
    m = m:lower()
    if m == "/e gravar" then t.StartRecording() elseif m == "/e parar" then t.StopRecording() end
end

if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
    tcs.OnIncomingMessage = function(m) if m.TextSource and m.TextSource.UserId == lp.UserId then onChat(m.Text) end end
else
    lp.Chatted:Connect(onChat)
end

t.GetSaved = function()
    local o = {}
    if listfiles then for _, f in ipairs(listfiles(fPath)) do if f:sub(-5) == ".json" then o[#o + 1] = f:match("([^/]+)%.json$") end end end
    return o
end

t.SaveCurrent = function()
    if not t.CurrentName or t.CurrentName == "" or #t.RecFrames == 0 then return end
    writefile(fPath .. "/" .. t.CurrentName .. ".json", hs:JSONEncode({ Version = 1, Frames = t.RecFrames }))
    return t.GetSaved()
end

t.UpdateSelection = function(sl)
    t.Selection = type(sl) ~= "table" and {sl} or sl
    local ns = {}
    for _, n in ipairs(sl) do ns[n] = true end
    for n in pairs(t.Loaded) do if not ns[n] then clr(n) t.Loaded[n] = nil end end
    for _, n in ipairs(sl) do
        if not t.Loaded[n] and n ~= "" then
            local p = fPath .. "/" .. n .. ".json"
            if isfile(p) and readfile then
                local c = hs:JSONDecode(readfile(p))
                t.Loaded[n] = { Frames = c.Frames or {}, VP = {}, PP = {}, W = false, P = false }
            end
        end
    end
    if t.ReqPlay then for n in pairs(t.Loaded) do act(n) end end
end

t.DeleteSelected = function()
    if #t.Selection == 0 then notif("TAS", "Nada selecionado.") return end
    for _, n in ipairs(t.Selection) do
        local p = fPath .. "/" .. n .. ".json"
        if isfile(p) and delfile then delfile(p) end
        clr(n)
        t.Loaded[n] = nil
    end
    t.Selection = {}
    return t.GetSaved()
end

t.ManualStopPlayback = function()
    for _, d in pairs(t.Loaded) do if d.P and d.PC then stopMov() d.PC:Disconnect() d.P = false end end
    chkPlay()
end
