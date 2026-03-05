hookfunction(getrenv().getfenv, function() return task.wait(9e9) end)

-- serviços
local cloneref        = cloneref or function(o) return o end

local Players         = cloneref(game:GetService("Players"))
local TeamsService    = cloneref(game:GetService("Teams"))
local UserInputService= cloneref(game:GetService("UserInputService"))
local RunService      = cloneref(game:GetService("RunService"))
local CoreGui         = cloneref(game:GetService("CoreGui"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local HttpService     = cloneref(game:GetService("HttpService"))
local Workspace       = cloneref(game:GetService("Workspace"))

local LocalPlayer     = cloneref(Players.LocalPlayer)


-- executor
local Executor = identifyexecutor and string.lower(identifyexecutor()) or "unknown"

if string.find(Executor, "xeno") or string.find(Executor, "solara") then
    LocalPlayer:Kick("Seu executor não tem suporte para rodar o michigun.xyz.")
    task.wait(0.5)
    while true do end
end


-- auth
local secret    = "michigun817282861nzjzhan_uqyaisn7klol"
local url       = "https://michigun.xyz/script"

local userId    = tostring(LocalPlayer.UserId)
local placeId   = tostring(game.PlaceId)
local timestamp = tostring(os.time())

local data      = userId .. placeId .. timestamp .. secret
local signature = "nocrypto"

if crypt and crypt.hash then
    signature = crypt.hash(data, "sha256")
elseif syn and syn.crypt then
    signature = syn.crypt.hash(data)
elseif http and http.hash then
    signature = http.hash(data, "sha256")
end

local response = request({
    Url     = url,
    Method  = "GET",
    Headers = {
        ["x-user-id"]   = userId,
        ["x-place-id"]  = placeId,
        ["x-timestamp"] = timestamp,
        ["x-signature"] = signature,
        ["x-mode"]      = "check"
    }
})

if response.StatusCode ~= 200 then
    warn("Erro: " .. response.StatusCode)
end


-- hooks e ghost table
local NewCClosure = newcclosure or function(f) return f end
local CheckCaller = checkcaller or function() return false end

local GhostTable  = setmetatable({}, {__mode = "k"})

local function GetGhost(obj, key)
    return GhostTable[obj] and GhostTable[obj][key]
end
getgenv().GetGhost = GetGhost

local function SetGhost(obj, key, val)
    if not GhostTable[obj] then GhostTable[obj] = {} end
    GhostTable[obj][key] = val
end

local OldIndex
OldIndex = hookmetamethod(game, "__index", NewCClosure(function(self, k)
    if not CheckCaller() then
        if k == "Size"
            and typeof(self) == "Instance"
            and self:IsA("BasePart")
            and self.Name == "HumanoidRootPart"
        then
            local ghost = GetGhost(self, k)
            return ghost ~= nil and ghost or Vector3.new(2, 2, 1)
        end

        local ghost = GetGhost(self, k)
        if ghost ~= nil then return ghost end
    end
    return OldIndex(self, k)
end))

local OldNewIndex
OldNewIndex = hookmetamethod(game, "__newindex", NewCClosure(function(self, k, v)
    if not CheckCaller() and typeof(self) == "Instance" then
        local isHum  = self:IsA("Humanoid")
        local isRoot = self:IsA("BasePart") and self.Name == "HumanoidRootPart"

        if isHum and k == "WalkSpeed" then
            SetGhost(self, k, v)
            if Config and Config.SpeedEnabled then return end
        elseif isHum and k == "JumpPower" then
            SetGhost(self, k, v)
            if Config and Config.JumpEnabled then return end
        elseif isRoot and k == "Size" then
            SetGhost(self, k, v)
            return
        end
    end
    return OldNewIndex(self, k, v)
end))


-- spoof do personagem
local function InitSpoof(char)
    local hum  = char:WaitForChild("Humanoid",        10)
    local root = char:WaitForChild("HumanoidRootPart", 10)

    if hum then
        if not GetGhost(hum, "WalkSpeed") then SetGhost(hum, "WalkSpeed", hum.WalkSpeed) end
        if not GetGhost(hum, "JumpPower") then SetGhost(hum, "JumpPower", hum.JumpPower) end
    end

    if root then
        if not GetGhost(root, "Size") then SetGhost(root, "Size", root.Size) end
    end
end

local function HandlePlayer(p)
    if p.Character then InitSpoof(p.Character) end
    p.CharacterAdded:Connect(InitSpoof)
end

local plrs = game:GetService("Players")
for _, p in ipairs(plrs:GetPlayers()) do HandlePlayer(p) end
plrs.PlayerAdded:Connect(HandlePlayer)


--// ui
local UI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
UI:SetFont("rbxassetid://16658237174")
loadstring(game:HttpGet("https://raw.githubusercontent.com/michigun-log/logs/refs/heads/main/740dd88a77e9cc25.lua.txt"))()

--// tema
UI:AddTheme({
    Name = "Michigun",

    Accent                               = Color3.fromHex("#040303"),
    Background                           = Color3.fromHex("#040303"),
    BackgroundTransparency               = 0,
    Outline                              = Color3.fromHex("#333333"),
    Text                                 = Color3.fromHex("#f0f0f0"),
    Placeholder                          = Color3.fromHex("#555555"),
    Button                               = Color3.fromHex("#1c1c1c"),
    Icon                                 = Color3.fromHex("#888888"),

    Primary                              = Color3.fromHex("#ffffff"),
    Hover                                = Color3.fromHex("#ffffff"),

    WindowBackground                     = Color3.fromHex("#040303"),
    WindowShadow                         = Color3.fromHex("#000000"),

    WindowTopbarButtonIcon               = Color3.fromHex("#888888"),
    WindowTopbarTitle                    = Color3.fromHex("#f0f0f0"),
    WindowTopbarAuthor                   = Color3.fromHex("#666666"),
    WindowTopbarIcon                     = Color3.fromHex("#aaaaaa"),

    TabBackground                        = Color3.fromHex("#111111"),
    TabTitle                             = Color3.fromHex("#f0f0f0"),
    TabIcon                              = Color3.fromHex("#888888"),
    TabBorder                            = Color3.fromHex("#2e2e2e"),

    ElementBackground                    = Color3.fromHex("#141414"),
    ElementTitle                         = Color3.fromHex("#f0f0f0"),
    ElementDesc                          = Color3.fromHex("#777777"),
    ElementIcon                          = Color3.fromHex("#999999"),

    PopupBackground                      = Color3.fromHex("#0f0f0f"),
    PopupBackgroundTransparency          = 0,
    PopupTitle                           = Color3.fromHex("#f0f0f0"),
    PopupContent                         = Color3.fromHex("#bbbbbb"),
    PopupIcon                            = Color3.fromHex("#888888"),

    DialogBackground                     = Color3.fromHex("#0f0f0f"),
    DialogBackgroundTransparency         = 0,
    DialogTitle                          = Color3.fromHex("#f0f0f0"),
    DialogContent                        = Color3.fromHex("#bbbbbb"),
    DialogIcon                           = Color3.fromHex("#888888"),

    Toggle                               = Color3.fromHex("#2a2a2a"),
    ToggleBar                            = Color3.fromHex("#f0f0f0"),

    Checkbox                             = Color3.fromHex("#1c1c1c"),
    CheckboxIcon                         = Color3.fromHex("#f0f0f0"),
    CheckboxBorder                       = Color3.fromHex("#aaaaaa"),
    CheckboxBorderTransparency           = 0,

    Slider                               = Color3.fromHex("#2a2a2a"),
    SliderThumb                          = Color3.fromHex("#f0f0f0"),
    SliderIconFrom                       = Color3.fromHex("#555555"),
    SliderIconTo                         = Color3.fromHex("#f0f0f0"),

    Tooltip                              = Color3.fromHex("#1c1c1c"),
    TooltipText                          = Color3.fromHex("#f0f0f0"),
    TooltipSecondary                     = Color3.fromHex("#444444"),
    TooltipSecondaryText                 = Color3.fromHex("#f0f0f0"),

    SectionExpandIcon                    = Color3.fromHex("#f0f0f0"),
    SectionExpandIconTransparency        = 0.2,
    SectionBox                           = Color3.fromHex("#888888"),
    SectionBoxTransparency               = 0.85,
    SectionBoxBorder                     = Color3.fromHex("#666666"),
    SectionBoxBorderTransparency         = 0.3,
    SectionBoxBackground                 = Color3.fromHex("#888888"),
    SectionBoxBackgroundTransparency     = 0.92,

    SearchBarBorder                      = Color3.fromHex("#444444"),
    SearchBarBorderTransparency          = 0,

    Notification                         = Color3.fromHex("#181818"),
    NotificationTitle                    = Color3.fromHex("#f0f0f0"),
    NotificationTitleTransparency        = 0,
    NotificationContent                  = Color3.fromHex("#aaaaaa"),
    NotificationContentTransparency      = 0,
    NotificationDuration                 = Color3.fromHex("#666666"),
    NotificationDurationTransparency     = 0,
    NotificationBorder                   = Color3.fromHex("#444444"),
    NotificationBorderTransparency       = 0,

    DropdownTabBorder                    = Color3.fromHex("#333333"),
})

local main = UI:CreateWindow({
    Title = "mich.xyz",
    Icon = "rbxthumb://type=Asset&id=137064182739714&w=420&h=420",
    Author = "Feito por fp3",
    Folder = "michigun.xyz",
    Size = UDim2.fromOffset(560, 350),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Radius = 20,
    Transparent = true,
    Theme = "Michigun",
    Resizable = true,
    SideBarWidth = 150,
    ShadowTransparency = 0.7,
    HideSearchBar = true,
    Background = "rbxthumb://type=Asset&id=137064182739714&w=420&h=420",
    BackgroundImageTransparency = 0.9,
    User = {
        Enabled = true,
        Callback = function()
        end
    },
})

--// notificação
local function notificar(mensagem, tempo, icone)
    UI:Notify({
        Title = "mich.xyz",
        Content = mensagem,
        Duration = tempo,
        Icon = icone,
    })
end

--// discord
main:CreateTopbarButton("Discord", "geist:logo-discord", function()
    setclipboard("https://discord.gg/G5vEkrAXnF")
    notificar("Link copiado!", 5, "geist:logo-discord")
end, 990)

--[[ 
uso: Title = cor({"Teste", "#FF0000"}, {" arroz"}),
]]--
function cor(...)
    local output = {}
    for i, data in ipairs({...}) do
        output[i] = "<font color='" .. (data[2] or "#ffffff") .. "'>" .. data[1] .. "</font>"
    end
    return table.concat(output)
end


-- tags
local function lerpColor(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

local function fpsColor(f)
    if f >= 60 then
        return Color3.fromRGB(80, 220, 130)
    elseif f >= 45 then
        return lerpColor(
            Color3.fromRGB(80, 220, 130),
            Color3.fromRGB(255, 190, 50),
            (60 - f) / 15
        )
    elseif f >= 25 then
        return lerpColor(
            Color3.fromRGB(255, 190, 50),
            Color3.fromRGB(230, 70, 70),
            (45 - f) / 20
        )
    else
        return Color3.fromRGB(230, 70, 70)
    end
end

local function pingColor(p)
    if p <= 60 then
        return Color3.fromRGB(80, 220, 130)
    elseif p <= 120 then
        return lerpColor(
            Color3.fromRGB(80, 220, 130),
            Color3.fromRGB(255, 190, 50),
            (p - 60) / 60
        )
    elseif p <= 250 then
        return lerpColor(
            Color3.fromRGB(255, 190, 50),
            Color3.fromRGB(230, 70, 70),
            (p - 120) / 130
        )
    else
        return Color3.fromRGB(230, 70, 70)
    end
end

-- fps
local fpsTag = main:Tag({
    Title  = "-- FPS",
    Radius = 20,
    Icon   = "lucide:gauge",
    Color  = Color3.fromRGB(80, 220, 130),
})

local lastUpdate = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount += 1
    local now = tick()
    local delta = now - lastUpdate
    if delta >= 1 then
        local current = math.floor(frameCount / delta)
        fpsTag:SetTitle(current .. " FPS")
        fpsTag:SetColor(fpsColor(current))
        frameCount = 0
        lastUpdate  = now
    end
end)

-- ping
local pingTag = main:Tag({
    Title  = "-- ms",
    Radius = 20,
    Icon   = "lucide:signal",
    Color  = Color3.fromRGB(80, 220, 130),
})

local Stats      = game:GetService("Stats")
local pingItem   = Stats.Network.ServerStatsItem["Data Ping"]

task.spawn(function()
    while true do
        local ok, value = pcall(function()
            return math.floor(pingItem:GetValue())
        end)

        if ok and value then
            pingTag:SetTitle(value .. " ms")
            pingTag:SetColor(pingColor(value))
        end

        task.wait(2)
    end
end)

--// criar seção
function criarsection(tab, title, desc, icon, opened)
    return tab:Section({
        Title = title,
        Desc = desc,
        Icon = icon,
        Opened = opened or false
    })
end

--// criar tab
function criartab(title, icon, locked)
    return main:Tab({
        Title = title,
        Icon = icon,
        Border = true,
        Locked = locked or false
    })
end

--// tabs "combate"
criarsection(main, "Combate", "Seção de combate", nil, true)
local SilentAim = criartab("Silent aim", "lucide:crosshair", false)
local HitboxExpander = criartab("Hitbox expander", "lucide:codesandbox", false)
local ESP = criartab("ESP", "lucide:view", false)
local X1 = criartab("PvP", "lucide:person-standing", false)

--// tabs "parkour"
criarsection(main, "Parkour", "Seção de parkour", nil, true)
local TAS = criartab("TAS", "solar:running-outline", false)
local JJs = criartab("JJ's", "lucide:space", false)
local ChatGPT = criartab("ChatGPT", "geist:logo-open-ai", false)
local F3X = criartab("F3X", "lucide:hammer", false)

--// tabs "locais"
criarsection(main, "Local", "Seção local", nil, true)
local Char = criartab("Char", "solar:user-hands-bold", false)
local Player = criartab("Player", "solar:user-bold", false)

--// tab "config"
local Configs = criartab("Configurações", "lucide:settings", false)

-- load
local BASE_URL = "https://raw.githubusercontent.com/brasiIidade/x/main/"
local FilePaths = {}

local function download(url, tentativas)
    for i = 1, tentativas or 3 do
        local ok, res = pcall(game.HttpGet, game, url)
        if ok and type(res) == "string" and res:sub(1, 4) ~= "404:" then
            return res
        end
        task.wait(1)
    end
    return nil
end

local function exec(content, nome)
    local fn, err = loadstring(content)
    if not fn then
        warn("[Loader] Erro ao compilar '" .. nome .. "': " .. tostring(err))
        return false
    end
    local ok, err2 = pcall(fn)
    if not ok then
        warn("[Loader] Erro ao executar '" .. nome .. "': " .. tostring(err2))
        return false
    end
    return true
end

local function carregarPaths()
    local content = download(BASE_URL .. "path.lua?t=" .. os.time(), 5)
    if not content then
        if notificar then notificar("Falha ao carregar path.lua", 5, "lucide:wifi-off") end
        return false
    end
    local fn = loadstring(content)
    if fn then FilePaths = fn() end
    return next(FilePaths) ~= nil
end

local function ler(key)
    local nome = FilePaths[key]
    if not nome then
        warn("[Loader] Chave não encontrada: " .. key)
        return
    end

    nome = nome:match("^%s*(.-)%s*$")
    local content = download(BASE_URL .. nome)
    if not content then
        if notificar then notificar("Falha ao baixar: " .. nome, 3, "lucide:wifi-off") end
        return
    end
    exec(content, nome)
end

if not carregarPaths() then return end

-- [[ Loader Removido ]] --


-- silent
getgenv().SilentConfig = {
    Enabled = false,
    TeamCheck = "Team",
    TargetPart = {"Head"},
    TargetPriority = "Distance",
    MaxDistance = 1000,
    HitChance = 70,
    WallCheck = true,
    UseLegitOffset = true,
    WhitelistedUsers = {},
    WhitelistedTeams = {},
    FocusList = {},
    FocusMode = false,
    ShowFOV = true,
    FOVSize = 110,
    FOVColor = Color3.fromRGB(247, 255, 5),
    FOVBehavior = "Center",
    ShowHighlight = true,
    HighlightColor = Color3.fromRGB(255, 60, 60),
    ESP = {
        Enabled = true,
        ShowName = true,
        ShowTeam = true,
        ShowHealth = true,
        ShowWeapon = true
    }
}

local Config = getgenv().SilentConfig
local LocalPlayer = Players.LocalPlayer

local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

local function GetTeamNames()
    local names = {}
    if TeamsService then
        for _, t in ipairs(TeamsService:GetTeams()) do table.insert(names, t.Name) end
    end
    return names
end

do
    local MainSection = criarsection(SilentAim, "Principal", "Controle do silent aim", "lucide:crosshair", true)

    local FirstRun = true
    local ToggleAim = MainSection:Toggle({
        Title = "Silent aim",
        Desc = cor({"Redireciona os "}, {"tiros", "#00FF00"}, {" para o alvo"}),
        Icon = "lucide:power",
        Type = "Checkbox",
        Value = Config.Enabled,
        Flag = "SilentAim",
        Callback = function(state) 
            Config.Enabled = state
            if FirstRun then
                FirstRun = false
                return
            end
            if state then
                notificar("Ativado", 2, "lucide:circle-check")
            else
                notificar("Desativado", 2, "lucide:circle-x")
            end
        end
    })
    
    local CurrentKey = Enum.KeyCode.Q

    MainSection:Keybind({
        Title = "Keybind",
        Desc = cor({"Tecla para "}, {"ativar", "#00FF00"}, {" / "}, {"desativar", "#FF0000"}, {" o silent aim"}),
        Value = "Q",
        Flag = "KeybindSilentAim",
        Callback = function(v)
            if v and Enum.KeyCode[v] then CurrentKey = Enum.KeyCode[v] end
        end
    })

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == CurrentKey then
            local newState = not Config.Enabled
            ToggleAim:SetValue(newState)
        end
    end)

    MainSection:Slider({
        Title = "Hit chance",
        Desc = "Porcentagem de tiros que acertarão o alvo",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = Config.HitChance },
        Flag = "ChanceSilentAim",
        Callback = function(value) Config.HitChance = value end
    })

    local WhitelistSection = criarsection(SilentAim, "Lista de exceções", "Gerenciar amigos e times", "lucide:shield", false)
    local PlayerWhitelist
    
    WhitelistSection:Button({
        Title = "Atualizar lista",
        Desc = "Atualiza a lista de jogadores",
        Icon = "lucide:refresh-cw",
        Callback = function()
            if PlayerWhitelist then PlayerWhitelist:Refresh(GetPlayerNames()) end
            notificar("Lista atualizada", 1, "lucide:refresh-ccw")
        end
    })

    PlayerWhitelist = WhitelistSection:Dropdown({
        Title = "Ignorar jogadores",
        Desc = cor({"Não", "#FF0000"}, {" foca nesses jogadores"}),
        Values = GetPlayerNames(),
        Value = Config.WhitelistedUsers, 
        Multi = true,
        AllowNone = true,
        Flag = "WhitelistPlayersSilentAim",
        Callback = function(options) Config.WhitelistedUsers = options end
    })

    WhitelistSection:Dropdown({
        Title = "Ignorar times",
        Desc = cor({"Não", "#FF0000"}, {" foca nesses times"}),
        Values = GetTeamNames(),
        Value = Config.WhitelistedTeams,
        Multi = true,
        AllowNone = true,
        Flag = "WhitelistTimesSilentAim",
        Callback = function(options) Config.WhitelistedTeams = options end
    })

    local FocusSection = criarsection(SilentAim, "Focar", "Focar em jogadores específicos", "lucide:scan-eye", false)
    
    local FocusFirstRun = true
    FocusSection:Toggle({
        Title = "Modo foco",
        Desc = cor({"Foca "}, {"apenas", "#FFAA00"}, {" em quem está na lista"}),
        Icon = "lucide:focus",
        Type = "Checkbox",
        Value = Config.FocusMode,
        Flag = "ModoFocarSilentAim",
        Callback = function(state)
            Config.FocusMode = state
            if FocusFirstRun then
                FocusFirstRun = false
                return
            end
            notificar("Modo foco: " .. (state and "Ativado" or "Desativado"), 2, "lucide:circle-alert")
        end
    })

    local FocusListParagraph = nil
    local RemoveDropdown = nil

    local function UpdateFocusUI()
        if FocusListParagraph then
            local listStr = table.concat(Config.FocusList, ", ")
            if listStr == "" then listStr = "Nenhum alvo definido." end
            FocusListParagraph:SetDesc(listStr)
        end
        if RemoveDropdown then
            RemoveDropdown:Refresh(Config.FocusList)
        end
    end

    FocusSection:Input({
        Title = "Adicionar alvo",
        Desc = cor({"Digite o "}, {"nome", "#00AAFF"}),
        Placeholder = "Digite aqui",
        InputIcon = "lucide:user-plus",
        Callback = function(text)
            if not text or text == "" then return end
            local foundName = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if string.sub(p.Name:lower(), 1, #text) == text:lower() then
                    foundName = p.Name
                    break
                end
            end
            if foundName then
                if not table.find(Config.FocusList, foundName) then
                    table.insert(Config.FocusList, foundName)
                    UpdateFocusUI()
                    notificar("Alvo adicionado: " .. foundName, 2, "lucide:check")
                end
            else
                notificar("Jogador não encontrado", 2, "lucide:search-x")
            end
        end
    })

    RemoveDropdown = FocusSection:Dropdown({
        Title = "Remover da lista",
        Desc = cor({"Selecione para "}, {"excluir", "#FF0000"}),
        Values = {},
        Value = nil,
        Multi = false,
        AllowNone = true,
        Callback = function(val)
            if val then
                local idx = table.find(Config.FocusList, val)
                if idx then
                    table.remove(Config.FocusList, idx)
                    UpdateFocusUI()
                    RemoveDropdown:Select(nil)
                end
            end
        end
    })

    FocusListParagraph = FocusSection:Paragraph({
        Title = "Jogadores focados",
        Desc = "Nenhum alvo",
        Buttons = {
            {
                Icon = "lucide:trash-2",
                Title = "Limpar",
                Callback = function()
                    Config.FocusList = {}
                    UpdateFocusUI()
                    notificar("Lista limpa", 2, "lucide:trash")
                end
            }
        }
    })

    local LogicSection = criarsection(SilentAim, "Configurações", "Ajustar configurações", "lucide:settings-2", false)

    LogicSection:Dropdown({
        Title = "Prioridade",
        Desc = "Como escolher o melhor alvo",
        Values = {"Distance", "Health"},
        Value = "Distance",
        Flag = "PrioridadeSilentAim",
        Callback = function(option) Config.TargetPriority = option end
    })

    LogicSection:Dropdown({
        Title = "Partes",
        Desc = "Onde o tiro deve ir",
        Values = { "Aleatório", "Cabeça", "Tronco", "Braço direito", "Braço esquerdo", "Perna direita", "Perna esquerda" },
        Value = {"Aleatório"},
        Multi = true,
        AllowNone = true,
        Flag = "PartesSilentAim",
        Callback = function(option) Config.TargetPart = option end
    })

    LogicSection:Dropdown({
        Title = "Alvos",
        Desc = "Quem deve ser atacado",
        Values = { "Todos", "Inimigos" },
        Value = "Inimigos",
        Flag = "AlvosSilentAim",
        Callback = function(option) Config.TeamCheck = (option == "Todos") and "All" or "Team" end
    })

    LogicSection:Toggle({
        Title = "Humanizar",
        Desc = cor({"O tiro sairá mais "}, {"legit", "#00FF00"}),
        Icon = "lucide:user-check",
        Type = "Checkbox",
        Value = Config.UseLegitOffset,
        Flag = "LegitSilentAim",
        Callback = function(state) Config.UseLegitOffset = state end
    })

    LogicSection:Toggle({
        Title = "Wall check",
        Desc = cor({"Ignora", "#FF0000"}, {" inimigos atrás de paredes"}),
        Icon = "lucide:brick-wall",
        Type = "Checkbox",
        Value = Config.WallCheck,
        Flag = "WallcheckSilentAim",
        Callback = function(state) Config.WallCheck = state end
    })

    LogicSection:Slider({
        Title = "Distância máxima",
        Desc = "Alcance do silent aim",
        Step = 10,
        Value = { Min = 50, Max = 5000, Default = Config.MaxDistance },
        Flag = "AlcanceSilentAim",
        Callback = function(value) Config.MaxDistance = value end
    })

    local VisualsSection = criarsection(SilentAim, "Visual", "FOV", "lucide:palette", false)

    VisualsSection:Toggle({
        Title = "FOV",
        Desc = "Ativa o FOV",
        Icon = "lucide:check",
        Type = "Checkbox",
        Value = Config.ShowFOV,
        Flag = "FOV",
        Callback = function(state) Config.ShowFOV = state end
    })

    VisualsSection:Dropdown({
        Title = "Posição",
        Desc = "Modifica a posição do FOV",
        Values = { "Mouse", "Center" },
        Value = "Center",
        Flag = "PosicaoFOV",
        Callback = function(option) Config.FOVBehavior = option end
    })

    VisualsSection:Slider({
        Title = "Tamanho",
        Desc = "Modifica o tamanho do FOV",
        Step = 5,
        Value = { Min = 40, Max = 1000, Default = Config.FOVSize },
        Flag = "TamanhoFOV",
        Callback = function(value) Config.FOVSize = value end
    })

    VisualsSection:Colorpicker({
        Title = "Cor do FOV",
        Default = Config.FOVColor,
        Transparency = 0,
        Locked = false,
        Flag = "CorFOV1",
        Callback = function(color) Config.FOVColor = color end
    })

    VisualsSection:Toggle({
        Title = "Highlight",
        Desc = cor({"Brilha"}, {" a pessoa focada", "#00AAFF"}),
        Icon = "lucide:sparkles",
        Type = "Checkbox",
        Value = Config.ShowHighlight,
        Flag = "HighlightSilentAim",
        Callback = function(state) Config.ShowHighlight = state end
    })

    VisualsSection:Colorpicker({
        Title = "Cor da info",
        Desc = "HUD e highlight",
        Default = Config.HighlightColor,
        Transparency = 0,
        Locked = false,
        Flag = "HighlightCorSilentAim",
        Callback = function(color) Config.HighlightColor = color end
    })

    local InfoSection = criarsection(SilentAim, "HUD", "Informações dos alvos", "lucide:layout-template", false)
    local ToggleName, ToggleHP, ToggleWeapon, ToggleTeam

    local ToggleESP = InfoSection:Toggle({
        Title = "HUD",
        Desc = "Mostra informações do alvo",
        Icon = "lucide:app-window",
        Type = "Checkbox",
        Value = Config.ESP.Enabled,
        Flag = "InfoSilentAim",
        Callback = function(state) 
            Config.ESP.Enabled = state
            if state then
                if ToggleName then ToggleName:Unlock() end
                if ToggleTeam then ToggleTeam:Unlock() end
                if ToggleHP then ToggleHP:Unlock() end
                if ToggleWeapon then ToggleWeapon:Unlock() end
            else
                if ToggleName then ToggleName:Lock() end
                if ToggleTeam then ToggleTeam:Lock() end
                if ToggleHP then ToggleHP:Lock() end
                if ToggleWeapon then ToggleWeapon:Lock() end
            end
        end
    })

    ToggleName = InfoSection:Toggle({
        Title = "Nome",
        Desc = "Mostra o nome do jogador",
        Icon = "lucide:text-cursor",
        Type = "Checkbox",
        Value = Config.ESP.ShowName,
        Flag = "InfoNomeSilentAim",
        Callback = function(state) Config.ESP.ShowName = state end
    })

    ToggleTeam = InfoSection:Toggle({
        Title = "Time",
        Desc = "Mostra o time do jogador",
        Icon = "lucide:users",
        Type = "Checkbox",
        Value = Config.ESP.ShowTeam,
        Flag = "InfoTimeSilentAim",
        Callback = function(state) Config.ESP.ShowTeam = state end
    })

    ToggleHP = InfoSection:Toggle({
        Title = "Vida",
        Desc = "Mostra a vida do alvo",
        Icon = "lucide:heart-pulse",
        Type = "Checkbox",
        Value = Config.ESP.ShowHealth,
        Flag = "InfoVidaSilentAim",
        Callback = function(state) Config.ESP.ShowHealth = state end
    })

    ToggleWeapon = InfoSection:Toggle({
        Title = "Item",
        Desc = "Mostra o que o alvo está segurando",
        Icon = "lucide:sword",
        Type = "Checkbox",
        Value = Config.ESP.ShowWeapon,
        Flag = "InfoItemSilentAim",
        Callback = function(state) Config.ESP.ShowWeapon = state end
    })
    
    if not Config.ESP.Enabled then
        ToggleName:Lock(); ToggleTeam:Lock(); ToggleHP:Lock(); ToggleWeapon:Lock()
    end
end

--// tab hitbox

getgenv().HitboxConfig = {
    Enabled = false,
    Size = Vector3.new(5,5,5),
    Transparency = 0.5,
    Shape = Enum.PartType.Ball,
    HideOnShield = false,
    TeamCheck = true,
    TeamFilterEnabled = false,
    SelectedTeams = {},
    WhitelistedUsers = {},
    WhitelistedTeams = {},
    FocusList = {},
    FocusMode = false
}

local Config = getgenv().HitboxConfig

do
    local MainSection = criarsection(HitboxExpander, "Principal", "Controles gerais", "lucide:box", true)

    local FirstRun = true
    MainSection:Toggle({
        Title = "Hitbox",
        Desc = cor({"Liga", "#00FF00"}, {" o hitbox expander"}),
        Icon = "lucide:boxes",
        Value = Config.Enabled,
        Flag = "Hitbox",
        Callback = function(v)
            Config.Enabled = v
            if FirstRun then
                FirstRun = false
                return
            end

            if v then
                notificar("Ligado", 2, "lucide:play")
            else
                notificar("Desligado", 2, "lucide:pause")
            end
        end
    })

MainSection:Toggle({
        Title = "Team check",
        Desc = cor({"Ignora", "#FF0000"}, {" jogadores do mesmo time"}),
        Icon = "lucide:shield-check",
        Value = Config.TeamCheck,
        Flag = "TeamCheckHitbox",
        Callback = function(v)
            Config.TeamCheck = v
        end
    })

    local ConfigSection = criarsection(HitboxExpander, "Configuração", "Ajustes visuais e técnicos", "lucide:settings-2", false)

    ConfigSection:Input({
        Title = "Tamanho da hitbox",
        Placeholder = "20",
        InputIcon = "lucide:ruler",
        Flag = "TamanhoHitbox",
        Callback = function(v)
            local n = tonumber(v)
            if n then
                Config.Size = Vector3.new(n,n,n)
            end
        end
    })

    ConfigSection:Dropdown({
        Title = "Formato",
        Desc = cor({"Formato", "#00AAFF"}, {" usado para a hitbox"}),
        Icon = "lucide:shapes",
        Values = { "Sphere", "Block", "Cylinder", "Wedge" },
        Value = "Sphere",
        Flag = "FormatoHitbox",
        Callback = function(option)
            local map = {
                Sphere = Enum.PartType.Ball,
                Block = Enum.PartType.Block,
                Cylinder = Enum.PartType.Cylinder,
                Wedge = Enum.PartType.Wedge
            }
            Config.Shape = map[option]
        end
    })

    ConfigSection:Toggle({
        Title = "Escudo check",
        Desc = cor({"A hitbox volta ao normal se "}, {"equiparem", "#FFAA00"}, {" o escudo"}),
        Icon = "lucide:shield-alert",
        Value = Config.HideOnShield,
        Flag = "EscudoHitbox",
        Callback = function(v)
            Config.HideOnShield = v
        end
    })

    ConfigSection:Slider({
        Title = "Transparência",
        Desc = cor({"0 = "}, {"visível", "#00FF00"}, {"; 1 = "}, {"invisível", "#FF0000"}),
        Icon = "lucide:ghost",
        Step = 0.02,
        Value = { Min = 0, Max = 1, Default = Config.Transparency },
        Flag = "VisibilidadeHitbox",
        Callback = function(val)
            Config.Transparency = val
        end
    })

    local TeamSection = criarsection(HitboxExpander, "Filtros", "Configuração de times", "lucide:users", false)

    TeamSection:Toggle({
        Title = "Filtrar por time",
        Desc = cor({"Aplica", "#00AAFF"}, {" a hitbox apenas nos times selecionados"}),
        Icon = "lucide:sliders-horizontal",
        Value = Config.TeamFilterEnabled,
        Flag = "FiltrarTimeHitbox",
        Callback = function(v)
            Config.TeamFilterEnabled = v
        end
    })

    TeamSection:Dropdown({
        Title = "Times",
        Desc = cor({"Selecione", "#FFFFFF"}, {" os times"}),
        Icon = "lucide:users-round",
        Values = GetTeamNames(),
        Value = {}, 
        Multi = true,
        AllowNone = true,
        Flag = "TimesFiltradosHitbox",
        Callback = function(option)
            Config.SelectedTeams = option
        end
    })

    local WhitelistSection = criarsection(HitboxExpander, "Lista de exceções", "Gerenciar amigos e times", "lucide:shield", false)
    local PlayerWhitelist
    
    WhitelistSection:Button({
        Title = "Atualizar lista",
        Desc = "Atualiza a lista de jogadores",
        Icon = "lucide:refresh-cw",
        Callback = function()
            if PlayerWhitelist then PlayerWhitelist:Refresh(GetPlayerNames()) end
            notificar("Lista atualizada", 1, "lucide:refresh-ccw")
        end
    })

    PlayerWhitelist = WhitelistSection:Dropdown({
        Title = "Ignorar jogadores",
        Desc = cor({"Não", "#FF0000"}, {" foca nesses jogadores"}),
        Values = GetPlayerNames(),
        Value = Config.WhitelistedUsers, 
        Multi = true,
        AllowNone = true,
        Callback = function(options) Config.WhitelistedUsers = options end
    })

    WhitelistSection:Dropdown({
        Title = "Ignorar times",
        Desc = cor({"Não", "#FF0000"}, {" foca nesses times"}),
        Values = GetTeamNames(),
        Value = Config.WhitelistedTeams,
        Multi = true,
        AllowNone = true,
        Flag = "IgnorarTimesHitbox",
        Callback = function(options) Config.WhitelistedTeams = options end
    })

    local FocusSection = criarsection(HitboxExpander, "Focar", "Focar em jogadores específicos", "lucide:scan-eye", false)
    
    local FocusFirstRun = true
    FocusSection:Toggle({
        Title = "Modo foco",
        Desc = cor({"Foca "}, {"apenas", "#FFAA00"}, {" em quem está na lista"}),
        Icon = "lucide:focus",
        Type = "Checkbox",
        Value = Config.FocusMode,
        Flag = "ModoFocarHitbox",
        Callback = function(state)
            Config.FocusMode = state
            if FocusFirstRun then
                FocusFirstRun = false
                return
            end
            notificar("Modo foco: " .. (state and "Ativado" or "Desativado"), 2, "lucide:circle-alert")
        end
    })

    local FocusListParagraph = nil
    local RemoveDropdown = nil

    local function UpdateFocusUI()
        if FocusListParagraph then
            local listStr = table.concat(Config.FocusList, ", ")
            if listStr == "" then listStr = "Nenhum alvo definido." end
            FocusListParagraph:SetDesc(listStr)
        end
        if RemoveDropdown then
            RemoveDropdown:Refresh(Config.FocusList)
        end
    end

    FocusSection:Input({
        Title = "Adicionar alvo",
        Desc = cor({"Digite o "}, {"nome", "#00AAFF"}),
        Placeholder = "Digite aqui",
        InputIcon = "lucide:user-plus",
        Callback = function(text)
            if not text or text == "" then return end
            local foundName = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if string.sub(p.Name:lower(), 1, #text) == text:lower() then
                    foundName = p.Name
                    break
                end
            end
            if foundName then
                if not table.find(Config.FocusList, foundName) then
                    table.insert(Config.FocusList, foundName)
                    UpdateFocusUI()
                    notificar("Alvo adicionado: " .. foundName, 2, "lucide:check")
                end
            else
                notificar("Jogador não encontrado", 2, "lucide:search-x")
            end
        end
    })

    RemoveDropdown = FocusSection:Dropdown({
        Title = "Remover da lista",
        Desc = cor({"Selecione para "}, {"excluir", "#FF0000"}),
        Values = {},
        Value = nil,
        Multi = false,
        AllowNone = true,
        Callback = function(val)
            if val then
                local idx = table.find(Config.FocusList, val)
                if idx then
                    table.remove(Config.FocusList, idx)
                    UpdateFocusUI()
                    RemoveDropdown:Select(nil)
                end
            end
        end
    })

    FocusListParagraph = FocusSection:Paragraph({
        Title = "Jogadores focados",
        Desc = "Nenhum alvo",
        Buttons = {
            {
                Icon = "lucide:trash-2",
                Title = "Limpar",
                Callback = function()
                    Config.FocusList = {}
                    UpdateFocusUI()
                    notificar("Lista limpa", 2, "lucide:trash")
                end
            }
        }
    })
end

--// tab esp
getgenv().ESPConfig = {
    Enabled = false,
    TeamCheck = false,
    Chams = false,
    Name = false,
    Studs = false,
    Health = false,
    WeaponN = false
}

local MainSection = criarsection(ESP, "Principal", "Controles gerais", "lucide:eye", true)

MainSection:Paragraph({
    Title = "ESP",
    Image = "lucide:scan-eye",
    Desc = cor({"Permite ver "}, {"jogadores", "#FFFFFF"}, {" através das "}, {"paredes", "#FF0000"})
})

local FirstRunESP = true
MainSection:Toggle({
    Title = "ESP",
    Desc = cor({"Liga", "#00FF00"}, {" o ESP"}),
    Icon = "lucide:power",
    Value = false,
    Flag = "ESP",
    Callback = function(v)
        if FirstRunESP then
            FirstRunESP = false
            if v then
                if getgenv().StartESP then getgenv().StartESP() end
            else
                if getgenv().StopESP then getgenv().StopESP() end
            end
            return
        end

        if v then
            if getgenv().StartESP then 
                getgenv().StartESP() 
                notificar("Ativado", 2, "lucide:eye")
            end
        else
            if getgenv().StopESP then 
                getgenv().StopESP() 
                notificar("Desativado", 2, "lucide:eye-off")
            end
        end
    end
})

MainSection:Toggle({
    Title = "Team check",
    Desc = cor({"Não", "#FF0000"}, {" mostra se o jogador for do seu "}, {"time", "#00FF00"}),
    Icon = "lucide:shield-check",
    Value = getgenv().ESPConfig.TeamCheck,
    Flag = "TimeESP",
    Callback = function(v)
        getgenv().ESPConfig.TeamCheck = v
    end
})

local VisualsSection = criarsection(ESP, "Visualização", "Elementos visuais", "lucide:monitor", true)

VisualsSection:Toggle({ 
    Title = "Highlight", 
    Desc = cor({"Ativa o "}, {"brilho", "#FFAA00"}),
    Icon = "lucide:sparkles", 
    Value = getgenv().ESPConfig.Chams, 
    Flag = "ChamsESP", 
    Callback = function(v) getgenv().ESPConfig.Chams = v end 
})

VisualsSection:Toggle({ 
    Title = "Nome", 
    Desc = cor({"Exibe o "}, {"nome", "#FFFFFF"}),
    Icon = "lucide:user", 
    Value = getgenv().ESPConfig.Name, 
    Flag = "NomeESP", 
    Callback = function(v) getgenv().ESPConfig.Name = v end 
})

VisualsSection:Toggle({ 
    Title = "Distância", 
    Desc = cor({"Mostra a "}, {"distância", "#00AAFF"}),
    Icon = "lucide:ruler", 
    Value = getgenv().ESPConfig.Studs, 
    Flag = "DistanciaESP", 
    Callback = function(v) getgenv().ESPConfig.Studs = v end 
})

VisualsSection:Toggle({ 
    Title = "Vida", 
    Desc = cor({"Exibe "}, {"a barra de vida", "#FF0000"}),
    Icon = "lucide:heart", 
    Value = getgenv().ESPConfig.Health, 
    Flag = "VidaESP", 
    Callback = function(v) getgenv().ESPConfig.Health = v end 
})

VisualsSection:Toggle({ 
    Title = "Item", 
    Desc = cor({"Mostra o "}, {"item", "#FFAA00"}, {" que o jogador está segurando"}),
    Icon = "lucide:sword", 
    Value = getgenv().ESPConfig.WeaponN, 
    Flag = "ItemESP", 
    Callback = function(v) getgenv().ESPConfig.WeaponN = v end 
})


--// tab X1
local ugs = UserSettings():GetService("UserGameSettings")

local slData = {
    on = false,
    loop = false,
    binds = {},
    active = false
}

local function setSL(state)
    slData.active = state
    if not state then
        pcall(function()
            ugs.RotationType = Enum.RotationType.MovementRelative
        end)
    end
end

local function check(char)
    if not slData.on or not char then return end
    local found = false
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and string.find(string.lower(v.Name), "escudo") then
            found = true
            break
        end
    end
    setSL(found)
end

local function init(char)
    if not char then return end
    
    check(char)
    
    local b1 = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            check(char)
        end
    end)
    
    local b2 = char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            check(char)
        end
    end)
    
    table.insert(slData.binds, b1)
    table.insert(slData.binds, b2)
