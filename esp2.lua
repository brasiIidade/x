local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local rs = cr(game:GetService("RunService"))
local lp = plrs.LocalPlayer

local env = getgenv()
env.ESPConfig = env.ESPConfig or {
    Enabled = false,
    Boxes = false,
    Names = false,
    Distance = false,
    Health = false,
    Tracers = false,
    TeamCheck = true,
    MaxDistance = 2000
}

env.espObjects = env.espObjects or {}
env.espConns = env.espConns or {}

local t_col = Color3.fromRGB(0, 255, 0)
local e_col = Color3.fromRGB(255, 0, 0)
local n_col = Color3.fromRGB(255, 255, 255)

local function is_tm(p)
    if not lp.Team or not p.Team then return false end
    return p.Team == lp.Team
end

local function get_col(p)
    if env.ESPConfig.TeamCheck and is_tm(p) then return t_col end
    return e_col
end

local function mk_esp(p)
    if p == lp or env.espObjects[p] then return end
    
    local d = {
        bx = Drawing.new("Square"),
        nm = Drawing.new("Text"),
        dt = Drawing.new("Text"),
        hb_bg = Drawing.new("Square"),
        hb = Drawing.new("Square"),
        tr = Drawing.new("Line")
    }
    
    d.bx.Visible = false
    d.bx.Color = n_col
    d.bx.Thickness = 1
    d.bx.Transparency = 1
    d.bx.Filled = false
    
    d.nm.Visible = false
    d.nm.Color = n_col
    d.nm.Size = 15
    d.nm.Center = true
    d.nm.Outline = true
    d.nm.OutlineColor = Color3.new(0, 0, 0)
    
    d.dt.Visible = false
    d.dt.Color = n_col
    d.dt.Size = 13
    d.dt.Center = true
    d.dt.Outline = true
    d.dt.OutlineColor = Color3.new(0, 0, 0)
    
    d.hb_bg.Visible = false
    d.hb_bg.Color = Color3.new(0, 0, 0)
    d.hb_bg.Thickness = 1
    d.hb_bg.Transparency = 0.8
    d.hb_bg.Filled = true
    
    d.hb.Visible = false
    d.hb.Color = t_col
    d.hb.Thickness = 1
    d.hb.Transparency = 1
    d.hb.Filled = true
    
    d.tr.Visible = false
    d.tr.Color = n_col
    d.tr.Thickness = 1
    d.tr.Transparency = 1
    
    env.espObjects[p] = d
end

local function rm_esp(p)
    if env.espObjects[p] then
        for _, v in pairs(env.espObjects[p]) do
            v:Remove()
        end
        env.espObjects[p] = nil
    end
end

local function upd()
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    local vp_sz = cam.ViewportSize
    local cfg = env.ESPConfig
    
    for p, d in pairs(env.espObjects) do
        if not p or not p.Parent or not p.Character or not cfg.Enabled or (cfg.TeamCheck and is_tm(p)) then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end
        
        local char = p.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        local head = char:FindFirstChild("Head")
        
        if not root or not hum or not head or hum.Health <= 0 then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end
        
        local dist = (root.Position - cam.CFrame.Position).Magnitude
        if dist > cfg.MaxDistance then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end
        
        local hd_pos, on_scr = cam:WorldToViewportPoint(head.Position)
        local rt_pos = cam:WorldToViewportPoint(root.Position)
        
        if not on_scr then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end
        
        local col = get_col(p)
        local bx_sz = Vector2.new(2000 / dist, 2500 / dist)
        local bx_pos = Vector2.new(rt_pos.X - bx_sz.X / 2, rt_pos.Y - bx_sz.Y / 2)
        
        if cfg.Boxes then
            d.bx.Size = bx_sz
            d.bx.Position = bx_pos
            d.bx.Color = col
            d.bx.Visible = true
        else
            d.bx.Visible = false
        end
        
        if cfg.Names then
            d.nm.Text = p.Name
            d.nm.Position = Vector2.new(hd_pos.X, hd_pos.Y - 20)
            d.nm.Color = col
            d.nm.Visible = true
        else
            d.nm.Visible = false
        end
        
        if cfg.Distance then
            d.dt.Text = string.format("[%dm]", math.floor(dist))
            d.dt.Position = Vector2.new(rt_pos.X, rt_pos.Y + bx_sz.Y / 2 + 5)
            d.dt.Visible = true
        else
            d.dt.Visible = false
        end
        
        if cfg.Health then
            local hp_pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local bw = 2
            local bh = bx_sz.Y
            
            d.hb_bg.Size = Vector2.new(bw, bh)
            d.hb_bg.Position = Vector2.new(bx_pos.X - 5, bx_pos.Y)
            d.hb_bg.Visible = true
            
            d.hb.Color = Color3.new(1 - hp_pct, hp_pct, 0)
            d.hb.Size = Vector2.new(bw, bh * hp_pct)
            d.hb.Position = Vector2.new(bx_pos.X - 5, bx_pos.Y + bh * (1 - hp_pct))
            d.hb.Visible = true
        else
            d.hb_bg.Visible = false
            d.hb.Visible = false
        end
        
        if cfg.Tracers then
            d.tr.From = Vector2.new(vp_sz.X / 2, vp_sz.Y)
            d.tr.To = Vector2.new(rt_pos.X, rt_pos.Y)
            d.tr.Color = col
            d.tr.Visible = true
        else
            d.tr.Visible = false
        end
    end
end

env.StopESP = function()
    for _, c in pairs(env.espConns) do c:Disconnect() end
    table.clear(env.espConns)
    for p, _ in pairs(env.espObjects) do rm_esp(p) end
    table.clear(env.espObjects)
end

env.StartESP = function()
    env.StopESP()
    for _, p in ipairs(plrs:GetPlayers()) do if p ~= lp then mk_esp(p) end end
    table.insert(env.espConns, plrs.PlayerAdded:Connect(mk_esp))
    table.insert(env.espConns, plrs.PlayerRemoving:Connect(rm_esp))
    table.insert(env.espConns, rs.RenderStepped:Connect(upd))
end
