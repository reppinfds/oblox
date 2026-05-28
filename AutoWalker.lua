-- ================================================
--   AUTO WALKER v1.0
--   Pilih route & auto walk AFK
--   By: kamu sendiri :)
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- =====================
--       STATE
-- =====================
local isWalking = false
local isPaused = false
local walkerConnection = nil
local currentPath = {}
local currentIndex = 1
local isLooping = true
local SAVE_FILE = "walker_routes.json"
local REACH_DIST = 4

-- =====================
--    LOAD ROUTES
-- =====================
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
            for name, _ in pairs(routes) do
                table.insert(routeNames, name)
            end
            table.sort(routeNames)
        end
    end
end

loadRoutes()

-- =====================
--        GUI
-- =====================
if player.PlayerGui:FindFirstChild("AutoWalkerGUI") then
    player.PlayerGui.AutoWalkerGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoWalkerGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 360)
mainFrame.Position = UDim2.new(1, -260, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(60, 60, 100)
stroke.Thickness = 1.2

-- Title Bar
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
titleBar.BorderSizePixel = 0

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local tfix = Instance.new("Frame", titleBar)
tfix.Size = UDim2.new(1, 0, 0.5, 0)
tfix.Position = UDim2.new(0, 0, 0.5, 0)
tfix.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
tfix.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -16, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "◈  AUTO WALKER"
titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Status
local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, -20, 0, 22)
statusLabel.Position = UDim2.new(0, 10, 0, 58)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Progress
local progressLabel = Instance.new("TextLabel", mainFrame)
progressLabel.Size = UDim2.new(1, -20, 0, 20)
progressLabel.Position = UDim2.new(0, 10, 0, 78)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "Progress: -"
progressLabel.TextColor3 = Color3.fromRGB(80, 80, 120)
progressLabel.TextSize = 11
progressLabel.Font = Enum.Font.Gotham
progressLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Divider
local div1 = Instance.new("Frame", mainFrame)
div1.Size = UDim2.new(1, -20, 0, 1)
div1.Position = UDim2.new(0, 10, 0, 106)
div1.BackgroundColor3 = Color3.fromRGB(35, 35, 65)
div1.BorderSizePixel = 0

-- Route Label
local routeLabel = Instance.new("TextLabel", mainFrame)
routeLabel.Size = UDim2.new(1, -20, 0, 20)
routeLabel.Position = UDim2.new(0, 10, 0, 116)
routeLabel.BackgroundTransparency = 1
routeLabel.Text = "Pilih Route:"
routeLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
routeLabel.TextSize = 11
routeLabel.Font = Enum.Font.Gotham
routeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Route List Container
local listContainer = Instance.new("ScrollingFrame", mainFrame)
listContainer.Size = UDim2.new(1, -20, 0, 110)
listContainer.Position = UDim2.new(0, 10, 0, 138)
listContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
listContainer.BorderSizePixel = 0
listContainer.ScrollBarThickness = 3
listContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 150)
listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)

Instance.new("UICorner", listContainer).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout", listContainer)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)

local listPadding = Instance.new("UIPadding", listContainer)
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)

-- Selected route tracker
local selectedRoute = nil
local selectedBtn = nil

local function updateRouteList()
    -- Clear existing buttons
    for _, child in pairs(listContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    if #routeNames == 0 then
        local empty = Instance.new("TextLabel", listContainer)
        empty.Size = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "Belum ada route tersimpan"
        empty.TextColor3 = Color3.fromRGB(70, 70, 100)
        empty.TextSize = 11
        empty.Font = Enum.Font.Gotham
        return
    end

    for _, name in ipairs(routeNames) do
        local pts = routes[name] and #routes[name] or 0
        local btn = Instance.new("TextButton", listContainer)
        btn.Size = UDim2.new(1, -4, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
        btn.BorderSizePixel = 0
        btn.Text = "  " .. name .. "  (" .. pts .. " pts)"
        btn.TextColor3 = Color3.fromRGB(160, 160, 200)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.TextXAlignment = Enum.TextXAlignment.Left

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            if selectedBtn then
                selectedBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
                selectedBtn.TextColor3 = Color3.fromRGB(160, 160, 200)
            end
            selectedRoute = name
            selectedBtn = btn
            btn.BackgroundColor3 = Color3.fromRGB(40, 60, 120)
            btn.TextColor3 = Color3.fromRGB(120, 180, 255)
            statusLabel.Text = "Status: Route dipilih"
            statusLabel.TextColor3 = Color3.fromRGB(100, 160, 255)
        end)
    end

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
    end)
    listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end

updateRouteList()

-- Divider 2
local div2 = Instance.new("Frame", mainFrame)
div2.Size = UDim2.new(1, -20, 0, 1)
div2.Position = UDim2.new(0, 10, 0, 256)
div2.BackgroundColor3 = Color3.fromRGB(35, 35, 65)
div2.BorderSizePixel = 0

-- Loop Toggle
local loopFrame = Instance.new("Frame", mainFrame)
loopFrame.Size = UDim2.new(1, -20, 0, 28)
loopFrame.Position = UDim2.new(0, 10, 0, 264)
loopFrame.BackgroundTransparency = 1

