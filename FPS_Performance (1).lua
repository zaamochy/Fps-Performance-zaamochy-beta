--[[
    FPS Performance (versi buatan Claude)
    Tab Combat   : Full Bright, No Fog, No Shadow, Low Grafik
    Tab Rendering: Material Polos, Matikan Partikel/Efek/Decal
    Tab Misc     : FPS & Ping Counter, Anti AFK
    Semua toggle bisa dimatikan lagi (nilai asli dikembalikan).
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- Hindari dobel GUI kalau script dijalankan 2x
pcall(function()
    if getgenv and getgenv().FPSPerfGui then
        getgenv().FPSPerfGui:Destroy()
    end
end)

local function getParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    if ok and ui then return ui end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then return core end
    return LP:WaitForChild("PlayerGui")
end

local function scan(fn)
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(fn, v)
        n += 1
        if n % 400 == 0 then task.wait() end
    end
end

----------------------------------------------------------------
-- FITUR
----------------------------------------------------------------
local Features = {}
local conns = {}

-- Full Bright
do
    local orig, loop
    Features.FullBright = {
        on = function()
            orig = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
            loop = true
            task.spawn(function()
                while loop do
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.Ambient = Color3.new(1, 1, 1)
                    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                    task.wait(1)
                end
            end)
        end,
        off = function()
            loop = false
            if orig then
                for k, v in pairs(orig) do Lighting[k] = v end
            end
        end,
    }
end

-- No Fog
do
    local orig, loop
    local atm = setmetatable({}, { __mode = "k" })
    Features.NoFog = {
        on = function()
            orig = { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd }
            loop = true
            task.spawn(function()
                while loop do
                    Lighting.FogStart = 9e9
                    Lighting.FogEnd = 9e9
                    for _, a in ipairs(Lighting:GetChildren()) do
                        if a:IsA("Atmosphere") then
                            if not atm[a] then atm[a] = a.Density end
                            a.Density = 0
                        end
                    end
                    task.wait(1)
                end
            end)
        end,
        off = function()
            loop = false
            if orig then
                Lighting.FogStart = orig.FogStart
                Lighting.FogEnd = orig.FogEnd
            end
            for a, d in pairs(atm) do
                if a.Parent then a.Density = d end
            end
        end,
    }
end

-- No Shadow
do
    local orig = setmetatable({}, { __mode = "k" })
    local gs, con
    Features.NoShadow = {
        on = function()
            gs = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
            local function apply(v)
                if v:IsA("BasePart") then
                    if orig[v] == nil then orig[v] = v.CastShadow end
                    v.CastShadow = false
                end
            end
            con = workspace.DescendantAdded:Connect(function(v) pcall(apply, v) end)
            task.spawn(scan, apply)
        end,
        off = function()
            if con then con:Disconnect() end
            if gs ~= nil then Lighting.GlobalShadows = gs end
            for p, v in pairs(orig) do
                if p.Parent then p.CastShadow = v end
            end
        end,
    }
end

-- Low Grafik
do
    local origQ, origE, origS
    Features.LowGrafik = {
        on = function()
            pcall(function()
                origQ = settings().Rendering.QualityLevel
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            pcall(function()
                origE = Lighting.EnvironmentDiffuseScale
                origS = Lighting.EnvironmentSpecularScale
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0
            end)
        end,
        off = function()
            pcall(function()
                if origQ then settings().Rendering.QualityLevel = origQ end
            end)
            pcall(function()
                if origE then Lighting.EnvironmentDiffuseScale = origE end
                if origS then Lighting.EnvironmentSpecularScale = origS end
            end)
        end,
    }
end

-- Material Polos (hapus tekstur)
do
    local mats = setmetatable({}, { __mode = "k" })
    local texs = setmetatable({}, { __mode = "k" })
    local water, con
    Features.PlainMaterial = {
        on = function()
            local function apply(v)
                if v:IsA("Terrain") then return end
                if v:IsA("BasePart") then
                    if mats[v] == nil then mats[v] = v.Material end
                    v.Material = Enum.Material.SmoothPlastic
                elseif v:IsA("Texture") then
                    if texs[v] == nil then texs[v] = v.Transparency end
                    v.Transparency = 1
                end
            end
            pcall(function()
                local t = workspace.Terrain
                water = {
                    t.WaterWaveSize, t.WaterWaveSpeed,
                    t.WaterReflectance, t.WaterTransparency,
                }
                t.WaterWaveSize = 0
                t.WaterWaveSpeed = 0
                t.WaterReflectance = 0
                t.WaterTransparency = 1
            end)
            con = workspace.DescendantAdded:Connect(function(v) pcall(apply, v) end)
            task.spawn(scan, apply)
        end,
        off = function()
            if con then con:Disconnect() end
            for p, m in pairs(mats) do
                if p.Parent then p.Material = m end
            end
            for t, tr in pairs(texs) do
                if t.Parent then t.Transparency = tr end
            end
            pcall(function()
                local t = workspace.Terrain
                if water then
                    t.WaterWaveSize = water[1]
                    t.WaterWaveSpeed = water[2]
                    t.WaterReflectance = water[3]
                    t.WaterTransparency = water[4]
                end
            end)
        end,
    }
end

-- Matikan Partikel, Efek & Decal
do
    local en = setmetatable({}, { __mode = "k" })
    local dc = setmetatable({}, { __mode = "k" })
    local con
    local EFFECTS = { "ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles", "Beam" }
    Features.NoEffects = {
        on = function()
            local function apply(v)
                for _, c in ipairs(EFFECTS) do
                    if v:IsA(c) then
                        if en[v] == nil then en[v] = v.Enabled end
                        v.Enabled = false
                        return
                    end
                end
                if v:IsA("Decal") and not v:IsA("Texture") then
                    if dc[v] == nil then dc[v] = v.Transparency end
                    v.Transparency = 1
                end
            end
            con = workspace.DescendantAdded:Connect(function(v) pcall(apply, v) end)
            task.spawn(scan, apply)
        end,
        off = function()
            if con then con:Disconnect() end
            for e, v in pairs(en) do
                if e.Parent then e.Enabled = v end
            end
            for d, v in pairs(dc) do
                if d.Parent then d.Transparency = v end
            end
        end,
    }
end

-- Anti AFK
do
    local con
    Features.AntiAFK = {
        on = function()
            con = LP.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end)
        end,
        off = function()
            if con then con:Disconnect() end
        end,
    }
end

----------------------------------------------------------------
-- UI (tema glass biru, mengikuti desain FPS Performance by zaamochy)
----------------------------------------------------------------
local LOGO_ID = "rbxassetid://102535739463149"

local Gui = Instance.new("ScreenGui")
Gui.Name = "FPSPerformance"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = true
pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)
Gui.Parent = getParent()
pcall(function() if getgenv then getgenv().FPSPerfGui = Gui end end)

-- Warna tema
local WHITE = Color3.new(1, 1, 1)
local BLUE = Color3.fromRGB(47, 107, 255)
local BLUE_LIGHT = Color3.fromRGB(96, 165, 250)
local CYAN = "#22D3EE"
local PURPLE = "#A78BFA"
local PANEL_TOP = Color3.fromRGB(30, 56, 128)
local PANEL_BOT = Color3.fromRGB(9, 18, 56)
local ROW = Color3.fromRGB(36, 50, 96)
local SUB = Color3.fromRGB(176, 190, 225)

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
    return c
end

local function stroke(o, color, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = t
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function label(parent, text, size, color, font, pos, sz, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color
    l.Font = font or Enum.Font.GothamMedium
    l.Position = pos
    l.Size = sz
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeDraggable(handle, target, uiscale)
    local dragging, start, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = i.Position
            startPos = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            local s = uiscale and uiscale.Scale or 1
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X / s,
                startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
        end
    end)
end

-- Logo blue hole cadangan (dipakai kalau gambar logo gagal dimuat)
local spinList = {}
local function makeBlueHole(parent, size, pos)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(size, size)
    holder.Position = pos
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local function circle(scale, color, transp)
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.fromScale(0.5, 0.5)
        f.Size = UDim2.fromScale(scale, scale)
        f.BackgroundColor3 = color
        f.BackgroundTransparency = transp or 0
        f.BorderSizePixel = 0
        f.Parent = holder
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0.5, 0)
        c.Parent = f
        return f
    end
    local function spin(frame, seq, speed)
        local g = Instance.new("UIGradient")
        g.Color = seq
        g.Parent = frame
        spinList[#spinList + 1] = { g = g, speed = speed }
    end

    circle(1, Color3.fromRGB(56, 140, 255), 0.65)
    local ring = circle(0.92, WHITE)
    spin(ring, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 211, 238)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(37, 99, 235)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(124, 58, 237)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(34, 211, 238)),
    }), 140)
    local ring2 = circle(0.7, WHITE)
    spin(ring2, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 20, 70)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(96, 165, 250)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 20, 70)),
    }), -220)
    local core = circle(0.46, Color3.fromRGB(0, 0, 8))
    stroke(core, Color3.fromRGB(147, 197, 253), 1.2, 0.3)
    return holder