end

local function mgrLoop(enable)
    if enable then
        if not slData.loop then
            slData.loop = true
            RunService:BindToRenderStep("SL_E", 201, function()
                if slData.active then
                    local cam = workspace.CurrentCamera
                    if cam then
                        ugs.RotationType = Enum.RotationType.CameraRelative
                        if 0.99 <= (cam.Focus.Position - cam.CFrame.Position).Magnitude then
                            cam.CFrame *= CFrame.new(2.5, 0, 0)
                            cam.Focus = CFrame.fromMatrix(cam.Focus.Position, cam.CFrame.RightVector, cam.CFrame.UpVector) * CFrame.new(2.5, 0, 0)
                        end
                    end
                end
            end)
        end
    else
        if slData.loop then
            slData.loop = false
            RunService:UnbindFromRenderStep("SL_E")
        end
        setSL(false)
    end
end

X1:Toggle({
    Title = "Escudo -> shiftlock",
    Desc = cor({"Ativa", "#00FF00"}, {" o"}, {" shiftlock", "#00FF00"}, {" ao equipar o escudo"}),
    Icon = "lucide:brick-wall-shield",
    Value = false,
    Flag = "EscudoShiftlock",
    Callback = function(v)
        slData.on = v
        
        for _, b in ipairs(slData.binds) do 
            b:Disconnect() 
        end
        table.clear(slData.binds)
        
        local char = LocalPlayer.Character
        
        if not v then
            mgrLoop(false)
            return
        end
        
        mgrLoop(true)
        
        if char then init(char) end
        
        local b3 = LocalPlayer.CharacterAdded:Connect(function(newChar)
            setSL(false)
            init(newChar)
        end)
        table.insert(slData.binds, b3)
    end
})

local logic = {
    Enabled = false,
    X = 1.0,
    Y = 1.0,
    Z = 1.0,
    IsBound = false
}

local sliderX, sliderY, sliderZ

local StretchSection = criarsection(X1, "Tela esticada", "Modificar tela", "lucide:fullscreen", true)

StretchSection:Toggle({
    Title = "Tela esticada",
    Value = false,
    Flag = "TelaEsticada",
    Callback = function(v)
        logic.Enabled = v
        if v then
            if sliderX then sliderX:Unlock() end
            if sliderY then sliderY:Unlock() end
            if sliderZ then sliderZ:Unlock() end
            
            if not logic.IsBound then
                logic.IsBound = true
                RunService:BindToRenderStep("ForceStretchCamera", Enum.RenderPriority.Camera.Value + 1, function()
                    local c = Workspace.CurrentCamera
                    if c then
                        local right = c.CFrame.RightVector.Unit
                        local up = c.CFrame.UpVector.Unit
                        local look = -c.CFrame.LookVector.Unit
                        
                        local cleanCFrame = CFrame.fromMatrix(c.CFrame.Position, right, up, look)
                        
                        c.CFrame = cleanCFrame * CFrame.new(
                            0, 0, 0,
                            logic.X, 0, 0,
                            0, logic.Y, 0,
                            0, 0, logic.Z
                        )
                    end
                end)
            end
        else
            if sliderX then sliderX:Lock() end
            if sliderY then sliderY:Lock() end
            if sliderZ then sliderZ:Lock() end
            
            if logic.IsBound then
                RunService:UnbindFromRenderStep("ForceStretchCamera")
                logic.IsBound = false
            end
        end
    end
})

StretchSection:Divider()

local pX = StretchSection:Paragraph({
    Title = "Largura",
    Desc = "1.00",
    Flag = "Largura1"
})

sliderX = StretchSection:Slider({
    Title = "Valor",
    Value = { Min = 0.10, Max = 1.20, Default = 1.00 },
    Step = 0.01,
    Locked = true,
    Flag = "Largura2",
    Callback = function(value)
        logic.X = value
        pX:SetDesc(string.format("%.2f", logic.X))
    end
})

StretchSection:Divider()

local pY = StretchSection:Paragraph({
    Title = "Altura",
    Desc = "1.00",
    Flag = "Altura1"
})

sliderY = StretchSection:Slider({
    Title = "Valor",
    Value = { Min = 0.10, Max = 1.30, Default = 1.00 },
    Step = 0.01,
    Locked = true,
    Flag = "Altura2",
    Callback = function(value)
        logic.Y = value
        pY:SetDesc(string.format("%.2f", logic.Y))
    end
})

StretchSection:Divider()

local pZ = StretchSection:Paragraph({
    Title = "Profundidade",
    Desc = "1.00",
    Flag = "Profundidade1"
})

sliderZ = StretchSection:Slider({
    Title = "Valor",
    Value = { Min = 0.10, Max = 1.20, Default = 1.00 },
    Step = 0.01,
    Locked = true,
    Flag = "Profundidade2",
    Callback = function(value)
        logic.Z = value
        pZ:SetDesc(string.format("%.2f", logic.Z))
    end
})


--// tab tas

local TASDropdown
local StopButton
local DeleteButton
local IsConfirmingDelete = false

local function RefreshTASList(list)
    if TASDropdown then
        table.sort(list, function(a, b) return a:lower() < b:lower() end)
        TASDropdown:Refresh(list)
    end
end

local PlaybackSection = criarsection(TAS, "Reprodução", "Controles de execução", "lucide:play", true)

PlaybackSection:Toggle({
    Title = "Iniciar",
    Icon = "lucide:circle-play",
    Desc = cor({"Inicia a "}, {"execução", "#00FF00"}, {" do percurso"}),
    Value = false,
    Flag = "TAS",
    Callback = function(v)
        if getgenv().TAS and getgenv().TAS.ToggleAll then
            getgenv().TAS.ToggleAll(v)
        end
    end
})

StopButton = PlaybackSection:Button({
    Title = "Parar",
    Desc = cor({"Interrompe o ", "#FF0000"}, {" TAS"}),
    Icon = "lucide:circle-stop",
    Locked = true,
    Callback = function()
        if getgenv().TAS and getgenv().TAS.ManualStopPlayback then
            getgenv().TAS.ManualStopPlayback()
        end
    end
})
PlaybackSection:Space()

