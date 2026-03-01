--[[
    jogos.lua
    Interface pública preservada:
        getgenv().TAS           → módulo TAS completo
        getgenv().JJs / _G.JJs  → módulo JJs completo
        getgenv().F3X           → módulo F3X completo
        _G.ChatGPT              → módulo ChatGPT completo
]]

-- ─────────────────────────────────────────────
-- Serviços
-- ─────────────────────────────────────────────
local cloneref        = cloneref or function(o) return o end
local Players         = cloneref(game:GetService("Players"))
local Workspace       = cloneref(game:GetService("Workspace"))
local RunService      = cloneref(game:GetService("RunService"))
local HttpService     = cloneref(game:GetService("HttpService"))
local TextChat        = cloneref(game:GetService("TextChatService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local VirtualInput    = cloneref(game:GetService("VirtualInputManager"))
local TweenService    = cloneref(game:GetService("TweenService"))
local CoreGui         = cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local env         = getgenv()

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end

local function safeGui()
    local ok, hui = pcall(gethui)
    return (ok and hui) and hui or CoreGui
end

-- ═══════════════════════════════════════════════════════
-- TAS
-- ═══════════════════════════════════════════════════════
local TAS_FOLDER = "michigun.xyz/tas"
if writefile and not isfolder(TAS_FOLDER) then makefolder(TAS_FOLDER) end

-- ScreenGui para viewports
local tasGui = Instance.new("ScreenGui")
tasGui.Name, tasGui.ResetOnSpawn = ".", false
local existingGui = safeGui():FindFirstChild(".")
if existingGui then existingGui:Destroy() end
tasGui.Parent = safeGui()

-- Enum de estados do humanoid cacheado
local humanoidStateEnums = {}
for _, item in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
    humanoidStateEnums[item.Value] = item
end

env.TAS = env.TAS or {}
local TAS = env.TAS

TAS.Loaded       = TAS.Loaded    or {}
TAS.Selection    = TAS.Selection or {}
TAS.Recording    = false
TAS.ReqPlay      = false
TAS.RecFrames    = {}
TAS.CurrentName  = ""
TAS.RecConn      = nil
TAS.IsReady      = true
TAS.LastJump     = false
TAS.ActRad       = 1
TAS.ActH         = 1.5
TAS.ActAng       = 10
TAS.ColorBot     = Color3.fromRGB(0, 255, 0)
TAS.ColorPath    = Color3.fromRGB(0, 255, 0)
TAS.VisualOpacity = 0
TAS.NotifyFunc   = nil
TAS.UpdateButtonState = nil

-- ── Utilitários internos TAS ──

local function tasNotify(title, msg)
    if TAS.NotifyFunc then TAS.NotifyFunc(title .. ": " .. msg, 3, "lucide:info") end
end

local function tasStopMovement()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = true
        hum:Move(Vector3.zero)
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local touchGui  = playerGui and playerGui:FindFirstChild("TouchGui")
    if touchGui then
        touchGui.Enabled = false
        task.spawn(function()
            for _ = 1, 10 do
                if touchGui then touchGui.Enabled = true end
                task.wait(0.1)
            end
        end)
    end
end

local function tasUpdateButtonState()
    local isPlaying = false
    for _, data in pairs(TAS.Loaded) do
        if data.Playing then isPlaying = true; break end
    end
    if TAS.UpdateButtonState then TAS.UpdateButtonState(isPlaying) end
end

-- ── Captura e aplicação de frames ──

local function captureFrame()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return nil end

    local cf = {root.CFrame:GetComponents()}
    local vel = root.AssemblyLinearVelocity

    return {
        cf    = cf,
        vel   = { vel.X, vel.Y, vel.Z },
        jump  = hum.Jump,
        state = hum:GetState().Value,
    }
end

local function applyFrame(frame, root, hum)
    if not frame or not root or not hum then return end

    if frame.cf then
        root.CFrame = CFrame.new(table.unpack(frame.cf))
    end

    if frame.vel then
        root.AssemblyLinearVelocity = Vector3.new(table.unpack(frame.vel))
    end

    if frame.jump ~= TAS.LastJump then
        if frame.jump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        TAS.LastJump = frame.jump
    end

    local stateEnum = humanoidStateEnums[frame.state]
    if stateEnum then
        if stateEnum ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= stateEnum then
            hum:ChangeState(stateEnum)
        end
        hum.AutoRotate = false
    end
end

-- ── Viewport (preview visual no início do TAS) ──

local function createViewport(part)
    local vpFrame = Instance.new("ViewportFrame")
    local vpCamera = Instance.new("Camera")

    vpFrame.Parent               = tasGui
    vpFrame.BackgroundTransparency = 1
    vpFrame.Size                 = UDim2.new(0, 150, 0, 150)
    vpFrame.ZIndex               = 10
    vpCamera.Parent              = vpFrame

    local clone = part:Clone()
    clone.Transparency = 0
    clone.Material     = Enum.Material.Neon
    clone.CFrame       = CFrame.new()
    clone.Parent       = vpFrame

    local maxDim = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z)
    vpCamera.CFrame = CFrame.new(0, maxDim, maxDim * 2.5)
        * CFrame.Angles(math.rad(-20), math.rad(180), 0)

    local connection = RunService.Stepped:Connect(function()
        if not part or not part.Parent then return end
        local screenPos, visible = Camera:WorldToScreenPoint(part.Position)
        vpFrame.Position = UDim2.fromOffset(screenPos.X - 75, screenPos.Y - 75)
        vpFrame.Visible  = visible
        clone.CFrame     = CFrame.Angles(0, tick() % (math.pi * 2), 0)
    end)

    return { Frame = vpFrame, Connection = connection, Part = part }
end

-- ── Construção do path visual ──

local function buildPathVisuals(frames, parent)
    local parts = {}
    if not frames or #frames < 2 then return parts end

    for i = 1, #frames - 1 do
        local a, b = frames[i], frames[i + 1]
        if a.cf and b.cf then
            local startPos = Vector3.new(a.cf[1], a.cf[2], a.cf[3])
            local endPos   = Vector3.new(b.cf[1], b.cf[2], b.cf[3])
            local distance = (endPos - startPos).Magnitude

            if distance > 0.05 then
                local cylinder = Instance.new("CylinderHandleAdornment")
                cylinder.Radius       = 0.05
                cylinder.Height       = distance
                cylinder.CFrame       = CFrame.new(startPos:Lerp(endPos, 0.5), endPos)
                cylinder.Color3       = TAS.ColorPath
                cylinder.Transparency = TAS.VisualOpacity
                cylinder.Adornee      = Workspace.Terrain
                cylinder.ZIndex       = 0
                cylinder.Parent       = parent
                table.insert(parts, cylinder)
            end
        end
    end

    return parts
end

-- ── Limpeza de um TAS ──

local function clearTasEntry(name)
    local data = TAS.Loaded[name]
    if not data then return end

    if data.MarkerConn then data.MarkerConn:Disconnect() end
    if data.PlayConn   then data.PlayConn:Disconnect() end

    tasStopMovement()

    if data.VisualFolder then data.VisualFolder:Destroy() end

    if data.Viewports then
        for _, vp in ipairs(data.Viewports) do
            if vp.Connection then vp.Connection:Disconnect() end
            if vp.Frame      then vp.Frame:Destroy() end
        end
    end

    if data.PathParts then
        for _, part in ipairs(data.PathParts) do
            if part then part:Destroy() end
        end
    end

    data.VisualFolder = nil
    data.Viewports    = {}
    data.PathParts    = {}
    data.Waiting      = false
    data.Playing      = false

    tasUpdateButtonState()
end

-- ── Construção dos visuais do boneco ──

local function buildBotVisuals(folder, startCFrame, color, opacity)
    local function makeAdornment(name, isBox, size, offset, angleOffset)
        local adorn = isBox
            and Instance.new("BoxHandleAdornment")
            or  Instance.new("CylinderHandleAdornment")

        if isBox then
            adorn.Size = size
        else
            adorn.Radius = size.X
            adorn.Height = size.Y
        end

        local cf = offset and (startCFrame * CFrame.new(offset)) or startCFrame
        if angleOffset then cf = cf * angleOffset end

        adorn.Name         = name
        adorn.CFrame       = cf
        adorn.Color3       = color
        adorn.Transparency = opacity
        adorn.Adornee      = Workspace.Terrain
        adorn.ZIndex       = 1
        adorn.Parent       = folder
    end

    makeAdornment("Torso",    true,  Vector3.new(2, 2, 1),   nil)
    makeAdornment("LeftLeg",  true,  Vector3.new(1, 2, 1),   Vector3.new(-0.5, -2, 0))
    makeAdornment("RightLeg", true,  Vector3.new(1, 2, 1),   Vector3.new( 0.5, -2, 0))
    makeAdornment("LeftArm",  true,  Vector3.new(1, 2, 1),   Vector3.new(-1.5,  0, 0))
    makeAdornment("RightArm", true,  Vector3.new(1, 2, 1),   Vector3.new( 1.5,  0.5, -1),
        CFrame.Angles(math.rad(90), 0, 0))
end

-- ── Ativação (waiting + playback) ──

local function activateTas(name)
    local data = TAS.Loaded[name]
    if not data or not data.Frames or #data.Frames == 0 then return end
    if data.Waiting or data.Playing then return end

    clearTasEntry(name)
    data.Waiting = true

    local firstFrame = data.Frames[1].cf
    local startCFrame = CFrame.new(table.unpack(firstFrame))

    -- Pasta de visuais
    local folder = Instance.new("Folder")
    folder.Name   = "_" .. name
    folder.Parent = safeGui()
    data.VisualFolder = folder

    -- Boneco visual
    buildBotVisuals(folder, startCFrame, TAS.ColorBot, TAS.VisualOpacity)

    -- Viewport
    local dummyPart = Instance.new("Part")
    dummyPart.Size        = Vector3.new(2, 2, 1)
    dummyPart.CFrame      = startCFrame
    dummyPart.Transparency = 1
    dummyPart.Anchored    = true
    dummyPart.CanCollide  = false
    table.insert(data.Viewports, createViewport(dummyPart))

    -- Path visual
    data.PathParts = buildPathVisuals(data.Frames, folder)

    -- Aguarda jogador chegar na posição de início
    data.MarkerConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local delta        = root.Position - startCFrame.Position
        local horizontalDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
        local verticalDist   = math.abs(delta.Y)
        local lookAlignment  = root.CFrame.LookVector:Dot(startCFrame.LookVector)

        local inRadius  = horizontalDist <= TAS.ActRad
        local inHeight  = verticalDist   <= TAS.ActH
        local inAngle   = lookAlignment  >= math.cos(math.rad(TAS.ActAng))

        if not (inRadius and inHeight and inAngle) then return end

        -- Chegou na posição — inicia playback
        data.MarkerConn:Disconnect()
        folder:Destroy()
        for _, vp in ipairs(data.Viewports) do
            if vp.Connection then vp.Connection:Disconnect() end
            if vp.Frame      then vp.Frame:Destroy() end
        end
        for _, part in ipairs(data.PathParts) do
            if part then part:Destroy() end
        end

        data.Waiting  = false
        data.Playing  = true
        tasUpdateButtonState()

        local startTime = tick()
        local lastChar  = LocalPlayer.Character
        local cachedRoot = lastChar and lastChar:FindFirstChild("HumanoidRootPart")
        local cachedHum  = lastChar and lastChar:FindFirstChildOfClass("Humanoid")

        data.PlayConn = RunService.Heartbeat:Connect(function()
            local currentChar = LocalPlayer.Character
            if currentChar ~= lastChar then
                lastChar   = currentChar
                cachedRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
                cachedHum  = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
            end

            local frameIndex = math.floor((tick() - startTime) * 60) + 1
            if frameIndex > #data.Frames then
                tasStopMovement()
                data.PlayConn:Disconnect()
                data.Playing = false
                tasUpdateButtonState()
                return
            end

            applyFrame(data.Frames[frameIndex], cachedRoot, cachedHum)
        end)
    end)
