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

local off = Vector3.new(0, -9, 0)
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
    hrp.AssemblyLinearVelocity = v0
    hrp.AssemblyAngularVelocity = v0
end

local function gCls(tN)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local t = ws:FindFirstChild("Trabalhos / SWATntj")
    local cl = t and t:FindFirstChild("Coleta")
    if not cl then return nil end

    local bP, bD = nil, math.huge
    for _, v in ipairs(cl:GetChildren()) do
        if v.Name == tN then
            local p = v:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p and p.Enabled then
                local pt = p.Parent
                if pt and pt:IsA("Attachment") then pt = pt.Parent end
                if pt and pt:IsA("BasePart") then
                    local d = (pt.Position - hrp.Position).Magnitude
                    if d < bD then 
                        bD = d
                        bP = p 
                    end
                end
            end
        end
    end
    return bP
end

local function twTo(pt, hum)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    sGrav(hrp)
    
    local tCf = CFrame.new(pt.Position + off)
    local d = (hrp.Position - tCf.Position).Magnitude
    
    if d < 1.5 then 
        hrp.CFrame = tCf
        return true 
    end
    
    local spd = 65
    local ti = TweenInfo.new(d / spd, Enum.EasingStyle.Linear)
    
    if cTw then cTw:Cancel() end
    cTw = ts:Create(hrp, ti, {CFrame = tCf})
    
    local cnn
    cnn = rs.Heartbeat:Connect(function()
        if not lgc.Enabled or hum.Health <= 0 or not pt.Parent then
            if cTw then cTw:Cancel() end
        else
            sGrav(hrp)
            for _, bp in ipairs(c:GetDescendants()) do
                if bp:IsA("BasePart") then bp.CanCollide = false end
            end
        end
    end)
    
    cTw:Play()
    cTw.Completed:Wait()
    cnn:Disconnect()
    
    return lgc.Enabled and hum.Health > 0 and pt.Parent ~= nil
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
            hrp.CFrame = CFrame.new(hrp.Position + off)
            sGrav(hrp)
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
                sGrav(hrp)
                
                local hasL = c:FindFirstChild("Lixo_model") ~= nil
                local tN = hasL and "Lixeira" or "Lixo"
                local prm = gCls(tN)
                
                if prm and prm.Parent then
                    local pt = prm.Parent
                    if pt:IsA("Attachment") then pt = pt.Parent end
                    
                    if pt and pt:IsA("BasePart") then
                        prm.HoldDuration = 0
                        local ok = twTo(pt, hum)
                        
                        if ok then
                            local sT = tick()
                            repeat
                                if not lgc.Enabled or hum.Health <= 0 then break end
                                local chk = c:FindFirstChild("Lixo_model") ~= nil
                                if chk ~= hasL then break end
                                if tick() - sT > 5 then break end
                                
                                sGrav(hrp)
                                hrp.CFrame = CFrame.new(pt.Position + off)
                                fireproximityprompt(prm)
                                task.wait(0.1)
                            until not prm.Parent or not prm.Enabled or not pt.Parent
                        end
                    else
                        task.wait(0.1)
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
