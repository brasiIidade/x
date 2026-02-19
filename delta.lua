local cr = cloneref or function(o) return o end
local rs = cr(game:GetService("ReplicatedStorage"))
local plrs = cr(game:GetService("Players"))
local lp = cr(plrs.LocalPlayer)

local rems = rs:WaitForChild("Remotes")
local poli = rems:WaitForChild("Polichinelos")
local decM = rems:WaitForChild("Events"):WaitForChild("Economy"):WaitForChild("DecrementMoney")
local trns = rs:WaitForChild("Modules"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("EconomyService"):WaitForChild("RE"):WaitForChild("Transfer")

local function ntf(m)
    if getgenv().notificar then
        getgenv().notificar(m, 3, "lucide:info")
    end
end

local lgc = { JJValue = 0, MoneyAllEnabled = false, rL = {} }
getgenv().DeltaLogic = lgc

function lgc.SetJJ()
    local n = tonumber(lgc.JJValue)
    if not n or n == 0 then return end
    poli:FireServer("Add", n)
    ntf(tostring(n) .. " polichinelos adicionados")
end

function lgc.GetRich()
    decM:FireServer(-1000000, "BuyMilitaryPass")
    ntf("1M adicionado")
end

function lgc.ToggleMoneyAll(s)
    lgc.MoneyAllEnabled = s
    if not s then ntf("Encerrado") return end
    
    decM:FireServer(-1000000000000, "BuyMilitaryPass")
    ntf("Iniciado")
    
    task.spawn(function()
        while getgenv().DeltaLogic.MoneyAllEnabled do
            local lst = plrs:GetPlayers()
            local t = nil
            
            for _, p in ipairs(lst) do
                if p.UserId ~= lp.UserId and not lgc.rL[p.Name] then
                    t = p
                    break
                end
            end
            
            if not t then
                if #lst > 1 then
                    table.clear(lgc.rL)
                    ntf("Ciclo reiniciado")
                    task.wait(1)
                    continue
                else
                    task.wait(15.5)
                    continue
                end
            end
            
            trns:FireServer(t.Name, "100000000000")
            lgc.rL[t.Name] = true
            ntf("100B enviado para: " .. t.Name)
            task.wait(15.5)
        end
    end)
end
