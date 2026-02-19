--[[ 
    LÓGICA SILENT AIM - OTIMIZADA E ADAPTADA PARA A UI
    - Antideteção aplicada em serviços e funções matemáticas.
    - FOV nativo (ScreenGui) com gradiente.
    - Suporte completo a Whitelist, Focus Mode e Prioridades.
]]

-- // OTIMIZAÇÃO E SEGURANÇA (CLONEFUNCTION) //
local getgenv = getgenv or function() return _G end
local cloneref = cloneref or function(o) return o end -- Fallback caso não exista, mas evitamos usar no script principal
local clonefunction = clonefunction or function(f) return f end

local Game = game
local Players = clonefunction(Game.GetService)(Game, "Players")
local RunService = clonefunction(Game.GetService)(Game, "RunService")
local Workspace = clonefunction(Game.GetService)(Game, "Workspace")
local CoreGui = clonefunction(Game.GetService)(Game, "CoreGui")
local UserInputService = clonefunction(Game.GetService)(Game, "UserInputService")
local GuiService = clonefunction(Game.GetService)(Game, "GuiService")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Funções Otimizadas
local Vector2New = clonefunction(Vector2.new)
local Vector3New = clonefunction(Vector3.new)
local CFrameNew = clonefunction(CFrame.new)
local MathRandom = clonefunction(math.random)
local MathClamp = clonefunction(math.clamp)
local MathFloor = clonefunction(math.floor)
local MathHuge = clonefunction(math.huge)
local TableInsert = clonefunction(table.insert)
local TableFind = clonefunction(table.find)
local StringLower = clonefunction(string.lower)
local StringFind = clonefunction(string.find)
local Pairs = clonefunction(pairs)
local IPairs = clonefunction(ipairs)
local WorldToScreenPoint = clonefunction(Camera.WorldToScreenPoint)
local Raycast = clonefunction(Workspace.Raycast)

-- // LIMPEZA ANTERIOR //
if _G.SilentAimConnections then
    for _, conn in Pairs(_G.SilentAimConnections) do conn:Disconnect() end
end
if _G.SilentAimGUI then _G.SilentAimGUI:Destroy() _G.SilentAimGUI = nil end

_G.SilentAimConnections = {}
_G.SilentAimActive = false

-- Variáveis Globais de Controle
local ClosestHitPart = nil
local CurrentTargetCharacter = nil

-- Configuração Padrão (Compatível com sua UI)
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
    FOVBehavior = "Center", -- "Center" ou "Mouse"
    FOVNumSides = 20, -- (Ignorado no FOV nativo circular perfeito, mas mantido pra compatibilidade)
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

