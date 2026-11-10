-- ============================================================
-- OgorodTalk Hub — universal Roblox cheat hub
-- Style: dark + lime accent (from OgorodTalk)
-- Compatibility: Solara, Delta, Codex, Fluxus, Hydrogen, Arceus X
-- Loader: loadstring(game:HttpGet("URL/hub.lua"))()
-- ============================================================

-- ============================================================
-- SAFE BOOTSTRAP (кросс-інжектор)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- PlayerGui: на Delta іноді потрібно довше
local PlayerGui
pcall(function()
    PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
end)
if not PlayerGui then
    pcall(function()
        PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end)
end

-- CoreGui: не завжди доступний (Delta блокує)
local CoreGui
pcall(function()
    CoreGui = game:GetService("CoreGui")
end)

-- Куди класти GUI
local GuiParent = PlayerGui
if CoreGui then
    local ok = pcall(function()
        local test = Instance.new("ScreenGui")
        test.Parent = CoreGui
        test:Destroy()
    end)
    if ok then GuiParent = CoreGui end
end

-- Drawing: є тільки на ПК-інжекторах
local HAS_DRAWING = false
pcall(function()
    local d = Drawing.new("Square")
    d:Remove()
    HAS_DRAWING = true
end)

-- File IO: є на Solara, часто нема на Delta
local HAS_FILE_IO = (type(writefile) == "function"
    and type(readfile) == "function"
    and type(isfile) == "function")

-- ClipBoard
local HAS_CLIPBOARD = (type(setclipboard) == "function")

-- ============================================================
-- PLATFORM
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local VIEWPORT = Camera.ViewportSize
local GUI_W = IS_MOBILE and math.min(VIEWPORT.X * 0.95, 420) or 640
local GUI_H = IS_MOBILE and math.min(VIEWPORT.Y * 0.9, 460) or 520
local BTN_H = IS_MOBILE and 40 or 32
local FONT_SIZE = IS_MOBILE and 14 or 13

-- ============================================================
-- THEME (як в OgorodTalk)
-- ============================================================
local Theme = {
    BG = Color3.fromRGB(16, 37, 27),
    PANEL = Color3.fromRGB(24, 54, 40),
    PANEL_LIGHT = Color3.fromRGB(33, 70, 50),
    LIME = Color3.fromRGB(163, 230, 53),
    LIME_HOVER = Color3.fromRGB(190, 242, 100),
    TEXT = Color3.fromRGB(243, 251, 239),
    MUTED = Color3.fromRGB(167, 199, 174),
    BORDER = Color3.fromRGB(49, 82, 61),
    BORDER_SOFT = Color3.fromRGB(40, 75, 53),
    HOVER = Color3.fromRGB(43, 87, 61),
    ERROR = Color3.fromRGB(255, 154, 154),
    ONLINE = Color3.fromRGB(34, 197, 94),
    OFFLINE = Color3.fromRGB(156, 163, 175),
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    Speed = 16, Jump = 50, Gravity = 196.2, FlySpeed = 120, FOV = 70,
    Fly = false, Noclip = false, InfJump = false, ClickTP = false, AntiAFK = true,
    ESP = false, Tracers = false, Fullbright = false, GravityOff = false,
    DoorsAutoCoins = false, DoorsAutoDrawers = false, DoorsAutoItems = false,
    DoorsSmartHide = false, DoorsHighlight = false,
    GrESP = false, GrEntityAlarm = false, GrAlarmRadius = 40, GrSafeZone = false,
    GrAutoHide = false, GrRushAlarm = false, GrFullbright = false,
    MmESP = false, MmRoleEsp = true, MmMurdererTracker = false, MmSheriffLocator = false,
    MmWeaponEsp = false, MmBodyEsp = false, MmRoleCounter = false,
    FtESP = false, FtESPItems = false, FtDragAll = false, FtAutoFling = false,
    FtFlingRadius = 30,
    FunBigHead = false, FunTinyBody = false, FunRainbow = false, FunSpin = false,
    FunGhost = false, FunInvisible = false, FunConfetti = false, FunClone = false,
    UtilServerHud = false, UtilAutoReconnect = false,
    NotifSound = true, NotifVolume = 0.5, NotifDuration = 4,
}

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "OT_Notifs"
notifGui.ResetOnSpawn = false
notifGui.Parent = GuiParent

local notifHolder = Instance.new("Frame")
notifHolder.Size = UDim2.new(0, 320, 1, -40)
notifHolder.Position = UDim2.new(1, -340, 0, 20)
notifHolder.BackgroundTransparency = 1
notifHolder.Parent = notifGui

local notifLayout = Instance.new("UIListLayout", notifHolder)
notifLayout.Padding = UDim.new(0, 8)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local notifColors = {
    success = Color3.fromRGB(34, 197, 94),
    error = Color3.fromRGB(220, 80, 80),
    warn = Color3.fromRGB(230, 190, 80),
    info = Color3.fromRGB(120, 160, 240),
}
local notifIcons = {success="✅", error="❌", warn="⚠️", info="ℹ️"}

local function playNotifSound(id)
    if not State.NotifSound then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = State.NotifVolume
        s.Parent = SoundService
        s:Play()
        game:GetService("Debris"):AddItem(s, 3)
    end)
