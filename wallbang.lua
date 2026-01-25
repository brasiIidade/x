if not _G.AimbotConfig then return end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Vector2New = Vector2.new
local Vector3New = Vector3.new
local CFrameNew = CFrame.new
local MathRandom = math.random
local IPairs = ipairs
local Pairs = pairs
local StringLower = string.lower
local StringFind = string.find
local MathHuge = math.huge

-- VariÃ¡veis de controle
_G.SilentAimConnections = {}
_G.SilentAimActive = false
local ClosestHitPart = nil
local CurrentTargetCharacter = nil

-- FunÃ§Ãµes Auxiliares (Magic Bullet Keywords adicionadas)
local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", 
    "missile", "rocket", "hit", "damage", "attack", 
    "cast", "ray", "target", "server", "remote", "action", 
    "mouse", "input", "create", "impact", "verify"
}

local function getLegitOffset()
    if not _G.AimbotConfig.UseLegitOffset then return Vector3New(0,0,0) end
    -- Pequena variaÃ§Ã£o para nÃ£o parecer 100% robÃ³tico
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

-- MAGIC BULLET EDIT: Modifiquei para ignorar WallCheck se MagicBullet estiver ativo
local function IsPartVisible(part, character)
    if _G.AimbotConfig.MagicBullet then return true end -- Sempre retorna visÃ­vel para ativar o magic bullet
    if not _G.AimbotConfig.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, character, Camera, _G.AimbotGui}
    local rayResult = Workspace:Raycast(origin, direction, RayParams)
    return rayResult == nil
end

local function GetBestPart(character)
    local targets = _G.AimbotConfig.TargetPart
    if typeof(targets) ~= "table" then targets = {targets} end
    
    if #targets == 0 or table.find(targets, "Random") then
        targets = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}
    end

    for _, name in IPairs(targets) do
        local part = character:FindFirstChild(name)
        if part and IsPartVisible(part, character) then return part end
    end
    return nil
end

local function getClosestPlayer()
    local BestPart = nil
    local BestChar = nil
    local ClosestDistance3D = MathHuge 
    local OriginPos = (_G.AimbotConfig.FOVBehavior == "Mouse") and UserInputService:GetMouseLocation() or Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
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
        
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        
        if not RootPart or not Humanoid or Humanoid.Health <= 0 then continue end
        
        local currentDistance3D = (RootPart.Position - myPos).Magnitude
        if currentDistance3D > _G.AimbotConfig.MaxDistance then continue end

        local ReferencePart = Character:FindFirstChild("Head") or RootPart
        local screenPos, onScreen = Camera:WorldToScreenPoint(ReferencePart.Position)
        
        if onScreen then
            local dist2D = (OriginPos - Vector2New(screenPos.X, screenPos.Y)).Magnitude
            
            if dist2D <= _G.AimbotConfig.FOVSize then
                if currentDistance3D < ClosestDistance3D then
                    local ValidPart = GetBestPart(Character)
                    if ValidPart then
                        ClosestDistance3D = currentDistance3D
                        BestPart = ValidPart
                        BestChar = Character
                    end
                end
            end
        end
    end
    return BestPart, BestChar
end

-- ================= GERENCIAMENTO (START/STOP) ================= --

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

    -- Adiciona config padrÃ£o para MagicBullet se nÃ£o existir
    if config.MagicBullet == nil then config.MagicBullet = true end 

    -- Visuais (FOV)
    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false
    fov_circle.Thickness = 1.5
    fov_circle.Transparency = 1
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    -- Visuais (UI)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InternalAimbotUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    if pcall(function() ScreenGui.Parent = CoreGui end) then
        _G.AimbotGui = ScreenGui
    else
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        _G.AimbotGui = ScreenGui
    end

    local TargetHighlight = Instance.new("Highlight")
    TargetHighlight.Name = "H"
    TargetHighlight.FillTransparency = 0.5
    TargetHighlight.OutlineTransparency = 0
    TargetHighlight.Parent = ScreenGui
    _G.AimHighlight = TargetHighlight

    -- Loop Visual e LÃ³gico
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

    local c2 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
            
            TargetHighlight.FillColor = config.HighlightColor
            if config.ShowHighlight and Character then
                TargetHighlight.Adornee = Character
                TargetHighlight.Enabled = true
            else
                TargetHighlight.Adornee = nil
                TargetHighlight.Enabled = false
            end
        else
            ClosestHitPart = nil
            CurrentTargetCharacter = nil
            TargetHighlight.Enabled = false
        end
    end)
    table.insert(_G.SilentAimConnections, c2)
end

-- ================= HOOK (MAGIC BULLET) ================= --

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not checkcaller() and _G.SilentAimActive and ClosestHitPart then
        local Method = getnamecallmethod()
        
        if MathRandom(1, 100) <= _G.AimbotConfig.HitChance then
            local Arguments = {...}
            local TargetPos = ClosestHitPart.Position + getLegitOffset()
            
            -- MAGIC BULLET TRICK: 
            -- Se "MagicBullet" estiver ativo, a gente recalcula a origem do tiro
            -- para ser PRÃ“XIMA ao alvo, garantindo que o Raycast do servidor nÃ£o bata na parede.
            local OriginPos = Camera.CFrame.Position
            if _G.AimbotConfig.MagicBullet then
                -- Move a origem para apenas 2 studs de distÃ¢ncia do alvo,
                -- "teleportando" a bala para lÃ¡
                OriginPos = TargetPos + (OriginPos - TargetPos).Unit * 2
            end

            -- Intercepta Raycast direto
            if Method == "Raycast" and self == Workspace then
                local rayOrigin = Arguments[1]
                
                if _G.AimbotConfig.MagicBullet then
                    rayOrigin = OriginPos -- Manipula a origem do raycast tambÃ©m
                end

                local direction = (TargetPos - rayOrigin).Unit * 5000 
                Arguments[1] = rayOrigin
                Arguments[2] = direction 
                return oldNamecall(self, unpack(Arguments))
            
            -- Intercepta Remotes de Arma
            elseif (Method == "FireServer" or Method == "InvokeServer") then
                if isBulletRemote(self.Name) then
                    
                    for i, v in Pairs(Arguments) do
                        if typeof(v) == "Vector3" then
                            -- Verifica se Ã© DireÃ§Ã£o ou PosiÃ§Ã£o
                            -- Geralmente vetores unitÃ¡rios (Magnitude ~1) sÃ£o direÃ§Ã£o
                            if v.Magnitude <= 5 then 
                                Arguments[i] = (TargetPos - OriginPos).Unit -- DireÃ§Ã£o Manipulada
                            else
                                Arguments[i] = TargetPos -- PosiÃ§Ã£o Manipulada
                            end
                        elseif typeof(v) == "CFrame" then
                            Arguments[i] = CFrameNew(OriginPos, TargetPos) -- CFrame da bala manipulado
                        elseif typeof(v) == "table" then
                            -- Recursivo para tabelas (muitos jogos mandam dados dentro de tabelas)
                            for k, subVal in Pairs(v) do
                                if typeof(subVal) == "Vector3" then
                                     if subVal.Magnitude <= 5 then
                                        v[k] = (TargetPos - OriginPos).Unit
                                     else
                                        v[k] = TargetPos
                                     end
                                elseif typeof(subVal) == "CFrame" then
                                    v[k] = CFrameNew(OriginPos, TargetPos)
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
