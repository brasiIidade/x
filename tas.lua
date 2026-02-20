local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local hs = cr(game:GetService("HttpService"))
local tcs = cr(game:GetService("TextChatService"))
local lp = cr(plrs.LocalPlayer)
local cam = cr(ws.CurrentCamera)

local unp = table.unpack or unpack
local stEnums = {}
for _, e in ipairs(Enum.HumanoidStateType:GetEnumItems()) do stEnums[e.Value] = e end

local gh = gethui or function() return game:GetService("CoreGui") end
if gh():FindFirstChild(".") then gh():FindFirstChild("."):Destroy() end
local ui = Instance.new("ScreenGui")
ui.Name, ui.ResetOnSpawn, ui.Parent = ".", false, gh()

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
local fDir = "michigun.xyz/tas"
if writefile and not isfolder(fDir) then makefolder(fDir) end

local env = getgenv()
env.TAS = env.TAS or {}
local tas = env.TAS

tas.Loaded = tas.Loaded or {}
tas.Selection = tas.Selection or {}
tas.Recording = false
tas.ReqPlay = false
tas.RecFrames = {}
tas.CurrentName = ""
tas.RecConn = nil
tas.IsReady = true
tas.LastJump = false
tas.ActRad = 1
tas.ActH = 1.5
tas.ActAng = 10
tas.ColorBot = Color3.fromRGB(0, 255, 0)
tas.ColorPath = Color3.fromRGB(0, 255, 0)
tas.VisualOpacity = 0

local function sNotif(t, m)
    if tas.NotifyFunc then tas.NotifyFunc(t .. ": " .. m, 3, "lucide:info") end
end

local function stpMov()
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.AutoRotate = true h:Move(Vector3.zero) end
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    if tg then 
        tg.Enabled = false 
        task.spawn(function() for i=1,10 do if tg then tg.Enabled = true end task.wait(0.1) end end)
    end
end

local function chkPlay()
    local ip = false
    for _, d in pairs(tas.Loaded) do if d.Playing then ip = true break end end
    if tas.UpdateButtonState then tas.UpdateButtonState(ip) end
end

local function capFr()
    local c = lp.Character
    local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    return { cf = {hrp.CFrame:GetComponents()}, vel = {hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z}, jump = hum.Jump, state = hum:GetState().Value }
end

local function appFr(f)
    if not f then return end
    local c = lp.Character
    local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if f.cf then hrp.CFrame = CFrame.new(unp(f.cf)) end
    if f.vel then hrp.AssemblyLinearVelocity = Vector3.new(f.vel[1], f.vel[2], f.vel[3]) end
    if f.jump ~= tas.LastJump then
        if f.jump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        tas.LastJump = f.jump
    end
    local recSt = stEnums[f.state]
    if recSt then
        if recSt ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= recSt then hum:ChangeState(recSt) end
        hum.AutoRotate = false 
    end
end

local function mkVp(pt)
    local vpf, vpc = Instance.new("ViewportFrame"), Instance.new("Camera")
    vpf.Parent, vpf.BackgroundTransparency, vpf.Size, vpf.ZIndex = ui, 1, UDim2.new(0, 150, 0, 150), 10
    vpc.Parent = vpf
    local cl = pt:Clone()
    cl.Parent, cl.Transparency, cl.Material, cl.CFrame = vpf, 0, Enum.Material.Neon, CFrame.new()
    local mx = math.max(cl.Size.X, cl.Size.Y, cl.Size.Z)
    vpc.CFrame = CFrame.new(0, mx, mx * 2.5) * CFrame.Angles(math.rad(-20), math.rad(180), 0)
    local cnn = rs.Stepped:Connect(function()
        if not pt then return end
        local ps, vs = cam:WorldToScreenPoint(pt.Position)
        vpf.Position, vpf.Visible = UDim2.fromOffset(ps.X - 75, ps.Y - 75), vs
        cl.CFrame = CFrame.Angles(0, tick() % (math.pi * 2), 0)
    end)
    return { Frame = vpf, Connection = cnn, Part = pt }
end

