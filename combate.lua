-- Apex
if game.PlaceId == 2069320852 then
    local oldFireServer
    oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(remote, ...)
        if remote.Name ~= "ClientKick" then
            return oldFireServer(remote, ...)
        end
        if select(1, ...) == "HitBox" then
            return
        end
        return oldFireServer(remote, ...)
    end)
end

-- servicos
local cr        = cloneref or function(o) return o end
local Players   = cr(game:GetService("Players"))
local RunService = cr(game:GetService("RunService"))
local CoreGui   = cr(game:GetService("CoreGui"))
local HttpService = cr(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer

local function safeGui()
    local ok, hui = pcall(gethui)
    return (ok and hui) and hui or CoreGui
end

local function isShielded(character)
    if not character then return false end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            if name:find("escudo") or name:find("shield") then
                return true
            end
        end
    end
    return false
end


-- Hitbox
local hitboxSaved = {} 
local hitboxLights = {}

local function hitboxConfig()
    return getgenv().HitboxConfig
end

local function hitboxShouldTarget(player)
    local cfg = hitboxConfig()
    if not cfg or not cfg.Enabled then return false end
    if player == LocalPlayer then return false end
    if table.find(cfg.WhitelistedUsers, player.Name) then return false end
    if player.Team and table.find(cfg.WhitelistedTeams, player.Team.Name) then return false end
    if cfg.FocusMode and not table.find(cfg.FocusList, player.Name) then return false end
    if cfg.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    if cfg.TeamFilterEnabled and #cfg.SelectedTeams > 0 then
        local playerTeam = player.Team and player.Team.Name or ""
        local allowed = false
        for _, team in ipairs(cfg.SelectedTeams) do
            if team == playerTeam then allowed = true; break end
        end
        if not allowed then return false end
    end

    local char = player.Character
    if not char then return false end
    local hum  = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return false end
    if cfg.HideOnShield and isShielded(char) then return false end

    return true
end

local function hitboxSaveState(player, root)
    if hitboxSaved[player] then return end
    hitboxSaved[player] = {
        size       = root.Size,
        canCollide = root.CanCollide,
    }
end

local function hitboxRestoreState(player)
    local saved = hitboxSaved[player]
    if not saved then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Size       = saved.size
        root.CanCollide = saved.canCollide
    end
    hitboxSaved[player] = nil
end

local function hitboxRemoveHighlight(player)
    if hitboxLights[player] then
        hitboxLights[player]:Destroy()
        hitboxLights[player] = nil
    end
end

local function hitboxCleanPlayer(player)
    hitboxRestoreState(player)
    hitboxRemoveHighlight(player)
end

local function hitboxApply(player, root, cfg)
    root.Size       = cfg.Size
    root.CanCollide = false

    if cfg.Transparency < 1 then
        local teamColor = (player.TeamColor and player.TeamColor.Color) or Color3.new(1, 0, 0)
        if not hitboxLights[player] then
            local hl = Instance.new("Highlight")
            hl.Name                = HttpService:GenerateGUID(false)
            hl.Adornee             = root
            hl.FillColor           = teamColor
            hl.FillTransparency    = cfg.Transparency
            hl.OutlineTransparency = cfg.Transparency
            hl.Parent              = safeGui()
            hitboxLights[player]   = hl
        else
            local hl = hitboxLights[player]
            hl.Adornee             = root
            hl.FillColor           = teamColor
            hl.FillTransparency    = cfg.Transparency
            hl.OutlineTransparency = cfg.Transparency
        end
    else
        hitboxRemoveHighlight(player)
    end
end

RunService.Heartbeat:Connect(function()
    local cfg = hitboxConfig()

    if not cfg or not cfg.Enabled then
        for player in pairs(hitboxSaved) do hitboxCleanPlayer(player) end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if hitboxShouldTarget(player) then
            local root = player.Character.HumanoidRootPart
            hitboxSaveState(player, root)
            hitboxApply(player, root, cfg)
        else
            hitboxCleanPlayer(player)
        end
    end
end)

Players.PlayerRemoving:Connect(hitboxCleanPlayer)


-- ESP
local env = getgenv()

env.espConns = env.espConns or {}
env.espStore = env.espStore or {}
env.espHold  = env.espHold  or nil


env.ESPConfig = env.ESPConfig or {
    Enabled  = false,
    TeamCheck = false,
    Chams    = false,
    Name     = false,
    Studs    = false,
    Health   = false,
    WeaponN  = false,
}

local function espGetContainer()
    if not env.espHold or not env.espHold.Parent then
        local folder = Instance.new("Folder")
        folder.Name  = HttpService:GenerateGUID(false)
        folder.Parent = safeGui()
        env.espHold  = folder
    end
    return env.espHold
end

local function espMakeLabel(parent, order, color, size)
    local label = Instance.new("TextLabel")
    label.Parent                = parent
    label.BackgroundTransparency = 1
    label.Size                  = UDim2.new(1, 0, 0, size or 12)
    label.TextColor3            = color or Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3      = Color3.new(0, 0, 0)
    label.Font                  = Enum.Font.GothamBold
    label.TextSize              = size or 12
    label.LayoutOrder           = order
    label.Visible               = false
    return label
end

local function espAddPlayer(player)
    if not player or player == LocalPlayer or env.espStore[player] then return end

    local container = espGetContainer()
    local entry = {
        highlight = Instance.new("Highlight"),
        billboard = Instance.new("BillboardGui"),
        labels    = {},
    }

    -- hl
    local hl = entry.highlight
    hl.Name                = HttpService:GenerateGUID(false)
    hl.FillColor           = Color3.new(1, 0, 0)
    hl.OutlineColor        = Color3.new(1, 1, 1)
    hl.FillTransparency    = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled             = false
    hl.Parent              = container

    -- gui
    local bb = entry.billboard
    bb.Name         = HttpService:GenerateGUID(false)
    bb.Size         = UDim2.new(0, 200, 0, 60)
    bb.StudsOffset  = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop  = true
    bb.Enabled      = false
    bb.Parent       = container

    local layout = Instance.new("UIListLayout")
    layout.Parent            = bb
    layout.SortOrder         = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding           = UDim.new(0, 0)

    entry.labels.name   = espMakeLabel(bb, 1, Color3.new(1, 1, 1), 13)
    entry.labels.health = espMakeLabel(bb, 2, Color3.fromRGB(0, 255, 100), 11)
    entry.labels.weapon = espMakeLabel(bb, 3, Color3.fromRGB(200, 200, 200), 11)
    entry.labels.studs  = espMakeLabel(bb, 4, Color3.fromRGB(255, 220, 0), 11)

    env.espStore[player] = entry
end

local function espRemovePlayer(player)
    local entry = env.espStore[player]
    if not entry then return end
    if entry.highlight then entry.highlight:Destroy() end
    if entry.billboard then entry.billboard:Destroy() end
    env.espStore[player] = nil
end

local function espUpdate()
    local cfg   = env.ESPConfig
    local lchar = LocalPlayer.Character
    local lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")

    for player, entry in pairs(env.espStore) do
        if not player or not player.Parent then
            espRemovePlayer(player)
            continue
        end

        local char  = player.Character
        local root  = char and char:FindFirstChild("HumanoidRootPart")
        local hum   = char and char:FindFirstChild("Humanoid")
        local head  = char and char:FindFirstChild("Head")
        local alive = char and root and hum and hum.Health > 0 and head
        local sameTeam = cfg.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team

        if not alive or sameTeam then
            entry.highlight.Enabled = false
            entry.billboard.Enabled = false
            continue
        end

        -- chams
        if cfg.Chams then
            entry.highlight.Adornee  = char
            entry.highlight.FillColor = (player.TeamColor and player.TeamColor.Color) or Color3.new(1, 0, 0)
            entry.highlight.Enabled  = true
        else
            entry.highlight.Enabled = false
        end

        -- labels
        local showBillboard = cfg.Name or cfg.Health or cfg.WeaponN or cfg.Studs
        if showBillboard then
            entry.billboard.Adornee = head
            entry.billboard.Enabled = true

            -- nome
            local lblName = entry.labels.name
            if cfg.Name then
                lblName.Text    = player.Name
                lblName.Visible = true
            else
                lblName.Visible = false
            end

            -- vida
            local lblHealth = entry.labels.health
            if cfg.Health then
                local hp = math.floor(hum.Health)
                lblHealth.Text      = tostring(hp)
                lblHealth.TextColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(50, 255, 50), hp / hum.MaxHealth)
                lblHealth.Visible   = true
            else
                lblHealth.Visible = false
            end

            -- item
            local lblWeapon = entry.labels.weapon
            if cfg.WeaponN then
                local tool = char:FindFirstChildOfClass("Tool")
                lblWeapon.Text    = tool and tool.Name or ""
                lblWeapon.Visible = tool ~= nil
            else
                lblWeapon.Visible = false
            end

            -- dist
            local lblStuds = entry.labels.studs
            if cfg.Studs then
                local dist = lroot and (lroot.Position - root.Position).Magnitude or 0
                lblStuds.Text    = string.format("[%d]", math.floor(dist))
                lblStuds.Visible = true
            else
                lblStuds.Visible = false
            end
        else
            entry.billboard.Enabled = false
        end
    end
end

-- UI
env.StopESP = function()
    for _, conn in pairs(env.espConns) do conn:Disconnect() end
    table.clear(env.espConns)
    for player in pairs(env.espStore) do espRemovePlayer(player) end
    table.clear(env.espStore)
    if env.espHold then
        env.espHold:Destroy()
        env.espHold = nil
    end
end

env.StartESP = function()
    env.StopESP()
    espGetContainer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then espAddPlayer(player) end
    end
    table.insert(env.espConns, Players.PlayerAdded:Connect(espAddPlayer))
    table.insert(env.espConns, Players.PlayerRemoving:Connect(espRemovePlayer))
    table.insert(env.espConns, RunService.RenderStepped:Connect(espUpdate))
end