TASDropdown = PlaybackSection:Dropdown({
    Title = "Selecionar",
    Icon = "lucide:list",
    Desc = cor({"Escolha os "}, {"TAS para iniciar", "#FFFFFF"}),
    Values = {},
    Value = {},
    Multi = true,
    AllowNone = true,
    Flag = "SelecaoTAS",
    Callback = function(v)
        if getgenv().TAS and getgenv().TAS.UpdateSelection then
            getgenv().TAS.UpdateSelection(v)
        end
    end
})

DeleteButton = PlaybackSection:Button({
    Title = "Deletar",
    Desc = cor({"Apaga", "#FF0000"}, {" os TAS selecionados"}),
    Icon = "lucide:trash-2",
    Callback = function()
        if IsConfirmingDelete then
            if getgenv().TAS and getgenv().TAS.DeleteSelected then
                local newList = getgenv().TAS.DeleteSelected()
                RefreshTASList(newList)
                TASDropdown:Select({})
            end
            IsConfirmingDelete = false
            DeleteButton:SetTitle("Deletar")
            DeleteButton:SetDesc(cor({"Apaga", "#FF0000"}, {" os TAS selecionados"}))
        else
            IsConfirmingDelete = true
            DeleteButton:SetTitle("Certeza?")
            DeleteButton:SetDesc(cor({"Clique novamente para "}, {"apagar", "#FF0000"}))
            task.delay(3, function()
                if IsConfirmingDelete then
                    IsConfirmingDelete = false
                    DeleteButton:SetTitle("Deletar")
                    DeleteButton:SetDesc(cor({"Apaga", "#FF0000"}, {" os TAS selecionados"}))
                end
            end)
        end
    end
})

PlaybackSection:Colorpicker({
    Title = "Humanoid",
    Desc = "Muda a cor do personagem",
    Default = Color3.fromRGB(0, 255, 0),
    Flag = "TASHumanoidCor",
    Callback = function(color)
        if getgenv().TAS and getgenv().TAS.UpdateVisuals then
            getgenv().TAS.UpdateVisuals(color, nil, nil)
        end
    end
})

PlaybackSection:Colorpicker({
    Title = "Trajetória",
    Desc = "Muda a cor da trajetória",
    Default = Color3.fromRGB(0, 255, 0),
    Flag = "TASTrajetoriaCor",
    Callback = function(color)
        if getgenv().TAS and getgenv().TAS.UpdateVisuals then
            getgenv().TAS.UpdateVisuals(nil, color, nil)
        end
    end
})

PlaybackSection:Slider({
    Title = "Opacidade",
    Desc = cor({"Visibilidade do  "}, {"TAS", "#FF0000"}),
    Value = { Min = 0, Max = 1, Default = 0 },
    Step = 0.05,
    Flag = "OpacidadeTAS",
    Callback = function(value)
        if getgenv().TAS and getgenv().TAS.UpdateVisuals then
            getgenv().TAS.UpdateVisuals(nil, nil, value)
        end
    end
})

task.spawn(function()
    repeat task.wait(0.5) until getgenv().TAS and getgenv().TAS.IsReady
    getgenv().TAS.NotifyFunc = notificar 

    local oldStop = getgenv().TAS.StopRecording
    getgenv().TAS.StopRecording = function()
        if oldStop then oldStop() end
        if main then main:Open() end
    end

    getgenv().TAS.UpdateButtonState = function(isPlaying)
        if StopButton then
            if isPlaying then
                StopButton:Unlock()
            else
                StopButton:Lock()
            end
        end
    end
    
    if getgenv().TAS.GetSaved then
        RefreshTASList(getgenv().TAS.GetSaved())
    end
end)

local RecordSection = criarsection(TAS, "Gravação", "Criar novo percurso", "lucide:video", false)

RecordSection:Paragraph({
    Title = "Observação",
    Color = Color3.fromHex("#800080"),
    Image = "lucide:message-square",
    ImageSize = 30,
    Desc = cor({"Também é possível usar "}, {"/e gravar", "#00FF00"}, {" e "}, {"/e parar", "#FF0000"}, {" no chat"}),
})

RecordSection:Input({
    Title = "Nome",
    Desc = cor({"Defina o "}, {"nome", "#00AAFF"}, {" do arquivo"}),
    Value = "",
    InputIcon = "lucide:pencil",
    Flag = "NomeTAS",
    Callback = function(v)
        if getgenv().TAS then getgenv().TAS.CurrentName = v end
    end
})

local g = RecordSection:Group()
g:Button({ 
    Title = "Gravar", 
    Desc = cor({"Inicia", "#00FF00"}, {" a gravação"}),
    Icon = "lucide:circle-dot",
    Callback = function()
        if main then main:Close() end
        if getgenv().TAS and getgenv().TAS.StartRecording then getgenv().TAS.StartRecording() end
    end 
})

g:Space()

g:Button({ 
    Title = "Parar", 
    Desc = cor({"Finaliza", "#FF0000"}, {" a gravação"}),
    Icon = "lucide:square",
    Callback = function()
        if getgenv().TAS and getgenv().TAS.StopRecording then getgenv().TAS.StopRecording() end
    end 
})

RecordSection:Paragraph({
    Title = "Observação",
    Color = Color3.fromHex("#800080"),
    Image = "lucide:hard-drive",
    ImageSize = 30,
    Desc = cor({"O arquivo será salvo para a pasta "}, {"michigun.xyz/tas", "#00AAFF"}),
})

RecordSection:Button({ 
    Title = "Salvar", 
    Desc = cor({"Salva", "#FFAA00"}, {" o arquivo"}),
    Icon = "lucide:save",
    Callback = function()
        if not getgenv().TAS then return end
        
        if not getgenv().TAS.CurrentName or getgenv().TAS.CurrentName == "" then
            notificar("Defina um nome antes de salvar", 3, "lucide:alert-circle")
            return
        end

        if getgenv().TAS.SaveCurrent then
            local newList = getgenv().TAS.SaveCurrent()
            if newList then
                RefreshTASList(newList)
                notificar("Salvo com sucesso", 3, "lucide:check")
            else
                notificar("Nada gravado para salvar", 3, "lucide:x")
            end
        end
    end 
})


--// tab JJs
local ETAParagraph = JJs:Paragraph({
    Title = "Status",
    Desc  = "Aguardando...",
    Color = "Green",
    Locked = false,
})

task.spawn(function()
    local RunService = game:GetService("RunService")
    
    repeat task.wait(0.5) until getgenv().JJs or _G.JJs
    local ref = getgenv().JJs or _G.JJs
    
    while true do
        if ref.State and ref.State.Running then
            local state = ref.State
            local now = tick()
            
            local timeLeft = math.max(0, state.FinishTimestamp - now)
            
            if ETAParagraph then
                ETAParagraph:SetDesc(string.format(
                    "Progresso: %d / %d\nEstimativa: %.1f s", 
                    state.Current, 
                    state.Total, 
                    timeLeft
                ))
            end
        else
            if ETAParagraph then ETAParagraph:SetDesc("Aguardando início...") end
        end
        RunService.RenderStepped:Wait()
    end
end)

local JJsMain = criarsection(JJs, "Essenciais", "Configurações principais", "lucide:sliders-horizontal", true)

local jjTypes = {"Padrão"}

if game.PlaceId == 14511049 then
    table.insert(jjTypes, "JJ (Delta)")
end

if game.PlaceId == 13132367906 then
    table.insert(jjTypes, "Canguru")
end

JJsMain:Toggle({
    Title = "Auto JJ's",
    Desc = cor({"Créditos ao "}, {"Zv_yz", "#A020F0"}),
    Icon = "lucide:zap",
    Value = false,
    Callback = function(v)
        if _G.JJs then
            if v then
                _G.JJs.Start()
                notificar("Iniciado", 2, "lucide:play")
            else
                _G.JJs.Stop()
                notificar("Parado", 2, "lucide:pause")
            end
        end
    end
})

JJsMain:Dropdown({
    Title = "Modo",
    Desc = cor({"Escolha qual "}, {"JJ", "#00AAFF"}, {" fazer"}),
    Icon = "lucide:list",
    Values = jjTypes,
    Value = "Padrão",
    Flag = "TipoJJ",
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.Mode = v end
    end
})

JJsMain:Space()

JJsMain:Input({
    Title = "Inicial",
    Placeholder = "1",
    InputIcon = "lucide:hash",
    Callback = function(v)
        if _G.JJs and v ~= "" then _G.JJs.Config.StartValue = tonumber(v) or 1 end
    end
})

JJsMain:Input({
    Title = "Final",
    Placeholder = "100",
    InputIcon = "lucide:hash",
    Callback = function(v)
        if _G.JJs and v ~= "" then _G.JJs.Config.EndValue = tonumber(v) or 100 end
    end
})

JJsMain:Toggle({
    Title = "Pular",
    Desc = cor({"Pular", "#00FF00"}, {" ao enviar JJ's"}),
    Icon = "lucide:arrow-up",
    Value = false,
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.JumpEnabled = v end
    end
})

JJsMain:Toggle({
    Title = "Espaçamento",
    Desc = cor({"Separa", "#FFFFFF"}, {" o sufixo do número"}),
    Icon = "lucide:move-horizontal",
    Value = false,
    Flag = "JJsEspacar",
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.SpacingEnabled = v end
    end
})

JJsMain:Space()

JJsMain:Toggle({
    Title = "Intervalo inteligente",
    Desc  = cor({"Ignora", "#FF0000"}, {" intervalos e termina exatamente no tempo indicado"}),
    Icon = "lucide:brain-circuit",
    Value = false,
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.FinishInTime = v end
    end
})

JJsMain:Input({
    Title = "Tempo",
    Placeholder = "60 (segundos)",
    InputIcon = "lucide:hourglass",
    Callback = function(v)
        if _G.JJs and v ~= "" then _G.JJs.Config.FinishTotalTime = tonumber(v) or 60 end
    end
})

JJsMain:Space()

JJsMain:Dropdown({
    Title = "Sufixo",
    Icon = "lucide:quote",
    Values = { "!", "?", ".", ",", "/" },
    Value = "!",
    Flag = "JJsSufixo",
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.Suffix = v end
    end
})

JJsMain:Input({
    Title = "Sufixo customizado",
    Placeholder = "@",
    InputIcon = "lucide:pen-line",
    Flag = "JJsSufixoCustomizado",
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.CustomSuffix = tostring(v or "") end
    end
})

local intervalos = criarsection(JJs, "Intervalo", "Configuração de tempo", "lucide:timer", false)

intervalos:Toggle({
    Title = "Intervalo fixo",
    Desc  = cor({"Ativa", "#00AAFF"}, {" o intervalo fixo"}),
    Icon = "lucide:clock",
    Value = false,
    Flag = "JJsIntervaloFixo",
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.DelayEnabled = v end
    end
})

intervalos:Input({
    Title = "Intervalo fixo",
    Placeholder = "1.5 (segundos)",
    InputIcon = "lucide:watch",
    Flag = "JJsIntervaloFixoTempo",
    Callback = function(v)
        if _G.JJs and v ~= "" then _G.JJs.Config.DelayValue = tonumber(v) or 1.5 end
    end
})

intervalos:Space()

intervalos:Toggle({
    Title = "Intervalo dinâmico",
    Desc  = cor({"Usa um intervalo "}, {"aleatório", "#FFAA00"}, {" entre mínimo e máximo"}),
    Icon = "lucide:shuffle",
    Value = false,
    Flag = "JJsIntervaloDinamico",
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.RandomDelay = v end
    end
})

intervalos:Input({
    Title = "Valor mínimo",
    Placeholder = "1",
    InputIcon = "lucide:arrow-down-to-line",
    Flag = "JJsDinamicoMinimo",
    Callback = function(v)
        if _G.JJs and v ~= "" then _G.JJs.Config.RandomMin = tonumber(v) or 1 end
    end
})

intervalos:Input({
    Title = "Valor máximo",
    Placeholder = "3",
    InputIcon = "lucide:arrow-up-to-line",
    Flag = "JJsDinamicoMaximo",
    Callback = function(v)
        if _G.JJs and v ~= "" then _G.JJs.Config.RandomMax = tonumber(v) or 3 end
    end
})

local Extras = criarsection(JJs, "Extras", "Opções adicionais", "lucide:layers", false)

Extras:Toggle({
    Title = "Modo reverso",
    Desc  = cor({"Conta de "}, {"trás pra frente", "#FF0000"}),
    Icon = "lucide:arrow-up-down",
    Value = false,
    Flag = "JJsReverso",
    Callback = function(v)
        if _G.JJs then _G.JJs.Config.ReverseEnabled = v end
    end
})


--// tab ChatGPT
local currentPrompt = ""

ChatGPT:Paragraph({
    Title = "Observação",
    Desc = cor({"O prompt usado para a IA está localizado na pasta"}, {"michigun.xyz/IA", "#FFF000"}, {"."}, {"Você pode colocar todas as leis no arquivo e a IA saberá"}),
    Color = "Blue",
    Image = "lucide:info",
    ImageSize = 30
})

ChatGPT:Input({
    Title = "Prompt",
    Placeholder = "Pergunte aqui",
    InputIcon = "lucide:message-square",
    Callback = function(text)
        currentPrompt = text
    end
})

local SendBtn
SendBtn = ChatGPT:Button({
    Title = "Enviar prompt",
    Icon = "lucide:send",
    Justify = "Center",
    Callback = function()
        if not _G.ChatGPT or not _G.ChatGPT.Ask then 
            notificar("Aguarde...", 2, "lucide:loader")
            return 
        end
        if currentPrompt == "" then return end

        SendBtn:Lock()
        
        local timestamp = os.date("%H:%M:%S")
        
        ChatGPT:Divider()
        ChatGPT:Space()
        
        ChatGPT:Paragraph({
            Title = timestamp .. " Você:",
            Color = "Blue",
            Desc = currentPrompt,
            Image = "lucide:user-round",
            ImageSize = 25
        })

        task.spawn(function()
            local cleanMsg, luaCode = _G.ChatGPT.Ask(currentPrompt)
            
            ChatGPT:Paragraph({
                Title = timestamp .. " Resposta:",
                Desc = cleanMsg,
                Color = "Green",
                Image = "geist:logo-open-ai",
                ImageSize = 28
            })

            if luaCode then
                ChatGPT:Code({ Code = luaCode })
            end

            SendBtn:Unlock()
        end)
    end
})

ChatGPT:Button({
    Title = "Enviar resposta no chat",
    Icon = "lucide:message-circle",
    Justify = "Center",
    Callback = function()
        if _G.ChatGPT and _G.ChatGPT.SendToChat and _G.ChatGPT.LastMessage then
            _G.ChatGPT.SendToChat(_G.ChatGPT.LastMessage)
            notificar("Enviado no chat", 2, "lucide:message-square")
        else
            notificar("Nada para enviar", 2, "lucide:x")
        end
    end
})

ChatGPT:Button({
    Title = "Copiar resposta",
    Icon = "lucide:copy",
    Justify = "Center",
    Callback = function()
        if _G.ChatGPT and _G.ChatGPT.LastMessage then
            if setclipboard then
                setclipboard(_G.ChatGPT.LastMessage)
                notificar("Copiado!", 2, "lucide:copy")
            else
                notificar("Executor sem 'setclipboard'", 2, "lucide:x")
            end
        else
            notificar("Nada para copiar", 2, "lucide:x")
        end
    end
})

--// tab F3X
local InfoParagraph
local InputX, InputY, InputZ
local ConfigDropdown
local CurrentConfigName = ""
local SelectedConfig = nil

local function round(n)
    return math.floor(n * 10 + 0.5) / 10
end

local function GetF3X()
    return getgenv().F3X
end

local function UpdateUIBridge()
    local f3x = GetF3X()
    if not f3x or not InfoParagraph then return end
    
    if not f3x.SelectedParts or #f3x.SelectedParts == 0 then
        InfoParagraph:SetTitle(cor({"Nada ", "#FF0000"}, {"selecionado"}))
        InfoParagraph:SetDesc("")
        return
    end

    local part = f3x.SelectedParts[1]
    if not part then return end
    local s = part.Size
    
    InfoParagraph:SetTitle(cor({part.Name, "#00AAFF"}))
    InfoParagraph:SetDesc(
        cor({"X: ", "#AAAAAA"}, {tostring(round(s.X)), "#FFFFFF"}) .. "\n" ..
        cor({"Y: ", "#AAAAAA"}, {tostring(round(s.Y)), "#FFFFFF"}) .. "\n" ..
        cor({"Z: ", "#AAAAAA"}, {tostring(round(s.Z)), "#FFFFFF"})
    )

    if InputX and InputX.Set then InputX:Set(tostring(round(s.X))) end
    if InputY and InputY.Set then InputY:Set(tostring(round(s.Y))) end
    if InputZ and InputZ.Set then InputZ:Set(tostring(round(s.Z))) end
end

local SelectionSection = criarsection(F3X, "Seleção", "Status e ativação", "lucide:mouse-pointer-click", true)

SelectionSection:Toggle({
    Title = "Selecionar",
    Desc = cor({"Ativa a ferramenta de "}, {"seleção", "#00FF00"}),
    Icon = "lucide:mouse-pointer-2",
    Callback = function(v)
        local f = GetF3X()
        if f and f.Toggle then f.Toggle(v) end
    end
})

InfoParagraph = SelectionSection:Paragraph({ Title = "Nenhuma parte selecionada.", Desc = "" })

local EditSection = criarsection(F3X, "Edição", "Ajustes de tamanho", "lucide:scaling", true)

InputX = EditSection:Input({ Title = "X (largura)", Desc = cor({"Altera a "}, {"largura", "#00AAFF"}), InputIcon = "lucide:move-3d", Flag = "InputX" })
local gx = EditSection:Group()
gx:Button({ Title = "-0.2", Callback = function() if InputX.Value then InputX:Set(tostring((tonumber(InputX.Value) or 0) - 0.2)) end end })
gx:Button({ Title = "+0.2", Callback = function() if InputX.Value then InputX:Set(tostring((tonumber(InputX.Value) or 0) + 0.2)) end end })

EditSection:Space()

InputY = EditSection:Input({ Title = "Y (altura)", Desc = cor({"Altera a "}, {"altura", "#00AAFF"}), InputIcon = "lucide:move-3d", Flag = "InputY" })
local gy = EditSection:Group()
gy:Button({ Title = "-0.2", Callback = function() if InputY.Value then InputY:Set(tostring((tonumber(InputY.Value) or 0) - 0.2)) end end })
gy:Button({ Title = "+0.2", Callback = function() if InputY.Value then InputY:Set(tostring((tonumber(InputY.Value) or 0) + 0.2)) end end })

EditSection:Space()

InputZ = EditSection:Input({ Title = "Z (profundidade)", Desc = cor({"Altera a "}, {"profundidade", "#00AAFF"}), InputIcon = "lucide:move-3d", Flag = "InputZ" })
local gz = EditSection:Group()
gz:Button({ Title = "-0.2", Callback = function() if InputZ.Value then InputZ:Set(tostring((tonumber(InputZ.Value) or 0) - 0.2)) end end })
gz:Button({ Title = "+0.2", Callback = function() if InputZ.Value then InputZ:Set(tostring((tonumber(InputZ.Value) or 0) + 0.2)) end end })

EditSection:Space()

EditSection:Button({
    Title = "Aplicar tamanho",
    Desc = cor({"Aplica as "}, {"dimensões", "#00FF00"}, {" na parte selecionada"}),
    Icon = "lucide:check",
    Callback = function()
        local f = GetF3X()
        if f and f.ApplySize then
            f.ApplySize(Vector3.new(tonumber(InputX.Value), tonumber(InputY.Value), tonumber(InputZ.Value)))
        end
    end
})

local gUR = EditSection:Group()
gUR:Button({ Title = "Undo", Desc = cor({"Desfaz", "#FFAA00"}, {" a última ação"}), Icon = "lucide:undo-2", Callback = function() local f = GetF3X() if f and f.Undo then f.Undo() end end })
gUR:Button({ Title = "Redo", Desc = cor({"Refaz", "#FFAA00"}, {" a última ação"}), Icon = "lucide:redo-2", Callback = function() local f = GetF3X() if f and f.Redo then f.Redo() end end })

local ConfigSection = criarsection(F3X, "Configurações", "Salvar e carregar", "lucide:save", false)

ConfigSection:Paragraph({
    Title = "Sistema de salvamento",
    Desc = cor({"Permite "}, {"salvar", "#00FF00"}, {", "}, {"deletar", "#FF0000"}, {" e "}, {"aplicar", "#00AAFF"}, {" F3X"})
})

ConfigSection:Paragraph({
    Title = "Observação",
    Color = Color3.fromHex("#800080"),
    Image = "lucide:info",
    ImageSize = 30,
    Desc = cor({"Salvo em "}, {"michigun.xyz/F3X", "#00AAFF"})
})

ConfigSection:Input({
    Title = "Nome da configuração",
    Desc = cor({"Digite o "}, {"nome", "#FFFFFF"}, {" para salvar"}),
    InputIcon = "lucide:tag",
    Callback = function(v) CurrentConfigName = v end
})

ConfigDropdown = ConfigSection:Dropdown({
    Title = "F3X salvos",
    Desc = cor({"Selecione um "}, {"arquivo", "#FFFFFF"}, {" da lista"}),
    Icon = "lucide:folder",
    Values = {},
    Callback = function(v) SelectedConfig = v end
})

local ActionDropdown = nil
local CreateConfigActions

CreateConfigActions = function()
    if ActionDropdown then
        ActionDropdown:Destroy()
        ActionDropdown = nil
    end

    local actions = {
        {
            Title = "Salvar novo F3X",
            Desc = cor({"Cria", "#00FF00"}, {" um novo registro"}),
            Icon = "lucide:save",
            Callback = function()
                if not CurrentConfigName or CurrentConfigName == "" then
                    notificar("Digite um nome primeiro", 3, "lucide:alert-circle")
                    CreateConfigActions()
                    return
                end
                
                local f = GetF3X()
                if f and f.SaveConfig then
                    local newList = f.SaveConfig(CurrentConfigName)
                    if newList then 
                        ConfigDropdown:Refresh(newList)
                        notificar("Salvo com sucesso", 3, "lucide:check")
                    end
                end
                CreateConfigActions()
            end
        },
        {
            Title = "Carregar F3X",
            Desc = cor({"Carrega", "#00AAFF"}, {" os dados selecionados"}),
            Icon = "lucide:upload",
            Callback = function()
                if not SelectedConfig then
                    notificar("Selecione um F3X primeiro", 3, "lucide:mouse-pointer-click")
                    CreateConfigActions()
                    return
                end

                local f = GetF3X()
                if f and f.ApplyConfig then 
                    f.ApplyConfig(SelectedConfig) 
                    notificar("Configuração aplicada", 3, "lucide:check")
                end 
                CreateConfigActions()
            end
        },
        {
            Title = "Deletar F3X",
            Desc = cor({"Remove", "#FF0000"}, {" permanentemente o arquivo"}),
            Icon = "lucide:trash-2",
            Callback = function()
                if not SelectedConfig then
                    notificar("Selecione um F3X primeiro", 3, "lucide:mouse-pointer-click")
                    CreateConfigActions()
                    return
                end

                local f = GetF3X()
                if f and f.DeleteConfig then
                    local newList = f.DeleteConfig(SelectedConfig)
                    if newList then 
                        ConfigDropdown:Refresh(newList) 
                        SelectedConfig = nil
                        ConfigDropdown:Select(nil)
                        notificar("F3X deletado", 3, "lucide:trash")
                    end
                end 
                CreateConfigActions()
            end
        }
    }

    ActionDropdown = ConfigSection:Dropdown({
        Title = "Ações",
        Desc = cor({"Gerenciar "}, {"configurações", "#FFAA00"}),
        Icon = "lucide:settings-2",
        Values = actions,
        Value = "Nenhuma"
    })
