local function f(m)print(m)task.wait(.5)local function c()return c()end c()end local r,cn=0,game:GetService("RunService").Heartbeat:Connect(function()r=r+1 end)repeat task.wait()until r>=2 cn:Disconnect()if not getmetatable or not setmetatable or not type or not select or type(select(2,pcall(getmetatable,setmetatable({},{__index=function()while 1 do end end})))['__index'])~='function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or({debug.info(print,'a')})[1]~=0 or({debug.info(tostring,'a')})[1]~=0 or({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1,pcall(getfenv,69))==true or not select(2,pcall(rawget,debug,"info")) or #(((select(2,pcall(rawget,debug,"info")))(getfenv,"n")))<=1 or #(((select(2,pcall(rawget,debug,"info")))(print,"n")))<=1 or not(select(2,pcall(rawget,debug,"info")))(print,"s")=="[C]" or not(select(2,pcall(rawget,debug,"info")))(require,"s")=="[C]" or(select(2,pcall(rawget,debug,"info")))((function()end),"s")=="[C]" or not select(1,pcall(debug.info,coroutine.wrap(function()end)(),'s'))==false then f("skid de EB :(")end if not game.ServiceAdded or getfenv()[Instance.new("Part")] or getmetatable(__call)then f("skid de EB :(")end if pcall(function()Instance.new("Part"):B("a")end)then f("skid de EB :(")end local s,res=pcall(function()return game:GetService("HttpService"):JSONDecode('[42,"",false,1,true,[1,"",null],null,["",1,true],{"k":1},[null,["",1,false]]]')end)if not s or res[6][3]~=nil then f("skid de EB :(")end local _,m=pcall(function()game()end)if not m:find("attempt to call a Instance value")or #game:GetChildren()<=4 then f("skid de EB :(")end

local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
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
    local r = {}
    for _, c in utf8.codes(s) do
        local ch = utf8.char(c)
        r[#r+1] = ac[ch] or string.upper(ch)
    end
    return table.concat(r)
end

local function ph(n)
    if n == 0 then return "" end
    if n == 100 then return "cem" end
    local hv = math.floor(n / 100)
    local rv = n % 100
    local p = {}
    if hv > 0 then table.insert(p, h[hv]) end
    if rv > 0 then
        if rv < 20 then
            table.insert(p, u[rv])
        else
            table.insert(p, t[math.floor(rv/10)])
            local uv = rv % 10
            if uv > 0 then table.insert(p, u[uv]) end
        end
    end
    return table.concat(p, " e ")
end

local function nt(n)
    n = tonumber(n)
    if not n then return "N/A" end
    if n == 0 then return "ZERO" end
    local g = {}
    while n > 0 do table.insert(g, n % 1000) n = math.floor(n / 1000) end
    local x = {}
    for i = #g, 1, -1 do
        local v = g[i]
        if v ~= 0 then
            local txt = ph(v)
            if i == 2 then txt = (v == 1 and "mil" or txt .. " mil") end
            if i == 3 then txt = (v == 1 and "um milhão" or txt .. " milhões") end
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
             local c = tcs:FindFirstChildOfClass("TextChannels")
             if c then
                 local tgt = tcs:FindFirstChildOfClass("ChatInputBarConfiguration")
                 tgt = tgt and tgt.TargetTextChannel or c:FindFirstChild("RBXGeneral")
                 if tgt then pcall(function() tgt:SendAsync(s) end) done = true end
             end
        end
        if not done then
            local ev = rep:FindFirstChild("DefaultChatSystemChatEvents")
            local req = ev and ev:FindFirstChild("SayMessageRequest")
            if req then pcall(function() req:FireServer(s, "All") end) end
        end
    end)
end

local function gc()
    local c = lp.Character
    return (c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart")) and c or nil
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
    if not c then return end
    local h, r = c.Humanoid, c.HumanoidRootPart
    h.AutoRotate = false
    local nv = Instance.new("NumberValue")
    local tw = ts:Create(nv, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Value = 360 * (math.random(1,2)==1 and 1 or -1)})
    local b = r.CFrame.Rotation
    local cn; cn = rs.Heartbeat:Connect(function()
        if r and r.Parent then r.CFrame = CFrame.new(r.Position) * b * CFrame.Angles(0, math.rad(nv.Value), 0) else cn:Disconnect() end
    end)
    tw.Completed:Connect(function() cn:Disconnect() nv:Destroy() if h then h.AutoRotate = true end end)
    tw:Play()
end

jjs.Start = function()
    local c = jjs.Config
    if c.Running then return end
    c.Running = true
    
    task.spawn(function()
        local s, e, dir = c.StartValue, c.EndValue, 1
        if c.ReverseEnabled then s, e, dir = c.EndValue, c.StartValue, -1 end
        
        local tot = math.abs(e - s) + 1
        local cnt = 0
        local ft = c.FinishInTime and (c.FinishTotalTime / math.max(1, tot)) or nil
        
        jjs.State.Running = true
        jjs.State.Total = tot
        jjs.State.Current = 0
        
        local dt = nil
        if c.Mode == "JJ (Delta)" then
            local ch = gc()
            if ch then
                local a = Instance.new("Animation")
                a.AnimationId = "rbxassetid://105471471504794"
                dt = ch.Humanoid:LoadAnimation(a)
                dt.Priority = Enum.AnimationPriority.Action
            end
            local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
            if rm then pcall(function() rm:FireServer("Prepare") rm:FireServer("Start") end) end
        end

        for i = s, e, dir do
            if not c.Running then break end
            cnt = cnt + 1
            
            jjs.State.Current = i
            local rem = tot - cnt
            local delay = ft or (c.RandomDelay and (c.RandomMin + math.random() * (c.RandomMax - c.RandomMin)) or c.DelayValue)
            local timeLeft = rem * delay
            jjs.State.FinishTimestamp = tick() + timeLeft + delay
            
            local txt = nt(i)
            local sf = (c.CustomSuffix ~= "" and c.CustomSuffix) or c.Suffix
            local fn = c.SpacingEnabled and (txt .. " " .. sf) or (txt .. sf)
            
            if c.Mode == "JJ (Delta)" then
                local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
                if rm then pcall(function() rm:FireServer("Add", 1) end) end
                if dt then dt:Play() end
                
            elseif c.Mode == "Canguru" then
                sc(fn)
                task.wait(0.2)
                pcall(function()
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait()
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game) task.wait(0.2)
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait()
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                end)
                task.wait(0.1)
                aj()
                task.wait(0.2)
                as()
                
            else 
                sc(fn)
                if c.JumpEnabled then aj() end
            end
            
            task.wait(delay)
        end
        
        c.Running = false
        jjs.State.Running = false
        if dt then dt:Stop() end
    end)
end

jjs.Stop = function()
    jjs.Config.Running = false
    jjs.State.Running = false
end
