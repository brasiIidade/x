--------------------------------------------------------------------------------
-- [[ COMBATE.LUA ]]
-- Hitbox Expander + ESP com anti-detecção profissional
--------------------------------------------------------------------------------

local cr          = cloneref or function(o) return o end
local newcc       = newcclosure or function(f) return f end
local checkc      = checkcaller or function() return false end
local gethui_safe = gethui or function() return cr(game:GetService("CoreGui")) end

local Players    = cr(game:GetService("Players"))
local RunService = cr(game:GetService("RunService"))
local HttpSvc    = cr(game:GetService("HttpService"))
local Workspace  = cr(game:GetService("Workspace"))

local LocalPlayer = cr(Players.LocalPlayer)

--------------------------------------------------------------------------------
-- [[ APEX — HOOK DE KICK ]]
-- Bloqueia o remote de kick do servidor sem deixar rastro no callstack.
--------------------------------------------------------------------------------

if game.PlaceId == 2069320852 then
    local mt     = getrawmetatable(game)
    local old_nc = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcc(function(self, ...)
        if checkc() then return old_nc(self, ...) end

        local method = getnamecallmethod()
        if method == "FireServer" then
            local remote = self
            local arg1   = select(1, ...)
            if typeof(remote) == "Instance"
                and remote:IsA("RemoteEvent")
                and remote.Name == "ClientKick"
                and arg1 == "HitBox"
            then
                return
            end
        end

        return old_nc(self, ...)
    end)

    setreadonly(mt, true)
end

--------------------------------------------------------------------------------
-- [[ UTILITÁRIOS INTERNOS ]]
--------------------------------------------------------------------------------

local env  = getgenv()
local guid = function() return HttpSvc:GenerateGUID(false) end

local function SafeGui()
    local ok, hui = pcall(gethui_safe)
    return (ok and hui and hui.Parent ~= nil) and hui or cr(game:GetService("CoreGui"))
end

-- Wrap de operações em instâncias para evitar erros silenciosos
local function TrySet(instance, prop, value)
    if not instance or not instance.Parent then return end
    local ok, err = pcall(function() instance[prop] = value end)
    if not ok then
        -- silencioso: não vaza stack trace
    end
end

-- Verifica se um personagem está usando escudo
local function IsShielded(character)
    if not character then return false end
    for _, item in character:GetChildren() do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            if name:find("escudo") or name:find("shield") then return true end
        end
    end
    return false
end

-- Verifica se o player está vivo e possui partes essenciais
local function IsAlive(character)
    if not character then return false end
    local hum  = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return hum ~= nil and root ~= nil and hum.Health > 0
end

-- Obtem a root de forma segura sem disparar __index do jogo
local function GetRoot(character)
    if not character then return nil end
    return rawget(character, "HumanoidRootPart") or character:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------------------------------------
-- [[ HITBOX EXPANDER ]]
--------------------------------------------------------------------------------

local Hitbox = {}
Hitbox.Saved  = setmetatable({}, { __mode = "k" })
Hitbox.Lights = setmetatable({}, { __mode = "k" })

local function HitboxConfig()
    return env.HitboxConfig
end

local function HitboxShouldTarget(player)
    local cfg = HitboxConfig()
    if not cfg or not cfg.Enabled then return false end
    if player == LocalPlayer then return false end

    local char = player.Character
    if not char or not IsAlive(char) then return false end

    -- Whitelist de usuários
    if cfg.WhitelistedUsers and table.find(cfg.WhitelistedUsers, player.Name) then return false end

    -- Whitelist de times
    if cfg.WhitelistedTeams and player.Team and table.find(cfg.WhitelistedTeams, player.Team.Name) then return false end

    -- Focus mode
    if cfg.FocusMode and cfg.FocusList and not table.find(cfg.FocusList, player.Name) then return false end

    -- Team check
    if cfg.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end

    -- Filtro por time específico
    if cfg.TeamFilterEnabled and cfg.SelectedTeams and #cfg.SelectedTeams > 0 then
        local playerTeamName = player.Team and player.Team.Name or ""
        local allowed = false
        for _, team in cfg.SelectedTeams do
            if team == playerTeamName then allowed = true; break end
        end
        if not allowed then return false end
    end

    -- Escudo check
    if cfg.HideOnShield and IsShielded(char) then return false end

    return true
end

local function HitboxSaveState(player, root)
    if Hitbox.Saved[player] then return end
    Hitbox.Saved[player] = {
        Size         = root.Size,
        Transparency = root.Transparency,
        Shape        = root.Shape,
        CanCollide   = root.CanCollide,
        Material     = root.Material,
        Color        = root.Color,
        CastShadow   = root.CastShadow,
    }
end

local function HitboxRestoreState(player)
    local saved = Hitbox.Saved[player]
    if not saved then return end

    local char = player.Character
    local root = char and GetRoot(char)
    if root and root.Parent then
        TrySet(root, "Size",         saved.Size)
        TrySet(root, "Transparency", saved.Transparency)
        TrySet(root, "Shape",        saved.Shape)
        TrySet(root, "CanCollide",   saved.CanCollide)
        TrySet(root, "Material",     saved.Material)
        TrySet(root, "Color",        saved.Color)
        TrySet(root, "CastShadow",   saved.CastShadow)
    end

    Hitbox.Saved[player] = nil