end

local function Notify(title, text, ntype)
    ntype = ntype or "info"
    local color = notifColors[ntype] or notifColors.info
    local icon = notifIcons[ntype] or "ℹ️"

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Theme.PANEL
    card.BackgroundTransparency = 1
    card.Position = UDim2.new(1, 60, 0, 0)
    card.Parent = notifHolder
    local cc = Instance.new("UICorner", card) cc.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = color
    bar.Parent = card
    local bc = Instance.new("UICorner", bar) bc.CornerRadius = UDim.new(0, 8)

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0, 30, 1, 0)
    iconL.Position = UDim2.new(0, 8, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextSize = 20
    iconL.Font = Enum.Font.GothamBold
    iconL.TextColor3 = color
    iconL.Parent = card

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -50, 0, 22)
    titleL.Position = UDim2.new(0, 42, 0, 6)
    titleL.BackgroundTransparency = 1
    titleL.Text = "OgorodTalk • " .. tostring(title)
    titleL.TextColor3 = Theme.TEXT
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 13
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.Parent = card

    local textL = Instance.new("TextLabel")
    textL.Size = UDim2.new(1, -50, 0, 22)
    textL.Position = UDim2.new(0, 42, 0, 28)
    textL.BackgroundTransparency = 1
    textL.Text = tostring(text)
    textL.TextColor3 = Theme.MUTED
    textL.Font = Enum.Font.Gotham
    textL.TextSize = 11
    textL.TextXAlignment = Enum.TextXAlignment.Left
    textL.Parent = card

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0,
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    if ntype == "success" then playNotifSound("rbxassetid://4590662766")
    elseif ntype == "error" then playNotifSound("rbxassetid://5159527953")
    else playNotifSound("rbxassetid://4590662766") end

    task.delay(State.NotifDuration, function()
        local t = TweenService:Create(card, TweenInfo.new(0.35), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 60, 0, 0),
        })
        t:Play()
        TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 1}):Play()
        t.Completed:Wait()
        card:Destroy()
    end)
end

local function safe(label, fn)
    local ok, err = pcall(fn)
    if ok then Notify(label, "Активовано", "success")
    else Notify(label, "Помилка: " .. tostring(err), "error") end
end

-- ============================================================
-- UTILITIES
-- ============================================================
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function applyHumanoid()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = State.Speed
        hum.UseJumpPower = true
        hum.JumpPower = State.Jump
    end
end
applyHumanoid()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyHumanoid()
end)

-- ============================================================
-- FLY / NOCLIP / INF JUMP / GRAVITY / FOV
-- ============================================================
local bv, bg, flyVel = nil, nil, Vector3.zero
local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    flyVel = Vector3.zero
end
local function startFly()
    local hrp = getHRP() if not hrp then return end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4
    bg.Parent = hrp
    RunService.RenderStepped:Connect(function(dt)
        if not State.Fly or not bv then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        local target = move * State.FlySpeed
        flyVel = flyVel:Lerp(target, math.min(dt*8, 1))
        bv.Velocity = flyVel
    end)
end

RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    workspace.Gravity = State.GravityOff and 0 or State.Gravity
end)

RunService.RenderStepped:Connect(function()
    if Camera.FieldOfView ~= State.FOV then Camera.FieldOfView = State.FOV end
end)

-- ============================================================
-- ESP (універсальний: Drawing для ПК, Highlight для мобільних)
-- ============================================================
local espList = {}
local function createESP(player)
    if player == LocalPlayer then return end
    if espList[player] then return end

    if HAS_DRAWING then
        local box = Drawing.new("Square")
        box.Thickness = 1.5
        box.Color = Color3.fromRGB(163, 230, 53)
        box.Filled = false
        box.Visible = false

        local nm = Drawing.new("Text")
        nm.Size = 13
        nm.Color = Color3.fromRGB(243, 251, 239)
        nm.Center = true
        nm.Outline = true
        nm.Visible = false

        espList[player] = {box = box, name = nm, mode = "drawing"}

        RunService.RenderStepped:Connect(function()
            local d = espList[player]
            if not d or d.mode ~= "drawing" then return end
            local char = player.Character
            if not char or not State.ESP then
                box.Visible = false
                nm.Visible = false
                return
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if not hrp or not head then
                box.Visible = false
                nm.Visible = false
                return
            end
            local pos, on = Camera:WorldToViewportPoint(hrp.Position)
            local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            if on then
                local h = math.abs(pos.Y - hp.Y) * 2
                local w = h / 2
                box.Size = Vector2.new(w, h)
                box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                box.Visible = true
                nm.Position = Vector2.new(pos.X, pos.Y - h/2 - 16)
                nm.Text = player.Name
                nm.Visible = true
            else
                box.Visible = false
                nm.Visible = false
            end
        end)
    else
        -- Highlight + BillboardGui
        local hl = Instance.new("Highlight")
        hl.Name = "OT_ESP_" .. player.UserId
        hl.FillColor = Theme.LIME
        hl.OutlineColor = Theme.TEXT
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0.2
        hl.Enabled = false
        hl.Parent = workspace

        local bb = Instance.new("BillboardGui")
        bb.Name = "OT_ESPN_" .. player.UserId
        bb.Size = UDim2.new(0, 120, 0, 20)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = false

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = player.Name
        txt.TextColor3 = Theme.TEXT
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 12
        txt.TextStrokeTransparency = 0
        txt.Parent = bb

        espList[player] = {highlight = hl, billboard = bb, name = txt, mode = "highlight"}

        RunService.RenderStepped:Connect(function()
            local d = espList[player]
            if not d or d.mode ~= "highlight" then return end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            if not State.ESP or not hrp or not head then
                hl.Enabled = false
                bb.Enabled = false
                return
            end
            hl.Adornee = char
            hl.Enabled = true
            bb.Adornee = head
            bb.Enabled = true
            d.name.Text = player.Name
        end)
    end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

