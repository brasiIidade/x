local cloneref = cloneref or function(o) return o end
local plrs = cloneref(game:GetService("Players"))
local cg = cloneref(game:GetService("CoreGui"))
local rs = cloneref(game:GetService("RunService"))
local hs = cloneref(game:GetService("HttpService"))
local lp = cloneref(plrs.LocalPlayer)

local env = getgenv()
env.espConns = env.espConns or {}
env.espStore = env.espStore or {}
env.espHold = env.espHold or nil

env.ESPConfig = env.ESPConfig or {
    Enabled = false,
    TeamCheck = false,
    Chams = false,
    Name = false,
    Studs = false,
    Health = false,
    WeaponN = false
}

local function getHold()
    if not env.espHold then
        local h = Instance.new("Folder")
        h.Name = hs:GenerateGUID(false)
        local s, t = pcall(gethui)
        h.Parent = (s and t) and t or cg
        env.espHold = h
    end
    return env.espHold
end

local function mkLbl(p, o, c, s)
    local l = Instance.new("TextLabel")
    l.Parent, l.BackgroundTransparency, l.Size, l.TextColor3, l.TextStrokeTransparency, l.TextStrokeColor3, l.Font, l.TextSize, l.LayoutOrder, l.Visible = p, 1, UDim2.new(1, 0, 0, s or 12), c or Color3.new(1, 1, 1), 0.2, Color3.new(0, 0, 0), Enum.Font.GothamBold, s or 12, o, false
    return l
end

local function add(p)
    if p == lp or env.espStore[p] then return end
    local h = getHold()
    local c = { hl = Instance.new("Highlight"), bb = Instance.new("BillboardGui"), lbls = {} }

    c.hl.Name, c.hl.FillColor, c.hl.OutlineColor, c.hl.FillTransparency, c.hl.OutlineTransparency, c.hl.DepthMode, c.hl.Enabled, c.hl.Parent = hs:GenerateGUID(false), Color3.new(1, 0, 0), Color3.new(1, 1, 1), 0.6, 0, Enum.HighlightDepthMode.AlwaysOnTop, false, h
    c.bb.Name, c.bb.Size, c.bb.StudsOffset, c.bb.AlwaysOnTop, c.bb.Enabled, c.bb.Parent = hs:GenerateGUID(false), UDim2.new(0, 200, 0, 60), Vector3.new(0, 2, 0), true, false, h

    local ly = Instance.new("UIListLayout")
    ly.Parent, ly.SortOrder, ly.HorizontalAlignment, ly.Padding = c.bb, Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, UDim.new(0, 0)

    c.lbls.n = mkLbl(c.bb, 1, Color3.new(1, 1, 1), 13)
    c.lbls.h = mkLbl(c.bb, 2, Color3.fromRGB(0, 255, 100), 11)
    c.lbls.w = mkLbl(c.bb, 3, Color3.fromRGB(200, 200, 200), 11)
    c.lbls.s = mkLbl(c.bb, 4, Color3.fromRGB(255, 220, 0), 11)

    env.espStore[p] = c
end

local function rem(p)
    local c = env.espStore[p]
    if c then
        if c.hl then c.hl:Destroy() end
        if c.bb then c.bb:Destroy() end
        env.espStore[p] = nil
    end
end

local function upd()
    local cfg = env.ESPConfig
    local lchar = lp.Character
    local lhrp = lchar and lchar:FindFirstChild("HumanoidRootPart")

    for p, c in pairs(env.espStore) do
        if not p or not p.Parent then rem(p) continue end

        local char = p.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local head = char and char:FindFirstChild("Head")

        if not (char and hrp and hum and hum.Health > 0 and head) or (cfg.TeamCheck and lp.Team and p.Team == lp.Team) then
            c.hl.Enabled, c.bb.Enabled = false, false
            continue
        end

        if cfg.Chams then
            c.hl.Adornee = char
            c.hl.FillColor = p.TeamColor and p.TeamColor.Color or Color3.new(1, 0, 0)
            c.hl.Enabled = true
        else
            c.hl.Enabled = false
        end

        if cfg.Name or cfg.Health or cfg.WeaponN or cfg.Studs then
            c.bb.Adornee = head
            c.bb.Enabled = true
            
            if cfg.Name then c.lbls.n.Text, c.lbls.n.Visible = p.Name, true else c.lbls.n.Visible = false end
            
            if cfg.Health then
                local hp = math.floor(hum.Health)
                c.lbls.h.Text, c.lbls.h.TextColor3, c.lbls.h.Visible = tostring(hp), Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(50, 255, 50), hp / hum.MaxHealth), true
            else
                c.lbls.h.Visible = false
            end

            if cfg.WeaponN then
                local t = char:FindFirstChildOfClass("Tool")
                if t then c.lbls.w.Text, c.lbls.w.Visible = t.Name, true else c.lbls.w.Visible = false end
            else
                c.lbls.w.Visible = false
            end

            if cfg.Studs then
                local d = lhrp and (lhrp.Position - hrp.Position).Magnitude or 0
                c.lbls.s.Text, c.lbls.s.Visible = string.format("[%d]", math.floor(d)), true
            else
                c.lbls.s.Visible = false
            end
        else
            c.bb.Enabled = false
        end
    end
end

env.StopESP = function()
    for _, c in pairs(env.espConns) do c:Disconnect() end
    table.clear(env.espConns)
    for p, _ in pairs(env.espStore) do rem(p) end
    table.clear(env.espStore)
    if env.espHold then env.espHold:Destroy() env.espHold = nil end
end

env.StartESP = function()
    env.StopESP()
    getHold()
    for _, p in ipairs(plrs:GetPlayers()) do if p ~= lp then add(p) end end
    table.insert(env.espConns, plrs.PlayerAdded:Connect(add))
    table.insert(env.espConns, plrs.PlayerRemoving:Connect(rem))
    table.insert(env.espConns, rs.RenderStepped:Connect(upd))
end
