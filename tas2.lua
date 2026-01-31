Local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))

local LocalPlayer = cloneref(Players.LocalPlayer)
local CurrentCamera = cloneref(Workspace.CurrentCamera)

local unpack = table.unpack or unpack

local BASE_COLOR_POS = Color3.fromRGB(0, 255, 255)
local BASE_COLOR_LOOK = Color3.fromRGB(255, 50, 100)
local PATH_COLOR = Color3.fromRGB(0, 200, 255)
local MATERIAL_INDICATOR = Enum.Material.ForceField
local TRANSPARENCY_INDICATOR = 0.1
local VIEWPORT_SIZE = UDim2.new(0, 150, 0, 150)
local PATH_THICKNESS = 0.1
local TARGET_FPS = 60
local FRAME_TIME = 1 / TARGET_FPS

local TAS_GUI_NAME = "."
local gethui_func = gethui or function() return game:GetService("CoreGui") end
local existingGui = gethui_func():FindFirstChild(TAS_GUI_NAME)
if existingGui then existingGui:Destroy() end

local TAS_GUI = Instance.new("ScreenGui")
TAS_GUI.Name = TAS_GUI_NAME
TAS_GUI.ResetOnSpawn = false
TAS_GUI.Parent = gethui_func()

if not isfolder("michigun.xyz") then
    makefolder("michigun.xyz")
end

local TAS_FOLDER = "michigun.xyz/fp3_Parkours"
if writefile and not isfolder(TAS_FOLDER) then
    makefolder(TAS_FOLDER)
end

_G.TAS = _G.TAS or {}
_G.TAS.Loaded = {}
_G.TAS.Selection = {}
_G.TAS.Recording = false
_G.TAS.RequestedPlay = false
_G.TAS.RecFrames = {}
_G.TAS.CurrentName = ""
_G.TAS.RecordConn = nil
_G.TAS.IsReady = true
_G.TAS.NotifyFunc = nil 
_G.TAS.UpdateButtonState = nil 

_G.TAS.ActivationRadius = 1
_G.TAS.ActivationHeight = 1.5
_G.TAS.ActivationAngle = 10

local function safeNotify(title, msg)
    if _G.TAS.NotifyFunc then
        _G.TAS.NotifyFunc(title .. ": " .. msg, 3, "lucide:info")
    end
end

local function checkPlaybackState()
    local isPlaying = false
    for _, data in pairs(_G.TAS.Loaded) do
        if data.Playing then
            isPlaying = true
            break
        end
    end
    
    if _G.TAS.UpdateButtonState then
        _G.TAS.UpdateButtonState(isPlaying)
    end
end

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function stopMovementInput()
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
    local hum = getHumanoid()
    if hum then
        hum:Move(Vector3.zero, false)
    end
end

-- Limpeza das constraints físicas (AlignPosition/Orientation)
local function cleanupPhysicsConstraints()
    local hrp = getHRP()
    local hum = getHumanoid()
    if hrp then
        if hrp:FindFirstChild("TAS_AlignPosition") then hrp.TAS_AlignPosition:Destroy() end
        if hrp:FindFirstChild("TAS_AlignOrientation") then hrp.TAS_AlignOrientation:Destroy() end
        if hrp:FindFirstChild("TAS_Attachment") then hrp.TAS_Attachment:Destroy() end
    end
    if hum then
        hum.PlatformStand = false -- Garante que ele volte ao normal
        hum.AutoRotate = true
    end
end

local function captureFrame()
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    return {
        cf  = { hrp.CFrame:GetComponents() },
        cam = { CurrentCamera.CFrame:GetComponents() },
        vel = { hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z },
        rotVel = { hrp.AssemblyAngularVelocity.X, hrp.AssemblyAngularVelocity.Y, hrp.AssemblyAngularVelocity.Z }, -- Adicionado RotVelocity igual TASability
        jump = hum.Jump,
        state = hum:GetState().Value -- Salva o estado para reproduzir fielmente
    }
end

