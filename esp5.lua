local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local rs = cr(game:GetService("RunService"))
local lp = plrs.LocalPlayer

local env = getgenv()

local def_cfg = {
    Enabled = false,
    Boxes = false,
    Names = false,
    Distance = false,
    Health = false,
    Weapon = false,
    TeamCheck = true,
    UseTeamColor = false,
    MaxDistance = 2000,
    Colors = {
        Box = Color3.fromRGB(255, 255, 255),
        Name = Color3.fromRGB(255, 255, 255),
        Distance = Color3.fromRGB(200, 200, 200),
        Weapon = Color3.fromRGB(255, 255, 255)
    }
}

if type(env.ESPConfig) ~= "table" then
    env.ESPConfig = def_cfg
else
    for k, v in pairs(def_cfg) do
        if env.ESPConfig[k] == nil then env.ESPConfig[k] = v end
    end
    if type(env.ESPConfig.Colors) ~= "table" then env.ESPConfig.Colors = def_cfg.Colors end
    for k, v in pairs(def_cfg.Colors) do
        if env.ESPConfig.Colors[k] == nil then env.ESPConfig.Colors[k] = v end
    end
end

env.espObjects = env.espObjects or {}
env.espConns = env.espConns or {}

local function is_tm(p)
    if not lp.Team or not p.Team then return false end
    return p.Team == lp.Team
end

local function get_esp_col(p, def)
    if env.ESPConfig.UseTeamColor and p.Team and p.TeamColor then
        return p.TeamColor.Color
    end
    return def or Color3.fromRGB(255, 255, 255)
end

local function mk_esp(p)
    if p == lp or env.espObjects[p] then return end
    
    local d = {}
    
    d.bx_out = Drawing.new("Square")
    d.bx_out.Visible = false
    d.bx_out.Color = Color3.fromRGB(0, 0, 0)
    d.bx_out.Thickness = 3
    d.bx_out.Transparency = 1
    d.bx_out.Filled = false

    d.bx = Drawing.new("Square")
    d.bx.Visible = false
    d.bx.Thickness = 1
    d.bx.Transparency = 1
    d.bx.Filled = false
    
    d.nm = Drawing.new("Text")
    d.nm.Visible = false
    d.nm.Size = 14
    d.nm.Center = true
    d.nm.Outline = true
    d.nm.OutlineColor = Color3.fromRGB(0, 0, 0)
    d.nm.Font = 2
    
    d.dt = Drawing.new("Text")
    d.dt.Visible = false
    d.dt.Size = 12
    d.dt.Center = true
    d.dt.Outline = true
    d.dt.OutlineColor = Color3.fromRGB(0, 0, 0)
    d.dt.Font = 2

    d.wp = Drawing.new("Text")
    d.wp.Visible = false
    d.wp.Size = 12
    d.wp.Center = true
    d.wp.Outline = true
    d.wp.OutlineColor = Color3.fromRGB(0, 0, 0)
    d.wp.Font = 2
    
    d.hb_out = Drawing.new("Square")
    d.hb_out.Visible = false
    d.hb_out.Color = Color3.fromRGB(0, 0, 0)
    d.hb_out.Thickness = 1
    d.hb_out.Transparency = 1
    d.hb_out.Filled = true

    d.hb_bg = Drawing.new("Square")
    d.hb_bg.Visible = false
    d.hb_bg.Color = Color3.fromRGB(30, 30, 30)
    d.hb_bg.Thickness = 1
    d.hb_bg.Transparency = 1
    d.hb_bg.Filled = true
    
    d.hb = Drawing.new("Square")
    d.hb.Visible = false
    d.hb.Thickness = 1
    d.hb.Transparency = 1
    d.hb.Filled = true
    
    env.espObjects[p] = d
end

local function rm_esp(p)
    if env.espObjects[p] then
        for _, v in pairs(env.espObjects[p]) do
            if v and v.Remove then v:Remove() end
        end
        env.espObjects[p] = nil
    end
end