end

CreateConfigActions()

task.spawn(function()
    repeat task.wait(0.5) until getgenv().F3X and getgenv().F3X.IsReady
    local f = GetF3X()
    f.UpdateUI = UpdateUIBridge
    f.NotifyFunc = notificar
    if f.ListConfigs then
        ConfigDropdown:Refresh(f.ListConfigs())
    end
end)


--// tab char
local function GetAvatar()
    return getgenv().Avatar
end

local targetInput = ""
local otherTargetName = ""
local otherSkinInput = ""
local selectedFavorite = nil
local confirmDelete = false
local confirmTask = nil
local SkinDropdown = nil
local DeleteButton = nil

local MainSection = criarsection(Char, "Principal", "Char", "lucide:shirt", true)

MainSection:Paragraph({
    Title = "Observação",
    Desc = cor({"A skin aplicada é visual. "}, {"Skins são salvas na pasta michigun/skins", "#FF0000"}),
    Color = "Blue",
    Image = "lucide:circle-alert",
    ImageSize = 30,
    Locked = false
})

MainSection:Input({
    Title = "Nome",
    Desc = cor({"Digite o "}, {"nome", "#FFFFFF"}, {" ou "}, {"ID", "#FFFFFF"}, {" do usuário"}),
    Value = "",
    InputIcon = "lucide:search",
    Placeholder = "Digite aqui",
    Callback = function(input)
        targetInput = input
    end
})

local g1 = MainSection:Group()
g1:Button({
    Title = "Aplicar",
    Desc = cor({"Aplica", "#00FF00"}, {" o char"}),
    Icon = "lucide:check",
    Callback = function()
        local av = GetAvatar()
        if av and av.ApplySkin then
            av.ApplySkin(targetInput)
        end
    end
})

g1:Space()

g1:Button({
    Title = "Restaurar",
    Desc = cor({"Restaura", "#FF0000"}, {" sua skin original"}),
    Icon = "lucide:rotate-ccw",
    Callback = function()
        local av = GetAvatar()
        if av and av.RestoreSkin then
            av.RestoreSkin()
        end
    end
})

local OthersSection = criarsection(Char, "Outros", "Modifica a skin de terceiros", "lucide:users", false)

OthersSection:Input({
    Title = "Nome",
    Desc = cor({"Nome do "}, {"jogador", "#00AAFF"}),
    Value = "",
    InputIcon = "lucide:user-search",
    Placeholder = "sanctuaryangels",
    Callback = function(input)
        otherTargetName = input
    end
})

OthersSection:Input({
    Title = "Nome",
    Desc = cor({"Nome ou ID do char que será "}, {"aplicado", "#00FF00"}, {" no jogador"}),
    Value = "",
    InputIcon = "lucide:shirt",
    Placeholder = "ID ou Nome",
    Callback = function(input)
        otherSkinInput = input
    end
})

local g2 = OthersSection:Group()

g2:Button({
    Title = "Aplicar",
    Desc = cor({"Muda", "#00FF00"}, {" a skin do jogador alvo"}),
    Icon = "lucide:wand-2",
    Callback = function()
        local av = GetAvatar()
        if av and av.ApplySkinToOther then
            av.ApplySkinToOther(otherTargetName, otherSkinInput)
        end
    end
})

g2:Button({
    Title = "Restaurar",
    Desc = cor({"Reseta", "#FF0000"}, {" a skin do jogador alvo"}),
    Icon = "lucide:refresh-ccw",
    Callback = function()
        local av = GetAvatar()
        if av and av.RestoreOther then
            av.RestoreOther(otherTargetName)
        end
    end
})

OthersSection:Button({
    Title = "Aplicar favorito",
    Desc = cor({"Aplica a skin "}, {"favoritada", "#FFAA00"}, {" selecionada no alvo"}),
    Icon = "lucide:star",
    Callback = function()
        if not selectedFavorite then
             notificar("Nenhum favorito selecionado", 3, "lucide:x")
             return
        end
        local av = GetAvatar()
        if av and av.ApplySkinToOther then
            av.ApplySkinToOther(otherTargetName, selectedFavorite, true) 
        end
    end
})

local FavSection = criarsection(Char, "Favoritos", "Gerenciar skins salvas", "lucide:star", false)

local SkinSelectDropdown = nil
local ActionDropdown = nil
local isConfirmingDelete = false

local function RefreshList()
    local av = GetAvatar()
    if av and av.GetSavedSkins and SkinSelectDropdown then
        local skins = av.GetSavedSkins()
        SkinSelectDropdown:Refresh(skins)
        
        local found = false
        for _, v in pairs(skins) do
            local t = (type(v) == "table" and v.Title) or v
            if t == selectedFavorite then found = true break end
        end
        
        if not found then
            selectedFavorite = nil
            SkinSelectDropdown:Select(nil)
        end
    end
end

local CreateActionMenu

SkinSelectDropdown = FavSection:Dropdown({
    Title = "Selecionar skin",
    Desc = cor({"Escolha para "}, {"carregar", "#00FF00"}, {" ou "}, {"deletar", "#FF0000"}),
    Icon = "lucide:list",
    Values = {}, 
    Value = "",
    Callback = function(option)
        isConfirmingDelete = false
        if confirmTask then task.cancel(confirmTask) confirmTask = nil end
        
        local title = (type(option) == "table" and option.Title) or option

        if title == "Nenhuma salva" or title == "" then
            selectedFavorite = nil
        else
            selectedFavorite = title
        end
        
        if ActionDropdown then
             CreateActionMenu()
        end
    end
})

CreateActionMenu = function()
    if ActionDropdown then
        ActionDropdown:Destroy()
        ActionDropdown = nil
    end

    local actions = {
        {
            Title = "Aplicar em mim",
            Desc = cor({"Usa", "#00FF00"}, {" o char selecionado em você"}),
            Icon = "lucide:user-check",
            Callback = function()
                if not selectedFavorite then
                    notificar("Selecione um char primeiro", 3, "lucide:mouse-pointer-click")
                    return
                end
                
                local av = GetAvatar()
                if av and av.LoadSkin then
                    av.LoadSkin(selectedFavorite)
                    notificar("Aplicado: " .. selectedFavorite, 3, "lucide:check")
                end
            end
        },
        {
            Title = "Favoritar char atual",
            Desc = cor({"Salva", "#FFAA00"}, {" o char que você está usando"}),
            Icon = "lucide:save",
            Callback = function()
                local av = GetAvatar()
                if av and av.SaveSkin then
                    av.SaveSkin(targetInput) 
                    notificar("Char salvo", 3, "lucide:check")
                    RefreshList()
                end
                CreateActionMenu()
            end
        },
        {
            Title = isConfirmingDelete and "Confirmar deleção?" or "Deletar selecionado",
            Desc = isConfirmingDelete and cor({"Clique novamente para "}, {"apagar", "#FF0000"}) or cor({"Remove", "#FF0000"}, {" a skin selecionada"}),
            Icon = isConfirmingDelete and "lucide:alert-triangle" or "lucide:trash-2",
            Callback = function()
                if not selectedFavorite then
                    notificar("Selecione um char primeiro", 3, "lucide:mouse-pointer-click")
                    CreateActionMenu()
                    return
                end

                if not isConfirmingDelete then
                    isConfirmingDelete = true
                    notificar("Confirme a ação", 2, "lucide:alert-triangle")
                    CreateActionMenu()

                    if confirmTask then task.cancel(confirmTask) end
                    confirmTask = task.delay(3, function()
                        if isConfirmingDelete then
                            isConfirmingDelete = false
                            if ActionDropdown then CreateActionMenu() end
                        end
                    end)
                else
                    local av = GetAvatar()
                    if av and av.DeleteSkin then
                        av.DeleteSkin(selectedFavorite)
                        notificar("Deletado: " .. selectedFavorite, 3, "lucide:trash")
                    end
                    
                    isConfirmingDelete = false
                    if confirmTask then task.cancel(confirmTask) end
                    selectedFavorite = nil
                    
                    RefreshList()
                    CreateActionMenu()
                end
            end
        },
        {
            Type = "Divider"
        },
        {
            Title = "Atualizar lista",
            Desc = cor({"Recarrega", "#00AAFF"}, {" a lista de favoritos"}),
            Icon = "lucide:rotate-ccw",
            Callback = function()
                RefreshList()
                notificar("Lista atualizada", 2, "lucide:check")
                CreateActionMenu()
            end
        }
    }

    ActionDropdown = FavSection:Dropdown({
        Title = "Gerenciar",
        Desc = cor({"Gerenciar "}, {"favoritos", "#FFFFFF"}),
        Icon = "lucide:settings-2",
        Values = actions,
        Value = "Nenhuma"
    })
end

CreateActionMenu()

task.spawn(function()
    repeat task.wait(0.5) until getgenv().Avatar and getgenv().Avatar.GetSavedSkins
    RefreshList()
end)

--//tab player
getgenv().PlayerConfig = {
    SpeedEnabled = false,
    SpeedVal = 16,
    JumpEnabled = false,
    JumpVal = 50,
    Noclip = false,
    RespawnEnabled = false,
    AnonEnabled = false,
    FakeName = "Anônimo",
    InvisEnabled = false,
    SpectateActive = false,
    FlingActive = false,
    TargetPlayer = "",
    TriggerTeleport = false,
    TriggerReturn = false,
    TriggerFling = false
}

local Config = getgenv().PlayerConfig

local function FindPlayerName(txt)
    if not txt or txt == "" then return nil end
    txt = txt:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Name:lower():sub(1, #txt) == txt or p.DisplayName:lower():sub(1, #txt) == txt then
                return p.Name
            end
        end
    end
    return nil
end

do
    local CharSection = criarsection(Player, "Personagem", "Modificar personagem", "lucide:user-cog", true)

    CharSection:Toggle({
        Title = "Anônimo",
        Desc = cor({"Altera o seu nome"}, {" visualmente", "#00AAFF"}),
        Flag = "Anonimo",
        Icon = "lucide:square-user-round",
        Callback = function(v)
            Config.AnonEnabled = v
            if v then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then hum.DisplayName = Config.FakeName end
            end
        end
    })

    CharSection:Input({
        Title = "Nome",
        Desc = cor({"Nome para o modo "}, {"anônimo", "#00AAFF"}),
        Placeholder = "Anônimo",
        InputIcon = "lucide:user-pen",
        Callback = function(v)
            if v ~= "" then Config.FakeName = v end
        end
    })

    CharSection:Space()

    CharSection:Toggle({
        Title = "Invisibilidade",
        Desc = cor({"Fica "}, {"invisível", "#FFFFFF"}, {" para outros jogadores"}),
        Flag = "Invisivel",
        Icon = "lucide:hat-glasses",
        Callback = function(v) Config.InvisEnabled = v end
    })

    CharSection:Toggle({
        Title = "Respawn",
        Desc = cor({"Volta ao lugar onde você "}, {"morreu", "#FF0000"}),
        Flag = "Respawn",
        Icon = "lucide:map-pin",
        Callback = function(v) 
            Config.RespawnEnabled = v 
            if v then notificar("Respawn ativado", 2, "lucide:check") end
        end
    })

    CharSection:Toggle({
        Title = "Noclip",
        Desc = cor({"Atravessa ", "#00AAFF"}, {"paredes"}),
        Flag = "Noclip",
        Icon = "lucide:ghost",
        Callback = function(v) Config.Noclip = v end
    })

    local ModSection = criarsection(Player, "Física", "Velocidade e pulo", "lucide:activity", false)

    local spd_val = 16
    ModSection:Input({
        Title = "Speed",
        Placeholder = "16",
        InputIcon = "lucide:gauge",
        Callback = function(v) spd_val = tonumber(v) or 16 end
    })

    local grp_spd = ModSection:Group()
    grp_spd:Button({
        Title = "Aplicar",
        Icon = "lucide:check-circle",
        Callback = function()
            Config.SpeedVal = spd_val
            Config.SpeedEnabled = true
            notificar("Velocidade: " .. spd_val, 2, "lucide:zap")
        end
    })
    grp_spd:Button({
        Title = "Resetar",
        Icon = "lucide:rotate-ccw",
        Callback = function()
            Config.SpeedEnabled = false
            Config.SpeedVal = 16
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if h then 
                h.WalkSpeed = GetGhost(h, "WalkSpeed") or 16 
            end
        end
    })

    ModSection:Space()

    local jmp_val = 50
    ModSection:Input({
        Title = "Jump",
        Placeholder = "50",
        InputIcon = "lucide:arrow-up",
        Callback = function(v) jmp_val = tonumber(v) or 50 end
    })

    local grp_jmp = ModSection:Group()
    grp_jmp:Button({
        Title = "Aplicar",
        Icon = "lucide:check-circle",
        Callback = function()
            Config.JumpVal = jmp_val
            Config.JumpEnabled = true
            notificar("Pulo: " .. jmp_val, 2, "lucide:zap")
        end
    })
    grp_jmp:Button({
        Title = "Resetar",
        Icon = "lucide:rotate-ccw",
        Callback = function()
            Config.JumpEnabled = false
            Config.JumpVal = 50
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if h then 
                h.JumpPower = GetGhost(h, "JumpPower") or 50 
            end
        end
    })

    local IntSection = criarsection(Player, "Interação", "Outros jogadores", "lucide:users", false)
    local ActionDrop
    
    IntSection:Input({
        Title = "Jogador",
        Desc = "Nome ou Display",
        Placeholder = "Digite aqui",
        InputIcon = "lucide:search",
        Callback = function(v)
            if v == "" then return end
            
            local found = FindPlayerName(v)
            if found then
                Config.TargetPlayer = found
                notificar("Selecionado: " .. found, 3, "lucide:user-check")
            else
                notificar("Jogador não encontrado", 2, "lucide:search-x")
            end
        end
    })

    local function refresh_drop()
        if ActionDrop then ActionDrop:Destroy() ActionDrop = nil end
        
        local acts = {
            {
                Title = "Fling",
                Desc = cor({"Arremessa o alvo (arriscado)"}),
                Icon = "lucide:earth",
                Callback = function()
                    if Config.TargetPlayer == "" then
                        notificar("Selecione um jogador primeiro", 2, "lucide:alert-circle")
                        return
                    end
                    Config.TriggerFling = true
                    notificar("Flingando " .. Config.TargetPlayer, 3, "lucide:helicopter")
                end
            },
            {
                Title = Config.SpectateActive and "Parar Espectar" or "Espectar",
                Desc = "Visualiza a câmera do alvo",
                Icon = "lucide:eye",
                Callback = function()
                    if Config.TargetPlayer == "" then
                         notificar("Selecione um jogador", 2, "lucide:alert-circle")
                         return
                    end
                    Config.SpectateActive = not Config.SpectateActive
                    refresh_drop()
                    
                    if Config.SpectateActive then
                        notificar("Espectando...", 2, "lucide:eye")
                    else
                        notificar("Restaurado", 2, "lucide:eye-off")
                    end
                end
            },
            {
                Title = "Teleportar",
                Desc = "Vai até o jogador",
                Icon = "lucide:plane",
                Callback = function()
                    if Config.TargetPlayer == "" then return end
                    Config.TriggerTeleport = true
                    notificar("Teleportando...", 2, "lucide:plane")
                end
            },
            {
                Title = "Voltar",
                Desc = "Retorna à posição anterior",
                Icon = "lucide:undo-2",
                Callback = function()
                    Config.TriggerReturn = true
                    notificar("Retornando...", 2, "lucide:undo-2")
                end
            }
        }
        
        ActionDrop = IntSection:Dropdown({
            Title = "Ações",
            Icon = "lucide:mouse-pointer-click",
            Values = acts,
            Value = "Selecione"
        })
    end
    
    refresh_drop()
end

--// tab configs

local GerenciadorConfig = main.ConfigManager
local NomeConfig = ""
local ConfigSelecionada = nil
local DropdownListaConfig = nil

local function AtualizarListaConfig()
    local configs = GerenciadorConfig:AllConfigs()
    if DropdownListaConfig then
        DropdownListaConfig:Refresh(configs)
    end
end

local CreationSection = criarsection(Configs, "Criação", "Criar configuração", "lucide:file-plus", true)

CreationSection:Input({
    Title = "Nome da configuração",
    Desc = cor({"Dê um "}, {"nome", "#FFFFFF"}, {" para o arquivo"}),
    Value = "",
    Placeholder = "Digite aqui...",
    InputIcon = "lucide:pencil",
    Type = "Input",
    Callback = function(texto)
        NomeConfig = texto
    end
})

CreationSection:Button({
    Title = "Criar configuração",
    Desc = cor({"Salva", "#00FF00"}, {" o estado atual das funções"}),
    Icon = "lucide:save-all",
    Callback = function()
        if NomeConfig ~= "" then
            local cfg = GerenciadorConfig:CreateConfig(NomeConfig)
            cfg:Save()
            notificar("Salvo como " .. NomeConfig, 3, "lucide:check")
            AtualizarListaConfig()
        else
            notificar("Digite um nome válido", 3, "lucide:x")
        end
    end
})

local ManagementSection = criarsection(Configs, "Gerenciamento", "Gerenciar configurações", "lucide:folder-open", true)

DropdownListaConfig = ManagementSection:Dropdown({
    Title = "Selecionar arquivo",
    Desc = cor({"Escolha a "}, {"configuração", "#00AAFF"}, {" alvo"}),
    Icon = "lucide:folder",
    Values = GerenciadorConfig:AllConfigs(),
    Value = "Nenhuma",
    Callback = function(val)
        ConfigSelecionada = val
    end
})

ManagementSection:Dropdown({
    Title = "Ações",
    Desc = cor({"Executa uma "}, {"ação", "#FFAA00"}, {" no arquivo selecionado"}),
    Icon = "lucide:settings-2",
    Values = {
        {
            Title = "Carregar",
            Desc = cor({"Carrega", "#00FF00"}, {" os dados salvos"}),
            Icon = "lucide:upload",
            Callback = function()
                if ConfigSelecionada and ConfigSelecionada ~= "Nenhuma" then
                    local cfg = GerenciadorConfig:CreateConfig(ConfigSelecionada)
                    cfg:Load()
                    notificar("Carregado: " .. ConfigSelecionada, 3, "lucide:check")
                else
                    notificar("Nenhuma configuração selecionada", 3, "lucide:x")
                end
            end
        },
        {
            Title = "Sobrescrever",
            Desc = cor({"Substitui", "#FFAA00"}, {" os dados deste arquivo"}),
            Icon = "lucide:refresh-cw",
            Callback = function()
                if ConfigSelecionada and ConfigSelecionada ~= "Nenhuma" then
                    local cfg = GerenciadorConfig:CreateConfig(ConfigSelecionada)
                    cfg:Save()
                    notificar("Alterado: " .. ConfigSelecionada, 3, "lucide:check")
                else
                    notificar("Nenhuma configuração selecionada", 3, "lucide:x")
                end
            end
        },
        {
            Type = "Divider",
        },
        {
            Title = "Deletar arquivo",
            Desc = cor({"Apaga", "#FF0000"}, {" permanentemente o registro"}),
            Icon = "lucide:trash-2",
            Callback = function()
                if ConfigSelecionada and ConfigSelecionada ~= "Nenhuma" then
                    local cfg = GerenciadorConfig:CreateConfig(ConfigSelecionada)
                    cfg:Delete()
                    notificar("Deletado: " .. ConfigSelecionada, 3, "lucide:trash")
                    AtualizarListaConfig()
                    ConfigSelecionada = "Nenhuma"
                    DropdownListaConfig:Select("Nenhuma")
                else
                    notificar("Nenhuma configuração selecionada", 3, "lucide:x")
                end
            end
        },
        {
            Title = "Atualizar lista",
            Desc = cor({"Recarrega", "#00AAFF"}, {" a lista de arquivos"}),
            Icon = "lucide:rotate-ccw",
            Callback = function()
                AtualizarListaConfig()
                notificar("Lista atualizada", 2, "lucide:check")
            end
        }
    }
})

--// ativar e desativar UI
local SecretWord = "/e" 
local KeybindKey = Enum.KeyCode.Z 
local ChatConnection = nil
local KeybindConnection = nil 

local function setupChatToggle()
    if ChatConnection then
        ChatConnection:Disconnect()
        ChatConnection = nil
    end

    ChatConnection = LocalPlayer.Chatted:Connect(function(msg)
        if msg == SecretWord then
            main:Toggle()
        end
    end)
end

setupChatToggle()

local function setupKeybind(isUpdate)
    if KeybindConnection then
        KeybindConnection:Disconnect()
        KeybindConnection = nil
    end

    KeybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == KeybindKey then
            main:Toggle()
        end
    end)
    
    if isUpdate then
        notificar("Keybind: " .. tostring(KeybindKey), 3, "lucide:keyboard")
    end
end

setupKeybind(false)

local InterfaceSection = criarsection(Configs, "Interface", "Opções da UI", "lucide:monitor", false)

InterfaceSection:Toggle({
    Title = "Botão UI",
    Desc = cor({"Ativa", "#00FF00"}, {" o botão flutuante ao "}, {"minimizar", "#FFAA00"}),
    Icon = "lucide:check",
    IconColor = "Green",
    Type = "Checkbox",
    Value = true,
    Callback = function(state)
    main:EditOpenButton({
    Title = "",
    Icon = "rbxthumb://type=Asset&id=137064182739714&w=420&h=420",
    CornerRadius = UDim.new(10, 10),
    StrokeThickness = 1,
    Color = ColorSequence.new(
        Color3.fromHex("#282828"), 
        Color3.fromHex("#FFFFFF")
    ),
    OnlyMobile = false,
    Enabled = state,
    Draggable = true,
})
    end
})

InterfaceSection:Input({
    Title = "Palavra secreta",
    Desc = cor({"Usa o "}, {"chat", "#FFFFFF"}, {" para abrir a UI"}),
    Placeholder = "/e",
    InputIcon = "lucide:message-square",
    Flag = "PalavraSecreta",
    Callback = function(v)
        if v == "" then return end
        local has_space = string.find(v or "", "%s")
        local is_empty = string.len(v or "") == 0
        
        if not is_empty and not has_space then
            SecretWord = v
            setupChatToggle()
            notificar("Definida para: " .. v, 3, "lucide:check")
        else
            notificar("Texto inválido", 3, "lucide:alert-circle")
            
            SecretWord = "/e"
            setupChatToggle()
            notificar("Resetada para: /e", 3, "lucide:rotate-ccw")
        end
    end
})

InterfaceSection:Input({
    Title = "Keybind",
    Desc = cor({"Define a tecla para "}, {"abrir/fechar", "#FFFFFF"}, {" a interface"}),
    Flag = "KeybindUI",
    InputIcon = "lucide:keyboard",
    Placeholder = "Z",
    Callback = function(v)
        local keyName = string.upper(string.gsub(v or "", "%s+", ""))

        if string.len(keyName) == 0 then
            return
        end

        local success, newKeybind = pcall(function()
            return Enum.KeyCode[keyName]
        end)

        if success and newKeybind then
            KeybindKey = newKeybind
            setupKeybind(true)
        else
            notificar("Tecla inválida", 3, "lucide:x")
        end
    end
})

local ThemeSection = criarsection(Configs, "Temas", "Customize a UI", "lucide:palette", false)

local function GetThemeList()
    local themes = UI:GetThemes() 
    local list = {}
    
    for k, v in pairs(themes) do
        local themeName
        if type(k) == "string" then
            themeName = k 
        elseif type(v) == "string" then
            themeName = v
        end
        
        if themeName then
            table.insert(list, {
                Title = themeName,
                Desc = cor({"Tema "}, {themeName, "#00AAFF"}),
                Icon = "lucide:paintbrush",
            })
        end
    end
    
    table.sort(list, function(a, b) return a.Title < b.Title end)
    
    return list