local function applyFrame(f)
    if not f then return end
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    -- === TÉCNICA TASABILITY: USAR CONSTRAINTS ===
    -- Em vez de teleportar (CFrame = x), usamos física para empurrar o boneco.
    -- Isso faz a animação funcionar nativamente. [Source: 98-99 do TASability.txt]

    local alignPos = hrp:FindFirstChild("TAS_AlignPosition")
    local alignOrient = hrp:FindFirstChild("TAS_AlignOrientation")
    local attachment = hrp:FindFirstChild("TAS_Attachment")

    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "TAS_Attachment"
        attachment.Parent = hrp
    end

    if not alignPos then
        alignPos = Instance.new("AlignPosition")
        alignPos.Name = "TAS_AlignPosition"
        alignPos.Attachment0 = attachment
        alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPos.MaxForce = 9e9 -- Força infinita para garantir precisão
        alignPos.MaxVelocity = 9e9
        alignPos.Responsiveness = 200 -- Muito rápido, mas ainda física
        alignPos.RigidityEnabled = true -- Garante que ele vá exatamente para o ponto
        alignPos.Parent = hrp
    end

    if not alignOrient then
        alignOrient = Instance.new("AlignOrientation")
        alignOrient.Name = "TAS_AlignOrientation"
        alignOrient.Attachment0 = attachment
        alignOrient.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignOrient.MaxTorque = 9e9
        alignOrient.MaxAngularVelocity = 9e9
        alignOrient.Responsiveness = 200
        alignOrient.RigidityEnabled = true
        alignOrient.Parent = hrp
    end

    -- 1. Aplicar a posição alvo nas constraints
    if f.cf then
        local targetCF = CFrame.new(unpack(f.cf))
        alignPos.Position = targetCF.Position
        alignOrient.CFrame = targetCF
    end

    -- 2. Restaurar velocidades para inércia correta (crucial para animação de pulo/queda)
    if f.vel then
        hrp.AssemblyLinearVelocity = Vector3.new(f.vel[1], f.vel[2], f.vel[3])
    end
    if f.rotVel then
        hrp.AssemblyAngularVelocity = Vector3.new(f.rotVel[1], f.rotVel[2], f.rotVel[3])
    end

    -- 3. Gerenciamento de Estado do Humanoide
    -- O TASability desativa a colisão e usa PlatformStand para evitar conflitos físicos [Source: 97]
    hum.PlatformStand = true 
    hum.AutoRotate = false

    -- Forçar o estado gravado (Jump, Freefall, Running) ajuda a animação correta a tocar
    if f.state then
        hum:ChangeState(f.state)
    elseif f.jump then
         hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    if f.cam then CurrentCamera.CFrame = CFrame.new(unpack(f.cam)) end
end

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
    clone.Transparency = 0
    clone.Material = Enum.Material.Neon
    clone.CFrame = CFrame.new()

    local maxDimension = math.max(clone.Size.X, clone.Size.Y, clone.Size.Z)
    viewportCamera.CFrame =
        CFrame.new(0, maxDimension, maxDimension * 2.5) *
        CFrame.Angles(math.rad(-20), math.rad(180), 0)

    local conn = RunService.Stepped:Connect(function()
        if not partToTrack or not partToTrack.Parent then return end
        
        local pos, visible = CurrentCamera:WorldToScreenPoint(partToTrack.Position)
        viewportFrame.Position = UDim2.fromOffset(
            pos.X - viewportFrame.Size.X.Offset / 2,
            pos.Y - viewportFrame.Size.Y.Offset / 2
        )
        viewportFrame.Visible = visible
        
        clone.CFrame = CFrame.Angles(0, tick() % (math.pi * 2), 0)
    end)

    return {
        Frame = viewportFrame,
        Connection = conn,
        Part = partToTrack
    }
end

local function clearSingleTAS(name)
    local data = _G.TAS.Loaded[name]
    if not data then return end

    if data.MarkerConn then data.MarkerConn:Disconnect() end
    if data.PlayConn then data.PlayConn:Disconnect() end
    
    cleanupPhysicsConstraints() -- Limpa constraints ao parar
    stopMovementInput()

    if data.VisualFolder then data.VisualFolder:Destroy() end

    if data.Viewports then
        for _, vp in ipairs(data.Viewports) do
            if vp.Connection then vp.Connection:Disconnect() end
            if vp.Frame then vp.Frame:Destroy() end
        end
    end
    
    if data.PathParts then
        for _, p in ipairs(data.PathParts) do
            if p then p:Destroy() end
        end
    end

    data.VisualFolder = nil
    data.Viewports = {}
    data.PathParts = {}
    data.Waiting = false
    data.Playing = false
    checkPlaybackState()
end

local function buildPathLine(frames)
    local parts = {}
    if not frames or #frames < 2 then return parts end

    local parentFolder = Instance.new("Folder", Workspace)
    parentFolder.Name = "2"

    for i = 1, #frames - 1 do
        if frames[i].cf and frames[i+1].cf then
            local startPos = Vector3.new(unpack(frames[i].cf))
            local endPos   = Vector3.new(unpack(frames[i+1].cf))
            local dist = (endPos - startPos).Magnitude

            if dist > 0.05 then
                local part = Instance.new("Part")
                part.Anchored = true
                part.CanCollide = false
                part.Material = Enum.Material.Neon
                part.Color = PATH_COLOR
                part.Transparency = 0.1
                part.Size = Vector3.new(PATH_THICKNESS, PATH_THICKNESS, dist)
                part.CFrame = CFrame.new(startPos:Lerp(endPos, 0.5), endPos)
                part.Parent = parentFolder
                table.insert(parts, part)
            end
        end
    end
    
    table.insert(parts, parentFolder) 
    return parts
