local function mkCloneMarker(cf)
    local bc = Color3.fromRGB(0, 200, 255)
    local adornments = {}

    local function mkM(nm, sz, c_frame, isC)
        local p = isC and Instance.new("CylinderHandleAdornment") or Instance.new("BoxHandleAdornment")
        if isC then p.Radius, p.Height = sz.X, sz.Y else p.Size = sz end
        p.Name, p.CFrame, p.Color3, p.Transparency, p.Adornee, p.ZIndex, p.Parent = nm, c_frame, bc, 0, workspace.Terrain, 1, workspace.Terrain
        table.insert(adornments, p)
        return p
    end

    mkM("Tor", Vector3.new(2, 2, 1), cf, false)
    mkM("LLg", Vector3.new(1, 2, 1), cf * CFrame.new(-0.5, -2, 0), false)
    mkM("RLg", Vector3.new(1, 2, 1), cf * CFrame.new(0.5, -2, 0), false)
    mkM("LAm", Vector3.new(1, 2, 1), cf * CFrame.new(-1.5, 0, 0), false)
    mkM("RAm", Vector3.new(1, 2, 1), cf * CFrame.new(1.5, 0.5, -1) * CFrame.Angles(math.rad(90), 0, 0), false)

    return {
        Destroy = function()
            for _, a in ipairs(adornments) do
                if a and a.Parent then a:Destroy() end
            end
            adornments = {}
        end
    }
end

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp               = game.Players.LocalPlayer
local cam              = workspace.CurrentCamera

local function setNoclip(enabled)
    getgenv().PlayerConfig.Noclip = enabled
end

local startCF = CFrame.new(1635, 1, -105)
local tpCF    = CFrame.new(1633, 1, -127) * CFrame.Angles(0, math.rad(90), 0)
local endCF   = CFrame.new(1633, 1, -129.5)

local tpSequence = {
    CFrame.new(1633, 1, -135),
    CFrame.new(1640, 1, -145),
    CFrame.new(1650, 1, -155),
    CFrame.new(1650, 1, -165),
}

-- Waypoint: seta na borda da tela apontando para o clone
local gh = gethui or function() return game:GetService("CoreGui") end

local wpGui = Instance.new("ScreenGui")
wpGui.Name            = "_routeWp"
wpGui.ResetOnSpawn    = false
wpGui.IgnoreGuiInset  = true
wpGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
wpGui.Parent          = gh()

local arrowLbl = Instance.new("TextLabel")
arrowLbl.Size                   = UDim2.new(0, 40, 0, 40)
arrowLbl.AnchorPoint            = Vector2.new(0.5, 0.5)
arrowLbl.BackgroundTransparency = 1
arrowLbl.TextColor3             = Color3.fromRGB(0, 200, 255)
arrowLbl.TextStrokeTransparency = 0
arrowLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
arrowLbl.TextScaled             = true
arrowLbl.Font                   = Enum.Font.GothamBold
arrowLbl.Text                   = "▲"
arrowLbl.ZIndex                 = 10
arrowLbl.Parent                 = wpGui

local distLbl = Instance.new("TextLabel")
distLbl.Size                   = UDim2.new(0, 60, 0, 20)
distLbl.AnchorPoint            = Vector2.new(0.5, 0)
distLbl.BackgroundTransparency = 1
distLbl.TextColor3             = Color3.fromRGB(0, 200, 255)
distLbl.TextStrokeTransparency = 0
distLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
distLbl.TextScaled             = true
distLbl.Font                   = Enum.Font.GothamBold
distLbl.ZIndex                 = 10
distLbl.Parent                 = wpGui

local MARGIN = 50

local wpConn = RunService.Heartbeat:Connect(function()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local vp   = cam.ViewportSize
    local cx   = vp.X / 2
    local cy   = vp.Y / 2

    local target = startCF.Position + Vector3.new(0, 3, 0)
    local sp, vis = cam:WorldToViewportPoint(target)
    local dist = math.floor((hrp.Position - startCF.Position).Magnitude)
    distLbl.Text = dist .. "m"

    local sx, sy = sp.X, sp.Y

    -- se atrás da câmera, inverte
    if not vis then sx = vp.X - sx; sy = vp.Y - sy end

    local dx = sx - cx
    local dy = sy - cy
    local angle = math.atan2(dx, -dy)

    -- se visível e dentro da tela com margem
    if vis and sx > MARGIN and sx < vp.X - MARGIN and sy > MARGIN and sy < vp.Y - MARGIN then
        arrowLbl.Rotation = 0
        arrowLbl.Position = UDim2.fromOffset(sx, sy - 30)
        distLbl.Position  = UDim2.fromOffset(sx, sy + 14)
    else
        -- projeta na borda
        local absDx = math.abs(dx)
        local absDy = math.abs(dy)
        local scale = math.min((cx - MARGIN) / (absDx + 1e-4), (cy - MARGIN) / (absDy + 1e-4))
        local bx = cx + dx * scale
        local by = cy + dy * scale
        arrowLbl.Rotation = math.deg(angle)
        arrowLbl.Position = UDim2.fromOffset(bx, by)
        distLbl.Position  = UDim2.fromOffset(bx, by + 24)
    end

    -- pisca quando perto
    arrowLbl.TextTransparency = (dist < 10 and tick() % 0.4 < 0.2) and 0.6 or 0
end)

