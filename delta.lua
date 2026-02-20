local function f(m)print(m)task.wait(.5)local function c()return c()end c()end local r,cn=0,game:GetService("RunService").Heartbeat:Connect(function()r=r+1 end)repeat task.wait()until r>=2 cn:Disconnect()if not getmetatable or not setmetatable or not type or not select or type(select(2,pcall(getmetatable,setmetatable({},{__index=function()while 1 do end end})))['__index'])~='function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or({debug.info(print,'a')})[1]~=0 or({debug.info(tostring,'a')})[1]~=0 or({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1,pcall(getfenv,69))==true or not select(2,pcall(rawget,debug,"info")) or #(((select(2,pcall(rawget,debug,"info")))(getfenv,"n")))<=1 or #(((select(2,pcall(rawget,debug,"info")))(print,"n")))<=1 or not(select(2,pcall(rawget,debug,"info")))(print,"s")=="[C]" or not(select(2,pcall(rawget,debug,"info")))(require,"s")=="[C]" or(select(2,pcall(rawget,debug,"info")))((function()end),"s")=="[C]" or not select(1,pcall(debug.info,coroutine.wrap(function()end)(),'s'))==false then f("skid de EB :(")end if not game.ServiceAdded or getfenv()[Instance.new("Part")] or getmetatable(__call)then f("skid de EB :(")end if pcall(function()Instance.new("Part"):B("a")end)then f("skid de EB :(")end local s,res=pcall(function()return game:GetService("HttpService"):JSONDecode('[42,"",false,1,true,[1,"",null],null,["",1,true],{"k":1},[null,["",1,false]]]')end)if not s or res[6][3]~=nil then f("skid de EB :(")end local _,m=pcall(function()game()end)if not m:find("attempt to call a Instance value")or #game:GetChildren()<=4 then f("skid de EB :(")end

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
