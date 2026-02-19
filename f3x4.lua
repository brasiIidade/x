local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local hs = cr(game:GetService("HttpService"))
local cg = cr(game:GetService("CoreGui"))
local uis = cr(game:GetService("UserInputService"))
local lp = cr(plrs.LocalPlayer)
local cam = cr(ws.CurrentCamera)

local env = getgenv()
env.F3X = env.F3X or {}
local f3x = env.F3X

f3x.Enabled = false
f3x.SelectedParts = {}
f3x.Highlights = {}
f3x.UndoStack = {}
f3x.RedoStack = {}
f3x.ModifiedParts = {}
f3x.UpdateUI = nil
f3x.NotifyFunc = nil
f3x.IsReady = true

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
local fDir = "michigun.xyz/fp3_F3X"
if writefile and not isfolder(fDir) then makefolder(fDir) end

local hlParent
local function getHlParent()
    if hlParent then return hlParent end
    local s, t = pcall(function() return gethui() end)
    hlParent = (s and t) and t or cg
    return hlParent
end

local function clrHl()
    for _, h in ipairs(f3x.Highlights) do if h then h:Destroy() end end
    table.clear(f3x.Highlights)
end

local function mkHl(p)
    task.defer(function()
        if not p or not p.Parent then return end
        local h = Instance.new("Highlight")
        h.Name = hs:GenerateGUID(false)
        h.FillTransparency = 1
        h.OutlineTransparency = 0
        h.OutlineColor = Color3.fromRGB(0, 255, 255)
        h.Adornee = p
        h.Parent = getHlParent()
        table.insert(f3x.Highlights, h)
    end)
end

f3x.ClearSelection = function()
    table.clear(f3x.SelectedParts)
    clrHl()
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

local function pushU()
    local s = {}
    for _, p in ipairs(f3x.SelectedParts) do s[p] = p.Size end
    table.insert(f3x.UndoStack, s)
    table.clear(f3x.RedoStack)
end

f3x.ApplySize = function(v)
    if #f3x.SelectedParts == 0 then return end
    pushU()
    for _, p in ipairs(f3x.SelectedParts) do
        p.Size = v
        f3x.ModifiedParts[p] = v
    end
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.Undo = function()
    local s = table.remove(f3x.UndoStack)
    if not s then return end
    local r = {}
    for p, sz in pairs(s) do
        r[p] = p.Size
        p.Size = sz
        f3x.ModifiedParts[p] = sz
    end
    table.insert(f3x.RedoStack, r)
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.Redo = function()
    local s = table.remove(f3x.RedoStack)
    if not s then return end
    local u = {}
    for p, sz in pairs(s) do
        u[p] = p.Size
        p.Size = sz
        f3x.ModifiedParts[p] = sz
    end
    table.insert(f3x.UndoStack, u)
    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
end

