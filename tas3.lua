local function Finalizar(Mensagem)
    print(Mensagem)
    task.wait(0.5)
    local function Crash() return Crash() end
    Crash()
end

local RanTimes = 0
local Connection = game:GetService("RunService").Heartbeat:Connect(function()
    RanTimes = RanTimes + 1
end)

repeat
    task.wait()
until RanTimes >= 2

Connection:Disconnect()

if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or ({debug.info(print,'a')})[1]~=0 or ({debug.info(tostring,'a')})[1]~=0 or ({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" or not select(1, pcall(debug.info, coroutine.wrap(function() end)(), 's')) == false then
    Finalizar("skid de EB :(")
end

if not game.ServiceAdded then
    Finalizar("skid de EB :(")
end

if getfenv()[Instance.new("Part")] then
    Finalizar("skid de EB :(")
end

if getmetatable(__call) then
    Finalizar("skid de EB :(")
end

local Success = pcall(function()
    Instance.new("Part"):BananaPeelSlipper("a")
end)

if Success then
    Finalizar("skid de EB :(")
end

local Success, Result = pcall(function()
    return game:GetService("HttpService"):JSONDecode([=[
        [
            42,
            "deworming tablets",
            false,
            987,
            true,
            [555, "shimmer", null],
            null,
            ["x", 77, true],
            {"key": "value", "num": 101},
            [null, ["nested", 999, false]]
        ]
    ]=])
end)

if not Success then
    Finalizar("skid de EB :(")
end

if Result[6][3] ~= nil then
    Finalizar("skid de EB :(")
end

local _, Message = pcall(function()
    game()
end)

if not Message:find("attempt to call a Instance value") then
    Finalizar("skid de EB :(")
end

if #game:GetChildren() <= 4 then
    Finalizar("skid de EB :(")
end

local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextChatService = cloneref(game:GetService("TextChatService"))

local LocalPlayer = cloneref(Players.LocalPlayer)
local CurrentCamera = cloneref(Workspace.CurrentCamera)

local unpack = table.unpack or unpack

local BASE_COLOR_POS = Color3.fromRGB(0, 255, 255)
local BASE_COLOR_LOOK = Color3.fromRGB(255, 50, 100)
local PATH_COLOR = Color3.fromRGB(0, 200, 255)
local TRANSPARENCY_INDICATOR = 0.1
local VIEWPORT_SIZE = UDim2.new(0, 150, 0, 150)
local PATH_THICKNESS = 0.1
local TARGET_FPS = 60
local FRAME_TIME = 1 / TARGET_FPS

local STATE_TO_ENUM = {}
for _, enumItem in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
    STATE_TO_ENUM[enumItem.Value] = enumItem
end

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
_G.TAS.LastJumpInput = false 

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
    local hum = getHumanoid()
    if hum then 
        hum.AutoRotate = true 
        hum:Move(Vector3.zero) 
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local tg = pg:FindFirstChild("TouchGui")
        if tg then
            tg.Enabled = false
            task.spawn(function()
                for i = 1, 10 do 
                    if tg then tg.Enabled = true end
                    task.wait(0.1)
                end
            end)
        end
    end
end

local function isGrounded(hrp)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ray = Workspace:Raycast(hrp.Position, Vector3.new(0, -3.5, 0), params)
    return ray ~= nil
end

local function captureFrame()
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    return {
        cf  = { hrp.CFrame:GetComponents() },
        cam = { CurrentCamera.CFrame:GetComponents() },
        vel = { hrp.AssemblyLinearVelocity.X, hrp.AssemblyLinearVelocity.Y, hrp.AssemblyLinearVelocity.Z },
        jump = hum.Jump, 
        state = hum:GetState().Value 
    }
end

local function applyFrame(f)
    if not f then return end
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end

    if f.cf then hrp.CFrame = CFrame.new(unpack(f.cf)) end
    
    if f.vel then 
        local v = Vector3.new(f.vel[1], f.vel[2], f.vel[3])
        hrp.AssemblyLinearVelocity = v
        
        if v.Magnitude > 0.5 then
            hum:Move(hrp.CFrame.LookVector, false)
        else
            hum:Move(Vector3.zero)
        end
    end

    if f.jump ~= _G.TAS.LastJumpInput then
        if f.jump then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        _G.TAS.LastJumpInput = f.jump
    end

    local recordedState = STATE_TO_ENUM[f.state]
    local onGround = isGrounded(hrp)
    local vY = hrp.AssemblyLinearVelocity.Y

    if onGround and math.abs(vY) < 5 then
        if recordedState == Enum.HumanoidStateType.Freefall then
             recordedState = Enum.HumanoidStateType.Running
        end
    end

    if f.state == Enum.HumanoidStateType.Climbing.Value then
        recordedState = Enum.HumanoidStateType.Climbing
    end

    if recordedState then
        local currentState = hum:GetState()
        if recordedState ~= Enum.HumanoidStateType.Jumping then
             if currentState ~= recordedState then
                hum:ChangeState(recordedState)
             end
        end
        hum.AutoRotate = false 
    end
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
        if not partToTrack then return end
        
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

local function buildPathLine(frames, parentFolder)
    local parts = {}
    if not frames or #frames < 2 then return parts end

    for i = 1, #frames - 1 do
        if frames[i].cf and frames[i+1].cf then
            local startPos = Vector3.new(unpack(frames[i].cf))
            local endPos   = Vector3.new(unpack(frames[i+1].cf))
            local dist = (endPos - startPos).Magnitude

            if dist > 0.05 then
                local part = Instance.new("CylinderHandleAdornment")
                part.Radius = PATH_THICKNESS / 2
                part.Height = dist
                part.CFrame = CFrame.new(startPos:Lerp(endPos, 0.5), endPos)
                part.Color3 = PATH_COLOR
                part.Transparency = 0.1
                part.Adornee = Workspace.Terrain
                part.ZIndex = 0
                part.Parent = parentFolder
                table.insert(parts, part)
            end
        end
    end
    
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

    local container = Instance.new("Folder")
    container.Name = "_" .. name
    container.Parent = gethui_func()
    data.VisualFolder = container

    local function marker(n, size, cframe, color, transp, isCylinder)
        local p
        if isCylinder then
            p = Instance.new("CylinderHandleAdornment")
            p.Radius = size.X
            p.Height = size.Y
        else
            p = Instance.new("BoxHandleAdornment")
            p.Size = size
        end
        p.Name = n
        p.CFrame = cframe
        p.Color3 = color
        p.Transparency = transp or TRANSPARENCY_INDICATOR
        p.Adornee = Workspace.Terrain
        p.ZIndex = 1
        p.Parent = container
        return p
    end

    local basePad = marker("BasePad", Vector2.new(3, 0.2), cf * CFrame.new(0, -2.8, 0) * CFrame.Angles(0,0,math.rad(90)), BASE_COLOR_POS, 0.3, true)
    local torso = marker("Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, 0, 0), BASE_COLOR_POS, 0.02, false)
    local lLeg = marker("LLeg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), BASE_COLOR_POS, 0.02, false)
    local rLeg = marker("RLeg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), BASE_COLOR_POS, 0.02, false)
    local lArm = marker("LArm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), BASE_COLOR_POS, 0.02, false)
    local rArm = marker("RArm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0.5, -1) * CFrame.Angles(math.rad(90), 0, 0), BASE_COLOR_POS, 0.02, false)
    
    local dummyPart = Instance.new("Part")
    dummyPart.Size = Vector3.new(2, 2, 1)
    dummyPart.CFrame = cf
    dummyPart.Transparency = 1
    dummyPart.Anchored = true
    dummyPart.CanCollide = false
    
    table.insert(data.Viewports, createViewportMarker(dummyPart))

    data.PathParts = buildPathLine(data.Frames, container)

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
            
            data.PlayConn = RunService.Heartbeat:Connect(function()
                local TimeElapsed = tick() - StartTime
                local currentFrameIndex = math.floor(TimeElapsed * TARGET_FPS) + 1
                
                if currentFrameIndex > #data.Frames then
                    stopMovementInput()
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
        stopMovementInput()
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
            stopMovementInput()
            data.PlayConn:Disconnect()
            data.Playing = false
        end
    end
    checkPlaybackState()
end
