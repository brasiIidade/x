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