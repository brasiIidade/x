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
    fling_start_pos = nil,
    fake_id = math.random(1000000, 2000000000),
    connections = {} 
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

local function spoof_string(str)
    local cfg = get_cfg()
    if not cfg or not cfg.AnonEnabled or type(str) ~= "string" then return str end
    
    local fake = cfg.FakeName or "Anônimo"
    local r_name = lp.Name
    local r_display = lp.DisplayName
    
    if str:find(r_name) or str:find(r_display) then
        local safe_name = r_name:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        local safe_display = r_display:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        
        str = str:gsub(safe_name, fake)
        str = str:gsub(safe_display, fake)
    end
    
    return str
end

local function monitor_object(obj)
    if not obj then return end
    if state.connections[obj] then return end 

    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        local function update()
            local cfg = get_cfg()
            if not cfg or not cfg.AnonEnabled then return end
            
            local current = obj.Text
            local spoofed = spoof_string(current)
            
            if current ~= spoofed then
                obj.Text = spoofed
            end
        end
        
        update()
        state.connections[obj] = obj:GetPropertyChangedSignal("Text"):Connect(update)
    end
end

local function scan_ui_layer(layer)
    if not layer then return end
    
    for _, v in ipairs(layer:GetDescendants()) do
        pcall(monitor_object, v)
    end
    
    local conn = layer.DescendantAdded:Connect(function(v)
        task.wait() 
        pcall(monitor_object, v)
    end)
    table.insert(state.connections, conn)
end

local function clear_spoof()
    for _, conn in pairs(state.connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(state.connections)
end

local function update_anon_visuals()
    local cfg = get_cfg()
    if not cfg then return end
    
    if cfg.AnonEnabled then
        local char = lp.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                if hum.DisplayName ~= cfg.FakeName then
                    hum.DisplayName = cfg.FakeName
                end
                
                local conn = hum:GetPropertyChangedSignal("DisplayName"):Connect(function()
                    if cfg.AnonEnabled and hum.DisplayName ~= cfg.FakeName then
                        hum.DisplayName = cfg.FakeName
                    end
                end)
                table.insert(state.connections, conn)
            end
        end
        
        scan_ui_layer(lp:WaitForChild("PlayerGui"))
        pcall(function() scan_ui_layer(srv.CoreGui) end)
        if char then scan_ui_layer(char) end
    else
        clear_spoof()
        local char = lp.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.DisplayName = lp.DisplayName end
        end
    end
end

local function toggle_invis(bool)
    local root = get_root(lp)
    if not root then return end
    
    if bool then
        local saved_cf = root.CFrame
        local old_cam = cam.CameraType
        
        cam.CameraType = Enum.CameraType.Scriptable
        root.CFrame = cf(-25.95, 84, 3537.55)
        task.wait(0.15)
        
        local s = inst("Seat")
        s.Name = srv.HttpService:GenerateGUID(false)
        s.Transparency = 1
        s.CanCollide = false
        s.Anchored = false
        s.Position = v3(-25.95, 84, 3537.55)
        s.Parent = srv.Workspace
        
        local w = inst("Weld")
        w.Part0 = s
        w.Part1 = lp.Character:FindFirstChild("Torso") or lp.Character:FindFirstChild("UpperTorso")
        w.Parent = s
        
        state.seat = s
        state.weld = w
        
        task.wait()
        s.CFrame = saved_cf
        cam.CameraType = old_cam
        
        for _, v in ipairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0.5
            elseif v:IsA("Decal") then
                v.Transparency = 0.5
            end
        end
    else
        if state.seat then state.seat:Destroy() end
        state.seat = nil
        
        for _, v in ipairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0
            elseif v:IsA("Decal") then
                v.Transparency = 0
            end
        end
    end
end

local function stop_fling(restore_pos)
    local cfg = get_cfg()
    if cfg then cfg.FlingActive = false end

    if state.fling_conn then 
        state.fling_conn:Disconnect() 
        state.fling_conn = nil
    end
    
    local root = get_root(lp)
    if root then
        root.Velocity = v3(0,0,0)
        root.RotVelocity = v3(0,0,0)
        if restore_pos and state.fling_start_pos then
            root.CFrame = state.fling_start_pos
        end
    end
    state.fling_start_pos = nil
end

local function start_fling(target_name)
    stop_fling(false)
    
    local target = find_player(target_name)
    if not target then return end
    
    local my_root = get_root(lp)
    if my_root then
        state.fling_start_pos = my_root.CFrame
    end

    local start_time = tick()

    state.fling_conn = srv.RunService.Heartbeat:Connect(function()
        local cfg = get_cfg()
        
        if tick() - start_time >= 2 then
            stop_fling(true)
            return
        end
        
        if not cfg.FlingActive or not target or not target.Character or not lp.Character then
            stop_fling(true)
            return
        end
        
        local t_root = target.Character:FindFirstChild("HumanoidRootPart")
        local my_curr_root = lp.Character:FindFirstChild("HumanoidRootPart")
        
        if t_root and my_curr_root then
            my_curr_root.CFrame = cf(t_root.Position + v3(0, -1, 0)) * CFrame.Angles(-math.pi/2, 0, 0)
            local god_force = v3(0, 10000, 0)
            my_curr_root.Velocity = god_force
            my_curr_root.RotVelocity = god_force
            pcall(function()
                sethiddenproperty(my_curr_root, 'PhysicsRepRootPart', t_root)
            end)
        else
            stop_fling(true)
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
    
    if get_cfg().AnonEnabled then
        scan_ui_layer(char)
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
        toggle_invis(true)
    end
    
    if cfg.AnonEnabled then
        task.wait(1)
        update_anon_visuals()
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
    if not cfg or not cfg.Noclip then return end
    
    local c = lp.Character
    if c then
        local parts = c:GetDescendants()
        for i = 1, #parts do
            local v = parts[i]
            if v:IsA("BasePart") and v.CanCollide then 
                v.CanCollide = false 
            end
        end
    end
end)

local mt = getrawmetatable(game)
local old_idx = mt.__index
local old_newidx = mt.__newindex
local old_nc = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(self, k)
    if not checkcaller() then
        local cfg = get_cfg()
        if cfg then
            if self == lp and cfg.AnonEnabled then
                if k == "UserId" then return state.fake_id end
                if k == "Name" then return cfg.FakeName end
                if k == "DisplayName" then return cfg.FakeName end
            end
            
            if self:IsA("Humanoid") then
                if k == "WalkSpeed" and cfg.SpeedEnabled then return 16 end
                if k == "JumpPower" and cfg.JumpEnabled then return 50 end
            end
        end
    end
    return old_idx(self, k)
end)