end

local function activateTAS(name)
    local data = _G.TAS.Loaded[name]
    if not data or not data.Frames or #data.Frames == 0 then return end
    if data.Waiting or data.Playing then return end

    clearSingleTAS(name) 
    data.Waiting = true

    local startFrame = data.Frames[1]
    local cf = CFrame.new(unpack(startFrame.cf))

    local container = Instance.new("Folder", Workspace)
    container.Name = "_" .. name
    data.VisualFolder = container

    local function marker(n, shape, size, cframe, color, mat, transp)
        local p = Instance.new("Part")
        p.Name = n
        p.Shape = shape
        p.Size = size
        p.CFrame = cframe
        p.Anchored = true
        p.CanCollide = false
        p.Material = mat or MATERIAL_INDICATOR
        p.Color = color
        p.Transparency = transp or TRANSPARENCY_INDICATOR
        p.CastShadow = false
        p.Parent = container
        return p
    end

    local basePad = marker("BasePad", Enum.PartType.Cylinder, Vector3.new(0.2, 6, 6), cf * CFrame.new(0, -2.8, 0) * CFrame.Angles(0,0,math.rad(90)), BASE_COLOR_POS, Enum.Material.Neon, 0.3)
    local torso = marker("Torso", Enum.PartType.Block, Vector3.new(2, 2, 1), cf * CFrame.new(0, 0, 0), BASE_COLOR_POS, Enum.Material.ForceField, 0.02)
    local lLeg = marker("LLeg", Enum.PartType.Block, Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), BASE_COLOR_POS, Enum.Material.ForceField, 0.02)
    local rLeg = marker("RLeg", Enum.PartType.Block, Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), BASE_COLOR_POS, Enum.Material.ForceField, 0.02)
    local lArm = marker("LArm", Enum.PartType.Block, Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), BASE_COLOR_POS, Enum.Material.ForceField, 0.02)
    local rArm = marker("RArm", Enum.PartType.Block, Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0.5, -1) * CFrame.Angles(math.rad(90), 0, 0), BASE_COLOR_POS, Enum.Material.ForceField, 0.02)
    
    table.insert(data.Viewports, createViewportMarker(torso))

    data.PathParts = buildPathLine(data.Frames)

    data.MarkerConn = RunService.Heartbeat:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        
        local t = tick()
        basePad.Transparency = 0.5 + math.sin(t * 3) * 0.2

        local delta = hrp.Position - cf.Position
        local flatDist = Vector3.new(delta.X,0,delta.Z).Magnitude
        local dot = hrp.CFrame.LookVector:Dot(cf.LookVector)

        local actRadius = _G.TAS.ActivationRadius or 0.5
        local actHeight = _G.TAS.ActivationHeight or 1.5
        local actAngle = _G.TAS.ActivationAngle or 5

        if flatDist <= actRadius and math.abs(delta.Y) <= actHeight and dot >= math.cos(math.rad(actAngle)) then
            if data.MarkerConn then data.MarkerConn:Disconnect() end
            
            if data.VisualFolder then data.VisualFolder:Destroy() end
            for _, vp in ipairs(data.Viewports) do
                if vp.Connection then vp.Connection:Disconnect() end
                if vp.Frame then vp.Frame:Destroy() end
            end
            for _, p in ipairs(data.PathParts) do
                if p then p:Destroy() end
            end

            data.Waiting = false
            data.Playing = true
            checkPlaybackState()
            
            local StartTime = tick()
            
            -- Prepare HRP for physics playback
            local hrp = getHRP()
            if hrp then 
                 for _, v in pairs(LocalPlayer.Character:GetChildren()) do
                    if v:IsA("BasePart") then v.CanCollide = false end -- TASability logic: desativar colisão [Source: 97]
                 end
            end

            data.PlayConn = RunService.Heartbeat:Connect(function()
                local TimeElapsed = tick() - StartTime
                local currentFrameIndex = math.floor(TimeElapsed * TARGET_FPS) + 1
                
                if currentFrameIndex > #data.Frames then
                    cleanupPhysicsConstraints()
                    if data.PlayConn then data.PlayConn:Disconnect() end
                    data.Playing = false
                    checkPlaybackState()
                    return
                end

                applyFrame(data.Frames[currentFrameIndex])
            end)
        end
    end)
end