end

-- ── API pública TAS ──

TAS.UpdateVisuals = function(botColor, pathColor, opacity)
    if botColor  ~= nil then TAS.ColorBot      = botColor  end
    if pathColor ~= nil then TAS.ColorPath     = pathColor end
    if opacity   ~= nil then TAS.VisualOpacity = opacity   end

    for _, data in pairs(TAS.Loaded) do
        if data.VisualFolder then
            for _, adorn in ipairs(data.VisualFolder:GetChildren()) do
                if adorn:IsA("BoxHandleAdornment") or adorn:IsA("CylinderHandleAdornment") then
                    adorn.Color3       = TAS.ColorBot
                    adorn.Transparency = TAS.VisualOpacity
                end
            end
        end
        if data.PathParts then
            for _, part in ipairs(data.PathParts) do
                part.Color3       = TAS.ColorPath
                part.Transparency = TAS.VisualOpacity
            end
        end
    end
end

TAS.StartRecording = function()
    if TAS.Recording then return end
    TAS.RecFrames = {}
    TAS.Recording = true

    local accumulator = 0
    local idleTimer   = 0
    local FRAME_RATE  = 1 / 60

    TAS.RecConn = RunService.Heartbeat:Connect(function(dt)
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            idleTimer = root.AssemblyLinearVelocity.Magnitude < 0.2 and (idleTimer + dt) or 0
        end

        if idleTimer >= 1 then
            TAS.StopRecording()
            return
        end

        accumulator = accumulator + dt
        while accumulator >= FRAME_RATE do
            accumulator = accumulator - FRAME_RATE
            local frame = captureFrame()
            if frame then table.insert(TAS.RecFrames, frame) end
        end
    end)

    tasNotify("TAS", "Gravação iniciada")