-- ============================================================
-- FULLBRIGHT
-- ============================================================
RunService.Heartbeat:Connect(function()
    if State.Fullbright then
        Lighting.Brightness = 4
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
        Lighting.FogEnd = 1e6
    end
end)

-- ============================================================
-- ANTI-AFK
-- ============================================================
LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
end)

-- ============================================================
-- CLICK TP
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if State.ClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local hrp = getHRP()
        if not hrp then return end
        local mouse = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0)) end
    end
end)

-- ============================================================
-- DOORS
-- ============================================================
local DoorCache = {furniture = {}, doors = {}, items = {}, lastScan = 0}

local function refreshDoorCache()
    local now = tick()
    if now - DoorCache.lastScan < 1.5 then return end
    DoorCache.lastScan = now
    DoorCache.furniture, DoorCache.doors, DoorCache.items = {}, {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("wardrobe") or n:find("locker") or n:find("bed") or n:find("drawer") or n:find("closet") then
                table.insert(DoorCache.furniture, obj)
            elseif n:find("door") and not n:find("frame") then
                table.insert(DoorCache.doors, obj)
            elseif n:find("key") or n:find("coin") or n:find("gold") or n:find("crucifix") or n:find("lighter") then
                table.insert(DoorCache.items, obj)
            end
        end
    end
end

-- Auto Collect Coins
task.spawn(function()
    while true do
        task.wait(0.8)
        if State.DoorsAutoCoins then
            local hrp = getHRP()
            if hrp then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local n = obj.Name:lower()
                        if n:find("coin") or n:find("gold") then
                            local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                            if base and (base.Position - hrp.Position).Magnitude < 40 then
                                pcall(function() base.CFrame = hrp.CFrame end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Open Drawers
task.spawn(function()
    local cooldown = {}
    while true do
        task.wait(0.6)
        if State.DoorsAutoDrawers then
            local hrp = getHRP()
            if hrp then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") or obj:IsA("BasePart") then
                        local n = obj.Name:lower()
                        if n:find("drawer") or n:find("cabinet") or n:find("chest") then
                            local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                            if base then
                                local d = (base.Position - hrp.Position).Magnitude
                                local key = tostring(obj)
                                if d < 12 and (not cooldown[key] or tick() - cooldown[key] > 1) then
                                    cooldown[key] = tick()
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                        task.wait(0.03)
                                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Collect Items
task.spawn(function()
    while true do
        task.wait(0.8)
        if State.DoorsAutoItems then
            local hrp = getHRP()
            if hrp then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") or obj:IsA("BasePart") then
                        local n = obj.Name:lower()
                        if n:find("key") or n:find("crucifix") or n:find("lighter") or n:find("lockpick") then
                            local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                            if base and (base.Position - hrp.Position).Magnitude < 40 then
                                pcall(function() base.CFrame = hrp.CFrame end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Smart Auto Hide
local smartHideState = {inHide = false, hideStart = 0}
local function toggleSmartHide(on)
    if not on then return end
    RunService.Heartbeat:Connect(function()
        if not State.DoorsSmartHide then return end
        local hrp = getHRP()
        if not hrp then return end
        local danger = false
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local n = obj.Name:lower()
                if n:find("rush") or n:find("ambush") or n:find("seek") or n:find("figure") then
                    local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                    if base and (base.Position - hrp.Position).Magnitude < 100 then
                        danger = true break
                    end
                end
            end
        end
        if danger and not smartHideState.inHide then
            refreshDoorCache()
            local nearest, dist = nil, 20
            for _, obj in ipairs(DoorCache.furniture) do
                local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if base then
                    local d = (base.Position - hrp.Position).Magnitude
                    if d < dist then nearest, dist = base, d end
                end
            end
            if nearest then
                hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 0))
                task.wait(0.1)
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end)
                smartHideState.inHide = true
                smartHideState.hideStart = tick()
            end
        elseif not danger and smartHideState.inHide then
            if tick() - smartHideState.hideStart > 2 then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end)
                smartHideState.inHide = false
            end
        end
    end)
end

-- Doors Highlight
local doorHL = {}
local function toggleDoorsHighlight(on)
    for _, h in pairs(doorHL) do h:Destroy() end
    doorHL = {}
    if not on then return end
    refreshDoorCache()
    for _, obj in ipairs(DoorCache.doors) do
        local hl = Instance.new("Highlight")
        hl.Adornee = obj:IsA("Model") and obj or obj.Parent
        hl.FillColor = Theme.LIME
        hl.OutlineColor = Theme.TEXT
        hl.FillTransparency = 0.5
        hl.Parent = obj
        table.insert(doorHL, hl)
    end
end

-- ============================================================
-- GRACE
-- ============================================================
local GraceCache = {entities = {}, lastScan = 0}

local function refreshGraceCache()
    local now = tick()
    if now - GraceCache.lastScan < 1.5 then return end
    GraceCache.lastScan = now
    GraceCache.entities = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("grace") or n:find("entity") or n:find("monster") or n:find("rush") or n:find("ambush") then
                table.insert(GraceCache.entities, obj)
            end
        end
    end
end

-- Entity Alarm
RunService.Heartbeat:Connect(function()
    if not State.GrEntityAlarm then return end
    refreshGraceCache()
    local hrp = getHRP()
    if not hrp then return end
    for _, ent in ipairs(GraceCache.entities) do
        local base = ent:IsA("Model") and ent:FindFirstChildWhichIsA("BasePart") or ent
        if base then
            local d = (base.Position - hrp.Position).Magnitude
            if d <= State.GrAlarmRadius then
                Notify("⚠ GRACE ALARM", "Сутність поруч! (" .. math.floor(d) .. " studs)", "error")
                return
            end
        end
    end
end)

-- Grace Rush Alarm
RunService.Heartbeat:Connect(function()
    if not State.GrRushAlarm then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("rush") or n:find("ambush") then
                Notify("RUSH ALARM", "Швидка сутність!", "warn")
                return
            end
        end
    end
end)

-- ============================================================
-- MM2
-- ============================================================
local MmCache = {trackers = {}, weapons = {}, bodies = {}}

local function mmGetRole(player)
    if not player or not player.Character then return "Unknown" end
    local char = player.Character
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n:find("knife") then return "Murderer" end
            if n:find("gun") or n:find("pistol") then return "Sheriff" end
        end
    end
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") then return "Murderer" end
                if n:find("gun") or n:find("pistol") then return "Sheriff" end
            end
        end
    end
    return "Innocent"
end

local function mmUpdateTrackers()
    if not State.MmMurdererTracker and not State.MmSheriffLocator then
        for _, hl in pairs(MmCache.trackers) do hl:Destroy() end
        MmCache.trackers = {}
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role = mmGetRole(p)
            local want = (State.MmMurdererTracker and role == "Murderer")
                      or (State.MmSheriffLocator and role == "Sheriff")
            if want then
                if not MmCache.trackers[p] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = role == "Murderer" and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(120, 160, 240)
                    hl.OutlineColor = Theme.TEXT
                    hl.Adornee = p.Character
                    hl.Parent = p.Character
                    MmCache.trackers[p] = hl
                end
            elseif MmCache.trackers[p] then
                MmCache.trackers[p]:Destroy()
                MmCache.trackers[p] = nil
            end
        end
    end
end

local function mmRefreshWeapons()
    for item, hl in pairs(MmCache.weapons) do
        if not item.Parent then
            hl:Destroy()
            MmCache.weapons[item] = nil
        end
    end
    if not State.MmWeaponEsp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("gun") or n:find("knife") then
                if not MmCache.weapons[obj] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Theme.LIME
                    hl.Adornee = obj
                    hl.Parent = obj
                    MmCache.weapons[obj] = hl
                end
            end
        end
    end
end

-- Role Counter HUD
local mmRoleGui = nil
local function mmCreateRoleCounter()
    if mmRoleGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "OT_MM2_Roles"
    g.ResetOnSpawn = false
    g.Parent = GuiParent
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 180, 0, 90)
    f.Position = UDim2.new(0, 10, 0, 10)
    f.BackgroundColor3 = Theme.PANEL
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.Parent = g
    local c = Instance.new("UICorner", f) c.CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", f)
    s.Color = Theme.LIME
    s.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 22)
    title.BackgroundTransparency = 1
    title.Text = "🎭 MM2 ROLES"
    title.TextColor3 = Theme.LIME
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.Parent = f

    local m = Instance.new("TextLabel")
    m.Size = UDim2.new(1, -10, 0, 18)
    m.Position = UDim2.new(0, 5, 0, 24)
    m.BackgroundTransparency = 1
    m.Text = "Murderer: 0"
    m.TextColor3 = Color3.fromRGB(220, 80, 80)
    m.Font = Enum.Font.Gotham
    m.TextSize = 12
    m.TextXAlignment = Enum.TextXAlignment.Left
    m.Parent = f

    local s2 = Instance.new("TextLabel")
    s2.Size = UDim2.new(1, -10, 0, 18)
    s2.Position = UDim2.new(0, 5, 0, 42)
    s2.BackgroundTransparency = 1
    s2.Text = "Sheriff: 0"
    s2.TextColor3 = Color3.fromRGB(120, 160, 240)
    s2.Font = Enum.Font.Gotham
    s2.TextSize = 12
    s2.TextXAlignment = Enum.TextXAlignment.Left
    s2.Parent = f

    local i = Instance.new("TextLabel")
    i.Size = UDim2.new(1, -10, 0, 18)
    i.Position = UDim2.new(0, 5, 0, 60)
    i.BackgroundTransparency = 1
    i.Text = "Innocent: 0"
    i.TextColor3 = Theme.TEXT
    i.Font = Enum.Font.Gotham
    i.TextSize = 12
    i.TextXAlignment = Enum.TextXAlignment.Left
    i.Parent = f

    mmRoleGui = {gui = g, m = m, s = s2, i = i}
