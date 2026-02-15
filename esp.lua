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

local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local LocalPlayer = cloneref(Players.LocalPlayer)

local ESPConnections = {}
local ESPStorage = {}
local ESPHolder = nil

local ESPConfig = {
    Enabled = false,
    TeamCheck = false,
    Chams = false,
    Name = false,
    Studs = false,
    Health = false,
    WeaponN = false
}

local function GetHolder()
    if not ESPHolder then
        local h = Instance.new("ScreenGui")
        h.Name = HttpService:GenerateGUID(false)
        h.IgnoreGuiInset = true
        h.ResetOnSpawn = false
        
        local success, target = pcall(function() return gethui() end)
        if success and target then
            h.Parent = target
        else
            pcall(function() h.Parent = CoreGui end)
        end
        ESPHolder = h
    end
    return ESPHolder
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
    if plr.Name == LocalPlayer.Name or ESPStorage[plr] then return end

    local Holder = GetHolder()
    
    local cache = {
        Highlight = nil,
        Billboard = nil,
        Labels = {}
    }

    local hl = Instance.new("Highlight")
    hl.Name = HttpService:GenerateGUID(false)
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = Holder
    cache.Highlight = hl

    local bb = Instance.new("BillboardGui")
    bb.Name = HttpService:GenerateGUID(false)
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
    ESPStorage[plr] = cache
end

local function RemoveESP(plr)
    local cache = ESPStorage[plr]
    if cache then
        if cache.Highlight then cache.Highlight:Destroy() end
        if cache.Billboard then cache.Billboard:Destroy() end
        ESPStorage[plr] = nil
    end
end

local function UpdateESP()
    for plr, cache in pairs(ESPStorage) do
        local config = ESPConfig
        
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

local function StopESP()
    for _, conn in pairs(ESPConnections) do
        conn:Disconnect()
    end
    table.clear(ESPConnections)

    for plr, _ in pairs(ESPStorage) do
        RemoveESP(plr)
    end
    table.clear(ESPStorage)
    
    if ESPHolder then
        ESPHolder:Destroy()
        ESPHolder = nil
    end
end

local function StartESP()
    StopESP()
    GetHolder() 

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name ~= LocalPlayer.Name then
            CreateESP(plr)
        end
    end

    local added = Players.PlayerAdded:Connect(CreateESP)
    local removed = Players.PlayerRemoving:Connect(RemoveESP)
    local loop = RunService.RenderStepped:Connect(UpdateESP)

    table.insert(ESPConnections, added)
    table.insert(ESPConnections, removed)
    table.insert(ESPConnections, loop)
end
