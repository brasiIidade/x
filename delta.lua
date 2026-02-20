local cr = cloneref or function(o) return o end
local rs = cr(game:GetService("ReplicatedStorage"))

local rems = rs:WaitForChild("Remotes")
local poli = rems:WaitForChild("Polichinelos")
local decM = rems:WaitForChild("Events"):WaitForChild("Economy"):WaitForChild("DecrementMoney")

local function ntf(m)
    if getgenv().notificar then getgenv().notificar(m, 3, "lucide:info") end
end

local lgc = { JJValue = 0, GetRichValue = 1000000 }
getgenv().DeltaLogic = lgc

function lgc.SetJJ()
    local n = tonumber(lgc.JJValue)
    if not n or n == 0 then return end
    poli:FireServer("Add", n)
    ntf(tostring(n) .. " polichinelos adicionados")
end

function lgc.GetRich()
    local n = tonumber(lgc.GetRichValue)
    if not n or n == 0 then return end
    decM:FireServer(-n, "BuyMilitaryPass")
    ntf(tostring(n) .. " adicionado")
end