end

TAS.StopRecording = function()
    if not TAS.Recording then return end
    TAS.Recording = false
    if TAS.RecConn then TAS.RecConn:Disconnect(); TAS.RecConn = nil end
    tasNotify("TAS", string.format("Gravação parada (%.2fs)", #TAS.RecFrames / 60))
end

TAS.SaveCurrent = function()
    if not TAS.CurrentName or TAS.CurrentName == "" then return nil end
    if #TAS.RecFrames == 0 then return nil end

    local encoded = HttpService:JSONEncode({ Version = 1, Frames = TAS.RecFrames })
    writefile(TAS_FOLDER .. "/" .. TAS.CurrentName .. ".json", encoded)
    TAS.RecFrames = {}

    return TAS.GetSaved()
end

TAS.GetSaved = function()
    local result = {}
    if listfiles then
        for _, path in ipairs(listfiles(TAS_FOLDER)) do
            if path:sub(-5) == ".json" then
                table.insert(result, path:match("([^/]+)%.json$"))
            end
        end
    end
    return result
end

TAS.UpdateSelection = function(selection)
    TAS.Selection = type(selection) == "table" and selection or { selection }

    -- Remove entradas que não estão mais na seleção
    for name in pairs(TAS.Loaded) do
        if not table.find(TAS.Selection, name) then
            clearTasEntry(name)
            TAS.Loaded[name] = nil
        end
    end

    -- Carrega novas entradas
    task.spawn(function()
        for i, name in ipairs(TAS.Selection) do
            if not TAS.Loaded[name] and name ~= "" then
                local path = TAS_FOLDER .. "/" .. name .. ".json"
                if isfile(path) then
                    local raw = readfile(path)
                    local decoded
                    pcall(function() decoded = HttpService:JSONDecode(raw) end)

                    if decoded and decoded.Frames then
                        TAS.Loaded[name] = {
                            Frames    = decoded.Frames,
                            Viewports = {},
                            PathParts = {},
                            Waiting   = false,
                            Playing   = false,
                        }
                    end
                end
            end
            if i % 3 == 0 then task.wait() end
        end

        if TAS.ReqPlay then
            for name in pairs(TAS.Loaded) do activateTas(name) end
        end
    end)
end

TAS.DeleteSelected = function()
    if #TAS.Selection == 0 then return end

    for _, name in ipairs(TAS.Selection) do
        local path = TAS_FOLDER .. "/" .. name .. ".json"
        if isfile(path) and delfile then delfile(path) end
        clearTasEntry(name)
        TAS.Loaded[name] = nil
    end

    TAS.Selection = {}
    return TAS.GetSaved()
end

TAS.ToggleAll = function(enable)
    TAS.ReqPlay = enable
    if enable then
        for name in pairs(TAS.Loaded) do activateTas(name) end
    else
        for name in pairs(TAS.Loaded) do clearTasEntry(name) end
        tasStopMovement()
        tasUpdateButtonState()
    end
end

TAS.ManualStopPlayback = function()
    for _, data in pairs(TAS.Loaded) do
        if data.Playing and data.PlayConn then
            tasStopMovement()
            data.PlayConn:Disconnect()
            data.Playing = false
        end
    end
    tasUpdateButtonState()
end

-- Comandos de chat para TAS
local function handleChatCommand(message)
    message = message:lower()
    if message == "/e gravar" then TAS.StartRecording()
    elseif message == "/e parar" then TAS.StopRecording()
    end
end

if TextChat.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChat.OnIncomingMessage = function(msg)
        if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then
            handleChatCommand(msg.Text)
        end
    end
else
    LocalPlayer.Chatted:Connect(handleChatCommand)
end

-- ═══════════════════════════════════════════════════════
-- JJs (Jumping Jacks)
-- ═══════════════════════════════════════════════════════
env.JJs = env.JJs or {}
_G.JJs  = env.JJs

local JJs = env.JJs

JJs.Config = JJs.Config or {
    Running        = false,
    StartValue     = 1,
    EndValue       = 100,
    DelayValue     = 3,
    RandomDelay    = false,
    RandomMin      = 2.5,
    RandomMax      = 4,
    JumpEnabled    = false,
    SpacingEnabled = false,
    ReverseEnabled = false,
    FinishInTime   = false,
    FinishTotalTime = 60,
    Suffix         = "!",
    CustomSuffix   = "",
    Mode           = "Padrão",
}

JJs.State = {
    Running          = false,
    Current          = 0,
    Total            = 0,
    FinishTimestamp  = 0,
}

-- ── Conversor de números para extenso (PT-BR) ──

local UNITS = {
    [0]="zero",[1]="um",[2]="dois",[3]="três",[4]="quatro",[5]="cinco",
    [6]="seis",[7]="sete",[8]="oito",[9]="nove",[10]="dez",[11]="onze",
    [12]="doze",[13]="treze",[14]="quatorze",[15]="quinze",[16]="dezesseis",
    [17]="dezessete",[18]="dezoito",[19]="dezenove",
}
local TENS = {
    [2]="vinte",[3]="trinta",[4]="quarenta",[5]="cinquenta",
    [6]="sessenta",[7]="setenta",[8]="oitenta",[9]="noventa",
}
local HUNDREDS = {
    [1]="cento",[2]="duzentos",[3]="trezentos",[4]="quatrocentos",
    [5]="quinhentos",[6]="seiscentos",[7]="setecentos",[8]="oitocentos",[9]="novecentos",
}
local ACCENTS = {
    ["á"]="Á",["à"]="À",["ã"]="Ã",["â"]="Â",["é"]="É",["ê"]="Ê",
    ["í"]="Í",["ó"]="Ó",["ô"]="Ô",["õ"]="Õ",["ú"]="Ú",["ç"]="Ç",
}

local function toUpperPTBR(str)
    local result = ""
    for _, code in utf8.codes(str) do
        local char = utf8.char(code)
        result = result .. (ACCENTS[char] or string.upper(char))
    end
    return result
end

local function hundredsToWords(n)
    if n == 0   then return "" end
    if n == 100 then return "cem" end

    local parts      = {}
    local hundredVal = math.floor(n / 100)
    local remainder  = n % 100

    if hundredVal > 0 then table.insert(parts, HUNDREDS[hundredVal]) end

    if remainder > 0 then
        if #parts > 0 then table.insert(parts, "e") end
        if remainder < 20 then
            table.insert(parts, UNITS[remainder])
        else
            table.insert(parts, TENS[math.floor(remainder / 10)])
            local unitVal = remainder % 10
            if unitVal > 0 then
                table.insert(parts, "e")
                table.insert(parts, UNITS[unitVal])
            end
        end
    end

    return table.concat(parts, " ")
end

local function numberToWords(n)
    n = tonumber(n)
    if not n      then return "N/A" end
    if n == 0     then return "ZERO" end

    local groups = {}
    local temp   = n
    while temp > 0 do
        table.insert(groups, temp % 1000)
        temp = math.floor(temp / 1000)
    end

    local parts = {}
    for i = #groups, 1, -1 do
        local val = groups[i]
        if val ~= 0 then
            local text = hundredsToWords(val)
            if     i == 2 then text = val == 1 and "mil" or text .. " mil"
            elseif i == 3 then text = val == 1 and "um milhão"  or text .. " milhões"
            elseif i == 4 then text = val == 1 and "um bilhão"  or text .. " bilhões"
            elseif i == 5 then text = val == 1 and "um trilhão" or text .. " trilhões"
            end
            table.insert(parts, text)
        end
    end

    return toUpperPTBR(table.concat(parts, " e "))
end

-- ── Envio de chat ──

local function sendChatMessage(message)
    local text = tostring(message)

    if TextChat.ChatVersion == Enum.ChatVersion.TextChatService then
        local channels = TextChat:FindFirstChild("TextChannels")
        local channel  = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildOfClass("TextChannel"))
        if channel then pcall(channel.SendAsync, channel, text) end
        return
    end

    local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local remote = events and events:FindFirstChild("SayMessageRequest")
    if remote then pcall(remote.FireServer, remote, text, "All") end
end

-- ── Ações de personagem ──

local function getCharacterIfAlive()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum  = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return (hum and root) and char or nil
end

local function doJump()
    local char = getCharacterIfAlive()
    if not char then return end
    local hum   = char.Humanoid
    local state = hum:GetState()
    if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function doSpin()
    local char = getCharacterIfAlive()
    if not char then return end

    local hum  = char.Humanoid
    local root = char.HumanoidRootPart
    hum.AutoRotate = false

    local tracker   = Instance.new("NumberValue")
    local direction = math.random(1, 2) == 1 and 1 or -1
    local tween     = TweenService:Create(tracker, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { Value = 360 * direction })
    local baseRot   = root.CFrame.Rotation

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if root and root.Parent then
            root.CFrame = CFrame.new(root.Position) * baseRot * CFrame.Angles(0, math.rad(tracker.Value), 0)
        else
            conn:Disconnect()
        end
    end)

    tween.Completed:Connect(function()
        conn:Disconnect()
        tracker:Destroy()
        if hum then hum.AutoRotate = true end
    end)

    tween:Play()
