local cr = cloneref or function(o) return o end

local plrs = cr(game:GetService("Players"))
local rs = cr(game:GetService("RunService"))
local ws = cr(game:GetService("Workspace"))
local cg = cr(game:GetService("CoreGui"))
local tcs = cr(game:GetService("TextChatService"))
local rep = cr(game:GetService("ReplicatedStorage"))
local uis = cr(game:GetService("UserInputService"))
local ts  = cr(game:GetService("TweenService"))

local lp = plrs.LocalPlayer
local env = getgenv()

local function Notify(msg)
    if env.notificar then 
        env.notificar(msg, 3, "lucide:info")
    elseif _G.notificar then
        _G.notificar(msg, 3, "lucide:info")
    end
end

-- Tabela de IDs dos mapas
local Mapas = {
    [13132367906] = "Tevez",
    [14511049] = "Delta",
    [16150352] = "Christian",
    [129890257340707] = "Soucre",
    [134858056613772] = "NovaEra",
    [2069320852] = "Apex"
}

local MapaAtual = Mapas[game.PlaceId]

if MapaAtual then

    if MapaAtual == "Tevez" then
        -- [[ TEVEZ ]] --
        local TevezLogic = {}
        TevezLogic.ChatMessage = ""
        TevezLogic.Spamming = false
        TevezLogic.SelectedDevice = "Computer"
        TevezLogic.SpoofEnabled = false
        TevezLogic.SelectedShopItem = "GLOCK 18"
        TevezLogic.Aura = false
        TevezLogic.Active = true
        TevezLogic.GunConfig = { Bullets = nil, Spread = nil, Range = nil }

        local gs = rep:WaitForChild("GunSystem", 3)
        local gc, fireEvent, reloadFunc, deviceRemote
        if gs then
            gc = gs:WaitForChild("GunsConfigurations")
            fireEvent = gs:WaitForChild("Remotes"):WaitForChild("Events"):WaitForChild("Fire")
            reloadFunc = gs.Remotes:WaitForChild("Functions"):WaitForChild("Reload")
        end
        local ast = rep:WaitForChild("Assets", 3)
        if ast then
            local r = ast:WaitForChild("Remotes")
            deviceRemote = r:WaitForChild("Device")
        end

        local tevezOldNc
        tevezOldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if self == deviceRemote and method == "FireServer" and TevezLogic.SpoofEnabled then
                local args = {...}
                args[1] = TevezLogic.SelectedDevice 
                return tevezOldNc(self, unpack(args))
            end
            return tevezOldNc(self, ...)
        end))

        function TevezLogic.ToggleSpam(state)
            TevezLogic.Spamming = state
            if state then
                task.spawn(function()
                    while TevezLogic.Spamming do
                        if TevezLogic.ChatMessage ~= "" and ast then
                            ast.Remotes.ForceChat:FireServer(TevezLogic.ChatMessage)
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end

        function TevezLogic.SendMessage()
            if ast then ast.Remotes.ForceChat:FireServer(TevezLogic.ChatMessage) end
        end

        function TevezLogic.SetAFK(state)
            if ast then ast.Remotes.AFK:FireServer(state) end
        end

        function TevezLogic.ToggleSpoof(state)
            TevezLogic.SpoofEnabled = state
            if state and lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.Health = 0
            end
        end

        function TevezLogic.BuyItem()
            if not TevezLogic.SelectedShopItem or not ast then return end
            local args = { "Buy", TevezLogic.SelectedShopItem }
            ast.Remotes.ToolsShop:FireServer(unpack(args))
            Notify("Comprado: " .. TevezLogic.SelectedShopItem)
        end

        local function HasGun()
            if not gc then return false end
            local bp = lp:FindFirstChild("Backpack")
            local char = lp.Character
            for _, cfg in ipairs(gc:GetChildren()) do
                local n = cfg.Name
                if (bp and bp:FindFirstChild(n)) or (char and char:FindFirstChild(n)) then
                    return true
                end
            end
            return false
        end

        local function ModifyGunProp(prop, val)
            local count = 0
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    if rawget(v, "Spread") or rawget(v, "Bullets") or rawget(v, "FireRate") then
                        if setreadonly then setreadonly(v, false) end
                        if rawget(v, prop) ~= nil then
                            rawset(v, prop, val)
                            count = count + 1
                        end
                    end
                end
            end
            return count
        end

        function TevezLogic.ApplyGunMods()
            if not HasGun() then
                Notify("Equipe uma arma primeiro")
                return
            end
            local changes = 0
            if TevezLogic.GunConfig.Bullets then 
                changes = changes + ModifyGunProp("Bullets", TevezLogic.GunConfig.Bullets) 
            end
            if TevezLogic.GunConfig.Spread then 
                changes = changes + ModifyGunProp("Spread", TevezLogic.GunConfig.Spread) 
            end
            if TevezLogic.GunConfig.Range then 
                changes = changes + ModifyGunProp("Range", TevezLogic.GunConfig.Range) 
            end
            Notify("Alterações aplicadas em: " .. tostring(changes) .. " tabelas")
        end

        function TevezLogic.ToggleAura(state, toggleUI)
            if state then
                if not HasGun() then
                    if toggleUI then toggleUI:Set(false) end
                    Notify("Precisa de uma arma")
                    return
                end
                TevezLogic.Aura = true
                Notify("Kill-aura Ativado")
            else
                TevezLogic.Aura = false
                Notify("Kill-aura Desativado")
            end
        end

        task.spawn(function()
            while task.wait(0.25) do
                if not TevezLogic.Active or not TevezLogic.Aura or not HasGun() or not reloadFunc then continue end
                local c = lp.Character
                if not c then continue end
                local tool = c:FindFirstChildWhichIsA("Tool")
                if not tool then continue end
                pcall(function() reloadFunc:InvokeServer(tool) end)
            end
        end)

        task.spawn(function()
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            while TevezLogic.Active do
                if TevezLogic.Aura and HasGun() and lp.Character and fireEvent then
                    local c = lp.Character
                    local tool = c:FindFirstChildWhichIsA("Tool")
                    if tool then
                        local cfgInstance = gc:FindFirstChild(tool.Name)
                        if cfgInstance then
                            local firePart = tool:FindFirstChild("FirePart") or tool:FindFirstChild("Handle") or tool.PrimaryPart
                            if firePart then
                                rp.FilterDescendantsInstances = {lp.Character}
                                for _, plr in ipairs(plrs:GetPlayers()) do
                                    if plr ~= lp and (plr.Team == nil or plr.Team ~= lp.Team) and plr.Character then
                                        local h = plr.Character:FindFirstChildOfClass("Humanoid")
                                        if h and h.Health > 0 then
                                            local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                                            if head then
                                                local direction = head.Position - firePart.Position
                                                local dist = direction.Magnitude
                                                if dist > 0 then
                                                    local result = ws:Raycast(firePart.Position, direction.Unit * dist, rp)
                                                    local hitPos = (result and result.Position) or head.Position
                                                    local info = {
                                                        [head] = {
                                                            Normal = (result and result.Normal) or Vector3.new(0,1,0),
                                                            Position = hitPos,
                                                            Instance = head,
                                                            Distance = dist,
                                                            Material = (result and result.Material) or Enum.Material.ForceField
                                                        }
                                                    }
                                                    for i = 1, 15 do
                                                        pcall(function() fireEvent:FireServer(tool, info, hitPos) end)
                                                    end
                                                end
                                            end
                                        end
                                    end
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

        local bank = ws:FindFirstChild("Map") and ws.Map:FindFirstChild("Robbery") and ws.Map.Robbery:FindFirstChild("Bank")
        local statusGui = bank and bank:FindFirstChild("RobberyStatus") and bank.RobberyStatus:FindFirstChild("SurfaceGui") and bank.RobberyStatus.SurfaceGui:FindFirstChild("BankStatus")
        local collectPos = bank and bank:FindFirstChild("CollectPad") and bank.CollectPad.Position or Vector3.zero
        local buyShop = ast and ast.Remotes:FindFirstChild("BuyShop")
        local robbery = ast and ast.Remotes:FindFirstChild("Robbery")
        local kaio = ws:FindFirstChild("Map") and ws.Map:FindFirstChild("NPCS") and ws.Map.NPCS:FindFirstChild("Kaio")
        local venderPos = kaio and kaio:FindFirstChild("HumanoidRootPart") and (kaio.HumanoidRootPart.Position - Vector3.new(9, 10, 0)) or Vector3.zero
        local afkLeftPos = collectPos - Vector3.new(10, 0, 0)
        local afkRightPos = collectPos + Vector3.new(10, 0, 0)

        local farmRunning = false
        local lastSell = 0
        local MIN_MONEY = 1300

        local function UpdateFarmStatus(msg)
            if FarmLogic.UpdateCallback then
                FarmLogic.UpdateCallback(msg, FarmLogic.MoneyFarmed)
            end
        end

        local function IsOpen() return statusGui and statusGui.Text == "ABERTO" end
        local function IsClosed() return statusGui and statusGui.Text == "FECHADO" end

        local function Tp(pos)
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character:PivotTo(CFrame.new(pos))
            end
        end

        local function GetItem(name)
            local bp = lp:FindFirstChild("Backpack")
            local char = lp.Character
            return (bp and bp:FindFirstChild(name)) or (char and char:FindFirstChild(name))
        end

        local function CheckSafe()
            if not FarmLogic.SafeMode then return false end
            if not lp.Character then return false end
            local root = lp.Character:FindFirstChild("HumanoidRootPart")
            if not root then return false end
            for _, p in ipairs(plrs:GetPlayers()) do
                if p ~= lp and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - root.Position).Magnitude <= FarmLogic.SafeRadius then
                        UpdateFarmStatus("Modo Seguro: Jogador perto!")
                        Tp(afkLeftPos + Vector3.new(0, 4, 0))
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
                Tp(afkLeftPos + Vector3.new(0, 4, 0))
                task.wait(0.02)
                Tp(afkRightPos + Vector3.new(0, 4, 0))
                task.wait(0.02)
            end
            return (not IsOpen() or not FarmLogic.Enabled)
        end

        local function BuyC4()
            if GetItem("C4") then return true end
            if not buyShop then return false end
            UpdateFarmStatus("Comprando C4...")
            Tp(Vector3.new(-766, 19, -365))
            task.wait(1)
            buyShop:FireServer("C4")
            for i = 1, 15 do
                if GetItem("C4") then return true end
                task.wait(0.1)
            end
            return false
        end

        local function GetMoneyBag()
            local char = lp.Character
            if not char then return 0 end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return 0 end
            
            for _, v in ipairs(char:GetDescendants()) do
                if v.Name == "Money Bag" then
                    local h = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if h then
                        local att = h:FindFirstChild("DataAttachment")
                        if att then
                            local gui = att:FindFirstChild("BillboardGui")
                            if gui and gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("Money") then
                                return tonumber(gui.Frame.Money.Text:match("%d+")) or 0
                            end
                        end
                    end
                end
            end
            
            for _, v in ipairs(ws:GetDescendants()) do
                if v.Name == "Money Bag" then
                    local h = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if h and (h.Position - root.Position).Magnitude <= 10 then
                        local att = h:FindFirstChild("DataAttachment")
                        if att then
                            local gui = att:FindFirstChild("BillboardGui")
                            if gui and gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("Money") then
                                return tonumber(gui.Frame.Money.Text:match("%d+")) or 0
                            end
                        end
                    end
                end
            end
            
            return 0
        end

        local function SellMoney(force)
            if not robbery then return end
            UpdateFarmStatus("Entregando dinheiro...")
            if not force and (CheckSafe() or IsClosed()) then return end
            Tp(venderPos)
            task.wait(0.5)
            local attempts = 0
            while GetMoneyBag() > 0 and FarmLogic.Enabled do
                if CheckSafe() then break end
                if not force and IsClosed() then break end
                robbery:FireServer("Payment")
                task.wait(0.5)
                attempts = attempts + 1
                if attempts > 15 then break end
            end
            if not FarmLogic.Enabled then return end
            task.wait(0.5)
            if IsOpen() then Tp(collectPos) end
            if lp.leaderstats and lp.leaderstats:FindFirstChild("Dinheiro") then
                FarmLogic.MoneyFarmed = lp.leaderstats.Dinheiro.Value - FarmLogic.InitialMoney
            end
            UpdateFarmStatus("Dinheiro entregue!")
        end

        local function FarmMainLoop()
            if farmRunning or not FarmLogic.Enabled then return end
            if not lp.leaderstats or not lp.leaderstats:FindFirstChild("Dinheiro") then return end
            if lp.leaderstats.Dinheiro.Value < MIN_MONEY then
                UpdateFarmStatus("Erro: Precisa de R$" .. MIN_MONEY)
                FarmLogic.Enabled = false
                return
            end
            farmRunning = true
            FarmLogic.InitialMoney = lp.leaderstats.Dinheiro.Value
            task.spawn(function()
                if not IsOpen() then
                    UpdateFarmStatus("Aguardando banco abrir...")
                    repeat task.wait(0.5) until IsOpen() or not FarmLogic.Enabled
                    if not FarmLogic.Enabled then farmRunning = false return end
                end
                UpdateFarmStatus("Iniciando rotina...")
                if not BuyC4() or not FarmLogic.Enabled or IsClosed() then
                    UpdateFarmStatus("Falha ao comprar C4")
                    farmRunning = false
                    return
                end
                local c4 = GetItem("C4")
                if c4 then lp.Character.Humanoid:EquipTool(c4) end
                local prompt = bank and bank:FindFirstChild("BankVault") and bank.BankVault:FindFirstChild("C4") and bank.BankVault.C4:FindFirstChild("Handle") and bank.BankVault.C4.Handle:FindFirstChildOfClass("ProximityPrompt")
                if bank and bank:FindFirstChild("BankVault") and bank.BankVault:FindFirstChild("Vault") then
                    Tp(bank.BankVault.Vault.Front.Position)
                end
                task.wait(0.5)
                UpdateFarmStatus("Plantando C4...")
                while FarmLogic.Enabled and IsOpen() do
                    if CheckSafe() then task.wait(0.1) continue end
                    if not GetItem("C4") then break end
                    if prompt then fireproximityprompt(prompt) end
                    task.wait(0.15)
                end
                if not FarmLogic.Enabled or IsClosed() then farmRunning = false return end
                DynamicWait(11)
                while FarmLogic.Enabled and IsOpen() do
                    if CheckSafe() then task.wait(0.1) continue end
                    if GetMoneyBag() >= 4000 then
                        task.wait(8)
                        SellMoney(false)
                        if not IsOpen() then break end
                    else
                        UpdateFarmStatus("Coletando...")
                        Tp(collectPos)
                        task.wait(0.05)
                        if lp.Character.Humanoid.Health < 50 then
                        UpdateFarmStatus("Curando...")
                        Tp(afkLeftPos + Vector3.new(0,4,0))
                        repeat task.wait(0.5) until lp.Character.Humanoid.Health > 90
                        end
                        if lp.Character then
                            lp.Character:PivotTo(lp.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(30), 0))
                        end
                        DynamicWait(0.5)
                    end
                end
                farmRunning = false
            end)
        end

        function FarmLogic.Toggle(state)
            FarmLogic.Enabled = state
            if state then
                FarmMainLoop()
            else
                farmRunning = false
                UpdateFarmStatus("Desativado")
            end
        end

        if statusGui then
            statusGui:GetPropertyChangedSignal("Text"):Connect(function()
                if not FarmLogic.Enabled then return end
                if IsOpen() then
                    FarmMainLoop()
                elseif IsClosed() then
                    if tick() - lastSell > 5 then
                        lastSell = tick()
                        task.spawn(function()
                            if GetMoneyBag() > 0 then SellMoney(true) end
                        end)
                    end
                    farmRunning = false
                end
            end)
        end

        lp.CharacterAdded:Connect(function(char)
            task.wait(1)
            if FarmLogic.Enabled and IsOpen() then
                FarmMainLoop()
            end
            char:WaitForChild("Humanoid").Died:Connect(function()
                farmRunning = false
                if FarmLogic.Enabled then
                    task.wait(3)
                    Tp(collectPos)
                end
            end)
        end)

        env.TevezMods = TevezLogic
        env.TevezAutoFarm = FarmLogic
        _G.TevezMods = TevezLogic
        _G.TevezAutoFarm = FarmLogic

    elseif MapaAtual == "Delta" then
        -- [[ DELTA ]] --

