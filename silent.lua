_G.AimbotConfig = _G.AimbotConfig or {
    Enabled = false,
    TeamCheck = "Team",         
    TargetPart = {"Random"},      
    MaxDistance = 1000,         
    SwitchThreshold = 5,
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
local TextService = game:GetService("TextService")
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

_G.SilentAimConnections = {}
_G.SilentAimActive = false
local ClosestHitPart = nil
local CurrentTargetCharacter = nil

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

local function toUpper(str)
    if not str then return "" end
    local map = {
        ["á"]="Á", ["é"]="É", ["í"]="Í", ["ó"]="Ó", ["ú"]="Ú",
        ["ã"]="Ã", ["õ"]="Õ", ["â"]="Â", ["ê"]="Ê", ["ô"]="Ô",
        ["ç"]="Ç", ["à"]="À"
    }
    local result = str:upper()
    for lower, upper in pairs(map) do
        result = result:gsub(lower, upper)
    end
    return result
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

    local fov_circle = Drawing.new("Circle")
    fov_circle.Visible = false
    fov_circle.Thickness = 1.5
    fov_circle.Transparency = 0.8
    fov_circle.Color = config.FOVColor1
    fov_circle.Filled = false
    fov_circle.NumSides = 64
    _G.AimFOVCircle = fov_circle

    local SafeParent = (gethui and gethui()) or CoreGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InternalAimbotUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.Parent = SafeParent
    _G.AimbotGui = ScreenGui

    local TargetHighlight = Instance.new("Highlight")
    TargetHighlight.Name = "TargetFX"
    TargetHighlight.FillTransparency = 0.85
    TargetHighlight.OutlineTransparency = 0.1
    TargetHighlight.OutlineColor = config.HighlightColor
    TargetHighlight.FillColor = config.HighlightColor
    TargetHighlight.Parent = ScreenGui
    _G.AimHighlight = TargetHighlight

    local HeadBillboard = Instance.new("BillboardGui")
    HeadBillboard.Size = UDim2.fromOffset(210, 50)
    HeadBillboard.StudsOffset = Vector3New(0, 6.5, 0)
    HeadBillboard.AlwaysOnTop = true
    HeadBillboard.Enabled = false
    HeadBillboard.Parent = ScreenGui

    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.Size = UDim2.new(1, 0, 1, 0)
    MainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MainContainer.BackgroundTransparency = 0.25
    MainContainer.BorderSizePixel = 0
    MainContainer.Parent = HeadBillboard

    local ContainerCorner = Instance.new("UICorner")
    ContainerCorner.CornerRadius = UDim.new(0, 6)
    ContainerCorner.Parent = MainContainer

    local ContainerStroke = Instance.new("UIStroke")
    ContainerStroke.Thickness = 1.5
    ContainerStroke.Color = config.HighlightColor
    ContainerStroke.Transparency = 0.3
    ContainerStroke.Parent = MainContainer

    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 4)
    Padding.PaddingBottom = UDim.new(0, 4)
    Padding.PaddingLeft = UDim.new(0, 8)
    Padding.PaddingRight = UDim.new(0, 8)
    Padding.Parent = MainContainer

    local TopRow = Instance.new("Frame")
    TopRow.BackgroundTransparency = 1
    TopRow.Size = UDim2.new(1, 0, 0, 14)
    TopRow.Parent = MainContainer

    local NameLabel = Instance.new("TextLabel")
    NameLabel.BackgroundTransparency = 1
    NameLabel.Size = UDim2.new(0.6, 0, 1, 0)
    NameLabel.Position = UDim2.new(0, 0, 0, 0)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 13
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = TopRow

    local TeamLabel = Instance.new("TextLabel")
    TeamLabel.BackgroundTransparency = 1
    TeamLabel.Size = UDim2.new(0.4, 0, 1, 0)
    TeamLabel.Position = UDim2.new(0.6, 0, 0, 0)
    TeamLabel.Font = Enum.Font.Gotham
    TeamLabel.TextSize = 11
    TeamLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    TeamLabel.TextXAlignment = Enum.TextXAlignment.Right
    TeamLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TeamLabel.Parent = TopRow

    local BottomRow = Instance.new("Frame")
    BottomRow.BackgroundTransparency = 1
    BottomRow.Size = UDim2.new(1, 0, 0, 14)
    BottomRow.Position = UDim2.new(0, 0, 0.45, 0)
    BottomRow.Parent = MainContainer

    local WeaponLabel = Instance.new("TextLabel")
    WeaponLabel.BackgroundTransparency = 1
    WeaponLabel.Size = UDim2.new(1, 0, 1, 0)
    WeaponLabel.Font = Enum.Font.Gotham
    WeaponLabel.TextSize = 11
    WeaponLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    WeaponLabel.TextXAlignment = Enum.TextXAlignment.Left
    WeaponLabel.TextTruncate = Enum.TextTruncate.AtEnd
    WeaponLabel.Parent = BottomRow

    local HealthLabel = Instance.new("TextLabel")
    HealthLabel.BackgroundTransparency = 1
    HealthLabel.Size = UDim2.new(1, 0, 0, 12)
    HealthLabel.Position = UDim2.new(0, 0, 1, -12)
    HealthLabel.Font = Enum.Font.Code
    HealthLabel.TextSize = 10
    HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    HealthLabel.TextXAlignment = Enum.TextXAlignment.Center
    HealthLabel.Text = "[ 100 / 100 ]"
    HealthLabel.Parent = MainContainer

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
        
            if config.ShowHighlight and Character then
                TargetHighlight.Adornee = Character
                TargetHighlight.Enabled = true
                TargetHighlight.OutlineColor = config.HighlightColor
                ContainerStroke.Color = config.HighlightColor
            else
                TargetHighlight.Adornee = nil
                TargetHighlight.Enabled = false
            end

            if config.ESP.Enabled and Character then
                local head = Character:FindFirstChild("Head")
                local hum = Character:FindFirstChild("Humanoid")
                local plr = Players:GetPlayerFromCharacter(Character)

                if head and hum then
                    HeadBillboard.Adornee = head
                    HeadBillboard.Enabled = true
                    
                    if config.ESP.ShowName then
                        NameLabel.Visible = true
                        NameLabel.Text = Character.Name
                    else
                        NameLabel.Visible = false
                    end

                    if config.ESP.ShowTeam and plr then
                        TeamLabel.Visible = true
                        TeamLabel.Text = plr.Team and plr.Team.Name or "No Team"
                        TeamLabel.TextColor3 = plr.TeamColor and plr.TeamColor.Color or Color3.fromRGB(200, 200, 200)
                    else
                        TeamLabel.Visible = false
                    end

                    if config.ESP.ShowWeapon then
                        WeaponLabel.Visible = true
                        local tool = Character:FindFirstChildWhichIsA("Tool")
                        if tool then
                            WeaponLabel.Text = toUpper(tool.Name)
                            WeaponLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        else
                            WeaponLabel.Text = "NADA EQUIPADO"
                            WeaponLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                        end
                    else
                        WeaponLabel.Visible = false
                    end

                    if config.ESP.ShowHealth then
                        HealthLabel.Visible = true
                        local hp = MathFloor(hum.Health)
                        local maxHp = MathFloor(hum.MaxHealth)
                        HealthLabel.Text = string.format("[ %d / %d ]", hp, maxHp)
                        local frac = math.clamp(hp/maxHp, 0, 1)
                        HealthLabel.TextColor3 = Color3.fromHSV(frac * 0.3, 0.9, 1)
                    else
                        HealthLabel.Visible = false
                    end
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