end

ThemeSection:Dropdown({
    Title = "Temas",
    Desc = cor({"Escolha o "}, {"tema", "#FFFFFF"}, {" da interface"}),
    Icon = "lucide:palette",
    Values = GetThemeList(),
    Flag = "Tema",
    Callback = function(val)
        local themeName = (type(val) == "table" and val.Title) or val
        if themeName then
            UI:SetTheme(themeName)
            notificar("Aplicado " .. themeName, 2, "lucide:check")
        end
    end
})

--// mapas 
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
    criarsection(main, "Mapa", "Exclusivos do mapa", "lucide:compass", true)

    if MapaAtual == "Tevez" then
        local TevezTab = criartab("Tevez", "https://tr.rbxcdn.com/180DAY-84c7c1edcc63c7dfab5712b1ad377133/768/432/Image/Webp/noFilter")

        local LocalSection = criarsection(TevezTab, "Local", "Chat", "lucide:message-circle", true)
        LocalSection:Input({
            Title = "Mensagem",
            Desc = cor({"Digite o "}, {"texto", "#FFFFFF"}, {" para enviar no chat"}),
            Value = "",
            InputIcon = "lucide:text-cursor",
            Placeholder = "Digite aqui...",
            Callback = function(Value) 
                if _G.TevezMods then _G.TevezMods.ChatMessage = Value end
            end
        })
        LocalSection:Toggle({
            Title = "Spam",
            Desc = cor({"Envia a mensagem "}, {"várias vezes", "#FFAA00"}),
            Icon = "lucide:repeat",
            Value = false,
            Callback = function(state) 
                if _G.TevezMods and _G.TevezMods.ToggleSpam then _G.TevezMods.ToggleSpam(state) end
            end
        })
        LocalSection:Button({
            Title = "Enviar",
            Desc = cor({"Manda", "#00FF00"}, {" a mensagem atual"}),
            Color = "Green",
            Icon = "lucide:send",
            Callback = function()
                if _G.TevezMods and _G.TevezMods.SendMessage then _G.TevezMods.SendMessage() end
            end
        })
        
        local SpooferSection = criarsection(TevezTab, "Spoofer", "Alterar dispositivo", "lucide:smartphone", false)
        SpooferSection:Paragraph({
            Title = "Spoofer",
            Desc = cor({"O "}, {"spoofer", "#00AAFF"}, {" permite você alterar o dispositivo para todos"})
        })
        SpooferSection:Dropdown({
            Title = "Dispositivo",
            Desc = cor({"Selecione o "}, {"dispositivo", "#FFFFFF"}),
            Icon = "lucide:laptop",
            Values = { "Mobile", "Computer" },
            Value = "Computer",
            Callback = function(option)
                if _G.TevezMods then _G.TevezMods.SelectedDevice = option end
            end
        })
        SpooferSection:Toggle({
            Title = "Ativar",
            Desc = cor({"Altera", "#00FF00"}, {" o dispositivo (reseta o personagem)"}),
            Icon = "lucide:power",
            Value = false,
            Callback = function(v)
                if _G.TevezMods and _G.TevezMods.ToggleSpoof then _G.TevezMods.ToggleSpoof(v) end
            end
        })
        SpooferSection:Space()

        SpooferSection:Dropdown({
            Title = "AFK",
            Desc = cor({"Permite "}, {"ativar", "#00FF00"}, {" ou "}, {"desativar", "#FF0000"}, {" o "}, {"AFK", "#FFAA00"}),
            Icon = "lucide:coffee",
            Values = { "Ativar", "Desativar" },
            Value = "Desativar",
            Callback = function(option)
                if _G.TevezMods and _G.TevezMods.SetAFK then _G.TevezMods.SetAFK(option == "Ativar") end
            end
        })
        
        local FarmSection = criarsection(TevezTab, "Autofarm", "Farm do banco", "lucide:banknote", false)
        
        local StatusParagraph = FarmSection:Paragraph({
            Title = "Status",
            Desc = "Aguardando...",
            Color = "Green",
            Image = "lucide:activity"
        })
        
        task.spawn(function()
            repeat task.wait(0.5) until _G.TevezAutoFarm
            _G.TevezAutoFarm.UpdateCallback = function(msg, money)
                if StatusParagraph then
                    StatusParagraph:SetDesc(cor({msg, "#AAAAAA"}) .. cor({"\n💰 Farmado: R$ ", "#AAAAAA"}, {tostring(money), "#00FF00"}))
                end
            end
        end)

        FarmSection:Toggle({
            Title = "Ativar",
            Desc = cor({"Inicia", "#00FF00"}, {" o autofarm"}),
            Icon = "lucide:play",
            Value = false,
            Callback = function(v)
                if _G.TevezAutoFarm then _G.TevezAutoFarm.Toggle(v) end
            end
        })
        
        FarmSection:Toggle({
            Title = "Modo seguro",
            Desc = cor({"Pausa", "#FF0000"}, {" se houver jogadores por perto"}),
            Icon = "lucide:shield-check",
            Value = false,
            Flag = "ModoSeguroAutofarmTevez",
            Callback = function(v)
                if _G.TevezAutoFarm then _G.TevezAutoFarm.SafeMode = v end
            end
        })
        
        FarmSection:Input({
            Title = "Raio de segurança",
            Desc = cor({"Distância para "}, {"detectar", "#FF0000"}, {" se há alguém por perto"}),
            Placeholder = "60",
            InputIcon = "lucide:radio",
            Flag = "RaioDeSegurancaAutofarmTevez",
            Callback = function(v)
                local n = tonumber(v)
                if n and _G.TevezAutoFarm then _G.TevezAutoFarm.SafeRadius = n end
            end
        })

        local CombatSection = criarsection(TevezTab, "Combate", "Kill aura", "lucide:swords", false)
        CombatSection:Paragraph({
            Title = "Kill aura",
            Image = "lucide:triangle-alert",
            Color = Color3.fromHex("#FF1D0D"),
            Desc = cor({"Risco.", "#FF0000"}, {" Você será banido caso alguém te denuncie"})
        })
        local KillAuraToggle
        CombatSection:Toggle({
            Title = "Permitir",
            Desc = cor({"Libera", "#00FF00"}, {" o uso do kill-aura"}),
            Icon = "lucide:lock-open",
            Value = false,
            Callback = function(state)
                if state then
                    if KillAuraToggle then KillAuraToggle:Unlock() end
                    notificar("Permissão concedida", 2, "lucide:key")
                else
                    if KillAuraToggle then 
                        KillAuraToggle:Set(false)
                        KillAuraToggle:Lock() 
                    end
                    notificar("Permissão negada", 2, "lucide:key")
                end
            end
        })
        KillAuraToggle = CombatSection:Toggle({
            Title = "Kill aura",
            Desc = cor({"Mata", "#FF0000"}, {" jogadores próximos"}),
            Icon = "lucide:skull",
            Value = false,
            Callback = function(state)
                if _G.TevezMods and _G.TevezMods.ToggleAura then
                    _G.TevezMods.ToggleAura(state, KillAuraToggle)
                end
            end
        })
        if KillAuraToggle then KillAuraToggle:Lock() end

        local ShopSection = criarsection(TevezTab, "Loja", "Comprar itens", "lucide:shopping-bag", false)
        local ItensLoja = { ["AK-47"] = 15000, ["MPT-76"] = 8500, ["UZI"] = 8200, ["M4A1"] = 13000, ["GLOCK 18"] = 4300, ["Colete"] = 15000 }
        local DropdownValues = {}
        local DisplayToItem = {}
        for nome, preco in pairs(ItensLoja) do
            local display = nome .. " - $" .. preco
            table.insert(DropdownValues, display)
            DisplayToItem[display] = nome
        end
        ShopSection:Dropdown({
            Title = "Comprar itens",
            Desc = cor({"Seleciona um "}, {"item", "#FFFFFF"}, {" na loja"}),
            Icon = "lucide:tag",
            Values = DropdownValues,
            Value = "GLOCK 18 - $4300",
            Callback = function(option)
                if _G.TevezMods then _G.TevezMods.SelectedShopItem = DisplayToItem[option] end
            end
        })
        ShopSection:Button({
            Title = "Comprar",
            Desc = cor({"Compra", "#00FF00"}, {" o item selecionado"}),
            Icon = "lucide:credit-card",
            Callback = function()
                if _G.TevezMods and _G.TevezMods.BuyItem then _G.TevezMods.BuyItem() end
            end
        })

        local ModsSection = criarsection(TevezTab, "Mods", "Modifica a arma", "lucide:hammer", false)
        ModsSection:Input({
            Title = "Bullets",
            Desc = cor({"Quantidade de "}, {"balas", "#00AAFF"}, {" por disparo"}),
            Placeholder = "Valor",
            InputIcon = "lucide:hash",
            Flag = "BalasTevez",
            Callback = function(v)
                if v == "" then return end
                if _G.TevezMods then _G.TevezMods.GunConfig.Bullets = tonumber(v) end
            end
        })
        ModsSection:Input({
            Title = "Spread",
            Desc = cor({"Muda o "}, {"espalhamento", "#FFAA00"}),
            Placeholder = "Valor",
            InputIcon = "lucide:expand",
            Flag = "SpreadTevez",
            Callback = function(v)
                if v == "" then return end
                if _G.TevezMods then _G.TevezMods.GunConfig.Spread = tonumber(v) end
            end
        })
        ModsSection:Input({
            Title = "Range",
            Desc = cor({"O quão "}, {"longe", "#00AAFF"}, {" as balas vão"}),
            Placeholder = "Valor",
            InputIcon = "lucide:target",
            Flag = "RangeTevez",
            Callback = function(v)
                if v == "" then return end
                if _G.TevezMods then _G.TevezMods.GunConfig.Range = tonumber(v) end
            end
        })
        ModsSection:Button({
            Title = "Aplicar mods",
            Desc = cor({"Muda", "#00FF00"}, {" os atributos da arma"}),
            Icon = "lucide:check-circle",
            Callback = function()
                if _G.TevezMods and _G.TevezMods.ApplyGunMods then _G.TevezMods.ApplyGunMods() end
            end
        })

    elseif MapaAtual == "Christian" then
        local ChristianTab = criartab("Christian", "https://tr.rbxcdn.com/180DAY-048e9d153b3fd43e5ee5207b61b810f7/768/432/Image/Webp/noFilter")

if not getgenv().ChristianSpooferConfig then
    getgenv().ChristianSpooferConfig = {
        Enabled = false,
        Device = "Pc"
    }
end

if not getgenv().ChristianSpooferHooked then
    getgenv().ChristianSpooferHooked = true
    
    local OldNameCall
    OldNameCall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if not checkcaller() and method == "FireServer" then
            if tostring(self) == "Dispositivo" and getgenv().ChristianSpooferConfig.Enabled then
                local args = {...}
                args[1] = getgenv().ChristianSpooferConfig.Device 
                return OldNameCall(self, unpack(args))
            end
        end
        
        return OldNameCall(self, ...)
    end))
end

local Spoofer = criarsection(ChristianTab, "Dispositivo", "Modificar dispositivo", "lucide:phone", true)

Spoofer:Paragraph({
    Title = "Spoofer",
    Desc = cor({"O "}, {"spoofer", "#00AAFF"}, {" permite você alterar o dispositivo para todos"})
})

Spoofer:Dropdown({
    Title = "Dispositivo",
    Desc = cor({"Selecione o "}, {"dispositivo", "#FFFFFF"}),
    Icon = "lucide:laptop",
    Values = { "Celular", "PC" },
    Value = "Celular",
    Callback = function(option)
        if option == "PC" then
            getgenv().ChristianSpooferConfig.Device = "Pc"
        elseif option == "Celular" then
            getgenv().ChristianSpooferConfig.Device = "Mobile"
        else
            getgenv().ChristianSpooferConfig.Device = option
        end
    end
})

Spoofer:Toggle({
    Title = "Ativar",
    Desc = cor({"Altera", "#00FF00"}, {" o dispositivo (reseta o personagem)"}),
    Icon = "lucide:power",
    Value = false,
    Callback = function(v)
        getgenv().ChristianSpooferConfig.Enabled = v
        
        if v and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid.Health = 0
            end
        end
    end
})

    elseif MapaAtual == "Delta" then
        local DeltaTab = criartab("Delta", "https://tr.rbxcdn.com/180DAY-8952e9d8abbff8104b22356f8b66f962/768/432/Image/Webp/noFilter")

     if type(notificar) == "function" then
    getgenv().notificar = notificar
end

local CombatSection = criarsection(DeltaTab, "Combate", "Kill aura", "lucide:swords", false)

CombatSection:Toggle({
    Title = "Kill aura",
    Desc = cor({"Mata", "#FF0000"}, {" todos os inimigos ao redor"}),
    Icon = "lucide:skull",
    Value = false,
    Callback = function(state)
        if getgenv().DeltaLogic then 
            getgenv().DeltaLogic.KillAuraAtiva = state 
        end
    end
})


local JJSection = criarsection(DeltaTab, "Polichinelos", "Modificar", "lucide:activity", true)

JJSection:Input({
    Title = "Quantidade",
    Desc = cor({"Valor para "}, {"adicionar ou remover", "#FFFFFF"}),
    Placeholder = "10",
    InputIcon = "lucide:hash",
    Callback = function(v)
        if getgenv().DeltaLogic then getgenv().DeltaLogic.JJValue = v:gsub("%D", "") end
    end
})

JJSection:Button({
    Title = "Modificar",
    Desc = cor({"Muda", "#00FF00"}, {" seus polichinelos"}),
    Icon = "lucide:edit-2",
    Callback = function()
        if getgenv().DeltaLogic and getgenv().DeltaLogic.SetJJ then getgenv().DeltaLogic.SetJJ() end
    end
})

local EcoSection = criarsection(DeltaTab, "Economia", "Dinheiro", "lucide:coins", false)

EcoSection:Input({
    Title = "Quantidade",
    Desc = cor({"Valor para receber"}),
    Placeholder = "1000000",
    InputIcon = "lucide:circle-dollar-sign",
    Callback = function(v)
        if getgenv().DeltaLogic then getgenv().DeltaLogic.GetRichValue = v:gsub("%D", "") end
    end
})

EcoSection:Button({
    Title = "Money",
    Desc = cor({"Pega", "#00FF00"}, {" o dinheiro"}),
    Icon = "lucide:gem",
    Callback = function()
        if getgenv().DeltaLogic and getgenv().DeltaLogic.GetRich then getgenv().DeltaLogic.GetRich() end
    end
})

    elseif MapaAtual == "Soucre" then
        local SoucreTab = criartab("Soucre", "https://tr.rbxcdn.com/180DAY-9b65f927dea36f98c1a720694fd00fd3/768/432/Image/Webp/noFilter")

local FarmSection = criarsection(SoucreTab, "Entregador", "Autofarm", "lucide:banknote-arrow-up", true)

local MoneyPara = FarmSection:Paragraph({
    Title = "Status",
    Desc = "Dinheiro farmado: $0",
    Color = "Green",
    Image = "lucide:coins"
})

task.spawn(function()
    repeat task.wait(0.5) until getgenv().SoucreLogic
    getgenv().SoucreLogic.UpdateCallback = function(val)
        if MoneyPara then 
            MoneyPara:SetDesc(cor({"Dinheiro farmado: ", "#AAAAAA"}, {"$", "#00FF00"}, {tostring(val), "#00FF00"})) 
        end
    end
end)

FarmSection:Toggle({
    Title = "Autofarm",
    Desc = cor({"Inicia", "#00FF00"}, {" o autofarm"}),
    Icon = "lucide:circle-play",
    Value = false,
    Callback = function(v)
        if getgenv().SoucreLogic then getgenv().SoucreLogic.Toggle(v) end
    end
})

    elseif MapaAtual == "NovaEra" then
        local NovaEraTab = criartab("Nova Era", "https://tr.rbxcdn.com/180DAY-9b65f927dea36f98c1a720694fd00fd3/768/432/Image/Webp/noFilter")

local FarmSection = criarsection(NovaEraTab, "Dinheiro", "Autofarm", "lucide:coins", true)

local MoneyPara = FarmSection:Paragraph({
    Title = "Status",
    Desc = "Dinheiro farmado: $0",
    Color = "Green",
    Image = "lucide:coins"
})

task.spawn(function()
    repeat task.wait(0.5) until getgenv().NovaEraLogic
    getgenv().NovaEraLogic.UpdateCallback = function(val)
        if MoneyPara then 
            MoneyPara:SetDesc(cor({"Dinheiro farmado: ", "#AAAAAA"}, {"$", "#00FF00"}, {tostring(val), "#00FF00"})) 
        end
    end
end)

FarmSection:Dropdown({
    Title = "Modo",
    Values = {"Lixeiro", "Barbeiro"},
    Value = "Lixeiro",
    Callback = function(v)
        if getgenv().NovaEraLogic and getgenv().NovaEraLogic.SetMode then
            getgenv().NovaEraLogic.SetMode(v)
        end
    end
})

FarmSection:Toggle({
    Title = "Autofarm",
    Desc = cor({"Inicia", "#00FF00"}, {" o autofarm de coleta"}),
    Icon = "lucide:circle-play",
    Value = false,
    Callback = function(v)
        if getgenv().NovaEraLogic and getgenv().NovaEraLogic.Toggle then 
            getgenv().NovaEraLogic.Toggle(v) 
        end
    end
})    

elseif MapaAtual == "Apex" then
        local ApexTab = criartab("Apex", "https://tr.rbxcdn.com/180DAY-9b65f927dea36f98c1a720694fd00fd3/768/432/Image/Webp/noFilter")

        ApexTab:Button({
        Title     = "Invadir base",
        Desc      = "Autoexplicativo",
        Icon      = "lucide:log-in",
        IconAlign = "Left",
        Locked    = not JD_IS_PREMIUM,
        LockedTitle = "Premium",
        Callback  = function()
        if getgenv().IniciarRota then
            getgenv().IniciarRota()
        end
    end
})

    local Mods    = criarsection(ApexTab, "Modificações", "Modificações de arma", "lucide:chevrons-left-right-ellipsis", false)
    local TrollTab = criarsection(ApexTab, "Troll", "Funções de troll", "https://pngfre.com/wp-content/uploads/1000117874.png", true)

    Mods:Toggle({
    Title    = "Bala infinita",
    Desc     = cor({"Congela", "#00FF00"}, {" a munição da arma"}),
    Icon     = "lucide:infinity",
    Flag     = "ApexBalaInfinita",
    Value    = false,
    Callback = function(v)
        if v then
            if getgenv()._InfiniteAmmoConn then
                getgenv()._InfiniteAmmoConn:Disconnect()
            end
            if getgenv()._InfiniteAmmoAddedConn then
                getgenv()._InfiniteAmmoAddedConn:Disconnect()
            end

            local function forcar(parent)
                if not parent then return end
                for _, tool in ipairs(parent:GetChildren()) do
                    if tool:IsA("Tool") and #tool:GetDescendants() > 5 then
                        local ammo = tool:FindFirstChild("Ammo")
                        if ammo then ammo.Value = ammo.MaxValue end
                    end
                end
            end

            getgenv()._InfiniteAmmoConn = RunService.Heartbeat:Connect(function()
                forcar(LocalPlayer:FindFirstChild("Backpack"))
                forcar(LocalPlayer.Character)
            end)

            getgenv()._InfiniteAmmoAddedConn = LocalPlayer.Backpack.ChildAdded:Connect(function(tool)
                task.wait(0.1)
                if tool:IsA("Tool") and #tool:GetDescendants() > 5 then
                    local ammo = tool:FindFirstChild("Ammo")
                    if ammo then ammo.Value = ammo.MaxValue end
                end
            end)
        else
            if getgenv()._InfiniteAmmoConn then
                getgenv()._InfiniteAmmoConn:Disconnect()
                getgenv()._InfiniteAmmoConn = nil
            end
            if getgenv()._InfiniteAmmoAddedConn then
                getgenv()._InfiniteAmmoAddedConn:Disconnect()
                getgenv()._InfiniteAmmoAddedConn = nil
            end
        end
    end
})

        TrollTab:Toggle({
            Title    = "Spammar sons",
            Desc     = cor({"Precisa", "#FF0000"}, {" de uma arma."}, {" Esses sons tocam para todos.", "#03F916"}),
            Icon     = "lucide:audio-lines",
            Value    = false,
            Callback = function(v)
                if getgenv().ApexLogic and getgenv().ApexLogic.ToggleSound then
                    getgenv().ApexLogic.ToggleSound(v)
                end
            end
        })
    end
end


-- ===== combate.lua ===== --
task.spawn(function()
-- apex
if game.PlaceId == 2069320852 then
    local oldFireServer
    oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(remote, ...)
        if remote.Name ~= "ClientKick" then
            return oldFireServer(remote, ...)
        end
        if select(1, ...) == "HitBox" then
            return
        end
        return oldFireServer(remote, ...)
    end)
end