local DeltaLogic = { JJValue = 0, GetRichValue = 1000000, KillAuraAtiva = false }
env.DeltaLogic = DeltaLogic

local dRem = rep:WaitForChild("Remotes", 3)
local dPoli, dDecM
if dRem then
    dPoli = dRem:WaitForChild("Polichinelos", 3)
    local dEvs = dRem:WaitForChild("Events", 3)
    if dEvs then
        local dEco = dEvs:WaitForChild("Economy", 3)
        if dEco then dDecM = dEco:WaitForChild("DecrementMoney", 3) end
    end
end

function DeltaLogic.SetJJ()
    if not dPoli then return end
    local n = tonumber(DeltaLogic.JJValue)
    if not n or n == 0 then return end
    dPoli:FireServer("Add", n)
    Notify(tostring(n) .. " polichinelos adicionados")
end

function DeltaLogic.GetRich()
    if not dDecM then return end
    local n = tonumber(DeltaLogic.GetRichValue)
    if not n or n == 0 then return end
    dDecM:FireServer(-n, "BuyMilitaryPass")
    Notify(tostring(n) .. " adicionado")
end

local bft = rep:WaitForChild("BFTEngine", 3)
local damageRemote, fxRemote
if bft then
    local pkgs = bft:WaitForChild("Packages", 3)
    if pkgs then
        local knit = pkgs:WaitForChild("Knit", 3)
        if knit then
            local svcs = knit:WaitForChild("Services", 3)
            if svcs then
                local bSvc = svcs:WaitForChild("BulletService", 3)
                if bSvc then
                    local re = bSvc:WaitForChild("RE", 3)
                    if re then
                        damageRemote = re:WaitForChild("Damage", 3)
                        fxRemote = re:WaitForChild("FX", 3)
                    end
                end
            end
        end
    end
