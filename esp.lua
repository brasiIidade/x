local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = cloneref(Players.LocalPlayer)

_G.ESPConnections = _G.ESPConnections or {}
_G.ESPStorage = _G.ESPStorage or {}
_G.ESPHolder = nil

_G.ESPConfig = _G.ESPConfig or {
    Enabled = false,
    TeamCheck = false,
    Chams = false,
    Name = false,
    Studs = false,
    Health = false,
    WeaponN = false
}

local function GetHolder()
    if not _G.ESPHolder then
        local h = Instance.new("ScreenGui")
        h.Name = "MichigunVisuals"
        h.IgnoreGuiInset = true
        h.ResetOnSpawn = false
        
        local success = pcall(function()
            h.Parent = CoreGui
        end)
        
        if not success then
            h.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
        _G.ESPHolder = h
    end
    return _G.ESPHolder
end

local function MakeLabel(parent, order, color, size)
    local lab = Instance.new("TextLabel")
    lab.Parent = parent
    lab.BackgroundTransparency = 1
    lab.Size = UDim2.new(1, 0, 0, size or 12)
    lab.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lab.TextStrokeTransparency = 0.2
    lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lab.Font = Enum.Font.GothamBold
    lab.TextSize = size or 12
    lab.LayoutOrder = order
    lab.Visible = false
    return lab
end

local function CreateESP(plr)
    if plr.Name == LocalPlayer.Name or _G.ESPStorage[plr] then return end

    local Holder = GetHolder()
    
    local cache = {
        Highlight = nil,
        Billboard = nil,
        Labels = {}
    }

    local hl = Instance.new("Highlight")
    hl.Name = "Glow"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = Holder
    cache.Highlight = hl

    local bb = Instance.new("BillboardGui")
    bb.Name = "Tag"
    bb.Adornee = nil
    bb.Size = UDim2.new(0, 200, 0, 60)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    bb.Parent = Holder

    local layout = Instance.new("UIListLayout")
    layout.Parent = bb
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 0)

    cache.Labels.Name = MakeLabel(bb, 1, Color3.fromRGB(255, 255, 255), 13)
    cache.Labels.Health = MakeLabel(bb, 2, Color3.fromRGB(0, 255, 100), 11)
    cache.Labels.Weapon = MakeLabel(bb, 3, Color3.fromRGB(200, 200, 200), 11)
    cache.Labels.Studs = MakeLabel(bb, 4, Color3.fromRGB(255, 220, 0), 11)

    cache.Billboard = bb
    _G.ESPStorage[plr] = cache
end

local function RemoveESP(plr)
    local cache = _G.ESPStorage[plr]
    if cache then
        if cache.Highlight then cache.Highlight:Destroy() end
        if cache.Billboard then cache.Billboard:Destroy() end
        _G.ESPStorage[plr] = nil
    end
end

local function UpdateESP()
    for plr, cache in pairs(_G.ESPStorage) do
        local config = _G.ESPConfig
        
        if not plr or not plr.Parent then
            RemoveESP(plr)
            continue
        end

        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local head = char and char:FindFirstChild("Head")

        if not (char and hrp and hum and hum.Health > 0 and head) then
            cache.Highlight.Enabled = false
            cache.Billboard.Enabled = false
            continue
        end

        if config.TeamCheck and plr.TeamColor == LocalPlayer.TeamColor then
            cache.Highlight.Enabled = false
            cache.Billboard.Enabled = false
            continue
        end

        if config.Chams then
            cache.Highlight.Adornee = char
            cache.Highlight.FillColor = plr.TeamColor.Color
            cache.Highlight.Enabled = true
        else
            cache.Highlight.Enabled = false
        end

        local showInfo = (config.Name or config.Health or config.WeaponN or config.Studs)

        if showInfo then
            cache.Billboard.Adornee = head
            cache.Billboard.Enabled = true
            cache.Billboard.StudsOffset = Vector3.new(0, 2, 0)

            if config.Name then
                cache.Labels.Name.Text = plr.Name
                cache.Labels.Name.Visible = true
            else
                cache.Labels.Name.Visible = false
            end

            if config.Health then
                local hp = math.floor(hum.Health)
                cache.Labels.Health.Text = tostring(hp)
                cache.Labels.Health.TextColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(50, 255, 50), hp / hum.MaxHealth)
                cache.Labels.Health.Visible = true
            else
                cache.Labels.Health.Visible = false
            end

            if config.WeaponN then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    cache.Labels.Weapon.Text = tool.Name
                    cache.Labels.Weapon.Visible = true
                else
                    cache.Labels.Weapon.Visible = false
                end
            else
                cache.Labels.Weapon.Visible = false
            end

            if config.Studs then
                local dist = 0
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    dist = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                end
                cache.Labels.Studs.Text = string.format("[%d]", math.floor(dist))
                cache.Labels.Studs.Visible = true
            else
                cache.Labels.Studs.Visible = false
            end
        else
            cache.Billboard.Enabled = false
        end
    end
end

_G.StopESP = function()
    for _, conn in pairs(_G.ESPConnections) do
        conn:Disconnect()
    end
    _G.ESPConnections = {}

    for plr, _ in pairs(_G.ESPStorage) do
        RemoveESP(plr)
    end
    _G.ESPStorage = {}
    
    if _G.ESPHolder then
        _G.ESPHolder:Destroy()
        _G.ESPHolder = nil
    end
end

_G.StartESP = function()
    _G.StopESP()
    GetHolder() 

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name ~= LocalPlayer.Name then
            CreateESP(plr)
        end
    end

    local added = Players.PlayerAdded:Connect(CreateESP)
    local removed = Players.PlayerRemoving:Connect(RemoveESP)
    local loop = RunService.RenderStepped:Connect(UpdateESP)

    table.insert(_G.ESPConnections, added)
    table.insert(_G.ESPConnections, removed)
    table.insert(_G.ESPConnections, loop)
end
