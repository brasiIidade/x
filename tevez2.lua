local cr = cloneref or function(o) return o end
local Services = {
    Players = cr(game:GetService("Players")),
    Replicated = cr(game:GetService("ReplicatedStorage")),
    Workspace = cr(game:GetService("Workspace")),
    RunService = cr(game:GetService("RunService")),
    HttpService = cr(game:GetService("HttpService"))
}

local LP = Services.Players.LocalPlayer
local Mouse = LP:GetMouse()

getgenv().TevezHub = {
    Config = {
        ChatMsg = "",
        Spamming = false,
        Device = "Computer",
        Spoofing = false,
        ShopItem = "GLOCK 18",
        Aura = false,
        GunData = { Bullets = nil, Spread = nil, Range = nil },
        Farm = {
            Enabled = false,
            SafeMode = false,
            SafeRadius = 60,
            Money = 0
        }
    },
    Functions = {},
    Events = {}
}

local Hub = getgenv().TevezHub
local Remotes = Services.Replicated:WaitForChild("Assets"):WaitForChild("Remotes")
local GunSystem = Services.Replicated:WaitForChild("GunSystem")
local GunConfigs = GunSystem:WaitForChild("GunsConfigurations")

local function Notify(msg)
    if getgenv().notificar then
        getgenv().notificar(msg, 3, "lucide:info")
    end
end

local OldNC
OldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Method = getnamecallmethod()
    if self == Remotes.Device and Method == "FireServer" and Hub.Config.Spoofing then
        return OldNC(self, Hub.Config.Device)
    end
    return OldNC(self, ...)
end))

Hub.Functions.ToggleSpam = function(state)
    Hub.Config.Spamming = state
    if state then
        task.spawn(function()
            while Hub.Config.Spamming do
                if Hub.Config.ChatMsg ~= "" then
                    Remotes.ForceChat:FireServer(Hub.Config.ChatMsg)
                end
                task.wait(0.5)
            end
        end)
    end
end

Hub.Functions.SendMessage = function()
    Remotes.ForceChat:FireServer(Hub.Config.ChatMsg)
end

Hub.Functions.SetAFK = function(state)
    Remotes.AFK:FireServer(state)
end

Hub.Functions.ToggleSpoof = function(state)
    Hub.Config.Spoofing = state
    if state and LP.Character then
        local Hum = LP.Character:FindFirstChild("Humanoid")
        if Hum then Hum.Health = 0 end
    end
end

Hub.Functions.BuyItem = function()
    if not Hub.Config.ShopItem then return end
    Remotes.ToolsShop:FireServer("Buy", Hub.Config.ShopItem)
    Notify("Comprado: " .. Hub.Config.ShopItem)
end

local function GetGun()
    local BP = LP:FindFirstChild("Backpack")
    local Char = LP.Character
    for _, V in ipairs(GunConfigs:GetChildren()) do
        if (BP and BP:FindFirstChild(V.Name)) or (Char and Char:FindFirstChild(V.Name)) then
            return true
        end
    end
    return false
end

Hub.Functions.ApplyMods = function()
    if not GetGun() then return Notify("Equipe uma arma") end
    local Count = 0
    local Cfg = Hub.Config.GunData
    
    for _, V in pairs(getgc(true)) do
        if type(V) == "table" and (rawget(V, "Spread") or rawget(V, "Bullets")) then
            if setreadonly then setreadonly(V, false) end
            if Cfg.Bullets and rawget(V, "Bullets") then rawset(V, "Bullets", Cfg.Bullets) Count = Count + 1 end
            if Cfg.Spread and rawget(V, "Spread") then rawset(V, "Spread", Cfg.Spread) Count = Count + 1 end
            if Cfg.Range and rawget(V, "Range") then rawset(V, "Range", Cfg.Range) Count = Count + 1 end
        end
    end
    Notify("Mods aplicados: " .. Count)
end

task.spawn(function()
    while task.wait(0.25) do
        if Hub.Config.Aura and GetGun() and LP.Character then
            local Tool = LP.Character:FindFirstChildWhichIsA("Tool")
            if Tool then
                pcall(function() GunSystem.Remotes.Functions.Reload:InvokeServer(Tool) end)
            end
        end
    end
end)

