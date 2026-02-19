--[[
    Silent Aim Logic + Visuals Ported from Universal Aim Assist Framework
    - Visuals: FOV, ESP Box, Name, Health, Magnitude, Tracer (Drawing API)
    - Logic: Silent Aim (Hook Intact)
]]

-- Otimização e Segurança
local clonefunction = clonefunction or function(f) return f end
local getnamecallmethod = clonefunction(getnamecallmethod)
local checkcaller = clonefunction(checkcaller)
local newcclosure = clonefunction(newcclosure)
local hookmetamethod = hookmetamethod

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Referências Locais
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local CFrameNew = CFrame.new
local MathRandom = math.random
local MathHuge = math.huge
local Color3New = Color3.new
local IPairs = ipairs
local Pairs = pairs

-- Limpeza
if _G.SilentAimConnections then
    for _, conn in Pairs(_G.SilentAimConnections) do conn:Disconnect() end
end
_G.SilentAimConnections = {}

-- Configuração Global (Atualizada com campos para os novos visuais)
_G.AimbotConfig = _G.AimbotConfig or {}
-- Garante valores padrão se não existirem
_G.AimbotConfig.Enabled = _G.AimbotConfig.Enabled or false
_G.AimbotConfig.TeamCheck = _G.AimbotConfig.TeamCheck or "Team"
_G.AimbotConfig.TargetPart = _G.AimbotConfig.TargetPart or {"Random"}
_G.AimbotConfig.HitChance = _G.AimbotConfig.HitChance or 100
_G.AimbotConfig.MaxDistance = _G.AimbotConfig.MaxDistance or 1000
_G.AimbotConfig.FOVSize = _G.AimbotConfig.FOVSize or 200
_G.AimbotConfig.ShowFOV = _G.AimbotConfig.ShowFOV ~= false
_G.AimbotConfig.FOVColor1 = _G.AimbotConfig.FOVColor1 or Color3.fromRGB(255, 255, 255)
_G.AimbotConfig.FOVNumSides = 60
_G.AimbotConfig.FOVThickness = 2
_G.AimbotConfig.FOVTransparency = 1
_G.AimbotConfig.FOVFilled = false

-- Configurações de ESP
_G.AimbotConfig.ESP = _G.AimbotConfig.ESP or {}
_G.AimbotConfig.ESP.Enabled = _G.AimbotConfig.ESP.Enabled ~= false
_G.AimbotConfig.ESP.ShowBox = true      -- Novo
_G.AimbotConfig.ESP.ShowName = true
_G.AimbotConfig.ESP.ShowHealth = true
_G.AimbotConfig.ESP.ShowDistance = true -- Magnitude
_G.AimbotConfig.ESP.ShowTracers = true  -- Novo
_G.AimbotConfig.ESP.FontSize = 14
_G.AimbotConfig.ESP.TextColor = _G.AimbotConfig.ESP.TextColor or Color3.fromRGB(255, 255, 255)
_G.AimbotConfig.ESP.OutlineColor = _G.AimbotConfig.ESP.OutlineColor or Color3.fromRGB(0, 0, 0)
_G.AimbotConfig.ESP.MainColor = Color3.fromRGB(255, 255, 255)

_G.SilentAimActive = true

-- Variáveis de Estado
local ClosestHitPart = nil
local Tracking = {} -- Armazena objetos ESP
local Visuals = {}  -- Armazena objetos visuais globais (FOV)

-- -------------------------------------------------------------------------
-- Handlers de Visuais (Portado do Script Fornecido)
-- -------------------------------------------------------------------------

local VisualsHandler = {}