end

local function pressKey(keyCode)
    pcall(function()
        VirtualInput:SendKeyEvent(true,  keyCode, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, keyCode, false, game)
    end)
end

-- ── API pública JJs ──

JJs.Start = function()
    local cfg = JJs.Config
    if cfg.Running then return end
    cfg.Running = true

    task.spawn(function()
        local startVal = tonumber(cfg.StartValue) or 1
        local endVal   = tonumber(cfg.EndValue)   or 100
        local step     = (cfg.ReverseEnabled and startVal < endVal) and -1 or 1
        if cfg.ReverseEnabled then startVal, endVal = endVal, startVal end

        -- Detecta modo baseado no jogo
        local mode = cfg.Mode
        if mode == "Padrão" then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("Polichinelos") then
                mode = "JJ (Delta)"
            end
        end

        local total    = math.abs(endVal - startVal) + 1
        local count    = 0
        local timePerJJ = cfg.FinishInTime and ((tonumber(cfg.FinishTotalTime) or 60) / math.max(1, total)) or nil

        JJs.State.Running = true
        JJs.State.Total   = total
        JJs.State.Current = 0

        -- Animação Delta
        local deltaAnim = nil
        if mode == "JJ (Delta)" then
            local char = getCharacterIfAlive()
            if char then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://105471471504794"
                deltaAnim = char.Humanoid:LoadAnimation(anim)
                deltaAnim.Priority = Enum.AnimationPriority.Action
            end

            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local remote  = remotes and remotes:FindFirstChild("Polichinelos")
            if remote then
                pcall(remote.FireServer, remote, "Prepare")
                pcall(remote.FireServer, remote, "Start")
            end
        end

        for i = startVal, endVal, step do
            if not cfg.Running then break end
            count = count + 1
            JJs.State.Current = i

            local delay = timePerJJ
                or (cfg.RandomDelay
                    and (math.random(cfg.RandomMin * 10, cfg.RandomMax * 10) / 10)
                    or  (tonumber(cfg.DelayValue) or 3))

            JJs.State.FinishTimestamp = tick() + ((total - count) * delay)

            local suffix  = (cfg.CustomSuffix ~= "") and cfg.CustomSuffix or cfg.Suffix
            local text    = numberToWords(i)
            local message = cfg.SpacingEnabled and (text .. " " .. suffix) or (text .. suffix)

            if mode == "JJ (Delta)" then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local remote  = remotes and remotes:FindFirstChild("Polichinelos")
                if remote then pcall(remote.FireServer, remote, "Add", 1) end
                if deltaAnim then deltaAnim:Play() end

            elseif mode == "Canguru" then
                sendChatMessage(message)
                task.wait(0.2)
                pressKey(Enum.KeyCode.C)
                task.wait(0.2)
                pressKey(Enum.KeyCode.C)
                task.wait(0.1)
                doJump()
                task.wait(0.2)
                doSpin()

            else
                sendChatMessage(message)
                if cfg.JumpEnabled then doJump() end
            end

            if i ~= endVal then task.wait(delay) end
        end

        cfg.Running       = false
        JJs.State.Running = false
        if deltaAnim then deltaAnim:Stop() end
    end)
