--[[ 
    SILENT AIM LOGIC - OPTIMIZED & SECURE
    Implementação completa do Backend para suportar a UI.
]]

--// Serviços e Otimização de Segurança (Anti-Detecção Básica)
local g = game
local clonefunction = clonefunction or function(f) return f end
local gethui = gethui or function() return g:GetService("CoreGui") end

-- Clonagem de funções críticas para evitar hooks de anti-cheat
local GetService = clonefunction(g.GetService)
local FindFirstChild = clonefunction(g.FindFirstChild)
local FindFirstChildWhichIsA = clonefunction(g.FindFirstChildWhichIsA)
local IsDescendantOf = clonefunction(g.IsDescendantOf)
local WorldToScreenPoint = clonefunction(g.GetService(g, "Workspace").CurrentCamera.WorldToScreenPoint)
local Raycast = clonefunction(g.GetService(g, "Workspace").Raycast)
local GetPlayers = clonefunction(g.GetService(g, "Players").GetPlayers)
local GetMouseLocation = clonefunction(g.GetService(g, "UserInputService").GetMouseLocation)

-- Serviços
local Players = GetService(g, "Players")
local RunService = GetService(g, "RunService")
local Workspace = GetService(g, "Workspace")
local UserInputService = GetService(g, "UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Otimização de Matemática e Tabelas
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local CFrameNew = CFrame.new
local MathRandom = math.random
local MathHuge = math.huge
local MathClamp = math.clamp
local MathFloor = math.floor
local MathRad = math.rad
local MathCos = math.cos
local MathSin = math.sin
local StringLower = string.lower
local StringFind = string.find
local TableInsert = table.insert
local TableFind = table.find
local Pairs = pairs
local IPairs = ipairs

--// Configuração Global (Ajustada para a UI)
_G.AimbotConfig = _G.AimbotConfig or {
    Enabled = false,
    TeamCheck = "Team",         -- "Team" ou "All"
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
    FOVBehavior = "Center",     -- "Mouse" ou "Center"
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

--// Variáveis de Controle
_G.SilentAimConnections = {}
_G.SilentAimActive = false
_G.FOVLines = {} -- Armazena as linhas da Drawing API
local ClosestHitPart = nil
local CurrentTargetCharacter = nil

-- Mapeamento de Partes do Corpo
local PartMapping = {
    ["Head"] = {"Head"},
    ["Torso"] = {"HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    ["Left Arm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["Right Arm"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["Left Leg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    ["Right Leg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

-- Palavras-chave para identificar disparos
local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", 
    "missile", "rocket", "hit", "damage", "attack", 
    "cast", "ray", "target", "server", "remote", "action", 
    "mouse", "input", "create"
}

--// Funções Auxiliares

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
    -- Checa Usuários
    if TableFind(_G.AimbotConfig.WhitelistedUsers, player.Name) then return true end
    -- Checa Times
    if player.Team and TableFind(_G.AimbotConfig.WhitelistedTeams, player.Team.Name) then return true end
    return false
end

-- Sistema de WallCheck (Raycast Otimizado)
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
    if _G.SilentAimGui then FilterCache[4] = _G.SilentAimGui end -- Ignora a GUI do Aim
    
    RayParams.FilterDescendantsInstances = FilterCache
    local rayResult = Raycast(Workspace, origin, direction, RayParams)
    
    -- Se não bateu em nada ou bateu no personagem alvo, está visível
    return rayResult == nil or IsDescendantOf(rayResult.Instance, character)
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
            TableInsert(partsToCheck, t)
        end
    end

    ShuffleTable(partsToCheck)

    for _, groupName in IPairs(partsToCheck) do
        local specificParts = PartMapping[groupName]
        if specificParts then
            for _, partName in IPairs(specificParts) do
                local part = FindFirstChild(character, partName)
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
        OriginPos = GetMouseLocation(UserInputService)
    else
        local Viewport = Camera.ViewportSize
        OriginPos = Vector2New(Viewport.X / 2, Viewport.Y / 2)
    end

    local MyPos = Camera.CFrame.Position
    local FOVSize = _G.AimbotConfig.FOVSize
    local MyTeam = LocalPlayer.Team
    local TeamCheckType = _G.AimbotConfig.TeamCheck -- "Team" ou "All"
    local FocusMode = _G.AimbotConfig.FocusMode
    local FocusList = _G.AimbotConfig.FocusList
    local Priority = _G.AimbotConfig.TargetPriority or "Distance"

    for _, Player in IPairs(GetPlayers(Players)) do
        if Player == LocalPlayer then continue end
        
        -- Verificação de Time
        if TeamCheckType == "Team" and Player.Team == MyTeam and MyTeam ~= nil then continue end

        -- Modo Foco e Whitelist
        if FocusMode then
            if not TableFind(FocusList, Player.Name) then continue end
        else
            if isWhitelisted(Player) then continue end
        end

        local Character = Player.Character
        if not Character then continue end
        
        local RootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        
        if not RootPart or not Humanoid or Humanoid.Health <= 0 then continue end

        local dist3D = (RootPart.Position - MyPos).Magnitude
        if dist3D > _G.AimbotConfig.MaxDistance then continue end

        -- Verificação de FOV
        local CheckPart = FindFirstChild(Character, "Head") or RootPart
        local screenPos, onScreen = WorldToScreenPoint(Camera, CheckPart.Position)

        if onScreen then
            local dist2D = (OriginPos - Vector2New(screenPos.X, screenPos.Y)).Magnitude
            
            if dist2D <= FOVSize then
                local currentScore
                if Priority == "Health" then
                    currentScore = Humanoid.Health
                else
                    currentScore = dist3D -- Distância 3D é geralmente melhor para prioridade "Distância"
                end

                if currentScore < BestScore then
                    -- Só faz o Raycast (caro) se o alvo for um candidato melhor
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

--// Limpeza
_G.StopSilentAim = function()
    _G.SilentAimActive = false
    
    if _G.SilentAimConnections then
        for _, conn in pairs(_G.SilentAimConnections) do
            if conn then conn:Disconnect() end
        end
    end
    _G.SilentAimConnections = {}

    -- Limpa GUI (Highlight/ESP)
    if _G.SilentAimGui then _G.SilentAimGui:Destroy() _G.SilentAimGui = nil end
    
    -- Limpa Drawing API (FOV)
    if _G.FOVLines then
        for _, line in pairs(_G.FOVLines) do
            pcall(function() line:Remove() end)
        end
    end
    _G.FOVLines = {}
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

--// Inicialização
_G.StartSilentAim = function()
    _G.StopSilentAim() -- Limpa anterior
    _G.SilentAimActive = true
    local config = _G.AimbotConfig
    
    if not config.Enabled then
         _G.AimbotConfig.Enabled = true
    end

    -- Criação da GUI segura (Apenas para Highlight e ESP)
    local SafeParent = gethui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SA_UI_" .. tostring(MathRandom(1000,9999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.Parent = SafeParent
    _G.SilentAimGui = ScreenGui
    
    -- Highlight e ESP Container
    local TargetHighlight = Instance.new("Highlight")
    TargetHighlight.Name = "TargetFX"
    TargetHighlight.FillTransparency = 0.85
    TargetHighlight.OutlineTransparency = 0.1
    TargetHighlight.OutlineColor = config.HighlightColor
    TargetHighlight.FillColor = config.HighlightColor
    TargetHighlight.Parent = ScreenGui

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
    
    -- Componentes do ESP
    local function createLabel(order, color, fontSize)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,0,0,14)
        l.BackgroundTransparency = 1
        l.TextColor3 = color
        l.Font = Enum.Font.GothamBold
        l.TextSize = fontSize or 12
        l.TextStrokeTransparency = 0.5
        l.LayoutOrder = order
        l.Visible = false
        l.Parent = MainContainer
        return l
    end

    local NameLabel = createLabel(1, Color3.new(1,1,1), 14)
    local TeamLabel = createLabel(2, Color3.new(0.8,0.8,0.8))
    local WeaponLabel = createLabel(3, Color3.new(0.9,0.9,0.9))
    local HPText = createLabel(4, Color3.new(0,1,0), 12)
    HPText.Font = Enum.Font.Code

    -- Loop Principal
    local rot = 0
    local c1 = RunService.RenderStepped:Connect(function(dt)
        -- Atualiza Lógica do Alvo
        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        
            -- Atualiza Visuais (ESP/Highlight)
            if Character then
                -- Highlight
                if config.ShowHighlight then
                    TargetHighlight.Adornee = Character
                    TargetHighlight.Enabled = true
                    TargetHighlight.OutlineColor = config.HighlightColor
                    TargetHighlight.FillColor = config.HighlightColor
                else
                    TargetHighlight.Enabled = false
                end

                -- ESP
                if config.ESP.Enabled then
                    local root = FindFirstChild(Character, "HumanoidRootPart")
                    local hum = FindFirstChild(Character, "Humanoid")
                    
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
                            local tool = FindFirstChildWhichIsA(Character, "Tool")
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
                            local health = MathFloor(hum.Health)
                            local maxHealth = MathFloor(hum.MaxHealth)
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

        -- Atualiza FOV (Drawing API Polígono)
        if _G.SilentAimActive and config.ShowFOV then
            
            -- Posição Central
            local pos
            if config.FOVBehavior == "Mouse" then
                pos = GetMouseLocation(UserInputService)
            else
                local vp = Camera.ViewportSize
                pos = Vector2New(vp.X / 2, vp.Y / 2)
            end
            
            local sides = config.FOVNumSides or 20
            if sides < 3 then sides = 3 end
            local radius = config.FOVSize
            
            -- Controle de rotação do gradiente
            rot = rot + (config.GradientSpeed or 1)
            if rot > 360 then rot = 0 end
            local gradPhase = rot / 360 
            
            local anglePerSide = 360 / sides
            
            -- Desenha as linhas do polígono usando Drawing API
            for i = 1, sides do
                local line = _G.FOVLines[i]
                if not line then
                    line = Drawing.new("Line")
                    line.Thickness = 1.5
                    line.Transparency = 1
                    _G.FOVLines[i] = line
                end
                line.Visible = true
                
                -- Calcula vértices
                local r1 = MathRad((i - 1) * anglePerSide)
                local r2 = MathRad(i * anglePerSide)
                
                local p1 = Vector2New(pos.X + MathCos(r1) * radius, pos.Y + MathSin(r1) * radius)
                local p2 = Vector2New(pos.X + MathCos(r2) * radius, pos.Y + MathSin(r2) * radius)
                
                line.From = p1
                line.To = p2
                
                -- Cor (Simulação de gradiente linear rotativo)
                local t = ((i / sides) + gradPhase) % 1
                line.Color = config.FOVColor1:Lerp(config.FOVColor2, t)
            end
            
            -- Esconde linhas não usadas da Drawing API
            for i = sides + 1, #_G.FOVLines do
                _G.FOVLines[i].Visible = false
            end
        else
            -- Esconde tudo se FOV estiver desligado
            for _, l in pairs(_G.FOVLines) do l.Visible = false end
        end
    end)
    TableInsert(_G.SilentAimConnections, c1)
end

--// HOOKMETAMETHOD (INTACTO - Como solicitado)
-- Apenas garantindo que as referências usadas existam
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
                            -- Modifica se for argumento de direção ou posição final
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
                -- Recalcula direção para bater no alvo
                Arguments[2] = (finalPosition - origin).Unit * 10000 
                return oldNamecall(self, unpack(Arguments))
            end
        end
    end
    return oldNamecall(self, ...)
end))

-- Inicializa se a config já estiver ativa
if _G.AimbotConfig and _G.AimbotConfig.Enabled then
    _G.StartSilentAim()
end
