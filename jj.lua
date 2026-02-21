local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local rs = cr(game:GetService("RunService"))
local rep = cr(game:GetService("ReplicatedStorage"))
local tcs = cr(game:GetService("TextChatService"))
local vim = cr(game:GetService("VirtualInputManager"))
local ts = cr(game:GetService("TweenService"))
local lp = cr(plrs.LocalPlayer)

local env = getgenv()
env.JJs = env.JJs or {}
_G.JJs = env.JJs 

local jjs = env.JJs
jjs.Config = jjs.Config or {
    Running = false,
    StartValue = 1,
    EndValue = 100,
    DelayValue = 1.5,
    RandomDelay = false,
    RandomMin = 1,
    RandomMax = 3,
    JumpEnabled = false,
    SpacingEnabled = false,
    ReverseEnabled = false,
    FinishInTime = false,
    FinishTotalTime = 60,
    Suffix = "!",
    CustomSuffix = "",
    Mode = "Padrão"
}

jjs.State = {
    Running = false,
    Current = 0,
    Total = 0,
    FinishTimestamp = 0
}

local u = {[0]="zero",[1]="um",[2]="dois",[3]="três",[4]="quatro",[5]="cinco",[6]="seis",[7]="sete",[8]="oito",[9]="nove",[10]="dez",[11]="onze",[12]="doze",[13]="treze",[14]="quatorze",[15]="quinze",[16]="dezesseis",[17]="dezessete",[18]="dezoito",[19]="dezenove"}
local t = {[2]="vinte",[3]="trinta",[4]="quarenta",[5]="cinquenta",[6]="sessenta",[7]="setenta",[8]="oitenta",[9]="noventa"}
local h = {[1]="cento",[2]="duzentos",[3]="trezentos",[4]="quatrocentos",[5]="quinhentos",[6]="seiscentos",[7]="setecentos",[8]="oitocentos",[9]="novecentos"}
local ac = {["á"]="Á",["à"]="À",["ã"]="Ã",["â"]="Â",["é"]="É",["ê"]="Ê",["í"]="Í",["ó"]="Ó",["ô"]="Ô",["õ"]="Õ",["ú"]="Ú",["ç"]="Ç"}

local function up(s)
    local r = ""
    for _, c in utf8.codes(s) do
        local ch = utf8.char(c)
        r = r .. (ac[ch] or string.upper(ch))
    end
    return r
end

local function ph(n)
    if n == 0 then
        return ""
    end
    if n == 100 then
        return "cem"
    end
    local hv = math.floor(n / 100)
    local rv = n % 100
    local p = {}
    if hv > 0 then
        table.insert(p, h[hv])
    end
    if rv > 0 then
        if #p > 0 then
            table.insert(p, "e")
        end
        if rv < 20 then
            table.insert(p, u[rv])
        else
            table.insert(p, t[math.floor(rv/10)])
            local uv = rv % 10
            if uv > 0 then 
                table.insert(p, "e")
                table.insert(p, u[uv]) 
            end
        end
    end
    return table.concat(p, " ")
end

local function nt(n)
    n = tonumber(n)
    if not n then
        return "N/A"
    end
    if n == 0 then
        return "ZERO"
    end
    local g = {}
    local temp = n
    while temp > 0 do
        table.insert(g, temp % 1000)
        temp = math.floor(temp / 1000)
    end
    local x = {}
    for i = #g, 1, -1 do
        local v = g[i]
        if v ~= 0 then
            local txt = ph(v)
            if i == 2 then
                if v == 1 then
                    txt = "mil"
                else
                    txt = txt .. " mil"
                end
            end
            if i == 3 then
                if v == 1 then
                    txt = "um milhão"
                else
                    txt = txt .. " milhões"
                end
            end
            if i == 4 then
                if v == 1 then
                    txt = "um bilhão"
                else
                    txt = txt .. " bilhões"
                end
            end
            if i == 5 then
                if v == 1 then
                    txt = "um trilhão"
                else
                    txt = txt .. " trilhões"
                end
            end
            table.insert(x, txt)
        end
    end
    return up(table.concat(x, " e "))
end

local function sc(m)
    task.spawn(function()
        local s = tostring(m)
        local done = false
        if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
             local c = tcs:FindFirstChild("TextChannels")
             local tgt = c and c:FindFirstChild("RBXGeneral")
             if tgt then
                 pcall(function()
                     tgt:SendAsync(s)
                 end)
                 done = true
             end
        end
        if not done then
            local ev = rep:FindFirstChild("DefaultChatSystemChatEvents")
            local req = ev and ev:FindFirstChild("SayMessageRequest")
            if req then
                pcall(function()
                    req:FireServer(s, "All")
                end)
            end
        end
    end)