end

RunService.Heartbeat:Connect(function()
    if not State.MmRoleCounter then
        if mmRoleGui then mmRoleGui.gui.Enabled = false end
        return
    end
    mmCreateRoleCounter()
    mmRoleGui.gui.Enabled = true
    local m, s, i = 0, 0, 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local role = mmGetRole(p)
                if role == "Murderer" then m += 1
                elseif role == "Sheriff" then s += 1
                else i += 1 end
            end
        end
    end
    mmRoleGui.m.Text = "Murderer: " .. m
    mmRoleGui.s.Text = "Sheriff: " .. s
    mmRoleGui.i.Text = "Innocent: " .. i
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        mmUpdateTrackers()
        mmRefreshWeapons()
    end
end)

-- ============================================================
-- FTAP
-- ============================================================
local FtCache = {players = {}, items = {}, dragAllConn = nil, flingConn = nil}

local function ftGetTargets()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then table.insert(list, {player = p, hrp = hrp}) end
        end
    end
    return list
end

local function ftGetItems()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Anchored == false then
            local parent = obj.Parent
            if not (parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid")) then
                table.insert(list, obj)
            end
        end
    end
    return list
end

local function startDragAll()
    if FtCache.dragAllConn then FtCache.dragAllConn:Disconnect() end
    FtCache.dragAllConn = RunService.Heartbeat:Connect(function()
        if not State.FtDragAll then return end
        local myHRP = getHRP()
        if not myHRP then return end
        for _, t in ipairs(ftGetTargets()) do
            local dir = (myHRP.Position - t.hrp.Position).Unit
            t.hrp.CFrame = t.hrp.CFrame + dir * 2
        end
    end)
end

local function startAutoFling()
    if FtCache.flingConn then FtCache.flingConn:Disconnect() end
    FtCache.flingConn = RunService.Heartbeat:Connect(function()
        if not State.FtAutoFling then return end
        local myHRP = getHRP()
        if not myHRP then return end
        for _, t in ipairs(ftGetTargets()) do
            local d = (t.hrp.Position - myHRP.Position).Magnitude
            if d < State.FtFlingRadius then
                local dir = Vector3.new(math.random(-1, 1), 1, math.random(-1, 1)).Unit
                t.hrp.Velocity = dir * 500
            end
        end
    end)
end

-- ============================================================
-- FUN
-- ============================================================
local funConnections = {}

local function toggleFunBigHead(on)
    if funConnections.bigHead then funConnections.bigHead:Disconnect() funConnections.bigHead = nil end
    if not on then return end
    funConnections.bigHead = RunService.Heartbeat:Connect(function()
        if not State.FunBigHead then return end
        local char = LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            head.Size = Vector3.new(2, 2, 2)
            local mesh = head:FindFirstChildOfClass("SpecialMesh")
            if mesh then mesh.Scale = Vector3.new(3, 3, 3) end
        end
    end)
end

local function toggleFunRainbow(on)
    if funConnections.rainbow then funConnections.rainbow:Disconnect() funConnections.rainbow = nil end
    if not on then return end
    funConnections.rainbow = RunService.Heartbeat:Connect(function()
        if not State.FunRainbow then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hue = (tick() * 0.5) % 1
        local col = Color3.fromHSV(hue, 1, 1)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.Color = col end
        end
    end)
end

local function toggleFunInvisible(on)
    if funConnections.invisible then funConnections.invisible:Disconnect() funConnections.invisible = nil end
    if not on then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
            end
        end
        return
    end
    funConnections.invisible = RunService.Heartbeat:Connect(function()
        if not State.FunInvisible then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
        end
    end)
end

local function toggleFunConfetti(on)
    if funConnections.confetti then
        funConnections.confetti:Destroy()
        funConnections.confetti = nil
    end
    if not on then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://241876428"
    emitter.Rate = 30
    emitter.Lifetime = NumberRange.new(1)
    emitter.Speed = NumberRange.new(15)
    emitter.SpreadAngle = Vector2.new(45, 45)
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(163, 230, 53)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 200, 240)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 200, 80)),
    })
    emitter.Parent = hrp
    funConnections.confetti = emitter
