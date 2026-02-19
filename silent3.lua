--[[
    Lógica Backend do Silent Aim
    - Melhorias de segurança (clonefunction)
    - FOV com Debugging
    - HUD Reestilizado e Organizado
    - Hook de tiro INTACTO
]]

-- Otimização e Segurança (Anti-Detecção)
local clonefunction = clonefunction or function(f) return f end
local getnamecallmethod = clonefunction(getnamecallmethod)
local checkcaller = clonefunction(checkcaller)
local newcclosure = clonefunction(newcclosure)
local hookmetamethod = hookmetamethod

-- Serviços
local Game = game
local GetService = clonefunction(Game.GetService)
local Players = GetService(Game, "Players")
local RunService = GetService(Game, "RunService")
local Workspace = GetService(Game, "Workspace")
local CoreGui = GetService(Game, "CoreGui")
local UserInputService = GetService(Game, "UserInputService")

-- Referências Locais (Performance)
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local CFrameNew = CFrame.new
local MathRandom = clonefunction(math.random)
local MathAbs = clonefunction(math.abs)
local MathSin = clonefunction(math.sin)
local MathClamp = clonefunction(math.clamp)
local MathHuge = math.huge
local IPairs = clonefunction(ipairs)
local Pairs = clonefunction(pairs)
local TableFind = clonefunction(table.find)
local StringLower = clonefunction(string.lower)
local StringFind = clonefunction(string.find)
local WorldToScreenPoint = clonefunction(Camera.WorldToScreenPoint)
local Raycast = clonefunction(Workspace.Raycast)
local OsClock = clonefunction(os.clock)

-- Limpeza de conexões antigas
if _G.SilentAimConnections then
    for _, conn in Pairs(_G.SilentAimConnections) do conn:Disconnect() end
end
if _G.AimFOVCircle then pcall(function() _G.AimFOVCircle:Remove() end) _G.AimFOVCircle = nil end
if _G.AimbotGui then _G.AimbotGui:Destroy() _G.AimbotGui = nil end
if _G.AimHighlight then _G.AimHighlight:Destroy() _G.AimHighlight = nil end

-- Configuração Global
_G.AimbotConfig = _G.AimbotConfig or {
    Enabled = false,
    TeamCheck = "Team",         
    TargetPart = {"Random"},
    TargetPriority = "Distance",
    MaxDistance = 1000,         
    SwitchThreshold = 1,
    WhitelistedUsers = {}, 
    WhitelistedTeams = {}, 
    FocusList = {},
    FocusMode = false,
    UseLegitOffset = true,
    HitChance = 60,
    WallCheck = true,
    FOVSize = 200,
    ShowFOV = true,
    FOVBehavior = "Center",
    FOVNumSides = 20,
    FOVColor1 = Color3.fromRGB(34, 140, 85),
    FOVColor2 = Color3.fromRGB(250, 255, 252),
    GradientSpeed = 4,
    ShowHighlight = true,
    HighlightColor = Color3.fromRGB(255, 60, 60),
    ESP = {
        Enabled = true,
        ShowName = true,
        ShowTeam = true,
        ShowHealth = true,
        ShowWeapon = true,
        TextColor = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(255, 60, 60),
    }
}

_G.SilentAimConnections = {}
_G.SilentAimActive = false
local ClosestHitPart = nil
local CurrentTargetCharacter = nil