end

JJs.Stop = function()
    JJs.Config.Running = false
    JJs.State.Running  = false
end

-- ═══════════════════════════════════════════════════════
-- F3X
-- ═══════════════════════════════════════════════════════
local F3X_FOLDER = "michigun.xyz/f3x"
if writefile and not isfolder(F3X_FOLDER) then makefolder(F3X_FOLDER) end

env.F3X = env.F3X or {}
local F3X = env.F3X

F3X.Enabled       = false
F3X.SelectedParts = {}
F3X.Highlights    = {}
F3X.UndoStack     = {}
F3X.RedoStack     = {}
F3X.ModifiedParts = {}
F3X.UpdateUI      = nil
F3X.NotifyFunc    = nil
F3X.IsReady       = true

-- ── Highlights de seleção ──

local highlightContainer = nil

local function getHighlightContainer()
    if highlightContainer and highlightContainer.Parent then return highlightContainer end
    highlightContainer = Instance.new("Folder")
    highlightContainer.Name   = "F3XHighlights"
    highlightContainer.Parent = safeGui()
    return highlightContainer
end

local function clearHighlights()
    for _, hl in ipairs(F3X.Highlights) do if hl then hl:Destroy() end end
    table.clear(F3X.Highlights)
end

local function addHighlight(part)
    task.defer(function()
        if not part or not part.Parent then return end
        local hl                 = Instance.new("Highlight")
        hl.Name                  = HttpService:GenerateGUID(false)
        hl.FillTransparency      = 1
        hl.OutlineTransparency   = 0
        hl.OutlineColor          = Color3.fromRGB(0, 255, 255)
        hl.Adornee               = part
        hl.Parent                = getHighlightContainer()
        table.insert(F3X.Highlights, hl)
    end)
