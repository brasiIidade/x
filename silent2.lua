-- [[ CONFIGURAÇÃO E LÓGICA ]] --

_G.AimbotConfig = _G.AimbotConfig or {
    Enabled = false,
    TeamCheck = "Team",
    TargetPart = {"Random"},
    MaxDistance = 1000,
    SwitchThreshold = 1,
    WhitelistedUsers = {},
    WhitelistedTeams = {},
    FocusList = {},
    FocusMode = false,
    UseLegitOffset = true,
    HitChance = 100,
    WallCheck = true,
    FOVSize = 200,
    ShowFOV = true,
    FOVBehavior = "Center",
    FOVColor1 = Color3.fromRGB(255, 255, 255),
    ShowHighlight = true,
    HighlightColor = Color3.fromRGB(255, 60, 60), -- Cor do HUD e do Tracer
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Vector2New = Vector2.new
local Vector3New = Vector3.new
local MathRandom = math.random
local IPairs = ipairs
local Pairs = pairs
local StringLower = string.lower
local StringFind = string.find
local MathHuge = math.huge
local MathFloor = math.floor

_G.SilentAimConnections = {}
_G.SilentAimActive = false
local ClosestHitPart = nil
local CurrentTargetCharacter = nil

local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", 
    "missile", "rocket", "hit", "damage", "attack", 
    "cast", "ray", "target", "server", "remote", "action", 
    "mouse", "input", "create"
}

-- Mapeamento inteligente para R6 e R15
local function IsMatch(partName, configName)
    if configName == "Random" then return true end
    if partName == configName then return true end
    
    -- Compatibilidade Torso
    if (configName == "Torso" or configName == "UpperTorso") and (partName == "Torso" or partName == "UpperTorso" or partName == "LowerTorso") then return true end
    
    -- Compatibilidade Braços
    if configName == "Left Arm" and (partName == "Left Arm" or partName == "LeftUpperArm" or partName == "LeftLowerArm" or partName == "LeftHand") then return true end
    if configName == "Right Arm" and (partName == "Right Arm" or partName == "RightUpperArm" or partName == "RightLowerArm" or partName == "RightHand") then return true end
    
    -- Compatibilidade Pernas
    if configName == "Left Leg" and (partName == "Left Leg" or partName == "LeftUpperLeg" or partName == "LeftLowerLeg" or partName == "LeftFoot") then return true end
    if configName == "Right Leg" and (partName == "Right Leg" or partName == "RightUpperLeg" or partName == "RightLowerLeg" or partName == "RightFoot") then return true end
    
    return false
end

local function getLegitOffset()
    if not _G.AimbotConfig.UseLegitOffset then return Vector3New(0,0,0) end
    return Vector3New(
        (MathRandom() - 0.5) * (MathRandom(1, 35) / 10),
        (MathRandom() - 0.5) * (MathRandom(1, 35) / 10),
        (MathRandom() - 0.5) * (MathRandom(1, 35) / 10)
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
    if #_G.AimbotConfig.WhitelistedUsers > 0 then
        if table.find(_G.AimbotConfig.WhitelistedUsers, player.Name) then return true end
    end
    if player.Team and #_G.AimbotConfig.WhitelistedTeams > 0 then
        if table.find(_G.AimbotConfig.WhitelistedTeams, player.Team.Name) then return true end
    end
    return false
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

local function IsPartVisible(part, character)
    if not _G.AimbotConfig.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, character, Camera, _G.AimbotGui}
    local rayResult = Workspace:Raycast(origin, direction, RayParams)
    return rayResult == nil
end

