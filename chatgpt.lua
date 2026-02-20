local function f(m)print(m)task.wait(.5)local function c()return c()end c()end local r,cn=0,game:GetService("RunService").Heartbeat:Connect(function()r=r+1 end)repeat task.wait()until r>=2 cn:Disconnect()if not getmetatable or not setmetatable or not type or not select or type(select(2,pcall(getmetatable,setmetatable({},{__index=function()while 1 do end end})))['__index'])~='function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or({debug.info(print,'a')})[1]~=0 or({debug.info(tostring,'a')})[1]~=0 or({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1,pcall(getfenv,69))==true or not select(2,pcall(rawget,debug,"info")) or #(((select(2,pcall(rawget,debug,"info")))(getfenv,"n")))<=1 or #(((select(2,pcall(rawget,debug,"info")))(print,"n")))<=1 or not(select(2,pcall(rawget,debug,"info")))(print,"s")=="[C]" or not(select(2,pcall(rawget,debug,"info")))(require,"s")=="[C]" or(select(2,pcall(rawget,debug,"info")))((function()end),"s")=="[C]" or not select(1,pcall(debug.info,coroutine.wrap(function()end)(),'s'))==false then f("skid de EB :(")end if not game.ServiceAdded or getfenv()[Instance.new("Part")] or getmetatable(__call)then f("skid de EB :(")end if pcall(function()Instance.new("Part"):B("a")end)then f("skid de EB :(")end local s,res=pcall(function()return game:GetService("HttpService"):JSONDecode('[42,"",false,1,true,[1,"",null],null,["",1,true],{"k":1},[null,["",1,false]]]')end)if not s or res[6][3]~=nil then f("skid de EB :(")end local _,m=pcall(function()game()end)if not m:find("attempt to call a Instance value")or #game:GetChildren()<=4 then f("skid de EB :(")end
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