function VisualsHandler:Visualize(Object)
    if not Drawing or not Drawing.new then return nil end
    local config = _G.AimbotConfig

    if string.lower(Object) == "fov" then
        local FoV = Drawing.new("Circle")
        FoV.Visible = false
        FoV.ZIndex = 2
        FoV.NumSides = config.FOVNumSides
        FoV.Radius = config.FOVSize
        FoV.Thickness = config.FOVThickness
        FoV.Transparency = config.FOVTransparency
        FoV.Filled = config.FOVFilled
        FoV.Color = config.FOVColor1
        return FoV
    elseif string.lower(Object) == "espbox" then
        local ESPBox = Drawing.new("Square")
        ESPBox.Visible = false
        ESPBox.ZIndex = 1
        ESPBox.Thickness = 1.5
        ESPBox.Transparency = 1
        ESPBox.Filled = false
        ESPBox.Color = config.ESP.MainColor
        return ESPBox
    elseif string.lower(Object) == "nameesp" then
        local NameESP = Drawing.new("Text")
        NameESP.Visible = false
        NameESP.ZIndex = 2
        NameESP.Center = true
        NameESP.Outline = true
        NameESP.OutlineColor = config.ESP.OutlineColor
        NameESP.Font = 2 -- Monospace (Plex no script original era 2 ou 3)
        NameESP.Size = config.ESP.FontSize
        NameESP.Transparency = 1
        NameESP.Color = config.ESP.TextColor
        return NameESP
    elseif string.lower(Object) == "traceresp" then
        local TracerESP = Drawing.new("Line")
        TracerESP.Visible = false
        TracerESP.ZIndex = 0
        TracerESP.Thickness = 1
        TracerESP.Transparency = 1
        TracerESP.Color = config.ESP.MainColor
        return TracerESP
    end
    return nil
end

function VisualsHandler:ClearVisual(Visual)
    if Visual then
        if Visual.Remove then Visual:Remove() end
        if Visual.Destroy then Visual:Destroy() end
    end
end

-- Inicializa o FOV
Visuals.FoV = VisualsHandler:Visualize("FoV")

function VisualsHandler:UpdateFoV()
    if not Visuals.FoV then return end
    local config = _G.AimbotConfig
    
    if config.ShowFOV then
        local MouseLocation = UserInputService:GetMouseLocation()
        if config.FOVBehavior == "Center" then
            Visuals.FoV.Position = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        else
            Visuals.FoV.Position = MouseLocation
        end
        
        Visuals.FoV.Radius = config.FOVSize
        Visuals.FoV.Thickness = config.FOVThickness
        Visuals.FoV.Color = config.FOVColor1
        Visuals.FoV.Visible = true
    else
        Visuals.FoV.Visible = false
    end
end

-- -------------------------------------------------------------------------
-- Biblioteca ESP (Portada e Adaptada)
-- -------------------------------------------------------------------------

local ESPLibrary = {}
ESPLibrary.__index = ESPLibrary

function ESPLibrary.new(character)
    local self = setmetatable({}, ESPLibrary)
    self.Character = character
    self.Player = Players:GetPlayerFromCharacter(character)
    
    self.ESPBox = VisualsHandler:Visualize("ESPBox")
    self.NameESP = VisualsHandler:Visualize("nameesp")
    self.HealthESP = VisualsHandler:Visualize("nameesp") -- Reutiliza tipo texto
    self.DistanceESP = VisualsHandler:Visualize("nameesp") -- Reutiliza tipo texto
    self.TracerESP = VisualsHandler:Visualize("traceresp")
    
    return self
end

