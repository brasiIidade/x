-- [[ CONFIGURAÇÃO INICIAL E LÓGICA ]] --

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

-- Lista de remotes de tiro comuns
local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", 
    "missile", "rocket", "hit", "damage", "attack", 
    "cast", "ray", "target", "server", "remote", "action", 
    "mouse", "input", "create"
}

-- Mapeamento para garantir que funcione em R6 e R15
local PartMapping = {
    ["UpperTorso"] = "Torso",
    ["LowerTorso"] = "Torso",
    ["Torso"] = "UpperTorso" -- Tentativa inversa
}

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

-- Verifica se a parte está na lista de alvos da UI
local function IsValidTargetPart(partName)
    local targets = _G.AimbotConfig.TargetPart
    if not targets or #targets == 0 then return true end -- Se vazio, aceita tudo (fallback)
    
    for _, t in ipairs(targets) do
        if t == "Random" then return true end
        if t == partName then return true end
        if PartMapping[t] == partName then return true end -- Checa R6/R15
    end
    return false
end

-- Lógica Principal de Detecção melhorada
local function getClosestPlayer()
    local BestPart = nil
    local BestChar = nil
    local ClosestDistToCenter = _G.AimbotConfig.FOVSize -- Começa com o limite do FOV
    
    -- Define o centro (Mouse ou Meio da Tela)
    local OriginPos
    if _G.AimbotConfig.FOVBehavior == "Mouse" then
        OriginPos = UserInputService:GetMouseLocation()
    else
        OriginPos = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    local myPos = Camera.CFrame.Position

    for _, Player in Pairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        
        -- Checagem de Time
        if _G.AimbotConfig.TeamCheck == "Team" and Player.Team == LocalPlayer.Team then continue end
        
        -- Modo Foco e Whitelist
        if _G.AimbotConfig.FocusMode then
            if not table.find(_G.AimbotConfig.FocusList, Player.Name) then continue end
        else
            if isWhitelisted(Player) then continue end
        end

        local Character = Player.Character
        if not Character then continue end
        
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then continue end
        
        -- Checagem de Distância Máxima (baseada no RootPart para performance)
        local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso")
        if RootPart then
            local dist3D = (RootPart.Position - myPos).Magnitude
            if dist3D > _G.AimbotConfig.MaxDistance then continue end
        end

        -- ITERAÇÃO SOBRE TODAS AS PARTES DO CORPO
        -- Isso corrige o bug de não detectar se só o braço estiver no FOV
        for _, part in Pairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                -- Verifica se essa parte deve ser mirada (Config da UI)
                if IsValidTargetPart(part.Name) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    
                    if onScreen then
                        local dist2D = (OriginPos - Vector2New(screenPos.X, screenPos.Y)).Magnitude
                        
                        -- Se a parte está no FOV e é a mais próxima do centro até agora
                        if dist2D < ClosestDistToCenter then
                            if IsPartVisible(part, Character) then
                                ClosestDistToCenter = dist2D
                                BestPart = part
                                BestChar = Character
                            end
                        end
                    end
                end
            end
        end
    end
    
    return BestPart, BestChar
end

-- Funções de Controle do Script
_G.StopSilentAim = function()
    _G.SilentAimActive = false
    
    for _, conn in pairs(_G.SilentAimConnections) do
        if conn then conn:Disconnect() end
    end
    _G.SilentAimConnections = {}

    if _G.AimFOVCircle then _G.AimFOVCircle:Remove(); _G.AimFOVCircle = nil end
    if _G.AimbotGui then _G.AimbotGui:Destroy(); _G.AimbotGui = nil end
    if _G.AimHighlight then _G.AimHighlight:Destroy(); _G.AimHighlight = nil end
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

