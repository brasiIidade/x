local z = false
local k =
[[
    skid
]]
if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" then
  return z and tostring(k) or nil
end

local cloneref = cloneref or function(o) return o end

local Replicated = cloneref(game:GetService("ReplicatedStorage"))
local Players = cloneref(game:GetService("Players"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = cloneref(Players.LocalPlayer)

local Logic = {}
Logic.Enabled = false
Logic.TotalProfit = 0
Logic.SessionStart = 0
Logic.UpdateCallback = nil

local OffsetAltura = -9
local OffsetFrame = CFrame.new(0, OffsetAltura, 0)
local SavedCFrame = nil
local ZeroVector = Vector3.zero

local TrabEntregador = Workspace:WaitForChild("Trabalhos"):WaitForChild("Entregador")
local PromptsBase = TrabEntregador:WaitForChild("Prompts")
local CaixaPart = PromptsBase:WaitForChild("Caixa")
local EntregadorFolders = {
    PromptsBase:WaitForChild("Entregar_B"),
    PromptsBase:WaitForChild("Entregar_F"),
    PromptsBase:WaitForChild("Frutas"),
    PromptsBase:WaitForChild("Bebidas")
}

local function ClearAntigravity()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        local bv = c.HumanoidRootPart:FindFirstChild("Antigravity")
        if bv then bv:Destroy() end
    end
end

local function TeleportTo(target)
    local c = LocalPlayer.Character
    if c then
        local r = c:FindFirstChild("HumanoidRootPart")
        if r then
            if not r:FindFirstChild("Antigravity") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "Antigravity"
                bv.Velocity = ZeroVector
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.P = 9000
                bv.Parent = r
            end
            r.CFrame = target.CFrame * OffsetFrame
            r.AssemblyLinearVelocity = ZeroVector
            r.AssemblyAngularVelocity = ZeroVector
        end
    end
end

local function FindDestino()
    for i = 1, 4 do
        local att = EntregadorFolders[i]:FindFirstChild("AttachmentDestino")
        if att then return att end
    end
    return nil
end

function Logic.Toggle(state)
    Logic.Enabled = state
    OffsetFrame = CFrame.new(0, OffsetAltura, 0)
    local d = LocalPlayer:FindFirstChild("Dados")
    local m = d and d:FindFirstChild("Dinheiro")
    local cur = m and m.Value or 0

    if state then
        Logic.SessionStart = cur
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            SavedCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        end
    else
        ClearAntigravity()
        Logic.TotalProfit = Logic.TotalProfit + (cur - Logic.SessionStart)
        if SavedCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = SavedCFrame
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = ZeroVector
        end
    end
end

task.spawn(function()
    while true do
        if Logic.Enabled then
            local d = LocalPlayer:FindFirstChild("Dados")
            local m = d and d:FindFirstChild("Dinheiro")
            if m and Logic.UpdateCallback then
                local display = Logic.TotalProfit + (m.Value - Logic.SessionStart)
                Logic.UpdateCallback(display)
            end
        elseif Logic.UpdateCallback then
            Logic.UpdateCallback(Logic.TotalProfit)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if Logic.Enabled then
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
                local att = FindDestino()
                if not att then
                    local p = CaixaPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if p then
                        p.HoldDuration = 0
                        repeat
                            if not Logic.Enabled or c.Humanoid.Health <= 0 then break end
                            TeleportTo(CaixaPart)
                            fireproximityprompt(p)
                            RunService.Heartbeat:Wait()
                            att = FindDestino()
                        until att
                    end
                else
                    local dest = att.Parent
                    if dest then
                        local p = dest:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p then
                            p.HoldDuration = 0
                            repeat
                                if not Logic.Enabled or c.Humanoid.Health <= 0 then break end
                                TeleportTo(dest)
                                fireproximityprompt(p)
                                RunService.Heartbeat:Wait()
                            until not att.Parent or att.Parent ~= dest
                        end
                    end
                end
            else
                ClearAntigravity()
                task.wait(0.5)
            end
        else
            ClearAntigravity()
            task.wait(0.5)
        end
        if Logic.Enabled then RunService.Heartbeat:Wait() end
    end
end)

_G.SoucreLogic = Logic