local function upd()
    local cam = workspace.CurrentCamera
    if not cam then return end
    
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
        if dist > (cfg.MaxDistance or 2000) then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end
        
        local hd_pos, on_scr = cam:WorldToViewportPoint(head.Position)
        local rt_pos = cam:WorldToViewportPoint(root.Position)
        
        if not on_scr then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end
        
        local bx_w = math.clamp(2000 / dist, 10, 1000)
        local bx_h = math.clamp(2500 / dist, 10, 1000)
        
        local bx_sz = Vector2.new(math.floor(bx_w), math.floor(bx_h))
        local bx_pos = Vector2.new(math.floor(rt_pos.X - bx_sz.X / 2), math.floor(rt_pos.Y - bx_sz.Y / 2))
        
        if cfg.Boxes and d.bx and d.bx_out then
            local c_bx = get_esp_col(p, cfg.Colors.Box)
            d.bx_out.Size = bx_sz
            d.bx_out.Position = bx_pos
            d.bx_out.Visible = true
            
            d.bx.Size = bx_sz
            d.bx.Position = bx_pos
            d.bx.Color = c_bx
            d.bx.Visible = true
        else
            if d.bx then d.bx.Visible = false end
            if d.bx_out then d.bx_out.Visible = false end
        end
        
        if cfg.Names and d.nm then
            d.nm.Text = p.Name
            d.nm.Position = Vector2.new(math.floor(hd_pos.X), math.floor(hd_pos.Y - 20))
            d.nm.Color = get_esp_col(p, cfg.Colors.Name)
            d.nm.Visible = true
        else
            if d.nm then d.nm.Visible = false end
        end
        
        local bottom_offset = 3
        
        if cfg.Distance and d.dt then
            d.dt.Text = string.format("[%dm]", math.floor(dist))
            d.dt.Position = Vector2.new(math.floor(rt_pos.X), math.floor(rt_pos.Y + bx_sz.Y / 2 + bottom_offset))
            d.dt.Color = get_esp_col(p, cfg.Colors.Distance)
            d.dt.Visible = true
            bottom_offset = bottom_offset + 14
        else
            if d.dt then d.dt.Visible = false end
        end

        if cfg.Weapon and d.wp then
            local tool = char:FindFirstChildOfClass("Tool")
            d.wp.Text = tool and tool.Name or "Nenhum item"
            d.wp.Position = Vector2.new(math.floor(rt_pos.X), math.floor(rt_pos.Y + bx_sz.Y / 2 + bottom_offset))
            d.wp.Color = get_esp_col(p, cfg.Colors.Weapon)
            d.wp.Visible = true
        else
            if d.wp then d.wp.Visible = false end
        end
        
        if cfg.Health and d.hb_bg and d.hb and d.hb_out then
            local max_hp = hum.MaxHealth > 0 and hum.MaxHealth or 100
            local hp_pct = math.clamp(hum.Health / max_hp, 0, 1)
            local bh = bx_sz.Y
            
            d.hb_out.Size = Vector2.new(4, bh + 2)
            d.hb_out.Position = Vector2.new(bx_pos.X - 6, bx_pos.Y - 1)
            d.hb_out.Visible = true
            
            d.hb_bg.Size = Vector2.new(2, bh)
            d.hb_bg.Position = Vector2.new(bx_pos.X - 5, bx_pos.Y)
            d.hb_bg.Visible = true
            
            d.hb.Color = Color3.fromRGB(math.floor(255 * (1 - hp_pct)), math.floor(255 * hp_pct), 0)
            d.hb.Size = Vector2.new(2, math.floor(bh * hp_pct))
            d.hb.Position = Vector2.new(bx_pos.X - 5, math.floor(bx_pos.Y + bh * (1 - hp_pct)))
            d.hb.Visible = true
        else
            if d.hb_out then d.hb_out.Visible = false end
            if d.hb_bg then d.hb_bg.Visible = false end
            if d.hb then d.hb.Visible = false end
        end
    end
end

env.StopESP = function()
    for _, c in pairs(env.espConns) do 
        if c then c:Disconnect() end 
    end
    table.clear(env.espConns)
    for p, _ in pairs(env.espObjects) do rm_esp(p) end
    table.clear(env.espObjects)
end

env.StartESP = function()
    env.StopESP()
    for _, p in ipairs(plrs:GetPlayers()) do 
        if p ~= lp then mk_esp(p) end 
    end
    table.insert(env.espConns, plrs.PlayerAdded:Connect(mk_esp))
    table.insert(env.espConns, plrs.PlayerRemoving:Connect(rm_esp))
    table.insert(env.espConns, rs.RenderStepped:Connect(upd))
end
