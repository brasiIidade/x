local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

local FarmLogic = {}
FarmLogic.Enabled = false
FarmLogic.SafeMode = false
FarmLogic.SafeRadius = 60
FarmLogic.MoneyFarmed = 0
FarmLogic.InitialMoney = 0
FarmLogic.StatusText = "Inativo"
FarmLogic.UpdateCallback = nil -- Função que a UI vai definir para atualizar o texto

-- Referências
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

-- Funções Auxiliares
local function Notify(msg)
    if getgenv().notificar then getgenv().notificar(msg, 3, "lucide:info") end
end

local function UpdateStatus(msg)
    FarmLogic.StatusText = msg
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
                UpdateStatus("Modo Seguro: Jogador perto!")
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
        
        DynamicWait(11) -- Espera explosão

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
                
                -- Anti-AFK spin visual
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

-- Listeners
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

_G.TevezAutoFarm = FarmLogic
