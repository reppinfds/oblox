-- ================================================
--   AUTO WALKER v4.0
--   Chiyo-inspired UI
--   Logo minimize | 2-column layout
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local isWalking = false
local isPaused = false
local walkerConnection = nil
local isLooping = true
local isOpen = true
local SAVE_FILE = "walker_routes.json"
local REACH_DIST = 4

local routes = {}
local routeNames = {}

local function loadRoutes()
    if isfile and isfile(SAVE_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end)
        if ok and data then
            routes = data
            routeNames = {}
            for name, _ in pairs(routes) do table.insert(routeNames, name) end
            table.sort(routeNames)
        end
    end
end
loadRoutes()

if player.PlayerGui:FindFirstChild("AutoWalkerGUI") then
    player.PlayerGui.AutoWalkerGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoWalkerGUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = player.PlayerGui

-- =====================
--   COLORS
-- =====================
local C = {
    bg       = Color3.fromRGB(28, 28, 34),
    surface  = Color3.fromRGB(36, 36, 44),
    surface2 = Color3.fromRGB(44, 44, 54),
    border   = Color3.fromRGB(55, 55, 70),
    accent   = Color3.fromRGB(100, 200, 255),
    green    = Color3.fromRGB(60, 200, 110),
    yellow   = Color3.fromRGB(230, 175, 50),
    red      = Color3.fromRGB(220, 75, 75),
    textPri  = Color3.fromRGB(225, 225, 235),
    textSec  = Color3.fromRGB(130, 130, 155),
    textDim  = Color3.fromRGB(70, 70, 90),
}

local function corner(p, r) Instance.new("UICorner", p).CornerRadius = UDim.new(0, r or 8) end
local function uistroke(p, c, t)
    local s = Instance.new("UIStroke", p)
    s.Color = c or C.border
    s.Thickness = t or 1
end

-- =====================
--   LOGO BUTTON (always visible)
-- =====================
local logoBtn = Instance.new("ImageButton")
logoBtn.Size = UDim2.new(0, 46, 0, 46)
logoBtn.Position = UDim2.new(0, 12, 0, 12)
logoBtn.BackgroundColor3 = C.bg
logoBtn.BorderSizePixel = 0
logoBtn.Image = ""
logoBtn.Parent = screenGui
corner(logoBtn, 23)
uistroke(logoBtn, C.accent, 2)

-- Logo text fallback
local logoLbl = Instance.new("TextLabel", logoBtn)
logoLbl.Size = UDim2.new(1, 0, 1, 0)
logoLbl.BackgroundTransparency = 1
logoLbl.Text = "AW"
logoLbl.TextColor3 = C.accent
logoLbl.TextSize = 14
logoLbl.Font = Enum.Font.GothamBold

-- Status dot on logo
local logoDot = Instance.new("Frame", logoBtn)
logoDot.Size = UDim2.new(0, 10, 0, 10)
logoDot.Position = UDim2.new(1, -11, 1, -11)
logoDot.BackgroundColor3 = C.textDim
logoDot.BorderSizePixel = 0
corner(logoDot, 5)

-- =====================
--   MAIN PANEL
-- =====================
local PANEL_W = 320
local PANEL_H = 420

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
panel.Position = UDim2.new(0, 66, 0, 6)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = screenGui
corner(panel, 12)
uistroke(panel, C.border, 1)

-- =====================
--   HEADER
-- =====================
local header = Instance.new("Frame", panel)
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = C.surface
header.BorderSizePixel = 0
corner(header, 12)

local headerFix = Instance.new("Frame", header)
headerFix.Size = UDim2.new(1, 0, 0.5, 0)
headerFix.Position = UDim2.new(0, 0, 0.5, 0)
headerFix.BackgroundColor3 = C.surface
headerFix.BorderSizePixel = 0

