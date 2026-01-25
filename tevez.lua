local cloneref = cloneref or function(o) return o end

local Replicated = cloneref(game:GetService("ReplicatedStorage"))
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local Player = Players.LocalPlayer

local function Notify(msg)
    if getgenv().notificar then 
        getgenv().notificar(msg, 3, "lucide:info")
    elseif _G.notificar then
        _G.notificar(msg, 3, "lucide:info")
    end
end

local TevezLogic = {}
TevezLogic.ChatMessage = ""
TevezLogic.Spamming = false
TevezLogic.SelectedDevice = "Computer"
TevezLogic.SpoofEnabled = false
TevezLogic.SelectedShopItem = "GLOCK 18"
TevezLogic.Aura = false
TevezLogic.Active = true
TevezLogic.GunConfig = { Bullets = nil, Spread = nil, Range = nil }

local GS = Replicated:WaitForChild("GunSystem")
local GC = GS:WaitForChild("GunsConfigurations")
local FireEvent = GS.Remotes.Events.Fire
local ReloadFunction = GS.Remotes.Functions.Reload
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

function TevezLogic.ToggleSpam(state)
    TevezLogic.Spamming = state
    if state then
        task.spawn(function()
            while TevezLogic.Spamming do
                if TevezLogic.ChatMessage ~= "" then
                    Replicated.Assets.Remotes.ForceChat:FireServer(TevezLogic.ChatMessage)
                end
                task.wait(0.5)
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
    Notify("Comprado: " .. TevezLogic.SelectedShopItem)
end

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

local function ModifyGun(prop, val)
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "Bullets") and rawget(v, "Spread") and rawget(v, "Range") then
            rawset(v, prop, val)
        end
    end
end

function TevezLogic.ApplyGunMods()
    if not HasGun() then
        Notify("Equipe uma arma")
        return
    end
    if TevezLogic.GunConfig.Bullets then ModifyGun("Bullets", TevezLogic.GunConfig.Bullets) end
    if TevezLogic.GunConfig.Spread then ModifyGun("Spread", TevezLogic.GunConfig.Spread) end
    if TevezLogic.GunConfig.Range then ModifyGun("Range", TevezLogic.GunConfig.Range) end
    Notify("Aplicados")
end

function TevezLogic.ToggleAura(state, toggleUI)
    if state then
        if not HasGun() then
            if toggleUI then toggleUI:Set(false) end
            Notify("Precisa de uma arma")
            return
        end
        TevezLogic.Aura = true
        Notify("Ativado")
    else
        TevezLogic.Aura = false
        Notify("Desativado")
    end
end

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

local FarmLogic = {}
FarmLogic.Enabled = false
FarmLogic.SafeMode = false
FarmLogic.SafeRadius = 60
FarmLogic.MoneyFarmed = 0
FarmLogic.InitialMoney = 0
FarmLogic.UpdateCallback = nil

local Bank = Workspace.Map.Robbery.Bank
local StatusGui = Bank.RobberyStatus.SurfaceGui.BankStatus
local CollectPos = Bank.CollectPad.Position 
local Remotes = Replicated.Assets.Remotes
local BuyShop = Remotes.BuyShop
local Robbery = Remotes.Robbery
local Kaio = Workspace.Map.NPCS.Kaio
local VENDER_POS = Kaio.HumanoidRootPart.Position - Vector3.new(9, 10, 0) 
local AFK_LEFT_POS = CollectPos - Vector3.new(10, 0, 0)
local AFK_RIGHT_POS = CollectPos + Vector3.new(10, 0, 0)

local Running = false
local LastSell = 0
local MIN_MONEY = 1300

local function UpdateStatus(msg)
    if FarmLogic.UpdateCallback then
        FarmLogic.UpdateCallback(msg, FarmLogic.MoneyFarmed)
    end
end

local function IsOpen() return StatusGui.Text == "ABERTO" end
local function IsClosed() return StatusGui.Text == "FECHADO" end

local function Teleport(pos)
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character:PivotTo(CFrame.new(pos))
    end
end

local function GetItem(name)
    local bp = Player:FindFirstChild("Backpack")
    local char = Player.Character
    return (bp and bp:FindFirstChild(name)) or (char and char:FindFirstChild(name))
end

local function CheckSafe()
    if not FarmLogic.SafeMode then return false end
    if not Player.Character then return false end
    local root = Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - root.Position).Magnitude <= FarmLogic.SafeRadius then
                UpdateStatus("Jogador perto. Aguardando...")
                Teleport(AFK_LEFT_POS + Vector3.new(0, 4, 0))
                return true
            end
        end
    end
    return false
end

local function DynamicWait(seconds)
    local start = tick()
    while FarmLogic.Enabled and IsOpen() and (tick() - start < seconds) do
        if CheckSafe() then
            task.wait(0.5)
            continue
        end
        Teleport(AFK_LEFT_POS + Vector3.new(0, 4, 0))
        task.wait(0.02)
        Teleport(AFK_RIGHT_POS + Vector3.new(0, 4, 0))
        task.wait(0.02)
    end
    return (not IsOpen() or not FarmLogic.Enabled)
