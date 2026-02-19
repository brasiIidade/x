local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local ts = cr(game:GetService("TweenService"))
local lp = cr(plrs.LocalPlayer)

local lgc = { Enabled = false, TotalProfit = 0, SessionStart = 0, UpdateCallback = nil }
getgenv().NovaEraLogic = lgc

local off = CFrame.new(0, -9, 0)
local sCf = nil
local v0 = Vector3.zero
local curTw = nil

local function gMon()
    local ls = lp:FindFirstChild("leaderstats")
    local m = ls and ls:FindFirstChild("Dinheiro")
    if m then
        return tonumber(m.Value or m.Text) or 0
    end
    return 0
end

local function cGrav(c)
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("AG")
            if bv then bv:Destroy() end
        end
    end
    if curTw then 
        curTw:Cancel() 
        curTw = nil 
    end
end

local function twTo(t)
    local c = lp.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not hrp:FindFirstChild("AG") then
        local bv = Instance.new("BodyVelocity")
        bv.Name, bv.Velocity, bv.MaxForce, bv.P, bv.Parent = "AG", v0, Vector3.new(9e9, 9e9, 9e9), 9000, hrp
    end
    
    local tgCf = t.CFrame * off
    local d = (hrp.Position - tgCf.Position).Magnitude
    
    if d < 3 then 
        hrp.CFrame = tgCf
        return 
    end
    
    local spd = 250
    local ti = TweenInfo.new(d / spd, Enum.EasingStyle.Linear)
    
    if curTw then curTw:Cancel() end
    curTw = ts:Create(hrp, ti, {CFrame = tgCf})
    curTw:Play()
    curTw.Completed:Wait()
end

local function gPrm(p)
    if not p then return end
    for _, v in ipairs(p:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled and v.Parent and v.Parent:IsA("BasePart") then
            return v
        end
    end
end

function lgc.Toggle(s)
    lgc.Enabled = s
    local m = gMon()
    if s then
        lgc.SessionStart = m
        local c = lp.Character
        if c and c:FindFirstChild("HumanoidRootPart") then 
            sCf = c.HumanoidRootPart.CFrame 
        end
    else
        cGrav(lp.Character)
        lgc.TotalProfit = lgc.TotalProfit + (m - lgc.SessionStart)
        local c = lp.Character
        if sCf and c and c:FindFirstChild("HumanoidRootPart") then
            c.HumanoidRootPart.CFrame = sCf
            c.HumanoidRootPart.AssemblyLinearVelocity = v0
        end
    end
end

rs.Heartbeat:Connect(function()
    if not lgc.UpdateCallback then return end
    if lgc.Enabled then
        lgc.UpdateCallback(lgc.TotalProfit + (gMon() - lgc.SessionStart))
    else
        lgc.UpdateCallback(lgc.TotalProfit)
    end
end)

task.spawn(function()
    while true do
        if lgc.Enabled then
            local c = lp.Character
            if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 then
                
                for _, bp in ipairs(c:GetDescendants()) do
                    if bp:IsA("BasePart") then bp.CanCollide = false end
                end
                
                local t = ws:FindFirstChild("Trabalhos / SWATntj")
                local cl = t and t:FindFirstChild("Coleta")
                
                if cl then
                    local hasL = c:FindFirstChild("Lixo_model") ~= nil
                    local tgP = hasL and cl:FindFirstChild("Lixeira") or cl:FindFirstChild("Lixo")
                    local prm = gPrm(tgP)
                    
                    if prm and prm.Parent then
                        prm.HoldDuration = 0
                        twTo(prm.Parent)
                        
                        if lgc.Enabled and c.Humanoid.Health > 0 then
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
                cGrav(c)
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end)
