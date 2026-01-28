if not _G.AimbotConfig then
    _G.AimbotConfig = {
        Enabled = false,
        TeamCheck = "Team",
        TargetPart = {"Random"},
        TargetPriority = "Distance",
        MaxDistance = 1000,
        SwitchThreshold = 1,
        WhitelistedUsers = {},
        WhitelistedTeams = {},
        FocusList = {},
        FocusMode = false,
        UseLegitOffset = true,
        HitChance = 60,
        WallCheck = true,
        FOVSize = 200,
        ShowFOV = true,
        FOVBehavior = "Center",
        FOVColor1 = Color3.fromRGB(255, 255, 255),
        ShowHighlight = true,
        HighlightColor = Color3.fromRGB(255, 60, 60),
        ESP = {
            Enabled = true,
            ShowName = true,
            ShowTeam = true,
            ShowHealth = true,
            ShowWeapon = true,
            TextColor = Color3.fromRGB(255, 255, 255),
            OutlineColor = Color3.fromRGB(255, 60, 60),
        }
    }
end

task.spawn(function()
    pcall(function() ler("silent") end)
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeamsService = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

local function GetTeamNames()
    local names = {}
    if TeamsService then
        for _, t in pairs(TeamsService:GetTeams()) do table.insert(names, t.Name) end
    end
    return names
end

do
    local FirstRun = true

    local MainSection = criarsection(SilentAim, "Principal", "Controle do silent aim", "lucide:crosshair", true)

    local ToggleAim = MainSection:Toggle({
        Title = "Silent aim",
        Desc = "Permite matar alvos com facilidade",
        Icon = "lucide:power",
        Type = "Checkbox",
        Value = false,
        Flag = "SilentAim",
        Callback = function(state) 
            if FirstRun then
                FirstRun = false
                if state then
                    if _G.StartSilentAim then _G.StartSilentAim() end
                else
                    if _G.StopSilentAim then _G.StopSilentAim() end
                end
                return
            end

            if state then
                if _G.StartSilentAim then _G.StartSilentAim() end
                notificar("Ativado", 2, "lucide:circle-check")
            else
                if _G.StopSilentAim then _G.StopSilentAim() end
                notificar("Desativado", 2, "lucide:circle-x")
            end
        end
    })
    
    local CurrentKey = Enum.KeyCode.Q

    MainSection:Keybind({
        Title = "Keybind",
        Desc = "Tecla para ativar / desativar o silent aim",
        Value = "Q",
        Flag = "KeybindSilentAim",
        Callback = function(v)
            if v and Enum.KeyCode[v] then
                CurrentKey = Enum.KeyCode[v]
            end
        end
    })

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == CurrentKey then
            local newState = not ToggleAim.Value
            ToggleAim:SetValue(newState)
        end
    end)

    MainSection:Slider({
        Title = "Hit chance",
        Desc = "Porcentagem de tiros que acertarão o alvo",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = _G.AimbotConfig.HitChance },
        Flag = "ChanceSilentAim",
        Callback = function(value) _G.AimbotConfig.HitChance = value end
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
        Desc = "Não foca nesses jogadores",
        Values = GetPlayerNames(),
        Value = {}, 
        Multi = true,
        AllowNone = true,
        Flag = "WhitelistPlayersSilentAim",
        Callback = function(options) _G.AimbotConfig.WhitelistedUsers = options end
    })

    WhitelistSection:Dropdown({
        Title = "Ignorar times",
        Desc = "Não foca nesses times",
        Values = GetTeamNames(),
        Value = {},
        Multi = true,
        AllowNone = true,
        Flag = "WhitelistTimesSilentAim",
        Callback = function(options) _G.AimbotConfig.WhitelistedTeams = options end
    })

    local FocusSection = criarsection(SilentAim, "Focar", "Focar em jogadores específicos", "lucide:scan-eye", false)

    local FocusFirstRun = true
    FocusSection:Toggle({
        Title = "Modo foco",
        Desc = "Foca apenas em quem está na lista",
        Icon = "lucide:focus",
        Type = "Checkbox",
        Value = _G.AimbotConfig.FocusMode,
        Flag = "ModoFocarSilentAim",
        Callback = function(state)
            _G.AimbotConfig.FocusMode = state
            if FocusFirstRun then
                FocusFirstRun = false
                return
            end
            notificar("Modo Foco: " .. (state and "Ativado" or "Desativado"), 2, "lucide:circle-alert")
        end
    })

    local FocusListParagraph = nil
    local RemoveDropdown = nil

    local function UpdateFocusUI()
        if FocusListParagraph then
            local listStr = table.concat(_G.AimbotConfig.FocusList, ", ")
            if listStr == "" then listStr = "Nenhum alvo definido." end
            FocusListParagraph:SetDesc(listStr)
        end
        if RemoveDropdown then
            RemoveDropdown:Refresh(_G.AimbotConfig.FocusList)
        end
    end

    FocusSection:Input({
        Title = "Adicionar alvo",
        Desc = "Digite o nome",
        Placeholder = "sanctuaryangels",
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
                if not table.find(_G.AimbotConfig.FocusList, foundName) then
                    table.insert(_G.AimbotConfig.FocusList, foundName)
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
        Desc = "Selecione para excluir",
        Values = {},
        Value = nil,
        Multi = false,
        AllowNone = true,
        Callback = function(val)
            if val then
                local idx = table.find(_G.AimbotConfig.FocusList, val)
                if idx then
                    table.remove(_G.AimbotConfig.FocusList, idx)
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
                    _G.AimbotConfig.FocusList = {}
                    UpdateFocusUI()
                    notificar("Lista limpa", 2, "lucide:trash")
                end
            }
        }
    })

    local LogicSection = criarsection(SilentAim, "Configurações", "Ajustar configurações do silent aim", "lucide:settings-2", false)

    LogicSection:Dropdown({
        Title = "Prioridade",
        Desc = "Escolhe o alvo baseado em",
        Values = {"Distance", "Health"},
        Value = "Distance",
        Flag = "PrioridadeSilentAim",
        Callback = function(option) _G.AimbotConfig.TargetPriority = option end
    })

    LogicSection:Dropdown({
        Title = "Partes",
        Desc = "Onde o tiro deve ir",
        Values = { 
            "Random", "Head", "Torso",
            "Left Arm", "Right Arm", "Left Leg", "Right Leg"
        },
        Value = {"Random"},
        Multi = true,
        AllowNone = true,
        Flag = "PartesSilentAim",
        Callback = function(option) _G.AimbotConfig.TargetPart = option end
    })

    LogicSection:Dropdown({
        Title = "Alvos",
        Desc = "Quem deve ser atacado",
        Values = { "Todos", "Inimigos" },
        Value = "Inimigos",
        Flag = "AlvosSilentAim",
        Callback = function(option) _G.AimbotConfig.TeamCheck = (option == "Todos") and "All" or "Team" end
    })

    LogicSection:Toggle({
        Title = "Humanizar",
        Desc = "O tiro sairá mais legit",
        Icon = "lucide:user-check",
        Type = "Checkbox",
        Value = _G.AimbotConfig.UseLegitOffset,
        Flag = "LegitSilentAim",
        Callback = function(state) _G.AimbotConfig.UseLegitOffset = state end
    })

    LogicSection:Toggle({
        Title = "Wall check",
        Desc = "Ignora inimigos atrás de paredes",
        Icon = "lucide:brick-wall",
        Type = "Checkbox",
        Value = _G.AimbotConfig.WallCheck,
        Flag = "WallcheckSilentAim",
        Callback = function(state) _G.AimbotConfig.WallCheck = state end
    })

    LogicSection:Slider({
        Title = "Distância máxima",
        Desc = "Mede o quão longe o silent aim irá",
        Step = 10,
        Value = { Min = 50, Max = 5000, Default = _G.AimbotConfig.MaxDistance },
        Flag = "AlcanceSilentAim",
        Callback = function(value) _G.AimbotConfig.MaxDistance = value end
    })

    local VisualsSection = criarsection(SilentAim, "Interface Visual", "Customizar aparência", "lucide:palette", false)

    VisualsSection:Toggle({
        Title = "FOV",
        Desc = "Ativa o FOV",
        Icon = "lucide:circle",
        Type = "Checkbox",
        Value = _G.AimbotConfig.ShowFOV,
        Flag = "FOV",
        Callback = function(state) _G.AimbotConfig.ShowFOV = state end
    })

    VisualsSection:Dropdown({
        Title = "Posição",
        Desc = "Modifica a posição do FOV",
        Values = { "Mouse", "Center" },
        Value = "Center",
        Flag = "PosicaoFOV",
        Callback = function(option) _G.AimbotConfig.FOVBehavior = option end
    })

    VisualsSection:Slider({
        Title = "Tamanho",
        Desc = "Modifica o tamanho do FOV",
        Step = 5,
        Value = { Min = 40, Max = 1000, Default = _G.AimbotConfig.FOVSize },
        Flag = "TamanhoFOV",
        Callback = function(value) _G.AimbotConfig.FOVSize = value end
    })

    VisualsSection:Colorpicker({
        Title = "Cor",
        Desc = "Modifica a cor do FOV",
        Default = _G.AimbotConfig.FOVColor1,
        Transparency = 0,
        Locked = false,
        Flag = "CorFOV",
        Callback = function(color) _G.AimbotConfig.FOVColor1 = color end
    })

    VisualsSection:Toggle({
        Title = "Highlight",
        Desc = "Brilha a pessoa focada",
        Icon = "lucide:sparkles",
        Type = "Checkbox",
        Value = _G.AimbotConfig.ShowHighlight,
        Flag = "HighlightSilentAim",
        Callback = function(state) _G.AimbotConfig.ShowHighlight = state end
    })

    VisualsSection:Colorpicker({
        Title = "Cor da info",
        Desc = "Cor do highlight e do HUD",
        Default = _G.AimbotConfig.HighlightColor,
        Transparency = 0,
        Locked = false,
        Flag = "HighlightCorSilentAim",
        Callback = function(color) _G.AimbotConfig.HighlightColor = color end
    })

    local InfoSection = criarsection(SilentAim, "HUD", "Informações dos alvos", "lucide:layout-template", false)

    local ToggleName, ToggleHP, ToggleWeapon, ToggleTeam

    local ToggleESP = InfoSection:Toggle({
        Title = "HUD",
        Desc = "Mostra informações do alvo quando focado",
        Icon = "lucide:app-window",
        Type = "Checkbox",
        Value = _G.AimbotConfig.ESP.Enabled,
        Flag = "InfoSilentAim",
        Callback = function(state) 
            _G.AimbotConfig.ESP.Enabled = state
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
        Value = _G.AimbotConfig.ESP.ShowName,
        Flag = "InfoNomeSilentAim",
        Callback = function(state) _G.AimbotConfig.ESP.ShowName = state end
    })

    ToggleTeam = InfoSection:Toggle({
        Title = "Time",
        Desc = "Mostra o time do jogador",
        Icon = "lucide:users",
        Type = "Checkbox",
        Value = _G.AimbotConfig.ESP.ShowTeam,
        Flag = "InfoTimeSilentAim",
        Callback = function(state) _G.AimbotConfig.ESP.ShowTeam = state end
    })

    ToggleHP = InfoSection:Toggle({
        Title = "Vida",
        Desc = "Mostra a vida do alvo",
        Icon = "lucide:heart-pulse",
        Type = "Checkbox",
        Value = _G.AimbotConfig.ESP.ShowHealth,
        Flag = "InfoVidaSilentAim",
        Callback = function(state) _G.AimbotConfig.ESP.ShowHealth = state end
    })

    ToggleWeapon = InfoSection:Toggle({
        Title = "Item",
        Desc = "Mostra o que o alvo está segurando",
        Icon = "lucide:sword",
        Type = "Checkbox",
        Value = _G.AimbotConfig.ESP.ShowWeapon,
        Flag = "InfoItemSilentAim",
        Callback = function(state) _G.AimbotConfig.ESP.ShowWeapon = state end
    })
    
    if not _G.AimbotConfig.ESP.Enabled then
        ToggleName:Lock(); ToggleTeam:Lock(); ToggleHP:Lock(); ToggleWeapon:Lock()
    end
end
