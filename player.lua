local cr = cloneref or function(o) return o end

local plrs = cr(game:GetService("Players"))
local rs = cr(game:GetService("RunService"))
local ws = cr(game:GetService("Workspace"))
local cg = cr(game:GetService("CoreGui"))
local tcs = cr(game:GetService("TextChatService"))
local hs = cr(game:GetService("HttpService"))

local lp = plrs.LocalPlayer
local cam = ws.CurrentCamera
local env = getgenv()

local v3 = Vector3.new
local cf = CFrame.new
local inst = Instance.new

if not isfolder("michigun.xyz") then makefolder("michigun.xyz") end

--[[PLAYER]]
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
    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= lp then
            local pn = p.Name:lower()
            local pd = p.DisplayName:lower()
            if pn:sub(1, #str) == str or pd:sub(1, #str) == str then
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
        if not state.connections[obj] then
            state.connections[obj] = obj:GetPropertyChangedSignal("Text"):Connect(update)
        end
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
    if not state.connections[conn] then
        table.insert(state.connections, conn)
    end
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
        pcall(function() scan_ui_layer(cg) end)
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

local function set_transparency(trans)
    for _, v in ipairs(lp.Character:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.Transparency = trans
        elseif v:IsA("Decal") then
            v.Transparency = trans
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
        s.Name = hs:GenerateGUID(false)
        s.Transparency = 1
        s.CanCollide = false
        s.Anchored = false
        s.Position = v3(-25.95, 84, 3537.55)
        s.Parent = ws
        
        local w = inst("Weld")
        w.Part0 = s
        w.Part1 = lp.Character:FindFirstChild("Torso") or lp.Character:FindFirstChild("UpperTorso")
        w.Parent = s
        
        state.seat = s
        state.weld = w
        
        task.wait()
        s.CFrame = saved_cf
        cam.CameraType = old_cam
        
        set_transparency(0.5)
    else
        if state.seat then state.seat:Destroy() end
        state.seat = nil
        set_transparency(0)
    end
end

local function stop_fling(restore_pos)
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
    
    if restore_pos then 
        state.fling_start_pos = nil 
        local cfg = get_cfg()
        if cfg then cfg.FlingActive = false end
    end
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

    state.fling_conn = rs.Heartbeat:Connect(function()
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
            my_curr_root.CFrame = cf(t_root.Position + v3(0, -1, 0)) * CFrame.Angles(-1.5707963267948966, 0, 0)
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

rs.RenderStepped:Connect(function()
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

rs.Stepped:Connect(function()
    local cfg = get_cfg()
    if not cfg or not cfg.Noclip then return end
    
    local c = lp.Character
    if c then
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then 
                v.CanCollide = false 
            end
        end
    end
end)

local OldIdx
OldIdx = hookmetamethod(game, "__index", newcclosure(function(self, k)
    if not checkcaller() then
        local cfg = get_cfg()
        if cfg and cfg.AnonEnabled and self == lp then
            if k == "UserId" then return state.fake_id end
            if k == "Name" then return cfg.FakeName end
            if k == "DisplayName" then return cfg.FakeName end
        end
    end
    return OldIdx(self, k)
end))

local OldNewIdx
OldNewIdx = hookmetamethod(game, "__newindex", newcclosure(function(self, k, v)
    if not checkcaller() then
        local cfg = get_cfg()
        if cfg and cfg.AnonEnabled and k == "Text" and type(v) == "string" then
            return OldNewIdx(self, k, spoof_string(v))
        end
    end
    return OldNewIdx(self, k, v)
end))

local OldNc
OldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local cfg = get_cfg()
    
    if not checkcaller() and cfg and cfg.AnonEnabled then
        if method == "SetCore" and args[1] == "SendNotification" then
            local data = args[2]
            if type(data) == "table" then
                if data.Title then data.Title = spoof_string(data.Title) end
                if data.Text then data.Text = spoof_string(data.Text) end
                return OldNc(self, unpack(args))
            end
        end
    end
    
    return OldNc(self, ...)
end))

if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
    tcs.OnIncomingMessage = function(msg)
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


--[[CHAR]]
env.Avatar = env.Avatar or {}
local av = env.Avatar

av.TargetInput = ""
av.CurrentAppliedId = (lp and lp.UserId) or 0
av.SkinFolder = "michigun.xyz/skins"

if not isfolder(av.SkinFolder) then makefolder(av.SkinFolder) end

local function s_ton(v) return v and tonumber(v) or nil end

local function morph(c, fn, fid, d)
    if not c then return end
    if lp and c == lp.Character then av.CurrentAppliedId = fid or av.CurrentAppliedId end
    
    task.spawn(function()
        pcall(function()
            task.wait(0.3)
            local h = c:WaitForChild("Humanoid", 10)
            if not h then return end
            
            for _, v in ipairs(c:GetDescendants()) do
                if v:IsA("Accessory") or v:IsA("Hat") then v:Destroy() end
            end
            
            for _, v in ipairs(c:GetChildren()) do
                if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") then v:Destroy() end
            end
            
            local bc = h:FindFirstChildOfClass("BodyColors")
            if bc then bc:Destroy() end
            
            for _, l in ipairs({"Torso","Left Arm","Right Arm","Left Leg","Right Leg"}) do
                local p = c:FindFirstChild(l)
                if p then
                    for _, v in ipairs(p:GetChildren()) do if v:IsA("SpecialMesh") then v:Destroy() end end
                end
            end
            
            local hd = c:FindFirstChild("Head")
            if hd then
                local m = hd:FindFirstChildOfClass("SpecialMesh")
                if m then m.MeshId = "" m.TextureId = "" end
            end
            
            task.wait(0.1)
            if d then h:ApplyDescriptionClientServer(d) end
        end)
    end)
end

av.ApplySkin = function(tgt)
    if not lp or not lp.Character then return end
    local fn = tgt or ""
    if fn == "" then return end
    local fid = s_ton(fn)
    local s = pcall(function()
        if fid then fn = plrs:GetNameFromUserIdAsync(fid)
        else fid = plrs:GetUserIdFromNameAsync(fn) fn = plrs:GetNameFromUserIdAsync(fid) end
    end)
    if s and fid then
        local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(fid) end)
        if k and d then morph(lp.Character, fn, fid, d) end
    end
end

av.ApplySkinToOther = function(tn, si, sf)
    local tp = find_player(tn)
    if not tp or not tp.Character then return end
    local fid, fn = nil, si
    if sf then
        local s, sd = pcall(function() return readfile(av.SkinFolder .. "/" .. si .. ".txt") end)
        if s and sd then fid = s_ton(sd) fn = "SavedSkin" else return end
    else
        fid = s_ton(fn)
        local k = pcall(function()
            if fid then fn = plrs:GetNameFromUserIdAsync(fid)
            else fid = plrs:GetUserIdFromNameAsync(fn) fn = plrs:GetNameFromUserIdAsync(fid) end
        end)
        if not k then return end
    end
    if fid then
        local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(fid) end)
        if k and d then morph(tp.Character, fn, fid, d) end
    end
