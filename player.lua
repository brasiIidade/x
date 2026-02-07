local z = false
local k =
[[
    skid
]]
if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" then
  return z and tostring(k) or nil
end

local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = cloneref(Players.LocalPlayer) 
local Camera = cloneref(Workspace.CurrentCamera)


_G.PlayerMod = _G.PlayerMod or {}
_G.PlayerMod.NoclipConnection = nil
_G.PlayerMod.AntiSpawnEnabled = false
_G.PlayerMod.DeathCFrame = nil
_G.PlayerMod.Viewing = false
_G.PlayerMod.ViewConnection = nil
_G.PlayerMod.ViewTarget = nil
_G.PlayerMod.TPTarget = nil
_G.PlayerMod.LastPos = nil
_G.PlayerMod.DefaultSpeed = 16
_G.PlayerMod.IsReady = true

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

local function onCharAdded(c)
    local h = c:WaitForChild("Humanoid", 10)
    if h then
        bypass(h)
        h.Died:Connect(function()
            if _G.PlayerMod.AntiSpawnEnabled and c:FindFirstChild("HumanoidRootPart") then
                _G.PlayerMod.DeathCFrame = c.HumanoidRootPart.CFrame
            else
                _G.PlayerMod.DeathCFrame = nil
            end
        end)
    end
    
    if _G.PlayerMod.AntiSpawnEnabled and _G.PlayerMod.DeathCFrame then
        local hrp = c:WaitForChild("HumanoidRootPart", 10)
        if hrp then
            task.wait(0.1)
            hrp.CFrame = _G.PlayerMod.DeathCFrame
        end
    end
end

if LocalPlayer.Character then
    onCharAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharAdded)

_G.PlayerMod.SetSpeed = function(val)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end

_G.PlayerMod.ResetSpeed = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = _G.PlayerMod.DefaultSpeed
    end
end

_G.PlayerMod.ToggleNoclip = function(state)
    if state then
        if _G.PlayerMod.NoclipConnection then _G.PlayerMod.NoclipConnection:Disconnect() end
        _G.PlayerMod.NoclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    else
        if _G.PlayerMod.NoclipConnection then
            _G.PlayerMod.NoclipConnection:Disconnect()
            _G.PlayerMod.NoclipConnection = nil
        end
    end
end

_G.PlayerMod.ToggleAntiSpawn = function(state)
    _G.PlayerMod.AntiSpawnEnabled = state
    if not state then _G.PlayerMod.DeathCFrame = nil end
end

_G.PlayerMod.ToggleChat = function(state)
    if TextChatService and TextChatService.ChatWindowConfiguration then
        TextChatService.ChatWindowConfiguration.Enabled = state
    end
end

_G.PlayerMod.FindPlayer = function(text)
    if not text or text == "" then return nil end
    text = text:lower()
    local match = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local name = p.Name:lower()
            if name:sub(1, #text) == text then
                return p
            elseif name:find(text, 1, true) then
                match = p
            end
        end
    end
    return match
end

_G.PlayerMod.ToggleView = function(state, targetName)
    _G.PlayerMod.Viewing = state
    if state then
        local target = _G.PlayerMod.FindPlayer(targetName)
        if target then
            _G.PlayerMod.ViewTarget = target
            if _G.PlayerMod.ViewConnection then _G.PlayerMod.ViewConnection:Disconnect() end
            _G.PlayerMod.ViewConnection = RunService.RenderStepped:Connect(function()
                if not _G.PlayerMod.ViewTarget or not _G.PlayerMod.ViewTarget.Parent then
                    _G.PlayerMod.ToggleView(false)
                    return
                end
                local hum = _G.PlayerMod.ViewTarget.Character and _G.PlayerMod.ViewTarget.Character:FindFirstChildOfClass("Humanoid")
                if hum then Camera.CameraSubject = hum end
            end)
            return target.Name
        else
            return nil
        end
    else
        if _G.PlayerMod.ViewConnection then
            _G.PlayerMod.ViewConnection:Disconnect()
            _G.PlayerMod.ViewConnection = nil
        end
        _G.PlayerMod.ViewTarget = nil
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then Camera.CameraSubject = hum end
        end
    end
end

_G.PlayerMod.TeleportTo = function(targetName)
    local target = _G.PlayerMod.FindPlayer(targetName)
    if target and target.Character and LocalPlayer.Character then
        _G.PlayerMod.LastPos = LocalPlayer.Character:GetPivot()
        LocalPlayer.Character:PivotTo(target.Character:GetPivot())
        return target.Name
    end
    return nil
end

_G.PlayerMod.ReturnPos = function()
    if _G.PlayerMod.LastPos and LocalPlayer.Character then
        LocalPlayer.Character:PivotTo(_G.PlayerMod.LastPos)
        return true
    end
    return false
end