-- Lógica de Detecção Robusta
local function getClosestPlayer()
    local BestPart = nil
    local BestChar = nil
    local ClosestDistToCenter = _G.AimbotConfig.FOVSize 
    
    -- Define origem do FOV
    local OriginPos
    if _G.AimbotConfig.FOVBehavior == "Mouse" then
        OriginPos = UserInputService:GetMouseLocation()
    else
        OriginPos = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    local myPos = Camera.CFrame.Position

    for _, Player in Pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        if _G.AimbotConfig.TeamCheck == "Team" and Player.Team == LocalPlayer.Team then continue end
        
        if _G.AimbotConfig.FocusMode then
            if not table.find(_G.AimbotConfig.FocusList, Player.Name) then continue end
        else
            if isWhitelisted(Player) then continue end
        end

        local Character = Player.Character
        if not Character then continue end
        
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then continue end
        
        -- Checagem de Distância (Root)
        local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso")
        if RootPart then
            local dist3D = (RootPart.Position - myPos).Magnitude
            if dist3D > _G.AimbotConfig.MaxDistance then continue end
        end

        -- 1. Verifica se ALGUMA parte do corpo está no FOV
        local isInFOV = false
        for _, child in Pairs(Character:GetChildren()) do
            if child:IsA("BasePart") then
                local screenPos, onScreen = Camera:WorldToViewportPoint(child.Position)
                if onScreen then
                    local dist2D = (OriginPos - Vector2New(screenPos.X, screenPos.Y)).Magnitude
                    if dist2D <= _G.AimbotConfig.FOVSize then
                        isInFOV = true
                        break -- Já sabemos que está no FOV
                    end
                end
            end
        end

        -- 2. Se estiver no FOV, escolhe a melhor parte baseada na Config
        if isInFOV then
            -- Procura a parte desejada (ex: Head, Left Arm, ou Random)
            local potentialParts = {}
            local targets = _G.AimbotConfig.TargetPart
            if typeof(targets) ~= "table" then targets = {targets} end

            for _, child in Pairs(Character:GetChildren()) do
                if child:IsA("BasePart") then
                    -- Verifica se a parte bate com a config
                    local matchesConfig = false
                    for _, tName in ipairs(targets) do
                        if IsMatch(child.Name, tName) then
                            matchesConfig = true
                            break
                        end
                    end

                    if matchesConfig and IsPartVisible(child, Character) then
                        table.insert(potentialParts, child)
                    end
                end
            end

            -- Se achou partes válidas, pega a mais próxima do centro
            for _, part in ipairs(potentialParts) do
                local screenPos = Camera:WorldToViewportPoint(part.Position)
                local dist2D = (OriginPos - Vector2New(screenPos.X, screenPos.Y)).Magnitude
                
                if dist2D < ClosestDistToCenter then
                    ClosestDistToCenter = dist2D
                    BestPart = part
                    BestChar = Character
                end
            end
        end
    end
    
    return BestPart, BestChar
end

_G.StopSilentAim = function()
    _G.SilentAimActive = false
    
    for _, conn in pairs(_G.SilentAimConnections) do
        if conn then conn:Disconnect() end
    end
    _G.SilentAimConnections = {}

    if _G.AimFOVCircle then _G.AimFOVCircle:Remove(); _G.AimFOVCircle = nil end
    if _G.AimTracer then _G.AimTracer:Remove(); _G.AimTracer = nil end
    if _G.AimbotGui then _G.AimbotGui:Destroy(); _G.AimbotGui = nil end
    if _G.AimHighlight then _G.AimHighlight:Destroy(); _G.AimHighlight = nil end
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

