local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local GS = Replicated:WaitForChild("GunSystem")
local GC = GS:WaitForChild("GunsConfigurations")
local FireEvent = GS.Remotes.Events.Fire
local ReloadFunction = GS.Remotes.Functions.Reload

-- Objeto principal
local TevezLogic = {}
TevezLogic.ChatMessage = ""
TevezLogic.Spamming = false
TevezLogic.SelectedDevice = "Computer"
TevezLogic.SpoofEnabled = false
TevezLogic.SelectedShopItem = "GLOCK 18"
TevezLogic.Aura = false
TevezLogic.Active = true
TevezLogic.GunConfig = { Bullets = nil, Spread = nil, Range = nil }

-- Helper interno para notificações seguras
local function SendNotify(title, msg)
    if notificar then
        notificar(title .. ": " .. msg, 3, "lucide:info")
    end
end

-- Hook do Spoofer
local DeviceRemote = Replicated:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("Device")
local OldNameCall
OldNameCall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if self == DeviceRemote and method == "FireServer" and TevezLogic.SpoofEnabled then
        local args = {...}
        args[1] = TevezLogic.SelectedDevice 
        return OldNameCall(self, unpack(args))
    end
    return OldNameCall(self, ...)
end))

-- Funções do Chat/AFK
function TevezLogic.ToggleSpam(state)
    TevezLogic.Spamming = state
    if state then
        task.spawn(function()
            while TevezLogic.Spamming do
                Replicated.Assets.Remotes.ForceChat:FireServer(TevezLogic.ChatMessage)
                task.wait(0.1)
            end
        end)
    end
end

function TevezLogic.SendMessage()
    Replicated.Assets.Remotes.ForceChat:FireServer(TevezLogic.ChatMessage)
end

function TevezLogic.SetAFK(state)
    Replicated.Assets.Remotes.AFK:FireServer(state)
end

function TevezLogic.ToggleSpoof(state)
    TevezLogic.SpoofEnabled = state
    if state and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.Health = 0
    end
end

function TevezLogic.BuyItem()
    if not TevezLogic.SelectedShopItem then return end
    local args = { "Buy", TevezLogic.SelectedShopItem }
    Replicated.Assets.Remotes.ToolsShop:FireServer(unpack(args))
    SendNotify("Loja", "Comprado: " .. TevezLogic.SelectedShopItem)
end

-- Lógica de Armas
local function HasGun()
    local bp = Player:FindFirstChild("Backpack")
    local char = Player.Character
    for _, cfg in ipairs(GC:GetChildren()) do
        local n = cfg.Name
        if (bp and bp:FindFirstChild(n)) or (char and char:FindFirstChild(n)) then
            return true
        end
    end
    return false
end

local function GetGun()
    local c = Player.Character
    if not c then return nil end
    local tool = c:FindFirstChildWhichIsA("Tool")
    if not tool then return nil end
    local cfgInstance = GC:FindFirstChild(tool.Name)
    if not cfgInstance then return nil end
    local ok, moduleTable = pcall(function() return require(cfgInstance) end)
    if ok and type(moduleTable) == "table" then
        return moduleTable, tool.Name
    end
    return nil, tool.Name
end

local function ModifyGun(prop, val)
    local cfg, gunName = GetGun()
    if not cfg then return end
    if rawget(cfg, prop) ~= nil then
        rawset(cfg, prop, val)
    end
end

function TevezLogic.ApplyGunMods()
    if not HasGun() then
        SendNotify("Mods", "Equipe uma arma")
        return
    end
    if TevezLogic.GunConfig.Bullets then ModifyGun("Bullets", TevezLogic.GunConfig.Bullets) end
    if TevezLogic.GunConfig.Spread then ModifyGun("Spread", TevezLogic.GunConfig.Spread) end
    if TevezLogic.GunConfig.Range then ModifyGun("Range", TevezLogic.GunConfig.Range) end
    SendNotify("Mods", "Aplicado")
end

function TevezLogic.ToggleAura(state, toggleUI)
    if state then
        if not HasGun() then
            if toggleUI then toggleUI:Set(false) end
            SendNotify("Erro", "Precisa de uma arma")
            return
        end
        TevezLogic.Aura = true
        SendNotify("Kill-aura", "Ativado")
    else
        TevezLogic.Aura = false
        SendNotify("Kill-aura", "Desativado")
    end
end

-- Loops de Auto Reload e Aura
task.spawn(function()
    while task.wait(0.25) do
        if not TevezLogic.Active or not TevezLogic.Aura or not HasGun() then continue end
        local c = Player.Character
        if not c then continue end
        local tool = c:FindFirstChildWhichIsA("Tool")
        if not tool then continue end
        pcall(function() ReloadFunction:InvokeServer(tool) end)
    end
end)

task.spawn(function()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    while TevezLogic.Active do
        if TevezLogic.Aura and HasGun() and Player.Character then
            local c = Player.Character
            local tool = c:FindFirstChildWhichIsA("Tool")
            if tool then
                local cfgInstance = GC:FindFirstChild(tool.Name)
                if cfgInstance then
                    local firePart = tool:FindFirstChild("FirePart") or tool:FindFirstChild("Handle") or tool.PrimaryPart
                    if firePart then
                        rp.FilterDescendantsInstances = {Player.Character}
                        local target, dist = nil, math.huge
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= Player and plr.Team ~= Player.Team and plr.Character then
                                local h = plr.Character:FindFirstChildOfClass("Humanoid")
                                if h and h.Health > 0 then
                                    local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                                    if head then
                                        local d = (head.Position - firePart.Position).Magnitude
                                        if d < dist then
                                            dist = d
                                            target = head
                                        end
                                    end
                                end
                            end
                        end
                        if target then
                            local direction = target.Position - firePart.Position
                            local result = workspace:Raycast(firePart.Position, direction.Unit * direction.Magnitude, rp)
                            local hitPos = (result and result.Position) or target.Position
                            local info = {
                                [target] = {
                                    Normal = (result and result.Normal) or Vector3.new(0,1,0),
                                    Position = hitPos,
                                    Instance = target,
                                    Distance = direction.Magnitude,
                                    Material = (result and result.Material) or Enum.Material.ForceField
                                }
                            }
                            pcall(function() FireEvent:FireServer(tool, info, hitPos) end)
                        end
                    end
                end
            end
        end
        task.wait()
    end
end)

_G.TevezMods = TevezLogic