end

-- ============================================================
-- UTILITIES (Server HUD + Reconnect)
-- ============================================================
local serverHudStart = tick()
local serverHudGui = nil
local fpsCounter = {count = 0, last = tick(), value = 60}

RunService.RenderStepped:Connect(function()
    fpsCounter.count += 1
    local now = tick()
    if now - fpsCounter.last >= 1 then
        fpsCounter.value = fpsCounter.count
        fpsCounter.count = 0
        fpsCounter.last = now
    end
end)

local function createServerHud()
    if serverHudGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "OT_ServerHud"
    g.ResetOnSpawn = false
    g.Parent = GuiParent
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 250, 0, 70)
    l.Position = UDim2.new(1, -260, 0, 10)
    l.BackgroundTransparency = 1
    l.Text = "…"
    l.TextColor3 = Theme.MUTED
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Right
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.Parent = g
    serverHudGui = {gui = g, label = l}
end

task.spawn(function()
    while true do
        task.wait(1)
        if State.UtilServerHud then
            createServerHud()
            serverHudGui.gui.Enabled = true
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            local elapsed = math.floor(tick() - serverHudStart)
            local m = math.floor(elapsed / 60)
            local s = elapsed % 60
            serverHudGui.label.Text = string.format(
                "FPS: %d\nPing: %d ms\nPlayers: %d\nUptime: %02d:%02d",
                fpsCounter.value, ping, #Players:GetPlayers(), m, s
            )
        elseif serverHudGui then
            serverHudGui.gui.Enabled = false
        end
    end
end)

