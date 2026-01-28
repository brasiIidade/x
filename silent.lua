-- Limpeza
if _G.SilentAimConnections then
    for _, conn in pairs(_G.SilentAimConnections) do conn:Disconnect() end
end
if _G.AimFOVCircle then pcall(function() _G.AimFOVCircle:Remove() end) _G.AimFOVCircle = nil end
if _G.AimbotGui then _G.AimbotGui:Destroy() _G.AimbotGui = nil end
if _G.AimHighlight then _G.AimHighlight:Destroy() _G.AimHighlight = nil end

-- Configuração Padrão
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

-- Config do ESP Original
local ESP_SETTINGS = {
    Enabled = true,
    FontSize = 11,
    Drawing = {
        Boxes = {
            Animate = true,
            RotationSpeed = 300,
            Gradient = false, GradientRGB1 = Color3.fromRGB(119, 120, 255), GradientRGB2 = Color3.fromRGB(0, 0, 0), 
            GradientFill = true, GradientFillRGB1 = Color3.fromRGB(119, 120, 255), GradientFillRGB2 = Color3.fromRGB(0, 0, 0), 
            Filled = { Enabled = true, Transparency = 0.75 },
            Full = { Enabled = true },
            Corner = { Enabled = true, RGB = Color3.fromRGB(255, 255, 255) },
        },
        Healthbar = {
            Enabled = true, HealthText = true, Lerp = false,
            Width = 2.5,
            Gradient = true, GradientRGB1 = Color3.fromRGB(200, 0, 0), GradientRGB2 = Color3.fromRGB(60, 60, 125), GradientRGB3 = Color3.fromRGB(119, 120, 255), 
        }
    }
}

-- Polyfill para cloneref se não existir
local cloneref = cloneref or function(o) return o end
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))
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
local WorldToScreenPoint = Camera.WorldToScreenPoint
local Raycast = Workspace.Raycast

_G.SilentAimConnections = {}
_G.SilentAimActive = false
local ClosestHitPart = nil
local CurrentTargetCharacter = nil
local RotationAngle, Tick = -45, tick();

-- Funções Auxiliares (Helper)
local Functions = {}
function Functions:Create(Class, Properties)
    local _Instance = typeof(Class) == 'string' and Instance.new(Class) or Class
    for Property, Value in pairs(Properties) do
        _Instance[Property] = Value
    end
    return _Instance;
end

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
    return Vector3New((MathRandom() - 0.5) * 0.5, (MathRandom() - 0.5) * 0.5, (MathRandom() - 0.5) * 0.5)
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
    FilterCache[1] = LocalPlayer.Character; FilterCache[2] = character; FilterCache[3] = Camera
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
        for _, t in IPairs(targets) do table.insert(partsToCheck, t) end
    end
    ShuffleTable(partsToCheck)
    for _, groupName in IPairs(partsToCheck) do
        local specificParts = PartMapping[groupName]
        if specificParts then
            for _, partName in IPairs(specificParts) do
                local part = character:FindFirstChild(partName)
                if part and IsPartVisible(part, character) then return part end
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
        if FocusMode then if not table.find(FocusList, Player.Name) then continue end
        else if isWhitelisted(Player) then continue end end

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
                local currentScore = (Priority == "Health") and Humanoid.Health or dist3D
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

_G.StopSilentAim = function()
    _G.SilentAimActive = false
    if _G.SilentAimConnections then
        for _, conn in pairs(_G.SilentAimConnections) do if conn then conn:Disconnect() end end
    end
    _G.SilentAimConnections = {}
    if _G.AimFOVCircle then pcall(function() _G.AimFOVCircle:Remove() end) _G.AimFOVCircle = nil end
    if _G.AimbotGui then _G.AimbotGui:Destroy() _G.AimbotGui = nil end
    if _G.AimHighlight then _G.AimHighlight:Destroy() _G.AimHighlight = nil end
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