local headerTitle = Instance.new("TextLabel", header)
headerTitle.Size = UDim2.new(1, -16, 1, 0)
headerTitle.Position = UDim2.new(0, 16, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "AUTO WALKER"
headerTitle.TextColor3 = C.textPri
headerTitle.TextSize = 13
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextXAlignment = Enum.TextXAlignment.Left

local versionLbl = Instance.new("TextLabel", header)
versionLbl.Size = UDim2.new(0, 60, 1, 0)
versionLbl.Position = UDim2.new(1, -66, 0, 0)
versionLbl.BackgroundTransparency = 1
versionLbl.Text = "v4.0"
versionLbl.TextColor3 = C.textDim
versionLbl.TextSize = 10
versionLbl.Font = Enum.Font.GothamBold
versionLbl.TextXAlignment = Enum.TextXAlignment.Right

-- =====================
--   CONTENT (2 columns)
-- =====================
local content = Instance.new("Frame", panel)
content.Size = UDim2.new(1, -16, 1, -52)
content.Position = UDim2.new(0, 8, 0, 48)
content.BackgroundTransparency = 1

-- LEFT COLUMN
local leftCol = Instance.new("Frame", content)
leftCol.Size = UDim2.new(0.5, -4, 1, 0)
leftCol.BackgroundTransparency = 1

local leftLayout = Instance.new("UIListLayout", leftCol)
leftLayout.Padding = UDim.new(0, 6)
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- RIGHT COLUMN
local rightCol = Instance.new("Frame", content)
rightCol.Size = UDim2.new(0.5, -4, 1, 0)
rightCol.Position = UDim2.new(0.5, 4, 0, 0)
rightCol.BackgroundTransparency = 1

local rightLayout = Instance.new("UIListLayout", rightCol)
rightLayout.Padding = UDim.new(0, 6)
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- =====================
--   HELPERS
-- =====================
local function makeCard(parent, height, order)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = C.surface
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    corner(card, 8)
    uistroke(card, C.border)
    return card
end

local function cardLabel(parent, text, posY)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, -12, 0, 14)
    l.Position = UDim2.new(0, 8, 0, posY)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.textDim
    l.TextSize = 9
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function makeBtn(parent, text, color, size, pos)
    local b = Instance.new("TextButton", parent)
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    corner(b, 6)
    local orig = color
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = orig:Lerp(Color3.fromRGB(255,255,255), 0.15)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = orig}):Play()
    end)
    return b
end

-- =====================
--   LEFT: STATUS CARD
-- =====================
local statusCard = makeCard(leftCol, 76, 1)

cardLabel(statusCard, "STATUS", 6)

local statusDot = Instance.new("Frame", statusCard)
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 8, 0, 26)
statusDot.BackgroundColor3 = C.textDim
statusDot.BorderSizePixel = 0
corner(statusDot, 4)

local statusLbl = Instance.new("TextLabel", statusCard)
statusLbl.Size = UDim2.new(1, -24, 0, 16)
statusLbl.Position = UDim2.new(0, 20, 0, 23)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Idle"
statusLbl.TextColor3 = C.textPri
statusLbl.TextSize = 12
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

local segLbl = Instance.new("TextLabel", statusCard)
segLbl.Size = UDim2.new(1, -12, 0, 12)
segLbl.Position = UDim2.new(0, 8, 0, 44)
segLbl.BackgroundTransparency = 1
segLbl.Text = "Segment: —"
segLbl.TextColor3 = C.textSec
segLbl.TextSize = 9
segLbl.Font = Enum.Font.Gotham
segLbl.TextXAlignment = Enum.TextXAlignment.Left

local progressLbl = Instance.new("TextLabel", statusCard)
progressLbl.Size = UDim2.new(1, -12, 0, 12)
progressLbl.Position = UDim2.new(0, 8, 0, 58)
progressLbl.BackgroundTransparency = 1
progressLbl.Text = "Progress: —"
progressLbl.TextColor3 = C.textDim
progressLbl.TextSize = 9
progressLbl.Font = Enum.Font.Gotham
progressLbl.TextXAlignment = Enum.TextXAlignment.Left

-- =====================
--   LEFT: ROUTE LIST
-- =====================
local routeCard = makeCard(leftCol, 175, 2)
cardLabel(routeCard, "ROUTE", 6)

