local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

_G.F3X = _G.F3X or {}
_G.F3X.Enabled = false
_G.F3X.SelectedParts = {}
_G.F3X.Highlights = {}
_G.F3X.UndoStack = {}
_G.F3X.RedoStack = {}
_G.F3X.ModifiedParts = {}
_G.F3X.UpdateUI = nil
_G.F3X.NotifyFunc = nil 
_G.F3X.IsReady = true

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end
local F3X_FOLDER = "michigun.xyz/fp3_F3X"
if writefile and not isfolder(F3X_FOLDER) then makefolder(F3X_FOLDER) end

local TOLERANCE = 1

local function round(n)
    return math.floor(n * 10 + 0.5) / 10
end

local function sizeMatch(a, b)
    return math.abs(a.X - b.X) <= TOLERANCE
       and math.abs(a.Y - b.Y) <= TOLERANCE
       and math.abs(a.Z - b.Z) <= TOLERANCE
end

local function safeNotify(title, msg)
    if _G.F3X.NotifyFunc then
        _G.F3X.NotifyFunc(msg, 3, "lucide:info")
    end
end

local function clearHighlights()
    for _, h in ipairs(_G.F3X.Highlights) do
        if h then h:Destroy() end
    end
    table.clear(_G.F3X.Highlights)
end

local function highlight(part)
    local h = Instance.new("Highlight")
    h.Name = "F3XSelection"
    h.FillTransparency = 1
    h.OutlineTransparency = 0
    h.OutlineColor = Color3.fromRGB(0, 255, 255)
    h.Parent = part
    table.insert(_G.F3X.Highlights, h)
end

_G.F3X.ClearSelection = function()
    table.clear(_G.F3X.SelectedParts)
    clearHighlights()
    if _G.F3X.UpdateUI then _G.F3X.UpdateUI() end
end

local function pushUndo()
    local snap = {}
    for _, p in ipairs(_G.F3X.SelectedParts) do
        snap[p] = p.Size
    end
    table.insert(_G.F3X.UndoStack, snap)
    table.clear(_G.F3X.RedoStack)
end

_G.F3X.ApplySize = function(v)
    if #_G.F3X.SelectedParts == 0 then return end
    pushUndo()
    for _, p in ipairs(_G.F3X.SelectedParts) do
        p.Size = v
        _G.F3X.ModifiedParts[p] = v
    end
    if _G.F3X.UpdateUI then _G.F3X.UpdateUI() end
end

_G.F3X.Undo = function()
    local s = table.remove(_G.F3X.UndoStack)
    if not s then return end
    local redo = {}
    for p, size in pairs(s) do
        redo[p] = p.Size
        p.Size = size
        _G.F3X.ModifiedParts[p] = size
    end
    table.insert(_G.F3X.RedoStack, redo)
    if _G.F3X.UpdateUI then _G.F3X.UpdateUI() end
end

_G.F3X.Redo = function()
    local s = table.remove(_G.F3X.RedoStack)
    if not s then return end
    local undo = {}
    for p, size in pairs(s) do
        undo[p] = p.Size
        p.Size = size
        _G.F3X.ModifiedParts[p] = size
    end
    table.insert(_G.F3X.UndoStack, undo)
    if _G.F3X.UpdateUI then _G.F3X.UpdateUI() end
end

_G.F3X.ListConfigs = function()
    local out = {}
    if listfiles then
        for _, f in ipairs(listfiles(F3X_FOLDER)) do
            if f:sub(-5) == ".json" then
                out[#out + 1] = f:match("([^/]+)%.json$")
            end
        end
    end
    return out
end

_G.F3X.SaveConfig = function(name)
    if not name or name == "" then
        safeNotify("F3X", "Nome inválido.")
        return nil
    end

    local data = {
        PlaceId = game.PlaceId,
        Parts = {}
    }

    for part, size in pairs(_G.F3X.ModifiedParts) do
        if part and part.Parent then
            data.Parts[#data.Parts + 1] = {
                Path = part:GetFullName(),
                CFrame = { part.CFrame:GetComponents() },
                Size = { size.X, size.Y, size.Z }
            }
        end
    end

    writefile(F3X_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    safeNotify("F3X", "Config salva")
    return _G.F3X.ListConfigs()
end

_G.F3X.ApplyConfig = function(name)
    if not name then return end
    local path = F3X_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then return end

    local data = HttpService:JSONDecode(readfile(path))

    if data.PlaceId ~= game.PlaceId then
        safeNotify("F3X", "Configuração de outro mapa.")
        return
    end

    for _, v in ipairs(data.Parts or {}) do
        local cf = CFrame.new(unpack(v.CFrame))
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj:GetFullName() == v.Path then
                if (obj.Position - cf.Position).Magnitude < 1 then
                    obj.Size = Vector3.new(unpack(v.Size))
                    break
                end
            end
        end
    end
    safeNotify("F3X", "Aplicada.")
end

_G.F3X.DeleteConfig = function(name)
    if not name then
        safeNotify("F3X", "Nenhuma config selecionada.")
        return nil
    end
    delfile(F3X_FOLDER .. "/" .. name .. ".json")
    safeNotify("F3X", "Deletada.")
    return _G.F3X.ListConfigs()
end

_G.F3X.Toggle = function(state)
    _G.F3X.Enabled = state
    if not state then
        _G.F3X.ClearSelection()
    end
end

Mouse.Button1Down:Connect(function()
    if not _G.F3X.Enabled then return end
    local t = Mouse.Target
    if not t or not t:IsA("BasePart") then return end

    for i, p in ipairs(_G.F3X.SelectedParts) do
        if p == t then
            table.remove(_G.F3X.SelectedParts, i)
            clearHighlights()
            for _, sp in ipairs(_G.F3X.SelectedParts) do
                highlight(sp)
            end
            if _G.F3X.UpdateUI then _G.F3X.UpdateUI() end
            return
        end
    end

    if #_G.F3X.SelectedParts > 0 and not sizeMatch(_G.F3X.SelectedParts[1].Size, t.Size) then
        safeNotify("F3X", "Selecione partes do mesmo tamanho.")
        return
    end

    table.insert(_G.F3X.SelectedParts, t)
    highlight(t)
    if _G.F3X.UpdateUI then _G.F3X.UpdateUI() end
end)