task.spawn(function()
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    
    while true do
        if Hub.Config.Aura and GetGun() and LP.Character then
            local Char = LP.Character
            local Tool = Char:FindFirstChildWhichIsA("Tool")
            
            if Tool and GunConfigs:FindFirstChild(Tool.Name) then
                local FirePart = Tool:FindFirstChild("FirePart") or Tool:FindFirstChild("Handle")
                
                if FirePart then
                    Params.FilterDescendantsInstances = {Char}
                    local Target, Closest = nil, math.huge
                    
                    for _, P in ipairs(Services.Players:GetPlayers()) do
                        if P ~= LP and P.Team ~= LP.Team and P.Character then
                            local Root = P.Character:FindFirstChild("HumanoidRootPart")
                            local Hum = P.Character:FindFirstChild("Humanoid")
                            if Root and Hum and Hum.Health > 0 then
                                local Dist = (Root.Position - FirePart.Position).Magnitude
                                if Dist < Closest then
                                    Closest = Dist
                                    Target = Root
                                end
                            end
                        end
                    end
                    
                    if Target then
                        local Dir = Target.Position - FirePart.Position
                        local Res = Services.Workspace:Raycast(FirePart.Position, Dir.Unit * Dir.Magnitude, Params)
                        local HitPos = (Res and Res.Position) or Target.Position
                        
                        local Info = {
                            [Target] = {
                                Normal = (Res and Res.Normal) or Vector3.yAxis,
                                Position = HitPos,
                                Instance = Target,
                                Distance = Dir.Magnitude,
                                Material = (Res and Res.Material) or Enum.Material.ForceField
                            }
                        }
                        pcall(function() GunSystem.Remotes.Events.Fire:FireServer(Tool, Info, HitPos) end)
                    end
                end
            end
        end
        task.wait()
    end
end)

local Farm = {
    Running = false,
    LastSell = 0,
    Objects = {
        Bank = Services.Workspace.Map.Robbery.Bank,
        NPC = Services.Workspace.Map.NPCS.Kaio
    }
}

local function UpdateFarmStatus(msg)
    if Hub.Events.UpdateStatus then
        Hub.Events.UpdateStatus(msg, Hub.Config.Farm.Money)
    end
end

local function TP(pos)
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character:PivotTo(CFrame.new(pos))
    end
end

local function GetInv(name)
    local BP = LP:FindFirstChild("Backpack")
    local Char = LP.Character
    return (BP and BP:FindFirstChild(name)) or (Char and Char:FindFirstChild(name))
end

local function IsSafe()
    if not Hub.Config.Farm.SafeMode or not LP.Character then return false end
    local Root = LP.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return false end
    
    for _, P in ipairs(Services.Players:GetPlayers()) do
        if P ~= LP and P.Character then
            local ERoot = P.Character:FindFirstChild("HumanoidRootPart")
            if ERoot and (ERoot.Position - Root.Position).Magnitude <= Hub.Config.Farm.SafeRadius then
                UpdateFarmStatus("Segurança: Jogador detectado!")
                TP(Farm.Objects.Bank.CollectPad.Position - Vector3.new(10, -4, 0))
                return true
            end
        end
    end
    return false
end

local function FarmWait(sec)
    local Start = tick()
    local Pad = Farm.Objects.Bank.CollectPad.Position
    while Hub.Config.Farm.Enabled and Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "ABERTO" and (tick() - Start < sec) do
        if IsSafe() then task.wait(0.5) continue end
        TP(Pad - Vector3.new(10, -4, 0))
        task.wait(0.02)
        TP(Pad + Vector3.new(10, 4, 0))
        task.wait(0.02)
    end
    return (Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text ~= "ABERTO" or not Hub.Config.Farm.Enabled)
end

local function BuyC4()
    if GetInv("C4") then return true end
    UpdateFarmStatus("Comprando C4...")
    TP(Vector3.new(-766, 19, -365))
    task.wait(1)
    Remotes.BuyShop:FireServer("C4")
    for _ = 1, 15 do
        if GetInv("C4") then return true end
        task.wait(0.1)
    end
    return false
end

local function GetBag()
    for _, V in ipairs(Services.Workspace:GetDescendants()) do
        if V.Name == "Money Bag" then
            local Gui = V:FindFirstChild("DataAttachment") and V.DataAttachment:FindFirstChild("BillboardGui")
            if Gui and Gui.Frame:FindFirstChild("Money") then
                return tonumber(Gui.Frame.Money.Text:match("%d+")) or 0
            end
        end
    end
    return 0
end