_G.StartSilentAim = function()
    _G.StopSilentAim()
    _G.SilentAimActive = true
    local config = _G.AimbotConfig

    -- Desenho do FOV
    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false
    fov_circle.Thickness = 1.5
    fov_circle.Transparency = 0.8
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    -- GUI Segura
    local SafeParent = (gethui and gethui()) or CoreGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.Parent = SafeParent
    _G.AimbotGui = ScreenGui

    -- Highlight (Brilho no personagem)
    local TargetHighlight = Instance.new("Highlight")
    TargetHighlight.Name = "TargetFX"
    TargetHighlight.FillTransparency = 0.85
    TargetHighlight.OutlineTransparency = 0.1
    TargetHighlight.OutlineColor = config.HighlightColor
    TargetHighlight.FillColor = config.HighlightColor
    TargetHighlight.Parent = ScreenGui
    _G.AimHighlight = TargetHighlight

    -- Billboard (Info em cima da cabeça)
    local HeadBillboard = Instance.new("BillboardGui")
    HeadBillboard.Size = UDim2.new(0, 200, 0, 70) 
    HeadBillboard.StudsOffset = Vector3New(0, 4, 0)
    HeadBillboard.AlwaysOnTop = true
    HeadBillboard.Enabled = false
    HeadBillboard.Parent = ScreenGui

    local MainContainer = Instance.new("Frame")
    MainContainer.Parent = HeadBillboard
    MainContainer.AnchorPoint = Vector2.new(0.5, 1)
    MainContainer.Position = UDim2.fromScale(0.5, 1)
    MainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainContainer.BackgroundTransparency = 0.2
    MainContainer.Size = UDim2.new(1, 0, 1, 0)

    local ContainerStroke = Instance.new("UIStroke")
    ContainerStroke.Parent = MainContainer
    ContainerStroke.Thickness = 1.5
    ContainerStroke.Color = config.HighlightColor
    ContainerStroke.Transparency = 0.3

    Instance.new("UICorner", MainContainer).CornerRadius = UDim.new(0, 6)
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = MainContainer
    ListLayout.FillDirection = Enum.FillDirection.Vertical
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Labels de Info
    local NameLabel = Instance.new("TextLabel", MainContainer)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 13
    NameLabel.TextColor3 = Color3.new(1,1,1)
    NameLabel.Text = "Nome"

    local HPText = Instance.new("TextLabel", MainContainer)
    HPText.BackgroundTransparency = 1
    HPText.Size = UDim2.new(0.9, 0, 0.25, 0)
    HPText.Font = Enum.Font.Code
    HPText.TextSize = 11
    HPText.TextColor3 = Color3.fromRGB(0, 255, 150)
    HPText.Text = "HP"

    local WeaponLabel = Instance.new("TextLabel", MainContainer)
    WeaponLabel.BackgroundTransparency = 1
    WeaponLabel.Size = UDim2.new(0.9, 0, 0.25, 0)
    WeaponLabel.Font = Enum.Font.Gotham
    WeaponLabel.TextSize = 11
    WeaponLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    WeaponLabel.Text = "Item"

    -- Loop de Renderização (Visuais)
    local c1 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive and config.ShowFOV then
            fov_circle.Visible = true
            fov_circle.Radius = config.FOVSize
            fov_circle.Color = config.FOVColor1
            if config.FOVBehavior == "Mouse" then
                fov_circle.Position = UserInputService:GetMouseLocation()
            else
                fov_circle.Position = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            end
        else
            fov_circle.Visible = false
        end
    end)
    table.insert(_G.SilentAimConnections, c1)

    -- Loop de Lógica (Targeting)
    local c2 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive then
            -- AQUI CHAMA A NOVA FUNÇÃO DE DETECÇÃO
            local Part, Character = getClosestPlayer()
            
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        
            -- Atualiza Highlight
            if config.ShowHighlight and Character then
                TargetHighlight.Adornee = Character
                TargetHighlight.Enabled = true
                TargetHighlight.OutlineColor = config.HighlightColor
                ContainerStroke.Color = config.HighlightColor
            else
                TargetHighlight.Adornee = nil
                TargetHighlight.Enabled = false
            end

            -- Atualiza HUD (ESP)
            if config.ESP.Enabled and Character and Part then
                local head = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")
                local hum = Character:FindFirstChild("Humanoid")
                
                if head and hum then
                    HeadBillboard.Adornee = head
                    HeadBillboard.Enabled = true
                    
                    NameLabel.Visible = config.ESP.ShowName
                    NameLabel.Text = Character.Name
                    
                    HPText.Visible = config.ESP.ShowHealth
                    HPText.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
                    
                    WeaponLabel.Visible = config.ESP.ShowWeapon
                    local tool = Character:FindFirstChildWhichIsA("Tool")
                    WeaponLabel.Text = tool and tool.Name or "Nada"
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

-- Hook para redirecionar os tiros
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
                            -- Verifica se é direção ou posição
                            if v.Magnitude <= 50 then 
                                Arguments[i] = (finalPosition - cameraPos).Unit
                            else
                                Arguments[i] = finalPosition
                            end
                        elseif typeof(v) == "CFrame" then
                            Arguments[i] = CFrame.new(cameraPos, finalPosition)
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