end

local spinConn = RunService.RenderStepped:Connect(function(dt)
    for _, s in ipairs(spinList) do
        s.g.Rotation = (s.g.Rotation + s.speed * dt) % 360
    end
end)

-- Logo: pakai gambar (asset ID), kalau gagal tampil blue hole buatan
local function makeLogo(parent, size, pos)
    local holder = makeBlueHole(parent, size, pos)
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromScale(1, 1)
    img.BackgroundTransparency = 1
    img.Image = LOGO_ID
    img.ScaleType = Enum.ScaleType.Fit
    img.ZIndex = 5
    img.Parent = holder
    task.spawn(function()
        local t = 0
        while t < 6 and not img.IsLoaded do
            task.wait(0.2)
            t += 0.2
        end
        if img.IsLoaded then
            for _, c in ipairs(holder:GetChildren()) do
                if c ~= img then c.Visible = false end
            end
        end
    end)
    return holder
end

----------------------------------------------------------------
-- Jendela utama
----------------------------------------------------------------
local W, H = 340, 376

local Root = Instance.new("Frame")
Root.Name = "Root"
Root.Size = UDim2.fromOffset(W, H)
Root.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
Root.BackgroundTransparency = 1
Root.Parent = Gui

local UIScaler = Instance.new("UIScale")
UIScaler.Parent = Root
local cam = workspace.CurrentCamera
local function fit()
    if cam then
        UIScaler.Scale = math.clamp(cam.ViewportSize.Y / 440, 0.6, 1)
    end
