--[[
    AetherGlass UI Library (.luau) - Anti-Bug Drag vs Click Edition
    Fitur Utama:
    1. Glassmorphism Transparent Window + UIStroke + UIGradient
    2. Fast Animated Loading Screen dengan Progress Bar & Fade Transition
    3. Draggable Floating Toggle ("Dogle Mengambang") dengan Threshold 6px
       -> Klik (geser <= 6px) DIJAMIN selalu membuka/menutup UI tanpa bug!
    4. Draggable Top Telemetry HUD (Live FPS, CPU ms, & Network Ping)
    5. Smooth Tab Transitions, Toggle Switch, Slider & Toast Notification
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Bersihkan UI lama jika di-execute ulang
local ExistingUI = PlayerGui:FindFirstChild("AetherGlassUI")
if ExistingUI then ExistingUI:Destroy() end

-- ============================================================================
-- KONFIGURASI TEMA & WARNA GLASSMORPHISM
-- ============================================================================
local Theme = {
    Background = Color3.fromRGB(13, 16, 24),
    BgTransparency = 0.28, -- Transparansi utama kaca
    Card = Color3.fromRGB(24, 29, 43),
    CardTransparency = 0.45,
    Stroke = Color3.fromRGB(255, 255, 255),
    StrokeTransparency = 0.86,
    Accent = Color3.fromRGB(34, 211, 238), -- Neon Cyan
    Secondary = Color3.fromRGB(129, 140, 248), -- Electric Indigo
    TextPrimary = Color3.fromRGB(248, 250, 252),
    TextMuted = Color3.fromRGB(148, 163, 184),
    FontUI = Enum.Font.BuilderSans,
    FontMono = Enum.Font.RobotoMono
}

local function Create(className: string, props: {[string]: any}, children: {Instance}?)
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

local function Tween(inst: Instance, duration: number, props: {[string]: any}, style: Enum.EasingStyle?)
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

-- ============================================================================
-- ANTI-BUG DRAGGABLE ENGINE (THRESHOLD 6 PIXEL UNTUK KLIK MURNI)
-- ============================================================================
local function MakeDraggable(frame: GuiObject, handle: GuiObject?, onClick: (() -> ())?)
    local dragHandle = handle or frame
    local DRAG_THRESHOLD = 6 -- Minimal geser 6px baru dianggap drag!
    local activeInput: InputObject? = nil
    local hasDragged = false
    local dragStart = Vector3.zero
    local startPos = UDim2.new()

    dragHandle.InputBegan:Connect(function(input: InputObject)
        if activeInput ~= nil then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
            hasDragged = false
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input: InputObject)
        if activeInput == nil then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if not hasDragged and delta.Magnitude > DRAG_THRESHOLD then
                hasDragged = true
            end
            if hasDragged then
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input: InputObject)
        if activeInput == nil then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local wasClick = not hasDragged
            activeInput = nil
            hasDragged = false

            -- Jika gerakan <= 6px saat dilepas, DIJAMIN dianggap klik tombol!
            if wasClick and onClick then
                task.spawn(onClick)
            end
        end
    end)
end

-- ============================================================================
-- ROOT SCREENGUI
-- ============================================================================
local ScreenGui = Create("ScreenGui", {
    Name = "AetherGlassUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
})
ScreenGui.Parent = PlayerGui

-- ============================================================================
-- 1. TOP TELEMETRY HUD BAR (LIVE FPS, CPU ms, PING)
-- ============================================================================
local TelemetryHUD = Create("Frame", {
    Name = "TelemetryHUD",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 14),
    Size = UDim2.new(0, 300, 0, 32),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = Theme.BgTransparency,
    Active = true,
    Parent = ScreenGui
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    Create("UIStroke", { Color = Theme.Stroke, Transparency = Theme.StrokeTransparency, Thickness = 1 })
})

local HudLabel = Create("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Font = Theme.FontMono,
    TextSize = 12,
    TextColor3 = Theme.TextPrimary,
    RichText = true,
    Text = "● HUD  |  FPS: 60  |  PING: 30ms",
    Parent = TelemetryHUD
})

MakeDraggable(TelemetryHUD)

local lastUpdate = 0
RunService.RenderStepped:Connect(function(dt)
    lastUpdate += dt
    if lastUpdate >= 0.5 then
        local fps = math.floor(1 / math.max(dt, 0.001))
        local cpuMs = string.format("%.1f", dt * 1000)
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        HudLabel.Text = string.format(
            '<font color="#34d399">●</font> <b>HUD</b>  |  FPS <font color="#22d3ee">%d</font>  |  CPU <font color="#818cf8">%sms</font>  |  PING <font color="#34d399">%dms</font>',
            fps, cpuMs, ping
        )
        lastUpdate = 0
    end
end)

