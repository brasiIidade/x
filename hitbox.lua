local function f(m)print(m)task.wait(.5)local function c()return c()end c()end local r,cn=0,game:GetService("RunService").Heartbeat:Connect(function()r=r+1 end)repeat task.wait()until r>=2 cn:Disconnect()if not getmetatable or not setmetatable or not type or not select or type(select(2,pcall(getmetatable,setmetatable({},{__index=function()while 1 do end end})))['__index'])~='function' or not pcall or not debug or not rawget or not rawset or not pcall(rawset,{}," "," ") or getmetatable(require) or getmetatable(print) or getmetatable(error) or({debug.info(print,'a')})[1]~=0 or({debug.info(tostring,'a')})[1]~=0 or({debug.info(print,'a')})[2]~=true or not select or not getfenv or select(1,pcall(getfenv,69))==true or not select(2,pcall(rawget,debug,"info")) or #(((select(2,pcall(rawget,debug,"info")))(getfenv,"n")))<=1 or #(((select(2,pcall(rawget,debug,"info")))(print,"n")))<=1 or not(select(2,pcall(rawget,debug,"info")))(print,"s")=="[C]" or not(select(2,pcall(rawget,debug,"info")))(require,"s")=="[C]" or(select(2,pcall(rawget,debug,"info")))((function()end),"s")=="[C]" or not select(1,pcall(debug.info,coroutine.wrap(function()end)(),'s'))==false then f("skid de EB :(")end if not game.ServiceAdded or getfenv()[Instance.new("Part")] or getmetatable(__call)then f("skid de EB :(")end if pcall(function()Instance.new("Part"):B("a")end)then f("skid de EB :(")end local s,res=pcall(function()return game:GetService("HttpService"):JSONDecode('[42,"",false,1,true,[1,"",null],null,["",1,true],{"k":1},[null,["",1,false]]]')end)if not s or res[6][3]~=nil then f("skid de EB :(")end local _,m=pcall(function()game()end)if not m:find("attempt to call a Instance value")or #game:GetChildren()<=4 then f("skid de EB :(")end

local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local run = cr(game:GetService("RunService"))
local core = cr(game:GetService("CoreGui"))
local http = cr(game:GetService("HttpService"))

local lp = plrs.LocalPlayer
local find = game.FindFirstChild
local is_a = game.IsA
local get_genv = getgenv
local v3_new = Vector3.new
local c3_new = Color3.new
local inst_new = Instance.new

local salvos = {} 
local luzes = {} 

local function pega_cfg()
    return get_genv().HitboxConfig
end

local function protecao(c)
    if not c then return false end
    local itens = c:GetChildren()
    for i = 1, #itens do
        local v = itens[i]
        if is_a(v, "Tool") then
            local n = v.Name:lower()
            if n:find("escudo") or n:find("shield") then
                return true
            end
        end
    end
    return false
end

local function limpa(p)
    local dados = salvos[p]
    if dados then
        local char = p.Character
        local root = char and find(char, "HumanoidRootPart")
        if root then
            root.Size = dados.s
            root.Transparency = dados.t
            root.Shape = dados.sh
            root.CanCollide = dados.c
            root.Material = dados.m
            root.Color = dados.co
        end
        salvos[p] = nil
    end
    
    if luzes[p] then
        luzes[p]:Destroy()
        luzes[p] = nil
    end
end

local function valida(p)
    local cfg = pega_cfg()
    if not cfg or not cfg.Enabled or p == lp then return false end
    
    if table.find(cfg.WhitelistedUsers, p.Name) then return false end
    if p.Team and table.find(cfg.WhitelistedTeams, p.Team.Name) then return false end
    
    if cfg.FocusMode and not table.find(cfg.FocusList, p.Name) then return false end
    
    local char = p.Character
    if not char then return false end
    
    local hum = find(char, "Humanoid")
    local root = find(char, "HumanoidRootPart")
    
    if not hum or not root or hum.Health <= 0 then return false end
    
    if cfg.TeamCheck and p.Team and lp.Team and p.Team == lp.Team then
        return false
    end
    
    if cfg.TeamFilterEnabled and #cfg.SelectedTeams > 0 then
        local t_nome = p.Team and p.Team.Name or ""
        local ok = false
        for _, t in ipairs(cfg.SelectedTeams) do
            if t == t_nome then ok = true break end
        end
        if not ok then return false end
    end
    
    if cfg.HideOnShield and protecao(char) then
        return false
    end
    
    return true
end

local loop = run.Heartbeat:Connect(function()
    local cfg = pega_cfg()
    
    if not cfg or not cfg.Enabled then
        for p, _ in pairs(salvos) do limpa(p) end
        return
    end

    local lista = plrs:GetPlayers()
    for i = 1, #lista do
        local p = lista[i]
        
        if valida(p) then
            local root = p.Character.HumanoidRootPart
            
            if not salvos[p] then
                salvos[p] = {
                    s = root.Size,
                    t = root.Transparency,
                    sh = root.Shape,
                    c = root.CanCollide,
                    m = root.Material,
                    co = root.Color
                }
            end
            
            root.Size = cfg.Size
            root.Transparency = cfg.Transparency
            root.Shape = cfg.Shape
            root.CanCollide = false
            root.Material = Enum.Material.ForceField
            
            if cfg.Transparency < 1 then
                if not luzes[p] then
                    local h = inst_new("Highlight")
                    h.Name = http:GenerateGUID(false)
                    h.Adornee = root
                    h.FillTransparency = cfg.Transparency
                    h.OutlineTransparency = cfg.Transparency
                    h.FillColor = p.TeamColor.Color
                    local suc, tar = pcall(gethui)
                    h.Parent = (suc and tar) and tar or core
                    luzes[p] = h
                else
                    luzes[p].Adornee = root
                    luzes[p].FillTransparency = cfg.Transparency
                    luzes[p].OutlineTransparency = cfg.Transparency
                    luzes[p].FillColor = p.TeamColor.Color
                end
            elseif luzes[p] then
                luzes[p]:Destroy()
                luzes[p] = nil
            end
        else
            limpa(p)
        end
    end
end)

plrs.PlayerRemoving:Connect(limpa)