local function clrTas(n)
    local d = tas.Loaded[n]
    if not d then return end
    if d.MarkerConn then d.MarkerConn:Disconnect() end
    if d.PlayConn then d.PlayConn:Disconnect() end
    stpMov()
    if d.VisualFolder then d.VisualFolder:Destroy() end
    if d.Viewports then for _, v in ipairs(d.Viewports) do if v.Connection then v.Connection:Disconnect() end if v.Frame then v.Frame:Destroy() end end end
    if d.PathParts then for _, p in ipairs(d.PathParts) do if p then p:Destroy() end end end
    d.VisualFolder, d.Viewports, d.PathParts, d.Waiting, d.Playing = nil, {}, {}, false, false
    chkPlay()
end

local function bldPth(fs, pf)
    local pts = {}
    if not fs or #fs < 2 then return pts end
    for i = 1, #fs - 1 do
        if fs[i].cf and fs[i+1].cf then
            local sp, ep = Vector3.new(unp(fs[i].cf)), Vector3.new(unp(fs[i+1].cf))
            local dst = (ep - sp).Magnitude
            if dst > 0.05 then
                local pt = Instance.new("CylinderHandleAdornment")
                pt.Radius, pt.Height, pt.CFrame, pt.Color3, pt.Transparency, pt.Adornee, pt.ZIndex, pt.Parent = 0.05, dst, CFrame.new(sp:Lerp(ep, 0.5), ep), tas.ColorPath, tas.VisualOpacity, ws.Terrain, 0, pf
                table.insert(pts, pt)
            end
        end
    end
    return pts
end

