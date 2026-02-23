local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    GuiService = game:GetService("GuiService"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

local gethui = gethui or function() return Services.CoreGui end
local clonefunction = clonefunction or function(f) return f end
local raycast = clonefunction(Services.Workspace.Raycast)
local wts = clonefunction(Camera.WorldToScreenPoint)
local get_mouse = clonefunction(Services.UserInputService.GetMouseLocation)

local PartMapping = {
    ["Cabeça"] = {"Head"},
    ["Tronco"] = {"Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    ["Braço direito"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["Braço esquerdo"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["Perna direita"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"},
    ["Perna esquerda"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"}
}

local AllCategories = {"Cabeça", "Tronco", "Braço direito", "Braço esquerdo", "Perna direita", "Perna esquerda"}

local Visuals = {
    Gui = nil,
    Circle = nil,
    Stroke = nil,
    Highlight = nil,
    ESP = nil,
    Labels = {}
}

local function InitVisuals()
    if Visuals.Gui then Visuals.Gui:Destroy() end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = Services.HttpService:GenerateGUID(false)
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = gethui()
    
    local circle = Instance.new("Frame", gui)
    circle.BackgroundTransparency = 1
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Visible = false
    
    local stroke = Instance.new("UIStroke", circle)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local corner = Instance.new("UICorner", circle)
    corner.CornerRadius = UDim.new(1, 0)
    
    local hl = Instance.new("Highlight", gui)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    
    local esp = Instance.new("BillboardGui", gui)
    esp.Size = UDim2.fromOffset(200, 150)
    esp.StudsOffset = Vector3.new(0, 3, 0)
    esp.AlwaysOnTop = true
    esp.Enabled = false
    
    local container = Instance.new("Frame", esp)
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout", container)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    
    local function createLabel(order, font, color)
        local l = Instance.new("TextLabel", container)
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, 0, 0, 14)
        l.Font = font or Enum.Font.GothamBold
        l.TextSize = 12
        l.TextColor3 = color or Color3.new(1, 1, 1)
        l.TextStrokeTransparency = 0.2
        l.LayoutOrder = order
        l.Visible = false
        return l
    end
    
    Visuals.Gui = gui
    Visuals.Circle = circle
    Visuals.Stroke = stroke
    Visuals.Highlight = hl
    Visuals.ESP = esp
    Visuals.Labels = {
        Name = createLabel(1),
        Team = createLabel(2, nil, Color3.new(0.8, 0.8, 0.8)),
        Weapon = createLabel(3),
        Health = createLabel(4, Enum.Font.Code)
    }
end
InitVisuals()

local function IsVisible(part, char, config)
    if not config.WallCheck then return true end
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {LocalPlayer.Character, Camera, char, Visuals.Gui}
    p.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local res = raycast(Services.Workspace, origin, dir, p)
    return res == nil or res.Instance:IsDescendantOf(char)
end

local State = { Target = nil, Part = nil }

local function GetTarget(config)
    local bestT, bestP = nil, nil
    local bestPhys = math.huge
    local bestHealth = math.huge
    
    local mouse = (config.FOVBehavior == "Mouse") and get_mouse(Services.UserInputService) or (Camera.ViewportSize * 0.5)
    local maxDist = config.MaxDistance
    local priority = config.TargetPriority
    local camPos = Camera.CFrame.Position
    
    local tParts = config.TargetPart
    if type(tParts) ~= "table" or #tParts == 0 then tParts = {"Cabeça"} end

    local isRandom = false
    for i = 1, #tParts do if tParts[i] == "Aleatório" then isRandom = true break end end

    local wlUsers = {}
    if config.WhitelistedUsers then
        for i = 1, #config.WhitelistedUsers do wlUsers[config.WhitelistedUsers[i]] = true end
    end

    local wlTeams = {}
    if config.WhitelistedTeams then
        for i = 1, #config.WhitelistedTeams do wlTeams[config.WhitelistedTeams[i]] = true end
    end

    local fList = {}
    if config.FocusList then
        for i = 1, #config.FocusList do fList[config.FocusList[i]] = true end
    end

    local players = Services.Players:GetPlayers()
    for _, v in ipairs(players) do
        if v == LocalPlayer then continue end
        if config.TeamCheck == "Team" and v.Team == LocalPlayer.Team then continue end
        
        local vName = v.Name
        if wlUsers[vName] then continue end
        
        local vTeam = v.Team and v.Team.Name
        if vTeam and wlTeams[vTeam] then continue end
        if config.FocusMode and not fList[vName] then continue end
        
        local c = v.Character
        if not c then continue end
        
        local r = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChild("Humanoid")
        if not r or not h or h.Health <= 0 then continue end
        
        if (r.Position - camPos).Magnitude > maxDist then continue end
        
        local partsToCheck = {}
        if isRandom then
            local pList = {}
            for i = 1, #AllCategories do
                local mapped = PartMapping[AllCategories[i]]
                for j = 1, #mapped do
                    local p = c:FindFirstChild(mapped[j])
                    if p then table.insert(pList, p) end
                end
            end
            if #pList > 0 then
                table.insert(partsToCheck, pList[math.random(1, #pList)])
            end
        else
            for i = 1, #tParts do
                local mapped = PartMapping[tParts[i]]
                if mapped then
                    for j = 1, #mapped do
                        local p = c:FindFirstChild(mapped[j])
                        if p then table.insert(partsToCheck, p) end
                    end
                end
            end
        end
        
        if #partsToCheck == 0 then table.insert(partsToCheck, r) end
        
        for i = 1, #partsToCheck do
            local pObj = partsToCheck[i]
            local sPos, onScreen = wts(Camera, pObj.Position)
            
            if onScreen then
                local dist = (mouse - Vector2.new(sPos.X, sPos.Y)).Magnitude
                if dist <= config.FOVSize then
                    if IsVisible(pObj, c, config) then
                        local isCurrent = (State.Target == c)
                        local pPhysDist = (pObj.Position - camPos).Magnitude
                        local effectivePhys = isCurrent and (pPhysDist - 5) or pPhysDist

                        if priority == "Health" then
                            if h.Health < bestHealth or (h.Health == bestHealth and effectivePhys < bestPhys) then
                                bestHealth = h.Health
                                bestPhys = effectivePhys
                                bestT = c
                                bestP = pObj
                            end
                        else
                            if effectivePhys < bestPhys then
                                bestPhys = effectivePhys
                                bestT = c
                                bestP = pObj
                            end
                        end
                    end
                end
            end
        end
    end
    return bestT, bestP
end

local LastTargetTick = 0

Services.RunService.RenderStepped:Connect(function()
    local Config = getgenv().SilentConfig
    
    if not Config or not Config.Enabled then
        Visuals.Circle.Visible = false
        Visuals.Highlight.Enabled = false
        Visuals.ESP.Enabled = false
        State.Target = nil
        State.Part = nil
        return
    end

    if tick() - LastTargetTick >= 0.05 then
        State.Target, State.Part = GetTarget(Config)
        LastTargetTick = tick()
    end
    
    if Config.ShowFOV then
        Visuals.Circle.Visible = true
        Visuals.Circle.Size = UDim2.fromOffset(Config.FOVSize * 2, Config.FOVSize * 2)
        Visuals.Stroke.Color = Config.FOVColor
        local pos = (Config.FOVBehavior == "Mouse") and get_mouse(Services.UserInputService) or (Camera.ViewportSize * 0.5)
        Visuals.Circle.Position = UDim2.fromOffset(pos.X, pos.Y)
    else
        Visuals.Circle.Visible = false
    end
    
    if State.Target then
        local root = State.Target:FindFirstChild("HumanoidRootPart")
        
        if Config.ShowHighlight then
            Visuals.Highlight.Adornee = State.Target
            Visuals.Highlight.FillColor = Config.HighlightColor
            Visuals.Highlight.OutlineColor = Config.HighlightColor
            Visuals.Highlight.Enabled = true
        else
            Visuals.Highlight.Enabled = false
        end

        if Config.ESP.Enabled and root then
            Visuals.ESP.Adornee = root
            Visuals.ESP.Enabled = true
            
            local player = Services.Players:GetPlayerFromCharacter(State.Target)
            local hum = State.Target:FindFirstChild("Humanoid")
            
            if Config.ESP.ShowName then
                Visuals.Labels.Name.Text = player and player.Name or State.Target.Name
                Visuals.Labels.Name.Visible = true
            else
                Visuals.Labels.Name.Visible = false
            end
            
            if Config.ESP.ShowTeam then
                Visuals.Labels.Team.Text = (player and player.Team) and player.Team.Name or "Sem time"
                Visuals.Labels.Team.TextColor3 = (player and player.Team) and player.TeamColor.Color or Color3.new(0.8, 0.8, 0.8)
                Visuals.Labels.Team.Visible = true
            else
                Visuals.Labels.Team.Visible = false
            end
            
            if Config.ESP.ShowWeapon then
                local tool = State.Target:FindFirstChildWhichIsA("Tool")
                Visuals.Labels.Weapon.Text = tool and tool.Name or "Nada equipado"
                Visuals.Labels.Weapon.Visible = true
            else
                Visuals.Labels.Weapon.Visible = false
            end
            
            if Config.ESP.ShowHealth and hum then
                local h, max = math.floor(hum.Health), math.floor(hum.MaxHealth)
                Visuals.Labels.Health.Text = string.format("[%d / %d]", h, max)
                Visuals.Labels.Health.TextColor3 = Color3.fromHSV(math.clamp(h/max, 0, 1) * 0.3, 1, 1)
                Visuals.Labels.Health.Visible = true
            else
                Visuals.Labels.Health.Visible = false
            end
        else
            Visuals.ESP.Enabled = false
        end
    else
        Visuals.Highlight.Enabled = false
        Visuals.ESP.Enabled = false
    end
end)

local safe_remotes = {"UpdateMouse", "Look", "Camera", "Status", "Animation", "Heartbeat"}
local BulletKeywords = {
    "fire", "shoot", "bullet", "ammo", "projectile", "missile", "rocket", "hit", 
    "damage", "attack", "cast", "ray", "target", "server", "remote", "action", "mouse", "input", "create"
}

local CheckedSafe = setmetatable({}, {__mode = "k"})
local CheckedRemotes = setmetatable({}, {__mode = "k"})

local function is_safe(remote)
    if CheckedSafe[remote] ~= nil then return CheckedSafe[remote] end
    local ln = string.lower(remote.Name)
    for i = 1, #safe_remotes do
        if string.find(ln, string.lower(safe_remotes[i])) then 
            CheckedSafe[remote] = false
            return false 
        end
    end
    CheckedSafe[remote] = true
    return true
end

local function isBulletRemote(remote)
    if CheckedRemotes[remote] ~= nil then return CheckedRemotes[remote] end
    local n = string.lower(remote.Name)
    for i = 1, #BulletKeywords do
        if string.find(n, BulletKeywords[i]) then 
            CheckedRemotes[remote] = true
            return true 
        end
    end
    CheckedRemotes[remote] = false
    return false
end

local function getLegitOffset(config)
    if not config.UseLegitOffset then return Vector3.zero end
    return Vector3.new((math.random()-0.5)*0.5, (math.random()-0.5)*0.5, (math.random()-0.5)*0.5)
end

local mt = getrawmetatable(game)
local old_nc = mt.__namecall
setreadonly(mt, false)

local getnamecallmethod = getnamecallmethod
local checkcaller = checkcaller
local typeof = typeof
local unpack = unpack or table.unpack
local CFrame_new = CFrame.new

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if checkcaller() then return old_nc(self, ...) end

    local Config = getgenv().SilentConfig
    
    if Config and Config.Enabled and State.Part then
        if method ~= "FireServer" and method ~= "InvokeServer" and method ~= "Raycast" then
            return old_nc(self, ...)
        end

        if math.random(1, 100) <= Config.HitChance then
            if method == "Raycast" and self == Services.Workspace then
                local args = {...}
                local origin = args[1]
                local finalPos = State.Part.Position + getLegitOffset(Config)
                args[2] = (finalPos - origin).Unit * 10000 
                return old_nc(self, unpack(args))
            elseif isBulletRemote(self) then
                local args = {...}
                local finalPos = State.Part.Position + getLegitOffset(Config)
                local camPos = Camera.CFrame.Position
                local direction = (finalPos - camPos).Unit
                
                for i = 1, #args do
                    local v = args[i]
                    if typeof(v) == "Vector3" then
                        if v.Magnitude <= 10 then
                            args[i] = direction
                        else
                            args[i] = finalPos
                        end
                    elseif typeof(v) == "CFrame" then
                        args[i] = CFrame_new(camPos, finalPos)
                    end
                end
                return old_nc(self, unpack(args))
            end
        end
    end
    
    return old_nc(self, ...)
end)
setreadonly(mt, true)
