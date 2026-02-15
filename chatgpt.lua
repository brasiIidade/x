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

local cloneref = cloneref or function(obj) return obj end

local HttpService = cloneref(game:GetService("HttpService"))
local TextChatService = cloneref(game:GetService("TextChatService"))
local Replicated = cloneref(game:GetService("ReplicatedStorage"))
local Players = cloneref(game:GetService("Players"))

local HttpRequest = request or http and http.request or http_request or syn and syn.request

_G.ChatGPT = _G.ChatGPT or {}
_G.ChatGPT.History = {}
_G.ChatGPT.LastMessage = ""

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
local PromptPath = "michigun.xyz/fp3_ChatGPT.txt"
if not isfile(PromptPath) then writefile(PromptPath, "Você é uma IA útil dentro do Roblox.") end

local Personality = readfile(PromptPath)
_G.ChatGPT.History = {{role = "system", content = Personality}}

local function extractLuaCode(responseText)
    local luaCode = responseText:match("```lua\n?(.-)```") or responseText:match("```\n?(.-)```")
    if luaCode then
        local cleanText = responseText:gsub("```lua\n?.-```", ""):gsub("```\n?.-```", "")
        return luaCode, cleanText
    end
    return nil, responseText
end

_G.ChatGPT.Ask = function(promptText)
    table.insert(_G.ChatGPT.History, {role = "user", content = promptText})

    local success, response = pcall(function()
        return HttpRequest({
            Url = "https://text.pollinations.ai/openai",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                messages = _G.ChatGPT.History,
                model = "openai"
            })
        })
    end)

    if not success or not response then
        return "Erro de conexão com a API.", nil
    end

    local aiText = ""
    local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(response.Body) end)
    
    if decodeSuccess and decoded.choices and decoded.choices[1] then
        aiText = decoded.choices[1].message.content
    else
        aiText = response.Body
    end

    local luaCode, cleanMessage = extractLuaCode(aiText)

    _G.ChatGPT.LastMessage = cleanMessage
    table.insert(_G.ChatGPT.History, {role = "assistant", content = aiText})

    return cleanMessage, luaCode
end

_G.ChatGPT.SendToChat = function(msg)
    if not msg or msg == "" then return end
    
    local msgString = tostring(msg)
    
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channels = TextChatService:WaitForChild("TextChannels", 2)
        if channels then
            local target = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildOfClass("TextChannel")
            if target then
                target:SendAsync(msgString)
            end
        end
    else
        local events = Replicated:FindFirstChild("DefaultChatSystemChatEvents")
        if events then
            local say = events:FindFirstChild("SayMessageRequest")
            if say then
                say:FireServer(msgString, "All")
            end
        end
    end
end