local loopLabel = Instance.new("TextLabel", loopFrame)
loopLabel.Size = UDim2.new(0.7, 0, 1, 0)
loopLabel.BackgroundTransparency = 1
loopLabel.Text = "Loop Mode (AFK):"
loopLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
loopLabel.TextSize = 11
loopLabel.Font = Enum.Font.Gotham
loopLabel.TextXAlignment = Enum.TextXAlignment.Left

local loopToggle = Instance.new("TextButton", loopFrame)
loopToggle.Size = UDim2.new(0, 44, 0, 22)
loopToggle.Position = UDim2.new(1, -44, 0.5, -11)
loopToggle.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
loopToggle.BorderSizePixel = 0
loopToggle.Text = "ON"
loopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
loopToggle.TextSize = 10
loopToggle.Font = Enum.Font.GothamBold

Instance.new("UICorner", loopToggle).CornerRadius = UDim.new(0, 6)

loopToggle.MouseButton1Click:Connect(function()
    isLooping = not isLooping
    if isLooping then
        loopToggle.Text = "ON"
        loopToggle.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
    else
        loopToggle.Text = "OFF"
        loopToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
    end
end)

-- Helper button
local function createBtn(text, color, posY)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0.31, 0, 0, 38)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Position = posY
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.12)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    return btn
end

local startBtn  = createBtn("▶ Start",  Color3.fromRGB(50, 160, 90),  UDim2.new(0, 10, 0, 302))
local pauseBtn  = createBtn("⏸ Pause",  Color3.fromRGB(200, 150, 40), UDim2.new(0.345, 0, 0, 302))
local stopBtn2  = createBtn("⏹ Stop",   Color3.fromRGB(190, 60, 60),  UDim2.new(0.69, 0, 0, 302))

-- Refresh button
local refreshBtn = Instance.new("TextButton", mainFrame)
refreshBtn.Size = UDim2.new(1, -20, 0, 0)
refreshBtn.Position = UDim2.new(0, 10, 1, -6)
refreshBtn.BackgroundTransparency = 1
refreshBtn.Text = "↻ Refresh Routes"
refreshBtn.TextColor3 = Color3.fromRGB(70, 70, 110)
refreshBtn.TextSize = 10
refreshBtn.Font = Enum.Font.Gotham

refreshBtn.MouseButton1Click:Connect(function()
    loadRoutes()
    updateRouteList()
    selectedRoute = nil
    selectedBtn = nil
    statusLabel.Text = "Status: Routes refreshed ✓"
    statusLabel.TextColor3 = Color3.fromRGB(100, 200, 150)
end)

-- =====================
--     WALK LOGIC
-- =====================
local function updateProgress()
    if #currentPath == 0 then
        progressLabel.Text = "Progress: -"
        return
    end
    progressLabel.Text = "Progress: " .. currentIndex .. " / " .. #currentPath
end

local function stopWalking()
    isWalking = false
    isPaused = false
    if walkerConnection then
        walkerConnection:Disconnect()
        walkerConnection = nil
    end
    currentIndex = 1
    statusLabel.Text = "Status: Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
    updateProgress()
end

local function startWalking()
    if not selectedRoute then
        statusLabel.Text = "Status: Pilih route dulu!"
        statusLabel.TextColor3 = Color3.fromRGB(220, 100, 80)
        return
    end

    currentPath = routes[selectedRoute]
    if not currentPath or #currentPath == 0 then
        statusLabel.Text = "Status: Route kosong!"
        statusLabel.TextColor3 = Color3.fromRGB(220, 100, 80)
        return
    end

    -- Refresh character reference
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    isWalking = true
    isPaused = false
    currentIndex = 1
    statusLabel.Text = "Status: Walking..."
    statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)

    walkerConnection = RunService.Heartbeat:Connect(function()
        if not isWalking or isPaused then return end
        if currentIndex > #currentPath then
            if isLooping then
                currentIndex = 1
            else
                stopWalking()
                statusLabel.Text = "Status: Done ✓"
                statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
                return
            end
        end

        local pt = currentPath[currentIndex]
        local target = Vector3.new(pt[1], pt[2], pt[3])
        local dist = (rootPart.Position - target).Magnitude

        if dist < REACH_DIST then
            currentIndex += 1
        else
            humanoid:MoveTo(target)
        end

        updateProgress()
    end)
end

-- =====================
--    BUTTON EVENTS
-- =====================
startBtn.MouseButton1Click:Connect(function()
    if isPaused then
        isPaused = false
        statusLabel.Text = "Status: Walking..."
        statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
    else
        if walkerConnection then stopWalking() end
        startWalking()
    end
end)

pauseBtn.MouseButton1Click:Connect(function()
    if not isWalking then return end
    isPaused = not isPaused
    if isPaused then
        humanoid:MoveTo(rootPart.Position)
        statusLabel.Text = "Status: Paused"
        statusLabel.TextColor3 = Color3.fromRGB(220, 170, 50)
    else
        statusLabel.Text = "Status: Walking..."
        statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
    end
end)

stopBtn2.MouseButton1Click:Connect(function()
    stopWalking()
    humanoid:MoveTo(rootPart.Position)
end)

-- Auto reconnect saat respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    if isWalking then
        task.wait(1)
        startWalking()
    end
end)

print("[AutoWalker] Loaded! Siap AFK walk.")