local routeScroll = Instance.new("ScrollingFrame", routeCard)
routeScroll.Size = UDim2.new(1, -8, 1, -24)
routeScroll.Position = UDim2.new(0, 4, 0, 22)
routeScroll.BackgroundTransparency = 1
routeScroll.BorderSizePixel = 0
routeScroll.ScrollBarThickness = 2
routeScroll.ScrollBarImageColor3 = C.border
routeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local rLayout = Instance.new("UIListLayout", routeScroll)
rLayout.Padding = UDim.new(0, 2)
Instance.new("UIPadding", routeScroll).PaddingTop = UDim.new(0, 2)

-- =====================
--   LEFT: LOOP TOGGLE
-- =====================
local loopCard = makeCard(leftCol, 34, 3)

local loopLbl = Instance.new("TextLabel", loopCard)
loopLbl.Size = UDim2.new(0.6, 0, 1, 0)
loopLbl.Position = UDim2.new(0, 10, 0, 0)
loopLbl.BackgroundTransparency = 1
loopLbl.Text = "Loop (AFK)"
loopLbl.TextColor3 = C.textSec
loopLbl.TextSize = 11
loopLbl.Font = Enum.Font.Gotham
loopLbl.TextXAlignment = Enum.TextXAlignment.Left

local loopToggle = Instance.new("TextButton", loopCard)
loopToggle.Size = UDim2.new(0, 42, 0, 22)
loopToggle.Position = UDim2.new(1, -48, 0.5, -11)
loopToggle.BackgroundColor3 = C.green
loopToggle.BorderSizePixel = 0
loopToggle.Text = "ON"
loopToggle.TextColor3 = Color3.fromRGB(255,255,255)
loopToggle.TextSize = 10
loopToggle.Font = Enum.Font.GothamBold
corner(loopToggle, 6)

-- =====================
--   RIGHT: SEGMENT LIST
-- =====================
local segCard = makeCard(rightCol, 175, 1)
cardLabel(segCard, "SEGMENTS", 6)

local segScroll = Instance.new("ScrollingFrame", segCard)
segScroll.Size = UDim2.new(1, -8, 1, -24)
segScroll.Position = UDim2.new(0, 4, 0, 22)
segScroll.BackgroundTransparency = 1
segScroll.BorderSizePixel = 0
segScroll.ScrollBarThickness = 2
segScroll.ScrollBarImageColor3 = C.border
segScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local sLayout = Instance.new("UIListLayout", segScroll)
sLayout.Padding = UDim.new(0, 2)
Instance.new("UIPadding", segScroll).PaddingTop = UDim.new(0, 2)

-- =====================
--   RIGHT: CONTROLS
-- =====================
local ctrlCard = makeCard(rightCol, 112, 2)
cardLabel(ctrlCard, "CONTROLS", 6)

local startBtn = makeBtn(ctrlCard, "▶  Start", C.green,
    UDim2.new(1, -12, 0, 28), UDim2.new(0, 6, 0, 22))

local pauseBtn = makeBtn(ctrlCard, "⏸  Pause", C.yellow,
    UDim2.new(0.5, -8, 0, 26), UDim2.new(0, 6, 0, 56))

local stopBtn = makeBtn(ctrlCard, "⏹  Stop", C.red,
    UDim2.new(0.5, -8, 0, 26), UDim2.new(0.5, 2, 0, 56))

local refreshBtn = Instance.new("TextButton", ctrlCard)
refreshBtn.Size = UDim2.new(1, -12, 0, 18)
refreshBtn.Position = UDim2.new(0, 6, 0, 88)
refreshBtn.BackgroundTransparency = 1
refreshBtn.Text = "↻ Refresh Routes"
refreshBtn.TextColor3 = C.textDim
refreshBtn.TextSize = 9
refreshBtn.Font = Enum.Font.Gotham

-- =====================
--   MINI BAR (saat walking, di bawah)
-- =====================
local miniBar = Instance.new("Frame", screenGui)
miniBar.Size = UDim2.new(0, 210, 0, 42)
miniBar.Position = UDim2.new(0.5, -105, 1, -58)
miniBar.BackgroundColor3 = C.surface
miniBar.BorderSizePixel = 0
miniBar.Visible = false
miniBar.Active = true
miniBar.Draggable = true
corner(miniBar, 21)
uistroke(miniBar, C.accent, 1.5)

