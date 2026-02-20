local s=pcall(function()Instance.new("Part"):A("a")end)while s do task.spawn()end game:GetChildren(function()while 1 do ({})[nil]=1 end end)while #game:GetChildren()<=4 do buffer.writei8(buffer.fromstring("a"),1,2)end local s,r=pcall(function()return game:GetService("HttpService"):JSONDecode('[1,"",true,1,false,[1,null,""],null,[""]]')end)while not s do task()end while r[6][2]~=nil do(1)()end local s=pcall(function()return game.HttpService end)while not s do _=(nil).P end _G.X=1while getfenv().X~=nil do game()end _G.X=nil local _,m=pcall(function()game()end)while not m:find("attempt to call a Instance value")do table.create(9e9)end

local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local rs = cr(game:GetService("RunService"))
local lp = cr(plrs.LocalPlayer)

local env = getgenv()
env.Avatar = env.Avatar or {}
local av = env.Avatar

av.TargetInput = ""
av.CurrentAppliedId = (lp and lp.UserId) or 0
av.SkinFolder = "michigun.xyz/skins"

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
if not isfolder(av.SkinFolder) then makefolder(av.SkinFolder) end

local function s_ton(v) return v and tonumber(v) or nil end

local function f_plr(n)
    if not n or type(n) ~= "string" or n == "" then return nil end
    n = n:lower()
    for _, p in ipairs(plrs:GetPlayers()) do
        local pn = p.Name and p.Name:lower()
        local pd = p.DisplayName and p.DisplayName:lower()
        if (pn and pn:sub(1, #n) == n) or (pd and pd:sub(1, #n) == n) then return p end
    end
    return nil
end

local function morph(c, fn, fid, d)
    if not c then return end
    if lp and c == lp.Character then av.CurrentAppliedId = fid or av.CurrentAppliedId end
    
    task.spawn(function()
        pcall(function()
            task.wait(0.3)
            local h = c:WaitForChild("Humanoid", 10)
            if not h then return end
            
            for _, v in ipairs(c:GetDescendants()) do
                if v:IsA("Accessory") or v:IsA("Hat") then v:Destroy() end
            end
            
            for _, v in ipairs(c:GetChildren()) do
                if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") then v:Destroy() end
            end
            
            local bc = h:FindFirstChildOfClass("BodyColors")
            if bc then bc:Destroy() end
            
            for _, l in ipairs({"Torso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
                local p = c:FindFirstChild(l)
                if p then
                    for _, v in ipairs(p:GetChildren()) do if v:IsA("SpecialMesh") then v:Destroy() end end
                end
            end
            
            local hd = c:FindFirstChild("Head")
            if hd then
                local m = hd:FindFirstChildOfClass("SpecialMesh")
                if m then m.MeshId = "" m.TextureId = "" end
            end
            
            task.wait(0.1)
            if d then h:ApplyDescriptionClientServer(d) end
        end)
    end)
end

av.ApplySkin = function(tgt)
    if not lp or not lp.Character then return end
    local fn = tgt or ""
    if fn == "" then return end
    local fid = s_ton(fn)
    local s = pcall(function()
        if fid then fn = plrs:GetNameFromUserIdAsync(fid)
        else fid = plrs:GetUserIdFromNameAsync(fn) fn = plrs:GetNameFromUserIdAsync(fid) end
    end)
    if s and fid then
        local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(fid) end)
        if k and d then morph(lp.Character, fn, fid, d) end
    end
end

av.ApplySkinToOther = function(tn, si, sf)
    local tp = f_plr(tn)
    if not tp or not tp.Character then return end
    local fid, fn = nil, si
    if sf then
        local s, sd = pcall(function() return readfile(av.SkinFolder .. "/" .. si .. ".txt") end)
        if s and sd then fid = s_ton(sd) fn = "SavedSkin" else return end
    else
        fid = s_ton(fn)
        local k = pcall(function()
            if fid then fn = plrs:GetNameFromUserIdAsync(fid)
            else fid = plrs:GetUserIdFromNameAsync(fn) fn = plrs:GetNameFromUserIdAsync(fid) end
        end)
        if not k then return end
    end
    if fid then
        local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(fid) end)
        if k and d then morph(tp.Character, fn, fid, d) end
    end
end

av.RestoreOther = function(tn)
    local tp = f_plr(tn)
    if not tp or not tp.Character then return end
    local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(tp.UserId) end)
    if k and d then morph(tp.Character, tp.Name, tp.UserId, d) end
end

av.RestoreSkin = function()
    if not lp or not lp.Character then return end
    local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(lp.UserId) end)
    if k and d then morph(lp.Character, lp.Name, lp.UserId, d) end
end

av.GetSavedSkins = function()
    local s, f = pcall(listfiles, av.SkinFolder)
    if not s or not f then return {{Title="Erro ao ler pasta", Icon="lucide:alert-triangle"}} end
    local o = {}
    for _, v in ipairs(f) do
        local n = v:match("([^\\/]+)%.txt$")
        if n then table.insert(o, {Title=n, Icon="lucide:user"}) end
    end
    if #o == 0 then table.insert(o, {Title="Nenhuma salva", Icon="lucide:frown"}) end
    return o
end

av.SaveSkin = function(cn)
    local i = av.CurrentAppliedId or 0
    local n = (cn ~= "" and cn:gsub("[^%w%s]", "")) or "Skin_" .. i
    writefile(av.SkinFolder .. "/" .. n .. ".txt", tostring(i))
end

av.LoadSkin = function(n)
    if not lp or not lp.Character then return end
    local s, sd = pcall(function() return readfile(av.SkinFolder .. "/" .. n .. ".txt") end)
    if s and sd then
        local ni = s_ton(sd)
        if ni then
            local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(ni) end)
            if k and d then morph(lp.Character, n, ni, d) end
        end
    end
end

av.DeleteSkin = function(n)
    local p = av.SkinFolder .. "/" .. n .. ".txt"
    if isfile(p) then delfile(p) end
end
