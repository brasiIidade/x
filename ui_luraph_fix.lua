-- Este arquivo deve ser executado DEPOIS da UI e DO TAS
-- Place this after your UI code loads

task.wait(2) -- Espera 2 segundos para garantir que tudo foi carregado

-- Corrige o acesso ao TAS na UI
-- Substitui getgenv().TAS por getgenv().TAS ou _G.TAS

local env = getgenv()

-- Garante que TAS está acessível
if not env.TAS and _G.TAS then
    env.TAS = _G.TAS
    print("[UI Fix] TAS restaurado de _G")
end

if not env.JJs and _G.JJs then
    env.JJs = _G.JJs
    print("[UI Fix] JJs restaurado de _G")
end

if not env.F3X and _G.F3X then
    env.F3X = _G.F3X
    print("[UI Fix] F3X restaurado de _G")
end

print("[UI Fix] Correções de acesso aplicadas")