local miniDot = Instance.new("Frame", miniBar)
miniDot.Size = UDim2.new(0, 8, 0, 8)
miniDot.Position = UDim2.new(0, 12, 0.5, -4)
miniDot.BackgroundColor3 = C.green
miniDot.BorderSizePixel = 0
corner(miniDot, 4)

local miniLbl = Instance.new("TextLabel", miniBar)
miniLbl.Size = UDim2.new(0, 100, 1, 0)
miniLbl.Position = UDim2.new(0, 26, 0, 0)
miniLbl.BackgroundTransparency = 1
miniLbl.Text = "Walking..."
miniLbl.TextColor3 = C.textPri
miniLbl.TextSize = 10
miniLbl.Font = Enum.Font.GothamBold
miniLbl.TextXAlignment = Enum.TextXAlignment.Left
miniLbl.TextTruncate = Enum.TextTruncate.AtEnd

local miniPauseBtn = Instance.new("TextButton", miniBar)
miniPauseBtn.Size = UDim2.new(0, 32, 0, 28)
miniPauseBtn.Position = UDim2.new(1, -76, 0.5, -14)
miniPauseBtn.BackgroundColor3 = C.yellow
miniPauseBtn.BorderSizePixel = 0
miniPauseBtn.Text = "⏸"
miniPauseBtn.TextColor3 = Color3.fromRGB(255,255,255)
miniPauseBtn.TextSize = 13
miniPauseBtn.Font = Enum.Font.GothamBold
corner(miniPauseBtn, 7)

local miniStopBtn = Instance.new("TextButton", miniBar)
miniStopBtn.Size = UDim2.new(0, 32, 0, 28)
miniStopBtn.Position = UDim2.new(1, -40, 0.5, -14)
miniStopBtn.BackgroundColor3 = C.red
miniStopBtn.BorderSizePixel = 0
miniStopBtn.Text = "⏹"
miniStopBtn.TextColor3 = Color3.fromRGB(255,255,255)
miniStopBtn.TextSize = 13
miniStopBtn.Font = Enum.Font.GothamBold
corner(miniStopBtn, 7)

-- =====================
--   TOGGLE PANEL
-- =====================
local function setOpen(v)
    isOpen = v
    panel.Visible = v
    logoDot.BackgroundColor3 = v and C.textDim or (isWalking and C.green or C.textDim)
    TweenService:Create(logoBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = v and C.bg or C.surface
    }):Play()
end

logoBtn.MouseButton1Click:Connect(function()
    setOpen(not isOpen)
end)

-- =====================
--   LIST BUILDERS
-- =====================
local selectedRoute = nil
local selectedRouteBtn = nil

