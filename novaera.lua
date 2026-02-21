local cr = cloneref or function(a) return a end

local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local lp = cr(plrs.LocalPlayer)

local logic = {}
logic.Enabled = false
logic.Mode = "Lixeiro"
logic.Farmed = 0
logic.InitialMoney = 0
logic.UpdateCallback = nil

local offset = CFrame.new(0, -9, 0)
local zeroVec = Vector3.zero
local startCF = nil

local function getMoney()
    local ls = lp:FindFirstChild("leaderstats")
    local din = ls and ls:FindFirstChild("Dinheiro")
    if din then
        return tonumber(din.Value) or tonumber(din.Text) or 0
    end
    return 0
end

local function stopFloat()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ag = hrp:FindFirstChild("Antigravity")
        if ag then ag:Destroy() end
    end
end

local function floatAt(targetCF)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ag = hrp:FindFirstChild("Antigravity")
        if not ag then
            ag = Instance.new("BodyVelocity")
            ag.Name = "Antigravity"
            ag.Velocity = zeroVec
            ag.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            ag.P = 9000
            ag.Parent = hrp
        end
        hrp.CFrame = targetCF
        hrp.AssemblyLinearVelocity = zeroVec
        hrp.AssemblyAngularVelocity = zeroVec
    end
end

local function getPrompt(parent)
    if not parent then return nil end
    for _, v in ipairs(parent:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Enabled and v.Parent and v:IsDescendantOf(ws) then
            return v
        end
    end
    return nil
end

function logic.SetMode(m)
    logic.Mode = m
end

function logic.Toggle(state)
    logic.Enabled = state
    local m = getMoney()

    if state then
        logic.InitialMoney = m
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            startCF = hrp.CFrame
        end
    else
        stopFloat()
        logic.Farmed = logic.Farmed + (m - logic.InitialMoney)
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if startCF and hrp then
            hrp.CFrame = startCF
            hrp.AssemblyLinearVelocity = zeroVec
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if logic.UpdateCallback then
            if logic.Enabled then
                local cur = getMoney()
                logic.UpdateCallback(logic.Farmed + (cur - logic.InitialMoney))
            else
                logic.UpdateCallback(logic.Farmed)
            end
        end
    end
end)

task.spawn(function()
    while true do
        if logic.Enabled then
            local char = lp.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if char and hum and hrp and hum.Health > 0 then
                if logic.Mode == "Lixeiro" then
                    local trab = ws:FindFirstChild("Trabalhos / SWATntj")
                    local col = trab and trab:FindFirstChild("Coleta")
                    
                    if col then
                        local hasBag = char:FindFirstChild("Lixo_model") ~= nil
                        local targetFolder = hasBag and col:FindFirstChild("Lixeira") or col:FindFirstChild("Lixo")
                        local prompt = getPrompt(targetFolder)

                        if prompt and prompt.Parent then
                            prompt.HoldDuration = 0
                            repeat
                                if not logic.Enabled or hum.Health <= 0 then break end
                                if (char:FindFirstChild("Lixo_model") ~= nil) ~= hasBag then break end
                                
                                floatAt(prompt.Parent.CFrame * offset)
                                fireproximityprompt(prompt)
                                task.wait(0.3)
                            until not prompt.Parent or not prompt.Enabled
                        else
                            stopFloat()
                            task.wait(0.1)
                        end
                    else
                        stopFloat()
                        task.wait(0.5)
                    end
                elseif logic.Mode == "Barbeiro" then
                    local shop = ws:FindFirstChild("BarberShop")
                    local found = false
                    
                    if shop then
                        for _, npc in ipairs(shop:GetChildren()) do
                            if not logic.Enabled or hum.Health <= 0 then break end
                            local head = npc:FindFirstChild("Head")
                            local prompt = getPrompt(head)
                            
                            if prompt and prompt.Parent then
                                found = true
                                prompt.HoldDuration = 0
                                repeat
                                    if not logic.Enabled or hum.Health <= 0 then break end
                                    floatAt(prompt.Parent.CFrame * offset)
                                    fireproximityprompt(prompt)
                                    task.wait(0.3)
                                until not prompt.Parent or not prompt.Enabled
                            end
                        end
                    end
                    
                    if not found then
                        stopFloat()
                        task.wait(0.5)
                    end
                end
            else
                stopFloat()
                task.wait(0.5)
            end
        else
            stopFloat()
            task.wait(0.5)
        end
        if logic.Enabled then rs.Heartbeat:Wait() end
    end
end)

getgenv().NovaEraLogic = logic
