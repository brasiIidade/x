local cloneref = cloneref or function(o) return o end
local plrs = cloneref(game:GetService("Players"))
local rs = cloneref(game:GetService("RunService"))
local ws = cloneref(game:GetService("Workspace"))
local lp = cloneref(plrs.LocalPlayer)

local env = getgenv()
env.espConns = env.espConns or {}
env.espStore = env.espStore or {}

env.ESPConfig = env.ESPConfig or {
    Enabled = false,
    TeamCheck = false,
    UseTeamColor = false,
    Boxes = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    Names = false,
    NameColor = Color3.fromRGB(255, 255, 255),
    Distance = false,
    DistanceColor = Color3.fromRGB(200, 200, 200),
    Health = false,
    Tracers = false,
    TracerColor = Color3.fromRGB(255, 255, 255),
    MaxDistance = 2000
}

local function createESP(p)
    if p == lp or env.espStore[p] then return end
    
    local esp = {}
    
    esp.box = Drawing.new("Square")
    esp.box.Thickness = 1
    esp.box.Filled = false
    
    esp.name = Drawing.new("Text")
    esp.name.Size = 15
    esp.name.Center = true
    esp.name.Outline = true
    
    esp.dist = Drawing.new("Text")
    esp.dist.Size = 13
    esp.dist.Center = true
    esp.dist.Outline = true
    
    esp.hpBg = Drawing.new("Square")
    esp.hpBg.Filled = true
    esp.hpBg.Color = Color3.fromRGB(20, 20, 20)
    
    esp.hpBar = Drawing.new("Square")
    esp.hpBar.Filled = true
    
    esp.tracer = Drawing.new("Line")
    esp.tracer.Thickness = 1
    
    env.espStore[p] = esp
end

local function removeESP(p)
    if env.espStore[p] then
        for _, v in pairs(env.espStore[p]) do
            v:Remove()
        end
        env.espStore[p] = nil
    end
end

local function updateESP()
    local cam = ws.CurrentCamera
    if not cam then return end

    if not env.ESPConfig.Enabled then
        for _, esp in pairs(env.espStore) do
            for _, v in pairs(esp) do v.Visible = false end
        end
        return
    end

    for p, esp in pairs(env.espStore) do
        if not p or not p.Parent then
            removeESP(p)
            continue
        end

        local char = p.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local head = char and char:FindFirstChild("Head")

        if not (char and hrp and hum and hum.Health > 0 and head) or (env.ESPConfig.TeamCheck and lp.Team and p.Team == lp.Team) then
            for _, v in pairs(esp) do v.Visible = false end
            continue
        end

        local dist = (hrp.Position - cam.CFrame.Position).Magnitude
        if dist > env.ESPConfig.MaxDistance then
            for _, v in pairs(esp) do v.Visible = false end
            continue
        end

        local headPos, onScreen = cam:WorldToViewportPoint(head.Position)
        local rootPos = cam:WorldToViewportPoint(hrp.Position)

        if not onScreen then
            for _, v in pairs(esp) do v.Visible = false end
            continue
        end

        local height = (cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y - headPos.Y)
        local width = height / 2
        local boxSize = Vector2.new(math.floor(width), math.floor(height))
        local boxPos = Vector2.new(math.floor(rootPos.X - width / 2), math.floor(headPos.Y))

        local tColor = (env.ESPConfig.UseTeamColor and p.TeamColor) and p.TeamColor.Color or nil

        if env.ESPConfig.Boxes then
            esp.box.Size = boxSize
            esp.box.Position = boxPos
            esp.box.Color = tColor or env.ESPConfig.BoxColor
            esp.box.Visible = true
        else
            esp.box.Visible = false
        end

        if env.ESPConfig.Names then
            esp.name.Text = p.Name
            esp.name.Position = Vector2.new(boxPos.X + (boxSize.X / 2), boxPos.Y - 16)
            esp.name.Color = tColor or env.ESPConfig.NameColor
            esp.name.Visible = true
        else
            esp.name.Visible = false
        end

        if env.ESPConfig.Distance then
            esp.dist.Text = string.format("[%dm]", math.floor(dist))
            esp.dist.Position = Vector2.new(boxPos.X + (boxSize.X / 2), boxPos.Y + boxSize.Y + 2)
            esp.dist.Color = tColor or env.ESPConfig.DistanceColor
            esp.dist.Visible = true
        else
            esp.dist.Visible = false
        end

        if env.ESPConfig.Health then
            local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            esp.hpBg.Size = Vector2.new(3, boxSize.Y)
            esp.hpBg.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
            esp.hpBg.Visible = true

            esp.hpBar.Size = Vector2.new(3, math.floor(boxSize.Y * hpPct))
            esp.hpBar.Position = Vector2.new(boxPos.X - 6, boxPos.Y + (boxSize.Y - esp.hpBar.Size.Y))
            esp.hpBar.Color = Color3.fromRGB(255 - (hpPct * 255), hpPct * 255, 0)
            esp.hpBar.Visible = true
        else
            esp.hpBg.Visible = false
            esp.hpBar.Visible = false
        end

        if env.ESPConfig.Tracers then
            esp.tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
            esp.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            esp.tracer.Color = tColor or env.ESPConfig.TracerColor
            esp.tracer.Visible = true
        else
            esp.tracer.Visible = false
        end
    end
end

env.StopESP = function()
    env.ESPConfig.Enabled = false
    for _, c in pairs(env.espConns) do c:Disconnect() end
    table.clear(env.espConns)
    for p, _ in pairs(env.espStore) do removeESP(p) end
    table.clear(env.espStore)
end

env.StartESP = function()
    env.StopESP()
    env.ESPConfig.Enabled = true
    for _, p in ipairs(plrs:GetPlayers()) do createESP(p) end
    table.insert(env.espConns, plrs.PlayerAdded:Connect(createESP))
    table.insert(env.espConns, plrs.PlayerRemoving:Connect(removeESP))
    table.insert(env.espConns, rs.RenderStepped:Connect(updateESP))
end
