local cr = cloneref or function(o) return o end

local plrs = cr(game:GetService("Players"))
local rs = cr(game:GetService("RunService"))
local ws = cr(game:GetService("Workspace"))
local cg = cr(game:GetService("CoreGui"))
local tcs = cr(game:GetService("TextChatService"))
local rep = cr(game:GetService("ReplicatedStorage"))

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
        -- Agora usando if aninhado no lugar de "continue" para o ofuscador não surtar
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
        -- [[ APEX BACKEND ]] --
        local ApexLogic = {}
        getgenv().SpamAtivo = false -- Inicia desligado
        
        if env then env.ApexLogic = ApexLogic end
        getgenv().ApexLogic = ApexLogic

        function ApexLogic.ToggleSound(state)
            getgenv().SpamAtivo = state
            
            if state then
                -- Quando liga o botão, ele roda a SUA lógica exata
                task.spawn(function()
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local LP = game:GetService("Players").LocalPlayer
                    local remote = ReplicatedStorage:WaitForChild("ServerEvents"):WaitForChild("FireClient")
                    
                    local token = nil
                    local listaSons = {}

                    local function atualizarSons()
                        local novosSons = {}
                        for _, v in pairs(game:GetDescendants()) do
                            if v:IsA("Sound") and v.SoundId ~= "" then
                                table.insert(novosSons, v)
                            end
                        end
                        local limitada = {}
                        for i = 1, math.min(100, #novosSons) do
                            limitada[i] = novosSons[i]
                        end
                        listaSons = limitada
                    end

                    local function buscarToken()
                        for _, v in pairs(getgc(true)) do
                            if type(v) == "function" and debug.getinfo(v).name == "PlaySound" then
                                local t = debug.getupvalue(v, 2)
                                if t then return t end
                            end
                        end
                    end

                    atualizarSons()
                    token = buscarToken()

                    -- Loop secundário para atualizar os sons
                    task.spawn(function()
                        while getgenv().SpamAtivo do
                            task.wait(30)
                            if getgenv().SpamAtivo then atualizarSons() end
                        end
                    end)

                    -- Loop principal de spam
                    while getgenv().SpamAtivo do
                        local char = LP.Character
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        
                        if not tool or tool.Parent ~= char then
                            task.wait(0.2)
                            if not token then token = buscarToken() end
                            continue
                        end

                        for i = 1, #listaSons do
                            if not getgenv().SpamAtivo or not tool or tool.Parent ~= char then
                                break
                            end

                            local som = listaSons[i]
                            if som and som.Parent then
                                pcall(function()
                                    remote:FireServer(token, "PlaySound", som, nil)
                                end)
                            end

                            if i % 100 == 0 then
                                task.wait()
                            end
                        end

                        task.wait(0.1)
                    end
                end)
            end
        end

    end -- Fim do bloco Apex
end -- Fim da checagem de mapas