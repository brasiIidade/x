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

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local lp = Players.LocalPlayer

local AvatarLib = {}

AvatarLib.TargetInput = ""
AvatarLib.CurrentAppliedId = (lp and lp.UserId) or 0
AvatarLib.SkinFolder = "michigun.xyz/fp3_Skins"

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
if not isfolder(AvatarLib.SkinFolder) then makefolder(AvatarLib.SkinFolder) end

local function safe_tonumber(val)
    if not val then return nil end
    return tonumber(val)
end

local function find_player(name)
    if not name or type(name) ~= "string" or name == "" then return nil end
    name = name:lower()
    
    local playerList = Players:GetPlayers()
    for i = 1, #playerList do
        local p = playerList[i]
        if p then
            local pName = p.Name and p.Name:lower()
            local pDisp = p.DisplayName and p.DisplayName:lower()
            
            if (pName and pName:sub(1, #name) == name) or (pDisp and pDisp:sub(1, #name) == name) then
                return p
            end
        end
    end
    return nil
end

local function morphchar(char, faken, fakeid, desc)
    if not char then return end
    
    if lp and char == lp.Character then
        AvatarLib.CurrentAppliedId = fakeid or AvatarLib.CurrentAppliedId
    end
    
    task.spawn(function()
        local success, err = pcall(function()
            task.wait(0.3)
            local hum = char:WaitForChild("Humanoid", 10)
            if not hum then return end
            
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("Accessory") or v:IsA("Hat") then v:Destroy() end
            end
            
            local children = char:GetChildren()
            for i = 1, #children do
                local v = children[i]
                if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") then 
                    v:Destroy() 
                end
            end
            
            local bc = hum:FindFirstChildOfClass("BodyColors")
            if bc then bc:Destroy() end
            
            local limbs = {"Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
            for i = 1, #limbs do
                local pt = char:FindFirstChild(limbs[i])
                if pt then
                    local ptChildren = pt:GetChildren()
                    for j = 1, #ptChildren do
                        local v = ptChildren[j]
                        if v:IsA("SpecialMesh") then v:Destroy() end
                    end
                end
            end
            
            local hd = char:FindFirstChild("Head")
            if hd then
                local ms = hd:FindFirstChildOfClass("SpecialMesh")
                if ms then
                    ms.MeshId = ""
                    ms.TextureId = ""
                end
            end
            
            task.wait(0.1)
            if desc then
                hum:ApplyDescriptionClientServer(desc)
            end
        end)
        
        if not success then warn("Morph Error:", err) end
    end)
end

AvatarLib.ApplySkin = function(target)
    if not lp or not lp.Character then return end
    
    local fakename = target or ""
    if fakename == "" then return end
    
    local fakeid = safe_tonumber(fakename)
    
    local ok = pcall(function()
        if fakeid then
            fakename = Players:GetNameFromUserIdAsync(fakeid)
        else
            fakeid = Players:GetUserIdFromNameAsync(fakename)
            fakename = Players:GetNameFromUserIdAsync(fakeid)
        end
    end)
    
    if ok and fakeid then
        local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(fakeid) end)
        if s and desc then
            morphchar(lp.Character, fakename, fakeid, desc)
        end
    end
end

AvatarLib.ApplySkinToOther = function(targetName, skinInput, isSavedFile)
    local targetPlr = find_player(targetName)
    if not targetPlr or not targetPlr.Character then return end
    
    local fakeid
    local fakename = skinInput

    if isSavedFile then
        local success, savedId = pcall(function()
            return readfile(AvatarLib.SkinFolder .. "/" .. skinInput .. ".txt")
        end)
        if success and savedId then
            fakeid = safe_tonumber(savedId)
            fakename = "SavedSkin"
        else
            return
        end
    else
        fakeid = safe_tonumber(fakename)
        local ok = pcall(function()
            if fakeid then
                fakename = Players:GetNameFromUserIdAsync(fakeid)
            else
                fakeid = Players:GetUserIdFromNameAsync(fakename)
                fakename = Players:GetNameFromUserIdAsync(fakeid)
            end
        end)
        if not ok then return end
    end

    if fakeid then
        local s, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(fakeid)
        end)
        if s and desc then
            morphchar(targetPlr.Character, fakename, fakeid, desc)
        end
    end
end

AvatarLib.RestoreOther = function(targetName)
    local targetPlr = find_player(targetName)
    if not targetPlr or not targetPlr.Character then return end
    
    local s, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(targetPlr.UserId)
    end)
    
    if s and desc then
        morphchar(targetPlr.Character, targetPlr.Name, targetPlr.UserId, desc)
    end
end

AvatarLib.RestoreSkin = function()
    if not lp or not lp.Character then return end
    
    local s, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(lp.UserId) end)
    
    if s and desc then
        morphchar(lp.Character, lp.Name, lp.UserId, desc)
    end
end

AvatarLib.GetSavedSkins = function()
    local success, files = pcall(listfiles, AvatarLib.SkinFolder)
    if not success or not files then return {{Title = "Erro ao ler pasta", Icon = "lucide:alert-triangle"}} end
    
    local options = {}
    for _, file in ipairs(files) do
        local name = file:match("([^\\/]+)%.txt$")
        if name then
            table.insert(options, {Title = name, Icon = "lucide:user"})
        end
    end
    if #options == 0 then
        table.insert(options, {Title = "Nenhuma salva", Icon = "lucide:frown"})
    end
    return options
end

AvatarLib.SaveSkin = function(customName)
    local idToSave = AvatarLib.CurrentAppliedId or 0
    local fileName = (customName ~= "" and customName:gsub("[^%w%s]", "")) or "Skin_" .. idToSave
    writefile(AvatarLib.SkinFolder .. "/" .. fileName .. ".txt", tostring(idToSave))
end

AvatarLib.LoadSkin = function(name)
    if not lp or not lp.Character then return end
    
    local success, savedId = pcall(function()
        return readfile(AvatarLib.SkinFolder .. "/" .. name .. ".txt")
    end)
    
    if success and savedId then
        local numId = safe_tonumber(savedId)
        if numId then
            local s, desc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(numId)
            end)
            if s and desc then
                morphchar(lp.Character, name, numId, desc)
            end
        end
    end
end

AvatarLib.DeleteSkin = function(name)
    local path = AvatarLib.SkinFolder .. "/" .. name .. ".txt"
    if isfile(path) then
        delfile(path)
    end
end

_G.Avatar = AvatarLib
