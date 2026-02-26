-- Este arquivo deve ser executado APÓS o treino.lua (do TAS)
-- Coloque este arquivo para executar depois do treino.lua no seu carregador

-- Verifica se o TAS existe e cria backup no _G
task.wait(1) -- Espera 1 segundo para garantir que o TAS foi carregado

local env = getgenv()
if env.TAS then
    _G.TAS = env.TAS
    print("[TAS] Backup em _G.TAS criado com sucesso")
else
    -- Tenta obter do _G se getgenv() falhou
    if _G.TAS then
        env.TAS = _G.TAS
        print("[TAS] Restaurado de _G.TAS")
    end
end

-- Mesma coisa para JJs
if env.JJs then
    _G.JJs = env.JJs
    print("[JJs] Backup em _G.JJs criado com sucesso")
end

-- Mesma coisa para F3X
if env.F3X then
    _G.F3X = env.F3X
    print("[F3X] Backup em _G.F3X criado com sucesso")
end

print("[Luraph Fix] Correções aplicadas")