LocalPlayer.OnTeleport:Connect(function(state)
    if not State.UtilAutoReconnect then return end
    if state == Enum.TeleportState.Failed then
        task.wait(2)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
end)

-- ============================================================
-- SERVER HOP
-- ============================================================
local function serverHop()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then Notify("Server Hop", "Помилка запиту", "error") return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 then Notify("Server Hop", "Помилка розбору JSON", "error") return end
    for _, srv in ipairs(data.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            Notify("Server Hop", "Перехід...", "info")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
            return
        end
    end
    Notify("Server Hop", "Вільних серверів немає", "warn")
end

-- ============================================================
-- GUI
-- ============================================================
local old = GuiParent:FindFirstChild("OgorodTalk_Hub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "OgorodTalk_Hub"
gui.ResetOnSpawn = false
gui.Parent = GuiParent

local main = Instance.new("Frame")
main.Size = UDim2.new(0, GUI_W, 0, GUI_H)
main.Position = IS_MOBILE and UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2) or UDim2.new(0, 40, 0, 60)
main.BackgroundColor3 = Theme.BG
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local mc = Instance.new("UICorner", main) mc.CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Theme.LIME
stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Theme.PANEL
title.BorderSizePixel = 0
title.Text = "🌱 OgorodTalk Hub"
title.TextColor3 = Theme.LIME
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = main
local tc = Instance.new("UICorner", title) tc.CornerRadius = UDim.new(0, 12)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Theme.ERROR
closeBtn.Text = "—"
closeBtn.TextColor3 = Theme.BG
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = title
local cbc = Instance.new("UICorner", closeBtn) cbc.CornerRadius = UDim.new(0, 6)

local sidebar = Instance.new("Frame")
sidebar.Size = IS_MOBILE and UDim2.new(0, 110, 1, -46) or UDim2.new(0, 140, 1, -46)
sidebar.Position = UDim2.new(0, 8, 0, 42)
sidebar.BackgroundColor3 = Theme.PANEL
sidebar.BorderSizePixel = 0
sidebar.Parent = main
local sbc = Instance.new("UICorner", sidebar) sbc.CornerRadius = UDim.new(0, 8)

local sidebarScroll = Instance.new("ScrollingFrame")
sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
sidebarScroll.BackgroundTransparency = 1
sidebarScroll.BorderSizePixel = 0
sidebarScroll.ScrollBarThickness = 3
sidebarScroll.ScrollBarImageColor3 = Theme.LIME
sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebarScroll.Parent = sidebar

local sbLay = Instance.new("UIListLayout", sidebarScroll)
sbLay.Padding = UDim.new(0, 4)
sbLay.SortOrder = Enum.SortOrder.LayoutOrder
sbLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
sbLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sbLay.AbsoluteContentSize.Y + 10)
end)

local content = Instance.new("Frame")
content.Size = IS_MOBILE and UDim2.new(1, -134, 1, -46) or UDim2.new(1, -164, 1, -46)
content.Position = IS_MOBILE and UDim2.new(0, 126, 0, 42) or UDim2.new(0, 156, 0, 42)
content.BackgroundColor3 = Theme.PANEL_LIGHT
content.BorderSizePixel = 0
content.Parent = main
local ccc = Instance.new("UICorner", content) ccc.CornerRadius = UDim.new(0, 8)

if IS_MOBILE then
    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Size = UDim2.new(0, 56, 0, 56)
    mobileBtn.Position = UDim2.new(1, -70, 0, 100)
    mobileBtn.BackgroundColor3 = Theme.LIME
    mobileBtn.Text = "🌱"
    mobileBtn.TextSize = 26
    mobileBtn.TextColor3 = Theme.BG
    mobileBtn.Font = Enum.Font.GothamBold
    mobileBtn.Active = true
    mobileBtn.Draggable = true
    mobileBtn.Parent = gui
    local mbc = Instance.new("UICorner", mobileBtn) mbc.CornerRadius = UDim.new(1, 0)
    local mbs = Instance.new("UIStroke", mobileBtn)
    mbs.Color = Theme.LIME_HOVER
    mbs.Thickness = 2
    mobileBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)
    main.Visible = false
else
    main.Visible = true
end

local pages = {}

