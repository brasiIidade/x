--[[
    Silent Aim Logic + Visuals Refined
    - HUD/ESP aparece APENAS no alvo focado.
    - FOV corrigido (toggle on/off).
    - Visuais melhorados.
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

-- Configuração Global
_G.AimbotConfig = _G.AimbotConfig or {}
_G.AimbotConfig.Enabled = _G.AimbotConfig.Enabled or false
_G.AimbotConfig.TeamCheck = _G.AimbotConfig.TeamCheck or "Team"
_G.AimbotConfig.TargetPart = _G.AimbotConfig.TargetPart or {"Random"}
_G.AimbotConfig.HitChance = _G.AimbotConfig.HitChance or 100
_G.AimbotConfig.MaxDistance = _G.AimbotConfig.MaxDistance or 1000
_G.AimbotConfig.FOVSize = _G.AimbotConfig.FOVSize or 200
_G.AimbotConfig.ShowFOV = _G.AimbotConfig.ShowFOV ~= false -- Padrão true se nil
_G.AimbotConfig.FOVColor1 = _G.AimbotConfig.FOVColor1 or Color3.fromRGB(255, 255, 255)
_G.AimbotConfig.FOVNumSides = 60
_G.AimbotConfig.FOVThickness = 2
_G.AimbotConfig.FOVTransparency = 1
_G.AimbotConfig.FOVFilled = false

-- Configurações de ESP (Visuais)
_G.AimbotConfig.ESP = _G.AimbotConfig.ESP or {}
_G.AimbotConfig.ESP.Enabled = _G.AimbotConfig.ESP.Enabled ~= false
_G.AimbotConfig.ESP.ShowBox = true
_G.AimbotConfig.ESP.BoxFilled = true -- Novo: Caixa preenchida
_G.AimbotConfig.ESP.BoxTransparency = 0.5
_G.AimbotConfig.ESP.ShowName = true
_G.AimbotConfig.ESP.ShowHealth = true
_G.AimbotConfig.ESP.ShowDistance = true
_G.AimbotConfig.ESP.ShowTracers = true
_G.AimbotConfig.ESP.FontSize = 13
_G.AimbotConfig.ESP.TextColor = Color3.fromRGB(255, 255, 255)
_G.AimbotConfig.ESP.OutlineColor = Color3.fromRGB(0, 0, 0)
_G.AimbotConfig.ESP.MainColor = Color3.fromRGB(255, 255, 255)

_G.SilentAimActive = true

-- Variáveis de Estado
local ClosestHitPart = nil
local CurrentTargetCharacter = nil -- Alvo atual focado
local Tracking = {} 
local Visuals = {} 

-- -------------------------------------------------------------------------
-- Handlers de Visuais
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
    elseif string.lower(Object) == "espboxfilled" then
        local ESPBoxFilled = Drawing.new("Square")
        ESPBoxFilled.Visible = false
        ESPBoxFilled.ZIndex = 0
        ESPBoxFilled.Thickness = 1
        ESPBoxFilled.Transparency = config.ESP.BoxTransparency or 0.2
        ESPBoxFilled.Filled = true
        ESPBoxFilled.Color = config.ESP.MainColor
        return ESPBoxFilled
    elseif string.lower(Object) == "text" then
        local Text = Drawing.new("Text")
        Text.Visible = false
        Text.ZIndex = 2
        Text.Center = true
        Text.Outline = true
        Text.OutlineColor = config.ESP.OutlineColor
        Text.Font = 2 -- Plex/Monospace
        Text.Size = config.ESP.FontSize
        Text.Transparency = 1
        Text.Color = config.ESP.TextColor
        return Text
    elseif string.lower(Object) == "tracer" then
        local Tracer = Drawing.new("Line")
        Tracer.Visible = false
        Tracer.ZIndex = 0
        Tracer.Thickness = 1
        Tracer.Transparency = 1
        Tracer.Color = config.ESP.MainColor
        return Tracer
    end
    return nil
end

function VisualsHandler:ClearVisual(Visual)
    if Visual then
        if Visual.Remove then Visual:Remove() end
        if Visual.Destroy then Visual:Destroy() end
    end
end

-- Inicialização do FOV
Visuals.FoV = VisualsHandler:Visualize("FoV")

function VisualsHandler:UpdateFoV()
    -- Recria se foi deletado
    if not Visuals.FoV then 
        Visuals.FoV = self:Visualize("FoV")
    end
    
    if not Visuals.FoV then return end -- Se falhar ao criar

    local config = _G.AimbotConfig
    
    -- Verifica se o Silent Aim está ativo E a config de FOV está ligada
    if _G.SilentAimActive and config.ShowFOV then
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
-- Biblioteca ESP (Focada no Alvo)
-- -------------------------------------------------------------------------

local ESPLibrary = {}
ESPLibrary.__index = ESPLibrary

function ESPLibrary.new(character)
    local self = setmetatable({}, ESPLibrary)
    self.Character = character
    self.Player = Players:GetPlayerFromCharacter(character)
    
    -- Objetos Visuais
    self.ESPBox = VisualsHandler:Visualize("espbox")
    self.ESPBoxFilled = VisualsHandler:Visualize("espboxfilled")
    self.NameESP = VisualsHandler:Visualize("text")
    self.InfoESP = VisualsHandler:Visualize("text") -- Combina Vida/Distância para ficar mais limpo
    self.TracerESP = VisualsHandler:Visualize("tracer")
    
    return self
end

function ESPLibrary:Update()
    -- Se o personagem sumiu, remove tudo
    if not self.Character or not self.Character.Parent then 
        self:Remove()
        return 
    end

    local config = _G.AimbotConfig.ESP

    -- Regra Principal: Só mostra se for o alvo atual (Focado)
    local isTarget = (self.Character == CurrentTargetCharacter)
    
    -- Se não estiver ativo, ou não for o alvo, ou ESP desligado globalmente -> Esconde tudo
    if not _G.SilentAimActive or not config.Enabled or not isTarget then
        self:SetVisible(false)
        return
    end

    -- Partes do corpo
    local Head = self.Character:FindFirstChild("Head")
    local Root = self.Character:FindFirstChild("HumanoidRootPart")
    local Hum = self.Character:FindFirstChild("Humanoid")

    if Head and Root and Hum and Hum.Health > 0 then
        local RootPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
        
        if OnScreen then
            local HeadPos = Camera:WorldToViewportPoint(Head.Position + Vector3New(0, 0.5, 0))
            local LegPos = Camera:WorldToViewportPoint(Root.Position - Vector3New(0, 3, 0))
            
            -- Box Calculation
            local BoxHeight = HeadPos.Y - LegPos.Y
            local BoxSize = Vector2New(2000 / RootPos.Z, math.abs(BoxHeight)) -- Ajustei largura para ficar mais "slim"
            local BoxPos = Vector2New(RootPos.X - BoxSize.X / 2, HeadPos.Y)

            local MainColor = config.MainColor

            -- Atualiza Box
            if config.ShowBox then
                self.ESPBox.Size = BoxSize
                self.ESPBox.Position = BoxPos
                self.ESPBox.Color = MainColor
                self.ESPBox.Visible = true
                
                if config.BoxFilled then
                    self.ESPBoxFilled.Size = BoxSize
                    self.ESPBoxFilled.Position = BoxPos
                    self.ESPBoxFilled.Color = MainColor
                    self.ESPBoxFilled.Transparency = 0.15 -- Bem sutil
                    self.ESPBoxFilled.Visible = true
                else
                    self.ESPBoxFilled.Visible = false
                end
            else
                self.ESPBox.Visible = false
                self.ESPBoxFilled.Visible = false
            end

            -- Atualiza Nome (Topo)
            if config.ShowName then
                self.NameESP.Text = self.Player.Name
                self.NameESP.Position = Vector2New(RootPos.X, BoxPos.Y - 18)
                self.NameESP.Color = config.TextColor
                self.NameESP.Visible = true
            else
                self.NameESP.Visible = false
            end

            -- Atualiza Info (Baixo: Vida | Distância)
            if config.ShowHealth or config.ShowDistance then
                local infoText = ""
                
                if config.ShowHealth then
                    local hpPercent = math.floor(Hum.Health)
                    infoText = infoText .. string.format("%dHP", hpPercent)
                end
                
                if config.ShowDistance then
                    local dist = math.floor((Root.Position - Camera.CFrame.Position).Magnitude)
                    if infoText ~= "" then infoText = infoText .. " | " end
                    infoText = infoText .. string.format("%dm", dist)
                end

                self.InfoESP.Text = infoText
                self.InfoESP.Position = Vector2New(RootPos.X, LegPos.Y + 2)
                -- Cor dinâmica baseada na vida (Verde -> Vermelho)
                self.InfoESP.Color = Color3New(0, 1, 0):Lerp(Color3New(1, 0, 0), 1 - (Hum.Health / Hum.MaxHealth))
                self.InfoESP.Visible = true
            else
                self.InfoESP.Visible = false
            end

            -- Atualiza Tracer
            if config.ShowTracers then
                self.TracerESP.From = Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) 
                self.TracerESP.To = Vector2New(RootPos.X, LegPos.Y)
                self.TracerESP.Color = MainColor
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
    if self.ESPBoxFilled then self.ESPBoxFilled.Visible = val end
    if self.NameESP then self.NameESP.Visible = val end
    if self.InfoESP then self.InfoESP.Visible = val end
    if self.TracerESP then self.TracerESP.Visible = val end
end

function ESPLibrary:Remove()
    VisualsHandler:ClearVisual(self.ESPBox)
    VisualsHandler:ClearVisual(self.ESPBoxFilled)
    VisualsHandler:ClearVisual(self.NameESP)
    VisualsHandler:ClearVisual(self.InfoESP)
    VisualsHandler:ClearVisual(self.TracerESP)
end

-- -------------------------------------------------------------------------
-- Lógica Silent Aim
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
                -- Verifica se está dentro do FOV
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

-- Loop Principal
local RenderConn = RunService.RenderStepped:Connect(function()
    if _G.SilentAimActive then
        -- 1. Calcula o alvo primeiro
        local Part, Char = getClosestPlayer()
        ClosestHitPart = Part
        CurrentTargetCharacter = Char -- Atualiza quem está sendo focado para o ESP usar
        
        -- 2. Atualiza FOV
        VisualsHandler:UpdateFoV()

        -- 3. Atualiza ESP (Agora sabe quem é o CurrentTargetCharacter)
        for _, espObj in Pairs(Tracking) do
            espObj:Update()
        end
    else
        -- Se desligado, esconde FOV
        if Visuals.FoV then Visuals.FoV.Visible = false end
        -- Esconde todos ESPs
        for _, espObj in Pairs(Tracking) do
            espObj:SetVisible(false)
        end
        CurrentTargetCharacter = nil
        ClosestHitPart = nil
    end
end)
table.insert(_G.SilentAimConnections, RenderConn)

-- -------------------------------------------------------------------------
-- Hook de Tiro
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

-- Funções de Controle
_G.StopSilentAim = function()
    _G.SilentAimActive = false
    -- Não removemos o FOV aqui para evitar bugs de recriação, apenas deixamos o loop escondê-lo
    CurrentTargetCharacter = nil
end

_G.StartSilentAim = function()
    _G.SilentAimActive = true
end
