local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local lp = cr(plrs.LocalPlayer)

local lgc = { Enabled = false, TotalProfit = 0, SessionStart = 0, UpdateCallback = nil }
getgenv().SoucreLogic = lgc

local off = CFrame.new(0, -9, 0)
local sCf = nil
local v0 = Vector3.zero

local trab = ws:WaitForChild("Trabalhos"):WaitForChild("Entregador")
local pB = trab:WaitForChild("Prompts")
local cP = pB:WaitForChild("Caixa")
local flds = { pB:WaitForChild("Entregar_B"), pB:WaitForChild("Entregar_F"), pB:WaitForChild("Frutas"), pB:WaitForChild("Bebidas") }

local function cGrav(c)
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("AG")
            if bv then bv:Destroy() end
        end
    end
end

local function tp(t)
    local c = lp.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if not hrp:FindFirstChild("AG") then
        local bv = Instance.new("BodyVelocity")
        bv.Name, bv.Velocity, bv.MaxForce, bv.P, bv.Parent = "AG", v0, Vector3.new(9e9, 9e9, 9e9), 9000, hrp
    end
    hrp.CFrame = t.CFrame * off
    hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = v0, v0
end

local function fDst()
    for i = 1, 4 do
        local att = flds[i]:FindFirstChild("AttachmentDestino")
        if att then return att end
    end
    return nil
end

local function gMon()
    local d = lp:FindFirstChild("Dados")
    local m = d and d:FindFirstChild("Dinheiro")
    return m and m.Value or 0
end

function lgc.Toggle(s)
    lgc.Enabled = s
    local cur = gMon()
    
    if s then
        lgc.SessionStart = cur
        local c = lp.Character
        if c and c:FindFirstChild("HumanoidRootPart") then sCf = c.HumanoidRootPart.CFrame end
    else
        cGrav(lp.Character)
        lgc.TotalProfit = lgc.TotalProfit + (cur - lgc.SessionStart)
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

rs.Heartbeat:Connect(function()
    if not lgc.Enabled then 
        cGrav(lp.Character) 
        return 
    end
    
    local c = lp.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") or not c:FindFirstChild("Humanoid") or c.Humanoid.Health <= 0 then
        cGrav(c)
        return
    end

    local att = fDst()
    if not att then
        local p = cP:FindFirstChildWhichIsA("ProximityPrompt", true)
        if p then
            p.HoldDuration = 0
            tp(cP)
            fireproximityprompt(p)
        end
    else
        local d = att.Parent
        if d then
            local p = d:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then
                p.HoldDuration = 0
                tp(d)
                fireproximityprompt(p)
            end
        end
    end
end)