local function newPage(name, isSettings)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Theme.LIME
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content
    local lay = Instance.new("UIListLayout", page)
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
    end)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = isSettings and Theme.HOVER or Theme.PANEL_LIGHT
    btn.Text = name
    btn.TextColor3 = Theme.TEXT
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.LayoutOrder = #pages
    btn.Parent = sidebarScroll
    local bc = Instance.new("UICorner", btn) bc.CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.HOVER}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if not pages[name] or not pages[name].page.Visible then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = isSettings and Theme.HOVER or Theme.PANEL_LIGHT
            }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do
            p.page.Visible = false
            TweenService:Create(p.btn, TweenInfo.new(0.2), {
                BackgroundColor3 = p.isSettings and Theme.HOVER or Theme.PANEL_LIGHT
            }):Play()
        end
        page.Visible = true
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.LIME}):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Theme.BG}):Play()
    end)

    pages[name] = {page = page, btn = btn, isSettings = isSettings}
    return page
end

local function makeLabel(parent, text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Theme.LIME
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeButton(parent, text, cb, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, BTN_H)
    b.BackgroundColor3 = color or Theme.PANEL_LIGHT
    b.Text = text
    b.TextColor3 = Theme.TEXT
    b.Font = Enum.Font.Gotham
    b.TextSize = FONT_SIZE
    b.Parent = parent
    local bc = Instance.new("UICorner", b) bc.CornerRadius = UDim.new(0, 6)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Theme.HOVER}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color or Theme.PANEL_LIGHT}):Play()
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function makeToggle(parent, text, default, cb)
    local b = makeButton(parent, text .. ": " .. (default and "ON" or "OFF"), nil)
    local on = default
    local function upd()
        b.Text = text .. ": " .. (on and "ON" or "OFF")
        TweenService:Create(b, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Theme.LIME or Theme.PANEL_LIGHT,
            TextColor3 = on and Theme.BG or Theme.TEXT
        }):Play()
    end
    upd()
    b.MouseButton1Click:Connect(function()
        on = not on
        upd()
        safe(text, function() cb(on) end)
    end)
    return b
end

local function makeSlider(parent, label, min, max, default, cb)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -10, 0, 48)
    cont.BackgroundColor3 = Theme.PANEL
    cont.Parent = parent
    local c = Instance.new("UICorner", cont) c.CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. default
    lbl.TextColor3 = Theme.TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, IS_MOBILE and 12 or 8)
    bar.Position = UDim2.new(0, 10, 0, 26)
    bar.BackgroundColor3 = Theme.BORDER
    bar.BorderSizePixel = 0
    bar.Parent = cont
    local bc = Instance.new("UICorner", bar) bc.CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.LIME
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner", fill) fc.CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = label .. ": " .. val
        cb(val)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- PAGES