_G.TAS.ToggleAll = function(enable)
    _G.TAS.RequestedPlay = enable
    if enable then
        for name, _ in pairs(_G.TAS.Loaded) do
            activateTAS(name)
        end
    else
        for name, _ in pairs(_G.TAS.Loaded) do
            clearSingleTAS(name)
        end
        cleanupPhysicsConstraints()
        checkPlaybackState()
    end
end

_G.TAS.StopRecording = function()
    if not _G.TAS.Recording then return end
    _G.TAS.Recording = false
    if _G.TAS.RecordConn then
        _G.TAS.RecordConn:Disconnect()
        _G.TAS.RecordConn = nil
    end
    
    local duration = #_G.TAS.RecFrames * FRAME_TIME
    safeNotify("TAS", string.format("Gravação parada (%.2f segundos)", duration))
    if main then main:Open() end
end

_G.TAS.StartRecording = function()
    if _G.TAS.Recording then return end
    if main then main:Close() end
    _G.TAS.RecFrames = {}
    _G.TAS.Recording = true
    
    local accumulator = 0
    local idleTime = 0
    
    _G.TAS.RecordConn = RunService.Heartbeat:Connect(function(dt)
        local hrp = getHRP()
        if hrp then
            if hrp.AssemblyLinearVelocity.Magnitude < 0.2 then
                idleTime = idleTime + dt
            else
                idleTime = 0
            end
        end
        
        if idleTime >= 1 then
            _G.TAS.StopRecording()
            return
        end
        
        accumulator = accumulator + dt
        while accumulator >= FRAME_TIME do
            accumulator = accumulator - FRAME_TIME
            local frame = captureFrame()
            if frame then
                table.insert(_G.TAS.RecFrames, frame)
            end
        end
    end)
    safeNotify("TAS", "Gravação iniciada")
end

local function onChatCommand(msg)
    msg = msg:lower()
    if msg == "/e gravar" then
        _G.TAS.StartRecording()
    elseif msg == "/e parar" then
        _G.TAS.StopRecording()
    end
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.OnIncomingMessage = function(message)
        if message.TextSource and message.TextSource.UserId == LocalPlayer.UserId then
            onChatCommand(message.Text)
        end
    end
else
    LocalPlayer.Chatted:Connect(onChatCommand)
end

_G.TAS.GetSaved = function()
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

_G.TAS.SaveCurrent = function()
    if not _G.TAS.CurrentName or _G.TAS.CurrentName == "" or #_G.TAS.RecFrames == 0 then return end
    writefile(TAS_FOLDER .. "/" .. _G.TAS.CurrentName .. ".json", HttpService:JSONEncode({ Version = 1, Frames = _G.TAS.RecFrames }))
    return _G.TAS.GetSaved()
end

_G.TAS.UpdateSelection = function(selectedList)
    if type(selectedList) ~= "table" then
        selectedList = {selectedList}
    end
    _G.TAS.Selection = selectedList

    local newSet = {}
    for _, name in ipairs(selectedList) do
        newSet[name] = true
    end

    for name, _ in pairs(_G.TAS.Loaded) do
        if not newSet[name] then
            clearSingleTAS(name)
            _G.TAS.Loaded[name] = nil
        end
    end

    for _, name in ipairs(selectedList) do
        if not _G.TAS.Loaded[name] and name ~= "" then
            local path = TAS_FOLDER .. "/" .. name .. ".json"
            if isfile(path) and readfile then
                local content = readfile(path)
                local decoded = HttpService:JSONDecode(content)
                _G.TAS.Loaded[name] = {
                    Frames = decoded.Frames or {},
                    Viewports = {},
                    PathParts = {},
                    Waiting = false,
                    Playing = false
                }
            end
        end
    end

    if _G.TAS.RequestedPlay then
        for name, _ in pairs(_G.TAS.Loaded) do
            activateTAS(name)
        end
    end
end

_G.TAS.DeleteSelected = function()
    if #_G.TAS.Selection == 0 then
        safeNotify("TAS", "Nenhuma gravação selecionada.")
        return
    end

    for _, name in ipairs(_G.TAS.Selection) do
        local path = TAS_FOLDER .. "/" .. name .. ".json"
        if isfile(path) and delfile then delfile(path) end
        clearSingleTAS(name)
        _G.TAS.Loaded[name] = nil
    end

    _G.TAS.Selection = {}
    return _G.TAS.GetSaved()
end

_G.TAS.ManualStopPlayback = function()
    for _, data in pairs(_G.TAS.Loaded) do
        if data.Playing and data.PlayConn then
            cleanupPhysicsConstraints()
            stopMovementInput()
            data.PlayConn:Disconnect()
            data.Playing = false
        end
    end
    checkPlaybackState()
end