end
fit()
if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

-- Cahaya (glow) di sekeliling panel
local glow1 = Instance.new("Frame")
glow1.Position = UDim2.fromOffset(-9, -9)
glow1.Size = UDim2.new(1, 18, 1, 18)
glow1.BackgroundColor3 = BLUE_LIGHT
glow1.BackgroundTransparency = 0.92
glow1.BorderSizePixel = 0
glow1.Parent = Root
corner(glow1, 30)
local glow2 = Instance.new("Frame")
glow2.Position = UDim2.fromOffset(-4, -4)
glow2.Size = UDim2.new(1, 8, 1, 8)
glow2.BackgroundColor3 = BLUE_LIGHT
glow2.BackgroundTransparency = 0.85
glow2.BorderSizePixel = 0
glow2.Parent = Root
corner(glow2, 25)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromScale(1, 1)
Main.BackgroundColor3 = WHITE
Main.BackgroundTransparency = 0.12
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Root
corner(Main, 22)
local bg = Instance.new("UIGradient")
bg.Color = ColorSequence.new(PANEL_TOP, PANEL_BOT)
bg.Rotation = 90
bg.Parent = Main
local mainStroke = stroke(Main, BLUE_LIGHT, 1.6, 0.05)
local sg = Instance.new("UIGradient")
sg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(147, 197, 253)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(47, 107, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(147, 197, 253)),
})
sg.Rotation = 90
sg.Parent = mainStroke

-- Kilap kaca di bagian atas
local sheen = Instance.new("Frame")
sheen.Size = UDim2.new(1, 0, 0.5, 0)
sheen.BackgroundColor3 = WHITE
sheen.BorderSizePixel = 0
sheen.Parent = Main
local shg = Instance.new("UIGradient")
shg.Transparency = NumberSequence.new(0.9, 1)
shg.Rotation = 90
shg.Parent = sheen

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundTransparency = 1
Header.Parent = Main
makeDraggable(Header, Root, UIScaler)

makeLogo(Header, 46, UDim2.fromOffset(12, 9))

local vline = Instance.new("Frame")
vline.Size = UDim2.fromOffset(1, 36)
vline.Position = UDim2.fromOffset(68, 14)
vline.BackgroundColor3 = WHITE
vline.BackgroundTransparency = 0.85
vline.BorderSizePixel = 0
vline.Parent = Header

label(Header, "FPS Performance", 17, WHITE, Enum.Font.GothamBold,
    UDim2.fromOffset(78, 11), UDim2.fromOffset(160, 22))
label(Header, "by zaamochy", 12, SUB, Enum.Font.Gotham,
    UDim2.fromOffset(78, 33), UDim2.fromOffset(160, 18))