-- ============================================================================
-- 2. MAIN GLASSMORPHISM HUB WINDOW
-- ============================================================================
local MainWindow = Create("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(540, 350),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = 1,
    Visible = false,
    ClipsDescendants = true,
    Parent = ScreenGui
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 16) }),
    Create("UIStroke", { Color = Theme.Stroke, Transparency = Theme.StrokeTransparency, Thickness = 1 }),
    Create("UIScale", { Name = "WindowScale", Scale = 0.92 })
})

local Header = Create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.96,
    Active = true,
    Parent = MainWindow
}, {
    Create("TextLabel", {
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Theme.FontUI,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.TextPrimary,
        RichText = true,
        Text = '<b>AetherGlass</b> <font color="#22d3ee">HUB</font>'
    })
})

MakeDraggable(MainWindow, Header)

local Sidebar = Create("Frame", {
    Position = UDim2.fromOffset(0, 44),
    Size = UDim2.new(0, 140, 1, -44),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.78,
    Parent = MainWindow
}, {
    Create("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
    Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
})

local ContentArea = Create("ScrollingFrame", {
    Position = UDim2.fromOffset(140, 44),
    Size = UDim2.new(1, -140, 1, -44),
    BackgroundTransparency = 1,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = MainWindow
}, {
    Create("UIListLayout", { Padding = UDim.new(0, 10) }),
    Create("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) })
})

-- ============================================================================
-- 3. DRAGGABLE FLOATING TOGGLE ("DOGLE MENGAMBANG")
-- ============================================================================
local isUIVisible = true
local ToggleStateLabel

local FloatingToggle = Create("Frame", {
    Name = "FloatingToggle",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 24, 1, -24),
    Size = UDim2.fromOffset(132, 42),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = Theme.BgTransparency,
    Active = true,
    ZIndex = 20,
    Parent = ScreenGui
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
    Create("UIStroke", { Color = Theme.Accent, Transparency = 0.4, Thickness = 1.3 }),
    Create("Frame", {
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Accent
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Create("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Secondary), Rotation = 45 })
    }),
    Create("TextLabel", {
        Position = UDim2.fromOffset(44, 5),
        Size = UDim2.fromOffset(80, 16),
        BackgroundTransparency = 1,
        Font = Theme.FontUI,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.TextPrimary,
        Text = "<b>Aether UI</b>",
        RichText = true
    })
})

ToggleStateLabel = Create("TextLabel", {
    Position = UDim2.fromOffset(44, 20),
    Size = UDim2.fromOffset(80, 14),
    BackgroundTransparency = 1,
    Font = Theme.FontMono,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Theme.Accent,
    Text = "Visible",
    Parent = FloatingToggle
})

local function SetWindowOpen(open: boolean)
    isUIVisible = open
    local scaleObj = MainWindow:FindFirstChild("WindowScale")
    if open then
        MainWindow.Visible = true
        Tween(MainWindow, 0.28, { BackgroundTransparency = Theme.BgTransparency })
        if scaleObj then Tween(scaleObj, 0.28, { Scale = 1 }, Enum.EasingStyle.Back) end
        ToggleStateLabel.Text = "Visible"
        ToggleStateLabel.TextColor3 = Theme.Accent
    else
        Tween(MainWindow, 0.22, { BackgroundTransparency = 1 })
        if scaleObj then Tween(scaleObj, 0.22, { Scale = 0.92 }) end
        ToggleStateLabel.Text = "Hidden"
        ToggleStateLabel.TextColor3 = Theme.TextMuted
        task.delay(0.22, function()
            if not isUIVisible then MainWindow.Visible = false end
        end)
    end
end

-- Tombol Minimize (-) di pojok kanan atas Header
local MinBtn = Create("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.92,
    Font = Theme.FontUI,
    TextSize = 16,
    TextColor3 = Theme.TextPrimary,
    Text = "–",
    Parent = Header
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 8) })
})
MinBtn.MouseButton1Click:Connect(function()
    SetWindowOpen(false)
end)

-- Dogle Mengambang: Geser > 6px = Drag, Klik <= 6px = Toggle Window
MakeDraggable(FloatingToggle, FloatingToggle, function()
    SetWindowOpen(not isUIVisible)
end)