-- ============================================================
local pOther = newPage("Other")
makeLabel(pOther, "— Загальні функції —")
makeSlider(pOther, "Speed", 16, 500, State.Speed, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pOther, "Jump", 50, 500, State.Jump, function(v) State.Jump = v applyHumanoid() end)
makeSlider(pOther, "Gravity", 0, 500, State.Gravity, function(v) State.Gravity = v end)
makeSlider(pOther, "Fly Speed", 50, 800, State.FlySpeed, function(v) State.FlySpeed = v end)
makeSlider(pOther, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeToggle(pOther, "Fly (WASD)", false, function(on)
    State.Fly = on
    if on then startFly() else stopFly() end
end)
makeToggle(pOther, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pOther, "Infinite Jump", false, function(on) State.InfJump = on end)
makeToggle(pOther, "Gravity OFF", false, function(on) State.GravityOff = on end)
makeToggle(pOther, "ESP Players", false, function(on) State.ESP = on end)
makeToggle(pOther, "Fullbright", false, function(on) State.Fullbright = on end)
makeToggle(pOther, "Click TP", false, function(on) State.ClickTP = on end)
makeToggle(pOther, "Anti-AFK", true, function(on) State.AntiAFK = on end)

makeLabel(pOther, "— Утиліти —")
makeButton(pOther, "Reset Character", function()
    safe("Reset", function()
        local hum = getHum() if hum then hum.Health = 0 end
    end)
end)
makeButton(pOther, "Rejoin", function()
    Notify("Rejoin", "Перезахід...", "info")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
makeButton(pOther, "Server Hop", serverHop)

local pDoors = newPage("Doors")
makeLabel(pDoors, "— Doors —")
makeSlider(pDoors, "Speed", 16, 60, 22, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pDoors, "Jump", 50, 200, 60, function(v) State.Jump = v applyHumanoid() end)
makeToggle(pDoors, "Inf Jump", false, function(on) State.InfJump = on end)
makeToggle(pDoors, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pDoors, "Auto Collect Coins", false, function(on) State.DoorsAutoCoins = on end)
makeToggle(pDoors, "Auto Open Drawers", false, function(on) State.DoorsAutoDrawers = on end)
makeToggle(pDoors, "Auto Collect Items", false, function(on) State.DoorsAutoItems = on end)
makeToggle(pDoors, "Smart Auto Hide", false, function(on)
    State.DoorsSmartHide = on
    toggleSmartHide(on)
end)
makeToggle(pDoors, "Highlight Doors", false, toggleDoorsHighlight)
makeToggle(pDoors, "Fullbright", false, function(on) State.Fullbright = on end)
makeButton(pDoors, "Server Hop", serverHop)

local pGr = newPage("Grace")
makeLabel(pGr, "— Grace —")
makeSlider(pGr, "Speed", 16, 60, 20, function(v) State.Speed = v applyHumanoid() end)
makeToggle(pGr, "ESP Players", false, function(on) State.GrESP = on end)
makeToggle(pGr, "Entity Alarm", false, function(on) State.GrEntityAlarm = on end)
makeSlider(pGr, "Alarm Radius", 10, 150, State.GrAlarmRadius, function(v) State.GrAlarmRadius = v end)
makeToggle(pGr, "Rush Alarm", false, function(on) State.GrRushAlarm = on end)
makeToggle(pGr, "Auto Hide", false, function(on) State.GrAutoHide = on end)
makeToggle(pGr, "Fullbright", false, function(on) State.Fullbright = on end)
makeButton(pGr, "Server Hop", serverHop)

local pMm = newPage("MM2")
makeLabel(pMm, "— MM2 —")
makeToggle(pMm, "ESP Players", false, function(on) State.MmESP = on end)
makeToggle(pMm, "Role ESP", true, function(on) State.MmRoleEsp = on end)
makeToggle(pMm, "Murderer Tracker", false, function(on) State.MmMurdererTracker = on end)
makeToggle(pMm, "Sheriff Locator", false, function(on) State.MmSheriffLocator = on end)
makeToggle(pMm, "Weapon ESP", false, function(on) State.MmWeaponEsp = on end)
makeToggle(pMm, "Role Counter", false, function(on) State.MmRoleCounter = on end)
makeButton(pMm, "Server Hop", serverHop)

local pFt = newPage("FTAP")
makeLabel(pFt, "— Fling Things And People —")
makeToggle(pFt, "ESP Players", false, function(on) State.FtESP = on end)
makeToggle(pFt, "ESP Items", false, function(on) State.FtESPItems = on end)
makeToggle(pFt, "Drag All", false, function(on)
    State.FtDragAll = on
    if on then startDragAll() end
end)
makeToggle(pFt, "Auto Fling", false, function(on)
    State.FtAutoFling = on
    if on then startAutoFling() end
end)
makeSlider(pFt, "Fling Radius", 10, 100, State.FtFlingRadius, function(v) State.FtFlingRadius = v end)
makeButton(pFt, "Server Hop", serverHop)

local pFun = newPage("🎉 Fun")
makeLabel(pFun, "— Веселощі —")
makeToggle(pFun, "Big Head", false, function(on)
    State.FunBigHead = on
    toggleFunBigHead(on)
end)
makeToggle(pFun, "Rainbow Character", false, function(on)
    State.FunRainbow = on
    toggleFunRainbow(on)
end)
makeToggle(pFun, "Invisible", false, function(on)
    State.FunInvisible = on
    toggleFunInvisible(on)
end)
makeToggle(pFun, "Confetti", false, function(on)
    State.FunConfetti = on
    toggleFunConfetti(on)
end)

local pUtil = newPage("🛠 Utilities")
makeLabel(pUtil, "— Продуктивність —")
makeToggle(pUtil, "Server Info HUD", false, function(on) State.UtilServerHud = on end)
makeToggle(pUtil, "Auto Reconnect", false, function(on) State.UtilAutoReconnect = on end)

local pSet = newPage("⚙ Settings", true)
makeLabel(pSet, "— Сповіщення —")
makeToggle(pSet, "Звук сповіщень", State.NotifSound, function(on) State.NotifSound = on end)
makeSlider(pSet, "Гучність (%)", 0, 100, math.floor(State.NotifVolume*100), function(v) State.NotifVolume = v / 100 end)
makeSlider(pSet, "Тривалість (сек)", 1, 15, State.NotifDuration, function(v) State.NotifDuration = v end)

makeLabel(pSet, "— Інформація —", Theme.MUTED)
makeLabel(pSet, "Інжектор: " .. tostring(identifyexecutor and identifyexecutor() or "unknown"), Theme.MUTED)
makeLabel(pSet, "Drawing: " .. (HAS_DRAWING and "✅" or "❌ (ESP через Highlight)"), Theme.MUTED)
makeLabel(pSet, "File IO: " .. (HAS_FILE_IO and "✅" or "❌"), Theme.MUTED)
makeLabel(pSet, "Clipboard: " .. (HAS_CLIPBOARD and "✅" or "❌"), Theme.MUTED)

-- ============================================================
-- DEFAULT + COLLAPSE
-- ============================================================
for n, p in pairs(pages) do
    p.page.Visible = (n == "Other")
    p.btn.BackgroundColor3 = (n == "Other") and Theme.LIME or (p.isSettings and Theme.HOVER or Theme.PANEL_LIGHT)
    if n == "Other" then p.btn.TextColor3 = Theme.BG end
end

local opened = true
closeBtn.MouseButton1Click:Connect(function()
    opened = not opened
    if opened then
        sidebar.Visible = true
        content.Visible = true
        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, GUI_W, 0, GUI_H)
        }):Play()
        closeBtn.Text = "—"
    else
        local tween = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, GUI_W, 0, 36)
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not opened then
                sidebar.Visible = false
                content.Visible = false
            end
        end)
        closeBtn.Text = "+"
    end
end)

Notify("OgorodTalk Hub", "Завантажено! Працює на Solara, Delta, Codex, Fluxus", "success")
print("[OgorodTalk Hub] Loaded — Drawing:", HAS_DRAWING, "| FileIO:", HAS_FILE_IO, "| Mobile:", IS_MOBILE)
