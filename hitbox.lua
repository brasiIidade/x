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
local HttpService = cloneref(game:GetService("HttpService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local LocalPlayer = cloneref(Players.LocalPlayer)

_G.HitboxConnections = {}

_G.HitboxConfig = _G.HitboxConfig or {
    Size = Vector3.new(5,5,5),
    Transparency = 0.5,
    Shape = Enum.PartType.Ball,
    HideOnShield = false,
    TeamCheck = true,
    TeamFilterEnabled = false,
    SelectedTeams = {}
}

local OriginalHRP = {}
local PlayerHighlights = {}

local function SaveOriginal(plr, hrp)
    if not OriginalHRP[plr] then
        OriginalHRP[plr] = {
            Shape = hrp.Shape,
            Size = hrp.Size,
            Transparency = hrp.Transparency,
            CanCollide = hrp.CanCollide,
            Material = hrp.Material
        }
    end
end

local function ResetHitbox(plr)
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local data = OriginalHRP[plr]
    
    if hrp and data then
        hrp.Shape = data.Shape
        hrp.Size = data.Size
        hrp.Transparency = data.Transparency
        hrp.CanCollide = data.CanCollide
        hrp.Material = data.Material
    end
    
    if PlayerHighlights[plr] then
        PlayerHighlights[plr]:Destroy()
        PlayerHighlights[plr] = nil
    end
end

local function PlayerHasShield(plr)
    local char = plr.Character
    if not char then return false end
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") and string.find(string.lower(v.Name), "escudo") then
            return true
        end
    end
    return false
end

local function ApplyHitbox(plr)
    local Config = _G.HitboxConfig
    
    if plr.Name == LocalPlayer.Name then return end
    
    if Config.TeamCheck then
        if plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team.Name == LocalPlayer.Team.Name then 
            ResetHitbox(plr)
            return 
        end
    end

    if Config.HideOnShield and PlayerHasShield(plr) then
        ResetHitbox(plr)
        return 
    end

    if Config.TeamFilterEnabled then
        local isTargetTeam = false
        if plr.Team then
            for _, teamName in pairs(Config.SelectedTeams) do
                if plr.Team.Name == teamName then isTargetTeam = true; break end
            end
        end
        if not isTargetTeam then ResetHitbox(plr); return end
    end

    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    SaveOriginal(plr, hrp)

    hrp.Shape = Config.Shape
    hrp.Size = Config.Size
    hrp.Transparency = Config.Transparency
    hrp.CanCollide = false
    hrp.Material = Enum.Material.ForceField

    if PlayerHighlights[plr] then
        PlayerHighlights[plr]:Destroy()
        PlayerHighlights[plr] = nil
    end

    if Config.Transparency < 1 then
        local hl = Instance.new("Highlight")
        hl.Name = HttpService:GenerateGUID(false)
        hl.Adornee = char
        hl.FillColor = plr.TeamColor.Color
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = Config.Transparency
        hl.OutlineTransparency = Config.Transparency

        local success, target = pcall(function() return gethui() end)
        if success and target then
            hl.Parent = target
        else
            pcall(function() hl.Parent = CoreGui end)
        end

        PlayerHighlights[plr] = hl
    end
end

local function MonitorPlayer(plr)
    if plr.Character then 
        ApplyHitbox(plr)
        local c1 = plr.Character.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then ApplyHitbox(plr) end
        end)
        local c2 = plr.Character.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then ApplyHitbox(plr) end
        end)
        table.insert(_G.HitboxConnections, c1)
        table.insert(_G.HitboxConnections, c2)
    end

    local c3 = plr.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        ApplyHitbox(plr)
        local c4 = char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then ApplyHitbox(plr) end
        end)
        local c5 = char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then ApplyHitbox(plr) end
        end)
        table.insert(_G.HitboxConnections, c4)
        table.insert(_G.HitboxConnections, c5)
    end)
    table.insert(_G.HitboxConnections, c3)
end

_G.StopHitboxLogic = function()
    for _, conn in pairs(_G.HitboxConnections) do
        if conn then conn:Disconnect() end
    end
    _G.HitboxConnections = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        ResetHitbox(plr)
    end
end

_G.StartHitboxLogic = function()
    _G.StopHitboxLogic()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name ~= LocalPlayer.Name then
            MonitorPlayer(plr)
        end
    end

    local c = Players.PlayerAdded:Connect(function(plr)
        MonitorPlayer(plr)
    end)
    table.insert(_G.HitboxConnections, c)
end

_G.UpdateHitboxValues = function()
    if #_G.HitboxConnections > 0 then
        for _, plr in ipairs(Players:GetPlayers()) do
            ApplyHitbox(plr)
        end
    end
end