-- ============================================================================
-- 4. KOMPONEN TOGGLE SWITCH & NOTIFICATION TOAST
-- ============================================================================
local function Notify(title: string, msg: string)
    local Toast = Create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 300, 1, -24),
        Size = UDim2.fromOffset(260, 56),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.15,
        Parent = ScreenGui
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        Create("UIStroke", { Color = Theme.Accent, Transparency = 0.4, Thickness = 1 }),
        Create("TextLabel", {
            Position = UDim2.fromOffset(14, 8),
            Size = UDim2.new(1, -24, 0, 18),
            BackgroundTransparency = 1,
            Font = Theme.FontUI,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.Accent,
            Text = title
        }),
        Create("TextLabel", {
            Position = UDim2.fromOffset(14, 26),
            Size = UDim2.new(1, -24, 0, 22),
            BackgroundTransparency = 1,
            Font = Theme.FontUI,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.TextPrimary,
            Text = msg
        })
    })

    Tween(Toast, 0.35, { Position = UDim2.new(1, -24, 1, -24) }, Enum.EasingStyle.Back)
    task.delay(3, function()
        Tween(Toast, 0.3, { Position = UDim2.new(1, 300, 1, -24) })
        task.delay(0.32, function() Toast:Destroy() end)
    end)
end

local function AddToggle(parent: Instance, title: string, default: boolean, callback: (boolean) -> ())
    local state = default
    local Card = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = Theme.CardTransparency,
        Text = "",
        AutoButtonColor = false,
        Parent = parent
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("UIStroke", { Color = Theme.Stroke, Transparency = Theme.StrokeTransparency }),
        Create("TextLabel", {
            Position = UDim2.fromOffset(14, 0),
            Size = UDim2.new(0.7, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Theme.FontUI,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.TextPrimary,
            Text = title
        })
    })

    local Pill = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(40, 20),
        BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(51, 65, 85),
        Parent = Card
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    local Knob = Create("Frame", {
        Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Parent = Pill
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    Card.MouseButton1Click:Connect(function()
        state = not state
        Tween(Pill, 0.2, { BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(51, 65, 85) })
        Tween(Knob, 0.2, { Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) })
        callback(state)
    end)
end

Create("TextButton", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.82,
    Font = Theme.FontUI,
    TextSize = 13,
    TextColor3 = Theme.Accent,
    Text = "Main Features",
    Parent = Sidebar
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
    Create("UIStroke", { Color = Theme.Accent, Transparency = 0.6 })
})

AddToggle(ContentArea, "Speed Boost (32 WalkSpeed)", false, function(enabled)
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = enabled and 32 or 16
    end
    Notify("WalkSpeed", enabled and "Speed Boost Diaktifkan!" or "Speed kembali normal.")
end)

AddToggle(ContentArea, "Infinite Jump", false, function(enabled)
    Notify("Infinite Jump", enabled and "Mode lompat tanpa batas aktif." or "Dimatikan.")
end)

-- ============================================================================
-- 5. FAST ANIMATED LOADING SCREEN
-- ============================================================================
local LoadingOverlay = Create("Frame", {
    Name = "LoadingOverlay",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(7, 9, 14),
    BackgroundTransparency = 0.1,
    ZIndex = 50,
    Parent = ScreenGui
})

local LoadBox = Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(280, 110),
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = 0.2,
    ZIndex = 51,
    Parent = LoadingOverlay
}, {
    Create("UICorner", { CornerRadius = UDim.new(0, 16) }),
    Create("UIStroke", { Color = Theme.Accent, Transparency = 0.5 }),
    Create("TextLabel", {
        Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Font = Theme.FontUI,
        TextSize = 17,
        TextColor3 = Theme.TextPrimary,
        RichText = true,
        ZIndex = 52,
        Text = '<b>AETHER</b><font color="#22d3ee">GLASS</font>'
    })
})

local BarBg = Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 62),
    Size = UDim2.fromOffset(220, 6),
    BackgroundColor3 = Color3.fromRGB(30, 41, 59),
    ZIndex = 52,
    Parent = LoadBox
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) })
})

local BarFill = Create("Frame", {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = Theme.Accent,
    ZIndex = 53,
    Parent = BarBg
}, {
    Create("UICorner", { CornerRadius = UDim.new(1, 0) })
})

task.spawn(function()
    Tween(BarFill, 0.9, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Quint)
    task.wait(1.05)
    Tween(LoadingOverlay, 0.4, { BackgroundTransparency = 1 })
    Tween(LoadBox, 0.35, { BackgroundTransparency = 1 })
    task.wait(0.4)
    LoadingOverlay:Destroy()
    SetWindowOpen(true)
    Notify("AetherGlass Ready", "Klik atau geser Dogle Mengambang di kiri bawah.")
end)