end

local function gc()
    local c = lp.Character
    if c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart") then
        return c
    end
    return nil
end

local function aj()
    local c = gc()
    if c then
        local h = c.Humanoid
        if h:GetState() ~= Enum.HumanoidStateType.Jumping and h:GetState() ~= Enum.HumanoidStateType.Freefall then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function as()
    local c = gc()
    if not c then
        return
    end
    local h = c.Humanoid
    local r = c.HumanoidRootPart
    h.AutoRotate = false
    local nv = Instance.new("NumberValue")
    local tw = ts:Create(nv, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Value = 360 * (math.random(1,2)==1 and 1 or -1)})
    local b = r.CFrame.Rotation
    local cn
    cn = rs.Heartbeat:Connect(function()
        if r and r.Parent then
            r.CFrame = CFrame.new(r.Position) * b * CFrame.Angles(0, math.rad(nv.Value), 0)
        else
            cn:Disconnect()
        end
    end)
    tw.Completed:Connect(function()
        cn:Disconnect()
        nv:Destroy()
        if h then
            h.AutoRotate = true
        end
    end)
    tw:Play()
end

jjs.Start = function()
    local c = jjs.Config
    if c.Running then
        return
    end
    c.Running = true
    
    task.spawn(function()
        local startVal = tonumber(c.StartValue) or 1
        local endVal = tonumber(c.EndValue) or 100
        local s = startVal
        local e = endVal
        local dir = 1
        
        if c.ReverseEnabled then 
            s = endVal
            e = startVal
            dir = -1 
        else
            if s > e then
                dir = -1
            end
        end
        
        local currentMode = c.Mode
        if currentMode == "Padrão" then
            local remotes = rep:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("Polichinelos") then
                currentMode = "JJ (Delta)"
            end
        end
        
        local tot = math.abs(e - s) + 1
        local cnt = 0
        local ft = nil
        if c.FinishInTime then
            ft = c.FinishTotalTime / math.max(1, tot)
        end
        
        jjs.State.Running = true
        jjs.State.Total = tot
        
        local dt = nil
        if currentMode == "JJ (Delta)" then
            local ch = gc()
            if ch then
                local a = Instance.new("Animation")
                a.AnimationId = "rbxassetid://105471471504794"
                dt = ch.Humanoid:LoadAnimation(a)
                dt.Priority = Enum.AnimationPriority.Action
            end
            local rm = rep:FindFirstChild("Remotes")
            local poli = rm and rm:FindFirstChild("Polichinelos")
            if poli then
                pcall(function()
                    poli:FireServer("Prepare")
                    poli:FireServer("Start")
                end)
            end
        end

        for i = s, e, dir do
            if not c.Running then
                break
            end
            cnt = cnt + 1
            
            jjs.State.Current = i
            local rem = tot - cnt
            local delay = ft or c.DelayValue
            if not ft and c.RandomDelay then
                delay = c.RandomMin + math.random() * (c.RandomMax - c.RandomMin)
            end
            
            local timeLeft = rem * delay
            jjs.State.FinishTimestamp = tick() + timeLeft + delay
            
            local txt = nt(i)
            local sf = c.Suffix
            if c.CustomSuffix ~= "" then
                sf = c.CustomSuffix
            end
            
            local fn = txt .. sf
            if c.SpacingEnabled then
                fn = txt .. " " .. sf
            end
            
            if currentMode == "JJ (Delta)" then
                local rm = rep:FindFirstChild("Remotes")
                local poli = rm and rm:FindFirstChild("Polichinelos")
                if poli then
                    pcall(function()
                        poli:FireServer("Add", 1)
                    end)
                end
                if dt then
                    dt:Play()
                end
            elseif currentMode == "Canguru" then
                sc(fn)
                task.wait(0.2)
                pcall(function()
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task.wait()
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                    task.wait(0.2)
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                    task.wait()
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                end)
                task.wait(0.1)
                aj()
                task.wait(0.2)
                as()
            else 
                sc(fn)
                if c.JumpEnabled then
                    aj()
                end
            end
            
            if i ~= e then
                task.wait(delay)
            end
        end
        
        c.Running = false
        jjs.State.Running = false
        if dt then
            dt:Stop()
        end
    end)
end

jjs.Stop = function()
    jjs.Config.Running = false
    jjs.State.Running = false
end
