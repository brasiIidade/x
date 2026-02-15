local cloneref = cloneref or function(o) return o end

local game = cloneref(game)
local Lighting = cloneref(game:GetService("Lighting"))
local PhysicsService = cloneref(game:GetService("PhysicsService"))
local GuiService = cloneref(game:GetService("GuiService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local Stats = cloneref(game:GetService("Stats"))
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local HttpService = cloneref(game:GetService("HttpService"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local TeleportService = cloneref(game:GetService("TeleportService"))

local Terrain = cloneref(Workspace:FindFirstChildOfClass("Terrain") or Workspace.Terrain)
local LocalPlayer = cloneref(Players.LocalPlayer)

local getgenv = getgenv or function() return _G end
local hookmetamethod = hookmetamethod or function() end
local getnamecallmethod = getnamecallmethod or function() return "" end
local checkcaller = checkcaller or function() return false end
local setfpscap = setfpscap or function() end
local sethiddenproperty = sethiddenproperty or function(i, p, v) pcall(function() i[p] = v end) end

local env = getgenv()
env.AntiLag = env.AntiLag or {}

if env.AntiLag.Running then return end
env.AntiLag.Running = false

local OriginalIndex
OriginalIndex = hookmetamethod(game, "__index", function(t, k)
    if not checkcaller() then
        if t == Lighting and k == "Brightness" then return 1 end
        if t == Lighting and k == "GlobalShadows" then return true end
        if t == Lighting and k == "FogEnd" then return 100000 end
        if t == Workspace and k == "StreamingEnabled" then return false end
        if typeof(t) == "Instance" and t:IsA("BasePart") then
            if k == "Material" then return Enum.Material.Plastic end
            if k == "Reflectance" then return 0 end
            if k == "Transparency" then return 0 end
        end
        if typeof(t) == "Instance" and (t:IsA("Decal") or t:IsA("Texture")) and k == "Transparency" then
            return 0
        end
    end
    return OriginalIndex(t, k)
end)

local OriginalNamecall
OriginalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() then
        if method == "GetDescendants" or method == "GetChildren" then
            local results = OriginalNamecall(self, ...)
            if type(results) == "table" then
                local filtered = {}
                for i = 1, #results do
                    local obj = results[i]
                    if typeof(obj) == "Instance" then
                        if obj:IsA("Sky") and obj.Name == "OptimizedSky" then continue end
                        if obj:IsA("Part") and obj.Name:match("^LowPoly_") then continue end
                    end
                    filtered[#filtered + 1] = obj
                end
                return filtered
            end
        end
    end
    return OriginalNamecall(self, ...)
end)

env.AntiLag.Start = function()
    if env.AntiLag.Running then return end
    env.AntiLag.Running = true

    task.spawn(function()
        local Config = {
            OPTIMIZATION_INTERVAL = 10,
            MAX_DISTANCE = 50,
            GRAY_SKY_ID = "rbxassetid://114666145996289",
            COLLISION_GROUP_NAME = "OptimizedParts",
            FPS_CAP = 1000,
            MEMORY_CLEANUP_THRESHOLD = 500,
            REDUCE_PLAYER_REPLICATION_DISTANCE = 100,
            IMPORTANT_TEXTURE_KEYWORDS = {"sign", "ui", "hud", "menu", "button", "fence"}
        }

        local function safeCall(func, ...)
            local success, err = pcall(func, ...)
            return success
        end

        local function isLocalPlayer(instance)
            if LocalPlayer and LocalPlayer.Character and instance:IsDescendantOf(LocalPlayer.Character) then return true end
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and instance:IsDescendantOf(p.Character) then return true end
            end
            return false
        end

        local function setSmoothPlastic()
            local function handleInstance(instance)
                if isLocalPlayer(instance) then return end
                if instance:IsA("BasePart") then
                    pcall(function()
                        instance.Material = Enum.Material.SmoothPlastic
                        instance.Reflectance = 0
                    end)
                elseif instance:IsA("Texture") or instance:IsA("Decal") then
                    pcall(function() instance.Transparency = 1 end)
                end
            end
            for _, instance in ipairs(Workspace:GetDescendants()) do handleInstance(instance) end
            Workspace.DescendantAdded:Connect(handleInstance)
        end

        local function removeTextures()
            local keywords = { "chair", "seat", "stool", "bench", "coffee", "fruit", "paper", "document", "note", "cup", "mug", "photo", "monitor", "screen", "display", "pistol", "rifle", "plate", "computer", "laptop", "desktop", "bedframe", "table", "desk", "plank", "cloud", "furniture", "bottle", "cardboard", "chest", "book", "pillow", "magazine", "poster", "sign", "billboard", "keyboard", "picture", "frame", "painting", "pipe", "wires", "fridge", "glass", "leaf", "window", "pane", "shelf", "phone", "tree", "bush", "plant", "foliage", "boxes", "decor", "ornament", "detail", "knob", "handle", "wall", "prop", "object", "tool", "weapon", "food", "drink", "bloxy", "cola", "container", "box", "bag", "case", "stand", "rack", "holder", "support", "leg", "arm", "back", "top", "base", "cover", "lid", "door", "drawer", "switch", "lever", "wheel", "chain", "rope", "wire", "cable", "tube", "hose", "vent", "fan", "motor", "engine", "machine", "equipment", "device", "closet", "potplant", "balloons" }
            
            local function hasKeyword(name)
                name = name:lower()
                for i = 1, #keywords do
                    if name:find(keywords[i]) then return true end
                end
                return false
            end

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not isLocalPlayer(obj) and hasKeyword(obj.Name) then
                    pcall(function()
                        for _, child in ipairs(obj:GetChildren()) do
                            if child:IsA("Decal") or child:IsA("Texture") then child:Destroy() end
                        end
                        obj.BrickColor = BrickColor.new("Medium stone grey")
                        obj.Material = Enum.Material.Plastic
                        if obj:IsA("Part") then
                            obj.TopSurface = Enum.SurfaceType.Smooth
                            obj.BottomSurface = Enum.SurfaceType.Smooth
                            obj.LeftSurface = Enum.SurfaceType.Smooth
                            obj.RightSurface = Enum.SurfaceType.Smooth
                            obj.FrontSurface = Enum.SurfaceType.Smooth
                            obj.BackSurface = Enum.SurfaceType.Smooth
                        end
                    end)
                end
            end
        end

        local function removeEmitters()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    pcall(function() obj.Enabled = false end)
                end
            end
        end

        local function simplifyTerrain()
            if Terrain then
                pcall(function()
                    sethiddenproperty(Terrain, "Decoration", false)
                    Terrain:SetAttribute("GrassDistance", 0)
                    Terrain:SetAttribute("WaterWaveSize", 0)
                    Terrain:SetAttribute("WaterWaveSpeed", 0)
                    Terrain:SetAttribute("WaterTransparency", 1)
                    Terrain:SetAttribute("WaterReflectance", 0)
                end)
            end
        end

        local function optimizeLighting()
            pcall(function()
                Lighting.Brightness = 2
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                Lighting.Ambient = Color3.new(1, 1, 1)
                Lighting.ExposureCompensation = 0
                Lighting.FogEnd = 1000000
                Lighting.FogStart = 0
                Lighting.FogColor = Color3.fromRGB(200, 200, 200)
                Lighting.ShadowSoftness = 0
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0

                for _, obj in ipairs(Lighting:GetChildren()) do
                    if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") or obj:IsA("PostEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BloomEffect") or obj:IsA("DepthOfFieldEffect") then
                        obj:Destroy()
                    end
                end

                local sky = Instance.new("Sky")
                sky.Name = "OptimizedSky"
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
            end)
        end

        local function optimizePhysics()
            pcall(function()
                PhysicsService:CreateCollisionGroup(Config.COLLISION_GROUP_NAME)
                PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, Config.COLLISION_GROUP_NAME, false)
                PhysicsService:CollisionGroupSetCollidable(Config.COLLISION_GROUP_NAME, "Default", false)
            end)

            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") and not isLocalPlayer(part) then
                    pcall(function()
                        part.CastShadow = false
                        part.Material = Enum.Material.SmoothPlastic
                        part.Reflectance = 0
                        
                        for _, child in ipairs(part:GetChildren()) do
                            if child:IsA("SurfaceAppearance") then child:Destroy() end
                        end

                        if part:GetPropertyChangedSignal("AssemblyLinearVelocity") then
                            part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end
                        
                        if part:IsGrounded() then
                            part.Anchored = false
                        end
                    end)
                elseif part:IsA("Reflection") then
                    pcall(function() part:Destroy() end)
                end
            end
        end

        local function optimizeConstraints()
            for _, c in ipairs(Workspace:GetDescendants()) do
                if (c:IsA("AlignPosition") or c:IsA("AlignOrientation") or c:IsA("Motor") or c:IsA("HingeConstraint") or c:IsA("RodConstraint")) and not isLocalPlayer(c) then
                    pcall(function() c.Enabled = false end)
                end
            end
        end

        local function coreSettings()
            pcall(function()
                local s = settings()
                s.Rendering.QualityLevel = Enum.QualityLevel.Level01
                s.Physics.AllowSleep = true
                s.Rendering.EagerBulkExecution = true
                s.Rendering.EnableFRM = true
                s.Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
                s.Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
                s.Rendering.TextureQuality = Enum.TextureQuality.Low
                s.Network.StreamingEnabled = true
                setfpscap(Config.FPS_CAP)
            end)
        end

        local function memoryCleanup()
            if collectgarbage("count") > Config.MEMORY_CLEANUP_THRESHOLD then
                collectgarbage("collect")
            end
        end

        local function throttleSounds()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            for _, sound in ipairs(Workspace:GetDescendants()) do
                if sound:IsA("Sound") then
                    pcall(function()
                        local dist = sound.Parent and sound.Parent:IsA("BasePart") and (sound.Parent.Position - root.Position).Magnitude or 0
                        if dist > Config.MAX_DISTANCE then
                            sound:Stop()
                            sound.Playing = false
                        elseif dist > Config.MAX_DISTANCE / 2 then
                            sound.Volume = sound.Volume * 0.3
                        end
                    end)
                end
            end
        end

        local function disableGui()
            local elements = { "PlayerList", "EmotesMenu", "Health", "BubbleChat" }
            for _, el in ipairs(elements) do
                pcall(function()
                    local g = CoreGui:FindFirstChild(el)
                    if g then g.Enabled = false end
                end)
            end
            pcall(function() GuiService:SetGlobalGuiInset(0, 0, 0, 0) end)
        end

        local function runOptimizations()
            safeCall(simplifyTerrain)
            safeCall(optimizeLighting)
            safeCall(optimizePhysics)
            safeCall(setSmoothPlastic)
            safeCall(coreSettings)
            safeCall(optimizeConstraints)
            safeCall(removeTextures)
            safeCall(removeEmitters)
            safeCall(disableGui)
            safeCall(throttleSounds)
            safeCall(memoryCleanup)
        end

        runOptimizations()

        local lastOpt = 0
        RunService.Heartbeat:Connect(function()
            local t = tick()
            if t - lastOpt >= Config.OPTIMIZATION_INTERVAL then
                lastOpt = t
                runOptimizations()
            end
        end)
    end)
end