end

-- ── Undo/Redo ──

local function pushUndo()
    local snapshot = {}
    for _, part in ipairs(F3X.SelectedParts) do
        snapshot[part] = part.Size
    end
    table.insert(F3X.UndoStack, snapshot)
    table.clear(F3X.RedoStack)
end

-- ── Resolução de path ──

local function resolveObjectPath(path)
    local segments = {}
    for segment in path:gmatch("[^%.]+") do table.insert(segments, segment) end

    local current = game
    for _, segment in ipairs(segments) do
        if segment ~= "Game" then
            current = current:FindFirstChild(segment)
            if not current then return nil end
        end
    end
    return current
end

-- ── API pública F3X ──

F3X.ClearSelection = function()
    table.clear(F3X.SelectedParts)
    clearHighlights()
    if F3X.UpdateUI then task.defer(F3X.UpdateUI) end
end

F3X.ApplySize = function(size)
    if #F3X.SelectedParts == 0 then return end
    pushUndo()
    for _, part in ipairs(F3X.SelectedParts) do
        part.Size            = size
        F3X.ModifiedParts[part] = size
    end
    if F3X.UpdateUI then task.defer(F3X.UpdateUI) end
end

F3X.Undo = function()
    local snapshot = table.remove(F3X.UndoStack)
    if not snapshot then return end

    local redoSnapshot = {}
    for part, size in pairs(snapshot) do
        redoSnapshot[part]      = part.Size
        part.Size               = size
        F3X.ModifiedParts[part] = size
    end
    table.insert(F3X.RedoStack, redoSnapshot)
    if F3X.UpdateUI then task.defer(F3X.UpdateUI) end