local function clearGuide()
    if wpConn then wpConn:Disconnect(); wpConn = nil end
    if wpGui and wpGui.Parent then wpGui:Destroy() end
end


local function showBlackscreen()
    local bsGui = Instance.new("ScreenGui")
    bsGui.Name            = "_bs"
    bsGui.ResetOnSpawn    = false
    bsGui.IgnoreGuiInset  = true
    bsGui.DisplayOrder    = 9999
    bsGui.Parent          = gh()

    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(1, 0, 1, 0)
    frame.Position          = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel   = 0
    frame.ZIndex            = 9999
    frame.Parent            = bsGui

    -- impede que seja destruído
    local guardConn
    guardConn = frame.AncestryChanged:Connect(function()
        if not frame.Parent then
            frame.Parent = bsGui
        end
    end)
    local guardGui
    guardGui = bsGui.AncestryChanged:Connect(function()
        if not bsGui.Parent then
            bsGui.Parent = gh()
        end
    end)

    return function()
        guardConn:Disconnect()
        guardGui:Disconnect()
        task.wait(0.5)
        bsGui:Destroy()
    end
end

local marker = mkCloneMarker(startCF)

local ragdollChar = workspace:FindFirstChild(lp.Name)
local ragdoll     = ragdollChar and ragdollChar:FindFirstChild("Ragdoll")
local blockRagdoll
if ragdoll then
    blockRagdoll = ragdoll.ChildAdded:Connect(function(child)
        child:Destroy()
    end)
end

local triggered = false

local markerConn = RunService.Heartbeat:Connect(function()
    if triggered then return end
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local delta     = hrp.Position - startCF.Position
    local horizDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
    local vertDist  = math.abs(delta.Y)
    local dotAngle  = hrp.CFrame.LookVector:Dot(startCF.LookVector)

    if horizDist <= 1 and vertDist <= 1.5 and dotAngle >= math.cos(math.rad(10)) then
        triggered = true
        clearGuide()
        marker.Destroy()

        task.wait(0.5)
        local hideBlackscreen = showBlackscreen()
        hrp.CFrame = tpCF

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        setNoclip(true)

        task.spawn(function()
            task.wait(1)

            humanoid.WalkSpeed = 0.3

            local moveConn
            local endConn
            local deathConn
            local finished = false

            local function pararRota()
                if finished then return end
                finished = true
                if endConn   then endConn:Disconnect()   end
                if moveConn  then moveConn:Disconnect()  end
                if deathConn then deathConn:Disconnect() end
                humanoid:MoveTo(hrp.Position)
                humanoid.WalkSpeed = 16
                setNoclip(false)
                if blockRagdoll then blockRagdoll:Disconnect() end
                hideBlackscreen()
            end

            local function finalizarRota()
                if finished then return end
                finished = true
                if endConn   then endConn:Disconnect()   end
                if moveConn  then moveConn:Disconnect()  end
                if deathConn then deathConn:Disconnect() end
                humanoid:MoveTo(hrp.Position)
                humanoid.WalkSpeed = 16
                setNoclip(false)
                if blockRagdoll then blockRagdoll:Disconnect() end
                task.spawn(function()
                    for _, cf in ipairs(tpSequence) do
                        task.wait(0.2)
                        hrp.CFrame = cf
                    end
                    hideBlackscreen()
                end)
            end

            deathConn = humanoid.Died:Connect(function()
                setNoclip(false)
                if endConn   then endConn:Disconnect()   end
                if moveConn  then moveConn:Disconnect()  end
                if deathConn then deathConn:Disconnect() end
                if blockRagdoll then blockRagdoll:Disconnect() end
                finished = true
            end)

            lp.CharacterRemoving:Connect(function()
                setNoclip(false)
            end)

            moveConn = RunService.Heartbeat:Connect(function()
                humanoid:MoveTo(endCF.Position)
            end)

            endConn = RunService.Heartbeat:Connect(function()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) or
                   UserInputService:IsKeyDown(Enum.KeyCode.A) or
                   UserInputService:IsKeyDown(Enum.KeyCode.S) or
                   UserInputService:IsKeyDown(Enum.KeyCode.D) or
                   humanoid.MoveDirection.Magnitude > 0 then
                    pararRota()
                    return
                end

                local dist = (hrp.Position - endCF.Position).Magnitude
                if dist <= 1.6 then
                    finalizarRota()
                end
            end)
        end)
    end
end)