_G.StartSilentAim = function()
    _G.StopSilentAim()
    _G.SilentAimActive = true
    local config = _G.AimbotConfig
    if not config.Enabled then _G.AimbotConfig.Enabled = true end

    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false; fov_circle.Thickness = 2; fov_circle.Transparency = 1; fov_circle.Color = config.FOVColor1; fov_circle.Filled = false; fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    -- Creating the ScreenGui and ESP Elements
    local ScreenGui = Functions:Create("ScreenGui", {Parent = CoreGui, Name = "HUD"})
    _G.AimbotGui = ScreenGui

    -- Elements Construction (Exactly as requested visual style)
    local Name = Functions:Create("TextLabel", {Parent = ScreenGui, Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_SETTINGS.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
    local Distance = Functions:Create("TextLabel", {Parent = ScreenGui, Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_SETTINGS.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
    local Weapon = Functions:Create("TextLabel", {Parent = ScreenGui, Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_SETTINGS.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
    local Box = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.75, BorderSizePixel = 0, Visible = false})
    local Gradient1 = Functions:Create("UIGradient", {Parent = Box, Enabled = ESP_SETTINGS.Drawing.Boxes.GradientFill, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP_SETTINGS.Drawing.Boxes.GradientFillRGB1), ColorSequenceKeypoint.new(1, ESP_SETTINGS.Drawing.Boxes.GradientFillRGB2)}})
    local Outline = Functions:Create("UIStroke", {Parent = Box, Enabled = ESP_SETTINGS.Drawing.Boxes.Gradient, Transparency = 0, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter})
    local Gradient2 = Functions:Create("UIGradient", {Parent = Outline, Enabled = ESP_SETTINGS.Drawing.Boxes.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP_SETTINGS.Drawing.Boxes.GradientRGB1), ColorSequenceKeypoint.new(1, ESP_SETTINGS.Drawing.Boxes.GradientRGB2)}})
    local Healthbar = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, Visible = false})
    local BehindHealthbar = Functions:Create("Frame", {Parent = ScreenGui, ZIndex = -1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0, Visible = false})
    local HealthbarGradient = Functions:Create("UIGradient", {Parent = Healthbar, Enabled = ESP_SETTINGS.Drawing.Healthbar.Gradient, Rotation = -90, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP_SETTINGS.Drawing.Healthbar.GradientRGB1), ColorSequenceKeypoint.new(0.5, ESP_SETTINGS.Drawing.Healthbar.GradientRGB2), ColorSequenceKeypoint.new(1, ESP_SETTINGS.Drawing.Healthbar.GradientRGB3)}})
    local HealthText = Functions:Create("TextLabel", {Parent = ScreenGui, Size = UDim2.new(0, 100, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP_SETTINGS.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), Visible = false})
    local Chams = Functions:Create("Highlight", {Parent = ScreenGui, FillTransparency = 1, OutlineTransparency = 0, OutlineColor = Color3.fromRGB(119, 120, 255), DepthMode = "AlwaysOnTop", Enabled = false})

    -- Corner Boxes
    local LeftTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})
    local LeftSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})
    local RightTop = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})
    local RightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})
    local BottomSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})
    local BottomDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})
    local BottomRightSide = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})
    local BottomRightDown = Functions:Create("Frame", {Parent = ScreenGui, BackgroundColor3 = ESP_SETTINGS.Drawing.Boxes.Corner.RGB, Visible = false})

    local c1 = RunService.RenderStepped:Connect(function()
        if _G.SilentAimActive and config.ShowFOV and fov_circle then
            fov_circle.Visible = true; fov_circle.Radius = config.FOVSize; fov_circle.Color = config.FOVColor1
            local pos = config.FOVBehavior == "Mouse" and UserInputService:GetMouseLocation() or Vector2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            fov_circle.Position = pos
        else if fov_circle then fov_circle.Visible = false end end

        if _G.SilentAimActive then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and config.ESP.Enabled then
                local HRP = Character.HumanoidRootPart
                local Humanoid = Character.Humanoid
                local Pos, OnScreen = WorldToScreenPoint(Camera, HRP.Position)

                if OnScreen then
                    local Size = HRP.Size.Y
                    local scaleFactor = (Size * Camera.ViewportSize.Y) / (Pos.Z * 2)
                    local w, h = 3 * scaleFactor, 4.5 * scaleFactor

                    -- Highlight (Chams)
                    if config.ShowHighlight then
                        Chams.Enabled = true
                        Chams.Adornee = Character
                        Chams.OutlineColor = config.HighlightColor
                        local breathe_effect = math.atan(math.sin(tick() * 2)) * 2 / math.pi
                        Chams.OutlineTransparency = 0 * breathe_effect * 0.01
                    else
                        Chams.Enabled = false
                    end

                    -- Box Animation
                    RotationAngle = RotationAngle + (tick() - Tick) * ESP_SETTINGS.Drawing.Boxes.RotationSpeed * math.cos(math.pi / 4 * tick() - math.pi / 2)
                    Gradient1.Rotation = RotationAngle; Gradient2.Rotation = RotationAngle; Tick = tick()

                    -- Box Update
                    Box.Visible = true
                    Box.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2)
                    Box.Size = UDim2.new(0, w, 0, h)

                    -- Corner Boxes
                    LeftTop.Visible = true; LeftTop.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2); LeftTop.Size = UDim2.new(0, w / 5, 0, 1)
                    LeftSide.Visible = true; LeftSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y - h / 2); LeftSide.Size = UDim2.new(0, 1, 0, h / 5)
                    BottomSide.Visible = true; BottomSide.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2); BottomSide.Size = UDim2.new(0, 1, 0, h / 5); BottomSide.AnchorPoint = Vector2.new(0, 5)
                    BottomDown.Visible = true; BottomDown.Position = UDim2.new(0, Pos.X - w / 2, 0, Pos.Y + h / 2); BottomDown.Size = UDim2.new(0, w / 5, 0, 1); BottomDown.AnchorPoint = Vector2.new(0, 1)
                    RightTop.Visible = true; RightTop.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y - h / 2); RightTop.Size = UDim2.new(0, w / 5, 0, 1); RightTop.AnchorPoint = Vector2.new(1, 0)
                    RightSide.Visible = true; RightSide.Position = UDim2.new(0, Pos.X + w / 2 - 1, 0, Pos.Y - h / 2); RightSide.Size = UDim2.new(0, 1, 0, h / 5); RightSide.AnchorPoint = Vector2.new(0, 0)
                    BottomRightSide.Visible = true; BottomRightSide.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2); BottomRightSide.Size = UDim2.new(0, 1, 0, h / 5); BottomRightSide.AnchorPoint = Vector2.new(1, 1)
                    BottomRightDown.Visible = true; BottomRightDown.Position = UDim2.new(0, Pos.X + w / 2, 0, Pos.Y + h / 2); BottomRightDown.Size = UDim2.new(0, w / 5, 0, 1); BottomRightDown.AnchorPoint = Vector2.new(1, 1)

                    -- Healthbar Update
                    if config.ESP.ShowHealth then
                        local health = Humanoid.Health / Humanoid.MaxHealth
                        Healthbar.Visible = true; BehindHealthbar.Visible = true
                        Healthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - health))
                        Healthbar.Size = UDim2.new(0, ESP_SETTINGS.Drawing.Healthbar.Width, 0, h * health)
                        BehindHealthbar.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2)
                        BehindHealthbar.Size = UDim2.new(0, ESP_SETTINGS.Drawing.Healthbar.Width, 0, h)
                        
                        HealthText.Visible = true
                        local healthPercentage = math.floor(Humanoid.Health / Humanoid.MaxHealth * 100)
                        HealthText.Position = UDim2.new(0, Pos.X - w / 2 - 6, 0, Pos.Y - h / 2 + h * (1 - healthPercentage / 100) + 3)
                        HealthText.Text = tostring(healthPercentage)
                    else
                        Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                    end

                    -- Texts (Below Feet)
                    local OffsetY = 0
                    
                    -- Name
                    if config.ESP.ShowName then
                        Name.Visible = true
                        Name.Text = string.format('(<font color="rgb(255, 0, 0)">inimigo</font>) %s', Character.Name)
                        Name.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 8)
                        OffsetY = OffsetY + 11
                    else
                        Name.Visible = false
                    end

                    -- Weapon
                    if config.ESP.ShowWeapon then
                        Weapon.Visible = true
                        local tool = Character:FindFirstChildWhichIsA("Tool")
                        Weapon.Text = tool and string.upper(tool.Name) or "nada equipado"
                        Weapon.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 8 + OffsetY)
                        OffsetY = OffsetY + 11
                    else
                        Weapon.Visible = false
                    end

                    -- Distance (using Distance label slot)
                    local Dist = (Camera.CFrame.Position - HRP.Position).Magnitude
                    Distance.Visible = true
                    Distance.Text = string.format("[%d m]", math.floor(Dist))
                    Distance.Position = UDim2.new(0, Pos.X, 0, Pos.Y + h / 2 + 8 + OffsetY)

                else
                    -- Offscreen but exists
                    Box.Visible = false; Name.Visible = false; Distance.Visible = false; Weapon.Visible = false
                    Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                    LeftTop.Visible = false; LeftSide.Visible = false; BottomSide.Visible = false; BottomDown.Visible = false
                    RightTop.Visible = false; RightSide.Visible = false; BottomRightSide.Visible = false; BottomRightDown.Visible = false
                end
            else
                -- No target or ESP off
                Box.Visible = false; Name.Visible = false; Distance.Visible = false; Weapon.Visible = false
                Healthbar.Visible = false; BehindHealthbar.Visible = false; HealthText.Visible = false
                Chams.Enabled = false
                LeftTop.Visible = false; LeftSide.Visible = false; BottomSide.Visible = false; BottomDown.Visible = false
                RightTop.Visible = false; RightSide.Visible = false; BottomRightSide.Visible = false; BottomRightDown.Visible = false
            end
        end
    end)
    table.insert(_G.SilentAimConnections, c1)
end

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
                        if typeof(v) == "Vector3" then Arguments[i] = (v.Magnitude <= 10) and Direction or finalPosition
                        elseif typeof(v) == "CFrame" then Arguments[i] = CFrameNew(cameraPos, finalPosition) end
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
