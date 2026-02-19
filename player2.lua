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
local mouse = lp:GetMouse()
local cam = srv.Workspace.CurrentCamera

local v3 = Vector3.new
local cf = CFrame.new
local inst = Instance.new

local state = {
    last_pos = nil,
    death_pos = nil,
    seat = nil,
    weld = nil,
    view_conn = nil,
    fling_conn = nil,
    noclip_conn = nil,
    spoofed_objs = setmetatable({}, {__mode = "k"})
}

local function get_cfg()
    return getgenv().PlayerConfig
end

local function get_char(p)
    return p.Character or p.CharacterAdded:Wait()
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

local function spoof_text(text)
    local cfg = get_cfg()
    if not cfg.AnonEnabled or type(text) ~= "string" then return text end
    
    local safe_name = lp.Name:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local safe_display = lp.DisplayName:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    
    local res = text
    if res:find(lp.Name) then res = res:gsub(safe_name, cfg.FakeName) end
    if res:find(lp.DisplayName) then res = res:gsub(safe_display, cfg.FakeName) end
    return res
end

local function update_ui_nodes(parent)
    for _, v in ipairs(parent:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
            if not state.spoofed_objs[v] then
                state.spoofed_objs[v] = v.Text
                v:GetPropertyChangedSignal("Text"):Connect(function()
                    local cfg = get_cfg()
                    if cfg.AnonEnabled then
                        local raw = v.Text
                        local clean = spoof_text(raw)
                        if raw ~= clean then v.Text = clean end
                    end
                end)
            end
            v.Text = spoof_text(v.Text)
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
        root.CFrame = cf(-25.95, 84, 3537.55) -- Void safe zone
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

local function start_fling(target_name)
    if state.fling_conn then state.fling_conn:Disconnect() end
    
    local target = find_player(target_name)
    if not target then return end
    
    state.fling_conn = srv.RunService.Heartbeat:Connect(function()
        local cfg = get_cfg()
        if not cfg.FlingActive or not target.Character then
            state.fling_conn:Disconnect()
            local r = get_root(lp)
            if r then r.Velocity = v3(0,0,0) r.RotVelocity = v3(0,0,0) end
            return 
        end
        
        local my_root = get_root(lp)
        local t_root = target.Character:FindFirstChild("HumanoidRootPart")
        
        if my_root and t_root then
            my_root.CFrame = cf(t_root.Position) * cf(0, -1, 0)
            my_root.Velocity = v3(0, 100000, 0)
            my_root.RotVelocity = v3(0, 10000, 0)
        end
    end)
end

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
        else
            cfg.SpectateActive = false
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

lp.CharacterAdded:Connect(function(c)
    local cfg = get_cfg()
    local hum = c:WaitForChild("Humanoid", 10)
    
    if hum then
        hum.Died:Connect(function()
            if cfg.RespawnEnabled then
                local r = c:FindFirstChild("HumanoidRootPart")
                if r then state.death_pos = r.CFrame end
            end
        end)
    end
    
    if cfg.RespawnEnabled and state.death_pos then
        local r = c:WaitForChild("HumanoidRootPart", 10)
        if r then
            task.wait(0.2)
            r.CFrame = state.death_pos
            state.death_pos = nil
        end
    end
    
    if cfg.InvisEnabled then
        task.wait(0.5)
        toggle_invis(true)
    end
    
    if cfg.AnonEnabled then
        task.wait(1)
        update_ui_nodes(c)
    end
end)

local mt = getrawmetatable(game)
local old_idx = mt.__index
local old_nc = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(self, k)
    if not checkcaller() then
        local cfg = get_cfg()
        if cfg and self:IsA("Humanoid") then
            if k == "WalkSpeed" and cfg.SpeedEnabled then return 16 end
            if k == "JumpPower" and cfg.JumpEnabled then return 50 end
        end
    end
    return old_idx(self, k)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local cfg = get_cfg()
    
    if not checkcaller() and cfg and cfg.AnonEnabled then
        if method == "SetCore" and args[1] == "SendNotification" then
            local data = args[2]
            if type(data) == "table" then
                if data.Title then data.Title = spoof_text(data.Title) end
                if data.Text then data.Text = spoof_text(data.Text) end
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
                props.PrefixText = string.format("<font color='#F5CD30'>[%s]</font>", cfg.FakeName)
            else
                props.PrefixText = spoof_text(msg.PrefixText)
            end
        end
        return props
    end
end

task.spawn(function()
    while task.wait(0.5) do
        local cfg = get_cfg()
        if not cfg then continue end
        
        if cfg.TriggerFling then
            cfg.TriggerFling = false
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
        
        if cfg.InvisEnabled ~= (state.seat ~= nil) then
            toggle_invis(cfg.InvisEnabled)
        end
        
        if cfg.AnonEnabled then
            update_ui_nodes(lp:WaitForChild("PlayerGui"))
            pcall(function() update_ui_nodes(srv.CoreGui) end)
        end
    end
end)
