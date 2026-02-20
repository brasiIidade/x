local function f(m)print(m)task.wait(.5)local function c()return c()end c()end local r,cn=0,game:GetService("RunService").Heartbeat:Connect(function()r=r+1 end)repeat task.wait()until r>=2 cn:Disconnect()if not getmetatable or not setmetatable or not type or not select or type(select(2,pcall(getmetatable,setmetatable({},{__index=function()while 1 do end end})))['__index'])~='function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or({debug.info(print,'a')})[1]~=0 or({debug.info(tostring,'a')})[1]~=0 or({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1,pcall(getfenv,69))==true or not select(2,pcall(rawget,debug,"info")) or #(((select(2,pcall(rawget,debug,"info")))(getfenv,"n")))<=1 or #(((select(2,pcall(rawget,debug,"info")))(print,"n")))<=1 or not(select(2,pcall(rawget,debug,"info")))(print,"s")=="[C]" or not(select(2,pcall(rawget,debug,"info")))(require,"s")=="[C]" or(select(2,pcall(rawget,debug,"info")))((function()end),"s")=="[C]" or not select(1,pcall(debug.info,coroutine.wrap(function()end)(),'s'))==false then f("skid de EB :(")end if not game.ServiceAdded or getfenv()[Instance.new("Part")] or getmetatable(__call)then f("skid de EB :(")end if pcall(function()Instance.new("Part"):B("a")end)then f("skid de EB :(")end local s,res=pcall(function()return game:GetService("HttpService"):JSONDecode('[42,"",false,1,true,[1,"",null],null,["",1,true],{"k":1},[null,["",1,false]]]')end)if not s or res[6][3]~=nil then f("skid de EB :(")end local _,m=pcall(function()game()end)if not m:find("attempt to call a Instance value")or #game:GetChildren()<=4 then f("skid de EB :(")end
local lIlI = cloneref or function(a) return a end

local lIIl = lIlI(game:GetService("Players"))
local IllI = lIlI(game:GetService("Workspace"))
local IIll = lIlI(game:GetService("RunService"))
local lIlII = lIlI(lIIl.LocalPlayer)

local IlIlI = {}
IlIlI.Ill = false
IlIlI.lII = 0
IlIlI.IIl = 0
IlIlI.UpdateCallback = nil

local llIIl = CFrame.new(0, -9, 0)
local IIlIl = Vector3.zero
local lIllI = nil

local function IlIIl()
    local lI = lIlII:FindFirstChild("leaderstats")
    local Il = lI and lI:FindFirstChild("Dinheiro")
    if Il then
        local l = Il.Value or Il.Text
        return tonumber(l) or 0
    end
    return 0
end

local function lIIlI()
    local I = lIlII.Character
    if I then
        local l = I:FindFirstChild("HumanoidRootPart")
        if l then
            local i = l:FindFirstChild("Antigravity")
            if i then i:Destroy() end
        end
    end
end

local function IIllI(I)
    local l = lIlII.Character
    if l then
        local i = l:FindFirstChild("HumanoidRootPart")
        if i then
            if not i:FindFirstChild("Antigravity") then
                local L = Instance.new("BodyVelocity")
                L.Name = "Antigravity"
                L.Velocity = IIlIl
                L.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                L.P = 9000
                L.Parent = i
            end
            i.CFrame = I.CFrame * llIIl
            i.AssemblyLinearVelocity = IIlIl
            i.AssemblyAngularVelocity = IIlIl
        end
    end
end

local function llIll(I)
    if not I then return nil end
    for _, l in ipairs(I:GetDescendants()) do
        if l:IsA("ProximityPrompt") and l.Enabled and l.Parent and l.Parent:IsA("BasePart") then
            return l
        end
    end
    return nil
end

function IlIlI.Toggle(I)
    IlIlI.Ill = I
    local l = IlIIl()

    if I then
        IlIlI.IIl = l
        if lIlII.Character and lIlII.Character:FindFirstChild("HumanoidRootPart") then
            lIllI = lIlII.Character.HumanoidRootPart.CFrame
        end
    else
        lIIlI()
        IlIlI.lII = IlIlI.lII + (l - IlIlI.IIl)
        if lIllI and lIlII.Character and lIlII.Character:FindFirstChild("HumanoidRootPart") then
            lIlII.Character.HumanoidRootPart.CFrame = lIllI
            lIlII.Character.HumanoidRootPart.AssemblyLinearVelocity = IIlIl
        end
    end
end

task.spawn(function()
    while true do
        if IlIlI.Ill then
            if IlIlI.UpdateCallback then
                local I = IlIIl()
                local l = IlIlI.lII + (I - IlIlI.IIl)
                IlIlI.UpdateCallback(l)
            end
        elseif IlIlI.UpdateCallback then
            IlIlI.UpdateCallback(IlIlI.lII)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if IlIlI.Ill then
            local I = lIlII.Character
            if I and I:FindFirstChild("HumanoidRootPart") and I:FindFirstChild("Humanoid") and I.Humanoid.Health > 0 then
                local l = IllI:FindFirstChild("Trabalhos / SWATntj")
                local i = l and l:FindFirstChild("Coleta")
                
                if i then
                    local L = I:FindFirstChild("Lixo_model") ~= nil
                    local ll = L and i:FindFirstChild("Lixeira") or i:FindFirstChild("Lixo")
                    local lI = llIll(ll)

                    if lI and lI.Parent then
                        lI.HoldDuration = 0
                        repeat
                            if not IlIlI.Ill or I.Humanoid.Health <= 0 then break end
                            local Il = I:FindFirstChild("Lixo_model") ~= nil
                            if Il ~= L then break end
                            
                            IIllI(lI.Parent)
                            fireproximityprompt(lI)
                            task.wait(0.3)
                        until not lI.Parent or not lI.Enabled
                    else
                        IIll.Heartbeat:Wait()
                    end
                else
                    lIIlI()
                    task.wait(0.5)
                end
            else
                lIIlI()
                task.wait(0.5)
            end
        else
            lIIlI()
            task.wait(0.5)
        end
        if IlIlI.Ill then IIll.Heartbeat:Wait() end
    end
end)

_G.NovaEraLogic = IlIlI