_G.StartSilentAim = function()
    _G.StopSilentAim()
    _G.SilentAimActive = true
    local config = _G.AimbotConfig

    -- VISUAIS: FOV
    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false
    fov_circle.Thickness = 1.5
    fov_circle.Transparency = 0.8
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    -- VISUAIS: TRACER (LINHA)
    local tracer_line = Drawing.new("Line")
    tracer_line.Visible = false
    tracer_line.Thickness = 1
    tracer_line.Transparency = 0.8
    tracer_line.Color = config.HighlightColor -- Mesma cor do HUD/Highlight
    _G.AimTracer = tracer_line

    local SafeParent = (gethui and gethui()) or CoreGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.Parent = SafeParent
    _G.AimbotGui = ScreenGui

    -- Highlight (Brilho no Personagem)
    local TargetHighlight = Instance.new("Highlight")
    TargetHighlight.Name = "TargetFX"
    TargetHighlight.FillTransparency = 0.85
    TargetHighlight.OutlineTransparency = 0.1
    TargetHighlight.OutlineColor = config.HighlightColor
    TargetHighlight.FillColor = config.HighlightColor
    TargetHighlight.Parent = ScreenGui
    _G.AimHighlight = TargetHighlight

    -- HUD (Info sobre a cabeça)
    local HeadBillboard = Instance.new("BillboardGui")
    HeadBillboard.Size = UDim2.new(0, 200, 0, 70) 
    HeadBillboard.StudsOffset = Vector3New(0, 4, 0)
    HeadBillboard.AlwaysOnTop = true
    HeadBillboard.Enabled = false
    HeadBillboard.Parent = ScreenGui

    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.AnchorPoint = Vector2.new(0.5, 1)
    MainContainer.Position = UDim2.fromScale(0.5, 1)
    MainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainContainer.BackgroundTransparency = 0.2
    MainContainer.BorderSizePixel = 0
    MainContainer.Size = UDim2.new(1, 0, 1, 0)
    MainContainer.Parent = HeadBillboard

    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 6)
    ContainerCorner.Parent = MainContainer

    local ContainerStroke = Instance.new("UIStroke")
    ContainerStroke.Thickness = 1.5
    ContainerStroke.Color = config.HighlightColor
    ContainerStroke.Transparency = 0.3
    ContainerStroke.Parent = MainContainer

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = MainContainer
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Info Labels
    local InfoRow = Instance.new("Frame", MainContainer)
    InfoRow.BackgroundTransparency = 1; InfoRow.Size = UDim2.new(1,0,0,16)
    local NameLabel = Instance.new("TextLabel", InfoRow)
    NameLabel.BackgroundTransparency = 1; NameLabel.Size = UDim2.new(0.6,0,1,0); NameLabel.Font = Enum.Font.GothamBold; NameLabel.TextColor3 = Color3.new(1,1,1); NameLabel.TextSize = 13; NameLabel.TextXAlignment = Enum.TextXAlignment.Left; NameLabel.Position = UDim2.new(0.05,0,0,0)
    
    local HealthRow = Instance.new("Frame", MainContainer)
    HealthRow.BackgroundTransparency = 1; HealthRow.Size = UDim2.new(1,0,0,12)
    local HPText = Instance.new("TextLabel", HealthRow)
    HPText.BackgroundTransparency = 1; HPText.Size = UDim2.new(1,0,1,0); HPText.Font = Enum.Font.Code; HPText.TextColor3 = Color3.fromRGB(0,255,150); HPText.TextSize = 10
    
    local WeaponRow = Instance.new("Frame", MainContainer)
    WeaponRow.BackgroundTransparency = 1; WeaponRow.Size = UDim2.new(1,0,0,14)
    local WeaponLabel = Instance.new("TextLabel", WeaponRow)
    WeaponLabel.BackgroundTransparency = 1; WeaponLabel.Size = UDim2.new(1,0,1,0); WeaponLabel.Font = Enum.Font.Gotham; WeaponLabel.TextColor3 = Color3.fromRGB(180,180,180); WeaponLabel.TextSize = 11

    -- Loop Visual (FOV + Tracer)
    local c1 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive and config.ShowFOV then
            local origin
            if config.FOVBehavior == "Mouse" then
                origin = UserInputService:GetMouseLocation()
            else
                origin = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            end

            fov_circle.Visible = true
            fov_circle.Radius = config.FOVSize
            fov_circle.Color = config.FOVColor1
            fov_circle.Position = origin
            
            -- Atualiza TRACER
            if ClosestHitPart and config.ShowHighlight then -- Só mostra tracer se tiver highlight ativo (faz parte do visual)
                local partPos, onScreen = Camera:WorldToScreenPoint(ClosestHitPart.Position)
                if onScreen then
                    tracer_line.From = origin -- Sai do centro do FOV
                    tracer_line.To = Vector2New(partPos.X, partPos.Y) -- Vai até a parte mirada
                    tracer_line.Color = config.HighlightColor -- Sincroniza cor
                    tracer_line.Visible = true
                else
                    tracer_line.Visible = false
                end
            else
                tracer_line.Visible = false
            end
        else
            fov_circle.Visible = false
            tracer_line.Visible = false
        end
    end)
    table.insert(_G.SilentAimConnections, c1)

    -- Loop Lógica
    local c2 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        
            -- Cores dinâmicas
            TargetHighlight.FillColor = config.HighlightColor
            TargetHighlight.OutlineColor = config.HighlightColor
            ContainerStroke.Color = config.HighlightColor
            if _G.AimTracer then _G.AimTracer.Color = config.HighlightColor end

            if config.ShowHighlight and Character then
                TargetHighlight.Adornee = Character
                TargetHighlight.Enabled = true
            else
                TargetHighlight.Adornee = nil
                TargetHighlight.Enabled = false
            end

            if config.ESP.Enabled and Character then
                local head = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")
                local hum = Character:FindFirstChild("Humanoid")
                
                if head and hum then
                    HeadBillboard.Adornee = head
                    HeadBillboard.Enabled = true
                    
                    NameLabel.Visible = config.ESP.ShowName
                    NameLabel.Text = Character.Name
                    
                    HPText.Visible = config.ESP.ShowHealth
                    HPText.Text = string.format("[ %d / %d ]", math.floor(hum.Health), math.floor(hum.MaxHealth))
                    
                    WeaponLabel.Visible = config.ESP.ShowWeapon
                    local tool = Character:FindFirstChildWhichIsA("Tool")
                    WeaponLabel.Text = tool and string.upper(tool.Name) or "NADA"
                else
                    HeadBillboard.Enabled = false
                end
            else
                HeadBillboard.Enabled = false
            end
        else
            ClosestHitPart = nil
            CurrentTargetCharacter = nil
            TargetHighlight.Enabled = false
            HeadBillboard.Enabled = false
        end
    end)
    table.insert(_G.SilentAimConnections, c2)
