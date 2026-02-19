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
if not isfolder(fDir) then makefolder(fDir) end

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

local function chkPlay()
    local ip = false
    for _, d in pairs(tas.Loaded) do if d.Playing then ip = true break end end
    if tas.UpdateButtonState then tas.UpdateButtonState(ip) end
end

local function stpMov()
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then h.AutoRotate = true h:Move(Vector3.zero) end
end

local function capFr()
    local c = lp.Character
    local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    return { cf = {hrp.CFrame:GetComponents()}, cam = {cam.CFrame:GetComponents()}, vel = {hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z}, jump = hum.Jump, state = hum:GetState().Value }
end

local function appFr(f)
    if not f then return end
    local c = lp.Character
    local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if f.cf then hrp.CFrame = CFrame.new(unp(f.cf)) end
    if f.vel then 
        local v = Vector3.new(f.vel[1], f.vel[2], f.vel[3])
        hrp.AssemblyLinearVelocity = v
        if v.Magnitude > 0.5 then hum:Move(hrp.CFrame.LookVector, false) else hum:Move(Vector3.zero) end
    end
    if f.jump ~= tas.LastJump then
        if f.jump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        tas.LastJump = f.jump
    end
    local recSt = stEnums[f.state]
    if recSt and recSt ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= recSt then hum:ChangeState(recSt) end
end

local function clrTas(n)
    local d = tas.Loaded[n]
    if not d then return end
    if d.MarkerConn then d.MarkerConn:Disconnect() end
    if d.PlayConn then d.PlayConn:Disconnect() end
    stpMov()
    if d.VisualFolder then d.VisualFolder:Destroy() end
    d.VisualFolder, d.Waiting, d.Playing = nil, false, false
    chkPlay()
end

local function bldPth(fs, pf)
    local pts = {}
    for i = 1, #fs - 1 do
        local sp, ep = Vector3.new(unp(fs[i].cf)), Vector3.new(unp(fs[i+1].cf))
        local dst = (ep - sp).Magnitude
        if dst > 0.05 then
            local pt = Instance.new("CylinderHandleAdornment")
            pt.Radius, pt.Height, pt.CFrame, pt.Color3, pt.Transparency, pt.Adornee, pt.ZIndex, pt.Parent = 0.05, dst, CFrame.new(sp:Lerp(ep, 0.5), ep), tas.ColorPath, tas.VisualOpacity, ws.Terrain, 0, pf
            table.insert(pts, pt)
        end
    end
    return pts
end

local function actTas(n)
    local d = tas.Loaded[n]
    if not d or d.Waiting or d.Playing then return end
    clrTas(n)
    d.Waiting = true
    local cf = CFrame.new(unp(d.Frames[1].cf))
    local fldr = Instance.new("Folder")
    fldr.Name, fldr.Parent = "_" .. n, ui
    d.VisualFolder = fldr
    local function mkM(sz, c, cl)
        local p = Instance.new("BoxHandleAdornment")
        p.Size, p.CFrame, p.Color3, p.Transparency, p.Adornee, p.ZIndex, p.Parent = sz, c, cl, tas.VisualOpacity, ws.Terrain, 1, fldr
    end
    mkM(Vector3.new(2, 2, 1), cf, tas.ColorBot)
    bldPth(d.Frames, fldr)
    d.MarkerConn = rs.Heartbeat:Connect(function()
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if (hrp.Position - cf.Position).Magnitude <= tas.ActRad then
            d.MarkerConn:Disconnect()
            fldr:Destroy()
            d.Waiting, d.Playing = false, true
            chkPlay()
            local stT = tick()
            d.PlayConn = rs.Heartbeat:Connect(function()
                local cIdx = math.floor((tick() - stT) * 60) + 1
                if cIdx > #d.Frames then clrTas(n) return end
                appFr(d.Frames[cIdx])
            end)
        end
    end)
end

tas.UpdateVisuals = function(bC, pC, op)
    if bC then tas.ColorBot = bC end
    if pC then tas.ColorPath = pC end
    if op then tas.VisualOpacity = op end
    for _, d in pairs(tas.Loaded) do
        if d.VisualFolder then
            for _, v in ipairs(d.VisualFolder:GetChildren()) do
                v.Color3 = v:IsA("BoxHandleAdornment") and tas.ColorBot or tas.ColorPath
                v.Transparency = tas.VisualOpacity
            end
        end
    end
end

tas.StartRecording = function()
    tas.RecFrames, tas.Recording = {}, true
    tas.RecConn = rs.Heartbeat:Connect(function()
        local f = capFr()
        if f then table.insert(tas.RecFrames, f) end
    end)
    sNotif("TAS", "Gravando...")
end

tas.StopRecording = function()
    tas.Recording = false
    if tas.RecConn then tas.RecConn:Disconnect() end
    sNotif("TAS", "Parado")
end

local S_KEY = "MICHIGUN.XYZ_FP3_ENVERGONHADA"
local function s_e(k, s)
    local S, j = {}, 0
    for i=0,255 do S[i]=i end
    for i=0,255 do j=(j+S[i]+k:byte((i%#k)+1))%256 S[i],S[j]=S[j],S[i] end
    local i, j, o = 0, 0, {}
    for x=1,#s do i=(i+1)%256 j=(j+S[i])%256 S[i],S[j]=S[j],S[i] table.insert(o, string.char(bit32.bxor(s:byte(x), S[(S[i]+S[j])%256]))) end
    return table.concat(o)
end
local function eh(s) return (s:gsub(".", function(c) return string.format("%02X", c:byte()) end)) end
local function dh(s) return (s:gsub("..", function(c) return string.char(tonumber(c, 16)) end)) end

tas.SaveCurrent = function()
    if #tas.RecFrames == 0 or tas.CurrentName == "" then return end
    local data = hs:JSONEncode({Frames = tas.RecFrames})
    writefile(fDir.."/"..tas.CurrentName..".json", "michigun.xyz"..eh(s_e(S_KEY, data)))
    return tas.GetSaved()
end

tas.GetSaved = function()
    local o = {}
    for _, f in ipairs(listfiles(fDir)) do table.insert(o, f:match("([^/]+)%.json$")) end
    return o
end

tas.UpdateSelection = function(sL)
    tas.Selection = type(sL) == "table" and sL or {sL}
    for n in pairs(tas.Loaded) do clrTas(n) tas.Loaded[n] = nil end
    for _, n in ipairs(tas.Selection) do
        local p = fDir.."/"..n..".json"
        if isfile(p) then
            local c = readfile(p)
            if c:sub(1,12) == "michigun.xyz" then
                local ok, d = pcall(function() return hs:JSONDecode(s_e(S_KEY, dh(c:sub(13)))) end)
                if ok then tas.Loaded[n] = {Frames = d.Frames, Playing = false} end
            end
        end
    end
end

tas.DeleteSelected = function()
    for _, n in ipairs(tas.Selection) do delfile(fDir.."/"..n..".json") clrTas(n) tas.Loaded[n] = nil end
    return tas.GetSaved()
end

tas.ToggleAll = function(v) tas.ReqPlay = v if v then for n in pairs(tas.Loaded) do actTas(n) end else for n in pairs(tas.Loaded) do clrTas(n) end end end
tas.ManualStopPlayback = function() for n in pairs(tas.Loaded) do clrTas(n) end end
