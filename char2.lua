local cloneref = cloneref or function(o) return o end

local Players = cloneref(game:GetService("Players"))
local lp = Players.LocalPlayer

_G.Avatar = _G.Avatar or {}
_G.Avatar.TargetInput = ""
_G.Avatar.CurrentAppliedId = lp.UserId
_G.Avatar.SkinFolder = "michigun.xyz/fp3_Skins"

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
if not isfolder(_G.Avatar.SkinFolder) then makefolder(_G.Avatar.SkinFolder) end

local function find_player(name)
    if not name or name == "" then return nil end
    name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
    return nil
end

local function morphchar(char, faken, fakeid, desc)
    if char == lp.Character then
        _G.Avatar.CurrentAppliedId = fakeid
    end
    
    task.spawn(function()
        xpcall(function()
            task.wait(0.3)
            local hum = char:WaitForChild("Humanoid", 10)
            if not hum then return end
            
            for _, v in char:GetDescendants() do
                if v:IsA("Accessory") or v:IsA("Hat") then v:Destroy() end
            end
            for _, v in char:GetChildren() do
                if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") then v:Destroy() end
            end
            
            local bc = hum:FindFirstChildOfClass("BodyColors")
            if bc then bc:Destroy() end
            
            for _, n in {"Torso","Left Arm","Right Arm","Left Leg","Right Leg"} do
                local pt = char:FindFirstChild(n)
                if pt then
                    for _, v in pt:GetChildren() do
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
            hum:ApplyDescriptionClientServer(desc)
        end, warn)
    end)
end

_G.Avatar.ApplySkin = function(target)
    local fakename = target
    if fakename == "" then return end
    local fakeid = tonumber(fakename)
    local ok = pcall(function()
        if fakeid then
            fakename = Players:GetNameFromUserIdAsync(fakeid)
        else
            fakeid = Players:GetUserIdFromNameAsync(fakename)
            fakename = Players:GetNameFromUserIdAsync(fakeid)
        end
    end)
    if ok and lp.Character then
        local desc = Players:GetHumanoidDescriptionFromUserId(fakeid)
        morphchar(lp.Character, fakename, fakeid, desc)
    end
end

_G.Avatar.ApplySkinToOther = function(targetName, skinInput, isSavedFile)
    local targetPlr = find_player(targetName)
    if not targetPlr or not targetPlr.Character then return end
    
    local fakeid
    local fakename = skinInput

    if isSavedFile then
         local success, savedId = pcall(function()
            return readfile(_G.Avatar.SkinFolder .. "/" .. skinInput .. ".txt")
        end)
        if success then
            fakeid = tonumber(savedId)
            fakename = "SavedSkin"
        else
            return
        end
    else
        fakeid = tonumber(fakename)
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
        if s then
            morphchar(targetPlr.Character, fakename, fakeid, desc)
        end
    end
end

_G.Avatar.RestoreOther = function(targetName)
    local targetPlr = find_player(targetName)
    if not targetPlr or not targetPlr.Character then return end
    
    local s, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(targetPlr.UserId)
    end)
    
    if s then
        morphchar(targetPlr.Character, targetPlr.Name, targetPlr.UserId, desc)
    end
end

_G.Avatar.RestoreSkin = function()
    local desc = Players:GetHumanoidDescriptionFromUserId(lp.UserId)
    if lp.Character then
        morphchar(lp.Character, lp.Name, lp.UserId, desc)
    end
end

_G.Avatar.GetSavedSkins = function()
    local files = listfiles(_G.Avatar.SkinFolder)
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

_G.Avatar.SaveSkin = function(customName)
    local fileName = (customName ~= "" and customName:gsub("[^%w%s]", "")) or "Skin_" .. _G.Avatar.CurrentAppliedId
    writefile(_G.Avatar.SkinFolder .. "/" .. fileName .. ".txt", tostring(_G.Avatar.CurrentAppliedId))
end

_G.Avatar.LoadSkin = function(name)
    local success, savedId = pcall(function()
        return readfile(_G.Avatar.SkinFolder .. "/" .. name .. ".txt")
    end)
    if success then
        local s, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(tonumber(savedId))
        end)
        if s and lp.Character then
            morphchar(lp.Character, name, tonumber(savedId), desc)
        end
    end
end

_G.Avatar.DeleteSkin = function(name)
    local path = _G.Avatar.SkinFolder .. "/" .. name .. ".txt"
    if isfile(path) then
        delfile(path)
    end
end
