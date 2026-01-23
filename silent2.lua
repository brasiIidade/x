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

-- Variáveis de controle
_G.SilentAimConnections = {}
_G.SilentAimActive = false
local ClosestHitPart = nil
local CurrentTargetCharacter = nil

-- Funções Auxiliares
local bulletFunctions = {
    "fire", "shoot", "bullet", "ammo", "projectile", 
    "missile", "rocket", "hit", "damage", "attack", 
    "cast", "ray", "target", "server", "remote", "action", 
    "mouse", "input", "create"
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
    
    -- Desconecta loops
    for _, conn in pairs(_G.SilentAimConnections) do
        if conn then conn:Disconnect() end
    end
    _G.SilentAimConnections = {}

    -- Limpa visuais
    if _G.AimFOVCircle then _G.AimFOVCircle:Remove(); _G.AimFOVCircle = nil end
    if _G.AimbotGui then _G.AimbotGui:Destroy(); _G.AimbotGui = nil end
    if _G.AimHighlight then _G.AimHighlight:Destroy(); _G.AimHighlight = nil end
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

_G.StartSilentAim = function()
    _G.StopSilentAim() -- Garante limpeza antes de iniciar
    _G.SilentAimActive = true
    local config = _G.AimbotConfig

    -- 1. Cria Visuais (FOV)
    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false
    fov_circle.Thickness = 1.5
    fov_circle.Transparency = 1
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    -- 2. Cria Visuais (UI/ESP)
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

    local InfoPanelTop = Instance.new("BillboardGui", ScreenGui); InfoPanelTop.Size = UDim2.new(0, 200, 0, 50); InfoPanelTop.StudsOffset = Vector3New(0, 4, 0); InfoPanelTop.AlwaysOnTop = true; InfoPanelTop.Enabled = false 
    local LabelTop = Instance.new("TextLabel", InfoPanelTop); LabelTop.BackgroundTransparency = 1; LabelTop.Size = UDim2.new(1, 0, 1, 0); LabelTop.Font = Enum.Font.GothamBold; LabelTop.TextYAlignment = Enum.TextYAlignment.Bottom; LabelTop.TextSize = 14
    local InfoPanelBot = Instance.new("BillboardGui", ScreenGui); InfoPanelBot.Size = UDim2.new(0, 200, 0, 50); InfoPanelBot.StudsOffset = Vector3New(0, -3.5, 0); InfoPanelBot.AlwaysOnTop = true; InfoPanelBot.Enabled = false
    local LabelBot = Instance.new("TextLabel", InfoPanelBot); LabelBot.BackgroundTransparency = 1; LabelBot.Size = UDim2.new(1, 0, 1, 0); LabelBot.Font = Enum.Font.GothamBold; LabelBot.TextYAlignment = Enum.TextYAlignment.Top; LabelBot.TextSize = 13

    -- 3. Loop do FOV
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

    -- 4. Loop Principal (Busca de Alvo + ESP)
    local c2 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
            
            -- Atualiza Highlight/ESP
            TargetHighlight.FillColor = config.HighlightColor
            if config.ShowHighlight and Character then
                TargetHighlight.Adornee = Character
                TargetHighlight.Enabled = true
            else
                TargetHighlight.Adornee = nil
                TargetHighlight.Enabled = false
            end

            -- Atualiza Textos ESP
            if config.ESP.Enabled and Character then
                local head = Character:FindFirstChild("Head")
                local root = Character:FindFirstChild("HumanoidRootPart")
                local hum = Character:FindFirstChild("Humanoid")

                if head and root and hum then
                    InfoPanelTop.Adornee = head; InfoPanelTop.Enabled = true
                    InfoPanelBot.Adornee = root; InfoPanelBot.Enabled = true
                    
                    local nameStr = config.ESP.ShowName and "[" .. Character.Name .. "]" or ""
                    local hpStr = config.ESP.ShowHealth and "[" .. math.floor(hum.Health) .. "]" or ""
                    
                    LabelTop.Text = nameStr .. (nameStr ~= "" and "\n" or "") .. hpStr
                    LabelTop.TextColor3 = config.ESP.ShowHealth and Color3.new(1 - (hum.Health/100), (hum.Health/100), 0) or config.ESP.TextColor
                    LabelTop.TextStrokeColor3 = config.ESP.OutlineColor

                    local tool = Character:FindFirstChildWhichIsA("Tool")
                    LabelBot.Text = (config.ESP.ShowWeapon and tool) and "[" .. tool.Name .. "]" or ""
                    LabelBot.TextColor3 = config.ESP.TextColor
                    LabelBot.TextStrokeColor3 = config.ESP.OutlineColor
                else
                    InfoPanelTop.Enabled = false; InfoPanelBot.Enabled = false
                end
            else
                InfoPanelTop.Enabled = false; InfoPanelBot.Enabled = false
            end
        else
            ClosestHitPart = nil
            CurrentTargetCharacter = nil
            TargetHighlight.Enabled = false
            InfoPanelTop.Enabled = false; InfoPanelBot.Enabled = false
        end
    end)
    table.insert(_G.SilentAimConnections, c2)
end

-- ================= HOOK (GLOBAL) ================= --
-- O hook roda sempre, mas a verificação "if not _G.SilentAimActive" no topo o torna ultra-leve quando desligado.

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not checkcaller() and _G.SilentAimActive and ClosestHitPart then
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
                            if v.Magnitude <= 5 then 
                                Arguments[i] = (finalPosition - cameraPos).Unit
                            else
                                Arguments[i] = finalPosition
                            end
                        elseif typeof(v) == "CFrame" then
                            Arguments[i] = CFrameNew(cameraPos, finalPosition)
                        elseif typeof(v) == "table" then
                            for k, subVal in Pairs(v) do
                                if typeof(subVal) == "Vector3" then
                                     if subVal.Magnitude <= 5 then
                                        v[k] = (finalPosition - cameraPos).Unit
                                     else
                                        v[k] = finalPosition
                                     end
                                elseif typeof(subVal) == "CFrame" then
                                    v[k] = CFrameNew(cameraPos, finalPosition)
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
