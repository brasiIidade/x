local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local ws = cr(game:GetService("Workspace"))
local hs = cr(game:GetService("HttpService"))
local cg = cr(game:GetService("CoreGui"))
local uis = cr(game:GetService("UserInputService"))
local lp = cr(plrs.LocalPlayer)
local cam = cr(ws.CurrentCamera)

local unp = table.unpack or unpack

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
local fDir = "michigun.xyz/f3x"
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

f3x.SaveConfig = function(n)
    if not n or n == "" then if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Nome inválido", 3, "lucide:alert-circle") end return nil end
    local d = { PlaceId = game.PlaceId, Parts = {} }
    for p, sz in pairs(f3x.ModifiedParts) do
        if p and p.Parent then
            d.Parts[#d.Parts + 1] = { Path = p:GetFullName(), CFrame = { p.CFrame:GetComponents() }, Size = { sz.X, sz.Y, sz.Z } }
        end
    end
    local rj = hs:JSONEncode(d)
    writefile(fDir .. "/" .. n .. ".json", rj)
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
    local d = nil
    
    pcall(function() d = hs:JSONDecode(c) end)

    if not d then return end
    if d.PlaceId ~= game.PlaceId then 
        if f3x.NotifyFunc then f3x.NotifyFunc("F3X: Config de outro mapa", 3, "lucide:alert-circle") end 
        return 
    end

    for _, v in ipairs(d.Parts or {}) do
        local targetCf = CFrame.new(unp(v.CFrame))
        local foundPart = nil

        local obj = getObj(v.Path)
        if obj and obj:IsA("BasePart") and (obj.Position - targetCf.Position).Magnitude < 2 then
            foundPart = obj
        else
            for _, o in ipairs(ws:GetDescendants()) do
                if o:IsA("BasePart") and o:GetFullName() == v.Path then
                    if (o.Position - targetCf.Position).Magnitude < 2 then
                        foundPart = o
                        break
                    end
                end
            end
        end
        
        if foundPart then
            foundPart.Size = Vector3.new(unp(v.Size))
            f3x.ModifiedParts[foundPart] = foundPart.Size
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
        
        for i, p in ipairs(f3x.SelectedParts) do
            if p == t then
                table.remove(f3x.SelectedParts, i)
                clrHl()
                for _, sp in ipairs(f3x.SelectedParts) do mkHl(sp) end
                if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
                return
            end
        end
        
        if #f3x.SelectedParts > 0 then
            local ref = f3x.SelectedParts[1].Size
            local ts = t.Size
            if math.abs(ref.X - ts.X) > 1 or math.abs(ref.Y - ts.Y) > 1 or math.abs(ref.Z - ts.Z) > 1 then
                f3x.ClearSelection()
            end
        end
        
        table.insert(f3x.SelectedParts, t)
        mkHl(t)
        if f3x.UpdateUI then task.defer(f3x.UpdateUI) end
    end)
end
