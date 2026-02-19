local cr = cloneref or function(o) return o end
local srv = {
    Players = cr(game:GetService("Players")),
    RunService = cr(game:GetService("RunService")),
    Workspace = cr(game:GetService("Workspace")),
    CoreGui = cr(game:GetService("CoreGui")),
    TextChatService = cr(game:GetService("TextChatService")),
    HttpService = cr(game:GetService("HttpService"))
}

local lp = srv.Players.LocalPlayer
local cam = srv.Workspace.CurrentCamera

local v3 = Vector3.new
local cf = CFrame.new
local inst = Instance.new

local state = {
    last_pos = nil,
    death_cf = nil,
    seat = nil,
    weld = nil,
    fling_conn = nil,
    spoofed_objs = setmetatable({}, {__mode = "k"})
}

local function get_cfg()
    return getgenv().PlayerConfig
end

local function get_root(p)
    local c = p.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function get_hum(p)
    local c = p.Character
    return c and c:FindFirstChild("Humanoid")
end

local function find_player(str)
    if not str or str == "" then return nil end
    str = str:lower()
    for _, p in ipairs(srv.Players:GetPlayers()) do
        if p ~= lp then
            if p.Name:lower():sub(1, #str) == str or p.DisplayName:lower():sub(1, #str) == str then
                return p
            end
        end
    end
    return nil
end

local function stop_fling()
    if state.fling_conn then 
        state.fling_conn:Disconnect() 
        state.fling_conn = nil
    end
    
    local root = get_root(lp)
    if root then
        root.Velocity = v3(0,0,0)
        root.RotVelocity = v3(0,0,0)
    end
end

local function start_fling(target_name)
    stop_fling()

    local target = find_player(target_name)
    if not target then return end
    
    local start_time = tick()
    local duration = 3.0
    
    state.fling_conn = srv.RunService.Heartbeat:Connect(function()
        local cfg = get_cfg()
        if not cfg.FlingActive or not target or not target.Character or not lp.Character then
            stop_fling()
            return
        end
        
        local t_root = target.Character:FindFirstChild("HumanoidRootPart")
        local my_root = lp.Character:FindFirstChild("HumanoidRootPart")
        
        if t_root and my_root then
            my_root.CFrame = cf(t_root.Position + v3(0, -1, 0)) * CFrame.Angles(-math.pi/2, 0, 0)
            
            local god_force = v3(0, 10000, 0)
            my_root.Velocity = god_force
            my_root.RotVelocity = god_force
            
            pcall(function()
                sethiddenproperty(my_root, 'PhysicsRepRootPart', t_root)
            end)
        else
            stop_fling()
        end
    end)
end

local function hook_character(char)
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    
    if hum and root then
        hum.Died:Connect(function()
            local cfg = get_cfg()
            if cfg.RespawnEnabled and root then
                state.death_cf = root.CFrame
            end
        end)
    end
end

lp.CharacterAdded:Connect(function(char)
    local cfg = get_cfg()
    
    if cfg.RespawnEnabled and state.death_cf then
        task.spawn(function()
            local root = char:WaitForChild("HumanoidRootPart", 10)
            if root then
                task.wait(0.2) 
                root.CFrame = state.death_cf
                root.Velocity = v3(0,0,0)
            end
        end)
    end
    
    hook_character(char)
    
    if cfg.InvisEnabled then
        task.wait(0.5)
    end
end)

if lp.Character then hook_character(lp.Character) end


srv.RunService.RenderStepped:Connect(function()
    local cfg = get_cfg()
    if not cfg then return end
    
    local hum = get_hum(lp)
    if hum then
        if cfg.SpeedEnabled then hum.WalkSpeed = cfg.SpeedVal end
        if cfg.JumpEnabled then hum.JumpPower = cfg.JumpVal hum.UseJumpPower = true end
    end
    
    if cfg.SpectateActive then
        local target = find_player(cfg.TargetPlayer)
        if target then
            local t_hum = get_hum(target)
            if t_hum then cam.CameraSubject = t_hum end
        end
    else
        if hum then cam.CameraSubject = hum end
    end
end)

srv.RunService.Stepped:Connect(function()
    local cfg = get_cfg()
    if not cfg then return end
    
    if cfg.Noclip then
        local c = lp.Character
        if c then
            for _, v in ipairs(c:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end
        end
    end
end)


task.spawn(function()
    while task.wait(0.1) do
        local cfg = get_cfg()
        if not cfg then continue end
        
        if cfg.TriggerFling then
            cfg.TriggerFling = false -- Reseta trigger
            cfg.FlingActive = true   -- Ativa estado
            start_fling(cfg.TargetPlayer)
        end
        
        if cfg.TriggerTeleport then
            cfg.TriggerTeleport = false
            local t = find_player(cfg.TargetPlayer)
            if t and t.Character then
                local r = get_root(lp)
                local tr = t.Character:FindFirstChild("HumanoidRootPart")
                if r and tr then
                    state.last_pos = r.CFrame
                    r.CFrame = tr.CFrame * cf(0, 0, 3)
                end
            end
        end
        
        if cfg.TriggerReturn then
            cfg.TriggerReturn = false
            if state.last_pos then
                local r = get_root(lp)
                if r then r.CFrame = state.last_pos end
            end
        end
    end
end)
