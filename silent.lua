--[[ 
    FULL SILENT AIM + CUSTOM ESP (MODIFIED)
    Unificação solicitada.
]]

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [ CONFIGURAÇÃO E VARIÁVEIS GLOBAIS ]
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if _G.SilentAimConnections then
    for _, conn in pairs(_G.SilentAimConnections) do conn:Disconnect() end
end
if _G.AimFOVCircle then pcall(function() _G.AimFOVCircle:Remove() end) _G.AimFOVCircle = nil end
if _G.AimbotGui then _G.AimbotGui:Destroy() _G.AimbotGui = nil end
if _G.AimHighlight then _G.AimHighlight:Destroy() _G.AimHighlight = nil end
if _G.ESPHolder then _G.ESPHolder:Destroy() _G.ESPHolder = nil end -- Limpeza do novo ESP

_G.AimbotConfig = _G.AimbotConfig or {
    Enabled = false,
    TeamCheck = "Team",         
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
    ShowFOV = false,
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

-- Compatibilidade de funções para diferentes executores
local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
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
local MathFloor = math.floor
local WorldToScreenPoint = Camera.WorldToScreenPoint
local Raycast = Workspace.Raycast

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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [ LÓGICA DO SILENT AIM (MANTIDA ORIGINAL) ]
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
    if table.find(_G.AimbotConfig.WhitelistedUsers, player.Name) then return true end
    if player.Team and table.find(_G.AimbotConfig.WhitelistedTeams, player.Team.Name) then return true end
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

    if #targets == 0 or table.find(targets, "Random") then
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
    local TeamCheck = _G.AimbotConfig.TeamCheck == "Team"
    local FocusMode = _G.AimbotConfig.FocusMode
    local FocusList = _G.AimbotConfig.FocusList
    local Priority = _G.AimbotConfig.TargetPriority or "Distance"

    for _, Player in IPairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        if TeamCheck and Player.Team == MyTeam then continue end

        if FocusMode then
            if not table.find(FocusList, Player.Name) then continue end
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
                    currentScore = Humanoid.Health
                else
                    currentScore = dist3D
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

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [ SISTEMA DE ESP / HUD (MODIFICADO) ]
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Functions = {}
do
    function Functions:Create(Class, Properties)
        local _Instance = typeof(Class) == 'string' and Instance.new(Class) or Class
        for Property, Value in pairs(Properties) do
            _Instance[Property] = Value
        end
        return _Instance;
    end
    
    function Functions:FadeOutOnDist(element, distance, maxDist)
        local transparency = math.max(0.1, 1 - (distance / maxDist))
        if element:IsA("TextLabel") then
            element.TextTransparency = 1 - transparency
        elseif element:IsA("ImageLabel") then
            element.ImageTransparency = 1 - transparency
        elseif element:IsA("UIStroke") then
            element.Transparency = 1 - transparency
        elseif element:IsA("Frame") then
            element.BackgroundTransparency = 1 - transparency
        elseif element:IsA("Highlight") then
            element.FillTransparency = 1 - transparency
            element.OutlineTransparency = 1 - transparency
        end;
    end;  
end;

local function StartNewESP()
    local ESP_Settings = {
        MaxDistance = _G.AimbotConfig.MaxDistance, -- Sincroniza com silent
        FontSize = 11,
        FadeOut = { OnDistance = true },
        Drawing = {
            Boxes = {
                Gradient = false, GradientRGB1 = Color3.fromRGB(119, 120, 255), GradientRGB2 = Color3.fromRGB(0, 0, 0), 
                GradientFill = true, GradientFillRGB1 = Color3.fromRGB(119, 120, 255), GradientFillRGB2 = Color3.fromRGB(0, 0, 0), 
                Filled = { Enabled = true, Transparency = 0.75 },
                Corner = { Enabled = true, RGB = Color3.fromRGB(255, 255, 255) },
                RotationSpeed = 300, Animate = true
            },
            Healthbar = {
                Gradient = true, GradientRGB1 = Color3.fromRGB(200, 0, 0), GradientRGB2 = Color3.fromRGB(60, 60, 125), GradientRGB3 = Color3.fromRGB(119, 120, 255), 
            }
        }
    }

    local ScreenGui = Functions:Create("ScreenGui", {
        Parent = CoreGui,
        Name = "ESPHolder",
        ResetOnSpawn = false,
        IgnoreGuiInset = true
    });
    _G.ESPHolder = ScreenGui

    local RotationAngle, Tick = -45, tick()

    local function PlayerESP(plr)
        local Connection
        local function Cleanup()
            if ScreenGui:FindFirstChild(plr.Name) then
                ScreenGui[plr.Name]:Destroy()
            end
            if Connection then Connection:Disconnect() end
        end
        Cleanup()

        local Container = Functions:Create("Folder", {Parent = ScreenGui, Name = plr.Name})

        -- Elementos do UI
        local Name = Functions:Create("TextLabel", {Parent = Container, Position = UDim2.new(0.5, 0, 0, -20), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_Settings.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
        local TeamName = Functions:Create("TextLabel", {Parent = Container, Position = UDim2.new(0.5, 0, 0, -10), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.Code, TextSize = ESP_Settings.FontSize - 2, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
        
        local Distance = Functions:Create("TextLabel", {Parent = Container, Position = UDim2.new(0.5, 0, 0, 11), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_Settings.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
        local Weapon = Functions:Create("TextLabel", {Parent = Container, Position = UDim2.new(0.5, 0, 0, 21), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_Settings.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true})
        
        local Box = Functions:Create("Frame", {Parent = Container, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.75, BorderSizePixel = 0})
        local Gradient1 = Functions:Create("UIGradient", {Parent = Box, Enabled = ESP_Settings.Drawing.Boxes.GradientFill, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP_Settings.Drawing.Boxes.GradientFillRGB1), ColorSequenceKeypoint.new(1, ESP_Settings.Drawing.Boxes.GradientFillRGB2)}})
        local Outline = Functions:Create("UIStroke", {Parent = Box, Enabled = ESP_Settings.Drawing.Boxes.Gradient, Transparency = 0, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter})
        local Gradient2 = Functions:Create("UIGradient", {Parent = Outline, Enabled = ESP_Settings.Drawing.Boxes.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP_Settings.Drawing.Boxes.GradientRGB1), ColorSequenceKeypoint.new(1, ESP_Settings.Drawing.Boxes.GradientRGB2)}})
        
        local Healthbar = Functions:Create("Frame", {Parent = Container, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0})
        local BehindHealthbar = Functions:Create("Frame", {Parent = Container, ZIndex = -1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0})
        local HealthbarGradient = Functions:Create("UIGradient", {Parent = Healthbar, Enabled = ESP_Settings.Drawing.Healthbar.Gradient, Rotation = -90, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP_Settings.Drawing.Healthbar.GradientRGB1), ColorSequenceKeypoint.new(0.5, ESP_Settings.Drawing.Healthbar.GradientRGB2), ColorSequenceKeypoint.new(1, ESP_Settings.Drawing.Healthbar.GradientRGB3)}})
        local HealthText = Functions:Create("TextLabel", {Parent = Container, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_Settings.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0)})
        
        local Chams = Functions:Create("Highlight", {Parent = Container, FillTransparency = 1, OutlineTransparency = 0, OutlineColor = Color3.fromRGB(119, 120, 255), DepthMode = "AlwaysOnTop"})
        
        -- Box Corners
        local Corners = {}
        for i=1, 8 do table.insert(Corners, Functions:Create("Frame", {Parent = Container, BackgroundColor3 = ESP_Settings.Drawing.Boxes.Corner.RGB})) end

        Connection = RunService.RenderStepped:Connect(function()
            -- Verifica se o Silent/ESP está ativo e se o jogador existe
            if not _G.SilentAimActive or not _G.AimbotConfig.ESP.Enabled or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or not plr.Character:FindFirstChild("Humanoid") then
                Container.Parent = nil -- Hide everything
                return
            else
                Container.Parent = ScreenGui -- Show
            end

            local HRP = plr.Character.HumanoidRootPart
            local Humanoid = plr.Character.Humanoid
            local Pos, OnScreen = Camera:WorldToScreenPoint(HRP.Position)
            local Dist = (Camera.CFrame.Position - HRP.Position).Magnitude
            local UnitDist = Dist / 3.57 -- Fator de escala usado no script original
            
            if OnScreen and Dist <= _G.AimbotConfig.MaxDistance and Humanoid.Health > 0 then
                local Size = HRP.Size.Y
                local scaleFactor = (Size * Camera.ViewportSize.Y) / (Pos.Z * 2)
                local w, h = 3 * scaleFactor, 4.5 * scaleFactor

                -- Fade Out Logic
                if ESP_Settings.FadeOut.OnDistance then
                    Functions:FadeOutOnDist(Box, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(Outline, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(Name, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(TeamName, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(Distance, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(Weapon, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(Healthbar, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(BehindHealthbar, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(HealthText, UnitDist, _G.AimbotConfig.MaxDistance)
                    Functions:FadeOutOnDist(Chams, UnitDist, _G.AimbotConfig.MaxDistance)
                    for _, c in pairs(Corners) do Functions:FadeOutOnDist(c, UnitDist, _G.AimbotConfig.MaxDistance) end
                end

                -- [LOGICA DOS ALVOS E CORES]
                local isTeammate = (LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team)
                local RelationText = isTeammate and "(Aliado)" or "(Inimigo)"
                local RelationColor = isTeammate and "0, 255, 0" or "255, 0, 0" -- Verde / Vermelho
                
                -- Se for o alvo focado do SilentAim
                if plr == CurrentTargetCharacter then
                   Chams.OutlineColor = _G.AimbotConfig.HighlightColor
                   Chams.Enabled = _G.AimbotConfig.ShowHighlight
                else
                   Chams.OutlineColor = Color3.fromRGB(119, 120, 255)
                   Chams.Enabled = true -- Default Chams
                end

                -- 1. BOXES
                Box.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                Box.Size = UDim2.new(0, w, 0, h)
                Box.Visible = true

                -- Animate Box
                RotationAngle = RotationAngle + (tick() - Tick) * ESP_Settings.Drawing.Boxes.RotationSpeed * math.cos(math.pi / 4 * tick() - math.pi / 2)
                if ESP_Settings.Drawing.Boxes.Animate then
                    Gradient1.Rotation = RotationAngle
                    Gradient2.Rotation = RotationAngle
                else
                    Gradient1.Rotation = -45
                    Gradient2.Rotation = -45
                end
                Tick = tick()

                -- Corner Logic (Simplified Loop for readability)
                local cx, cy = Pos.X, Pos.Y
                local hw, hh = w/2, h/2
                local cl = w/5 -- Corner length
                if ESP_Settings.Drawing.Boxes.Corner.Enabled then
                    Corners[1].Position = UDim2.new(0, cx - hw, 0, cy - hh); Corners[1].Size = UDim2.new(0, cl, 0, 1) -- Top Left H
                    Corners[2].Position = UDim2.new(0, cx - hw, 0, cy - hh); Corners[2].Size = UDim2.new(0, 1, 0, h/5) -- Top Left V
                    Corners[3].Position = UDim2.new(0, cx - hw, 0, cy + hh); Corners[3].Size = UDim2.new(0, 1, 0, h/5); Corners[3].AnchorPoint = Vector2.new(0, 1) -- Bot Left V
                    Corners[4].Position = UDim2.new(0, cx - hw, 0, cy + hh); Corners[4].Size = UDim2.new(0, cl, 0, 1); Corners[4].AnchorPoint = Vector2.new(0, 1) -- Bot Left H
                    Corners[5].Position = UDim2.new(0, cx + hw, 0, cy - hh); Corners[5].Size = UDim2.new(0, cl, 0, 1); Corners[5].AnchorPoint = Vector2.new(1, 0) -- Top Right H
                    Corners[6].Position = UDim2.new(0, cx + hw - 1, 0, cy - hh); Corners[6].Size = UDim2.new(0, 1, 0, h/5); Corners[6].AnchorPoint = Vector2.new(0, 0) -- Top Right V
                    Corners[7].Position = UDim2.new(0, cx + hw, 0, cy + hh); Corners[7].Size = UDim2.new(0, 1, 0, h/5); Corners[7].AnchorPoint = Vector2.new(1, 1) -- Bot Right V
                    Corners[8].Position = UDim2.new(0, cx + hw, 0, cy + hh); Corners[8].Size = UDim2.new(0, cl, 0, 1); Corners[8].AnchorPoint = Vector2.new(1, 1) -- Bot Right H
                    for _, c in pairs(Corners) do c.Visible = true end
                else
                    for _, c in pairs(Corners) do c.Visible = false end
                end

                -- 2. HEALTH
                if _G.AimbotConfig.ESP.ShowHealth then
                    local health = Humanoid.Health / Humanoid.MaxHealth
                    Healthbar.Visible = true; BehindHealthbar.Visible = true
                    Healthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - health))  
                    Healthbar.Size = UDim2.new(0, 2.5, 0, h * health)  
                    BehindHealthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2)  
                    BehindHealthbar.Size = UDim2.new(0, 2.5, 0, h)

                    local hpPerc = math.floor(Humanoid.Health / Humanoid.MaxHealth * 100)
                    HealthText.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - hpPerc / 100) + 3)
                    HealthText.Text = tostring(hpPerc)
                    HealthText.Visible = (Humanoid.Health < Humanoid.MaxHealth)
                    
                    local color = health >= 0.75 and Color3.fromRGB(0, 255, 0) or health >= 0.5 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
                    HealthText.TextColor3 = color
                else
                    Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                end

                -- 3. NAMES & RELATIONSHIP
                if _G.AimbotConfig.ESP.ShowName then
                    Name.Visible = true
                    -- Formatação pedida: (<Cor>Aliado/Inimigo</Cor>) Nome
                    Name.Text = string.format('(<font color="rgb(%s)">%s</font>) %s', RelationColor, RelationText, plr.Name)
                    Name.Position = UDim2.new(0, Pos.X, 0, Pos.Y - h / 2 - 20)
                else
                    Name.Visible = false
                end

                -- 4. TEAM NAME (NOVO)
                if _G.AimbotConfig.ESP.ShowTeam then
                    TeamName.Visible = true
                    TeamName.Text = plr.Team and plr.Team.Name or "Sem Time"
                    TeamName.TextColor3 = plr.TeamColor and plr.TeamColor.Color or Color3.fromRGB(200, 200, 200)
                    TeamName.Position = UDim2.new(0, Pos.X, 0, Pos.Y - h / 2 - 10) -- Logo abaixo do nome
                else
                    TeamName.Visible = false
                end
                
                -- 5. DISTANCE
                Distance.Visible = true
                Distance.Text = string.format("[%d metros]", math.floor(Dist))
                Distance.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 7)

                -- 6. WEAPON
                if _G.AimbotConfig.ESP.ShowWeapon then
                    Weapon.Visible = true
                    local tool = plr.Character:FindFirstChildWhichIsA("Tool")
                    if tool then
                        Weapon.Text = tool.Name
                    else
                        Weapon.Text = "Nada equipado" -- Modificação solicitada
                    end
                    Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 18)
                else
                    Weapon.Visible = false
                end

                -- Chams Update
                Chams.Adornee = plr.Character

            else
                -- Off screen or too far
                Container.Parent = nil
            end
        end)
        table.insert(_G.SilentAimConnections, Connection)
    end

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then PlayerESP(v) end
    end
    
    local addedConn = Players.PlayerAdded:Connect(function(v)
        if v ~= LocalPlayer then PlayerESP(v) end
    end)
    table.insert(_G.SilentAimConnections, addedConn)
end


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- [ FUNÇÕES DE CONTROLE (START/STOP) ]
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

_G.StopSilentAim = function()
    _G.SilentAimActive = false
    
    if _G.SilentAimConnections then
        for _, conn in pairs(_G.SilentAimConnections) do
            if conn then conn:Disconnect() end
        end
    end
    _G.SilentAimConnections = {}

    if _G.AimFOVCircle then pcall(function() _G.AimFOVCircle:Remove() end) _G.AimFOVCircle = nil end
    if _G.AimbotGui then _G.AimbotGui:Destroy() _G.AimbotGui = nil end
    if _G.AimHighlight then _G.AimHighlight:Destroy() _G.AimHighlight = nil end
    if _G.ESPHolder then _G.ESPHolder:Destroy() _G.ESPHolder = nil end
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

_G.StartSilentAim = function()
    _G.StopSilentAim()
    _G.SilentAimActive = true
    local config = _G.AimbotConfig
    
    if not config.Enabled then
         _G.AimbotConfig.Enabled = true
    end

    -- FOV Circle
    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false 
    fov_circle.Thickness = 2
    fov_circle.Transparency = 1
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    -- Render Loop para FOV e Target Calculation
    local c1 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive and config.ShowFOV and fov_circle then
            fov_circle.Visible = true
            fov_circle.Radius = config.FOVSize
            fov_circle.Color = config.FOVColor1
            local pos = config.FOVBehavior == "Mouse" and UserInputService:GetMouseLocation() or Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fov_circle.Position = pos
        else
            if fov_circle then fov_circle.Visible = false end
        end

        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        end
    end)
    table.insert(_G.SilentAimConnections, c1)

    -- Iniciar o novo sistema de ESP
    StartNewESP()
end

-- Hook Metamethod (Mantido Original)
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