end

F3X.Redo = function()
    local snapshot = table.remove(F3X.RedoStack)
    if not snapshot then return end

    local undoSnapshot = {}
    for part, size in pairs(snapshot) do
        undoSnapshot[part]      = part.Size
        part.Size               = size
        F3X.ModifiedParts[part] = size
    end
    table.insert(F3X.UndoStack, undoSnapshot)
    if F3X.UpdateUI then task.defer(F3X.UpdateUI) end
end

F3X.ListConfigs = function()
    local result = {}
    if listfiles then
        for _, path in ipairs(listfiles(F3X_FOLDER)) do
            if path:sub(-5) == ".json" then
                table.insert(result, path:match("([^/]+)%.json$"))
            end
        end
    end
    return result
end

F3X.SaveConfig = function(name)
    if not name or name == "" then
        if F3X.NotifyFunc then F3X.NotifyFunc("F3X: Nome inválido", 3, "lucide:alert-circle") end
        return nil
    end

    local data = { PlaceId = game.PlaceId, Parts = {} }
    for part, size in pairs(F3X.ModifiedParts) do
        if part and part.Parent then
            table.insert(data.Parts, {
                Path   = part:GetFullName(),
                CFrame = { part.CFrame:GetComponents() },
                Size   = { size.X, size.Y, size.Z },
            })
        end
    end

    writefile(F3X_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    return F3X.ListConfigs()
end

F3X.ApplyConfig = function(name)
    if not name then return end

    local path = F3X_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then return end

    local data
    pcall(function() data = HttpService:JSONDecode(readfile(path)) end)
    if not data then return end

    if data.PlaceId ~= game.PlaceId then
        if F3X.NotifyFunc then F3X.NotifyFunc("F3X: Config de outro mapa", 3, "lucide:alert-circle") end
        return
    end

    for _, entry in ipairs(data.Parts or {}) do
        local targetCFrame = CFrame.new(table.unpack(entry.CFrame))
        local found        = nil

        -- Tenta pelo path direto primeiro
        local direct = resolveObjectPath(entry.Path)
        if direct and direct:IsA("BasePart")
        and (direct.Position - targetCFrame.Position).Magnitude < 2 then
            found = direct
        end

        -- Fallback: busca por nome + posição
        if not found then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj:GetFullName() == entry.Path
                and (obj.Position - targetCFrame.Position).Magnitude < 2 then
                    found = obj
                    break
                end
            end
        end

        if found then
            found.Size               = Vector3.new(table.unpack(entry.Size))
            F3X.ModifiedParts[found] = found.Size
        end
    end
end

F3X.DeleteConfig = function(name)
    if not name then
        if F3X.NotifyFunc then F3X.NotifyFunc("F3X: Nenhuma seleção", 3, "lucide:alert-circle") end
        return nil
    end
    delfile(F3X_FOLDER .. "/" .. name .. ".json")
    return F3X.ListConfigs()
end

F3X.Toggle = function(enabled)
    F3X.Enabled = enabled
    if not enabled then F3X.ClearSelection() end
end

-- Mouse click para seleção
if LocalPlayer then
    local mouse = LocalPlayer:GetMouse()
    mouse.Button1Down:Connect(function()
        if not F3X.Enabled then return end

        local target = mouse.Target
        if not target or not target:IsA("BasePart") then return end

        -- Toggle se já está selecionado
        for i, part in ipairs(F3X.SelectedParts) do
            if part == target then
                table.remove(F3X.SelectedParts, i)
                clearHighlights()
                for _, selected in ipairs(F3X.SelectedParts) do addHighlight(selected) end
                if F3X.UpdateUI then task.defer(F3X.UpdateUI) end
                return
            end
        end

        -- Verifica compatibilidade de tamanho com a seleção existente
        if #F3X.SelectedParts > 0 then
            local ref  = F3X.SelectedParts[1].Size
            local tSz  = target.Size
            if math.abs(ref.X - tSz.X) > 1
            or math.abs(ref.Y - tSz.Y) > 1
            or math.abs(ref.Z - tSz.Z) > 1 then
                return
            end
        end

        table.insert(F3X.SelectedParts, target)
        addHighlight(target)
        if F3X.UpdateUI then task.defer(F3X.UpdateUI) end
    end)
end

-- ═══════════════════════════════════════════════════════
-- ChatGPT / IA
-- ═══════════════════════════════════════════════════════
local HttpRequest = request or (http and http.request) or http_request or (syn and syn.request)

local IA_PROMPT_PATH = "michigun.xyz/IA.txt"
if not isfile(IA_PROMPT_PATH) then
    writefile(IA_PROMPT_PATH, "Você é uma IA útil dentro do Roblox.")
end

_G.ChatGPT = _G.ChatGPT or {}
local ChatGPT = _G.ChatGPT

ChatGPT.LastMessage = ""
ChatGPT.History     = {{ role = "system", content = readfile(IA_PROMPT_PATH) }}

-- ── Utilitários internos ──

local function extractCodeBlock(text)
    local code = text:match("```lua\n?(.-)```") or text:match("```\n?(.-)```")
    if code then
        local cleanText = text:gsub("```lua\n?.-```", ""):gsub("```\n?.-```", "")
        return code, cleanText
    end
    return nil, text
end

-- ── API pública ChatGPT ──

ChatGPT.Ask = function(prompt)
    table.insert(ChatGPT.History, { role = "user", content = prompt })

    local ok, response = pcall(function()
        return HttpRequest({
            Url     = "https://text.pollinations.ai/openai",
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode({
                messages = ChatGPT.History,
                model    = "openai",
            }),
        })
    end)

    if not ok or not response then
        return "Erro de conexão com a API.", nil
    end

    local aiText      = ""
    local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, response.Body)

    if decodeOk and decoded and decoded.choices and decoded.choices[1] then
        aiText = decoded.choices[1].message.content
    else
        aiText = response.Body
    end

    local code, cleanMessage = extractCodeBlock(aiText)
    ChatGPT.LastMessage = cleanMessage

    table.insert(ChatGPT.History, { role = "assistant", content = aiText })

    return cleanMessage, code
end

ChatGPT.SendToChat = function(message)
    if not message or message == "" then return end
    sendChatMessage(tostring(message))
end