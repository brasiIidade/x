local function Finalizar(Mensagem)
    print(Mensagem)
    task.wait(0.5)
    local function Crash() return Crash() end
    Crash()
end

local RanTimes = 0
local Connection = game:GetService("RunService").Heartbeat:Connect(function()
    RanTimes = RanTimes + 1
end)

repeat
    task.wait()
until RanTimes >= 2

Connection:Disconnect()

if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or ({debug.info(print,'a')})[1]~=0 or ({debug.info(tostring,'a')})[1]~=0 or ({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" or not select(1, pcall(debug.info, coroutine.wrap(function() end)(), 's')) == false then
    Finalizar("skid de EB :(")
end

if not game.ServiceAdded then
    Finalizar("skid de EB :(")
end

if getfenv()[Instance.new("Part")] then
    Finalizar("skid de EB :(")
end

if getmetatable(__call) then
    Finalizar("skid de EB :(")
end

local Success = pcall(function()
    Instance.new("Part"):BananaPeelSlipper("a")
end)

if Success then
    Finalizar("skid de EB :(")
end

local Success, Result = pcall(function()
    return game:GetService("HttpService"):JSONDecode([=[
        [
            42,
            "deworming tablets",
            false,
            987,
            true,
            [555, "shimmer", null],
            null,
            ["x", 77, true],
            {"key": "value", "num": 101},
            [null, ["nested", 999, false]]
        ]
    ]=])
end)

if not Success then
    Finalizar("skid de EB :(")
end

if Result[6][3] ~= nil then
    Finalizar("skid de EB :(")
end

local _, Message = pcall(function()
    game()
end)

if not Message:find("attempt to call a Instance value") then
    Finalizar("skid de EB :(")
end

if #game:GetChildren() <= 4 then
    Finalizar("skid de EB :(")
end

local cloneref = cloneref or function(o) return o end

_G.AimbotConfig = _G.AimbotConfig or {
    Enabled = false,
    TeamCheck = "Team",         
    TargetPart = {"Random"},
    TargetPriority = "Distance",
    MaxDistance = 3000,         
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
    FOVBehavior = "Center",
    FOVNumSides = 10,
    FOVColor1 = Color3.fromRGB(24, 24, 201),
    FOVColor2 = Color3.fromRGB(217, 217, 217),
    GradientSpeed = 5,
    
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

local SilentAimConnections = {}
local FOVLines = {}
local ESPDrawings = {}

if _G.SilentAimConnections then
    for _, conn in pairs(_G.SilentAimConnections) do pcall(function() conn:Disconnect() end) end
end
_G.SilentAimConnections = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local unpack = table.unpack or unpack
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local CFrameNew = CFrame.new
local MathRandom = math.random
local IPairs = ipairs
local Pairs = pairs
local StringLower = string.lower
local StringFind = string.find
local MathHuge = math.huge
local Raycast = Workspace.Raycast

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

local function getLegitOffset()
    if not _G.AimbotConfig.UseLegitOffset then return Vector3New(0,0,0) end
    return Vector3New((MathRandom() - 0.5) * 0.5, (MathRandom() - 0.5) * 0.5, (MathRandom() - 0.5) * 0.5)
end

local function isBulletRemote(name)
    if not name then return false end
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
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local direction = part.Position - origin
    FilterCache[1] = LocalPlayer.Character; FilterCache[2] = character; FilterCache[3] = cam
    RayParams.FilterDescendantsInstances = FilterCache
    local rayResult = Raycast(Workspace, origin, direction, RayParams)
    return rayResult == nil or rayResult.Instance:IsDescendantOf(character)
end

local function ShuffleTable(t)
    if not t then return {} end
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
    local cam = Workspace.CurrentCamera
    if not cam then return nil, nil end

    local BestPart = nil
    local BestChar = nil
    local BestScore = MathHuge
    local OriginPos
    
    if _G.AimbotConfig.FOVBehavior == "Mouse" then
        OriginPos = UserInputService:GetMouseLocation()
    else
        OriginPos = Vector2New(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    end

    local MyPos = cam.CFrame.Position
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
        local screenPos, onScreen = cam:WorldToViewportPoint(CheckPart.Position)

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
    for _, conn in pairs(SilentAimConnections) do if conn then conn:Disconnect() end end
    SilentAimConnections = {}
    for _, line in pairs(FOVLines) do pcall(function() line:Remove() end) end
    FOVLines = {}
    
    for _, drawing in pairs(ESPDrawings) do pcall(function() drawing:Remove() end) end
    ESPDrawings = {}
    
    ClosestHitPart = nil
    CurrentTargetCharacter = nil
end

local function CreateDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    table.insert(ESPDrawings, d)
    return d
end

_G.StartSilentAim = function()
    _G.StopSilentAim()
    _G.SilentAimActive = true
    local config = _G.AimbotConfig
    if not config.Enabled then _G.AimbotConfig.Enabled = true end

    FOVLines = {} 

    local DrawBoxOutline = CreateDrawing("Square", {Thickness = 3, Filled = false, Color = Color3.fromRGB(0, 0, 0), Visible = false})
    local DrawBox = CreateDrawing("Square", {Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255), Visible = false})
    
    local DrawHealthBg = CreateDrawing("Square", {Thickness = 1, Filled = true, Color = Color3.fromRGB(0, 0, 0), Visible = false})
    local DrawHealth = CreateDrawing("Square", {Thickness = 1, Filled = true, Color = Color3.fromRGB(0, 255, 0), Visible = false})
    
    local DrawName = CreateDrawing("Text", {Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false})
    local DrawTeam = CreateDrawing("Text", {Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false})
    local DrawWeapon = CreateDrawing("Text", {Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false})
    local DrawDistance = CreateDrawing("Text", {Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false})
    local DrawHealthText = CreateDrawing("Text", {Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false})

    local c1 = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        
        if _G.SilentAimActive and config.ShowFOV and cam then
            local pos = config.FOVBehavior == "Mouse" and UserInputService:GetMouseLocation() or Vector2New(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            local numSides = config.FOVNumSides or 60
            local radius = config.FOVSize
            local angleStep = (math.pi * 2) / numSides
            local time = tick()
                
            for i = 1, numSides do
                if not FOVLines[i] then
                    local l = Drawing.new("Line")
                    l.Thickness = 2
                    l.Transparency = 1
                    l.Visible = true
                    FOVLines[i] = l
                end
            end

            for i = numSides + 1, #FOVLines do
                if FOVLines[i] then FOVLines[i].Visible = false end
            end

            for i = 1, numSides do
                local line = FOVLines[i]
                if line then
                    line.Visible = true
                    line.Thickness = 2
                    
                    local currentRad = angleStep * (i - 1)
                    local nextRad = angleStep * i

                    local p1 = pos + Vector2New(math.cos(currentRad) * radius, math.sin(currentRad) * radius)
                    local p2 = pos + Vector2New(math.cos(nextRad) * radius, math.sin(nextRad) * radius)

                    line.From = p1
                    line.To = p2

                    local progress = i / numSides
                    local wave = math.sin(time * config.GradientSpeed + (progress * math.pi * 2))
                    local lerpFactor = (wave + 1) / 2
                    
                    line.Color = config.FOVColor1:Lerp(config.FOVColor2, lerpFactor)
                end
            end
        else
            if FOVLines then
                for _, l in pairs(FOVLines) do l.Visible = false end
            end
        end

        if _G.SilentAimActive and cam then
            local Part, Character = getClosestPlayer()
            ClosestHitPart = Part
            CurrentTargetCharacter = Character
        
            if Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("Humanoid") and config.ESP.Enabled then
                local HRP = Character.HumanoidRootPart
                local Humanoid = Character.Humanoid
                local Pos, OnScreen = cam:WorldToViewportPoint(HRP.Position)

                if OnScreen then
                    local Size = HRP.Size.Y
                    local scaleFactor = (Size * cam.ViewportSize.Y) / (Pos.Z * 2)
                    local w, h = 3 * scaleFactor, 4.5 * scaleFactor
                    local x, y = Pos.X - w / 2, Pos.Y - h / 2

                    DrawBoxOutline.Position = Vector2New(x, y)
                    DrawBoxOutline.Size = Vector2New(w, h)
                    DrawBoxOutline.Visible = true

                    DrawBox.Position = Vector2New(x, y)
                    DrawBox.Size = Vector2New(w, h)
                    DrawBox.Visible = true

                    if config.ESP.ShowHealth then
                        local health = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
                        local healthHeight = h * health
                        
                        DrawHealthBg.Position = Vector2New(x - 6, y)
                        DrawHealthBg.Size = Vector2New(4, h)
                        DrawHealthBg.Visible = true
                        
                        DrawHealth.Position = Vector2New(x - 5, y + (h - healthHeight))
                        DrawHealth.Size = Vector2New(2, healthHeight)
                        DrawHealth.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), health)
                        DrawHealth.Visible = true

                        local healthPercentage = math.floor(health * 100)
                        DrawHealthText.Position = Vector2New(x - 15, y + (h - healthHeight) - 5)
                        DrawHealthText.Text = tostring(healthPercentage)
                        DrawHealthText.Visible = true
                    else
                        DrawHealthBg.Visible = false
                        DrawHealth.Visible = false
                        DrawHealthText.Visible = false
                    end

                    local OffsetY = 0
                    if config.ESP.ShowName then
                        local plr = Players:GetPlayerFromCharacter(Character)
                        local statusText = "Inimigo"
                        local statusColor = Color3.fromRGB(255, 0, 0)
                        
                        if plr and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                            statusText = "Aliado"
                            statusColor = Color3.fromRGB(0, 255, 0)
                        end
                        
                        DrawName.Text = string.format("(%s) %s", statusText, Character.Name)
                        DrawName.Color = statusColor
                        DrawName.Position = Vector2New(Pos.X, y + h + 5)
                        DrawName.Visible = true
                        OffsetY = OffsetY + 13
                    else
                        DrawName.Visible = false
                    end

                    if config.ESP.ShowTeam then
                        local plr = Players:GetPlayerFromCharacter(Character)
                        local tName = plr and plr.Team and plr.Team.Name or "Sem time"
                        local tColor = plr and plr.TeamColor and plr.TeamColor.Color or Color3.fromRGB(255, 255, 255)
                        
                        DrawTeam.Text = tName
                        DrawTeam.Color = tColor
                        DrawTeam.Position = Vector2New(Pos.X, y + h + 5 + OffsetY)
                        DrawTeam.Visible = true
                        OffsetY = OffsetY + 13
                    else
                        DrawTeam.Visible = false
                    end

                    if config.ESP.ShowWeapon then
                        local tool = Character:FindFirstChildWhichIsA("Tool")
                        DrawWeapon.Text = tool and string.upper(tool.Name) or "Nada equipado"
                        DrawWeapon.Position = Vector2New(Pos.X, y + h + 5 + OffsetY)
                        DrawWeapon.Visible = true
                        OffsetY = OffsetY + 13
                    else
                        DrawWeapon.Visible = false
                    end

                    local Dist = (cam.CFrame.Position - HRP.Position).Magnitude
                    DrawDistance.Text = string.format("[%d m]", math.floor(Dist))
                    DrawDistance.Position = Vector2New(Pos.X, y + h + 5 + OffsetY)
                    DrawDistance.Visible = true

                else
                    for _, d in pairs(ESPDrawings) do d.Visible = false end
                end
            else
                for _, d in pairs(ESPDrawings) do d.Visible = false end
            end
        end
    end)
    table.insert(SilentAimConnections, c1)
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not checkcaller() and _G.SilentAimActive and ClosestHitPart then
        local Method = getnamecallmethod()
        local args = {...}
        local argsCount = select("#", ...)
        
        if argsCount == 0 then return oldNamecall(self, ...) end

        if MathRandom(1, 100) <= (_G.AimbotConfig.HitChance or 100) then
            local cam = Workspace.CurrentCamera
            if not cam then return oldNamecall(self, unpack(args, 1, argsCount)) end
            
            local finalPosition = ClosestHitPart.Position + (getLegitOffset and getLegitOffset() or Vector3New(0,0,0))
            local cameraPos = cam.CFrame.Position
            local Direction = (finalPosition - cameraPos).Unit

            if (Method == "FireServer" or Method == "InvokeServer") then
                if isBulletRemote(self.Name) then
                    for i = 1, argsCount do
                        local v = args[i]
                        if typeof(v) == "Vector3" then
                            if v.Magnitude <= 10 then 
                                args[i] = Direction * v.Magnitude
                            else
                                args[i] = finalPosition
                            end
                        elseif typeof(v) == "CFrame" then
                            args[i] = CFrameNew(cameraPos, finalPosition)
                        elseif typeof(v) == "Instance" and v:IsA("BasePart") and v.Parent and v.Parent:FindFirstChild("Humanoid") then
                            args[i] = ClosestHitPart
                        end
                    end
                    return oldNamecall(self, unpack(args, 1, argsCount))
                end

            elseif Method == "Raycast" and self == Workspace then
                local origin = args[1]
                local distance = 10000
                if args[2] then distance = args[2].Magnitude end
                
                args[2] = (finalPosition - origin).Unit * distance
                return oldNamecall(self, unpack(args, 1, argsCount))
            end
        end
    end
    return oldNamecall(self, ...)
end))

if _G.AimbotConfig and _G.AimbotConfig.Enabled then
    _G.StartSilentAim()
end