f3x.ListConfigs = function()
    local o = {}
    if listfiles then for _, f in ipairs(listfiles(fDir)) do if f:sub(-5) == ".json" then o[#o + 1] = f:match("([^/]+)%.json$") end end end
    return o
end

local function s_e(k, s)
    local S, j = {}, 0
    for i=0,255 do S[i]=i end
    for i=0,255 do j=(j+S[i]+k:byte((i%#k)+1))%256 S[i],S[j]=S[j],S[i] end
    local i, j, o = 0, 0, {}
    for x=1,#s do
        i=(i+1)%256 j=(j+S[i])%256 S[i],S[j]=S[j],S[i]
        table.insert(o, string.char(bit32.bxor(s:byte(x), S[(S[i]+S[j])%256])))
    end
    return table.concat(o)
end
local function eh(s) return (s:gsub(".", function(c) return string.format("%02X", c:byte()) end)) end
local function dh(s) return (s:gsub("..", function(c) return string.char(tonumber(c, 16)) end)) end
local S_KEY = "MICHIGUN_ENVERGONHADA_FP3"

local function stripHeader(s)
    return s:gsub("^%-%-%[%[.-%]%]%-%-[\r\n]*", "")
end

local function migrate()
    if not listfiles or not isfolder(fDir) then return end
    for _, path in ipairs(listfiles(fDir)) do
        if path:sub(-5) == ".json" then
            local s, content = pcall(readfile, path)
            if s and content then
                local clean = stripHeader(content)
                if clean:sub(1, 12) ~= "michigun.xyz" then
                    local d
                    pcall(function() d = hs:JSONDecode(content) end)
                    if d then
                        local name = path:match("([^/\\]+)%.json$") or "unknown"
                        local rj = hs:JSONEncode(d)
                        local enc = "michigun.xyz" .. eh(s_e(S_KEY, rj))
                        local header = string.format("--[[ F3X do michigun.xyz -> %s ]]--\n", name)
                        writefile(path, header .. enc)
                    end
                end
            end
        end
    end
end
task.spawn(migrate)

f3x.SaveConfig = function(n)
    if not n or n == "" then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Nome inválido", 3, "lucide:alert-circle") end return nil end
    local d = { PlaceId = game.PlaceId, Parts = {} }
    for p, sz in pairs(f3x.ModifiedParts) do
        if p and p.Parent then
            d.Parts[#d.Parts + 1] = { Path = p:GetFullName(), CFrame = { p.CFrame:GetComponents() }, Size = { sz.X, sz.Y, sz.Z } }
        end
    end
    local rj = hs:JSONEncode(d)
    local enc = "michigun.xyz" .. eh(s_e(S_KEY, rj))
    local header = string.format("--[[ F3X do michigun.xyz -> %s ]]--\n", n)
    writefile(fDir .. "/" .. n .. ".json", header .. enc)
    return f3x.ListConfigs()
end

local function getObj(path)
    local segs = {}
    for s in path:gmatch("[^%.]+") do table.insert(segs, s) end
    local cur = game
    for _, s in ipairs(segs) do
        if s ~= "Game" then
            cur = cur:FindFirstChild(s)
            if not cur then return nil end
        end
    end
    return cur
end

f3x.ApplyConfig = function(n)
    if not n then return end
    local p = fDir .. "/" .. n .. ".json"
    if not isfile(p) then return end
    local c = readfile(p)
    local clean = stripHeader(c)
    local d = nil
    
    if clean:sub(1, 12) == "michigun.xyz" then
        pcall(function() d = hs:JSONDecode(s_e(S_KEY, dh(clean:sub(13)))) end)
    else
        pcall(function() d = hs:JSONDecode(c) end)
    end

    if not d then return end
    if d.PlaceId ~= game.PlaceId then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Config de outro mapa", 3, "lucide:alert-circle") end return end

    for _, v in ipairs(d.Parts or {}) do
        local obj = getObj(v.Path)
        if not obj then 
            for _, o in ipairs(ws:GetDescendants()) do
                if o:IsA("BasePart") and o:GetFullName() == v.Path then
                    obj = o
                    break
                end
            end
        end
        
        if obj and obj:IsA("BasePart") then
            local cf = CFrame.new(unpack(v.CFrame))
            if (obj.Position - cf.Position).Magnitude < 2 then
                obj.Size = Vector3.new(unpack(v.Size))
            end
        end
    end
end

f3x.DeleteConfig = function(n)
    if not n then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Nenhuma seleção", 3, "lucide:alert-circle") end return nil end
    delfile(fDir .. "/" .. n .. ".json")
    return f3x.ListConfigs()
end

f3x.Toggle = function(s)
    f3x.Enabled = s
    if not s then f3x.ClearSelection() end
end

local mouseConn
if lp then
    local ms = lp:GetMouse()
    mouseConn = ms.Button1Down:Connect(function()
        if not f3x.Enabled then return end
        local t = ms.Target
        if not t or not t:IsA("BasePart") then return end
        
        local ctrl = uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.RightControl)
        
        if ctrl then
            for i, p in ipairs(f3x.SelectedParts) do
                if p == t then
                    table.remove(f3x.SelectedParts, i)
                    clrHl()
                    for _, sp in ipairs(f3x.SelectedParts) do mkHl(sp) end
                    if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
                    return
                end
            end
            table.insert(f3x.SelectedParts, t)
            mkHl(t)
        else
            f3x.ClearSelection()
            table.insert(f3x.SelectedParts, t)
            mkHl(t)
        end
        if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
    end)
end