-- servicos
local cr         = cloneref or function(o) return o end
local Players    = cr(game:GetService("Players"))
local RunService = cr(game:GetService("RunService"))
local CoreGui    = cr(game:GetService("CoreGui"))
local HttpService = cr(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer

-- FIX: em vez de getgenv(), usa uma tabela local como namespace
-- Ofuscadores quebram getgenv() ao envolver o script em closures
local env = getgenv()

local function safeGui()
    local ok, hui = pcall(gethui)
    return (ok and hui) and hui or CoreGui
end

local function isShielded(character)
    if not character then return false end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            if name:find("escudo") or name:find("shield") then
                return true
            end
        end
    end
    return false
end


-- hb
local hitboxSaved  = {}
local hitboxLights = {}

local function hitboxConfig()
    return getgenv().HitboxConfig
end

local function hitboxShouldTarget(player)
    local cfg = hitboxConfig()
    if not cfg or not cfg.Enabled then return false end
    if player == LocalPlayer then return false end
    if table.find(cfg.WhitelistedUsers, player.Name) then return false end
    if player.Team and table.find(cfg.WhitelistedTeams, player.Team.Name) then return false end
    if cfg.FocusMode and not table.find(cfg.FocusList, player.Name) then return false end
    if cfg.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
    if cfg.TeamFilterEnabled and #cfg.SelectedTeams > 0 then
        local playerTeam = player.Team and player.Team.Name or ""
        local allowed = false
        for _, team in ipairs(cfg.SelectedTeams) do
            if team == playerTeam then allowed = true; break end
        end
        if not allowed then return false end
    end

    local char = player.Character
    if not char then return false end
    local hum  = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return false end
    if cfg.HideOnShield and isShielded(char) then return false end

    return true
end

local function hitboxSaveState(player, root)
    if hitboxSaved[player] then return end
    hitboxSaved[player] = {
        size         = root.Size,
        transparency = root.Transparency,
        shape        = root.Shape,
        canCollide   = root.CanCollide,
        material     = root.Material,
        color        = root.Color,
    }
end

local function hitboxRestoreState(player)
    local saved = hitboxSaved[player]
    if not saved then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.Size         = saved.size
        root.Transparency = saved.transparency
        root.Shape        = saved.shape
        root.CanCollide   = saved.canCollide
        root.Material     = saved.material
        root.Color        = saved.color
    end
    hitboxSaved[player] = nil
end

local function hitboxRemoveHighlight(player)
    if hitboxLights[player] then
        hitboxLights[player]:Destroy()
        hitboxLights[player] = nil
    end
end

local function hitboxCleanPlayer(player)
    hitboxRestoreState(player)
    hitboxRemoveHighlight(player)
end

local function hitboxApply(player, root, cfg)
    local teamColor = (player.TeamColor and player.TeamColor.Color) or Color3.new(1, 0, 0)

    root.Size         = cfg.Size
    root.Transparency = cfg.Transparency
    root.Shape        = cfg.Shape
    root.CanCollide   = false
    root.Material     = Enum.Material.ForceField

    if cfg.Transparency < 1 then
        if not hitboxLights[player] then
            local hl = Instance.new("Highlight")
            hl.Name                = HttpService:GenerateGUID(false)
            hl.Adornee             = root
            hl.FillColor           = teamColor
            hl.FillTransparency    = cfg.Transparency
            hl.OutlineTransparency = cfg.Transparency
            hl.Parent              = safeGui()
            hitboxLights[player]   = hl
        else
            local hl = hitboxLights[player]
            hl.Adornee             = root
            hl.FillColor           = teamColor
            hl.FillTransparency    = cfg.Transparency
            hl.OutlineTransparency = cfg.Transparency
        end
    else
        hitboxRemoveHighlight(player)
    end
end

RunService.Heartbeat:Connect(function()
    local cfg = hitboxConfig()

    if not cfg or not cfg.Enabled then
        for player in pairs(hitboxSaved) do hitboxCleanPlayer(player) end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if hitboxShouldTarget(player) then
            local root = player.Character.HumanoidRootPart
            hitboxSaveState(player, root)
            hitboxApply(player, root, cfg)
        else
            hitboxCleanPlayer(player)
        end
    end
end)

Players.PlayerRemoving:Connect(hitboxCleanPlayer)


-- esp
env.espConns = env.espConns or {}
env.espStore = env.espStore or {}
env.espHold  = env.espHold  or nil

env.ESPConfig = env.ESPConfig or {
    Enabled  = false,
    TeamCheck = false,
    Chams    = false,
    Name     = false,
    Studs    = false,
    Health   = false,
    WeaponN  = false,
}

local function espGetContainer()
    if not env.espHold or not env.espHold.Parent then
        local folder = Instance.new("Folder")
        folder.Name   = HttpService:GenerateGUID(false)
        folder.Parent = safeGui()
        env.espHold   = folder
    end
    return env.espHold
end

local function espMakeLabel(parent, order, color, size)
    local label = Instance.new("TextLabel")
    label.Parent                 = parent
    label.BackgroundTransparency = 1
    label.Size                   = UDim2.new(1, 0, 0, size or 12)
    label.TextColor3             = color or Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3       = Color3.new(0, 0, 0)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = size or 12
    label.LayoutOrder            = order
    label.Visible                = false
    return label
end

local function espAddPlayer(player)
    if not player or player == LocalPlayer or env.espStore[player] then return end

    local container = espGetContainer()
    local entry = {
        highlight = Instance.new("Highlight"),
        billboard = Instance.new("BillboardGui"),
        labels    = {},
    }

    -- hl
    local hl = entry.highlight
    hl.Name                = HttpService:GenerateGUID(false)
    hl.FillColor           = Color3.new(1, 0, 0)
    hl.OutlineColor        = Color3.new(1, 1, 1)
    hl.FillTransparency    = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled             = false
    hl.Parent              = container

    -- gui
    local bb = entry.billboard
    bb.Name        = HttpService:GenerateGUID(false)
    bb.Size        = UDim2.new(0, 200, 0, 60)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.Enabled     = false
    bb.Parent      = container

    local layout = Instance.new("UIListLayout")
    layout.Parent              = bb
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding             = UDim.new(0, 0)

    entry.labels.name   = espMakeLabel(bb, 1, Color3.new(1, 1, 1), 13)
    entry.labels.health = espMakeLabel(bb, 2, Color3.fromRGB(0, 255, 100), 11)
    entry.labels.weapon = espMakeLabel(bb, 3, Color3.fromRGB(200, 200, 200), 11)
    entry.labels.studs  = espMakeLabel(bb, 4, Color3.fromRGB(255, 220, 0), 11)

    env.espStore[player] = entry
end

local function espRemovePlayer(player)
    local entry = env.espStore[player]
    if not entry then return end
    if entry.highlight then entry.highlight:Destroy() end
    if entry.billboard then entry.billboard:Destroy() end
    env.espStore[player] = nil
end

local function espUpdate()
    local cfg   = env.ESPConfig
    local lchar = LocalPlayer.Character
    local lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")

    for player, entry in pairs(env.espStore) do
        if not player or not player.Parent then
            espRemovePlayer(player)
        else
            local char  = player.Character
            local root  = char and char:FindFirstChild("HumanoidRootPart")
            local hum   = char and char:FindFirstChild("Humanoid")
            local head  = char and char:FindFirstChild("Head")
            local alive = char and root and hum and hum.Health > 0 and head
            local sameTeam = cfg.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team

            if not alive or sameTeam then
                entry.highlight.Enabled = false
                entry.billboard.Enabled = false
            else
                -- chams
                if cfg.Chams then
                    entry.highlight.Adornee   = char
                    entry.highlight.FillColor = (player.TeamColor and player.TeamColor.Color) or Color3.new(1, 0, 0)
                    entry.highlight.Enabled   = true
                else
                    entry.highlight.Enabled = false
                end

                -- labels
                local showBillboard = cfg.Name or cfg.Health or cfg.WeaponN or cfg.Studs
                if showBillboard then
                    entry.billboard.Adornee = head
                    entry.billboard.Enabled = true

                    -- nome
                    local lblName = entry.labels.name
                    if cfg.Name then
                        lblName.Text    = player.Name
                        lblName.Visible = true
                    else
                        lblName.Visible = false
                    end

                    -- vida
                    local lblHealth = entry.labels.health
                    if cfg.Health then
                        local hp = math.floor(hum.Health)
                        lblHealth.Text       = tostring(hp)
                        lblHealth.TextColor3 = Color3.fromRGB(255, 50, 50):Lerp(Color3.fromRGB(50, 255, 50), hp / hum.MaxHealth)
                        lblHealth.Visible    = true
                    else
                        lblHealth.Visible = false
                    end

                    -- item
                    local lblWeapon = entry.labels.weapon
                    if cfg.WeaponN then
                        local tool = char:FindFirstChildOfClass("Tool")
                        lblWeapon.Text    = tool and tool.Name or ""
                        lblWeapon.Visible = tool ~= nil
                    else
                        lblWeapon.Visible = false
                    end

                    -- dist
                    local lblStuds = entry.labels.studs
                    if cfg.Studs then
                        local dist = lroot and (lroot.Position - root.Position).Magnitude or 0
                        lblStuds.Text    = string.format("[%d]", math.floor(dist))
                        lblStuds.Visible = true
                    else
                        lblStuds.Visible = false
                    end
                else
                    entry.billboard.Enabled = false
                end
            end
        end
    end
end

-- UI
env.StopESP = function()
    for _, conn in pairs(env.espConns) do conn:Disconnect() end
    table.clear(env.espConns)
    for player in pairs(env.espStore) do espRemovePlayer(player) end
    table.clear(env.espStore)
    if env.espHold then
        env.espHold:Destroy()
        env.espHold = nil
    end
end

env.StartESP = function()
    env.StopESP()
    espGetContainer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then espAddPlayer(player) end
    end
    table.insert(env.espConns, Players.PlayerAdded:Connect(espAddPlayer))
    table.insert(env.espConns, Players.PlayerRemoving:Connect(espRemovePlayer))
    table.insert(env.espConns, RunService.RenderStepped:Connect(espUpdate))
end
end)


-- ===== jogos.lua ===== --
task.spawn(function()
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
                        for i = 1, 50 do
                            if not getgenv().SpamAtivo or not equippedTool or not isReadyToSpam then break end
                            local sound = soundList[rng:NextInteger(1, totalSons)]
                            if sound and sound.Parent then
                                local originalVolume = sound.Volume
                                sound.Volume = 10
                                pcall(fireClient.FireServer, fireClient, sessionToken, "PlaySound", sound, nil)
                                sound.Volume = originalVolume
                            end
                            task.wait()
                        end
                    end
                    task.wait()
                end
            end)
        end
    end
end

end)


-- ===== player.lua ===== --
task.spawn(function()
-- servicos
local cloneref    = cloneref or function(o) return o end
local Players     = cloneref(game:GetService("Players"))
local RunService  = cloneref(game:GetService("RunService"))
local Workspace   = cloneref(game:GetService("Workspace"))
local CoreGui     = cloneref(game:GetService("CoreGui"))
local TextChat    = cloneref(game:GetService("TextChatService"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local env         = getgenv()


local function playerConfig()
    return getgenv().PlayerConfig
end

local function getRootPart(player)
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
    local char = player.Character
    return char and char:FindFirstChild("Humanoid")
end

local function findPlayer(query)
    if not query or query == "" then return nil end
    query = query:lower()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Name:lower():sub(1, #query) == query
            or player.DisplayName:lower():sub(1, #query) == query then
                return player
            end
        end
    end
    return nil
end

-- anonimo
local anonConnections = {}  -- [obj] = connection para TextLabels
local anonMiscConns   = {}  -- array de conexões gerais

local function spoofText(str)
    local cfg = playerConfig()
    if not cfg or not cfg.AnonEnabled or type(str) ~= "string" then return str end

    local fakeName  = cfg.FakeName or "Anônimo"
    local realName  = LocalPlayer.Name
    local realDisplay = LocalPlayer.DisplayName

    if str:find(realName, 1, true) or str:find(realDisplay, 1, true) then
        local function escape(s) return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") end
        str = str:gsub(escape(realName), fakeName)
        str = str:gsub(escape(realDisplay), fakeName)
    end

    return str
end

local function monitorLabel(obj)
    if not obj then return end
    if anonConnections[obj] then return end

    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        local function refresh()
            local cfg = playerConfig()
            if not cfg or not cfg.AnonEnabled then return end
            local spoofed = spoofText(obj.Text)
            if obj.Text ~= spoofed then obj.Text = spoofed end
        end

        refresh()
        anonConnections[obj] = obj:GetPropertyChangedSignal("Text"):Connect(refresh)
    end
end

local function scanGuiLayer(layer)
    if not layer then return end

    for _, obj in ipairs(layer:GetDescendants()) do
        pcall(monitorLabel, obj)
    end

    local conn = layer.DescendantAdded:Connect(function(obj)
        task.wait()
        pcall(monitorLabel, obj)
    end)
    table.insert(anonMiscConns, conn)
end

local function clearAnonConnections()
    for _, conn in pairs(anonConnections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(anonConnections)

    for _, conn in ipairs(anonMiscConns) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(anonMiscConns)
end

local function applyAnonVisuals()
    local cfg = playerConfig()
    if not cfg then return end

    if cfg.AnonEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.DisplayName = cfg.FakeName

                local conn = hum:GetPropertyChangedSignal("DisplayName"):Connect(function()
                    if playerConfig().AnonEnabled and hum.DisplayName ~= playerConfig().FakeName then
                        hum.DisplayName = playerConfig().FakeName
                    end
                end)
                table.insert(anonMiscConns, conn)
            end
            scanGuiLayer(char)
        end

        scanGuiLayer(LocalPlayer:WaitForChild("PlayerGui"))
        pcall(scanGuiLayer, CoreGui)
    else
        clearAnonConnections()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.DisplayName = LocalPlayer.DisplayName end
        end
    end
end

-- invisibilidade
local invisState = { seat = nil, weld = nil }

local function setCharacterTransparency(value)
    local char = LocalPlayer.Character
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
            obj.Transparency = value
        elseif obj:IsA("Decal") then
            obj.Transparency = value
        end
    end
end

local function toggleInvisibility(enable)
    local root = getRootPart(LocalPlayer)
    if not root then return end

    if enable then
        local savedCFrame  = root.CFrame
        local savedCamType = Camera.CameraType

        Camera.CameraType = Enum.CameraType.Scriptable
        root.CFrame = CFrame.new(-25.95, 84, 3537.55)
        task.wait(0.15)

        local seat = Instance.new("Seat")
        seat.Name        = HttpService:GenerateGUID(false)
        seat.Transparency = 1
        seat.CanCollide  = false
        seat.Anchored    = false
        seat.Position    = Vector3.new(-25.95, 84, 3537.55)
        seat.Parent      = Workspace

        local weld   = Instance.new("Weld")
        weld.Part0   = seat
        weld.Part1   = LocalPlayer.Character:FindFirstChild("Torso")
                    or LocalPlayer.Character:FindFirstChild("UpperTorso")
        weld.Parent  = seat

        invisState.seat = seat
        invisState.weld = weld

        task.wait()
        seat.CFrame       = savedCFrame
        Camera.CameraType = savedCamType

        setCharacterTransparency(0.5)
    else
        if invisState.seat then invisState.seat:Destroy() end
        invisState.seat = nil
        invisState.weld = nil
        setCharacterTransparency(0)
    end
end

-- fling
local flingState = { connection = nil, startCFrame = nil }

local function stopFling(restorePosition)
    if flingState.connection then
        flingState.connection:Disconnect()
        flingState.connection = nil
    end

    local root = getRootPart(LocalPlayer)
    if root then
        root.Velocity    = Vector3.zero
        root.RotVelocity = Vector3.zero
        if restorePosition and flingState.startCFrame then
            root.CFrame = flingState.startCFrame
        end
    end

    if restorePosition then
        flingState.startCFrame = nil
        local cfg = playerConfig()
        if cfg then cfg.FlingActive = false end
    end
end

local function startFling(targetName)
    stopFling(false)

    local target = findPlayer(targetName)
    if not target then return end

    local myRoot = getRootPart(LocalPlayer)
    if myRoot then flingState.startCFrame = myRoot.CFrame end

    local startTime = tick()

    flingState.connection = RunService.Heartbeat:Connect(function()
        local cfg = playerConfig()

        if tick() - startTime >= 2 then
            stopFling(true)
            return
        end

        if not cfg.FlingActive or not target.Character or not LocalPlayer.Character then
            stopFling(true)
            return
        end

        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local myCurrentRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if targetRoot and myCurrentRoot then
            myCurrentRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, -1, 0))
                * CFrame.Angles(-math.pi / 2, 0, 0)

            local force = Vector3.new(0, 10000, 0)
            myCurrentRoot.Velocity    = force
            myCurrentRoot.RotVelocity = force

            pcall(sethiddenproperty, myCurrentRoot, "PhysicsRepRootPart", targetRoot)
        else
            stopFling(true)
        end
    end)
end

-- noclip
local noclipParts = {}

local function cacheNoclipParts(char)
    table.clear(noclipParts)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(noclipParts, part)
        end
    end
end

-- noclip loop
RunService.Stepped:Connect(function()
    local cfg = playerConfig()
    if not cfg or not cfg.Noclip then return end

    for _, part in ipairs(noclipParts) do
        if part and part.Parent and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- speed e jump
local physicsConn = nil

local function startPhysicsLoop()
    if physicsConn then return end
    physicsConn = RunService.RenderStepped:Connect(function()
        local cfg = playerConfig()
        if not cfg then return end

        local hum = getHumanoid(LocalPlayer)
        if not hum then return end

        if cfg.SpeedEnabled then hum.WalkSpeed = cfg.SpeedVal end
        if cfg.JumpEnabled  then
            hum.JumpPower    = cfg.JumpVal
            hum.UseJumpPower = true
        end
    end)
end

local function stopPhysicsLoop()
    if physicsConn then
        physicsConn:Disconnect()
        physicsConn = nil
    end
end

-- espectar
RunService.RenderStepped:Connect(function()
    local cfg = playerConfig()
    if not cfg then return end

    if cfg.SpectateActive then
        local target = findPlayer(cfg.TargetPlayer)
        if target then
            local hum = getHumanoid(target)
            if hum then Camera.CameraSubject = hum end
        end
    else
        local hum = getHumanoid(LocalPlayer)
        if hum and Camera.CameraSubject ~= hum then
            Camera.CameraSubject = hum
        end
    end
end)

-- anonimo hooks
local fakeId = math.random(1000000, 2000000000)

local OldIndex
OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() then
        local cfg = playerConfig()
        if cfg and cfg.AnonEnabled and self == LocalPlayer then
            if key == "UserId"      then return fakeId end
            if key == "Name"        then return cfg.FakeName end
            if key == "DisplayName" then return cfg.FakeName end
        end
    end
    return OldIndex(self, key)
end))

local OldNewIndex
OldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
    if not checkcaller() then
        local cfg = playerConfig()
        if cfg and cfg.AnonEnabled and key == "Text" and type(value) == "string" then
            return OldNewIndex(self, key, spoofText(value))
        end
    end
    return OldNewIndex(self, key, value)
end))

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}
    local cfg    = playerConfig()

    if not checkcaller() and cfg and cfg.AnonEnabled then
        if method == "SetCore" and args[1] == "SendNotification" then
            local data = args[2]
            if type(data) == "table" then
                if data.Title then data.Title = spoofText(data.Title) end
                if data.Text  then data.Text  = spoofText(data.Text)  end
                return OldNamecall(self, table.unpack(args))
            end
        end
    end

    return OldNamecall(self, ...)
end))

if TextChat.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChat.OnIncomingMessage = function(msg)
        local cfg   = playerConfig()
        local props = Instance.new("TextChatMessageProperties")

        if cfg and cfg.AnonEnabled then
            if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then
                local display = cfg.FakeName or "Anônimo"
                props.PrefixText = string.format("<font color='#F5CD30'>[%s]</font>", display)
            else
                props.PrefixText = spoofText(msg.PrefixText)
            end
        end

        return props
    end
end

-- eventos
local lastPosition = nil

local function hookCharacter(char)
    cacheNoclipParts(char)

    char.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") then
            table.insert(noclipParts, obj)
        end
    end)

    local hum  = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)

    if hum and root then
        hum.Died:Connect(function()
            local cfg = playerConfig()
            if cfg and cfg.RespawnEnabled then
                lastPosition = root.CFrame
            end
        end)
    end

    local cfg = playerConfig()
    if cfg and cfg.AnonEnabled then
        scanGuiLayer(char)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local cfg = playerConfig()

    if cfg.RespawnEnabled and lastPosition then
        task.spawn(function()
            local root = char:WaitForChild("HumanoidRootPart", 10)
            if root then
                task.wait(0.2)
                root.CFrame   = lastPosition
                root.Velocity = Vector3.zero
            end
        end)
    end

    hookCharacter(char)

    if cfg.InvisEnabled then
        task.wait(0.5)
        toggleInvisibility(true)
    end

    if cfg.AnonEnabled then
        task.wait(1)
        applyAnonVisuals()
    end

    if cfg.SpeedEnabled or cfg.JumpEnabled then
        startPhysicsLoop()
    end
end)

if LocalPlayer.Character then
    hookCharacter(LocalPlayer.Character)
end

-- estados
local lastAnonState  = false
local lastInvisState = false
local lastSpeedState = false
local lastJumpState  = false

task.spawn(function()
    while task.wait(0.1) do
        local cfg = playerConfig()
        if not cfg then continue end

        if cfg.TriggerFling then
            cfg.TriggerFling = false
            cfg.FlingActive  = true
            startFling(cfg.TargetPlayer)
        end

        if cfg.TriggerTeleport then
            cfg.TriggerTeleport = false
            local target = findPlayer(cfg.TargetPlayer)
            if target and target.Character then
                local myRoot     = getRootPart(LocalPlayer)
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and targetRoot then
                    lastPosition  = myRoot.CFrame
                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                end
            end
        end

        if cfg.TriggerReturn then
            cfg.TriggerReturn = false
            if lastPosition then
                local root = getRootPart(LocalPlayer)
                if root then root.CFrame = lastPosition end
            end
        end

        if cfg.InvisEnabled ~= lastInvisState then
            lastInvisState = cfg.InvisEnabled
            toggleInvisibility(cfg.InvisEnabled)
        end

        if cfg.AnonEnabled ~= lastAnonState then
            lastAnonState = cfg.AnonEnabled
            applyAnonVisuals()
        end

        local needsPhysics = cfg.SpeedEnabled or cfg.JumpEnabled
        if needsPhysics and not lastSpeedState then
            startPhysicsLoop()
        elseif not needsPhysics and lastSpeedState then
            stopPhysicsLoop()
        end
        lastSpeedState = needsPhysics
    end
end)


-- char
if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end

env.Avatar = env.Avatar or {}
local Avatar = env.Avatar

Avatar.TargetInput      = ""
Avatar.CurrentAppliedId = (LocalPlayer and LocalPlayer.UserId) or 0
Avatar.SkinFolder       = "michigun.xyz/skins"

if not isfolder(Avatar.SkinFolder) then makefolder(Avatar.SkinFolder) end

local function applyDescription(character, fakeName, fakeId, description)
    if not character then return end

    if LocalPlayer and character == LocalPlayer.Character then
        Avatar.CurrentAppliedId = fakeId or Avatar.CurrentAppliedId
    end

    task.spawn(function()
        pcall(function()
            task.wait(0.3)

            local hum = character:WaitForChild("Humanoid", 10)
            if not hum then return end

            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy() end
            end
            for _, obj in ipairs(character:GetChildren()) do
                if obj:IsA("Shirt") or obj:IsA("Pants")
                or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then
                    obj:Destroy()
                end
            end

            local bodyColors = hum:FindFirstChildOfClass("BodyColors")
            if bodyColors then bodyColors:Destroy() end

            for _, limbName in ipairs({"Torso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
                local limb = character:FindFirstChild(limbName)
                if limb then
                    for _, mesh in ipairs(limb:GetChildren()) do
                        if mesh:IsA("SpecialMesh") then mesh:Destroy() end
                    end
                end
            end

            local head = character:FindFirstChild("Head")
            if head then
                local mesh = head:FindFirstChildOfClass("SpecialMesh")
                if mesh then mesh.MeshId = "" mesh.TextureId = "" end
            end

            task.wait(0.1)
            if description then hum:ApplyDescriptionClientServer(description) end
        end)
    end)
end

local function resolveUserId(input)
    local id = tonumber(input)
    local name

    local ok = pcall(function()
        if id then
            name = Players:GetNameFromUserIdAsync(id)
        else
            id   = Players:GetUserIdFromNameAsync(input)
            name = Players:GetNameFromUserIdAsync(id)
        end
    end)

    if ok and id then return id, name end
    return nil, nil
end

Avatar.ApplySkin = function(input)
    if not LocalPlayer or not LocalPlayer.Character then return end
    if not input or input == "" then return end

    local id, name = resolveUserId(input)
    if not id then return end

    local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, id)
    if ok and desc then applyDescription(LocalPlayer.Character, name, id, desc) end
end

Avatar.ApplySkinToOther = function(targetName, skinInput, fromSaved)
    local target = findPlayer(targetName)
    if not target or not target.Character then return end

    local id, name

    if fromSaved then
        local ok, data = pcall(readfile, Avatar.SkinFolder .. "/" .. skinInput .. ".txt")
        if not ok or not data then return end
        id   = tonumber(data)
        name = "SavedSkin"
    else
        id, name = resolveUserId(skinInput)
    end

    if not id then return end

    local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, id)
    if ok and desc then applyDescription(target.Character, name, id, desc) end
end

Avatar.RestoreOther = function(targetName)
    local target = findPlayer(targetName)
    if not target or not target.Character then return end

    local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, target.UserId)
    if ok and desc then applyDescription(target.Character, target.Name, target.UserId, desc) end
end

Avatar.RestoreSkin = function()
    if not LocalPlayer or not LocalPlayer.Character then return end

    local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, LocalPlayer.UserId)
    if ok and desc then applyDescription(LocalPlayer.Character, LocalPlayer.Name, LocalPlayer.UserId, desc) end
end