-- // SISTEMA DE FOV NATIVO (GUI) //
-- Substitui o Drawing.new para ser menos detectável e suportar gradientes reais
local function CreateVisuals()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SA_Visuals_" .. tostring(MathRandom(1000,9999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    
    -- Tenta colocar no CoreGui ou gethui, fallback para PlayerGui
    local parent = (gethui and gethui()) or CoreGui
    pcall(function() ScreenGui.Parent = parent end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    -- Container do FOV
    local FOVFrame = Instance.new("Frame")
    FOVFrame.Name = "FOVRing"
    FOVFrame.BackgroundTransparency = 1
    FOVFrame.AnchorPoint = Vector2New(0.5, 0.5)
    FOVFrame.Visible = false
    FOVFrame.Parent = ScreenGui

    local FOVStroke = Instance.new("UIStroke")
    FOVStroke.Name = "Stroke"
    FOVStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    FOVStroke.Thickness = 1.5
    FOVStroke.Transparency = 0.2
    FOVStroke.Parent = FOVFrame

    local FOVCorner = Instance.new("UICorner")
    FOVCorner.CornerRadius = UDim.new(1, 0) -- Torna um círculo perfeito
    FOVCorner.Parent = FOVFrame

    local FOVGradient = Instance.new("UIGradient")
    FOVGradient.Rotation = 0
    FOVGradient.Parent = FOVStroke

    -- Container do Highlight (Chams)
    local Highlight = Instance.new("Highlight")
    Highlight.Name = "TargetChams"
    Highlight.FillTransparency = 0.7
    Highlight.OutlineTransparency = 0
    Highlight.Enabled = false
    Highlight.Parent = ScreenGui

    -- Container do ESP (HUD)
    local Billboard = Instance.new("BillboardGui")
    Billboard.Size = UDim2.new(0, 200, 0, 150)
    Billboard.StudsOffset = Vector3New(0, -4, 0) -- Abaixo do pé ou ajustável
    Billboard.AlwaysOnTop = true
    Billboard.Enabled = false
    Billboard.Parent = ScreenGui

    local InfoList = Instance.new("UIListLayout")
    InfoList.SortOrder = Enum.SortOrder.LayoutOrder
    InfoList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    InfoList.Padding = UDim.new(0, 2)
    InfoList.Parent = Billboard

    -- Função auxiliar para criar labels do ESP
    local function createLabel(order, color)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = color or Color3.new(1,1,1)
        lbl.TextStrokeTransparency = 0.3
        lbl.TextStrokeColor3 = Color3.new(0,0,0)
        lbl.LayoutOrder = order
        lbl.Visible = false
        lbl.Parent = Billboard
        return lbl
    end

    local NameLbl = createLabel(1, Color3.new(1,1,1))
    local TeamLbl = createLabel(2, Color3.new(0.8,0.8,0.8))
    local WeaponLbl = createLabel(3, Color3.new(0.9,0.9,0.9))
    local HealthLbl = createLabel(4, Color3.new(0,1,0))

    _G.SilentAimGUI = ScreenGui
    
    return {
        Gui = ScreenGui,
        FOV = {Frame = FOVFrame, Gradient = FOVGradient, Stroke = FOVStroke},
        Highlight = Highlight,
        ESP = {Billboard = Billboard, Name = NameLbl, Team = TeamLbl, Weapon = WeaponLbl, Health = HealthLbl}
    }
end

local Visuals = CreateVisuals()

-- // FUNÇÕES AUXILIARES //

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

local function getLegitOffset()
    if not _G.AimbotConfig.UseLegitOffset then return Vector3New(0,0,0) end
    -- Gera um offset leve para não parecer 100% robótico
    return Vector3New(
        (MathRandom() - 0.5) * 0.7,
        (MathRandom() - 0.5) * 0.7,
        (MathRandom() - 0.5) * 0.7
    )
end

local function isBulletRemote(name)
    name = StringLower(name)
    for _, keyword in IPairs(bulletFunctions) do
        if StringFind(name, keyword) then return true end
    end
    return false
end

-- Lógica de Whitelist e Focus
local function isValidTarget(player)
    if not player or player == LocalPlayer then return false end
    
    local config = _G.AimbotConfig
    
    -- Modo Foco: Se ativado, SÓ ataca quem está na lista
    if config.FocusMode then
        if not TableFind(config.FocusList, player.Name) then
            return false 
        end
        return true -- Se está na lista de foco, ignoramos team check/whitelist
    end

    -- Whitelist de Usuário
    if TableFind(config.WhitelistedUsers, player.Name) then return false end
    
    -- Whitelist de Time
    if player.Team and TableFind(config.WhitelistedTeams, player.Team.Name) then return false end

    -- Checagem de Time (Inimigos vs Todos)
    if config.TeamCheck == "Team" and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

-- Wall Check Otimizado
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true
local FilterCache = {} 

local function IsPartVisible(part, character)
    if not _G.AimbotConfig.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    
    -- Atualiza cache de filtro
    FilterCache[1] = LocalPlayer.Character
    FilterCache[2] = character
    FilterCache[3] = Camera
    if _G.SilentAimGUI then FilterCache[4] = _G.SilentAimGUI end
    
    RayParams.FilterDescendantsInstances = FilterCache
    local rayResult = Raycast(Workspace, origin, direction, RayParams)
    
    -- Se não bateu em nada ou bateu no personagem alvo, está visível
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

-- Seleciona a melhor parte do corpo baseada na config
local function GetBestPart(character)
    local config = _G.AimbotConfig
    local targetParts = config.TargetPart
    
    -- Garante que é uma tabela válida
    if typeof(targetParts) ~= "table" or #targetParts == 0 then 
        targetParts = {"Head", "Torso"} 
    end
    
    -- Se tiver "Random", expande para todas as partes principais
    if TableFind(targetParts, "Random") then
        targetParts = {"Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}
    end

    local validParts = {}
    -- Converte nomes de grupos (Head, Torso) em nomes reais de partes
    for _, group in IPairs(targetParts) do
        local mapping = PartMapping[group]
        if mapping then
            for _, partName in IPairs(mapping) do
                local p = character:FindFirstChild(partName)
                if p then TableInsert(validParts, p) end
            end
        end
    end

    -- Embaralha para dar efeito de "Random" real se houver múltiplas opções
    ShuffleTable(validParts)

    for _, part in IPairs(validParts) do
        if IsPartVisible(part, character) then
            return part
        end
    end

    return nil
end

local function getClosestPlayer()
    local BestPart = nil
    local BestChar = nil
    local BestScore = MathHuge
    local Config = _G.AimbotConfig

    -- Determina posição do centro do FOV
    local OriginPos
    if Config.FOVBehavior == "Mouse" then
        OriginPos = UserInputService:GetMouseLocation()
    else
        local Viewport = Camera.ViewportSize
        OriginPos = Vector2New(Viewport.X / 2, Viewport.Y / 2)
    end

    local MyPos = Camera.CFrame.Position
    
    for _, Player in IPairs(Players:GetPlayers()) do
        if not isValidTarget(Player) then continue end

        local Character = Player.Character
        if not Character then continue end
        
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        
        if not RootPart or not Humanoid or Humanoid.Health <= 0 then continue end

        -- Checagem de Distância Máxima
        local dist3D = (RootPart.Position - MyPos).Magnitude
        if dist3D > Config.MaxDistance then continue end

        -- Checa se está na tela e dentro do FOV
        local CheckPart = Character:FindFirstChild("Head") or RootPart
        local screenPos, onScreen = WorldToScreenPoint(Camera, CheckPart.Position)

        if onScreen then
            local dist2D = (OriginPos - Vector2New(screenPos.X, screenPos.Y)).Magnitude
            
            if dist2D <= Config.FOVSize then
                -- Lógica de Prioridade (Distance vs Health)
                local currentScore
                if Config.TargetPriority == "Health" then
                    currentScore = Humanoid.Health
                else -- Distance
                    currentScore = dist3D -- Usa distância 3D como prioridade
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

-- // LOOP PRINCIPAL (VISUAL E LÓGICA) //
local function Update()
    local Config = _G.AimbotConfig
    
    if not Config.Enabled then 
        Visuals.FOV.Frame.Visible = false
        Visuals.Highlight.Enabled = false
        Visuals.ESP.Billboard.Enabled = false
        ClosestHitPart = nil
        CurrentTargetCharacter = nil
        return 
    end

    -- 1. Atualizar FOV
    if Config.ShowFOV then
        local fovFrame = Visuals.FOV.Frame
        fovFrame.Visible = true
        fovFrame.Size = UDim2.new(0, Config.FOVSize * 2, 0, Config.FOVSize * 2) -- Diâmetro
        
        -- Posição do FOV
        if Config.FOVBehavior == "Mouse" then
            local mousePos = UserInputService:GetMouseLocation()
            fovFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
        else
            fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        end

        -- Cores e Gradiente
        Visuals.FOV.Gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Config.FOVColor1),
            ColorSequenceKeypoint.new(1, Config.FOVColor2)
        }
        -- Animação do gradiente
        Visuals.FOV.Gradient.Rotation = (tick() * Config.GradientSpeed * 10) % 360
    else
        Visuals.FOV.Frame.Visible = false
    end

    -- 2. Buscar Alvo
    local Part, Character = getClosestPlayer()
    ClosestHitPart = Part
    CurrentTargetCharacter = Character

    -- 3. Atualizar Visuais do Alvo (Highlight e HUD)
    if Character and Part then
        -- Highlight
        if Config.ShowHighlight then
            Visuals.Highlight.Adornee = Character
            Visuals.Highlight.Enabled = true
            Visuals.Highlight.OutlineColor = Config.HighlightColor
            Visuals.Highlight.FillColor = Config.HighlightColor
        else
            Visuals.Highlight.Enabled = false
        end

        -- ESP / HUD
        if Config.ESP.Enabled then
            local root = Character:FindFirstChild("HumanoidRootPart")
            local hum = Character:FindFirstChild("Humanoid")
            
            if root and hum then
                Visuals.ESP.Billboard.Adornee = root
                Visuals.ESP.Billboard.Enabled = true
                
                -- Nome
                if Config.ESP.ShowName then
                    Visuals.ESP.Name.Visible = true
                    Visuals.ESP.Name.Text = Character.Name
                    Visuals.ESP.Name.TextColor3 = Config.ESP.TextColor
                else
                    Visuals.ESP.Name.Visible = false
                end

                -- Time
                if Config.ESP.ShowTeam then
                    Visuals.ESP.Team.Visible = true
                    local plr = Players:GetPlayerFromCharacter(Character)
                    if plr then
                        Visuals.ESP.Team.Text = plr.Team and plr.Team.Name or "Sem Time"
                        Visuals.ESP.Team.TextColor3 = plr.TeamColor and plr.TeamColor.Color or Color3.new(1,1,1)
                    else
                        Visuals.ESP.Team.Text = "NPC"
                        Visuals.ESP.Team.TextColor3 = Color3.new(1,1,1)
                    end
                else
                    Visuals.ESP.Team.Visible = false
                end

                -- Arma
                if Config.ESP.ShowWeapon then
                    Visuals.ESP.Weapon.Visible = true
                    local tool = Character:FindFirstChildWhichIsA("Tool")
                    Visuals.ESP.Weapon.Text = tool and string.upper(tool.Name) or "DESARMADO"
                    Visuals.ESP.Weapon.TextColor3 = Config.ESP.TextColor
                else
                    Visuals.ESP.Weapon.Visible = false
                end

                -- Vida
                if Config.ESP.ShowHealth then
                    Visuals.ESP.Health.Visible = true
                    local hp = MathFloor(hum.Health)
                    local maxHp = MathFloor(hum.MaxHealth)
                    Visuals.ESP.Health.Text = string.format("[%d / %d]", hp, maxHp)
                    -- Cor dinâmica baseada na vida (Verde -> Vermelho)
                    local hue = MathClamp(hp / maxHp, 0, 1) * 0.33
                    Visuals.ESP.Health.TextColor3 = Color3.fromHSV(hue, 1, 1)
                else
                    Visuals.ESP.Health.Visible = false
                end
            end
        else
            Visuals.ESP.Billboard.Enabled = false
        end
    else
        Visuals.Highlight.Enabled = false
        Visuals.ESP.Billboard.Enabled = false
    end
end

-- // GESTÃO DE ESTADO //
_G.StartSilentAim = function()
    _G.SilentAimActive = true
    _G.AimbotConfig.Enabled = true
    
    -- Inicia o loop visual
    local conn = RunService.RenderStepped:Connect(Update)
    TableInsert(_G.SilentAimConnections, conn)
end

_G.StopSilentAim = function()
    _G.SilentAimActive = false
    _G.AimbotConfig.Enabled = false
    
    if _G.SilentAimConnections then
        for _, conn in Pairs(_G.SilentAimConnections) do conn:Disconnect() end
    end
    _G.SilentAimConnections = {}
    
    -- Esconde visuais imediatamente
    Visuals.FOV.Frame.Visible = false
    Visuals.Highlight.Enabled = false
    Visuals.ESP.Billboard.Enabled = false
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

-- Inicialização se já estiver ativado na config
if _G.AimbotConfig.Enabled then
    _G.StartSilentAim()
end

-- // HOOK (MANTIDO INTACTO CONFORME SOLICITADO) //
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
                            -- Modificação leve: só altera se parecer um hit point ou direção
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