end

-- Hook Tiro
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not checkcaller() and _G.SilentAimActive and ClosestHitPart and _G.AimbotConfig.Enabled then
        local Method = getnamecallmethod()
        
        if MathRandom(1, 100) <= _G.AimbotConfig.HitChance then
            local Arguments = {...}

            if Method == "Raycast" and self == Workspace then
                local finalPosition = ClosestHitPart.Position + getLegitOffset()
                local origin = Arguments[1] 
                local direction = (finalPosition - origin).Unit * 1000 
                Arguments[2] = direction 
                return oldNamecall(self, unpack(Arguments))
            
            elseif (Method == "FireServer" or Method == "InvokeServer") then
                if isBulletRemote(self.Name) then
                    local finalPosition = ClosestHitPart.Position + getLegitOffset()
                    local cameraPos = Camera.CFrame.Position
                    
                    for i, v in Pairs(Arguments) do
                        if typeof(v) == "Vector3" then
                            if v.Magnitude <= 50 then 
                                Arguments[i] = (finalPosition - cameraPos).Unit
                            else
                                Arguments[i] = finalPosition
                            end
                        elseif typeof(v) == "CFrame" then
                            Arguments[i] = CFrameNew(cameraPos, finalPosition)
                        elseif typeof(v) == "table" then
                            for k, subVal in Pairs(v) do
                                if typeof(subVal) == "Vector3" then
                                     if subVal.Magnitude <= 50 then
                                        v[k] = (finalPosition - cameraPos).Unit
                                     else
                                        v[k] = finalPosition
                                     end
                                end
                            end
                        end
                    end
                    return oldNamecall(self, unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(self, ...)
end))