local function actTas(n)
    local d = tas.Loaded[n]
    if not d or not d.Frames or #d.Frames == 0 or d.Waiting or d.Playing then return end
    clrTas(n)
    d.Waiting = true
    local cf = CFrame.new(unp(d.Frames[1].cf))
    local fldr = Instance.new("Folder")
    fldr.Name, fldr.Parent = "_" .. n, gh()
    d.VisualFolder = fldr
    local function mkM(nm, sz, c, cl, tr, isC)
        local p = isC and Instance.new("CylinderHandleAdornment") or Instance.new("BoxHandleAdornment")
        if isC then p.Radius, p.Height = sz.X, sz.Y else p.Size = sz end
        p.Name, p.CFrame, p.Color3, p.Transparency, p.Adornee, p.ZIndex, p.Parent = nm, c, cl, tr, ws.Terrain, 1, fldr
        return p
    end
    local bc, tr = tas.ColorBot, tas.VisualOpacity
    mkM("Tor", Vector3.new(2, 2, 1), cf, bc, tr, false)
    mkM("LLg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), bc, tr, false)
    mkM("RLg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), bc, tr, false)
    mkM("LAm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), bc, tr, false)
    mkM("RAm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0.5, -1) * CFrame.Angles(math.rad(90), 0, 0), bc, tr, false)
    local dm = Instance.new("Part")
    dm.Size, dm.CFrame, dm.Transparency, dm.Anchored, dm.CanCollide = Vector3.new(2, 2, 1), cf, 1, true, false
    table.insert(d.Viewports, mkVp(dm))
    d.PathParts = bldPth(d.Frames, fldr)
    d.MarkerConn = rs.Heartbeat:Connect(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dlt = hrp.Position - cf.Position
        if Vector3.new(dlt.X, 0, dlt.Z).Magnitude <= tas.ActRad and math.abs(dlt.Y) <= tas.ActH and hrp.CFrame.LookVector:Dot(cf.LookVector) >= math.cos(math.rad(tas.ActAng)) then
            if d.MarkerConn then d.MarkerConn:Disconnect() end
            if d.VisualFolder then d.VisualFolder:Destroy() end
            for _, v in ipairs(d.Viewports) do if v.Connection then v.Connection:Disconnect() end if v.Frame then v.Frame:Destroy() end end
            for _, p in ipairs(d.PathParts) do if p then p:Destroy() end end
            d.Waiting, d.Playing = false, true
            chkPlay()
            local stT = tick()
            d.PlayConn = rs.Heartbeat:Connect(function()
                local cIdx = math.floor((tick() - stT) * 60) + 1
                if cIdx > #d.Frames then stpMov() if d.PlayConn then d.PlayConn:Disconnect() end d.Playing = false chkPlay() return end
                appFr(d.Frames[cIdx])
            end)
        end
    end)
end

tas.UpdateVisuals = function(bC, pC, op)
    if bC ~= nil then tas.ColorBot = bC end
    if pC ~= nil then tas.ColorPath = pC end
    if op ~= nil then tas.VisualOpacity = op end

    for _, d in pairs(tas.Loaded) do
        if d.VisualFolder then
            for _, p in ipairs(d.VisualFolder:GetChildren()) do
                if p:IsA("BoxHandleAdornment") or p:IsA("CylinderHandleAdornment") then
                    p.Color3 = tas.ColorBot
                    p.Transparency = tas.VisualOpacity
                end
            end
        end
        if d.PathParts then
            for _, p in ipairs(d.PathParts) do
                p.Color3 = tas.ColorPath
                p.Transparency = tas.VisualOpacity
            end
        end
    end
end

tas.StopRecording = function()
    if not tas.Recording then return end
    tas.Recording = false
    if tas.RecConn then tas.RecConn:Disconnect() tas.RecConn = nil end
    sNotif("TAS", string.format("Gravação parada (%.2fs)", #tas.RecFrames * (1/60)))
end

tas.StartRecording = function()
    if tas.Recording then return end
    tas.RecFrames, tas.Recording = {}, true
    local acc, idl = 0, 0
    tas.RecConn = rs.Heartbeat:Connect(function(dt)
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then idl = hrp.AssemblyLinearVelocity.Magnitude < 0.2 and idl + dt or 0 end
        if idl >= 1 then tas.StopRecording() return end
        acc = acc + dt
        while acc >= (1/60) do acc = acc - (1/60) local f = capFr() if f then table.insert(tas.RecFrames, f) end end
    end)
    sNotif("TAS", "Gravação iniciada")
end

tas.SaveCurrent = function()
    if not tas.CurrentName or tas.CurrentName == "" or #tas.RecFrames == 0 then return end
    local rj = hs:JSONEncode({ Version = 1, Frames = tas.RecFrames })
    writefile(fDir .. "/" .. tas.CurrentName .. ".json", rj)
    tas.RecFrames = {}
    return tas.GetSaved()
end

tas.GetSaved = function()
    local out = {}
    if listfiles then for _, f in ipairs(listfiles(fDir)) do if f:sub(-5) == ".json" then out[#out + 1] = f:match("([^/]+)%.json$") end end end
    return out
end

tas.UpdateSelection = function(sL)
    tas.Selection = type(sL) ~= "table" and {sL} or sL
    for n in pairs(tas.Loaded) do local ok = false for _, v in ipairs(tas.Selection) do if v == n then ok = true break end end if not ok then clrTas(n) tas.Loaded[n] = nil end end
    task.spawn(function()
        for i, n in ipairs(tas.Selection) do
            if not tas.Loaded[n] and n ~= "" then
                local p = fDir .. "/" .. n .. ".json"
                if isfile(p) then
                    local raw = readfile(p)
                    local d = nil
                    pcall(function() d = hs:JSONDecode(raw) end)
                    
                    if d and d.Frames then 
                        tas.Loaded[n] = { Frames = d.Frames, Viewports = {}, PathParts = {}, Waiting = false, Playing = false } 
                    end 
                end
            end
            if i % 3 == 0 then task.wait() end
        end
        if tas.ReqPlay then for n in pairs(tas.Loaded) do actTas(n) end end
    end)
end

tas.DeleteSelected = function()
    if #tas.Selection == 0 then return end
    for _, n in ipairs(tas.Selection) do
        local p = fDir .. "/" .. n .. ".json"
        if isfile(p) and delfile then delfile(p) end
        clrTas(n)
        tas.Loaded[n] = nil
    end
    tas.Selection = {}
    return tas.GetSaved()
end

tas.ToggleAll = function(e)
    tas.ReqPlay = e
    if e then for n in pairs(tas.Loaded) do actTas(n) end else for n in pairs(tas.Loaded) do clrTas(n) end stpMov() chkPlay() end
end

tas.ManualStopPlayback = function()
    for _, d in pairs(tas.Loaded) do if d.Playing and d.PlayConn then stpMov() d.PlayConn:Disconnect() d.Playing = false end end
    chkPlay()
end

local function chCmd(m)
    m = m:lower()
    if m == "/e gravar" then tas.StartRecording() elseif m == "/e parar" then tas.StopRecording() end
end
if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
    tcs.OnIncomingMessage = function(m) if m.TextSource and m.TextSource.UserId == lp.UserId then chCmd(m.Text) end end
else
    lp.Chatted:Connect(chCmd)
end