local function Sell(force)
    UpdateFarmStatus("Vendendo...")
    if not force and (IsSafe() or Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "FECHADO") then return end
    
    TP(Farm.Objects.NPC.HumanoidRootPart.Position - Vector3.new(9, 10, 0))
    task.wait(0.5)
    
    while GetBag() > 0 and Hub.Config.Farm.Enabled do
        if IsSafe() then break end
        if not force and Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "FECHADO" then break end
        Remotes.Robbery:FireServer("Payment")
        task.wait(1)
    end
    
    if not Hub.Config.Farm.Enabled then return end
    task.wait(0.5)
    TP(Farm.Objects.Bank.CollectPad.Position)
    
    if LP.leaderstats and LP.leaderstats:FindFirstChild("Dinheiro") then
        Hub.Config.Farm.Money = LP.leaderstats.Dinheiro.Value
    end
    UpdateFarmStatus("Vendido!")
end

local function Loop()
    if Farm.Running or not Hub.Config.Farm.Enabled then return end
    if LP.leaderstats.Dinheiro.Value < 1300 then
        UpdateFarmStatus("Erro: Requer R$1300")
        Hub.Config.Farm.Enabled = false
        return
    end
    
    Farm.Running = true
    
    task.spawn(function()
        if Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text ~= "ABERTO" then
            UpdateFarmStatus("Aguardando Banco...")
            repeat task.wait(0.5) until Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "ABERTO" or not Hub.Config.Farm.Enabled
            if not Hub.Config.Farm.Enabled then Farm.Running = false return end
        end
        
        UpdateFarmStatus("Iniciando...")
        if not BuyC4() or not Hub.Config.Farm.Enabled or Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "FECHADO" then
            UpdateFarmStatus("Erro C4")
            Farm.Running = false
            return
        end
        
        local C4 = GetInv("C4")
        if C4 then LP.Character.Humanoid:EquipTool(C4) end
        
        TP(Farm.Objects.Bank.BankVault.Vault.Front.Position)
        task.wait(0.5)
        UpdateFarmStatus("Plantando...")
        
        local Prompt = Farm.Objects.Bank.BankVault.C4.Handle:FindFirstChildOfClass("ProximityPrompt")
        while Hub.Config.Farm.Enabled and Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "ABERTO" do
            if IsSafe() then task.wait(0.1) continue end
            if not GetInv("C4") then break end
            fireproximityprompt(Prompt)
            task.wait(0.15)
        end
        
        if not Hub.Config.Farm.Enabled or Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "FECHADO" then Farm.Running = false return end
        
        FarmWait(11)
        
        while Hub.Config.Farm.Enabled and Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "ABERTO" do
            if IsSafe() then task.wait(0.1) continue end
            if GetBag() >= 4000 then
                task.wait(8)
                Sell(false)
                if Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text ~= "ABERTO" then break end
            else
                UpdateFarmStatus("Coletando...")
                TP(Farm.Objects.Bank.CollectPad.Position)
                task.wait(0.05)
                
                if LP.Character.Humanoid.Health < 50 then
                    UpdateFarmStatus("Curando...")
                    TP(Farm.Objects.Bank.CollectPad.Position - Vector3.new(10, -4, 0))
                    repeat task.wait(0.5) until LP.Character.Humanoid.Health > 90
                end
                
                if LP.Character then
                    LP.Character:PivotTo(LP.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(30), 0))
                end
                FarmWait(0.5)
            end
        end
        Farm.Running = false
    end)
end

Hub.Functions.ToggleFarm = function(state)
    Hub.Config.Farm.Enabled = state
    if state then
        Loop()
    else
        Farm.Running = false
        UpdateFarmStatus("Desativado")
    end
end

Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus:GetPropertyChangedSignal("Text"):Connect(function()
    if not Hub.Config.Farm.Enabled then return end
    if Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "ABERTO" then
        Loop()
    else
        if tick() - Farm.LastSell > 5 then
            Farm.LastSell = tick()
            task.spawn(function()
                if GetBag() > 0 then Sell(true) end
            end)
        end
        Farm.Running = false
    end
end)

LP.CharacterAdded:Connect(function(C)
    task.wait(1)
    if Hub.Config.Farm.Enabled and Farm.Objects.Bank.RobberyStatus.SurfaceGui.BankStatus.Text == "ABERTO" then
        Loop()
    end
    C:WaitForChild("Humanoid").Died:Connect(function()
        Farm.Running = false
        if Hub.Config.Farm.Enabled then
            task.wait(3)
            TP(Farm.Objects.Bank.CollectPad.Position)
        end
    end)
end)
