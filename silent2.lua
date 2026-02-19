--[[
    Lógica Backend do Silent Aim
    Melhorias de segurança (anti-detecção) aplicadas usando clonefunction.
    Todas as funcionalidades da UI foram implementadas.
    O Hook de tiro foi mantido INTACTO.
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

-- Configuração Global (Sincronizada com a UI)
_G.AimbotConfig = _G.AimbotConfig or {
    Enabled = false,
    TeamCheck = "Team",         
    TargetPart = {"Random"},
    TargetPriority = "Distance", -- "Distance" ou "Health"
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
    FOVBehavior = "Center", -- "Mouse" ou "Center"
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
    local TeamCheckType = _G.AimbotConfig.TeamCheck -- "Team" or "All"
    local FocusMode = _G.AimbotConfig.FocusMode
    local FocusList = _G.AimbotConfig.FocusList
    local Priority = _G.AimbotConfig.TargetPriority or "Distance"

    for _, Player in IPairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        
        -- Lógica de Time (Team Check)
        if TeamCheckType == "Team" and Player.Team == MyTeam then continue end

        -- Lógica de Foco e Whitelist
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
                    currentScore = Humanoid.Health -- Menor vida = melhor
                else
                    currentScore = dist2D -- Menor distância do cursor = melhor
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

    -- Criação do FOV Circle
    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false 
    fov_circle.Thickness = 2
    fov_circle.Transparency = 1
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = config.FOVNumSides or 20
    _G.AimFOVCircle = fov_circle

    -- Criação da GUI
    local SafeParent = (gethui and gethui()) or CoreGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HUD"
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

    -- Billboard para ESP
    local FeetBillboard = Instance.new("BillboardGui")
    FeetBillboard.Size = UDim2.new(0, 200, 0, 90) 
    FeetBillboard.StudsOffset = Vector3New(0, -5, 0)
    FeetBillboard.AlwaysOnTop = true
    FeetBillboard.Enabled = false
    FeetBillboard.Parent = ScreenGui

    local MainContainer = Instance.new("Frame")
    MainContainer.Size = UDim2.new(1,0,1,0)
    MainContainer.BackgroundTransparency = 1
    MainContainer.Parent = FeetBillboard
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = MainContainer
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    ListLayout.Padding = UDim.new(0, 2)
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1,0,0,16)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.new(1,1,1)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 14
    NameLabel.TextStrokeTransparency = 0.5
    NameLabel.LayoutOrder = 1
    NameLabel.Parent = MainContainer
    
    local TeamLabel = Instance.new("TextLabel")
    TeamLabel.Size = UDim2.new(1,0,0,14)
    TeamLabel.BackgroundTransparency = 1
    TeamLabel.TextColor3 = Color3.new(0.8,0.8,0.8)
    TeamLabel.Font = Enum.Font.Gotham
    TeamLabel.TextSize = 12
    TeamLabel.TextStrokeTransparency = 0.5
    TeamLabel.LayoutOrder = 2
    TeamLabel.Parent = MainContainer
    
    local WeaponLabel = Instance.new("TextLabel")
    WeaponLabel.Size = UDim2.new(1,0,0,14)
    WeaponLabel.BackgroundTransparency = 1
    WeaponLabel.TextColor3 = Color3.new(0.9,0.9,0.9)
    WeaponLabel.Font = Enum.Font.Gotham
    WeaponLabel.TextSize = 12
    WeaponLabel.TextStrokeTransparency = 0.5
    WeaponLabel.LayoutOrder = 3
    WeaponLabel.Parent = MainContainer

    local HPText = Instance.new("TextLabel")
    HPText.Size = UDim2.new(1,0,0,14)
    HPText.BackgroundTransparency = 1
    HPText.TextColor3 = Color3.new(0,1,0)
    HPText.Font = Enum.Font.Code
    HPText.TextSize = 12
    HPText.TextStrokeTransparency = 0.5
    HPText.LayoutOrder = 4
    HPText.Parent = MainContainer

    -- Loop de Renderização
    local c1 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive and config.ShowFOV and fov_circle then
            fov_circle.Visible = true
            fov_circle.Radius = config.FOVSize
            fov_circle.NumSides = config.FOVNumSides or 20
            
            -- Lógica de Gradiente/Pulsar
            local tick = OsClock()
            local speed = config.GradientSpeed or 4
            local alpha = (MathSin(tick * speed) + 1) / 2
            local c1 = config.FOVColor1
            local c2 = config.FOVColor2
            fov_circle.Color = c1:Lerp(c2, alpha)

            local pos = config.FOVBehavior == "Mouse" and UserInputService:GetMouseLocation() or Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fov_circle.Position = pos
        else
            if fov_circle then fov_circle.Visible = false end
        end

        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        
            if Character then
                if config.ShowHighlight then
                    TargetHighlight.Adornee = Character
                    TargetHighlight.Enabled = true
                    TargetHighlight.OutlineColor = config.HighlightColor
                    TargetHighlight.FillColor = config.HighlightColor
                else
                    TargetHighlight.Enabled = false
                end

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
                                TeamLabel.Text = plr.Team and plr.Team.Name or "Sem Time"
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
                                WeaponLabel.Text = string.upper(tool.Name)
                            else
                                WeaponLabel.Text = "NADA EQUIPADO"
                            end
                        else
                            WeaponLabel.Visible = false
                        end

                        -- Vida
                        if config.ESP.ShowHealth then
                            HPText.Visible = true
                            local health = hum.Health
                            local maxHealth = hum.MaxHealth
                            HPText.Text = string.format("[%d / %d]", health, maxHealth)
                            
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

-- HOOK (INTACTO CONFORME SOLICITADO)
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
