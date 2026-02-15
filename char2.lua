-- anti
local _l1llIIll1I11 = {115, 107, 105, 100, 32, 109, 225, 120, 105, 109, 111, 44, 32, 112, 114, 111, 112, 114, 105, 101, 100, 97, 100, 101, 32, 100, 111, 32, 109, 105, 99, 104, 105, 103, 117, 110, 46, 120, 121, 122}
local _IIllIlIl11lI = "" for _1l1lI, _lllII in ipairs(_l1llIIll1I11) do _IIllIlIl11lI = _IIllIlIl11lI .. string.char(_lllII) end

local function _lIllIl111lIlI()
    warn(_IIllIlIl11lI)
    task.wait(0.5)
    local _1lIl1I = 0
    local function _lIlIl11II() return _lIlIl11II() end
    _lIlIl11II()
end

local _Il1l1I1II = 0
local _l1I1l1Il1 = game:GetService("RunService").Heartbeat:Connect(function()
    _Il1l1I1II += 1
end)
repeat
    task.wait()
until _Il1l1I1II >= 2
_l1I1l1Il1:Disconnect()

if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or ({debug.info(print,'a')})[1]~=0 or ({debug.info(tostring,'a')})[1]~=0 or ({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" or not select(1, pcall(debug.info, coroutine.wrap(function() end)(), 's')) == false then
    _lIllIl111lIlI()
end

if not game.ServiceAdded then
    _lIllIl111lIlI()
end

if getfenv()[Instance.new("Part")] then
    _lIllIl111lIlI()
end

if getmetatable(__call) then
    _lIllIl111lIlI()
end

local _llIl1llIl1 = pcall(function()
    Instance.new("Part"):BananaPeelSlipper("a")
end)

if _llIl1llIl1 then
    _lIllIl111lIlI()
end

local _1l1IIl1l, _IIl1l1Il = pcall(function()
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

if not _1l1IIl1l then
    _lIllIl111lIlI()
end

if _IIl1l1Il[6][3] ~= nil then
    _lIllIl111lIlI()
end

local _, _l1lIl11llI = pcall(function()
    game()
end)

if not _l1lIl11llI:find("attempt to call a Instance value") then
    _lIllIl111lIlI()
end

if #game:GetChildren() <= 4 then
    _lIllIl111lIlI()
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
