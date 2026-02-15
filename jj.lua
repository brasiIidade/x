-- anti

local function Finalizar(Mensagem)
    print(Mensagem)
    task.wait(0.5)
    local function Crash() return Crash() end
    Crash()
end

local RanTimes = 0
local Connection = game:GetService("RunService").Heartbeat:Connect(function()
    RanTimes = RanTimes + 1
end)

repeat
    task.wait()
until RanTimes >= 2

Connection:Disconnect()

if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or ({debug.info(print,'a')})[1]~=0 or ({debug.info(tostring,'a')})[1]~=0 or ({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" or not select(1, pcall(debug.info, coroutine.wrap(function() end)(), 's')) == false then
    Finalizar("skid de EB :(")
end

if not game.ServiceAdded then
    Finalizar("skid de EB :(")
end

if getfenv()[Instance.new("Part")] then
    Finalizar("skid de EB :(")
end

if getmetatable(__call) then
    Finalizar("skid de EB :(")
end

local Success = pcall(function()
    Instance.new("Part"):BananaPeelSlipper("a")
end)

if Success then
    Finalizar("skid de EB :(")
end

local Success, Result = pcall(function()
    return game:GetService("HttpService"):JSONDecode([=[
        [
            42,
            "deworming tablets",
            false,
            987,
            true,
            [555, "shimmer", null],
            null,
            ["x", 77, true],
            {"key": "value", "num": 101},
            [null, ["nested", 999, false]]
        ]
    ]=])
end)

if not Success then
    Finalizar("skid de EB :(")
end

if Result[6][3] ~= nil then
    Finalizar("skid de EB :(")
end

local _, Message = pcall(function()
    game()
end)

if not Message:find("attempt to call a Instance value") then
    Finalizar("skid de EB :(")
end

if #game:GetChildren() <= 4 then
    Finalizar("skid de EB :(")
end

local cloneref = cloneref or function(o) return o end

local TextChatService = cloneref(game:GetService("TextChatService"))
local Replicated = cloneref(game:GetService("ReplicatedStorage"))
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"))
local Players = cloneref(game:GetService("Players"))

local Player = cloneref(Players.LocalPlayer)


_G.JJs = _G.JJs or {}
_G.JJs.Config = {
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
_G.JJs.StatusFunc = nil

local DELTA_MAPA = (game.PlaceId == 14511049) -- Replace with actual ID if known, or rely on game specific object checks
local TEVEZ_MAPA = (game.PlaceId == 13132367906) -- Replace with actual ID if known

-- Helper: Remote Chat
local RemoteChat = {}
function RemoteChat:Send(Message)
    task.spawn(function()
        local msgString = tostring(Message)
        local sent = false
        local channelsFolder = TextChatService:FindFirstChild("TextChannels")

        if channelsFolder then
            local inputConfig = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
            if inputConfig and inputConfig.TargetTextChannel then
                pcall(function() inputConfig.TargetTextChannel:SendAsync(msgString) sent = true end)
            end
            if not sent then
                local general = channelsFolder:FindFirstChild("RBXGeneral")
                if general then pcall(function() general:SendAsync(msgString) sent = true end) end
            end
            if not sent then
                local anyChannel = channelsFolder:FindFirstChildOfClass("TextChannel")
                if anyChannel then pcall(function() anyChannel:SendAsync(msgString) sent = true end) end
            end
        end

        if not sent then
            local chatEvents = Replicated:FindFirstChild("DefaultChatSystemChatEvents")
            local sayMsg = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
            if sayMsg then pcall(function() sayMsg:FireServer(msgString, "All") end) end
        end
    end)
end

-- Helper: Character
local CharacterWrapper = {}
CharacterWrapper.__index = CharacterWrapper

function CharacterWrapper.new(Plr)
    local self = setmetatable({}, CharacterWrapper)
    self.Player = Plr
    self.Character = Plr.Character or Plr.CharacterAdded:Wait()
    self.Humanoid = self.Character:WaitForChild("Humanoid", 10)
    self.Root = self.Character:WaitForChild("HumanoidRootPart", 10)
    
    Plr.CharacterAdded:Connect(function(Char)
        self.Character = Char
        self.Humanoid = Char:WaitForChild("Humanoid", 10)
        self.Root = Char:WaitForChild("HumanoidRootPart", 10)
    end)
    return self
end

function CharacterWrapper:Jump()
    if not self.Humanoid then return end
    local state = self.Humanoid:GetState()
    if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed then
        pcall(function() self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end

local Char = CharacterWrapper.new(Player)

-- Helper: Number to Words (Portuguese)
local accentMap = {["á"]="Á",["à"]="À",["ã"]="Ã",["â"]="Â",["é"]="É",["ê"]="Ê",["í"]="Í",["ó"]="Ó",["ô"]="Ô",["õ"]="Õ",["ú"]="Ú",["ç"]="Ç"}
local function unicodeUpper(str)
    local out = {}
    for _,c in utf8.codes(str) do
        local ch = utf8.char(c)
        out[#out+1] = accentMap[ch] or string.upper(ch)
    end
    return table.concat(out)
end

local units = {[0]="zero",[1]="um",[2]="dois",[3]="três",[4]="quatro",[5]="cinco",[6]="seis",[7]="sete",[8]="oito",[9]="nove",[10]="dez",[11]="onze",[12]="doze",[13]="treze",[14]="quatorze",[15]="quinze",[16]="dezesseis",[17]="dezessete",[18]="dezoito",[19]="dezenove"}
local tens = {[2]="vinte",[3]="trinta",[4]="quarenta",[5]="cinquenta",[6]="sessenta",[7]="setenta",[8]="oitenta",[9]="noventa"}
local hundreds = {[1]="cento",[2]="duzentos",[3]="trezentos",[4]="quatrocentos",[5]="quinhentos",[6]="seiscentos",[7]="setecentos",[8]="oitocentos",[9]="novecentos"}
local scales_s = {[1]="mil",[2]="milhão",[3]="bilhão"}
local scales_p = {[1]="mil",[2]="milhões",[3]="bilhões"}

local function threeDigitToWords(n)
    if n == 0 then return "" end
    if n == 100 then return "cem" end
    local h = math.floor(n / 100)
    local rest = n % 100
    local parts = {}
    if h > 0 then table.insert(parts, hundreds[h]) end
    if rest < 20 then
        if rest > 0 then table.insert(parts, units[rest]) end
    else
        table.insert(parts, tens[math.floor(rest/10)])
        local u = rest % 10
        if u > 0 then table.insert(parts, units[u]) end
    end
    return table.concat(parts, " e ")
end

local function numberToWords(num)
    num = tonumber(num)
    if not num then return "NÚMERO INVÁLIDO" end
    if num == 0 then return "ZERO" end
    local groups = {}
    while num > 0 do table.insert(groups, num % 1000); num = math.floor(num / 1000) end
    local parts = {}
    for i = #groups,1,-1 do
        local val = groups[i]
        if val ~= 0 then
            local text = threeDigitToWords(val)
            if i > 1 then
                local scale = (val==1) and scales_s[i-1] or scales_p[i-1]
                text = (i==2 and val==1) and "mil" or text.." "..scale
            end
            table.insert(parts, text)
        end
    end
    return unicodeUpper(table.concat(parts, " e "))
end

-- Main Logic Function
_G.JJs.Start = function()
    local Config = _G.JJs.Config
    Config.Running = true

    task.spawn(function()
        local deltaTrack = nil
        
        -- Delta Setup
        if Config.Mode == "JJ (Delta)" then
            local deltaAnim = Instance.new("Animation")
            deltaAnim.AnimationId = "rbxassetid://105471471504794"
            if Char and Char.Humanoid then
                deltaTrack = Char.Humanoid:LoadAnimation(deltaAnim)
                deltaTrack.Priority = Enum.AnimationPriority.Action
            end
            local remote = Replicated:WaitForChild("Remotes", 5) and Replicated.Remotes:WaitForChild("Polichinelos", 5)
            if remote then remote:FireServer("Prepare"); remote:FireServer("Start") end
        end

        local i, limit, step = Config.StartValue, Config.EndValue, 1
        if Config.ReverseEnabled then
            i, limit, step = Config.EndValue, Config.StartValue, -1
        end

        local totalJJ = math.abs(Config.EndValue - Config.StartValue) + 1
        local forcedDelay = Config.FinishInTime and (Config.FinishTotalTime / totalJJ) or nil
        local executed = 0

        for num = i, limit, step do
            if not Config.Running then break end

            executed = executed + 1
            local remaining = totalJJ - executed
            local timeRemaining = 0
            
            if Config.FinishInTime then
                timeRemaining = Config.FinishTotalTime - (executed * forcedDelay)
            else
                local avgDelay = Config.RandomDelay and ((Config.RandomMin + Config.RandomMax) / 2) or Config.DelayValue
                timeRemaining = remaining * avgDelay
            end

            -- Update UI Status
            if _G.JJs.StatusFunc then
                _G.JJs.StatusFunc(remaining, timeRemaining)
            end

            -- Action Logic
            if Config.Mode == "JJ (Delta)" then
                local remote = Replicated:WaitForChild("Remotes", 5) and Replicated.Remotes:WaitForChild("Polichinelos", 5)
                if remote then remote:FireServer("Add", 1) end
                if deltaTrack then deltaTrack:Play() end
            
            elseif Config.Mode == "Canguru" then
                local word = numberToWords(num)
                local finalSuffix = (Config.CustomSuffix ~= "" and Config.CustomSuffix) or Config.Suffix
                local msg = Config.SpacingEnabled and (word .. " " .. finalSuffix) or (word .. finalSuffix)
                
                RemoteChat:Send(msg)
                task.wait(0.2)

                -- Canguru sequence
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game); task.wait()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game); task.wait(0.2)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, game); task.wait()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, game); task.wait(0.1)

                Char:Jump()
                task.wait(0.2)

                -- Spin logic
                if Char.Root and Char.Humanoid then
                    Char.Humanoid.AutoRotate = false
                    local rotValue = Instance.new("NumberValue")
                    rotValue.Value = 0
                    local targetAngle = math.random(355, 365) * ((math.random(1, 2) == 1) and 1 or -1)
                    local tween = TweenService:Create(rotValue, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Value = targetAngle})
                    local startRot = Char.Root.CFrame.Rotation
                    local conn; conn = RunService.Heartbeat:Connect(function()
                        if Char.Root then Char.Root.CFrame = CFrame.new(Char.Root.Position) * startRot * CFrame.Angles(0, math.rad(rotValue.Value), 0) end
                    end)
                    tween.Completed:Connect(function() conn:Disconnect(); rotValue:Destroy(); Char.Humanoid.AutoRotate = true end)
                    tween:Play()
                end
                task.wait(0.1)

            else -- Standard
                local word = numberToWords(num)
                local finalSuffix = (Config.CustomSuffix ~= "" and Config.CustomSuffix) or Config.Suffix
                local msg = Config.SpacingEnabled and (word .. " " .. finalSuffix) or (word .. finalSuffix)
                
                RemoteChat:Send(msg)
                if Config.JumpEnabled then Char:Jump() end
            end

            -- Delay Logic
            if Config.FinishInTime and forcedDelay then
                task.wait(forcedDelay)
            else
                if Config.RandomDelay then
                    task.wait(Config.RandomMin + (math.random() * (Config.RandomMax - Config.RandomMin)))
                else
                    task.wait(Config.DelayValue)
                end
            end
        end
        
        -- Finish
        if _G.JJs.StatusFunc then _G.JJs.StatusFunc(0, 0) end
        Config.Running = false
    end)
end

_G.JJs.Stop = function()
    _G.JJs.Config.Running = false
    if _G.JJs.StatusFunc then _G.JJs.StatusFunc(0, 0) end
end