end

av.RestoreOther = function(tn)
    local tp = find_player(tn)
    if not tp or not tp.Character then return end
    local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(tp.UserId) end)
    if k and d then morph(tp.Character, tp.Name, tp.UserId, d) end
end

av.RestoreSkin = function()
    if not lp or not lp.Character then return end
    local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(lp.UserId) end)
    if k and d then morph(lp.Character, lp.Name, lp.UserId, d) end
end

av.GetSavedSkins = function()
    local s, f = pcall(listfiles, av.SkinFolder)
    if not s or not f then return {{Title="Erro ao ler pasta", Icon="lucide:alert-triangle"}} end
    local o = {}
    for _, v in ipairs(f) do
        local n = v:match("([^\\/]+)%.txt$")
        if n then table.insert(o, {Title=n, Icon="lucide:user"}) end
    end
    if #o == 0 then table.insert(o, {Title="Nenhuma salva", Icon="lucide:frown"}) end
    return o
end

av.SaveSkin = function(cn)
    local i = av.CurrentAppliedId or 0
    local n = (cn ~= "" and cn:gsub("[^%w%s]", "")) or "Skin_" .. i
    writefile(av.SkinFolder .. "/" .. n .. ".txt", tostring(i))
end

av.LoadSkin = function(n)
    if not lp or not lp.Character then return end
    local s, sd = pcall(function() return readfile(av.SkinFolder .. "/" .. n .. ".txt") end)
    if s and sd then
        local ni = s_ton(sd)
        if ni then
            local k, d = pcall(function() return plrs:GetHumanoidDescriptionFromUserId(ni) end)
            if k and d then morph(lp.Character, n, ni, d) end
        end
    end
end

av.DeleteSkin = function(n)
    local p = av.SkinFolder .. "/" .. n .. ".txt"
    if isfile(p) then delfile(p) end
end