local function headBtn(txt, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(30, 30)
    b.Position = UDim2.new(1, x, 0, 17)
    b.BackgroundColor3 = ROW
    b.BackgroundTransparency = 0.35
    b.Text = txt
    b.TextColor3 = WHITE
    b.TextSize = 16
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = true
    b.Parent = Header
    corner(b, 11)
    stroke(b, WHITE, 1, 0.85)
    return b
end
local MinBtn = headBtn("–", -80)
local CloseBtn = headBtn("✕", -44)

local function hline(y)
    local l = Instance.new("Frame")
    l.Size = UDim2.new(1, -28, 0, 1)
    l.Position = UDim2.fromOffset(14, y)
    l.BackgroundColor3 = WHITE
    l.BackgroundTransparency = 0.88
    l.BorderSizePixel = 0
    l.Parent = Main
    return l
end
hline(64)

-- Tab
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 34)
TabBar.Position = UDim2.fromOffset(12, 72)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main
local tl = Instance.new("UIListLayout")
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 6)
tl.Parent = TabBar

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -24, 0, 214)
Body.Position = UDim2.fromOffset(12, 114)
Body.BackgroundTransparency = 1
Body.ClipsDescendants = true
Body.Parent = Main

local pages, tabs = {}, {}

local function newPage(name)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.fromScale(1, 1)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = BLUE_LIGHT
    p.CanvasSize = UDim2.new()
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.Parent = Body
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.Parent = p
    pages[name] = p
    return p
end

local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, t in pairs(tabs) do
        local on = (n == name)
        t.btn.BackgroundColor3 = on and WHITE or ROW
        t.btn.BackgroundTransparency = on and 0 or 0.4
        t.grad.Enabled = on
        t.stroke.Color = on and Color3.fromRGB(147, 197, 253) or WHITE
        t.stroke.Transparency = on and 0.1 or 0.85
    end
end

local function newTab(name, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / 3, -4, 1, 0)
    b.Text = text
    b.TextColor3 = WHITE
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = TabBar
    corner(b, 17)
    local s = stroke(b, WHITE, 1.2, 0.85)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.fromRGB(37, 99, 235), Color3.fromRGB(56, 160, 255))
    g.Rotation = 90
    g.Parent = b
    tabs[name] = { btn = b, grad = g, stroke = s }
    b.Activated:Connect(function() selectTab(name) end)
    newPage(name)
end

newTab("Combat", "⚔  Combat")
newTab("Rendering", "▣  Rendering")
newTab("Misc", "⚙  Misc")

-- Baris toggle
local function addRow(page, icon, title, desc, onFn, offFn)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 48)
    row.BackgroundColor3 = ROW
    row.BackgroundTransparency = 0.45
    row.Parent = page
    corner(row, 14)
    stroke(row, WHITE, 1, 0.9)

    label(row, icon, 22, WHITE, Enum.Font.GothamMedium,
        UDim2.fromOffset(6, 0), UDim2.fromOffset(38, 48), Enum.TextXAlignment.Center)
    label(row, title, 14, WHITE, Enum.Font.GothamBold,
        UDim2.fromOffset(50, 6), UDim2.new(1, -120, 0, 18))
    label(row, desc, 11, SUB, Enum.Font.Gotham,
        UDim2.fromOffset(50, 25), UDim2.new(1, -120, 0, 16))

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.fromOffset(46, 24)
    sw.Position = UDim2.new(1, -58, 0.5, -12)
    sw.BackgroundColor3 = Color3.fromRGB(55, 66, 105)
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = row
    corner(sw, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = WHITE
    knob.Parent = sw
    corner(knob, 9)

    local state = false
    local function set(v)
        if v == state then return end
        state = v
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = v and BLUE or Color3.fromRGB(55, 66, 105),
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
        }):Play()
        task.spawn(function() pcall(v and onFn or offFn) end)
    end
    sw.Activated:Connect(function() set(not state) end)
    return set
end

local setters = {}
local C, R, M = pages.Combat, pages.Rendering, pages.Misc

setters[#setters + 1] = addRow(C, "☀", "Full Bright", "Make the game brighter",
    Features.FullBright.on, Features.FullBright.off)
setters[#setters + 1] = addRow(C, "☁", "No Fog", "Remove fog effect",
    Features.NoFog.on, Features.NoFog.off)
setters[#setters + 1] = addRow(C, "◐", "No Shadow", "Disable shadows",
    Features.NoShadow.on, Features.NoShadow.off)
setters[#setters + 1] = addRow(C, "✿", "Low Grafik", "Reduce graphic quality",
    Features.LowGrafik.on, Features.LowGrafik.off)

setters[#setters + 1] = addRow(R, "▦", "Material Polos", "Hapus tekstur, jadi polos",
    Features.PlainMaterial.on, Features.PlainMaterial.off)
setters[#setters + 1] = addRow(R, "✦", "No Efek", "Matikan partikel, efek & decal",
    Features.NoEffects.on, Features.NoEffects.off)