function ESPLibrary:Update()
    local config = _G.AimbotConfig.ESP
    if not self.Character or not self.Character.Parent then 
        self:Remove()
        return 
    end

    -- Verificações básicas (Team check visual, Enabled check)
    if not config.Enabled then
        self:SetVisible(false)
        return
    end

    if _G.AimbotConfig.TeamCheck == "Team" and self.Player.Team == LocalPlayer.Team then
        self:SetVisible(false)
        return
    end

    local Head = self.Character:FindFirstChild("Head")
    local Root = self.Character:FindFirstChild("HumanoidRootPart")
    local Hum = self.Character:FindFirstChild("Humanoid")

    if Head and Root and Hum and Hum.Health > 0 then
        local RootPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
        
        if OnScreen then
            local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3New(0, 0.5, 0))
            local LegPos = Camera:WorldToViewportPoint(Root.Position - Vector3New(0, 3, 0))
            
            -- Cálculo do Box (Copiado do Script original)
            local BoxHeight = HeadPos.Y - LegPos.Y
            local BoxSize = Vector2New(2350 / RootPos.Z, math.abs(BoxHeight))
            local BoxPos = Vector2New(RootPos.X - BoxSize.X / 2, HeadPos.Y)

            -- Atualiza Box
            if config.ShowBox then
                self.ESPBox.Size = BoxSize
                self.ESPBox.Position = BoxPos
                self.ESPBox.Color = config.MainColor
                self.ESPBox.Visible = true
            else
                self.ESPBox.Visible = false
            end

            -- Atualiza Nome
            if config.ShowName then
                self.NameESP.Text = self.Player.Name
                self.NameESP.Position = Vector2New(RootPos.X, BoxPos.Y - 20)
                self.NameESP.Color = config.TextColor
                self.NameESP.Visible = true
            else
                self.NameESP.Visible = false
            end

            -- Atualiza Vida
            if config.ShowHealth then
                self.HealthESP.Text = string.format("[%d%%]", math.floor(Hum.Health))
                self.HealthESP.Position = Vector2New(RootPos.X, LegPos.Y + 5)
                self.HealthESP.Color = Color3New(0, 1, 0):Lerp(Color3New(1, 0, 0), 1 - (Hum.Health / Hum.MaxHealth))
                self.HealthESP.Visible = true
            else
                self.HealthESP.Visible = false
            end

            -- Atualiza Distância (Magnitude)
            if config.ShowDistance then
                local dist = (Root.Position - Camera.CFrame.Position).Magnitude
                self.DistanceESP.Text = string.format("[%dm]", math.floor(dist))
                -- Coloca um pouco abaixo da vida ou no topo se vida desligada
                local offset = config.ShowHealth and 20 or 5
                self.DistanceESP.Position = Vector2New(RootPos.X, LegPos.Y + offset)
                self.DistanceESP.Color = config.TextColor
                self.DistanceESP.Visible = true
            else
                self.DistanceESP.Visible = false
            end

            -- Atualiza Tracer
            if config.ShowTracers then
                self.TracerESP.From = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Bottom center
                self.TracerESP.To = Vector2New(RootPos.X, LegPos.Y)
                self.TracerESP.Color = config.MainColor
                self.TracerESP.Visible = true
            else
                self.TracerESP.Visible = false
            end

        else
            self:SetVisible(false)
        end
    else
        self:SetVisible(false)
    end
end

function ESPLibrary:SetVisible(val)
    if self.ESPBox then self.ESPBox.Visible = val end
    if self.NameESP then self.NameESP.Visible = val end
    if self.HealthESP then self.HealthESP.Visible = val end
    if self.DistanceESP then self.DistanceESP.Visible = val end
    if self.TracerESP then self.TracerESP.Visible = val end
end

function ESPLibrary:Remove()
    VisualsHandler:ClearVisual(self.ESPBox)
    VisualsHandler:ClearVisual(self.NameESP)
    VisualsHandler:ClearVisual(self.HealthESP)
    VisualsHandler:ClearVisual(self.DistanceESP)
    VisualsHandler:ClearVisual(self.TracerESP)
end

-- -------------------------------------------------------------------------
-- Lógica Silent Aim e Loops
-- -------------------------------------------------------------------------

local function getClosestPlayer()
    local BestPart, BestChar = nil, nil
    local BestScore = MathHuge
    local OriginPos = _G.AimbotConfig.FOVBehavior == "Mouse" and UserInputService:GetMouseLocation() or Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, Player in IPairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        if _G.AimbotConfig.TeamCheck == "Team" and Player.Team == LocalPlayer.Team then continue end

        local Char = Player.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")

        if Root and Hum and Hum.Health > 0 then
            local ScreenPos, OnScreen = Camera:WorldToScreenPoint(Root.Position)
            if OnScreen then
                local Dist2D = (OriginPos - Vector2New(ScreenPos.X, ScreenPos.Y)).Magnitude
                if Dist2D <= _G.AimbotConfig.FOVSize and Dist2D < BestScore then
                    BestScore = Dist2D
                    BestChar = Char
                    BestPart = Char:FindFirstChild("Head") or Root
                end
            end
        end
    end
    return BestPart, BestChar