mt.__newindex = newcclosure(function(self, k, v)
    if not checkcaller() then
        local cfg = get_cfg()
        if cfg and cfg.AnonEnabled then
            if k == "Text" and type(v) == "string" then
                return old_newidx(self, k, spoof_string(v))
            end
        end
    end
    return old_newidx(self, k, v)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local cfg = get_cfg()
    
    if not checkcaller() and cfg and cfg.AnonEnabled then
        if method == "SetCore" and args[1] == "SendNotification" then
            local data = args[2]
            if type(data) == "table" then
                if data.Title then data.Title = spoof_string(data.Title) end
                if data.Text then data.Text = spoof_string(data.Text) end
                return old_nc(self, unpack(args))
            end
        end
    end
    
    return old_nc(self, ...)
end)

setreadonly(mt, true)

if srv.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    srv.TextChatService.OnIncomingMessage = function(msg)
        local cfg = get_cfg()
        local props = inst("TextChatMessageProperties")
        
        if cfg and cfg.AnonEnabled then
            if msg.TextSource and msg.TextSource.UserId == lp.UserId then
                local display = cfg.FakeName or "Anônimo"
                props.PrefixText = string.format("<font color='#F5CD30'>[%s]</font>", display)
            else
                props.PrefixText = spoof_string(msg.PrefixText)
            end
        end
        return props
    end
end

task.spawn(function()
    local last_anon_state = false
    local last_invis_state = false

    while task.wait(0.1) do
        local cfg = get_cfg()
        if not cfg then continue end
        
        if cfg.TriggerFling then
            cfg.TriggerFling = false
            cfg.FlingActive = true
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
        
        if cfg.InvisEnabled ~= last_invis_state then
            last_invis_state = cfg.InvisEnabled
            toggle_invis(cfg.InvisEnabled)
        end
        
        if cfg.AnonEnabled ~= last_anon_state then
            last_anon_state = cfg.AnonEnabled
            update_anon_visuals()
        end
    end
end)