end

local function HitboxRemoveLight(player)
    local hl = Hitbox.Lights[player]
    if hl then
        pcall(function() hl:Destroy() end)
        Hitbox.Lights[player] = nil
    end
end

local function HitboxCleanPlayer(player)
    HitboxRestoreState(player)
    HitboxRemoveLight(player)
end

local function HitboxApply(player, root, cfg)
    TrySet(root, "Size",        cfg.Size)
    TrySet(root, "Shape",       cfg.Shape)
    TrySet(root, "CanCollide",  false)
    TrySet(root, "CastShadow",  false)
    TrySet(root, "Material",    Enum.Material.ForceField)

    -- Transparência: ForceField já cobre visualmente, mas respeitamos config
    local vis = math.clamp(cfg.Transparency, 0, 0.999)
    TrySet(root, "Transparency", vis)

    -- Highlight: apenas se visível (< 1)
    if cfg.Transparency < 1 then
        local teamColor = (player.TeamColor and player.TeamColor.Color) or Color3.fromRGB(255, 0, 0)

        if not Hitbox.Lights[player] or not Hitbox.Lights[player].Parent then
            local hl = Instance.new("SelectionBox")
            hl.Name                 = guid()
            hl.Adornee              = root
            hl.Color3               = teamColor
            hl.LineThickness        = 0.04
            hl.SurfaceTransparency  = math.clamp(cfg.Transparency + 0.3, 0, 1)
            hl.SurfaceColor3        = teamColor
            hl.Parent               = SafeGui()
            Hitbox.Lights[player]   = hl
        else
            local hl = Hitbox.Lights[player]
            TrySet(hl, "Adornee",             root)
            TrySet(hl, "Color3",              teamColor)
            TrySet(hl, "SurfaceTransparency", math.clamp(cfg.Transparency + 0.3, 0, 1))
            TrySet(hl, "SurfaceColor3",       teamColor)
        end
    else
        HitboxRemoveLight(player)
    end
end

-- Loop principal do hitbox
RunService.Heartbeat:Connect(newcc(function()
    local cfg = HitboxConfig()

    if not cfg or not cfg.Enabled then
        for player in pairs(Hitbox.Saved) do
            HitboxCleanPlayer(player)
        end
        return
    end

    for _, player in Players:GetPlayers() do
        if HitboxShouldTarget(player) then
            local char = player.Character
            local root = char and GetRoot(char)
            if root and root.Parent then
                HitboxSaveState(player, root)
                HitboxApply(player, root, cfg)
            end
        else
            HitboxCleanPlayer(player)
        end
    end
end))

Players.PlayerRemoving:Connect(newcc(function(player)
    HitboxCleanPlayer(player)
end))

-- Limpeza ao trocar de personagem
Players.PlayerAdded:Connect(newcc(function(player)
    player.CharacterRemoving:Connect(function()
        HitboxCleanPlayer(player)
    end)
end))

for _, player in Players:GetPlayers() do
    if player ~= LocalPlayer then
        player.CharacterRemoving:Connect(function()
            HitboxCleanPlayer(player)
        end)
    end
end

--------------------------------------------------------------------------------
-- [[ ESP ]]
--------------------------------------------------------------------------------

local ESP = {}
ESP.Conns = {}
ESP.Store = setmetatable({}, { __mode = "k" })
ESP.Hold  = nil

local function ESPConfig()
    return env.ESPConfig
end

local function ESPContainer()
    if not ESP.Hold or not ESP.Hold.Parent then
        local folder = Instance.new("Folder")
        folder.Name   = guid()
        folder.Parent = SafeGui()
        ESP.Hold = folder
    end
    return ESP.Hold
end

local function ESPMakeLabel(parent, order, color, size)
    local label = Instance.new("TextLabel")
    label.Parent                 = parent
    label.BackgroundTransparency = 1
    label.Size                   = UDim2.new(1, 0, 0, size or 12)
    label.TextColor3             = color or Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.25
    label.TextStrokeColor3       = Color3.new(0, 0, 0)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = size or 12
    label.LayoutOrder            = order
    label.Visible                = false
    label.TextXAlignment         = Enum.TextXAlignment.Center
    return label
end

local function ESPAddPlayer(player)
    if not player or player == LocalPlayer or ESP.Store[player] then return end

    local container = ESPContainer()
    local entry = {}

    -- Highlight (chams)
    local hl = Instance.new("Highlight")
    hl.Name                = guid()
    hl.FillColor           = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency    = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled             = false
    hl.Parent              = container
    entry.highlight        = hl

    -- BillboardGui para labels
    local bb = Instance.new("BillboardGui")
    bb.Name         = guid()
    bb.Size         = UDim2.new(0, 200, 0, 70)
    bb.StudsOffset  = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop  = true
    bb.Enabled      = false
    bb.Parent       = container
    entry.billboard = bb

    local layout = Instance.new("UIListLayout")
    layout.Parent              = bb
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding             = UDim.new(0, 1)

    entry.labels = {
        name   = ESPMakeLabel(bb, 1, Color3.fromRGB(255, 255, 255), 13),
        team   = ESPMakeLabel(bb, 2, Color3.fromRGB(180, 180, 180), 11),
        health = ESPMakeLabel(bb, 3, Color3.fromRGB(50, 255, 50),   11),
        weapon = ESPMakeLabel(bb, 4, Color3.fromRGB(200, 200, 200), 11),
        studs  = ESPMakeLabel(bb, 5, Color3.fromRGB(255, 220, 0),   11),
    }

    ESP.Store[player] = entry
