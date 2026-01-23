local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local Replicated = game:GetService("ReplicatedStorage")

local HttpRequest = request or http and http.request or http_request or syn and syn.request

_G.ChatGPT = _G.ChatGPT or {}
_G.ChatGPT.History = {}
_G.ChatGPT.LastMessage = ""

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
local PromptPath = "michigun.xyz/fp3_ChatGPT.txt"
if not isfile(PromptPath) then writefile(PromptPath, "Tudo que você colocar aqui será usado como prompt") end

local Personality = readfile(PromptPath)

_G.ChatGPT.History = {{role = "system", content = Personality}}

local function extractLuaCode(responseText)
    local luaCode = responseText:match("```lua(.-)```")
    if luaCode then
        local cleanText = responseText:gsub("```lua.-```", "")
        return luaCode, cleanText
    end
    return nil, responseText
end

_G.ChatGPT.Ask = function(promptText)
    table.insert(_G.ChatGPT.History, {role = "user", content = promptText})

    local response = HttpRequest({
        Url = "https://text.pollinations.ai/openai",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({messages = _G.ChatGPT.History})
    })

    local decoded = HttpService:JSONDecode(response.Body)
    local aiText = decoded.choices[1].message.content or ""
    local luaCode, cleanMessage = extractLuaCode(aiText)

    _G.ChatGPT.LastMessage = cleanMessage
    table.insert(_G.ChatGPT.History, {role = "assistant", content = cleanMessage})

    return cleanMessage, luaCode
end

_G.ChatGPT.SendToChat = function(msg)
    if not msg or msg == "" then return end
    task.spawn(function()
        local msgString = tostring(msg)
        local sent = false
        local channels = TextChatService:FindFirstChild("TextChannels")
        if channels then
            local input = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
            if input and input.TargetTextChannel then
                pcall(function() input.TargetTextChannel:SendAsync(msgString) sent = true end)
            end
            if not sent then
                local gen = channels:FindFirstChild("RBXGeneral")
                if gen then pcall(function() gen:SendAsync(msgString) sent = true end) end
            end
            if not sent then
                local any = channels:FindFirstChildOfClass("TextChannel")
                if any then pcall(function() any:SendAsync(msgString) sent = true end) end
            end
        end
        if not sent then
            local ev = Replicated:FindFirstChild("DefaultChatSystemChatEvents")
            local say = ev and ev:FindFirstChild("SayMessageRequest")
            if say then pcall(function() say:FireServer(msgString, "All") end) end
        end
    end)
end
