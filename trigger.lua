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

-- ConfiguraÃ§Ãµes Extras para o Triggerbot
if not _G.AimbotConfig.TriggerBot then
    _G.AimbotConfig.TriggerBot = {
        Enabled = true,
        Delay = 0.03,
        ReactionDistance = 30, -- DistÃ¢ncia da mira em pixels para ativar (menor = mais preciso)
        Spam = false -- Se true, clica sem parar; se false, clica e segura
    }
end

-- VariÃ¡veis de controle
_G.SilentAimConnections = {}
_G.SilentAimActive = false
local ClosestHitPart = nil
local CurrentTargetCharacter = nil
local TriggerbotLastShot = 0
local Mouse1Down = false

-- FunÃ§Ãµes Auxiliares
local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", 
    "missile", "rocket", "hit", "damage", "attack", 
    "cast", "ray", "target", "server", "remote", "action", 
    "mouse", "input", "create", "impact", "verify"
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
    if _G.AimbotConfig.MagicBullet then return true end -- ATIVA WALLBANG PARA DETECÃ‡ÃƒO
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
    local ClosestDistance2D = MathHuge -- Usado para o Triggerbot
    
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
                -- Prioridade por DistÃ¢ncia 3D (para Silent Aim)
                if currentDistance3D < ClosestDistance3D then
                    local ValidPart = GetBestPart(Character)
                    if ValidPart then
                        ClosestDistance3D = currentDistance3D
                        ClosestDistance2D = dist2D
                        BestPart = ValidPart
                        BestChar = Character
                    end
                end
            end
        end
    end
    return BestPart, BestChar, ClosestDistance2D
end

-- FunÃ§Ãµes de Input (Triggerbot)
local function PressMouse()
    if mouse1press then mouse1press() else 
        local t = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if t then t:Activate() end
    end
    Mouse1Down = true
end

local function ReleaseMouse()
    if mouse1release then mouse1release() else
        local t = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if t then t:Deactivate() end
    end
    Mouse1Down = false
end

-- ================= GERENCIAMENTO ================= --

_G.StopSilentAim = function()
    _G.SilentAimActive = false
    ReleaseMouse() -- Garante soltar o clique
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
    if config.MagicBullet == nil then config.MagicBullet = true end 

    -- Visuais
    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false
    fov_circle.Thickness = 1.5
    fov_circle.Transparency = 1
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InternalAimbotUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    if pcall(function() ScreenGui.Parent = CoreGui end) then _G.AimbotGui = ScreenGui else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui"); _G.AimbotGui = ScreenGui end
    local TargetHighlight = Instance.new("Highlight"); TargetHighlight.Name = "H"; TargetHighlight.FillTransparency = 0.5; TargetHighlight.OutlineTransparency = 0; TargetHighlight.Parent = ScreenGui; _G.AimHighlight = TargetHighlight

    -- Loop FOV
    local c1 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive and config.ShowFOV then
            fov_circle.Visible = true; fov_circle.Radius = config.FOVSize; fov_circle.Color = config.FOVColor1
            fov_circle.Position = (config.FOVBehavior == "Mouse") and UserInputService:GetMouseLocation() or Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        else
            fov_circle.Visible = false
        end
    end)
    table.insert(_G.SilentAimConnections, c1)

    -- Loop Principal (Silent Aim + Triggerbot)
    local c2 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive then
            local Part, Character, Dist2D = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
            
            -- Highlight Logic
            TargetHighlight.FillColor = config.HighlightColor
            if config.ShowHighlight and Character then
                TargetHighlight.Adornee = Character; TargetHighlight.Enabled = true
            else
                TargetHighlight.Adornee = nil; TargetHighlight.Enabled = false
            end

            -- TRIGGERBOT LOGIC
            if config.TriggerBot and config.TriggerBot.Enabled and Part then
                -- Checa se a mira estÃ¡ bem perto do alvo (Trigger zone)
                if Dist2D <= config.TriggerBot.ReactionDistance then
                    local now = tick()
                    if now - TriggerbotLastShot >= config.TriggerBot.Delay then
                        if not Mouse1Down then
                            PressMouse()
                            TriggerbotLastShot = now
                            if config.TriggerBot.Spam then 
                                task.delay(0.01, ReleaseMouse) -- Cliques rÃ¡pidos
                            end
                        end
                    end
                else
                    if Mouse1Down and not config.TriggerBot.Spam then ReleaseMouse() end
                end
            else
                if Mouse1Down and not config.TriggerBot.Spam then ReleaseMouse() end
            end
        else
            ClosestHitPart = nil; CurrentTargetCharacter = nil; TargetHighlight.Enabled = false
            if Mouse1Down then ReleaseMouse() end
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
            local OriginPos = Camera.CFrame.Position
            
            -- Se Triggerbot ou MagicBullet estiver ativado, movemos a origem do tiro
            if _G.AimbotConfig.MagicBullet then
                OriginPos = TargetPos + (OriginPos - TargetPos).Unit * 2
            end

            if Method == "Raycast" and self == Workspace then
                if _G.AimbotConfig.MagicBullet then Arguments[1] = OriginPos end
                local direction = (TargetPos - Arguments[1]).Unit * 5000 
                Arguments[2] = direction 
                return oldNamecall(self, unpack(Arguments))
            elseif (Method == "FireServer" or Method == "InvokeServer") then
                if isBulletRemote(self.Name) then
                    for i, v in Pairs(Arguments) do
                        if typeof(v) == "Vector3" then
                            if v.Magnitude <= 5 then Arguments[i] = (TargetPos - OriginPos).Unit else Arguments[i] = TargetPos end
                        elseif typeof(v) == "CFrame" then
                            Arguments[i] = CFrameNew(OriginPos, TargetPos)
                        elseif typeof(v) == "table" then
                            for k, subVal in Pairs(v) do
                                if typeof(subVal) == "Vector3" then
                                    if subVal.Magnitude <= 5 then v[k] = (TargetPos - OriginPos).Unit else v[k] = TargetPos end
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
