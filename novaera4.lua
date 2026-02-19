local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local lp = cr(plrs.LocalPlayer)

local oK
oK = hookmetamethod(game, "__namecall", function(self, ...)
    if not checkcaller() and getnamecallmethod() == "Kick" and self == lp then return end
    return oK(self, ...)
end)

local lgc = { Enabled = false, TotalProfit = 0, SessionStart = 0, UpdateCallback = nil }
getgenv().NovaEraLogic = lgc

local sCf = nil
local v0 = Vector3.zero

local function gMon()
    local ls = lp:FindFirstChild("leaderstats")
    local m = ls and ls:FindFirstChild("Dinheiro")
    return m and (tonumber(m.Value or m.Text) or 0) or 0
end

local function cMv(c)
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, n in ipairs({"MvA", "MvAP", "MvAO"}) do
            local i = hrp:FindFirstChild(n)
            if i then i:Destroy() end
        end
        hrp.AssemblyLinearVelocity = v0
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
            if p and p.Enabled then
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

local function mTo(tg)
    local c = lp.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local a = hrp:FindFirstChild("MvA") or Instance.new("Attachment", hrp)
    a.Name = "MvA"
    
    local ap = hrp:FindFirstChild("MvAP") or Instance.new("AlignPosition", hrp)
    ap.Name, ap.Attachment0, ap.Mode, ap.MaxForce, ap.MaxVelocity, ap.Responsiveness = "MvAP", a, 0, 9e9, 115, 200
    
    local ao = hrp:FindFirstChild("MvAO") or Instance.new("AlignOrientation", hrp)
    ao.Name, ao.Mode, ao.Attachment0, ao.MaxTorque, ao.Responsiveness = "MvAO", 0, a, 9e9, 200

    local fP = tg.Position + Vector3.new(0, -9, 0)
    ap.Position = fP
    ao.CFrame = CFrame.lookAt(hrp.Position, fP)

    local sT = tick()
    while lgc.Enabled and (hrp.Position - fP).Magnitude > 3 do
        if tick() - sT > 8 then break end
        rs.Heartbeat:Wait()
    end
    
    if lgc.Enabled then
        hrp.CFrame = CFrame.new(fP)
        hrp.AssemblyLinearVelocity = v0
    end
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
            hrp.CFrame = hrp.CFrame + Vector3.new(0, -9, 0)
        end
    else
        cMv(c)
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
                
                local tN = c:FindFirstChild("Lixo_model") and "Lixeira" or "Lixo"
                local prm = gCls(tN)
                
                if prm and prm.Parent then
                    prm.HoldDuration = 0
                    mTo(prm.Parent)
                    if lgc.Enabled and hum.Health > 0 then
                        fireproximityprompt(prm)
                        task.wait(0.2)
                    end
                else
                    task.wait(0.1)
                end
            else
                cMv(c)
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end)