----------------------------------------------------------------
-- FPS & Ping counter (tengah atas, bisa digeser)
----------------------------------------------------------------
local Counter = Instance.new("Frame")
Counter.Size = UDim2.fromOffset(190, 36)
Counter.Position = UDim2.new(0.5, -95, 0, 8)
Counter.BackgroundColor3 = Color3.fromRGB(14, 28, 80)
Counter.BackgroundTransparency = 0.2
Counter.Visible = false
Counter.Parent = Gui
corner(Counter, 18)
local cst = stroke(Counter, BLUE_LIGHT, 1.4, 0.15)
local cg = Instance.new("UIGradient")
cg.Color = ColorSequence.new(Color3.fromRGB(34, 211, 238), Color3.fromRGB(139, 92, 246))
cg.Parent = cst

local CounterText = label(Counter, "", 16, WHITE, Enum.Font.GothamBold,
    UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
CounterText.RichText = true
local function setCounter(fps, ping)
    CounterText.Text = string.format(
        '<font color="%s">%d FPS</font> <font color="#FFFFFF">|</font> <font color="%s">%dms</font>',
        CYAN, fps, PURPLE, ping)
end
setCounter(0, 0)
makeDraggable(Counter, Counter)

local counterConn
local function counterOn()
    Counter.Visible = true
    local frames, t0 = 0, os.clock()
    counterConn = RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - t0 >= 0.5 then
            local fps = math.floor(frames / (now - t0) + 0.5)
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
            end)
            setCounter(fps, ping)
            frames, t0 = 0, now
        end
    end)
end
local function counterOff()
    Counter.Visible = false
    if counterConn then counterConn:Disconnect() end
end

setters[#setters + 1] = addRow(M, "▂▄▆", "FPS & Ping", "Counter di tengah atas layar", counterOn, counterOff)
setters[#setters + 1] = addRow(M, "◎", "Anti AFK", "Cegah kick karena diam",
    Features.AntiAFK.on, Features.AntiAFK.off)

----------------------------------------------------------------
-- Footer
----------------------------------------------------------------
hline(H - 48)

label(Main, "▂▄▆", 15, BLUE, Enum.Font.GothamBold,
    UDim2.new(0, 16, 1, -40), UDim2.fromOffset(34, 30))
local FootText = label(Main, "<i>Optimized for maximum FPS</i>", 11, SUB, Enum.Font.Gotham,
    UDim2.new(0, 52, 1, -40), UDim2.new(1, -190, 0, 30))
FootText.RichText = true

local fdiv = Instance.new("Frame")
fdiv.Size = UDim2.fromOffset(1, 24)
fdiv.Position = UDim2.new(1, -128, 1, -37)
fdiv.BackgroundColor3 = WHITE
fdiv.BackgroundTransparency = 0.85
fdiv.BorderSizePixel = 0
fdiv.Parent = Main

local Tag = Instance.new("Frame")
Tag.Size = UDim2.fromOffset(106, 28)
Tag.Position = UDim2.new(1, -118, 1, -38)
Tag.BackgroundColor3 = Color3.fromRGB(14, 28, 80)
Tag.BackgroundTransparency = 0.25
Tag.Parent = Main
corner(Tag, 14)
stroke(Tag, BLUE_LIGHT, 1.2, 0.35)
makeLogo(Tag, 20, UDim2.fromOffset(6, 4))
local TagText = label(Tag, 'by <font color="#93C5FD">zaamochy</font>', 12, WHITE,
    Enum.Font.GothamBold, UDim2.fromOffset(30, 0), UDim2.new(1, -32, 1, 0))
TagText.RichText = true

----------------------------------------------------------------
-- Tombol bulat buka/tutup menu
----------------------------------------------------------------
local Orb = Instance.new("TextButton")
Orb.Size = UDim2.fromOffset(52, 52)
Orb.Position = UDim2.new(1, -68, 0.35, 0)
Orb.BackgroundColor3 = Color3.fromRGB(14, 28, 80)
Orb.BackgroundTransparency = 0.15
Orb.Text = ""
Orb.AutoButtonColor = false
Orb.Parent = Gui
corner(Orb, 16)
stroke(Orb, BLUE_LIGHT, 1.6, 0.1)
makeLogo(Orb, 40, UDim2.fromOffset(6, 6))
makeDraggable(Orb, Orb)
Orb.Activated:Connect(function() Root.Visible = not Root.Visible end)
MinBtn.Activated:Connect(function() Root.Visible = false end)

CloseBtn.Activated:Connect(function()
    for _, s in ipairs(setters) do pcall(s, false) end
    spinConn:Disconnect()
    task.wait(0.3)
    Gui:Destroy()
end)

selectTab("Combat")