local PartMapping = {
    ["Head"] = {"Head"},
    ["Torso"] = {"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    ["Left Arm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["Right Arm"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["Left Leg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    ["Right Leg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", 
    "missile", "rocket", "hit", "damage", "attack", 
    "cast", "ray", "target", "server", "remote", "action", 
    "mouse", "input", "create"
}

-- Funções Auxiliares
local function getLegitOffset()
    if not _G.AimbotConfig.UseLegitOffset then return Vector3New(0,0,0) end
    return Vector3New(
        (MathRandom() - 0.5) * 0.5,
        (MathRandom() - 0.5) * 0.5,
        (MathRandom() - 0.5) * 0.5
    )
end

local function isBulletRemote(name)
    name = StringLower(name)
    for _, keyword in IPairs(bulletFunctions) do
        if StringFind(name, keyword) then return true end
    end
    return false
end

local function isWhitelisted(player)
    if not player then return false end
    if TableFind(_G.AimbotConfig.WhitelistedUsers, player.Name) then return true end
    if player.Team and TableFind(_G.AimbotConfig.WhitelistedTeams, player.Team.Name) then return true end
    return false
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true
local FilterCache = {} 

local function IsPartVisible(part, character)
    if not _G.AimbotConfig.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    
    FilterCache[1] = LocalPlayer.Character
    FilterCache[2] = character
    FilterCache[3] = Camera
    if _G.AimbotGui then FilterCache[4] = _G.AimbotGui end
    
    RayParams.FilterDescendantsInstances = FilterCache
    local rayResult = Raycast(Workspace, origin, direction, RayParams)
    
    return rayResult == nil or rayResult.Instance:IsDescendantOf(character)
end

local function ShuffleTable(t)
    local n = #t
    for i = n, 2, -1 do
        local j = MathRandom(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function GetBestPart(character)
    local targets = _G.AimbotConfig.TargetPart
    if typeof(targets) ~= "table" then targets = {targets} end
    
    local partsToCheck = {}

    if #targets == 0 or TableFind(targets, "Random") then
        partsToCheck = {"Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
    else
        for _, t in IPairs(targets) do
            table.insert(partsToCheck, t)
        end
    end

    ShuffleTable(partsToCheck)

    for _, groupName in IPairs(partsToCheck) do
        local specificParts = PartMapping[groupName]
        if specificParts then
            for _, partName in IPairs(specificParts) do
                local part = character:FindFirstChild(partName)
                if part and IsPartVisible(part, character) then
                    return part 
                end
            end
        end
    end

    return nil
end

local function getClosestPlayer()
    local BestPart = nil
    local BestChar = nil
    local BestScore = MathHuge

    local OriginPos
    if _G.AimbotConfig.FOVBehavior == "Mouse" then
        OriginPos = UserInputService:GetMouseLocation()
    else
        local Viewport = Camera.ViewportSize
        OriginPos = Vector2New(Viewport.X / 2, Viewport.Y / 2)
    end

    local MyPos = Camera.CFrame.Position
    local FOVSize = _G.AimbotConfig.FOVSize
    local MyTeam = LocalPlayer.Team
    local TeamCheckType = _G.AimbotConfig.TeamCheck 
    local FocusMode = _G.AimbotConfig.FocusMode
    local FocusList = _G.AimbotConfig.FocusList
    local Priority = _G.AimbotConfig.TargetPriority or "Distance"

    for _, Player in IPairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        
        if TeamCheckType == "Team" and Player.Team == MyTeam then continue end

        if FocusMode then
            if not TableFind(FocusList, Player.Name) then continue end
        else
            if isWhitelisted(Player) then continue end
        end

        local Character = Player.Character
        if not Character then continue end
        
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        
        if not RootPart or not Humanoid or Humanoid.Health <= 0 then continue end

        local dist3D = (RootPart.Position - MyPos).Magnitude
        if dist3D > _G.AimbotConfig.MaxDistance then continue end

        local CheckPart = Character:FindFirstChild("Head") or RootPart
        local screenPos, onScreen = WorldToScreenPoint(Camera, CheckPart.Position)

        if onScreen then
            local dist2D = (OriginPos - Vector2New(screenPos.X, screenPos.Y)).Magnitude
            
            if dist2D <= FOVSize then
                local currentScore
                if Priority == "Health" then
                    currentScore = Humanoid.Health 
                else
                    currentScore = dist2D 
                end

                if currentScore < BestScore then
                    local PotentialPart = GetBestPart(Character)
                    if PotentialPart then
                        BestScore = currentScore
                        BestPart = PotentialPart
                        BestChar = Character
                    end
                end
            end
        end
    end

    return BestPart, BestChar
end

-- Controle Global
_G.StopSilentAim = function()
    _G.SilentAimActive = false
    
    if _G.SilentAimConnections then
        for _, conn in Pairs(_G.SilentAimConnections) do
            if conn then conn:Disconnect() end
        end
    end
    _G.SilentAimConnections = {}

    if _G.AimFOVCircle then pcall(function() _G.AimFOVCircle:Remove() end) _G.AimFOVCircle = nil end
    if _G.AimbotGui then _G.AimbotGui:Destroy() _G.AimbotGui = nil end
    if _G.AimHighlight then _G.AimHighlight:Destroy() _G.AimHighlight = nil end
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

_G.StartSilentAim = function()
    _G.StopSilentAim()
    _G.SilentAimActive = true
    local config = _G.AimbotConfig
    
    config.Enabled = true

    print("[DEBUG] Iniciando Silent Aim...")

    -- Verificação de suporte a Drawing
    if not Drawing then
        warn("[ERRO] Seu executor não suporta a biblioteca 'Drawing'. O FOV não aparecerá.")
    else
        print("[DEBUG] Biblioteca Drawing detectada.")
    end

    -- Criação do FOV Circle
    local success, fov_circle = pcall(function()
        local circle = Drawing.new("Circle")
        circle.Visible = true
        circle.Thickness = 2
        circle.Transparency = 1 -- 1 é visível na maioria das libs
        circle.Color = config.FOVColor1
        circle.Filled = false
        circle.NumSides = config.FOVNumSides or 20
        return circle
    end)

    if success then
        _G.AimFOVCircle = fov_circle
        print("[DEBUG] Círculo FOV criado com sucesso.")
    else
        warn("[ERRO] Falha ao criar Círculo FOV:", fov_circle)
    end

    -- Criação da GUI (HUD Melhorado)
    local SafeParent = (gethui and gethui()) or CoreGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SilentAimHUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.Parent = SafeParent
    _G.AimbotGui = ScreenGui

    -- Highlight
    local TargetHighlight = Instance.new("Highlight")
    TargetHighlight.Name = "TargetFX"
    TargetHighlight.FillTransparency = 0.85
    TargetHighlight.OutlineTransparency = 0.1
    TargetHighlight.OutlineColor = config.HighlightColor
    TargetHighlight.FillColor = config.HighlightColor
    TargetHighlight.Parent = ScreenGui
    _G.AimHighlight = TargetHighlight

    -- Billboard para ESP (Reestilizado)
    local FeetBillboard = Instance.new("BillboardGui")
    FeetBillboard.Size = UDim2.new(0, 200, 0, 100) 
    FeetBillboard.StudsOffset = Vector3New(0, -5, 0)
    FeetBillboard.AlwaysOnTop = true
    FeetBillboard.Enabled = false
    FeetBillboard.Parent = ScreenGui

    -- Container do HUD com fundo escuro e bordas
    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "Container"
    MainContainer.Size = UDim2.new(0.9, 0, 0.9, 0)
    MainContainer.Position = UDim2.new(0.05, 0, 0, 0)
    MainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainContainer.BackgroundTransparency = 0.3
    MainContainer.Parent = FeetBillboard
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainContainer

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = config.OutlineColor or config.HighlightColor
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.2
    UIStroke.Parent = MainContainer

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = MainContainer
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ListLayout.Padding = UDim.new(0, 2)
    
    -- Função helper para criar labels
    local function createLabel(order, defaultText, color, font)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color
        lbl.Font = font
        lbl.TextSize = 12
        lbl.TextStrokeTransparency = 0.8
        lbl.Text = defaultText
        lbl.LayoutOrder = order
        lbl.Parent = MainContainer
        return lbl
    end

    local NameLabel = createLabel(1, "Player Name", Color3.new(1,1,1), Enum.Font.GothamBold)
    NameLabel.TextSize = 14
    local TeamLabel = createLabel(2, "Team", Color3.new(0.8,0.8,0.8), Enum.Font.Gotham)
    local WeaponLabel = createLabel(3, "Weapon", Color3.new(0.9,0.9,0.9), Enum.Font.Gotham)
    local HPText = createLabel(4, "HP: 100", Color3.new(0,1,0), Enum.Font.Code)

    -- Variáveis de controle de Debug
    local lastDebugTime = 0
    local debugInterval = 2 -- Segundos entre mensagens de debug

    -- Loop de Renderização
    local c1 = RunService.RenderStepped:Connect(function()
        local now = OsClock()
        
        -- Lógica FOV
        if _G.AimFOVCircle then
            if _G.SilentAimActive and config.ShowFOV then
                _G.AimFOVCircle.Visible = true
                _G.AimFOVCircle.Radius = config.FOVSize
                _G.AimFOVCircle.NumSides = config.FOVNumSides or 20
                
                -- Gradiente
                local speed = config.GradientSpeed or 4
                local alpha = (MathSin(now * speed) + 1) / 2
                local c1 = config.FOVColor1
                local c2 = config.FOVColor2
                _G.AimFOVCircle.Color = c1:Lerp(c2, alpha)

                local pos
                if config.FOVBehavior == "Mouse" then
                     pos = UserInputService:GetMouseLocation()
                else
                     pos = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                end
                _G.AimFOVCircle.Position = pos
            else
                _G.AimFOVCircle.Visible = false
            end
        elseif config.ShowFOV and _G.SilentAimActive then
             -- Tentar recuperar se for nil e deveria estar mostrando
             if now - lastDebugTime > debugInterval then
                warn("[DEBUG] _G.AimFOVCircle é nulo, mas ShowFOV está ativado.")
             end
        end

        -- Debug Periódico
        if now - lastDebugTime > debugInterval then
            lastDebugTime = now
            if not _G.AimFOVCircle then
                print("[DEBUG] Status FOV: Objeto Inexistente")
            elseif not _G.AimFOVCircle.Visible and config.ShowFOV then
                 -- Se o script acha que está visível, mas não está
                 print("[DEBUG] Status FOV: Oculto (Possível conflito de renderização ou 'Active' false). Active:", _G.SilentAimActive)
            end
        end

        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        
            if Character then
                -- Highlight Update
                if config.ShowHighlight then
                    TargetHighlight.Adornee = Character
                    TargetHighlight.Enabled = true
                    TargetHighlight.OutlineColor = config.HighlightColor
                    TargetHighlight.FillColor = config.HighlightColor
                    UIStroke.Color = config.HighlightColor -- Atualiza borda do HUD também
                else
                    TargetHighlight.Enabled = false
                end

                -- ESP / HUD Update
                if config.ESP.Enabled then
                    local root = Character:FindFirstChild("HumanoidRootPart")
                    local hum = Character:FindFirstChild("Humanoid")
                    
                    if root and hum then
                        FeetBillboard.Adornee = root
                        FeetBillboard.Enabled = true
                        
                        -- Nome
                        if config.ESP.ShowName then
                            NameLabel.Visible = true
                            NameLabel.Text = Character.Name
                            NameLabel.TextColor3 = config.ESP.TextColor
                        else
                            NameLabel.Visible = false
                        end
                        
                        -- Time
                        if config.ESP.ShowTeam then
                            TeamLabel.Visible = true
                            local plr = Players:GetPlayerFromCharacter(Character)
                            if plr then
                                TeamLabel.Text = plr.Team and ("Time: " .. plr.Team.Name) or "Sem Time"
                                TeamLabel.TextColor3 = plr.TeamColor and plr.TeamColor.Color or Color3.new(1,1,1)
                            else
                                TeamLabel.Text = "NPC"
                            end
                        else
                            TeamLabel.Visible = false
                        end
                        
                        -- Arma
                        if config.ESP.ShowWeapon then
                            WeaponLabel.Visible = true
                            local tool = Character:FindFirstChildWhichIsA("Tool")
                            if tool then
                                WeaponLabel.Text = "Usando: " .. string.upper(tool.Name)
                            else
                                WeaponLabel.Text = "Mãos Livres"
                            end
                        else
                            WeaponLabel.Visible = false
                        end

                        -- Vida
                        if config.ESP.ShowHealth then
                            HPText.Visible = true
                            local health = hum.Health
                            local maxHealth = hum.MaxHealth
                            HPText.Text = string.format("HP: %d / %d", health, maxHealth)
                            
                            local hue = MathClamp(health / maxHealth, 0, 1) * 0.33
                            HPText.TextColor3 = Color3.fromHSV(hue, 1, 1)
                        else
                            HPText.Visible = false
                        end
                    end
                else
                    FeetBillboard.Enabled = false
                end
            else
                TargetHighlight.Enabled = false
                FeetBillboard.Enabled = false
            end
        end
    end)
    table.insert(_G.SilentAimConnections, c1)
end

-- HOOK (INTACTO)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not checkcaller() and _G.SilentAimActive and ClosestHitPart then
        local Method = getnamecallmethod()
        
        if MathRandom(1, 100) <= _G.AimbotConfig.HitChance then
            
            if (Method == "FireServer" or Method == "InvokeServer") then
                if isBulletRemote(self.Name) then
                    local Arguments = {...}
                    local finalPosition = ClosestHitPart.Position + getLegitOffset()
                    local cameraPos = Camera.CFrame.Position
                    local Direction = (finalPosition - cameraPos).Unit

                    for i = 1, #Arguments do
                        local v = Arguments[i]
                        if typeof(v) == "Vector3" then
                            Arguments[i] = (v.Magnitude <= 10) and Direction or finalPosition
                        elseif typeof(v) == "CFrame" then
                            Arguments[i] = CFrameNew(cameraPos, finalPosition)
                        end
                    end
                    return oldNamecall(self, unpack(Arguments))
                end
            elseif Method == "Raycast" and self == Workspace then
                local Arguments = {...}
                local origin = Arguments[1]
                local finalPosition = ClosestHitPart.Position + getLegitOffset()
                Arguments[2] = (finalPosition - origin).Unit * 10000 
                return oldNamecall(self, unpack(Arguments))
            end
        end
    end
    return oldNamecall(self, ...)
end))

if _G.AimbotConfig and _G.AimbotConfig.Enabled then
    _G.StartSilentAim()
end