end

local function ESPRemovePlayer(player)
    local entry = ESP.Store[player]
    if not entry then return end
    pcall(function() entry.highlight:Destroy() end)
    pcall(function() entry.billboard:Destroy() end)
    ESP.Store[player] = nil
end

local function ESPUpdate()
    local cfg   = ESPConfig()
    if not cfg then return end

    local lchar = LocalPlayer.Character
    local lroot = lchar and GetRoot(lchar)

    for player, entry in pairs(ESP.Store) do
        if not player or not player.Parent then
            ESPRemovePlayer(player)
            continue
        end

        local char  = player.Character
        local root  = char and GetRoot(char)
        local hum   = char and char:FindFirstChildOfClass("Humanoid")
        local head  = char and char:FindFirstChild("Head")
        local alive = root and hum and hum.Health > 0 and head

        local sameTeam = cfg.TeamCheck
            and LocalPlayer.Team ~= nil
            and player.Team ~= nil
            and player.Team == LocalPlayer.Team

        if not alive or sameTeam then
            TrySet(entry.highlight, "Enabled", false)
            TrySet(entry.billboard, "Enabled", false)
            for _, lbl in pairs(entry.labels) do TrySet(lbl, "Visible", false) end
            continue
        end

        -- Chams
        if cfg.Chams then
            TrySet(entry.highlight, "Adornee",  char)
            TrySet(entry.highlight, "FillColor", (player.TeamColor and player.TeamColor.Color) or Color3.fromRGB(255, 0, 0))
            TrySet(entry.highlight, "Enabled",  true)
        else
            TrySet(entry.highlight, "Enabled", false)
        end

        -- Labels
        local anyLabel = cfg.Name or cfg.Health or cfg.WeaponN or cfg.Studs

        if anyLabel then
            TrySet(entry.billboard, "Adornee", head)
            TrySet(entry.billboard, "Enabled", true)

            -- Nome
            local lblName = entry.labels.name
            if cfg.Name then
                lblName.Text    = player.Name
                lblName.Visible = true
            else
                lblName.Visible = false
            end

            -- Time
            local lblTeam = entry.labels.team
            if player.Team then
                lblTeam.Text       = player.Team.Name
                lblTeam.TextColor3 = player.Team.TeamColor.Color
                lblTeam.Visible    = true
            else
                lblTeam.Visible = false
            end

            -- Vida com barra de cor dinâmica
            local lblHP = entry.labels.health
            if cfg.Health then
                local hp    = math.floor(hum.Health)
                local maxhp = math.max(hum.MaxHealth, 1)
                local ratio = hp / maxhp
                lblHP.Text       = string.format("HP %d / %d", hp, maxhp)
                lblHP.TextColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(50, 255, 50), ratio)
                lblHP.Visible    = true
            else
                lblHP.Visible = false
            end

            -- Arma/Item
            local lblWeapon = entry.labels.weapon
            if cfg.WeaponN then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    lblWeapon.Text    = tool.Name
                    lblWeapon.Visible = true
                else
                    lblWeapon.Visible = false
                end
            else
                lblWeapon.Visible = false
            end

            -- Distância
            local lblStuds = entry.labels.studs
            if cfg.Studs and lroot then
                local dist = (lroot.Position - root.Position).Magnitude
                lblStuds.Text    = string.format("[ %d m ]", math.floor(dist))
                lblStuds.Visible = true
            else
                lblStuds.Visible = false
            end
        else
            TrySet(entry.billboard, "Enabled", false)
            for _, lbl in pairs(entry.labels) do TrySet(lbl, "Visible", false) end
        end
    end
end

-- API pública exposta para a UI
env.StopESP = newcc(function()
    for _, conn in ESP.Conns do conn:Disconnect() end
    table.clear(ESP.Conns)
    for player in pairs(ESP.Store) do ESPRemovePlayer(player) end
    table.clear(ESP.Store)
    if ESP.Hold then
        pcall(function() ESP.Hold:Destroy() end)
        ESP.Hold = nil
    end
end)

env.StartESP = newcc(function()
    env.StopESP()
    ESPContainer()

    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer then ESPAddPlayer(player) end
    end

    table.insert(ESP.Conns, Players.PlayerAdded:Connect(newcc(ESPAddPlayer)))
    table.insert(ESP.Conns, Players.PlayerRemoving:Connect(newcc(ESPRemovePlayer)))
    table.insert(ESP.Conns, RunService.RenderStepped:Connect(newcc(ESPUpdate)))
end)