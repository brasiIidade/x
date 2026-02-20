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
local PromptPath = "michigun.xyz/IA.txt"
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
