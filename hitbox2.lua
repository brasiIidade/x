--// Táticas de Segurança: cloneref e Localização de Funções
local cr = cloneref or function(o) return o end
local plrs = cr(game:GetService("Players"))
local run = cr(game:GetService("RunService"))
local core = cr(game:GetService("CoreGui"))
local http = cr(game:GetService("HttpService"))

--// Cache de Métodos (Performance e Segurança)
local lp = plrs.LocalPlayer
local find = game.FindFirstChild
local is_a = game.IsA
local get_genv = getgenv
local v3_new = Vector3.new
local c3_new = Color3.new
local inst_new = Instance.new

--// Tabelas Internas
local salvos = {} 
local luzes = {} 

local function pega_cfg()
    return get_genv().HitboxConfig
end

--// Verifica proteção (escudo)
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

--// Restaura ao estado original
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

--// Validação de Alvo
local function valida(p)
    local cfg = pega_cfg()
    if not cfg or not cfg.Enabled or p == lp then return false end
    
    local char = p.Character
    if not char then return false end
    
    local hum = find(char, "Humanoid")
    local root = find(char, "HumanoidRootPart")
    
    if not hum or not root or hum.Health <= 0 then return false end
    
    -- Filtros de Time
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
    
    -- Checagem de Escudo
    if cfg.HideOnShield and protecao(char) then
        return false
    end
    
    return true
end

--// Loop de Execução (Heartbeat é mais seguro que RenderStepped para física)
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
            
            -- Aplicação da Hitbox
            root.Size = cfg.Size
            root.Transparency = cfg.Transparency
            root.Shape = cfg.Shape
            root.CanCollide = false
            root.Material = Enum.Material.ForceField
            
            -- Highlight Visual (Indetectável via CoreGui)
            if cfg.Transparency < 1 then
                if not luzes[p] then
                    local h = inst_new("Highlight")
                    h.Name = http:GenerateGUID(false)
                    h.Adornee = p.Character
                    h.FillTransparency = cfg.Transparency
                    h.OutlineTransparency = cfg.Transparency
                    h.FillColor = p.TeamColor.Color
                    h.Parent = core
                    luzes[p] = h
                else
                    luzes[p].FillTransparency = cfg.Transparency
                    luzes[p].OutlineTransparency = cfg.Transparency
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

--// Limpeza ao sair
plrs.PlayerRemoving:Connect(limpa)
