local z = false
local k =
[[
    skid
]]
if not getmetatable or not setmetatable or not type or not select or type(select(2, pcall(getmetatable, setmetatable({}, {__index = function(self, ...) while true do end end})))['__index']) ~= 'function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or not select or not getfenv or select(1, pcall(getfenv, 69)) == true or not select(2, pcall(rawget, debug, "info")) or #(((select(2, pcall(rawget, debug, "info")))(getfenv, "n")))<=1 or #(((select(2, pcall(rawget, debug, "info")))(print, "n")))<=1 or not (select(2, pcall(rawget, debug, "info")))(print, "s") == "[C]" or not (select(2, pcall(rawget, debug, "info")))(require, "s") == "[C]" or (select(2, pcall(rawget, debug, "info")))((function()end), "s") == "[C]" then
  return z and tostring(k) or nil
end

local Replicated = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local function Notify(t, m)
    if getgenv().notificar then
        getgenv().notificar(t .. ": " .. m, 3, "lucide:info")
    elseif _G.notificar then
        _G.notificar(t .. ": " .. m, 3, "lucide:info")
    end
end

local Logic = {}
Logic.JJValue = 0
Logic.MoneyAllEnabled = false
Logic.ReceivedList = {}

local Polichinelos = Replicated:WaitForChild("Remotes"):WaitForChild("Polichinelos")
local DecMoney = Replicated:WaitForChild("Remotes"):WaitForChild("Events"):WaitForChild("Economy"):WaitForChild("DecrementMoney")
local TransRemote = Replicated:WaitForChild("Modules"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("EconomyService"):WaitForChild("RE"):WaitForChild("Transfer")

function Logic.SetJJ()
    local n = tonumber(Logic.JJValue)
    if not n or n == 0 then return end
    Polichinelos:FireServer("Add", n)
    Notify("Delta", "JJ Modificado")
end

function Logic.GetRich()
    DecMoney:FireServer(-1000000, "BuyMilitaryPass")
    Notify("Delta", "Reiniciando...")
    task.defer(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

function Logic.ToggleMoneyAll(state)
    Logic.MoneyAllEnabled = state
    if state then
        DecMoney:FireServer(-9e90, "BuyMilitaryPass")
        Notify("Money All", "Iniciando...")
        
        task.spawn(function()
            while Logic.MoneyAllEnabled do
                local list = Players:GetPlayers()
                local target = nil

                for _, p in ipairs(list) do
                    if p ~= LocalPlayer and not Logic.ReceivedList[p.Name] then
                        target = p
                        break
                    end
                end

                if not target then
                    local others = false
                    for _, p in ipairs(list) do
                        if p ~= LocalPlayer then others = true break end
                    end
                    if others then
                        Notify("Money All", "Reiniciando ciclo...")
                        table.clear(Logic.ReceivedList)
                        for _, p in ipairs(list) do
                            if p ~= LocalPlayer then target = p break end
                        end
                    end
                end

                if target then
                    TransRemote:FireServer(target.Name, "10e10")
                    Logic.ReceivedList[target.Name] = true
                    Notify("Money All", "Enviado: " .. target.Name)
                end
                task.wait(15.5)
            end
        end)
    else
        Notify("Money All", "Parado")
    end
end

_G.DeltaLogic = Logic
