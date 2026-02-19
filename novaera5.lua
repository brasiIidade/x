local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local ts = cr(game:GetService("TweenService"))
local lp = cr(plrs.LocalPlayer)

local oK
oK = hookmetamethod(game, "__namecall", function(self, ...)
    if not checkcaller() and getnamecallmethod() == "Kick" and self == lp then return end
    return oK(self, ...)
end)

local lgc = { Enabled = false, TotalProfit = 0, SessionStart = 0, UpdateCallback = nil }
getgenv().NovaEraLogic = lgc

local off = CFrame.new(0, -9, 0)
local sCf = nil
local v0 = Vector3.zero
local cTw = nil

local function gMon()
    local ls = lp:FindFirstChild("leaderstats")
    local m = ls and ls:FindFirstChild("Dinheiro")
    return m and (tonumber(m.Value or m.Text) or 0) or 0
end

local function cGrav(c)
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("AG")
            if bv then bv:Destroy() end
        end
    end
    if cTw then cTw:Cancel() cTw = nil end
end

local function sGrav(hrp)
    if not hrp:FindFirstChild("AG") then
        local bv = Instance.new("BodyVelocity")
        bv.Name, bv.Velocity, bv.MaxForce, bv.P, bv.Parent = "AG", v0, Vector3.new(9e9, 9e9, 9e9), 9000, hrp
    end
end

local function gCls(tN)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local t = ws:FindFirstChild("Trabalhos / SWATntj")
    local cl = t and t:FindFirstChild("Coleta")
    if not cl then return end

    local bP, bD = nil, 9e9
    for _, v in ipairs(cl:GetChildren()) do
        if v.Name == tN then
            local p = v:FindFirstChildWhichIsA("ProximityPrompt")
            if p and p.Enabled and v:IsA("BasePart") then
                local d = (v.Position - hrp.Position).Magnitude
                if d < bD then 
                    bD = d
                    bP = p 
                end
            end
        end
    end
    return bP
end

local function twTo(t)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    sGrav(hrp)
    
    local tgCf = t.CFrame * off
    local d = (hrp.Position - tgCf.Position).Magnitude
    
    if d < 3 then 
        hrp.CFrame = tgCf
        return 
    end
    
    local spd = 115
    local ti = TweenInfo.new(d / spd, Enum.EasingStyle.Linear)
    
    if cTw then cTw:Cancel() end
    cTw = ts:Create(hrp, ti, {CFrame = tgCf})
    cTw:Play()
    cTw.Completed:Wait()
    task.wait(0.1)
end

function lgc.Toggle(s)
    lgc.Enabled = s
    local m = gMon()
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    
    if s then
        lgc.SessionStart = m
        if hrp then
            sCf = hrp.CFrame
            hrp.CFrame = hrp.CFrame * off
            sGrav(hrp)
            hrp.AssemblyLinearVelocity = v0
        end
    else
        cGrav(c)
        lgc.TotalProfit = lgc.TotalProfit + (m - lgc.SessionStart)
        if sCf and hrp then
            hrp.CFrame = sCf
            hrp.AssemblyLinearVelocity = v0
        end
    end
end

rs.Heartbeat:Connect(function()
    if not lgc.UpdateCallback then return end
    lgc.UpdateCallback(lgc.Enabled and (lgc.TotalProfit + (gMon() - lgc.SessionStart)) or lgc.TotalProfit)
end)

task.spawn(function()
    while true do
        if lgc.Enabled then
            local c = lp.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                for _, bp in ipairs(c:GetDescendants()) do
                    if bp:IsA("BasePart") then bp.CanCollide = false end
                end
                
                sGrav(hrp)
                
                local tN = c:FindFirstChild("Lixo_model") and "Lixeira" or "Lixo"
                local prm = gCls(tN)
                
                if prm and prm.Parent then
                    prm.HoldDuration = 0
                    twTo(prm.Parent)
                    if lgc.Enabled and hum.Health > 0 then
                        fireproximityprompt(prm)
                        task.wait(0.2)
                    end
                else
                    task.wait(0.1)
                end
            else
                cGrav(c)
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end)