local function buildSegmentList(routeName)
    for _, c in pairs(segScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    if not routes[routeName] then return end
    local order = routes[routeName].order or {}
    local segments = routes[routeName].segments or {}

    if #order == 0 then
        local e = Instance.new("TextLabel", segScroll)
        e.Size = UDim2.new(1, 0, 0, 22)
        e.BackgroundTransparency = 1
        e.Text = "Tidak ada segment"
        e.TextColor3 = C.textDim
        e.TextSize = 9
        e.Font = Enum.Font.Gotham
        return
    end

    for i, segName in ipairs(order) do
        local pts = segments[segName] and #segments[segName] or 0
        local row = Instance.new("Frame", segScroll)
        row.Size = UDim2.new(1, 0, 0, 26)
        row.BackgroundColor3 = C.surface2
        row.BorderSizePixel = 0
        corner(row, 5)

        local n = Instance.new("TextLabel", row)
        n.Size = UDim2.new(0, 16, 1, 0)
        n.Position = UDim2.new(0, 5, 0, 0)
        n.BackgroundTransparency = 1
        n.Text = tostring(i)
        n.TextColor3 = C.accent
        n.TextSize = 9
        n.Font = Enum.Font.GothamBold

        local nm = Instance.new("TextLabel", row)
        nm.Size = UDim2.new(1, -55, 1, 0)
        nm.Position = UDim2.new(0, 22, 0, 0)
        nm.BackgroundTransparency = 1
        nm.Text = segName
        nm.TextColor3 = C.textSec
        nm.TextSize = 9
        nm.Font = Enum.Font.Gotham
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.TextTruncate = Enum.TextTruncate.AtEnd

        local p = Instance.new("TextLabel", row)
        p.Size = UDim2.new(0, 44, 1, 0)
        p.Position = UDim2.new(1, -46, 0, 0)
        p.BackgroundTransparency = 1
        p.Text = pts .. "p"
        p.TextColor3 = C.textDim
        p.TextSize = 8
        p.Font = Enum.Font.Gotham
        p.TextXAlignment = Enum.TextXAlignment.Right
    end

    segScroll.CanvasSize = UDim2.new(0, 0, 0, sLayout.AbsoluteContentSize.Y + 4)
end

local function updateRouteList()
    for _, c in pairs(routeScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end

    if #routeNames == 0 then
        local e = Instance.new("TextLabel", routeScroll)
        e.Size = UDim2.new(1, 0, 0, 26)
        e.BackgroundTransparency = 1
        e.Text = "Belum ada route"
        e.TextColor3 = C.textDim
        e.TextSize = 9
        e.Font = Enum.Font.Gotham
        return
    end

    for _, name in ipairs(routeNames) do
        local r = routes[name]
        local sc = r and r.order and #r.order or 0
        local b = Instance.new("TextButton", routeScroll)
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = C.surface2
        b.BorderSizePixel = 0
        b.Text = ""
        corner(b, 6)

        local nm = Instance.new("TextLabel", b)
        nm.Size = UDim2.new(1, -44, 1, 0)
        nm.Position = UDim2.new(0, 8, 0, 0)
        nm.BackgroundTransparency = 1
        nm.Text = name
        nm.TextColor3 = C.textPri
        nm.TextSize = 10
        nm.Font = Enum.Font.Gotham
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.TextTruncate = Enum.TextTruncate.AtEnd

        local sc_lbl = Instance.new("TextLabel", b)
        sc_lbl.Size = UDim2.new(0, 40, 1, 0)
        sc_lbl.Position = UDim2.new(1, -42, 0, 0)
        sc_lbl.BackgroundTransparency = 1
        sc_lbl.Text = sc .. " seg"
        sc_lbl.TextColor3 = C.textDim
        sc_lbl.TextSize = 8
        sc_lbl.Font = Enum.Font.Gotham
        sc_lbl.TextXAlignment = Enum.TextXAlignment.Right

        b.MouseButton1Click:Connect(function()
            if selectedRouteBtn then
                selectedRouteBtn.BackgroundColor3 = C.surface2
                for _, ch in pairs(selectedRouteBtn:GetChildren()) do
                    if ch:IsA("TextLabel") then ch.TextColor3 = C.textPri end
                end
            end
            selectedRoute = name
            selectedRouteBtn = b
            b.BackgroundColor3 = Color3.fromRGB(30, 55, 100)
            nm.TextColor3 = C.accent
            buildSegmentList(name)
            statusLbl.Text = name
            statusLbl.TextColor3 = C.accent
            statusDot.BackgroundColor3 = C.accent
        end)
    end

    routeScroll.CanvasSize = UDim2.new(0, 0, 0, rLayout.AbsoluteContentSize.Y + 4)
end

updateRouteList()

-- =====================
--   WALK LOGIC
-- =====================
local flatPath = {}
local segmentMap = {}
local currentIndex = 1

local function buildFlatPath(routeName)
    flatPath = {}
    segmentMap = {}
    if not routes[routeName] then return end
    local order = routes[routeName].order or {}
    local segments = routes[routeName].segments or {}
    for _, segName in ipairs(order) do
        local pts = segments[segName]
        if pts then
            for _, pt in ipairs(pts) do
                table.insert(flatPath, pt)
                table.insert(segmentMap, segName)
            end
        end
    end
end

local function setStatus(text, color, dotColor)
    statusLbl.Text = text
    statusLbl.TextColor3 = color or C.textPri
    statusDot.BackgroundColor3 = dotColor or C.textDim
    logoDot.BackgroundColor3 = dotColor or C.textDim
end

local function stopWalking()
    isWalking = false
    isPaused = false
    if walkerConnection then walkerConnection:Disconnect() walkerConnection = nil end
    currentIndex = 1
    setStatus("Stopped", C.red, C.red)
    segLbl.Text = "Segment: —"
    progressLbl.Text = "Progress: —"
    miniBar.Visible = false
    miniPauseBtn.Text = "⏸"
    miniPauseBtn.BackgroundColor3 = C.yellow
    setOpen(true)
end

local function startWalking()
    if not selectedRoute then
        setStatus("Pilih route!", C.red, C.red)
        return
    end
    buildFlatPath(selectedRoute)
    if #flatPath == 0 then
        setStatus("Route kosong!", C.red, C.red)
        return
    end

    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    isWalking = true
    isPaused = false
    currentIndex = 1
    setStatus("Walking", C.green, C.green)
    miniBar.Visible = true
    miniLbl.Text = "Starting..."
    miniDot.BackgroundColor3 = C.green

    -- Auto tutup panel setelah 1.5 detik
    task.delay(1.5, function()
        if isWalking then setOpen(false) end
    end)

    walkerConnection = RunService.Heartbeat:Connect(function()
        if not isWalking or isPaused then return end
        if currentIndex > #flatPath then
            if isLooping then
                currentIndex = 1
            else
                stopWalking()
                setStatus("Done ✓", C.accent, C.accent)
                return
            end
        end

        local pt = flatPath[currentIndex]
        local target = Vector3.new(pt[1], pt[2], pt[3])
        local dist = (rootPart.Position - target).Magnitude
        if dist < REACH_DIST then
            currentIndex += 1
        else
            humanoid:MoveTo(target)
        end

        local curSeg = segmentMap[currentIndex] or "—"
        segLbl.Text = "Segment: " .. curSeg
        progressLbl.Text = currentIndex .. " / " .. #flatPath
        miniLbl.Text = curSeg .. "  " .. currentIndex .. "/" .. #flatPath
    end)
end

-- =====================
--   BUTTON EVENTS
-- =====================
startBtn.MouseButton1Click:Connect(function()
    if isPaused then
        isPaused = false
        setStatus("Walking", C.green, C.green)
        miniDot.BackgroundColor3 = C.green
        miniPauseBtn.Text = "⏸"
        miniPauseBtn.BackgroundColor3 = C.yellow
    else
        if walkerConnection then stopWalking() end
        startWalking()
    end
end)

local function doPause()
    if not isWalking then return end
    isPaused = not isPaused
    if isPaused then
        pcall(function() humanoid:MoveTo(rootPart.Position) end)
        setStatus("Paused", C.yellow, C.yellow)
        miniDot.BackgroundColor3 = C.yellow
        miniPauseBtn.Text = "▶"
        miniPauseBtn.BackgroundColor3 = C.green
        miniLbl.Text = "Paused"
    else
        setStatus("Walking", C.green, C.green)
        miniDot.BackgroundColor3 = C.green
        miniPauseBtn.Text = "⏸"
        miniPauseBtn.BackgroundColor3 = C.yellow
    end
end

pauseBtn.MouseButton1Click:Connect(doPause)
miniPauseBtn.MouseButton1Click:Connect(doPause)

local function doStop()
    stopWalking()
    pcall(function() humanoid:MoveTo(rootPart.Position) end)
end

stopBtn.MouseButton1Click:Connect(doStop)
miniStopBtn.MouseButton1Click:Connect(doStop)

loopToggle.MouseButton1Click:Connect(function()
    isLooping = not isLooping
    loopToggle.Text = isLooping and "ON" or "OFF"
    loopToggle.BackgroundColor3 = isLooping and C.green or C.textDim
end)

refreshBtn.MouseButton1Click:Connect(function()
    loadRoutes()
    routeNames = {}
    for name, _ in pairs(routes) do table.insert(routeNames, name) end
    table.sort(routeNames)
    updateRouteList()
    selectedRoute = nil
    selectedRouteBtn = nil
    for _, c in pairs(segScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    setStatus("Refreshed ✓", C.accent, C.accent)
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    if isWalking then task.wait(1) startWalking() end
end)

print("[AutoWalker v4] Loaded!")
