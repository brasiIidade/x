if game.PlaceId == 2069320852 then
    local oldFireServer
    oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(remote, ...)
        local args = {...}
        if remote.Name == "ClientKick" and args[1] == "HitBox" then
            return
        end
        return oldFireServer(remote, ...)
    end)
end

-- backend
local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local run = cr(game:GetService("RunService"))
local core = cr(game:GetService("CoreGui"))
local http = cr(game:GetService("HttpService"))

local lp = plrs.LocalPlayer
local localName = lp.Name

local find = game.FindFirstChild
local is_a = game.IsA
local get_genv = getgenv
local env = get_genv()
local v3_new = Vector3.new
local c3_new = Color3.new
local inst_new = Instance.new

local salvos = {} 
local luzes = {} 

local function pega_cfg()
    return get_genv().HitboxConfig
end

local function protecao(c)
    if not c then return false end
    for _, v in ipairs(c:GetChildren()) do
        if is_a(v, "Tool") then
            local n = v.Name:lower()
            if n:find("escudo") or n:find("shield") then
                return true
            end
        end
    end
    return false
end

local function limpa(p)
    local dados = salvos[p]
    if dados then
        local char = p.Character
        local root = char and find(char, "HumanoidRootPart")
        if root then
            root.Size = dados.s
            root.Transparency = dados.t
            root.Shape = dados.sh
            root.CanCollide = dados.c
            root.Material = dados.m
            root.Color = dados.co
        end
        salvos[p] = nil
    end
    
    if luzes[p] then
        luzes[p]:Destroy()
        luzes[p] = nil
    end
end

local function valida(p)
    local cfg = pega_cfg()
    if not cfg or not cfg.Enabled or p == lp then return false end
    
    if table.find(cfg.WhitelistedUsers, p.Name) then return false end
    if p.Team and table.find(cfg.WhitelistedTeams, p.Team.Name) then return false end
    
    if cfg.FocusMode and not table.find(cfg.FocusList, p.Name) then return false end
    
    local char = p.Character
    if not char then return false end
    
    local hum = find(char, "Humanoid")
    local root = find(char, "HumanoidRootPart")
    
    if not hum or not root or hum.Health <= 0 then return false end
    
    if cfg.TeamCheck and p.Team and lp.Team and p.Team == lp.Team then
        return false
    end
    
    if cfg.TeamFilterEnabled and #cfg.SelectedTeams > 0 then
        local t_nome = p.Team and p.Team.Name or ""
        local ok = false
        for _, t in ipairs(cfg.SelectedTeams) do
            if t == t_nome then ok = true break end
        end
        if not ok then return false end
    end
    
    if cfg.HideOnShield and protecao(char) then
        return false
    end
    
    return true
end

local loop = run.Heartbeat:Connect(function()
    local cfg = pega_cfg()
    
    if not cfg or not cfg.Enabled then
        for p, _ in pairs(salvos) do limpa(p) end
        return
    end

    for _, p in ipairs(plrs:GetPlayers()) do
        if valida(p) then
            local root = p.Character.HumanoidRootPart
            
            if not salvos[p] then
                salvos[p] = {
                    s = root.Size,
                    t = root.Transparency,
                    sh = root.Shape,
                    c = root.CanCollide,
                    m = root.Material,
                    co = root.Color
                }
            end
            
            root.Size = cfg.Size
            root.Transparency = cfg.Transparency
            root.Shape = cfg.Shape
            root.CanCollide = false
            root.Material = Enum.Material.ForceField
            
            local teamColor = p.TeamColor and p.TeamColor.Color or Color3.new(1, 0, 0)
            
            if cfg.Transparency < 1 then
                if not luzes[p] then
                    local h = inst_new("Highlight")
                    h.Name = http:GenerateGUID(false)
                    h.Adornee = root
                    h.FillTransparency = cfg.Transparency
                    h.OutlineTransparency = cfg.Transparency
                    h.FillColor = teamColor
                    local suc, tar = pcall(gethui)
                    h.Parent = (suc and tar) and tar or core
                    luzes[p] = h
                else
                    luzes[p].Adornee = root
                    luzes[p].FillTransparency = cfg.Transparency
                    luzes[p].OutlineTransparency = cfg.Transparency
                    luzes[p].FillColor = teamColor
                end
            elseif luzes[p] then
                luzes[p]:Destroy()
                luzes[p] = nil
            end
        else
            limpa(p)
        end
    end
end)

plrs.PlayerRemoving:Connect(limpa)

-- ESP
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
        h.Name = http:GenerateGUID(false)
        local s, t = pcall(gethui)
        h.Parent = (s and t) and t or core
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
    if not p or p.Name == localName or env.espStore[p] then return end
    
    local h = getHold()
    local c = { hl = Instance.new("Highlight"), bb = Instance.new("BillboardGui"), lbls = {} }

    c.hl.Name, c.hl.FillColor, c.hl.OutlineColor, c.hl.FillTransparency, c.hl.OutlineTransparency, c.hl.DepthMode, c.hl.Enabled, c.hl.Parent = http:GenerateGUID(false), Color3.new(1, 0, 0), Color3.new(1, 1, 1), 0.6, 0, Enum.HighlightDepthMode.AlwaysOnTop, false, h
    c.bb.Name, c.bb.Size, c.bb.StudsOffset, c.bb.AlwaysOnTop, c.bb.Enabled, c.bb.Parent = http:GenerateGUID(false), UDim2.new(0, 200, 0, 60), Vector3.new(0, 2, 0), true, false, h

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
        if not p or p.Name == localName or not p.Parent then 
            rem(p) 
            continue 
        end

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
            local teamColor = p.TeamColor and p.TeamColor.Color or Color3.new(1, 0, 0)
            c.hl.FillColor = teamColor
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
    for _, p in ipairs(plrs:GetPlayers()) do 
        if p.Name ~= localName then add(p) end 
    end
    table.insert(env.espConns, plrs.PlayerAdded:Connect(add))
    table.insert(env.espConns, plrs.PlayerRemoving:Connect(rem))
    table.insert(env.espConns, run.RenderStepped:Connect(upd))
end