Avatar.GetSavedSkins = function()
    local ok, files = pcall(listfiles, Avatar.SkinFolder)
    if not ok or not files then
        return {{ Title = "Erro ao ler pasta", Icon = "lucide:alert-triangle" }}
    end

    local skins = {}
    for _, path in ipairs(files) do
        local name = path:match("([^\\/]+)%.txt$")
        if name then table.insert(skins, { Title = name, Icon = "lucide:user" }) end
    end

    if #skins == 0 then
        table.insert(skins, { Title = "Nenhuma salva", Icon = "lucide:frown" })
    end

    return skins
end

Avatar.SaveSkin = function(customName)
    local id   = Avatar.CurrentAppliedId or 0
    local name = (customName ~= "" and customName:gsub("[^%w%s]", "")) or ("Skin_" .. id)
    writefile(Avatar.SkinFolder .. "/" .. name .. ".txt", tostring(id))
end

Avatar.LoadSkin = function(name)
    if not LocalPlayer or not LocalPlayer.Character then return end

    local ok, data = pcall(readfile, Avatar.SkinFolder .. "/" .. name .. ".txt")
    if not ok or not data then return end

    local id = tonumber(data)
    if not id then return end

    local descOk, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, id)
    if descOk and desc then applyDescription(LocalPlayer.Character, name, id, desc) end
end

Avatar.DeleteSkin = function(name)
    local path = Avatar.SkinFolder .. "/" .. name .. ".txt"
    if isfile(path) then delfile(path) end
end
end)


