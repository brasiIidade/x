local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer

local OriginalHRP = {}

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
    if char then
        local hl = char:FindFirstChild("HitboxHighlight")
        if hl then hl:Destroy() end
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
    
    if not Config.Enabled or plr == LocalPlayer or (plr.Team == LocalPlayer.Team and plr.Team ~= nil) then
        ResetHitbox(plr)
        return
    end

    if Config.HideOnShield and PlayerHasShield(plr) then
        ResetHitbox(plr)
        return
    end

    if Config.TeamFilterEnabled then
        local isTargetTeam = false
        if plr.Team then
            for _, teamName in pairs(Config.SelectedTeams) do
                if plr.Team.Name == teamName then
                    isTargetTeam = true
                    break
                end
            end
        end
        
        if not isTargetTeam then
            ResetHitbox(plr)
            return
        end
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

    local old = char:FindFirstChild("HitboxHighlight")
    if old then old:Destroy() end

    if Config.Transparency >= 1 then
        return
    end

    local hl = Instance.new("Highlight")
    hl.Name = "HitboxHighlight"
    hl.Parent = char
    hl.Adornee = char
    hl.FillColor = plr.TeamColor.Color
    hl.OutlineColor = Color3.new(1,1,1)
    hl.FillTransparency = Config.Transparency
    hl.OutlineTransparency = Config.Transparency
end

_G.RefreshHitbox = function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if _G.HitboxConfig.Enabled then
            ApplyHitbox(plr)
        else
            ResetHitbox(plr)
        end
    end
end

local function MonitorCharacter(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if _G.HitboxConfig.Enabled then
            ApplyHitbox(plr)
        else
            ResetHitbox(plr)
        end

        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and _G.HitboxConfig.Enabled then
                ApplyHitbox(plr)
            end
        end)

        char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") and _G.HitboxConfig.Enabled then
                ApplyHitbox(plr)
            end
        end)
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    MonitorCharacter(plr)
    if plr.Character then
        if _G.HitboxConfig.Enabled then
            ApplyHitbox(plr)
        else
            ResetHitbox(plr)
        end
        
        plr.Character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and _G.HitboxConfig.Enabled then
                ApplyHitbox(plr)
            end
        end)

        plr.Character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") and _G.HitboxConfig.Enabled then
                ApplyHitbox(plr)
            end
        end)
    end
end

Players.PlayerAdded:Connect(MonitorCharacter)