end

-- Gerenciamento de Jogadores
local function AddPlayer(player)
    if player == LocalPlayer then return end
    
    local function CharAdded(char)
        if Tracking[player] then Tracking[player]:Remove() end
        Tracking[player] = ESPLibrary.new(char)
    end

    player.CharacterAdded:Connect(CharAdded)
    if player.Character then CharAdded(player.Character) end
end

local function RemovePlayer(player)
    if Tracking[player] then
        Tracking[player]:Remove()
        Tracking[player] = nil
    end
end

for _, p in IPairs(Players:GetPlayers()) do AddPlayer(p) end
table.insert(_G.SilentAimConnections, Players.PlayerAdded:Connect(AddPlayer))
table.insert(_G.SilentAimConnections, Players.PlayerRemoving:Connect(RemovePlayer))

-- Loop Principal (RenderStepped)
local RenderConn = RunService.RenderStepped:Connect(function()
    -- Atualiza FOV
    VisualsHandler:UpdateFoV()

    -- Atualiza ESP
    for _, espObj in Pairs(Tracking) do
        espObj:Update()
    end

    -- Atualiza Alvo do Silent Aim
    if _G.SilentAimActive then
        local Part, Char = getClosestPlayer()
        ClosestHitPart = Part
    end
end)
table.insert(_G.SilentAimConnections, RenderConn)

-- -------------------------------------------------------------------------
-- Hook de Tiro (Mantido Intacto)
-- -------------------------------------------------------------------------

local function getLegitOffset()
    if not _G.AimbotConfig.UseLegitOffset then return Vector3New(0,0,0) end
    return Vector3New((MathRandom()-0.5)*0.5, (MathRandom()-0.5)*0.5, (MathRandom()-0.5)*0.5)
end

local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", "missile", "rocket", "hit", "damage", "attack", "cast", "ray"
}
local function isBulletRemote(name)
    name = string.lower(name)
    for _, k in IPairs(bulletFunctions) do if string.find(name, k) then return true end end
    return false
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not checkcaller() and _G.SilentAimActive and ClosestHitPart then
        local Method = getnamecallmethod()
        if MathRandom(1, 100) <= _G.AimbotConfig.HitChance then
            if (Method == "FireServer" or Method == "InvokeServer") then
                if isBulletRemote(self.Name) then
                    local Args = {...}
                    local finalPos = ClosestHitPart.Position + getLegitOffset()
                    local camPos = Camera.CFrame.Position
                    local Direction = (finalPos - camPos).Unit
                    for i = 1, #Args do
                        local v = Args[i]
                        if typeof(v) == "Vector3" then Args[i] = (v.Magnitude <= 10) and Direction or finalPos
                        elseif typeof(v) == "CFrame" then Args[i] = CFrameNew(camPos, finalPos) end
                    end
                    return oldNamecall(self, unpack(Args))
                end
            elseif Method == "Raycast" and self == Workspace then
                local Args = {...}
                local finalPos = ClosestHitPart.Position + getLegitOffset()
                Args[2] = (finalPos - Args[1]).Unit * 10000 
                return oldNamecall(self, unpack(Args))
            end
        end
    end
    return oldNamecall(self, ...)
end))

-- Funções de Controle Global
_G.StopSilentAim = function()
    _G.SilentAimActive = false
    if Visuals.FoV then Visuals.FoV:Remove() end
    for _, esp in Pairs(Tracking) do esp:Remove() end
    Tracking = {}
end

_G.StartSilentAim = function()
    _G.SilentAimActive = true
end