end

local function obterArmaEquipada()
    local char = lp.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            return tool.Name
        end
    end
    return nil
end

local function alvoValido(plr)
    if plr == lp then return false end
    
    if plr.Team ~= nil and lp.Team ~= nil and plr.Team == lp.Team then 
        return false 
    end
    
    local char = plr.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    
    if hum and hum.Health > 0 and head then
        return true, head
    end
    
    return false
end

local ultimoTiro = 0

task.spawn(function()
    while task.wait() do
        if DeltaLogic.KillAuraAtiva and damageRemote and fxRemote then
            local armaNome = obterArmaEquipada()
            
            if armaNome then
                if tick() - ultimoTiro >= 0.1 then 
                    ultimoTiro = tick()
                    
                    for _, plr in ipairs(plrs:GetPlayers()) do
                        local valido, cabeca = alvoValido(plr)
                        
                        if valido then
                            pcall(function()
                                fxRemote:FireServer(armaNome, cabeca.Position)
                            end)
                            
                            pcall(function()
                                -- Argumentos passados direto, sem usar unpack()
                                damageRemote:FireServer(armaNome, cabeca.Position, cabeca)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

    elseif MapaAtual == "NovaEra" then
        -- [[ NOVA ERA ]] --
        local NovaEraLogic = {}
        NovaEraLogic.Enabled = false
        NovaEraLogic.Mode = "Lixeiro"
        NovaEraLogic.Farmed = 0
        NovaEraLogic.InitialMoney = 0
        NovaEraLogic.UpdateCallback = nil

        local neProfund = -20
        local neOff = CFrame.new(0, neProfund, 0)
        local neZero = Vector3.zero
        local neStartCF = nil

        local function getNeMoney()
            local ls = lp:FindFirstChild("leaderstats")
            local din = ls and ls:FindFirstChild("Dinheiro")
            if din then
                local val = tostring(din.Value or din.Text or "0")
                val = val:gsub("%D", "")
                return tonumber(val) or 0
            end
            return 0
        end

        local function neStopFloat()
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ag = hrp:FindFirstChild("Antigravity")
                if ag then ag:Destroy() end
            end
        end

        local function neFloatAt(targetCF)
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ag = hrp:FindFirstChild("Antigravity")
                if not ag then
                    ag = Instance.new("BodyVelocity")
                    ag.Name = "Antigravity"
                    ag.Velocity = neZero
                    ag.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    ag.P = 9000
                    ag.Parent = hrp
                end
                hrp.CFrame = targetCF
                hrp.AssemblyLinearVelocity = neZero
                hrp.AssemblyAngularVelocity = neZero
            end
        end

        local function neGetPrompt(parent)
            if not parent then return nil end
            for _, v in ipairs(parent:GetDescendants()) do
                if v:IsA("ProximityPrompt") and v.Enabled and v.Parent and v:IsDescendantOf(ws) then
                    return v
                end
            end
            return nil
        end

        function NovaEraLogic.SetMode(m)
            NovaEraLogic.Mode = m
        end

        function NovaEraLogic.Toggle(state)
            NovaEraLogic.Enabled = state
            local m = getNeMoney()

            if state then
                NovaEraLogic.InitialMoney = m
                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    neStartCF = hrp.CFrame
                end
            else
                neStopFloat()
                NovaEraLogic.Farmed = NovaEraLogic.Farmed + (m - NovaEraLogic.InitialMoney)
                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if neStartCF and hrp then
                    hrp.CFrame = neStartCF
                    hrp.AssemblyLinearVelocity = neZero
                end
            end
        end

        task.spawn(function()
            while task.wait(0.5) do
                if NovaEraLogic.UpdateCallback then
                    if NovaEraLogic.Enabled then
                        local cur = getNeMoney()
                        NovaEraLogic.UpdateCallback(NovaEraLogic.Farmed + (cur - NovaEraLogic.InitialMoney))
                    else
                        NovaEraLogic.UpdateCallback(NovaEraLogic.Farmed)
                    end
                end
            end
        end)

        task.spawn(function()
            while true do
                if NovaEraLogic.Enabled then
                    local char = lp.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if char and hum and hrp and hum.Health > 0 then
                        if NovaEraLogic.Mode == "Lixeiro" then
                            local trab = ws:FindFirstChild("Trabalhos / SWATntj")
                            local col = trab and trab:FindFirstChild("Coleta")
                            
                            if col then
                                local hasBag = char:FindFirstChild("Lixo_model") ~= nil
                                local targetFolder = hasBag and col:FindFirstChild("Lixeira") or col:FindFirstChild("Lixo")
                                local prompt = neGetPrompt(targetFolder)

                                if prompt and prompt.Parent then
                                    prompt.HoldDuration = 0
                                    repeat
                                        if not NovaEraLogic.Enabled or hum.Health <= 0 then break end
                                        if (char:FindFirstChild("Lixo_model") ~= nil) ~= hasBag then break end
                                        
                                        neFloatAt(prompt.Parent.CFrame * neOff)
                                        fireproximityprompt(prompt)
                                        task.wait(0.3)
                                    until not prompt.Parent or not prompt.Enabled
                                else
                                    if neStartCF then
                                        neFloatAt(neStartCF * neOff)
                                    else
                                        neStopFloat()
                                    end
                                    task.wait(0.1)
                                end
                            else
                                neStopFloat()
                                task.wait(0.5)
                            end
                        elseif NovaEraLogic.Mode == "Barbeiro" then
                            local shop = ws:FindFirstChild("BarberShop")
                            local found = false
                            
                            if shop then
                                for _, npc in ipairs(shop:GetChildren()) do
                                    if not NovaEraLogic.Enabled or hum.Health <= 0 then break end
                                    local head = npc:FindFirstChild("Head")
                                    local prompt = neGetPrompt(head)
                                    
                                    if prompt and prompt.Parent then
                                        found = true
                                        prompt.HoldDuration = 0
                                        local nextPrompt = 0
                                        
                                        repeat
                                            if not NovaEraLogic.Enabled or hum.Health <= 0 then break end
                                            
                                            hum.Sit = false
                                            neFloatAt(prompt.Parent.CFrame * neOff)
                                            
                                            if tick() >= nextPrompt then
                                                fireproximityprompt(prompt)
                                                nextPrompt = tick() + 0.3
                                            end
                                            
                                            rs.Heartbeat:Wait()
                                        until not prompt.Parent or not prompt.Enabled or not npc.Parent
                                    end
                                end
                            end
                            
                            if not found then
                                if neStartCF then
                                    neFloatAt(neStartCF * neOff)
                                else
                                    neStopFloat()
                                end
                                task.wait(0.1)
                            end
                        end
                    else
                        neStopFloat()
                        task.wait(0.5)
                    end
                else
                    neStopFloat()
                    task.wait(0.5)
                end
                if NovaEraLogic.Enabled then rs.Heartbeat:Wait() end
            end
        end)

        env.NovaEraLogic = NovaEraLogic

    elseif MapaAtual == "Soucre" then
        -- [[ SOUCRE ]] --
        local SoucreLogic = { Enabled = false, TotalProfit = 0, SessionStart = 0, UpdateCallback = nil }
        env.SoucreLogic = SoucreLogic

        local srcOff = CFrame.new(0, -9, 0)
        local srcSCf = nil
        local srcV0 = Vector3.zero

        local srcTrab = ws:FindFirstChild("Trabalhos") and ws.Trabalhos:FindFirstChild("Entregador")
        local srcPb, srcCp, srcFlds
        if srcTrab then
            srcPb = srcTrab:FindFirstChild("Prompts")
            if srcPb then
                srcCp = srcPb:FindFirstChild("Caixa")
                srcFlds = { srcPb:FindFirstChild("Entregar_B"), srcPb:FindFirstChild("Entregar_F"), srcPb:FindFirstChild("Frutas"), srcPb:FindFirstChild("Bebidas") }
            end
        end

        local function srcCGrav(c)
            if c then
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bv = hrp:FindFirstChild("AG")
                    if bv then bv:Destroy() end
                end
            end
        end

        local function srcTp(t)
            local c = lp.Character
            if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            if not hrp:FindFirstChild("AG") then
                local bv = Instance.new("BodyVelocity")
                bv.Name, bv.Velocity, bv.MaxForce, bv.P, bv.Parent = "AG", srcV0, Vector3.new(9e9, 9e9, 9e9), 9000, hrp
            end
            hrp.CFrame = t.CFrame * srcOff
            hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = srcV0, srcV0
        end

        local function srcFDst()
            if not srcFlds then return nil end
            for i = 1, 4 do
                if srcFlds[i] then
                    local att = srcFlds[i]:FindFirstChild("AttachmentDestino")
                    if att then return att end
                end
            end
            return nil
        end

        local function srcGMon()
            local d = lp:FindFirstChild("Dados")
            local m = d and d:FindFirstChild("Dinheiro")
            return m and m.Value or 0
        end

        function SoucreLogic.Toggle(s)
            SoucreLogic.Enabled = s
            local cur = srcGMon()
            
            if s then
                SoucreLogic.SessionStart = cur
                local c = lp.Character
                if c and c:FindFirstChild("HumanoidRootPart") then srcSCf = c.HumanoidRootPart.CFrame end
            else
                srcCGrav(lp.Character)
                SoucreLogic.TotalProfit = SoucreLogic.TotalProfit + (cur - SoucreLogic.SessionStart)
                local c = lp.Character
                if srcSCf and c and c:FindFirstChild("HumanoidRootPart") then
                    c.HumanoidRootPart.CFrame = srcSCf
                    c.HumanoidRootPart.AssemblyLinearVelocity = srcV0
                end
            end
        end

        rs.Heartbeat:Connect(function()
            if not SoucreLogic.UpdateCallback then return end
            if SoucreLogic.Enabled then
                SoucreLogic.UpdateCallback(SoucreLogic.TotalProfit + (srcGMon() - SoucreLogic.SessionStart))
            else
                SoucreLogic.UpdateCallback(SoucreLogic.TotalProfit)
            end
        end)

        rs.Heartbeat:Connect(function()
            if not SoucreLogic.Enabled then 
                srcCGrav(lp.Character) 
                return 
            end
            
            local c = lp.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") or not c:FindFirstChild("Humanoid") or c.Humanoid.Health <= 0 then
                srcCGrav(c)
                return
            end

            local att = srcFDst()
            if not att then
                if srcCp then
                    local p = srcCp:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then
                        p.HoldDuration = 0
                        srcTp(srcCp)
                        fireproximityprompt(p)
                    end
                end
            else
                local d = att.Parent
                if d then
                    local p = d:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then
                        p.HoldDuration = 0
                        srcTp(d)
                        fireproximityprompt(p)
                    end
                end
            end
        end)
        elseif MapaAtual == "Apex" then
        getgenv().ApexLogic            = getgenv().ApexLogic or {}
        getgenv()._ApexSpamMasterConns = getgenv()._ApexSpamMasterConns or {}
        getgenv()._ApexSpamCharConns   = getgenv()._ApexSpamCharConns or {}

        local function limparConns(tabela)
            for _, conn in ipairs(tabela) do
                if typeof(conn) == "RBXScriptConnection" and conn.Connected then
                    conn:Disconnect()
                end
            end
            table.clear(tabela)
        end

        -- invadir base
        do
            local routeConfig = {
                markerColor  = Color3.fromRGB(220, 50, 50),
                accentColor  = Color3.fromRGB(220, 50, 50),
                walkSpeed    = 0.3,
                stepDelay    = 0.28,
                triggerDist  = 1,
                triggerVert  = 1.5,
                triggerAngle = 10,
                startAt = CFrame.new(1635, 1, -105),
                enterAt = CFrame.new(1633, 1, -127) * CFrame.Angles(0, math.rad(90), 0),
                walkTo  = CFrame.new(1633, 1, -129.5),
                route = {
                    CFrame.new(1633, 1, -132),  CFrame.new(1633, 1, -135),
                    CFrame.new(1636, 1, -139),  CFrame.new(1640, 1, -145),
                    CFrame.new(1644, 1, -150),  CFrame.new(1648, 1, -155),
                    CFrame.new(1650, 1, -160),  CFrame.new(1650, 1, -165),
                    CFrame.new(1650, 1, -175),  CFrame.new(1650, 1, -185),
                    CFrame.new(1650, 1, -195),  CFrame.new(1650, 1, -205),
                    CFrame.new(1650, 1, -215),  CFrame.new(1650, 1, -225),
                    CFrame.new(1650, 1, -235),  CFrame.new(1650, 1, -245),
                    CFrame.new(1650, 1, -255),  CFrame.new(1650, 1, -265),
                    CFrame.new(1650, 1, -275),  CFrame.new(1635, 1, -286),
                }
            }

            local function toggleNoclip(state) getgenv().PlayerConfig.Noclip = state end

            local function getPlayer()
                local c = lp.Character
                return c, c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
            end

            local function newCorner(parent, scale)
                local c = Instance.new("UICorner", parent)
                c.CornerRadius = UDim.new(scale or 1, 0)
            end

            local function newStroke(parent, color, thick, transp)
                local s = Instance.new("UIStroke", parent)
                s.Color, s.Thickness, s.Transparency = color, thick or 1.5, transp or 0
            end

            local function buildClone(cf)
                local parts = {}
                local function addBox(name, size, frame)
                    local p = Instance.new("BoxHandleAdornment")
                    p.Size, p.Name, p.CFrame = size, name, frame
                    p.Color3, p.Transparency = routeConfig.markerColor, 0
                    p.Adornee, p.ZIndex, p.Parent = ws.Terrain, 1, ws.Terrain
                    table.insert(parts, p)
                end
                addBox("body", Vector3.new(2, 2, 1), cf)
                addBox("legL", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2,  0))
                addBox("legR", Vector3.new(1, 2, 1), cf * CFrame.new( 0.5, -2,  0))
                addBox("armL", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5,  0,  0))
                addBox("armR", Vector3.new(1, 2, 1), cf * CFrame.new( 1.5,  0.5, -1) * CFrame.Angles(math.rad(90), 0, 0))
                return function()
                    for _, p in ipairs(parts) do if p and p.Parent then p:Destroy() end end
                    parts = {}
                end
            end

            local function buildWaypoint()
                local guiRef = (gethui and gethui()) or cg
                local screen = Instance.new("ScreenGui")
                screen.Name, screen.ResetOnSpawn, screen.IgnoreGuiInset = ".", false, true
                screen.ZIndexBehavior, screen.Parent = Enum.ZIndexBehavior.Sibling, guiRef

                local wrap = Instance.new("Frame")
                wrap.Size, wrap.AnchorPoint, wrap.BackgroundTransparency = UDim2.new(0,44,0,62), Vector2.new(0.5,0.5), 1
                wrap.ZIndex, wrap.Parent = 10, screen

                local circle = Instance.new("Frame")
                circle.Size, circle.AnchorPoint = UDim2.new(0,32,0,32), Vector2.new(0.5,0)
                circle.Position, circle.BackgroundColor3 = UDim2.new(0.5,0,0,0), Color3.fromRGB(12,5,5)
                circle.BackgroundTransparency, circle.BorderSizePixel = 0.25, 0
                circle.ZIndex, circle.Parent = 10, wrap
                newCorner(circle) ; newStroke(circle, routeConfig.accentColor, 1.8)

                local arrow = Instance.new("TextLabel")
                arrow.Size, arrow.AnchorPoint, arrow.Position = UDim2.new(0,18,0,18), Vector2.new(0.5,0.5), UDim2.new(0.5,0,0.5,0)
                arrow.BackgroundTransparency, arrow.TextColor3 = 1, routeConfig.accentColor
                arrow.TextStrokeTransparency, arrow.TextStrokeColor3 = 0.2, Color3.fromRGB(0,0,0)
                arrow.TextScaled, arrow.Font, arrow.Text = true, Enum.Font.GothamBold, "▼"
                arrow.ZIndex, arrow.Parent = 11, circle

                local distBg = Instance.new("Frame")
                distBg.Size, distBg.AnchorPoint, distBg.Position = UDim2.new(0,44,0,18), Vector2.new(0.5,0), UDim2.new(0.5,0,1,5)
                distBg.BackgroundColor3, distBg.BackgroundTransparency, distBg.BorderSizePixel = Color3.fromRGB(10,4,4), 0.2, 0
                distBg.ZIndex, distBg.Parent = 10, wrap
                newCorner(distBg) ; newStroke(distBg, Color3.fromRGB(140,30,30), 1, 0.4)

                local distText = Instance.new("TextLabel")
                distText.Size, distText.BackgroundTransparency = UDim2.new(1,0,1,0), 1
                distText.TextColor3, distText.TextStrokeTransparency = Color3.fromRGB(220,180,180), 0.3
                distText.TextStrokeColor3, distText.Font = Color3.fromRGB(0,0,0), Enum.Font.GothamBold
                distText.TextSize, distText.ZIndex, distText.Parent = 11, 11, distBg

                local cam   = ws.CurrentCamera
                local EDGE  = 50
                local tick0 = tick()

                local loop = rs.Heartbeat:Connect(function()
                    local _, hrp = getPlayer()
                    if not hrp then return end
                    local vp = cam.ViewportSize
                    local cx, cy = vp.X/2, vp.Y/2
                    local target = routeConfig.startAt.Position + Vector3.new(0,3,0)
                    local meters = math.floor((hrp.Position - routeConfig.startAt.Position).Magnitude)
                    distText.Text = meters .. "m"

                    local camCF   = cam.CFrame
                    local dir     = (target - camCF.Position)
                    local forward = camCF.LookVector
                    local onScreen = forward:Dot(dir.Unit) > 0

                    local sp = cam:WorldToScreenPoint(target)
                    local sx, sy = sp.X, sp.Y

                    local dx, dy = sx - cx, sy - cy

                    if onScreen and sx > EDGE and sx < vp.X-EDGE and sy > EDGE and sy < vp.Y-EDGE then
                        wrap.Rotation = 0
                        wrap.Position = UDim2.fromOffset(sx, sy - 10)
                    else
                        if not onScreen then
                            dx, dy = -dx, -dy
                            if math.abs(dx) < 1 and math.abs(dy) < 1 then dx = 1 end
                        end
                        local sc = math.min(
                            (cx - EDGE) / (math.abs(dx) + 1e-4),
                            (cy - EDGE) / (math.abs(dy) + 1e-4)
                        )
                        wrap.Rotation = math.deg(math.atan2(dx, -dy))
                        wrap.Position = UDim2.fromOffset(cx + dx*sc, cy + dy*sc)
                    end

                    local sz = math.floor(32*(1+math.sin((tick()-tick0)*3.5)*0.06))
                    circle.Size = UDim2.new(0,sz,0,sz)
                    distText.TextColor3 = (meters<12 and tick()%0.5<0.25) and Color3.fromRGB(255,80,80) or Color3.fromRGB(220,180,180)
                end)

                return function()
                    loop:Disconnect()
                    if screen and screen.Parent then screen:Destroy() end
                end
            end

            local function buildLoadScreen(totalSteps)
                local guiRef = (gethui and gethui()) or cg
                local screen = Instance.new("ScreenGui")
                screen.Name, screen.ResetOnSpawn, screen.IgnoreGuiInset = tostring(math.random(1e8,9e8)), false, true
                screen.DisplayOrder, screen.Parent = 2147483647, guiRef

                local bg = Instance.new("Frame")
                bg.Size, bg.Position = UDim2.new(1,0,1,0), UDim2.new(0,0,0,0)
                bg.BackgroundColor3, bg.BackgroundTransparency, bg.BorderSizePixel = Color3.fromRGB(5,5,8), 1, 0
                bg.ZIndex, bg.Parent = 9999, screen

                local logo = Instance.new("ImageLabel")
                logo.Size, logo.AnchorPoint, logo.Position = UDim2.new(0,180,0,180), Vector2.new(0.5,0.5), UDim2.new(0.5,0,0.5,-60)
                logo.BackgroundTransparency, logo.ImageTransparency = 1, 1
                logo.Image, logo.ZIndex, logo.Parent = "rbxassetid://137064182739714", 10000, bg

                local titleText = Instance.new("TextLabel")
                titleText.Size, titleText.AnchorPoint, titleText.Position = UDim2.new(0,300,0,32), Vector2.new(0.5,0), UDim2.new(0.5,0,0.5,56)
                titleText.BackgroundTransparency, titleText.TextColor3 = 1, Color3.fromRGB(220,220,220)
                titleText.TextTransparency, titleText.TextStrokeTransparency = 1, 1
                titleText.TextStrokeColor3, titleText.Font = Color3.fromRGB(0,0,0), Enum.Font.GothamBold
                titleText.TextSize, titleText.Text, titleText.ZIndex, titleText.Parent = 16, "Feito por @fp3", 10000, bg

                local subText = Instance.new("TextLabel")
                subText.Size, subText.AnchorPoint, subText.Position = UDim2.new(0,300,0,18), Vector2.new(0.5,0), UDim2.new(0.5,0,0.5,92)
                subText.BackgroundTransparency, subText.TextColor3 = 1, Color3.fromRGB(100,35,35)
                subText.TextTransparency, subText.TextStrokeTransparency = 1, 1
                subText.Font, subText.TextSize = Enum.Font.Gotham, 11
                subText.Text, subText.ZIndex, subText.Parent = "vai se fuder larih <3", 10000, bg

                local track = Instance.new("Frame")
                track.Size, track.AnchorPoint, track.Position = UDim2.new(0,260,0,4), Vector2.new(0.5,0), UDim2.new(0.5,0,0.5,120)
                track.BackgroundColor3, track.BackgroundTransparency, track.BorderSizePixel = Color3.fromRGB(28,10,10), 1, 0
                track.ZIndex, track.Parent = 10000, bg ; newCorner(track)

                local fill = Instance.new("Frame")
                fill.Size, fill.BackgroundColor3, fill.BackgroundTransparency, fill.BorderSizePixel = UDim2.new(0,0,1,0), Color3.fromRGB(200,40,40), 1, 0
                fill.ZIndex, fill.Parent = 10001, track ; newCorner(fill)

                local dot = Instance.new("Frame")
                dot.Size, dot.AnchorPoint, dot.Position = UDim2.new(0,8,0,8), Vector2.new(0.5,0.5), UDim2.new(0,0,0.5,0)
                dot.BackgroundColor3, dot.BackgroundTransparency, dot.BorderSizePixel = Color3.fromRGB(220,60,60), 1, 0
                dot.ZIndex, dot.Parent = 10002, track ; newCorner(dot)

                local guards, alive = {}, true

                local function reattach()
                    if not alive then return end
                    task.defer(function()
                        if not alive then return end
                        if not screen.Parent then pcall(function() screen.Parent = guiRef end) end
                        if not bg.Parent     then pcall(function() bg.Parent = screen end) end
                    end)
                end

                guards[1] = bg.AncestryChanged:Connect(reattach)
                guards[2] = screen.AncestryChanged:Connect(reattach)
                guards[3] = screen.DescendantRemoving:Connect(function(d)
                    if d == bg or d == fill or d == track then reattach() end
                end)
                local checkT = 0
                guards[4] = rs.Heartbeat:Connect(function(dt)
                    checkT += dt ; if checkT < 0.1 then return end ; checkT = 0
                    if not alive then return end
                    if not screen.Parent then pcall(function() screen.Parent = guiRef end) end
                    if not bg.Parent     then pcall(function() bg.Parent = screen end) end
                    if screen.DisplayOrder ~= 2147483647 then screen.DisplayOrder = 2147483647 end
                end)

                local fi = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local mainTween = ts:Create(bg, fi, {BackgroundTransparency = 0})
                ts:Create(logo,      fi, {ImageTransparency = 0}):Play()
                ts:Create(titleText, fi, {TextTransparency = 0, TextStrokeTransparency = 0.5}):Play()
                ts:Create(subText,   fi, {TextTransparency = 0}):Play()
                ts:Create(track,     fi, {BackgroundTransparency = 0}):Play()
                ts:Create(fill,      fi, {BackgroundTransparency = 0}):Play()
                ts:Create(dot,       fi, {BackgroundTransparency = 0}):Play()

                local readyEvent = Instance.new("BindableEvent")
                mainTween.Completed:Once(function() readyEvent:Fire() end)
                mainTween:Play()

                local dotAlive = true
                task.spawn(function()
                    while dotAlive do
                        if dot and dot.Parent then ts:Create(dot, TweenInfo.new(0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {BackgroundTransparency=0.6}):Play() end
                        task.wait(0.42)
                        if dot and dot.Parent then ts:Create(dot, TweenInfo.new(0.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut), {BackgroundTransparency=0}):Play() end
                        task.wait(0.42)
                    end
                end)

                local step, completed = 0, false

                local function waitUntilReady()
                    readyEvent.Event:Wait() ; readyEvent:Destroy() ; task.wait(0.5)
                end

                local function markStep()
                    step += 1
                    local pct = math.clamp(step/(totalSteps or 1), 0, 1)
                    local tw = TweenInfo.new(0.22, Enum.EasingStyle.Quad)
                    ts:Create(fill, tw, {Size = UDim2.new(pct,0,1,0)}):Play()
                    ts:Create(dot,  tw, {Position = UDim2.new(pct,0,0.5,0)}):Play()
                    if pct >= 1 and not completed then
                        completed = true
                        task.spawn(function()
                            local tg = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
                            ts:Create(fill, tg, {BackgroundColor3 = Color3.fromRGB(40,180,70)}):Play()
                            ts:Create(dot,  tg, {BackgroundColor3 = Color3.fromRGB(80,220,100)}):Play()
                            for _ = 1, 2 do
                                ts:Create(track, TweenInfo.new(0.08), {Size = UDim2.new(0,268,0,6)}):Play() ; task.wait(0.09)
                                ts:Create(track, TweenInfo.new(0.08), {Size = UDim2.new(0,260,0,4)}):Play() ; task.wait(0.09)
                            end
                        end)
                    end
                end

                local function dismiss()
                    alive, dotAlive = false, false
                    for _, g in ipairs(guards) do g:Disconnect() end
                    ts:Create(fill, TweenInfo.new(0.2), {Size = UDim2.new(1,0,1,0)}):Play()
                    ts:Create(dot,  TweenInfo.new(0.2), {Position = UDim2.new(1,0,0.5,0)}):Play()
                    task.wait(0.22)
                    if not completed then
                        completed = true
                        ts:Create(fill, TweenInfo.new(0.25,Enum.EasingStyle.Quad), {BackgroundColor3=Color3.fromRGB(40,180,70)}):Play()
                        ts:Create(dot,  TweenInfo.new(0.25,Enum.EasingStyle.Quad), {BackgroundColor3=Color3.fromRGB(80,220,100)}):Play()
                        task.wait(0.28)
                    end
                    task.wait(0.3)
                    local fo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    ts:Create(bg,        fo, {BackgroundTransparency=1}):Play()
                    ts:Create(logo,      fo, {ImageTransparency=1}):Play()
                    ts:Create(titleText, fo, {TextTransparency=1, TextStrokeTransparency=1}):Play()
                    ts:Create(subText,   fo, {TextTransparency=1}):Play()
                    ts:Create(track,     fo, {BackgroundTransparency=1}):Play()
                    ts:Create(fill,      fo, {BackgroundTransparency=1}):Play()
                    ts:Create(dot,       fo, {BackgroundTransparency=1}):Play()
                    task.wait(0.5)
                    screen:Destroy()
                    getgenv()._RouteAtivo = false
                end

                return dismiss, markStep, waitUntilReady
            end

            getgenv().IniciarRota = function()
                if getgenv()._RouteTriggerConn then
                    pcall(function() getgenv()._RouteTriggerConn:Disconnect() end)
                    getgenv()._RouteTriggerConn = nil
                end
                if getgenv()._RouteRemoveMarker   then pcall(getgenv()._RouteRemoveMarker)   ; getgenv()._RouteRemoveMarker   = nil end
                if getgenv()._RouteRemoveWaypoint then pcall(getgenv()._RouteRemoveWaypoint) ; getgenv()._RouteRemoveWaypoint = nil end
                getgenv()._RouteAtivo = false

                getgenv()._RouteAtivo = true

                local removeMarker   = buildClone(routeConfig.startAt)
                local removeWaypoint = buildWaypoint()
                getgenv()._RouteRemoveMarker   = removeMarker
                getgenv()._RouteRemoveWaypoint = removeWaypoint

                local ragChar     = ws:FindFirstChild(lp.Name)
                local ragdoll     = ragChar and ragChar:FindFirstChild("Ragdoll")
                local stopRagdoll = ragdoll and ragdoll.ChildAdded:Connect(function(c) c:Destroy() end)

                local activated = false
                local triggerConn

                triggerConn = rs.Heartbeat:Connect(function()
                    if activated then return end
                    local char, hrp = getPlayer()
                    if not hrp then return end
                    local delta  = hrp.Position - routeConfig.startAt.Position
                    local hDist  = Vector3.new(delta.X,0,delta.Z).Magnitude
                    local vDist  = math.abs(delta.Y)
                    local facing = hrp.CFrame.LookVector:Dot(routeConfig.startAt.LookVector)
                    if hDist > routeConfig.triggerDist  then return end
                    if vDist > routeConfig.triggerVert  then return end
                    if facing < math.cos(math.rad(routeConfig.triggerAngle)) then return end

                    activated = true
                    triggerConn:Disconnect()
                    getgenv()._RouteTriggerConn = nil
                    removeWaypoint()
                    removeMarker()

                    task.spawn(function()
                        local dismiss, markStep, waitUntilReady = buildLoadScreen(#routeConfig.route)
                        waitUntilReady()

                        hrp.CFrame = routeConfig.enterAt
                        toggleNoclip(true)
                        task.wait(1)

                        local _, _, hum = getPlayer()
                        hum.WalkSpeed = routeConfig.walkSpeed

                        local connMove, connCheck, connDeath
                        local finished = false

                        local function cancelRoute()
                            if finished then return end ; finished = true
                            connMove:Disconnect() ; connCheck:Disconnect() ; connDeath:Disconnect()
                            hum:MoveTo(hrp.Position) ; hum.WalkSpeed = 16
                            toggleNoclip(false)
                            if stopRagdoll then stopRagdoll:Disconnect() end
                            dismiss()
                        end

                        local function completeRoute()
                            if finished then return end ; finished = true
                            connMove:Disconnect() ; connCheck:Disconnect() ; connDeath:Disconnect()
                            hum:MoveTo(hrp.Position) ; hum.WalkSpeed = 16
                            toggleNoclip(false)
                            if stopRagdoll then stopRagdoll:Disconnect() end
                            task.spawn(function()
                                for _, point in ipairs(routeConfig.route) do
                                    task.wait(routeConfig.stepDelay)
                                    hrp.CFrame = point
                                    markStep()
                                end
                                dismiss()
                            end)
                        end

                        connDeath = hum.Died:Connect(function()
                            toggleNoclip(false)
                            if stopRagdoll then stopRagdoll:Disconnect() end
                            finished = true
                            connMove:Disconnect() ; connCheck:Disconnect() ; connDeath:Disconnect()
                            dismiss()
                        end)

                        lp.CharacterRemoving:Connect(function() toggleNoclip(false) end)

                        connMove = rs.Heartbeat:Connect(function()
                            hum:MoveTo(routeConfig.walkTo.Position)
                        end)

                        connCheck = rs.Heartbeat:Connect(function()
                            if uis:IsKeyDown(Enum.KeyCode.W) or uis:IsKeyDown(Enum.KeyCode.A) or
                               uis:IsKeyDown(Enum.KeyCode.S) or uis:IsKeyDown(Enum.KeyCode.D) or
                               hum.MoveDirection.Magnitude > 0 then cancelRoute() ; return end
                            if (hrp.Position - routeConfig.walkTo.Position).Magnitude <= 1.6 then
                                completeRoute()
                            end
                        end)
                    end)
                getgenv()._RouteTriggerConn = triggerConn
                end)
            end
        end

       -- spam de sons
        getgenv().ApexLogic.ToggleSound = function(ativar)
            getgenv().SpamAtivo = ativar

            if not ativar then
                if getgenv()._SpamThread then
                    pcall(task.cancel, getgenv()._SpamThread)
                    getgenv()._SpamThread = nil
                end
                limparConns(getgenv()._ApexSpamMasterConns)
                limparConns(getgenv()._ApexSpamCharConns)
                return
            end

            if getgenv()._SpamThread then pcall(task.cancel, getgenv()._SpamThread) end
            limparConns(getgenv()._ApexSpamMasterConns)
            limparConns(getgenv()._ApexSpamCharConns)

            getgenv()._SpamThread = task.spawn(function()
                local fireClient = rep:WaitForChild("ServerEvents", 5)
                    and rep.ServerEvents:WaitForChild("FireClient", 5)

                if not fireClient then
                    if getgenv().notificar then getgenv().notificar("Inválido", 3, "lucide:alert-triangle") end
                    return
                end

                local sessionToken  = nil
                local soundList     = {}
                local equippedTool  = nil
                local isReadyToSpam = false
                local rng           = Random.new()

                local function refreshSounds()
                    local found, uniqueIds = {}, {}
                    for _, obj in ipairs(game:GetDescendants()) do
                        if obj:IsA("Sound") and obj.SoundId ~= "" then
                            if not uniqueIds[obj.SoundId] then
                                uniqueIds[obj.SoundId] = true
                                table.insert(found, obj)
                                if #found >= 200 then break end
                            end
                        end
                    end
                    soundList = found
                end

                local function findSessionToken()
                    for _, obj in ipairs(getgc(true)) do
                        if type(obj) == "function" and debug.getinfo(obj).name == "PlaySound" then
                            local val = debug.getupvalue(obj, 2)
                            if val then return val end
                        end
                    end
                    return nil
                end

                local function isValidWeapon(tool)
                    if not tool then return false end
                    local count = 0
                    for _ in ipairs(tool:GetDescendants()) do
                        count = count + 1
                        if count > 5 then return true end
                    end
                    return false
                end

                local function findWeaponInBag()
                    local bag = lp:FindFirstChild("Backpack")
                    if not bag then return nil end
                    for _, item in ipairs(bag:GetChildren()) do
                        if item:IsA("Tool") and isValidWeapon(item) then return item end
                    end
                    return nil
                end

                local function waitForWeapon(name)
                    local startTime = tick()
                    repeat
                        task.wait(0.05)
                        local char = lp.Character
                        local tool = char and char:FindFirstChild(name)
                        if tool and tool:IsA("Tool") then return tool end
                    until (tick() - startTime) > 3
                    return nil
                end

                local function setupToken()
                    isReadyToSpam = false
                    local char = lp.Character
                    if not char then return false end
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if not humanoid then return false end
                    humanoid:UnequipTools() ; task.wait(0.5)
                    local targetWeapon = findWeaponInBag()
                    if not targetWeapon then return false end
                    humanoid:EquipTool(targetWeapon)
                    if not waitForWeapon(targetWeapon.Name) then return false end
                    task.wait(1)
                    sessionToken = findSessionToken()
                    if not sessionToken then return false end
                    humanoid:UnequipTools() ; task.wait(0.5)
                    humanoid:EquipTool(targetWeapon)
                    if not waitForWeapon(targetWeapon.Name) then return false end
                    equippedTool = targetWeapon ; task.wait(0.5)
                    isReadyToSpam = true
                    return true
                end

                local function watchCharacter(char)
                    limparConns(getgenv()._ApexSpamCharConns)
                    isReadyToSpam, sessionToken = false, nil
                    if not char then return end
                    local function checkEquipped()
                        local tool = char:FindFirstChildOfClass("Tool")
                        equippedTool = isValidWeapon(tool) and tool or nil
                    end
                    table.insert(getgenv()._ApexSpamCharConns, char.ChildAdded:Connect(function(child)
                        if child:IsA("Tool") then checkEquipped() end
                    end))
                    table.insert(getgenv()._ApexSpamCharConns, char.ChildRemoved:Connect(function(child)
                        if child:IsA("Tool") then checkEquipped() end
                    end))
                    checkEquipped()
                end

                table.insert(getgenv()._ApexSpamMasterConns, lp.CharacterAdded:Connect(watchCharacter))
                if lp.Character then watchCharacter(lp.Character) end

                task.spawn(function()
                    while getgenv().SpamAtivo do
                        task.wait(30)
                        if getgenv().SpamAtivo then refreshSounds() end
                    end
                end)

                refreshSounds()
                setupToken()

                while getgenv().SpamAtivo do
                    if not equippedTool or not sessionToken or not isReadyToSpam then
                        task.wait(1)
                        if not isReadyToSpam and getgenv().SpamAtivo then setupToken() end
                        continue
                    end
                    local totalSons = #soundList
                    if totalSons > 0 then
                        for i = 1, 20 do
                            if not getgenv().SpamAtivo or not equippedTool or not isReadyToSpam then break end
                            local sound = soundList[rng:NextInteger(1, totalSons)]
                            if sound and sound.Parent then
                                local originalVolume = sound.Volume
                                sound.Volume = 10
                                pcall(fireClient.FireServer, fireClient, sessionToken, "PlaySound", sound, nil)
                                sound.Volume = originalVolume
                            end
                            task.wait(0.05)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
end