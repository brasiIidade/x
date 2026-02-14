local REVEAL_HINT_STACK = false
local ANTI_ENV_LOG_MESSAGE =
[[
    skid fudido
]]
if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or ({debug.info(print,'a')})[1]~=0 or ({debug.info(tostring,'a')})[1]~=0 or ({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" then
  return REVEAL_HINT_STACK and tostring(ANTI_ENV_LOG_MESSAGE) or nil
end

local cloneref = cloneref or function(o) return o end

local Lighting = cloneref(game:GetService("Lighting"))
local PhysicsService = cloneref(game:GetService("PhysicsService"))
local GuiService = cloneref(game:GetService("GuiService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Stats = cloneref(game:GetService("Stats"))
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local StarterGui = cloneref(game:GetService("StarterGui"))

local Terrain = cloneref(Workspace:FindFirstChildOfClass("Terrain"))
local LocalPlayer = cloneref(Players.LocalPlayer)
local Camera = cloneref(Workspace.CurrentCamera)


_G.AntiLag = _G.AntiLag or {}
_G.AntiLag.Running = false

_G.AntiLag.Start = function()
    if _G.AntiLag.Running then return end
    _G.AntiLag.Running = true

    task.spawn(function()
        local Config = {
            OPTIZ = true,
            OPTIMIZATION_INTERVAL = 10,
            MIN_INTERVAL = 3,
            MAX_DISTANCE = 50,
            PERFORMANCE_MONITORING = true,
            FPS_MONITOR = false, 
            FPS_THRESHOLD = 30,
            GRAY_SKY_ENABLED = true,
            GRAY_SKY_ID = "rbxassetid://114666145996289",
            FULL_BRIGHT_ENABLED = true,
            SMOOTH_PLASTIC_ENABLED = true,
            COLLISION_GROUP_NAME = "OptimizedParts",
            OPTIMIZE_PHYSICS = true,
            DISABLE_CONSTRAINTS = true,
            THROTTLE_PARTICLES = true,
            THROTTLE_TEXTURES = true,
            REMOVE_ANIMATIONS = true,
            LOW_POLY_CONVERSION = true,
            SELECTIVE_TEXTURE_REMOVAL = true,
            PRESERVE_IMPORTANT_TEXTURES = true,
            IMPORTANT_TEXTURE_KEYWORDS = {"sign", "ui", "hud", "menu", "button", "fence"},
            QUALITY_LEVEL = 1,
            FPS_CAP = 1000,
            MEMORY_CLEANUP_THRESHOLD = 500,
            NETWORK_OPTIMIZATION = true,
            REDUCE_REPLICATION = true,
            THROTTLE_REMOTE_EVENTS = true,
            OPTIMIZE_CHAT = true,
            DISABLE_UNNECESSARY_GUI = true,
            STREAMING_ENABLED = true,
            REDUCE_PLAYER_REPLICATION_DISTANCE = 100,
            THROTTLE_SOUNDS = true,
            DESTROY_EMITTERS = true,
            REMOVE_GRASS = true,
            CORE = true,
        }

        local function safeCall(func, name, ...)
            local success, err = pcall(func, ...)
            if not success then warn(string.format("Error in %s: %s", name, err)) end
            return success
        end

        local function setSmoothPlastic()
            if not Config.SMOOTH_PLASTIC_ENABLED then return end
            local function handleInstance(instance)
                if LocalPlayer and LocalPlayer.Character and instance:IsDescendantOf(LocalPlayer.Character) then return end
                if instance:IsA("BasePart") then
                    instance.Material = Enum.Material.SmoothPlastic
                    instance.Reflectance = 0
                elseif instance:IsA("Texture") or instance:IsA("Decal") then
                    instance.Transparency = 1
                end
            end
            for _, instance in ipairs(Workspace:GetDescendants()) do handleInstance(instance) end
            Workspace.DescendantAdded:Connect(handleInstance)
        end

        local function RemoveMesh(target)
            local textureKeywords = { "chair", "seat", "stool", "bench", "coffee", "fruit", "paper", "document", "note", "cup", "mug", "photo", "monitor", "screen", "display", "pistol", "rifle", "plate", "computer", "laptop", "desktop", "bedframe", "table", "desk", "plank", "cloud", "furniture", "bottle", "cardboard", "chest", "book", "pillow", "magazine", "poster", "sign", "billboard", "keyboard", "picture", "frame", "painting", "pipe", "wires", "fridge", "glass", "leaf", "window", "pane", "shelf", "phone", "tree", "bush", "plant", "foliage", "boxes", "decor", "ornament", "detail", "knob", "handle", "wall", "tree", "prop", "object", "tool", "weapon", "food", "drink", "bloxy", "cola", "container", "box", "bag", "case", "stand", "rack", "holder", "support", "leg", "arm", "back", "top", "base", "cover", "lid", "door", "drawer", "handle", "knob", "button", "switch", "lever", "wheel", "chain", "door", "rope", "wire", "cable", "tube", "hose", "vent", "fan", "motor", "engine", "machine", "equipment", "device", "bottle", "closet", "potplant", "balloons" }
            local function hasTextureKeyword(name)
                local lowerName = string.lower(name)
                for _, keyword in ipairs(textureKeywords) do
                    if string.find(lowerName, keyword:lower()) then return true end
                end
                return false
            end
            local function isLocalPlayer(instance)
                if LocalPlayer and LocalPlayer.Character then
                    if instance:IsDescendantOf(LocalPlayer.Character) then return true end
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and instance:IsDescendantOf(p.Character) then return true end
                end
                return false
            end
            local function processInstance(instance)
                if isLocalPlayer(instance) then return end
                if instance:IsA("BasePart") then
                    if hasTextureKeyword(instance.Name) then
                        local decal = instance:FindFirstChildWhichIsA("Decal")
                        if decal then decal:Destroy() end
                        for _, child in ipairs(instance:GetChildren()) do
                            if child:IsA("Decal") then child:Destroy() end
                        end
                        instance.BrickColor = BrickColor.new("Medium stone grey")
                        instance.Material = Enum.Material.Plastic
                        if instance:IsA("Part") then
                            instance.TopSurface = Enum.SurfaceType.Smooth
                            instance.BottomSurface = Enum.SurfaceType.Smooth
                            instance.LeftSurface = Enum.SurfaceType.Smooth
                            instance.RightSurface = Enum.SurfaceType.Smooth
                            instance.FrontSurface = Enum.SurfaceType.Smooth
                            instance.BackSurface = Enum.SurfaceType.Smooth
                        end
                    end
                elseif instance:IsA("Model") then
                    for _, child in ipairs(instance:GetChildren()) do processInstance(child) end
                end
            end
            if target then
                if target:IsA("Model") or target:IsA("BasePart") then
                    if not isLocalPlayer(target) then processInstance(target) end
                end
            else
                for _, obj in ipairs(Workspace:GetChildren()) do
                    if (obj:IsA("Model") or obj:IsA("BasePart")) and not isLocalPlayer(obj) then processInstance(obj) end
                end
            end
        end

        local function RemoveEmitters()
            if not Config.DESTROY_EMITTERS then return end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj:Destroy() end
            end
        end

        local function gras()
            if not Config.REMOVE_GRASS then return end
            coroutine.wrap(pcall)(function()
                if Terrain then
                    if sethiddenproperty then
                        sethiddenproperty(Terrain, "Decoration", false)
                    else
                        Terrain.Decoration = false
                    end
                end
            end)
        end

        local function shouldSkip(instance)
            if LocalPlayer.Character and instance:IsDescendantOf(LocalPlayer.Character) then return true end
            local parent = instance.Parent
            while parent do
                if parent:IsA("Model") and Players:GetPlayerFromCharacter(parent) then return true end
                parent = parent.Parent
            end
            return false
        end

        local function optimizeUI()
            local function optimizeGuiElement(gui)
                if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then gui.ImageTransparency = 0.5 elseif gui:IsA("Frame") or gui:IsA("TextLabel") then gui.BackgroundTransparency = 0.5 end
            end
            for _, gui in ipairs(StarterGui:GetDescendants()) do safeCall(function() optimizeGuiElement(gui) end, "ui_optimization") end
        end

        pcall(function()
            PhysicsService:CreateCollisionGroup(Config.COLLISION_GROUP_NAME)
            PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, Config.COLLISION_GROUP_NAME, false)
        end)

        local function removePlayerAnimations()
            if not Config.REMOVE_ANIMATIONS then return end
            local localRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local localHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            local isFirstPerson = false
            if localHumanoid then
                isFirstPerson = localHumanoid.CameraOffset == Vector3.new(0, 0, 0) and Camera.CameraSubject == localHumanoid
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local character = p.Character
                    if character then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        local rootPart = character:FindFirstChild("HumanoidRootPart")
                        local shouldRemoveAnimations = false
                        local isBehind = false
                        if localRootPart and rootPart then
                            local distance = (localRootPart.Position - rootPart.Position).Magnitude
                            local isFar = distance > Config.MAX_DISTANCE
                            if isFirstPerson and localRootPart then
                                local cameraDirection = Camera.CFrame.LookVector
                                local toPlayerDirection = (rootPart.Position - localRootPart.Position).Unit
                                local dotProduct = cameraDirection:Dot(toPlayerDirection)
                                isBehind = dotProduct < 0
                                shouldRemoveAnimations = isBehind
                            else
                                shouldRemoveAnimations = isFar
                            end
                        end
                        if humanoid then
                            if shouldRemoveAnimations then
                                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
                                if not humanoid:FindFirstChild("OriginalAnimator") then
                                    local animator = humanoid:FindFirstChildOfClass("Animator")
                                    if animator then
                                        local originalMarker = Instance.new("ObjectValue")
                                        originalMarker.Name = "OriginalAnimator"
                                        originalMarker.Value = animator
                                        originalMarker.Parent = humanoid
                                        animator.Parent = nil
                                    end
                                end
                            else
                                local originalAnimatorMarker = humanoid:FindFirstChild("OriginalAnimator")
                                if originalAnimatorMarker and originalAnimatorMarker.Value then
                                    originalAnimatorMarker.Value.Parent = humanoid
                                    originalAnimatorMarker:Destroy()
                                end
                            end
                        end
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                if shouldRemoveAnimations or (localRootPart and rootPart and (localRootPart.Position - rootPart.Position).Magnitude > Config.MAX_DISTANCE) then
                                    part.Material = Enum.Material.SmoothPlastic
                                    part.Reflectance = 0
                                    part.CastShadow = false
                                    pcall(function() PhysicsService:SetPartCollisionGroup(part, Config.COLLISION_GROUP_NAME) end)
                                end
                            elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Smoke") or part:IsA("Fire") then
                                part.Enabled = not shouldRemoveAnimations and (localRootPart and rootPart and (localRootPart.Position - rootPart.Position).Magnitude <= Config.MAX_DISTANCE)
                            end
                        end
                    end
                end
            end
        end

        local function applyGraySky()
            if not Config.GRAY_SKY_ENABLED then return end
            for _, obj in pairs(Lighting:GetChildren()) do
                if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then obj:Destroy() end
            end
            local sky = Instance.new("Sky")
            sky.SkyboxBk = Config.GRAY_SKY_ID
            sky.SkyboxDn = Config.GRAY_SKY_ID
            sky.SkyboxFt = Config.GRAY_SKY_ID
            sky.SkyboxLf = Config.GRAY_SKY_ID
            sky.SkyboxRt = Config.GRAY_SKY_ID
            sky.SkyboxUp = Config.GRAY_SKY_ID
            sky.SunAngularSize = 0
            sky.MoonAngularSize = 0
            sky.StarCount = 0
            sky.Parent = Lighting
        end

        local function applyFullBright()
            if not Config.FULL_BRIGHT_ENABLED then return end
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.ExposureCompensation = 0
        end

        local function simplifyTerrain()
            if Terrain then
                Terrain.Decoration = false
                Terrain:SetAttribute("GrassDistance", 0)
                Terrain:SetAttribute("WaterWaveSize", 0)
                Terrain:SetAttribute("WaterWaveSpeed", 0)
                Terrain:SetAttribute("WaterTransparency", 1)
                Terrain:SetAttribute("WaterReflectance", 0)
            end
        end

        local function optimizeLighting()
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 0
            Lighting.FogColor = Color3.fromRGB(200, 200, 200)
            Lighting.ShadowSoftness = 0
            Lighting.GlobalShadows = false
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") then v:Destroy() end
            end
        end

        local function optimizeLightingAdvanced()
            Lighting.GlobalShadows = false
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.ExposureCompensation = 0
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then effect:Destroy() end
            end
        end

        local function convertToLowPoly()
            if not Config.LOW_POLY_CONVERSION then return end
            local complexMeshKeywords = { "mesh", "part", "model", "detail", "ornament", "decal", "couch", "design" }
            local function shouldSimplify(part)
                if part:IsA("MeshPart") then return true end
                if part:IsA("Part") then
                    for _, child in ipairs(part:GetChildren()) do
                        if child:IsA("SpecialMesh") or child:IsA("BlockMesh") or child:IsA("CylinderMesh") or child:IsA("FileMesh") then return true end
                    end
                    local partName = part.Name:lower()
                    for _, keyword in ipairs(complexMeshKeywords) do
                        if partName:find(keyword:lower()) then return true end
                    end
                end
                return false
            end
            local function simplifyMeshPart(meshPart)
                if not meshPart or not meshPart.Parent then return end
                local replacement = Instance.new("Part")
                replacement.Name = "LowPoly_" .. meshPart.Name
                replacement.Size = meshPart.Size
                replacement.CFrame = meshPart.CFrame
                replacement.Color = meshPart.Color
                replacement.Material = Enum.Material.SmoothPlastic
                replacement.Transparency = meshPart.Transparency
                replacement.Anchored = meshPart.Anchored
                replacement.CanCollide = meshPart.CanCollide
                replacement.CastShadow = false
                replacement.Shape = Enum.PartType.Block
                for _, child in ipairs(meshPart:GetChildren()) do
                    if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Attachment") or child:IsA("Motor6D") then child:Clone().Parent = replacement end
                end
                replacement.Parent = meshPart.Parent
                meshPart:Destroy()
            end
            local function simplifyModel(model)
                if not model:IsA("Model") and not model:IsA("Folder") then return end
                for _, descendant in ipairs(model:GetDescendants()) do
                    if (descendant:IsA("MeshPart") or descendant:IsA("Part")) and shouldSimplify(descendant) then pcall(simplifyMeshPart, descendant) end
                end
            end
            for _, model in ipairs(Workspace:GetDescendants()) do
                if model:IsA("Model") and #model:GetChildren() > 0 then pcall(simplifyModel, model) end
            end
        end

        local function removeReflectionsAndOptimize()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                    for _, child in pairs(obj:GetChildren()) do
                        if child:IsA("SurfaceAppearance") then child:Destroy() end
                    end
                    if obj:CanSetNetworkOwnership() then obj:SetNetworkOwnershipAuto() end
                    pcall(function() PhysicsService:SetPartCollisionGroup(obj, Config.COLLISION_GROUP_NAME) end)
                    if obj:GetPropertyChangedSignal("AssemblyLinearVelocity") then
                        obj.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        obj.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    obj.Enabled = false
                elseif obj:IsA("Reflection") then obj:Destroy() end
            end
        end

        local function disableConstraints()
            if not Config.DISABLE_CONSTRAINTS then return end
            for _, c in ipairs(Workspace:GetDescendants()) do
                if (c:IsA("AlignPosition") or c:IsA("AlignOrientation") or c:IsA("Motor") or c:IsA("HingeConstraint") or c:IsA("RodConstraint")) and not shouldSkip(c) then pcall(function() c.Enabled = false end) end
            end
        end

        local function throttleTextures()
            if not Config.THROTTLE_TEXTURES then return end
            for _, t in ipairs(Workspace:GetDescendants()) do
                if (t:IsA("Decal") or t:IsA("Texture") or t:IsA("ImageLabel") or t:IsA("ImageButton")) and not shouldSkip(t) then pcall(function() t.Transparency = 1 end) elseif t:IsA("SurfaceAppearance") and not shouldSkip(t) then pcall(function() t:Destroy() end) end
            end
        end

        local function optimizePhysics()
            if not Config.OPTIMIZE_PHYSICS then return end
            settings().Rendering.QualityLevel = Config.QUALITY_LEVEL
            settings().Physics.PhysicsEnvironmentalThrottle = 2
            for _, part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CastShadow = false
                    if part:IsGrounded() then
                        part.Anchored = false
                        part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end

        local function throttleParticles()
            if not Config.THROTTLE_PARTICLES then return end
            for _, p in ipairs(Workspace:GetDescendants()) do
                if p:IsA("ParticleEmitter") and not shouldSkip(p) then pcall(function() p.Enabled = false end) end
            end
        end

        local function Core()
            if not Config.CORE then return end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Physics.AllowSleep = true
            settings().Rendering.EagerBulkExecution = true
            settings().Rendering.EnableFRM = true
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
            settings().Rendering.TextureQuality = Enum.TextureQuality.Low
            if setfpscap then setfpscap(Config.FPS_CAP) end
        end

        local function removeAllTextures()
            for _, object in pairs(Workspace:GetDescendants()) do
                if object:IsA("BasePart") then
                    object.Material = Enum.Material.SmoothPlastic
                    for _, decal in pairs(object:GetChildren()) do
                        if decal:IsA("Decal") then decal:Destroy() end
                    end
                end
            end
        end

        local function initializeCollisionGroups()
            pcall(function()
                PhysicsService:CreateCollisionGroup(Config.COLLISION_GROUP_NAME)
                PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, Config.COLLISION_GROUP_NAME, false)
                PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, "Default", false)
            end)
        end

        local function binmem()
            if collectgarbage("count") > Config.MEMORY_CLEANUP_THRESHOLD then collectgarbage("collect") end
        end

        local function selectiveTextureRemoval()
            if not Config.SELECTIVE_TEXTURE_REMOVAL then return end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj:IsA("Decal") or obj:IsA("Texture")) and not shouldSkip(obj) then
                    local shouldPreserve = false
                    if Config.PRESERVE_IMPORTANT_TEXTURES then
                        local objName = obj.Name:lower()
                        local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                        for _, keyword in ipairs(Config.IMPORTANT_TEXTURE_KEYWORDS) do
                            if objName:find(keyword:lower()) or parentName:find(keyword:lower()) then
                                shouldPreserve = true; break
                            end
                        end
                    end
                    if not shouldPreserve then pcall(function() obj.Transparency = 1 end) end
                end
            end
        end

        local function optimizeUIAdvanced()
            for _, gui in ipairs(CoreGui:GetDescendants()) do
                if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then gui.ImageTransparency = 0.3 elseif gui:IsA("Frame") then gui.BackgroundTransparency = 0.5 end
            end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p:FindFirstChild("PlayerGui") then
                    for _, gui in ipairs(p.PlayerGui:GetDescendants()) do
                        if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then pcall(function() gui.ImageTransparency = 0.5 end) end
                    end
                end
            end
        end

        local function optimizeNetworkSettings()
            if not Config.NETWORK_OPTIMIZATION then return end
            settings().Network.StreamingEnabled = Config.STREAMING_ENABLED
            if settings().Physics then settings().Physics.PhysicsSendRate = 60 end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then pcall(function() humanoid.AutoJumpEnabled = false end) end
                end
            end
        end

        local function reduceReplication()
            if not Config.REDUCE_REPLICATION then return end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if obj.Anchored and not obj:IsDescendantOf(LocalPlayer.Character) then pcall(function() obj:SetNetworkOwner(nil) end) end
                    local distance = 0
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        distance = (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    end
                    if distance > Config.REDUCE_PLAYER_REPLICATION_DISTANCE then pcall(function() obj:SetNetworkOwnershipAuto() end) end
                end
            end
        end

        local function throttleRemoteEvents()
            if not Config.THROTTLE_REMOTE_EVENTS then return end
            local remoteThrottle = {}
            local maxCallsPerSecond = 10
            local function throttleRemote(remote, ...)
                local currentTime = tick()
                local remoteId = tostring(remote)
                if not remoteThrottle[remoteId] then remoteThrottle[remoteId] = {} end
                for i = #remoteThrottle[remoteId], 1, -1 do
                    if currentTime - remoteThrottle[remoteId][i] > 1 then table.remove(remoteThrottle[remoteId], i) end
                end
                if #remoteThrottle[remoteId] < maxCallsPerSecond then
                    table.insert(remoteThrottle[remoteId], currentTime)
                    return true
                end
                return false
            end
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    local oldFireServer = obj.FireServer
                    obj.FireServer = function(self, ...) if throttleRemote(self, ...) then return oldFireServer(self, ...) end end
                elseif obj:IsA("RemoteFunction") then
                    local oldInvokeServer = obj.InvokeServer
                    obj.InvokeServer = function(self, ...) if throttleRemote(self, ...) then return oldInvokeServer(self, ...) end end
                end
            end
        end

        local function optimizeChat()
            if not Config.OPTIMIZE_CHAT then return end
            pcall(function()
                if TextChatService then
                    local channel = TextChatService:FindFirstChild("TextChannels"):FindFirstChild("RBXGeneral")
                    if channel then channel.MaximumChannelHistory = 50 end
                end
            end)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then pcall(function() if p:GetAttribute("BubbleChatEnabled") ~= nil then p:SetAttribute("BubbleChatEnabled", false) end end) end
            end
        end

        local function disableUnnecessaryGUI()
            if not Config.DISABLE_UNNECESSARY_GUI then return end
            local elementsToDisable = { "PlayerList", "EmotesMenu", "Health", "BubbleChat" }
            for _, element in ipairs(elementsToDisable) do
                pcall(function() local guiElement = CoreGui:FindFirstChild(element) if guiElement then guiElement.Enabled = false end end)
            end
            GuiService:SetGlobalGuiInset(0, 0, 0, 0)
        end

        local function throttleSounds()
            if not Config.THROTTLE_SOUNDS then return end
            for _, sound in ipairs(Workspace:GetDescendants()) do
                if sound:IsA("Sound") then
                    local distance = 0
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        distance = (sound.Parent and sound.Parent:IsA("BasePart") and (sound.Parent.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0
                    end
                    if distance > Config.MAX_DISTANCE then
                        sound:Stop()
                        sound.Playing = false
                    elseif distance > Config.MAX_DISTANCE / 2 then
                        sound.Volume = sound.Volume * 0.3
                    end
                end
            end
        end

        local function optimizeDataModel()
            pcall(function() HttpService.HttpEnabled = false end)
            pcall(function() if Stats then Stats.PerformanceStats.MeshCacheSize = 10; Stats.PerformanceStats.TextureCacheSize = 10 end end)
        end

        local function applya()
            applyGraySky()
            applyFullBright()
            simplifyTerrain()
            optimizeLighting()
            optimizeLightingAdvanced()
            removeReflectionsAndOptimize()
            optimizePhysics()
            setSmoothPlastic()
            removePlayerAnimations()
            convertToLowPoly()
            Core()
            optimizeUIAdvanced()
            disableConstraints()
            throttleParticles()
            throttleTextures()
            optimizeUI()
            removeAllTextures()
            initializeCollisionGroups()
            binmem()
            selectiveTextureRemoval()
            RemoveMesh()
            optimizeNetworkSettings()
            reduceReplication()
            throttleRemoteEvents()
            optimizeChat()
            disableUnnecessaryGUI()
            throttleSounds()
            optimizeDataModel()
            RemoveEmitters()
        end

        applya()
        
        Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function(character)
                task.wait(1)
                safeCall(removePlayerAnimations, "new_player_animations")
            end)
        end)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then safeCall(removePlayerAnimations, "initial_player_animations") end
        end
        
        local lastHeavyOptimization = 0
        while true do
            local currentTime = tick()
            if currentTime - lastHeavyOptimization >= 20 then
                safeCall(applya, "heavy_optimization")
                lastHeavyOptimization = currentTime
            end
            safeCall(removePlayerAnimations, "player_animations")
            task.wait(Config.OPTIMIZATION_INTERVAL)
        end
    end)
end