-- ===== silent.lua ===== --
task.spawn(function()
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    GuiService = game:GetService("GuiService"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    HttpService = game:GetService("HttpService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

local gethui = gethui or function() return Services.CoreGui end
local clonefunction = clonefunction or function(f) return f end
local raycast = clonefunction(Services.Workspace.Raycast)
local wts = clonefunction(Camera.WorldToScreenPoint)
local get_mouse = clonefunction(Services.UserInputService.GetMouseLocation)

local PartMapping = {
    ["Cabeça"] = {"Head"},
    ["Tronco"] = {"Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    ["Braço direito"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["Braço esquerdo"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["Perna direita"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"},
    ["Perna esquerda"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"}
}

local AllCategories = {"Cabeça", "Tronco", "Braço direito", "Braço esquerdo", "Perna direita", "Perna esquerda"}

local Visuals = { Gui = nil, Circle = nil, Stroke = nil, Highlight = nil, ESP = nil, Labels = {} }

local function InitVisuals()
    if Visuals.Gui then Visuals.Gui:Destroy() end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = Services.HttpService:GenerateGUID(false)
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = gethui()
    
    local circle = Instance.new("Frame", gui)
    circle.BackgroundTransparency = 1
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Visible = false
    
    local stroke = Instance.new("UIStroke", circle)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    local corner = Instance.new("UICorner", circle)
    corner.CornerRadius = UDim.new(1, 0)
    
    local hl = Instance.new("Highlight", gui)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    
    local esp = Instance.new("BillboardGui", gui)
    esp.Size = UDim2.fromOffset(200, 150)
    esp.StudsOffset = Vector3.new(0, 3, 0)
    esp.AlwaysOnTop = true
    esp.Enabled = false
    
    local container = Instance.new("Frame", esp)
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout", container)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    
    local function createLabel(order, font, color)
        local l = Instance.new("TextLabel", container)
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, 0, 0, 14)
        l.Font = font or Enum.Font.GothamBold
        l.TextSize = 12
        l.TextColor3 = color or Color3.new(1, 1, 1)
        l.TextStrokeTransparency = 0.2
        l.LayoutOrder = order
        l.Visible = false
        return l
    end
    
    Visuals.Gui = gui
    Visuals.Circle = circle
    Visuals.Stroke = stroke
    Visuals.Highlight = hl
    Visuals.ESP = esp
    Visuals.Labels = {
        Name = createLabel(1),
        Team = createLabel(2, nil, Color3.new(0.8, 0.8, 0.8)),
        Weapon = createLabel(3),
        Health = createLabel(4, Enum.Font.Code)
    }
end
InitVisuals()

local function IsVisible(part, char, config)
    if not config.WallCheck then return true end
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = {LocalPlayer.Character, Camera, char, Visuals.Gui}
    p.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local res = raycast(Services.Workspace, origin, dir, p)
    return res == nil or res.Instance:IsDescendantOf(char)
end

local State = { Target = nil, Part = nil }

local function GetTarget(config)
    local bestT, bestP = nil, nil
    local bestPhys = math.huge
    local bestHealth = math.huge
    
    local mouse = (config.FOVBehavior == "Mouse") and get_mouse(Services.UserInputService) or (Camera.ViewportSize * 0.5)
    local maxDist = config.MaxDistance
    local priority = config.TargetPriority
    local camPos = Camera.CFrame.Position
    
    local tParts = config.TargetPart
    if type(tParts) ~= "table" or #tParts == 0 then tParts = {"Cabeça"} end

    local isRandom = false
    for _, v in ipairs(tParts) do if v == "Aleatório" then isRandom = true break end end

    local wlUsers = {}
    if config.WhitelistedUsers then for _, v in ipairs(config.WhitelistedUsers) do wlUsers[v] = true end end

    local wlTeams = {}
    if config.WhitelistedTeams then for _, v in ipairs(config.WhitelistedTeams) do wlTeams[v] = true end end

    local fList = {}
    if config.FocusList then for _, v in ipairs(config.FocusList) do fList[v] = true end end

    local players = Services.Players:GetPlayers()
    for _, v in ipairs(players) do
        if v == LocalPlayer then continue end
        if config.TeamCheck == "Team" and v.Team == LocalPlayer.Team then continue end
        if wlUsers[v.Name] then continue end
        if v.Team and wlTeams[v.Team.Name] then continue end
        if config.FocusMode and not fList[v.Name] then continue end
        
        local c = v.Character
        if not c then continue end
        
        local r = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChild("Humanoid")
        if not r or not h or h.Health <= 0 then continue end
        if (r.Position - camPos).Magnitude > maxDist then continue end
        
        local partsToCheck = {}
        if isRandom then
            local pList = {}
            for _, cat in ipairs(AllCategories) do
                for _, partName in ipairs(PartMapping[cat]) do
                    local p = c:FindFirstChild(partName)
                    if p then table.insert(pList, p) end
                end
            end
            if #pList > 0 then table.insert(partsToCheck, pList[math.random(1, #pList)]) end
        else
            for _, partName in ipairs(tParts) do
                if PartMapping[partName] then
                    for _, partName2 in ipairs(PartMapping[partName]) do
                        local p = c:FindFirstChild(partName2)
                        if p then table.insert(partsToCheck, p) end
                    end
                end
            end
        end
        
        if #partsToCheck == 0 then table.insert(partsToCheck, r) end
        
        for _, pObj in ipairs(partsToCheck) do
            local sPos, onScreen = wts(Camera, pObj.Position)
            if onScreen then
                local dist = (mouse - Vector2.new(sPos.X, sPos.Y)).Magnitude
                if dist <= config.FOVSize and IsVisible(pObj, c, config) then
                    local isCurrent = (State.Target == c)
                    local pPhysDist = (pObj.Position - camPos).Magnitude
                    local effectivePhys = isCurrent and (pPhysDist - 5) or pPhysDist

                    if priority == "Health" then
                        if h.Health < bestHealth or (h.Health == bestHealth and effectivePhys < bestPhys) then
                            bestHealth = h.Health
                            bestPhys = effectivePhys
                            bestT = c
                            bestP = pObj
                        end
                    else
                        if effectivePhys < bestPhys then
                            bestPhys = effectivePhys
                            bestT = c
                            bestP = pObj
                        end
                    end
                end
            end
        end
    end
    return bestT, bestP
end

local LastTargetTick = 0

Services.RunService.RenderStepped:Connect(function()
    local Config = getgenv().SilentConfig
    
    if not Config or not Config.Enabled then
        Visuals.Circle.Visible = false
        Visuals.Highlight.Enabled = false
        Visuals.ESP.Enabled = false
        for _, l in pairs(Visuals.Labels) do l.Visible = false end
        State.Target = nil
        State.Part = nil
        return
    end

    if tick() - LastTargetTick >= 0.05 then
        State.Target, State.Part = GetTarget(Config)
        LastTargetTick = tick()
    end
    
    -- FOV
    if Config.ShowFOV then
        Visuals.Circle.Visible = true
        Visuals.Circle.Size = UDim2.fromOffset(Config.FOVSize * 2, Config.FOVSize * 2)
        Visuals.Stroke.Color = Config.FOVColor
        local pos = (Config.FOVBehavior == "Mouse") and get_mouse(Services.UserInputService) or (Camera.ViewportSize * 0.5)
        Visuals.Circle.Position = UDim2.fromOffset(pos.X, pos.Y)
    else
        Visuals.Circle.Visible = false
    end
    
    if State.Target then
        -- Highlight
        Visuals.Highlight.Adornee = State.Target
        Visuals.Highlight.FillColor = Config.HighlightColor
        Visuals.Highlight.OutlineColor = Config.HighlightColor
        Visuals.Highlight.Enabled = Config.ShowHighlight

        -- ESP/HUD
        if Config.ESP and Config.ESP.Enabled then
            local player = Services.Players:GetPlayerFromCharacter(State.Target)
            local humanoid = State.Target:FindFirstChild("Humanoid")
            local root = State.Target:FindFirstChild("HumanoidRootPart")

            Visuals.ESP.Adornee = root
            Visuals.ESP.Enabled = true

            -- Nome
            Visuals.Labels.Name.Text = player and player.Name or ""
            Visuals.Labels.Name.Visible = Config.ESP.ShowName

            -- Time
            if player and player.Team then
                Visuals.Labels.Team.Text = player.Team.Name
                Visuals.Labels.Team.TextColor3 = player.Team.TeamColor.Color
            else
                Visuals.Labels.Team.Text = ""
            end
            Visuals.Labels.Team.Visible = Config.ESP.ShowTeam

            -- Vida
            if humanoid then
                local hp = math.floor(humanoid.Health)
                local maxHp = math.floor(humanoid.MaxHealth)
                local ratio = hp / math.max(maxHp, 1)
                Visuals.Labels.Health.Text = string.format("HP: %d/%d", hp, maxHp)
                Visuals.Labels.Health.TextColor3 = Color3.new(1 - ratio, ratio, 0)
                Visuals.Labels.Health.Visible = Config.ESP.ShowHealth
            else
                Visuals.Labels.Health.Visible = false
            end

            -- Arma/Item
            if Config.ESP.ShowWeapon then
                local tool = State.Target:FindFirstChildOfClass("Tool")
                Visuals.Labels.Weapon.Text = tool and tool.Name or "Nenhum"
                Visuals.Labels.Weapon.Visible = true
            else
                Visuals.Labels.Weapon.Visible = false
            end
        else
            Visuals.ESP.Enabled = false
            for _, l in pairs(Visuals.Labels) do l.Visible = false end
        end
    else
        Visuals.Highlight.Enabled = false
        Visuals.ESP.Enabled = false
        for _, l in pairs(Visuals.Labels) do l.Visible = false end
    end
end)

local safe_remotes = {"UpdateMouse", "Look", "Camera", "Status", "Animation", "Heartbeat"}
local BulletKeywords = {"fire", "shoot", "bullet", "ammo", "projectile", "missile", "hit", "damage", "attack"}

local CheckedSafe = setmetatable({}, {__mode = "k"})
local CheckedRemotes = setmetatable({}, {__mode = "k"})

local function isBulletRemote(remote)
    if CheckedRemotes[remote] ~= nil then return CheckedRemotes[remote] end
    local n = string.lower(remote.Name)
    for _, v in ipairs(BulletKeywords) do
        if string.find(n, v) then 
            CheckedRemotes[remote] = true
            return true 
        end
    end
    CheckedRemotes[remote] = false
    return false
end

local function getLegitOffset(config)
    if not config.UseLegitOffset then return Vector3.zero end
    return Vector3.new((math.random()-0.5)*0.5, (math.random()-0.5)*0.5, (math.random()-0.5)*0.5)
end

local mt = getrawmetatable(game)
local old_nc = mt.__namecall
setreadonly(mt, false)

local getnamecallmethod = getnamecallmethod
local checkcaller = checkcaller
local typeof = typeof
local CFrame_new = CFrame.new
local Ray_new = Ray.new

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if checkcaller() then return old_nc(self, ...) end

    local Config = getgenv().SilentConfig
    
    if Config and Config.Enabled and State.Part then
        if method ~= "FireServer" and method ~= "InvokeServer" and method ~= "Raycast" 
        and method ~= "FindPartOnRayWithIgnoreList" and method ~= "FindPartOnRayWithWhitelist" 
        and method ~= "FindPartOnRay" and method ~= "findPartOnRay" then
            return old_nc(self, ...)
        end

        if math.random(1, 100) <= (Config.HitChance or 100) then
            local args = {...}
            local finalPos = State.Part.Position + getLegitOffset(Config)

            if self == Services.Workspace then
                if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" or method == "findPartOnRay" then
                    local a_ray = args[1]
                    if a_ray and typeof(a_ray) == "Ray" then
                        local origin = a_ray.Origin
                        local direction = (finalPos - origin).Unit * 10000
                        args[1] = Ray_new(origin, direction)
                        return old_nc(self, unpack(args))
                    end
                elseif method == "Raycast" then
                    local origin = args[1]
                    if origin and typeof(origin) == "Vector3" then
                        args[2] = (finalPos - origin).Unit * 10000 
                        return old_nc(self, unpack(args))
                    end
                end
            end

            if (method == "FireServer" or method == "InvokeServer") and isBulletRemote(self) then
                local camPos = Camera.CFrame.Position
                local direction = (finalPos - camPos).Unit
                
                for i = 1, #args do
                    local v = args[i]
                    if typeof(v) == "Vector3" then
                        if v.Magnitude <= 10 then
                            args[i] = direction
                        else
                            args[i] = finalPos
                        end
                    elseif typeof(v) == "CFrame" then
                        args[i] = CFrame_new(camPos, finalPos)
                    end
                end
                return old_nc(self, unpack(args))
            end
        end
    end
    
    return old_nc(self, ...)
end)
setreadonly(mt, true)
end)


-- ===== treino.lua ===== --
task.spawn(function()
local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local hs = cr(game:GetService("HttpService"))
local tcs = cr(game:GetService("TextChatService"))
local rep = cr(game:GetService("ReplicatedStorage"))
local vim = cr(game:GetService("VirtualInputManager"))
local ts = cr(game:GetService("TweenService"))
local cg = cr(game:GetService("CoreGui"))
local uis = cr(game:GetService("UserInputService"))

local lp = cr(plrs.LocalPlayer)
local cam = cr(ws.CurrentCamera)

local unp = table.unpack or unpack
local env = getgenv()

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end

-- [[ TAS ]] --
local stEnums = {}
for _, e in ipairs(Enum.HumanoidStateType:GetEnumItems()) do stEnums[e.Value] = e end

local gh = gethui or function() return cg end
if gh():FindFirstChild(".") then gh():FindFirstChild("."):Destroy() end
local ui = Instance.new("ScreenGui")
ui.Name, ui.ResetOnSpawn, ui.Parent = ".", false, gh()

local tas_fDir = "michigun.xyz/tas"
if writefile and not isfolder(tas_fDir) then makefolder(tas_fDir) end

env.TAS = env.TAS or {}
local tas = env.TAS

tas.Loaded      = tas.Loaded or {}
tas.Selection   = tas.Selection or {}
tas.Recording   = false
tas.ReqPlay     = false
tas.RecFrames   = {}
tas.CurrentName = ""
tas.RecConn     = nil
tas.IsReady     = true
tas.LastJump    = false
tas.ActRad      = 0.8
tas.ActH        = 1.5
tas.ActAng      = 10
tas.ColorBot    = Color3.fromRGB(0, 255, 0)
tas.ColorPath   = Color3.fromRGB(0, 255, 0)
tas.VisualOpacity = 0

local function extractName(path)
    local normalized = path:gsub("\\", "/")
    return normalized:match("([^/]+)%.json$")
end

local function filePath(name)
    return tas_fDir .. "/" .. name .. ".json"
end

local function sNotif(t, m)
    if tas.NotifyFunc then tas.NotifyFunc(t .. ": " .. m, 3, "lucide:info") end
end

-- Para o personagem e restaura controle total ao jogador (PC + mobile)
local function stpMov()
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then
        h.AutoRotate = true
        -- Para qualquer movimento forçado pelo TAS
        h:Move(Vector3.zero, false)
        -- Força saída de estados travados no próximo frame
        task.defer(function()
            if h and h.Parent then
                pcall(function() h:ChangeState(Enum.HumanoidStateType.Running) end)
            end
        end)
    end
    -- Reativa TouchGui imediatamente (botões de mobile)
    local pg = lp:FindFirstChild("PlayerGui")
    local tg = pg and pg:FindFirstChild("TouchGui")
    if tg then
        tg.Enabled = false
        task.defer(function() if tg and tg.Parent then tg.Enabled = true end end)
    end
end

local function chkPlay()
    local ip = false
    for _, d in pairs(tas.Loaded) do if d.Playing then ip = true; break end end
    if tas.UpdateButtonState then tas.UpdateButtonState(ip) end
end

local function capFr()
    local c = lp.Character
    local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
    local anims = {}
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            table.insert(anims, {
                id     = track.Animation.AnimationId,
                pos    = track.TimePosition,
                speed  = track.Speed,
                weight = track.WeightCurrent,
            })
        end
    end

    return {
        cf    = { hrp.CFrame:GetComponents() },
        vel   = { hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z },
        jump  = hum.Jump,
        state = hum:GetState().Value,
        anims = anims,
    }
end

-- Aplica frame gravado sem nenhum keypress — usa só Humanoid:Move e ChangeState
local function appFr(f, hrp, hum)
    if not f or not hrp or not hum then return end

    -- Teleporta para a posição gravada
    if f.cf then
        hrp.CFrame = CFrame.new(
            f.cf[1],f.cf[2],f.cf[3],
            f.cf[4],f.cf[5],f.cf[6],
            f.cf[7],f.cf[8],f.cf[9],
            f.cf[10],f.cf[11],f.cf[12]
        )
    end

    -- Aplica velocidade gravada
    if f.vel then
        hrp.AssemblyLinearVelocity = Vector3.new(f.vel[1], f.vel[2], f.vel[3])
    end

    -- Dispara pulo via ChangeState (sem keypress, funciona em mobile)
    if f.jump ~= tas.LastJump then
        tas.LastJump = f.jump
        if f.jump then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end

    -- Força o estado do humanoid conforme gravado (Freefall, Swimming, etc.)
    local recSt = stEnums[f.state]
    if recSt and recSt ~= Enum.HumanoidStateType.Jumping then
        if hum:GetState() ~= recSt then
            pcall(function() hum:ChangeState(recSt) end)
        end
    end

    -- Usa Humanoid:Move para acionar as animações corretas (corre, idle, etc.)
    -- Funciona em PC e mobile sem precisar de keypress
    local vel = f.vel and Vector3.new(f.vel[1], f.vel[2], f.vel[3]) or Vector3.zero
    local hvel = Vector3.new(vel.X, 0, vel.Z)
    hum.AutoRotate = false
    if hvel.Magnitude > 0.1 then
        hum:Move(hvel.Unit, false)
    else
        hum:Move(Vector3.zero, false)
    end
end

local function mkVp(worldPos, sz)
    local vpf, vpc = Instance.new("ViewportFrame"), Instance.new("Camera")
    vpf.Parent, vpf.BackgroundTransparency, vpf.Size, vpf.ZIndex = ui, 1, UDim2.new(0, 150, 0, 150), 10
    vpc.Parent = vpf
    local cl = Instance.new("Part")
    cl.Size, cl.Anchored, cl.CanCollide = sz, true, false
    cl.Transparency = 0
    cl.Material     = Enum.Material.Neon
    cl.CFrame       = CFrame.new()
    cl.Parent       = vpf
    local mx = math.max(sz.X, sz.Y, sz.Z)
    vpc.CFrame = CFrame.new(0, mx, mx * 2.5) * CFrame.Angles(math.rad(-20), math.rad(180), 0)
    local active = true
    local cnn = rs.Stepped:Connect(function()
        if not active then return end
        local ps, vs = cam:WorldToScreenPoint(worldPos)
        vpf.Position = UDim2.fromOffset(ps.X - 75, ps.Y - 75)
        vpf.Visible  = vs
        cl.CFrame    = CFrame.Angles(0, tick() % (math.pi * 2), 0)
    end)
    return { Frame = vpf, Connection = cnn, Deactivate = function() active = false end }
end

local function clrTas(n, playingOnly)
    local d = tas.Loaded[n]
    if not d then return end

    if d.PlayConn then d.PlayConn:Disconnect(); d.PlayConn = nil end
    if d.Playing then
        tas.LastJump = false
        stpMov()
    end
    d.Playing = false

    if not playingOnly then
        if d.MarkerConn then d.MarkerConn:Disconnect(); d.MarkerConn = nil end
        if d.Adornments then
            for _, a in ipairs(d.Adornments) do if a and a.Parent then a:Destroy() end end
        end
        if d.Viewports then
            for _, v in ipairs(d.Viewports) do
                if v.Deactivate then v.Deactivate() end
                if v.Connection then v.Connection:Disconnect() end
                if v.Frame      then v.Frame:Destroy() end
            end
        end
        if d.PathParts then
            for _, p in ipairs(d.PathParts) do if p then p:Destroy() end end
        end
        d.Viewports, d.PathParts, d.Adornments, d.Waiting = {}, {}, {}, false
    end

    chkPlay()
end

local function bldPth(fs)
    local pts = {}
    if not fs or #fs < 2 then return pts end
    for i = 1, #fs - 1 do
        if fs[i].cf and fs[i+1].cf then
            local sp  = Vector3.new(fs[i].cf[1],   fs[i].cf[2],   fs[i].cf[3])
            local ep  = Vector3.new(fs[i+1].cf[1], fs[i+1].cf[2], fs[i+1].cf[3])
            local dst = (ep - sp).Magnitude
            if dst > 0.05 then
                local pt = Instance.new("CylinderHandleAdornment")
                pt.Radius       = 0.05
                pt.Height       = dst
                pt.CFrame       = CFrame.new(sp:Lerp(ep, 0.5), ep)
                pt.Color3       = tas.ColorPath
                pt.Transparency = tas.VisualOpacity
                pt.Adornee      = ws.Terrain
                pt.ZIndex       = 0
                pt.Parent       = ws.Terrain
                table.insert(pts, pt)
            end
        end
    end
    return pts
end

local function actTas(n)
    local d = tas.Loaded[n]
    if not d or not d.Frames or #d.Frames == 0 or d.Waiting or d.Playing then return end

    clrTas(n, true)
    d.Waiting = true

    local c  = d.Frames[1].cf
    local cf = CFrame.new(c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12])

    d.Adornments = {}
    local bc, tr = tas.ColorBot, tas.VisualOpacity
    local function mkM(nm, sz, c_frame, isC)
        local p = isC and Instance.new("CylinderHandleAdornment") or Instance.new("BoxHandleAdornment")
        if isC then p.Radius, p.Height = sz.X, sz.Y else p.Size = sz end
        p.Name         = nm
        p.CFrame       = c_frame
        p.Color3       = bc
        p.Transparency = tr
        p.Adornee      = ws.Terrain
        p.ZIndex       = 1
        p.Parent       = ws.Terrain
        table.insert(d.Adornments, p)
        return p
    end
    mkM("Tor", Vector3.new(2, 2, 1), cf,                                                                 false)
    mkM("LLg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2,  0),                                     false)
    mkM("RLg", Vector3.new(1, 2, 1), cf * CFrame.new( 0.5, -2,  0),                                     false)
    mkM("LAm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5,  0,  0),                                     false)
    mkM("RAm", Vector3.new(1, 2, 1), cf * CFrame.new( 1.5, 0.5, -1) * CFrame.Angles(math.rad(90),0,0), false)

    d.Viewports = {}
    table.insert(d.Viewports, mkVp(cf.Position, Vector3.new(2, 2, 1)))
    d.PathParts = bldPth(d.Frames)

    d.MarkerConn = rs.Heartbeat:Connect(function()
        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dlt      = hrp.Position - cf.Position
        local horizDst = Vector3.new(dlt.X, 0, dlt.Z).Magnitude
        local vertDst  = math.abs(dlt.Y)
        local dot      = hrp.CFrame.LookVector:Dot(cf.LookVector)

        if horizDst <= tas.ActRad and vertDst <= tas.ActH and dot >= math.cos(math.rad(tas.ActAng)) then
            if d.MarkerConn then d.MarkerConn:Disconnect(); d.MarkerConn = nil end
            if d.Adornments then
                for _, a in ipairs(d.Adornments) do if a and a.Parent then a:Destroy() end end
                d.Adornments = {}
            end
            for _, v in ipairs(d.Viewports) do
                if v.Deactivate then v.Deactivate() end
                if v.Connection then v.Connection:Disconnect() end
                if v.Frame      then v.Frame:Destroy() end
            end
            for _, p in ipairs(d.PathParts) do if p then p:Destroy() end end
            d.Viewports, d.PathParts = {}, {}
            d.Waiting, d.Playing = false, true
            tas.LastJump = false
            chkPlay()

            local stT       = tick()
            local lastC     = lp.Character
            local cachedHrp = lastC and lastC:FindFirstChild("HumanoidRootPart")
            local cachedHum = lastC and lastC:FindFirstChildOfClass("Humanoid")

            d.PlayConn = rs.Heartbeat:Connect(function()
                -- Se foi parado externamente (ManualStop ou ToggleAll)
                if not d.Playing then return end

                local currC = lp.Character
                if currC ~= lastC then
                    lastC       = currC
                    cachedHrp   = currC and currC:FindFirstChild("HumanoidRootPart")
                    cachedHum   = currC and currC:FindFirstChildOfClass("Humanoid")
                end
                local cIdx = math.floor((tick() - stT) * 60) + 1
                if cIdx > #d.Frames then
                    tas.LastJump = false
                    stpMov()
                    if d.PlayConn then d.PlayConn:Disconnect(); d.PlayConn = nil end
                    d.Playing = false
                    chkPlay()
                    return
                end
                appFr(d.Frames[cIdx], cachedHrp, cachedHum)
            end)
        end
    end)
end

tas.UpdateVisuals = function(bC, pC, op)
    if bC ~= nil then tas.ColorBot      = bC end
    if pC ~= nil then tas.ColorPath     = pC end
    if op ~= nil then tas.VisualOpacity = op end
    for _, d in pairs(tas.Loaded) do
        if d.Adornments then
            for _, p in ipairs(d.Adornments) do
                if p and p.Parent then
                    p.Color3       = tas.ColorBot
                    p.Transparency = tas.VisualOpacity
                end
            end
        end
        if d.PathParts then
            for _, p in ipairs(d.PathParts) do
                if p then
                    p.Color3       = tas.ColorPath
                    p.Transparency = tas.VisualOpacity
                end
            end
        end
    end
end

tas.StopRecording = function()
    if not tas.Recording then return end
    tas.Recording = false
    if tas.RecConn then tas.RecConn:Disconnect(); tas.RecConn = nil end
    sNotif("TAS", string.format("Gravação parada (%.2fs)", #tas.RecFrames * (1/60)))
end

tas.StartRecording = function()
    if tas.Recording then return end
    tas.RecFrames, tas.Recording = {}, true
    local acc, idl = 0, 0
    tas.RecConn = rs.Heartbeat:Connect(function(dt)
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then idl = hrp.AssemblyLinearVelocity.Magnitude < 0.2 and idl + dt or 0 end
        if idl >= 1 then tas.StopRecording(); return end
        acc = acc + dt
        while acc >= (1/60) do
            acc = acc - (1/60)
            local f = capFr()
            if f then table.insert(tas.RecFrames, f) end
        end
    end)
    sNotif("TAS", "Gravação iniciada")
end

tas.SaveCurrent = function()
    if not tas.CurrentName or tas.CurrentName == "" or #tas.RecFrames == 0 then return end
    local rj = hs:JSONEncode({ Version = 1, Frames = tas.RecFrames })
    writefile(filePath(tas.CurrentName), rj)
    tas.RecFrames = {}
    return tas.GetSaved()
end

tas.GetSaved = function()
    local out = {}
    if listfiles then
        for _, f in ipairs(listfiles(tas_fDir)) do
            local name = extractName(f)
            if name then out[#out + 1] = name end
        end
    end
    return out
end

tas.UpdateSelection = function(sL)
    tas.Selection = type(sL) ~= "table" and { sL } or sL

    for n in pairs(tas.Loaded) do
        local ok = false
        for _, v in ipairs(tas.Selection) do if v == n then ok = true; break end end
        if not ok then
            clrTas(n)
            tas.Loaded[n] = nil
        end
    end

    task.spawn(function()
        for i, n in ipairs(tas.Selection) do
            if n ~= "" and not tas.Loaded[n] then
                local p = filePath(n)
                if isfile(p) then
                    local raw = readfile(p)
                    local d
                    pcall(function() d = hs:JSONDecode(raw) end)
                    if d and d.Frames then
                        tas.Loaded[n] = { Frames = d.Frames, Viewports = {}, PathParts = {}, Adornments = {}, Waiting = false, Playing = false }
                    end
                end
            end
            if i % 3 == 0 then task.wait() end
        end
        if tas.ReqPlay then
            for n in pairs(tas.Loaded) do actTas(n) end
        end
    end)
end

tas.DeleteSelected = function()
    if #tas.Selection == 0 then return end
    for _, n in ipairs(tas.Selection) do
        local p = filePath(n)
        if isfile and isfile(p) and delfile then delfile(p) end
        clrTas(n)
        tas.Loaded[n] = nil
    end
    tas.Selection = {}
    return tas.GetSaved()
end

tas.ToggleAll = function(e)
    tas.ReqPlay = e
    if e then
        for n in pairs(tas.Loaded) do actTas(n) end
    else
        -- Para tudo imediatamente, incluindo o Waiting
        for n, d in pairs(tas.Loaded) do
            d.Waiting = false
            clrTas(n)
        end
        tas.LastJump = false
        stpMov()
        chkPlay()
    end
end

tas.ManualStopPlayback = function()
    for n, d in pairs(tas.Loaded) do
        if d.Playing or d.Waiting then
            d.Waiting = false
            clrTas(n, true)
        end
    end
    tas.LastJump = false
    stpMov()
    chkPlay()
end

local function chCmd(m)
    m = m:lower()
    if m == "/e gravar" then tas.StartRecording()
    elseif m == "/e parar" then tas.StopRecording()
    end
end
if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
    tcs.OnIncomingMessage = function(m)
        if m.TextSource and m.TextSource.UserId == lp.UserId then chCmd(m.Text) end
    end
else
    lp.Chatted:Connect(chCmd)
end


-- jjs
env.JJs = nil
_G.JJs = nil

env.JJs = env.JJs or {}
_G.JJs = env.JJs 

local jjs = env.JJs
jjs.Config = jjs.Config or {
    Running = false,
    StartValue = 1,
    EndValue = 100,
    DelayValue = 3,
    RandomDelay = false,
    RandomMin = 2.5,
    RandomMax = 4,
    JumpEnabled = false,
    SpacingEnabled = false,
    ReverseEnabled = false,
    FinishInTime = false,
    FinishTotalTime = 60,
    Suffix = "!",
    CustomSuffix = "",
    Mode = "Padrão"
}

jjs.State = {
    Running = false,
    Current = 0,
    Total = 0,
    FinishTimestamp = 0
}

local u = {[0]="zero",[1]="um",[2]="dois",[3]="três",[4]="quatro",[5]="cinco",[6]="seis",[7]="sete",[8]="oito",[9]="nove",[10]="dez",[11]="onze",[12]="doze",[13]="treze",[14]="quatorze",[15]="quinze",[16]="dezesseis",[17]="dezessete",[18]="dezoito",[19]="dezenove"}
local t = {[2]="vinte",[3]="trinta",[4]="quarenta",[5]="cinquenta",[6]="sessenta",[7]="setenta",[8]="oitenta",[9]="noventa"}
local h = {[1]="cento",[2]="duzentos",[3]="trezentos",[4]="quatrocentos",[5]="quinhentos",[6]="seiscentos",[7]="setecentos",[8]="oitocentos",[9]="novecentos"}
local ac = {["á"]="Á",["à"]="À",["ã"]="Ã",["â"]="Â",["é"]="É",["ê"]="Ê",["í"]="Í",["ó"]="Ó",["ô"]="Ô",["õ"]="Õ",["ú"]="Ú",["ç"]="Ç"}

-- RemoteChat
local RemoteChat = {}
local Connections = {}
local CurrentChannel
local InputBar = tcs:FindFirstChildOfClass("ChatInputBarConfiguration")

local ChatMethods = {
    [Enum.ChatVersion.LegacyChatService] = function(Message)
        if CurrentChannel then
            CurrentChannel:SendAsync(Message)
            return
        end
        local channels = tcs:FindFirstChild("TextChannels")
        local general = channels and channels:FindFirstChild("RBXGeneral")
        if general then
            general:SendAsync(Message)
            return
        end
        local ChatUI = lp:WaitForChild("PlayerGui", 95):FindFirstChild("Chat")
        if ChatUI then
            local ChatBar = ChatUI:FindFirstChild("ChatBar", true)
            if ChatBar then
                ChatBar:CaptureFocus()
                ChatBar.Text = Message
                ChatBar:ReleaseFocus(true)
            end
        end
    end,
    [Enum.ChatVersion.TextChatService] = function(Message)
        if CurrentChannel then
            CurrentChannel:SendAsync(Message)
        end
    end,
}

function RemoteChat:Send(Message)
    pcall(ChatMethods[tcs.ChatVersion], Message)
end

if InputBar then
    if typeof(InputBar.TargetTextChannel) == "Instance" and InputBar.TargetTextChannel:IsA("TextChannel") then
        CurrentChannel = InputBar.TargetTextChannel
    end
    table.insert(Connections, InputBar.Changed:Connect(function(Prop)
        if Prop == "TargetTextChannel" and typeof(InputBar.TargetTextChannel) == "Instance" and InputBar.TargetTextChannel:IsA("TextChannel") then
            CurrentChannel = InputBar.TargetTextChannel
        end
    end))
end

local function sc(m)
    RemoteChat:Send(tostring(m))
end

-- Extenso
local function up(s)
    local r = ""
    for _, c in utf8.codes(s) do
        local ch = utf8.char(c)
        r = r .. (ac[ch] or string.upper(ch))
    end
    return r
end

local function ph(n)
    if n == 0 then return "" end
    if n == 100 then return "cem" end
    local hv = math.floor(n / 100)
    local rv = n % 100
    local p = {}
    if hv > 0 then table.insert(p, h[hv]) end
    if rv > 0 then
        if #p > 0 then table.insert(p, "e") end
        if rv < 20 then
            table.insert(p, u[rv])
        else
            table.insert(p, t[math.floor(rv/10)])
            local uv = rv % 10
            if uv > 0 then 
                table.insert(p, "e")
                table.insert(p, u[uv]) 
            end
        end
    end
    return table.concat(p, " ")
end

local function nt(n)
    n = tonumber(n)
    if not n or n == 0 then return n == 0 and "ZERO" or "N/A" end
    local g, x = {}, {}
    local temp = n
    while temp > 0 do
        table.insert(g, temp % 1000)
        temp = math.floor(temp / 1000)
    end
    for i = #g, 1, -1 do
        local v = g[i]
        if v ~= 0 then
            local txt = ph(v)
            if i == 2 then txt = (v == 1 and "mil" or txt .. " mil")
            elseif i == 3 then txt = (v == 1 and "um milhão" or txt .. " milhões")
            elseif i == 4 then txt = (v == 1 and "um bilhão" or txt .. " bilhões")
            elseif i == 5 then txt = (v == 1 and "um trilhão" or txt .. " trilhões") end
            table.insert(x, txt)
        end
    end
    return up(table.concat(x, " e "))
end

local function gc()
    local c = lp.Character
    return (c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart")) and c or nil
end

local function aj()
    local c = gc()
    if c then
        local hum = c.Humanoid
        if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function as()
    local c = gc()
    if not c then return end
    local h, r = c.Humanoid, c.HumanoidRootPart
    h.AutoRotate = false
    local nv = Instance.new("NumberValue")
    local tw = ts:Create(nv, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Value = 360 * (math.random(1,2)==1 and 1 or -1)})
    local b = r.CFrame.Rotation
    local cn
    cn = rs.Heartbeat:Connect(function()
        if r and r.Parent then
            r.CFrame = CFrame.new(r.Position) * b * CFrame.Angles(0, math.rad(nv.Value), 0)
        else
            cn:Disconnect()
        end
    end)
    tw.Completed:Connect(function()
        cn:Disconnect()
        nv:Destroy()
        if h then h.AutoRotate = true end
    end)
    tw:Play()
end

jjs.Start = function()
    local c = jjs.Config
    if c.Running then return end
    c.Running = true

    task.spawn(function()
        local s = tonumber(c.StartValue) or 1
        local e = tonumber(c.EndValue) or 100
        local dir = (c.ReverseEnabled and s < e) and -1 or 1
        if c.ReverseEnabled then s, e = e, s end

        local currentMode = c.Mode
        if currentMode == "Padrão" and rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos") then
            currentMode = "JJ (Delta)"
        end

        local tot = math.abs(e - s) + 1
        local cnt = 0
        local ft = c.FinishInTime and ((tonumber(c.FinishTotalTime) or 60) / math.max(1, tot)) or nil

        jjs.State.Running = true
        jjs.State.Total = tot
        jjs.State.Current = 0

        local dt = nil
        if currentMode == "JJ (Delta)" then
            local ch = gc()
            if ch then
                local a = Instance.new("Animation")
                a.AnimationId = "rbxassetid://105471471504794"
                dt = ch.Humanoid:LoadAnimation(a)
                dt.Priority = Enum.AnimationPriority.Action
            end
            local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
            if rm then pcall(function() rm:FireServer("Prepare") rm:FireServer("Start") end) end
        end

        for i = s, e, dir do
            if not c.Running then break end
            cnt = cnt + 1
            jjs.State.Current = i

            local delay = ft or (c.RandomDelay and (math.random(c.RandomMin * 10, c.RandomMax * 10) / 10) or (tonumber(c.DelayValue) or 3))
            jjs.State.FinishTimestamp = tick() + ((tot - cnt) * delay)

            local txt = nt(i)
            local sf = (c.CustomSuffix ~= "") and c.CustomSuffix or c.Suffix
            local fn = c.SpacingEnabled and (txt .. " " .. sf) or (txt .. sf)

            if currentMode == "JJ (Delta)" then
                local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
                if rm then pcall(function() rm:FireServer("Add", 1) end) end
                if dt then dt:Play() end
            elseif currentMode == "Canguru" then
                sc(fn)
                task.wait(0.2)
                pcall(function()
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                    task.wait(0.2)
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                end)
                task.wait(0.1)
                aj()
                task.wait(0.2)
                as()
            else
                sc(fn)
                if c.JumpEnabled then aj() end
            end

            if i ~= e then task.wait(delay) end
        end

        c.Running = false
        jjs.State.Running = false
        if dt then dt:Stop() end
    end)
end

jjs.Stop = function()
    jjs.Config.Running = false
    jjs.State.Running = false
end

-- [[ F3X ]] --
env.F3X = env.F3X or {}
local f3x = env.F3X

f3x.Enabled = false
f3x.SelectedParts = {}
f3x.Highlights = {}
f3x.UndoStack = {}
f3x.RedoStack = {}
f3x.ModifiedParts = {}
f3x.UpdateUI = nil
f3x.NotifyFunc = nil
f3x.IsReady = true

local f3x_fDir = "michigun.xyz/f3x"
if writefile and not isfolder(f3x_fDir) then makefolder(f3x_fDir) end

local hlParent
local function getHlParent()
    if hlParent then return hlParent end
    local s, t = pcall(function() return gethui() end)
    hlParent = (s and t) and t or cg
    return hlParent
end

local function clrHl()
    for _, h in ipairs(f3x.Highlights) do if h then h:Destroy() end end
    table.clear(f3x.Highlights)
end

local function mkHl(p)
    task.defer(function()
        if not p or not p.Parent then return end
        local h = Instance.new("Highlight")
        h.Name = hs:GenerateGUID(false)
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = Color3.fromRGB(0, 255, 255)
        h.Adornee = p
        h.Parent = getHlParent()
        table.insert(f3x.Highlights, h)
    end)
end

f3x.ClearSelection = function()
    table.clear(f3x.SelectedParts)
    clrHl()
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

local function pushU()
    local s = {}
    for _, p in ipairs(f3x.SelectedParts) do s[p] = p.Size end
    table.insert(f3x.UndoStack, s)
    table.clear(f3x.RedoStack)
end

f3x.ApplySize = function(v)
    if #f3x.SelectedParts == 0 then return end
    pushU()
    for _, p in ipairs(f3x.SelectedParts) do
        p.Size = v
        f3x.ModifiedParts[p] = v
    end
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.Undo = function()
    local s = table.remove(f3x.UndoStack)
    if not s then return end
    local r = {}
    for p, sz in pairs(s) do
        r[p] = p.Size
        p.Size = sz
        f3x.ModifiedParts[p] = sz
    end
    table.insert(f3x.RedoStack, r)
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.Redo = function()
    local s = table.remove(f3x.RedoStack)
    if not s then return end
    local u = {}
    for p, sz in pairs(s) do
        u[p] = p.Size
        p.Size = sz
        f3x.ModifiedParts[p] = sz
    end
    table.insert(f3x.UndoStack, u)
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.ListConfigs = function()
    local o = {}
    if listfiles then for _, f in ipairs(listfiles(f3x_fDir)) do if f:sub(-5) == ".json" then o[#o + 1] = f:match("([^/]+)%.json$") end end end
    return o
end

f3x.SaveConfig = function(n)
    if not n or n == "" then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Nome inválido", 3, "lucide:alert-circle") end return nil end
    local d = { PlaceId = game.PlaceId, Parts = {} }
    for p, sz in pairs(f3x.ModifiedParts) do
        if p and p.Parent then
            d.Parts[#d.Parts + 1] = { Path = p:GetFullName(), CFrame = { p.CFrame:GetComponents() }, Size = { sz.X, sz.Y, sz.Z } }
        end
    end
    local rj = hs:JSONEncode(d)
    writefile(f3x_fDir .. "/" .. n .. ".json", rj)
    return f3x.ListConfigs()
end

local function getObj(path)
    local segs = {}
    for s in path:gmatch("[^%.]+") do table.insert(segs, s) end
    local cur = game
    for _, s in ipairs(segs) do
        if s ~= "Game" then
            cur = cur:FindFirstChild(s)
            if not cur then return nil end
        end
    end
    return cur
end

f3x.ApplyConfig = function(n)
    if not n then return end
    local p = f3x_fDir .. "/" .. n .. ".json"
    if not isfile(p) then return end
    local c = readfile(p)
    local d = nil
    
    pcall(function() d = hs:JSONDecode(c) end)

    if not d then return end
    if d.PlaceId ~= game.PlaceId then 
        if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Config de outro mapa", 3, "lucide:alert-circle") end 
        return 
    end

    for _, v in ipairs(d.Parts or {}) do
        local targetCf = CFrame.new(unp(v.CFrame))
        local foundPart = nil

        local obj = getObj(v.Path)
        if obj and obj:IsA("BasePart") and (obj.Position - targetCf.Position).Magnitude < 2 then
            foundPart = obj
        else
            for _, o in ipairs(ws:GetDescendants()) do
                if o:IsA("BasePart") and o:GetFullName() == v.Path then
                    if (o.Position - targetCf.Position).Magnitude < 2 then
                        foundPart = o
                        break
                    end
                end
            end
        end
        
        if foundPart then
            foundPart.Size = Vector3.new(unp(v.Size))
            f3x.ModifiedParts[foundPart] = foundPart.Size
        end
    end
end

f3x.DeleteConfig = function(n)
    if not n then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Nenhuma seleção", 3, "lucide:alert-circle") end return nil end
    delfile(f3x_fDir .. "/" .. n .. ".json")
    return f3x.ListConfigs()
end

f3x.Toggle = function(s)
    f3x.Enabled = s
    if not s then f3x.ClearSelection() end
end

local f3xMouseConn
if lp then
    local ms = lp:GetMouse()
    f3xMouseConn = ms.Button1Down:Connect(function()
        if not f3x.Enabled then return end
        local t = ms.Target
        if not t or not t:IsA("BasePart") then return end
        
        for i, p in ipairs(f3x.SelectedParts) do
            if p == t then
                table.remove(f3x.SelectedParts, i)
                clrHl()
                for _, sp in ipairs(f3x.SelectedParts) do mkHl(sp) end
                if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
                return
            end
        end
        
        if #f3x.SelectedParts > 0 then
            local ref = f3x.SelectedParts[1].Size
            local ts = t.Size
            if math.abs(ref.X - ts.X) > 1 or math.abs(ref.Y - ts.Y) > 1 or math.abs(ref.Z - ts.Z) > 1 then
                return
            end
        end
        
        table.insert(f3x.SelectedParts, t)
        mkHl(t)
        if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
    end)
end

-- [[ ChatGPT / IA ]] --
local HttpRequest = request or http and http.request or http_request or syn and syn.request

_G.ChatGPT = _G.ChatGPT or {}
_G.ChatGPT.History = {}
_G.ChatGPT.LastMessage = ""

local PromptPath = "michigun.xyz/IA.txt"
if not isfile(PromptPath) then writefile(PromptPath, "Você é uma IA útil dentro do Roblox.") end

local Personality = readfile(PromptPath)
_G.ChatGPT.History = {{role = "system", content = Personality}}

local function extractLuaCode(responseText)
    local luaCode = responseText:match("```lua\n?(.-)```") or responseText:match("```\n?(.-)```")
    if luaCode then
        local cleanText = responseText:gsub("```lua\n?.-```", ""):gsub("```\n?.-```", "")
        return luaCode, cleanText
    end
    return nil, responseText
end

_G.ChatGPT.Ask = function(promptText)
    table.insert(_G.ChatGPT.History, {role = "user", content = promptText})

    local success, response = pcall(function()
        return HttpRequest({
            Url = "https://text.pollinations.ai/openai",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = hs:JSONEncode({
                messages = _G.ChatGPT.History,
                model = "openai"
            })
        })
    end)

    if not success or not response then
        return "Erro de conexão com a API.", nil
    end

    local aiText = ""
    local decodeSuccess, decoded = pcall(function() return hs:JSONDecode(response.Body) end)
    
    if decodeSuccess and decoded.choices and decoded.choices[1] then
        aiText = decoded.choices[1].message.content
    else
        aiText = response.Body
    end

    local luaCode, cleanMessage = extractLuaCode(aiText)

    _G.ChatGPT.LastMessage = cleanMessage
    table.insert(_G.ChatGPT.History, {role = "assistant", content = aiText})

    return cleanMessage, luaCode
end

_G.ChatGPT.SendToChat = function(msg)
    if not msg or msg == "" then return end
    
    local msgString = tostring(msg)
    
    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
        local channels = tcs:WaitForChild("TextChannels", 2)
        if channels then
            local target = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildOfClass("TextChannel")
            if target then
                target:SendAsync(msgString)
            end
        end
    else
        local events = rep:FindFirstChild("DefaultChatSystemChatEvents")
        if events then
            local say = events:FindFirstChild("SayMessageRequest")
            if say then
                say:FireServer(msgString, "All")
            end
        end
    end
end

end)
