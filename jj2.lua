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
jjs.StatusFunc = nil

local units = {[0]="zero",[1]="um",[2]="dois",[3]="três",[4]="quatro",[5]="cinco",[6]="seis",[7]="sete",[8]="oito",[9]="nove",[10]="dez",[11]="onze",[12]="doze",[13]="treze",[14]="quatorze",[15]="quinze",[16]="dezesseis",[17]="dezessete",[18]="dezoito",[19]="dezenove"}
local tens = {[2]="vinte",[3]="trinta",[4]="quarenta",[5]="cinquenta",[6]="sessenta",[7]="setenta",[8]="oitenta",[9]="noventa"}
local hundreds = {[1]="cento",[2]="duzentos",[3]="trezentos",[4]="quatrocentos",[5]="quinhentos",[6]="seiscentos",[7]="setecentos",[8]="oitocentos",[9]="novecentos"}
local accents = {["á"]="Á",["à"]="À",["ã"]="Ã",["â"]="Â",["é"]="É",["ê"]="Ê",["í"]="Í",["ó"]="Ó",["ô"]="Ô",["õ"]="Õ",["ú"]="Ú",["ç"]="Ç"}

local function toUpper(s)
    local res = {}
    for _, c in utf8.codes(s) do
        local ch = utf8.char(c)
        res[#res+1] = accents[ch] or string.upper(ch)
    end
    return table.concat(res)
end

local function parseHundreds(n)
    if n == 0 then return "" end
    if n == 100 then return "cem" end
    local h = math.floor(n / 100)
    local r = n % 100
    local p = {}
    if h > 0 then table.insert(p, hundreds[h]) end
    if r > 0 then
        if r < 20 then
            table.insert(p, units[r])
        else
            table.insert(p, tens[math.floor(r/10)])
            local u = r % 10
            if u > 0 then table.insert(p, units[u]) end
        end
    end
    return table.concat(p, " e ")
end

local function numToText(n)
    n = tonumber(n)
    if not n then return "N/A" end
    if n == 0 then return "ZERO" end
    local grps = {}
    while n > 0 do table.insert(grps, n % 1000) n = math.floor(n / 1000) end
    local txt = {}
    for i = #grps, 1, -1 do
        local v = grps[i]
        if v ~= 0 then
            local t = parseHundreds(v)
            if i == 2 then t = (v == 1 and "mil" or t .. " mil") end
            if i == 3 then t = (v == 1 and "um milhão" or t .. " milhões") end
            table.insert(txt, t)
        end
    end
    return toUpper(table.concat(txt, " e "))
end

local function sendChat(msg)
    task.spawn(function()
        local s = tostring(msg)
        local tcs_active = false
        
        if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
             local ch = tcs:FindFirstChildOfClass("TextChannels")
             if ch then
                 local target = tcs:FindFirstChildOfClass("ChatInputBarConfiguration")
                 target = target and target.TargetTextChannel or ch:FindFirstChild("RBXGeneral")
                 if target then pcall(function() target:SendAsync(s) end) tcs_active = true end
             end
        end
        
        if not tcs_active then
            local ev = rep:FindFirstChild("DefaultChatSystemChatEvents")
            local say = ev and ev:FindFirstChild("SayMessageRequest")
            if say then pcall(function() say:FireServer(s, "All") end) end
        end
    end)
end

local function getChar()
    local c = lp.Character
    if c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart") then return c end
    return nil
end

local function actJump()
    local c = getChar()
    if c then
        local h = c.Humanoid
        if h:GetState() ~= Enum.HumanoidStateType.Jumping and h:GetState() ~= Enum.HumanoidStateType.Freefall then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

local function actSpin()
    local c = getChar()
    if not c then return end
    local h, r = c.Humanoid, c.HumanoidRootPart
    h.AutoRotate = false
    local nv = Instance.new("NumberValue")
    local t = ts:Create(nv, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Value = 360 * (math.random(1,2)==1 and 1 or -1)})
    local base = r.CFrame.Rotation
    local cn; cn = rs.Heartbeat:Connect(function()
        if r and r.Parent then r.CFrame = CFrame.new(r.Position) * base * CFrame.Angles(0, math.rad(nv.Value), 0) else cn:Disconnect() end
    end)
    t.Completed:Connect(function() cn:Disconnect() nv:Destroy() if h then h.AutoRotate = true end end)
    t:Play()
end

jjs.Start = function()
    local c = jjs.Config
    if c.Running then return end
    c.Running = true
    
    task.spawn(function()
        local s, e, dir = c.StartValue, c.EndValue, 1
        if c.ReverseEnabled then s, e, dir = c.EndValue, c.StartValue, -1 end
        
        local total = math.abs(e - s) + 1
        local count = 0
        local forcedTime = c.FinishInTime and (c.FinishTotalTime / math.max(1, total)) or nil
        
        local dTrack = nil
        if c.Mode == "JJ (Delta)" then
            local ch = getChar()
            if ch then
                local ani = Instance.new("Animation")
                ani.AnimationId = "rbxassetid://105471471504794"
                dTrack = ch.Humanoid:LoadAnimation(ani)
                dTrack.Priority = Enum.AnimationPriority.Action
            end
            local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
            if rm then pcall(function() rm:FireServer("Prepare") rm:FireServer("Start") end) end
        end

        for i = s, e, dir do
            if not c.Running then break end
            count = count + 1
            
            if jjs.StatusFunc then
                local rem = total - count
                local timeL = 0
                if forcedTime then
                    timeL = rem * forcedTime
                else
                    local avg = c.RandomDelay and ((c.RandomMin + c.RandomMax)/2) or c.DelayValue
                    timeL = rem * avg
                end
                jjs.StatusFunc(rem, timeL)
            end
            
            local txt = numToText(i)
            local suf = (c.CustomSuffix ~= "" and c.CustomSuffix) or c.Suffix
            local final = c.SpacingEnabled and (txt .. " " .. suf) or (txt .. suf)
            
            if c.Mode == "JJ (Delta)" then
                local rm = rep:FindFirstChild("Remotes") and rep.Remotes:FindFirstChild("Polichinelos")
                if rm then pcall(function() rm:FireServer("Add", 1) end) end
                if dTrack then dTrack:Play() end
                
            elseif c.Mode == "Canguru" then
                sendChat(final)
                task.wait(0.2)
                pcall(function()
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait()
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game) task.wait(0.2)
                    vim:SendKeyEvent(true, Enum.KeyCode.C, false, game) task.wait()
                    vim:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                end)
                task.wait(0.1)
                actJump()
                task.wait(0.2)
                actSpin()
                
            else
                sendChat(final)
                if c.JumpEnabled then actJump() end
            end
            
            if forcedTime then
                task.wait(forcedTime)
            elseif c.RandomDelay then
                task.wait(c.RandomMin + math.random() * (c.RandomMax - c.RandomMin))
            else
                task.wait(c.DelayValue)
            end
        end
        
        c.Running = false
        if jjs.StatusFunc then jjs.StatusFunc(0, 0) end
        if dTrack then dTrack:Stop() end
    end)
end

jjs.Stop = function()
    jjs.Config.Running = false
    if jjs.StatusFunc then jjs.StatusFunc(0, 0) end
end