end

local function BuyC4()
    if GetItem("C4") then return true end
    UpdateStatus("Comprando C4...")
    Teleport(Vector3.new(-766, 19, -365))
    task.wait(1)
    BuyShop:FireServer("C4")
    for i = 1, 15 do
        if GetItem("C4") then return true end
        task.wait(0.1)
    end
    return false
end

local function GetMoneyBag()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "Money Bag" then
            local h = v:FindFirstChildWhichIsA("BasePart")
            if h then
                local att = h:FindFirstChild("DataAttachment")
                if att then
                    local gui = att:FindFirstChild("BillboardGui")
                    if gui and gui.Frame:FindFirstChild("Money") then
                        return tonumber(gui.Frame.Money.Text:match("%d+")) or 0
                    end
                end
            end
        end
    end
    return 0
end

local function SellMoney(force)
    UpdateStatus("Entregando dinheiro...")
    if not force and (CheckSafe() or IsClosed()) then return end
    
    Teleport(VENDER_POS)
    task.wait(0.5)
    
    while GetMoneyBag() > 0 and FarmLogic.Enabled do
        if CheckSafe() then break end
        if not force and IsClosed() then break end
        Robbery:FireServer("Payment")
        task.wait(1)
    end
    
    if not FarmLogic.Enabled then return end
    task.wait(0.5)
    Teleport(CollectPos)
    
    if Player.leaderstats and Player.leaderstats:FindFirstChild("Dinheiro") then
        FarmLogic.MoneyFarmed = Player.leaderstats.Dinheiro.Value - FarmLogic.InitialMoney
    end
    UpdateStatus("Dinheiro entregue!")
end

local function MainLoop()
    if Running or not FarmLogic.Enabled then return end
    
    if Player.leaderstats.Dinheiro.Value < MIN_MONEY then
        UpdateStatus("Erro: Precisa de R$" .. MIN_MONEY)
        FarmLogic.Enabled = false
        return
    end

    Running = true
    FarmLogic.InitialMoney = Player.leaderstats.Dinheiro.Value

    task.spawn(function()
        if not IsOpen() then
            UpdateStatus("Aguardando banco abrir...")
            repeat task.wait(0.5) until IsOpen() or not FarmLogic.Enabled
            if not FarmLogic.Enabled then Running = false return end
        end

        UpdateStatus("Iniciando rotina...")
        
        if not BuyC4() or not FarmLogic.Enabled or IsClosed() then
            UpdateStatus("Falha ao comprar C4")
            Running = false
            return
        end

        local c4 = GetItem("C4")
        if c4 then Player.Character.Humanoid:EquipTool(c4) end

        local prompt = Bank.BankVault.C4.Handle:FindFirstChildOfClass("ProximityPrompt")
        Teleport(Bank.BankVault.Vault.Front.Position)
        task.wait(0.5)

        UpdateStatus("Plantando C4...")
        while FarmLogic.Enabled and IsOpen() do
            if CheckSafe() then task.wait(0.1) continue end
            if not GetItem("C4") then break end
            fireproximityprompt(prompt)
            task.wait(0.15)
        end

        if not FarmLogic.Enabled or IsClosed() then Running = false return end
        
        DynamicWait(11)

        while FarmLogic.Enabled and IsOpen() do
            if CheckSafe() then task.wait(0.1) continue end
            
            if GetMoneyBag() >= 4000 then
                task.wait(8)
                SellMoney(false)
                if not IsOpen() then break end
            else
                UpdateStatus("Coletando...")
                Teleport(CollectPos)
                task.wait(0.05)
                if Player.Character.Humanoid.Health < 50 then
                   UpdateStatus("Curando...")
                   Teleport(AFK_LEFT_POS + Vector3.new(0,4,0))
                   repeat task.wait(0.5) until Player.Character.Humanoid.Health > 90
                end
                
                if Player.Character then
                    Player.Character:PivotTo(Player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(30), 0))
                end
                
                DynamicWait(0.5)
            end
        end
        Running = false
    end)
end

function FarmLogic.Toggle(state)
    FarmLogic.Enabled = state
    if state then
        MainLoop()
    else
        Running = false
        UpdateStatus("Desativado")
    end
end

StatusGui:GetPropertyChangedSignal("Text"):Connect(function()
    if not FarmLogic.Enabled then return end
    if IsOpen() then
        MainLoop()
    elseif IsClosed() then
        if tick() - LastSell > 5 then
            LastSell = tick()
            task.spawn(function()
                if GetMoneyBag() > 0 then SellMoney(true) end
            end)
        end
        Running = false
    end
end)

Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if FarmLogic.Enabled and IsOpen() then
        MainLoop()
    end
    char:WaitForChild("Humanoid").Died:Connect(function()
        Running = false
        if FarmLogic.Enabled then
            task.wait(3)
            Teleport(CollectPos)
        end
    end)
end)

_G.TevezMods = TevezLogic
_G.TevezAutoFarm = FarmLogic
