-- ================================================
--   PATH RECORDER v2.0
--   + Visualisasi path di dunia game
--   + Undo titik terakhir
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- =====================
--       STATE
-- =====================
local isRecording = false
local isPaused = false
local recordedPath = {}
local visualParts = {}
local recordConnection = nil
local RECORD_INTERVAL = 0.15
local SAVE_FILE = "walker_routes.json"

-- Folder buat nyimpen visual parts
local visualFolder = Instance.new("Folder")
visualFolder.Name = "PathVisuals"
visualFolder.Parent = workspace

-- =====================
--    LOAD/SAVE ROUTES
-- =====================
local routes = {}
local function loadRoutes()
    if isfile and isfile(SAVE_FILE) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(SAVE_FILE))
        end)
        if ok and data then routes = data end
    end
end

local function saveRoutes()
    if writefile then
        pcall(function()
            writefile(SAVE_FILE, game:GetService("HttpService"):JSONEncode(routes))
        end)
    else
        warn("Executor tidak support writefile!")
    end
end

loadRoutes()

-- =====================
--   VISUAL FUNCTIONS
-- =====================
local function createDot(position, index)
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.4, 0.4, 0.4)
    part.Position = position + Vector3.new(0, 0.3, 0)
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    if index % 10 == 0 then
        part.Color = Color3.fromRGB(255, 200, 0)
        part.Size = Vector3.new(0.6, 0.6, 0.6)
    else
        part.Color = Color3.fromRGB(80, 200, 255)
    end
    part.Transparency = 0.3
    part.Parent = visualFolder
    return part
end

local function removeLastDots(count)
    for i = 1, count do
        local part = table.remove(visualParts)
        if part then part:Destroy() end
    end
end

local function clearAllVisuals()
    for _, part in pairs(visualParts) do
        if part then part:Destroy() end
    end
    visualParts = {}
end

-- =====================
--        GUI
-- =====================
if player.PlayerGui:FindFirstChild("PathRecorderGUI") then
    player.PlayerGui.PathRecorderGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PathRecorderGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 245, 0, 390)
mainFrame.Position = UDim2.new(0, 20, 0.5, -195)
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
titleLabel.Text = "◉  PATH RECORDER v2"
titleLabel.TextColor3 = Color3.fromRGB(160, 160, 255)
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

-- Points
local pointsLabel = Instance.new("TextLabel", mainFrame)
pointsLabel.Size = UDim2.new(1, -20, 0, 20)
pointsLabel.Position = UDim2.new(0, 10, 0, 78)
pointsLabel.BackgroundTransparency = 1
pointsLabel.Text = "Points: 0"
pointsLabel.TextColor3 = Color3.fromRGB(80, 80, 120)
pointsLabel.TextSize = 11
pointsLabel.Font = Enum.Font.Gotham
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left

local function makeDivider(posY)
    local d = Instance.new("Frame", mainFrame)
    d.Size = UDim2.new(1, -20, 0, 1)
    d.Position = UDim2.new(0, 10, 0, posY)
    d.BackgroundColor3 = Color3.fromRGB(35, 35, 65)
    d.BorderSizePixel = 0
end

makeDivider(106)

-- Visual Toggle
local visFrame = Instance.new("Frame", mainFrame)
visFrame.Size = UDim2.new(1, -20, 0, 28)
visFrame.Position = UDim2.new(0, 10, 0, 114)
visFrame.BackgroundTransparency = 1

local visLabel = Instance.new("TextLabel", visFrame)
visLabel.Size = UDim2.new(0.75, 0, 1, 0)
visLabel.BackgroundTransparency = 1
visLabel.Text = "Tampilkan Path:"
visLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
visLabel.TextSize = 11
visLabel.Font = Enum.Font.Gotham
visLabel.TextXAlignment = Enum.TextXAlignment.Left

local showVisuals = true
local visToggle = Instance.new("TextButton", visFrame)
visToggle.Size = UDim2.new(0, 44, 0, 22)
visToggle.Position = UDim2.new(1, -44, 0.5, -11)
visToggle.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
visToggle.BorderSizePixel = 0
visToggle.Text = "ON"
visToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
visToggle.TextSize = 10
visToggle.Font = Enum.Font.GothamBold
Instance.new("UICorner", visToggle).CornerRadius = UDim.new(0, 6)

visToggle.MouseButton1Click:Connect(function()
    showVisuals = not showVisuals
    if showVisuals then
        visToggle.Text = "ON"
        visToggle.BackgroundColor3 = Color3.fromRGB(50, 170, 90)
        for _, p in pairs(visualParts) do if p then p.Transparency = 0.3 end end
    else
        visToggle.Text = "OFF"
        visToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
        for _, p in pairs(visualParts) do if p then p.Transparency = 1 end end
    end
end)

makeDivider(150)

-- Undo Section
local undoSectionLabel = Instance.new("TextLabel", mainFrame)
undoSectionLabel.Size = UDim2.new(1, -20, 0, 20)
undoSectionLabel.Position = UDim2.new(0, 10, 0, 158)
undoSectionLabel.BackgroundTransparency = 1
undoSectionLabel.Text = "Undo Titik Terakhir:"
undoSectionLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
undoSectionLabel.TextSize = 11
undoSectionLabel.Font = Enum.Font.Gotham
undoSectionLabel.TextXAlignment = Enum.TextXAlignment.Left

local undoInput = Instance.new("TextBox", mainFrame)
undoInput.Size = UDim2.new(0.45, 0, 0, 34)
undoInput.Position = UDim2.new(0, 10, 0, 180)
undoInput.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
undoInput.BorderSizePixel = 0
undoInput.Text = "20"
undoInput.TextColor3 = Color3.fromRGB(200, 200, 255)
undoInput.TextSize = 13
undoInput.Font = Enum.Font.GothamBold
undoInput.PlaceholderText = "Jumlah..."
undoInput.PlaceholderColor3 = Color3.fromRGB(70, 70, 100)
undoInput.ClearTextOnFocus = false
Instance.new("UICorner", undoInput).CornerRadius = UDim.new(0, 8)
local undoInputStroke = Instance.new("UIStroke", undoInput)
undoInputStroke.Color = Color3.fromRGB(60, 60, 100)
undoInputStroke.Thickness = 1
local undoPad = Instance.new("UIPadding", undoInput)
undoPad.PaddingLeft = UDim.new(0, 10)

local undoBtn = Instance.new("TextButton", mainFrame)
undoBtn.Size = UDim2.new(0.48, 0, 0, 34)
undoBtn.Position = UDim2.new(0.52, -10, 0, 180)
undoBtn.BackgroundColor3 = Color3.fromRGB(160, 80, 200)
undoBtn.BorderSizePixel = 0
undoBtn.Text = "↩  Undo"
undoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
undoBtn.TextSize = 12
undoBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", undoBtn).CornerRadius = UDim.new(0, 8)
undoBtn.MouseEnter:Connect(function()
    TweenService:Create(undoBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 100, 220)}):Play()
end)
undoBtn.MouseLeave:Connect(function()
    TweenService:Create(undoBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(160, 80, 200)}):Play()
end)

local clearBtn = Instance.new("TextButton", mainFrame)
clearBtn.Size = UDim2.new(1, -20, 0, 30)
clearBtn.Position = UDim2.new(0, 10, 0, 222)
clearBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "🗑  Hapus Semua Path"
clearBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
clearBtn.TextSize = 11
clearBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 8)
clearBtn.MouseEnter:Connect(function()
    TweenService:Create(clearBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 40, 40)}):Play()
end)
clearBtn.MouseLeave:Connect(function()
    TweenService:Create(clearBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 30, 30)}):Play()
end)

makeDivider(262)

-- Route Name Input
local inputLabel = Instance.new("TextLabel", mainFrame)
inputLabel.Size = UDim2.new(1, -20, 0, 20)
inputLabel.Position = UDim2.new(0, 10, 0, 270)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "Nama Route:"
inputLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
inputLabel.TextSize = 11
inputLabel.Font = Enum.Font.Gotham
inputLabel.TextXAlignment = Enum.TextXAlignment.Left

local inputBox = Instance.new("TextBox", mainFrame)
inputBox.Size = UDim2.new(1, -20, 0, 34)
inputBox.Position = UDim2.new(0, 10, 0, 292)
inputBox.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
inputBox.BorderSizePixel = 0
inputBox.Text = "Gunung A"
inputBox.TextColor3 = Color3.fromRGB(200, 200, 255)
inputBox.TextSize = 12
inputBox.Font = Enum.Font.Gotham
inputBox.PlaceholderText = "Nama route..."
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 100)
inputBox.ClearTextOnFocus = false
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local inputStroke = Instance.new("UIStroke", inputBox)
inputStroke.Color = Color3.fromRGB(60, 60, 100)
inputStroke.Thickness = 1
local inputPad = Instance.new("UIPadding", inputBox)
inputPad.PaddingLeft = UDim.new(0, 10)

makeDivider(334)

-- Bottom 3 buttons
local function createBtnSmall(text, color, pos)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0.31, 0, 0, 36)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.12)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    return btn
end

local recordBtn = createBtnSmall("⏺ Record", Color3.fromRGB(50, 170, 90),  UDim2.new(0, 10,    0, 342))
local stopBtn   = createBtnSmall("⏹ Stop",   Color3.fromRGB(190, 60, 60),  UDim2.new(0.345, 0, 0, 342))
local saveBtn   = createBtnSmall("💾 Save",   Color3.fromRGB(50, 100, 200), UDim2.new(0.69, 0,  0, 342))

-- =====================
--     FUNCTIONS
-- =====================
local function updateStatus(text, color)
    statusLabel.Text = "Status: " .. text
    statusLabel.TextColor3 = color or Color3.fromRGB(100, 100, 140)
end

local function updatePoints()
    pointsLabel.Text = "Points: " .. #recordedPath
end

local function addPoint()
    local pos = rootPart.Position
    table.insert(recordedPath, {pos.X, pos.Y, pos.Z})
    if showVisuals then
        local dot = createDot(pos, #recordedPath)
        table.insert(visualParts, dot)
    else
        table.insert(visualParts, nil)
    end
    updatePoints()
end

local function doRecord()
    isRecording = true
    isPaused = false
    updateStatus("Recording...", Color3.fromRGB(80, 220, 110))
    recordBtn.Text = "⏸ Pause"
    local timer = 0
    recordConnection = RunService.Heartbeat:Connect(function(dt)
        if not isRecording then return end
        timer += dt
        if timer >= RECORD_INTERVAL then
            timer = 0
            addPoint()
        end
    end)
end

-- =====================
--    BUTTON EVENTS
-- =====================
recordBtn.MouseButton1Click:Connect(function()
    if not isRecording and not isPaused then
        doRecord()
    elseif isRecording then
        isRecording = false
        isPaused = true
        if recordConnection then recordConnection:Disconnect() recordConnection = nil end
        updateStatus("Paused (" .. #recordedPath .. " pts)", Color3.fromRGB(220, 170, 50))
        recordBtn.Text = "▶ Resume"
    elseif isPaused then
        doRecord()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    isRecording = false
    isPaused = false
    if recordConnection then recordConnection:Disconnect() recordConnection = nil end
    updateStatus("Stopped — " .. #recordedPath .. " pts", Color3.fromRGB(200, 100, 100))
    recordBtn.Text = "⏺ Record"
end)

saveBtn.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    if name == "" then updateStatus("Nama route kosong!", Color3.fromRGB(220, 80, 80)) return end
    if #recordedPath == 0 then updateStatus("Belum ada path!", Color3.fromRGB(220, 80, 80)) return end
    routes[name] = recordedPath
    saveRoutes()
    updateStatus("Saved: " .. name .. " ✓", Color3.fromRGB(80, 220, 150))
    recordedPath = {}
    clearAllVisuals()
    updatePoints()
    isPaused = false
    recordBtn.Text = "⏺ Record"
end)

undoBtn.MouseButton1Click:Connect(function()
    local count = tonumber(undoInput.Text) or 20
    if count <= 0 then return end
    if #recordedPath == 0 then updateStatus("Tidak ada titik!", Color3.fromRGB(220, 80, 80)) return end
    count = math.min(count, #recordedPath)
    for i = 1, count do table.remove(recordedPath) end
    removeLastDots(count)
    updateStatus("Undo " .. count .. " titik ✓", Color3.fromRGB(180, 100, 255))
    updatePoints()
end)

clearBtn.MouseButton1Click:Connect(function()
    isRecording = false
    isPaused = false
    if recordConnection then recordConnection:Disconnect() recordConnection = nil end
    recordedPath = {}
    clearAllVisuals()
    updatePoints()
    updateStatus("Path dihapus semua", Color3.fromRGB(200, 80, 80))
    recordBtn.Text = "⏺ Record"
end)

game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
    clearAllVisuals()
    visualFolder:Destroy()
end)

print("[PathRecorder v2] Loaded!")divider.BorderSizePixel = 0

local inputLabel = Instance.new("TextLabel", mainFrame)
inputLabel.Size = UDim2.new(1, -20, 0, 20)
inputLabel.Position = UDim2.new(0, 10, 0, 118)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "Nama Route:"
inputLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
inputLabel.TextSize = 11
inputLabel.Font = Enum.Font.Gotham
inputLabel.TextXAlignment = Enum.TextXAlignment.Left

local inputBox = Instance.new("TextBox", mainFrame)
inputBox.Size = UDim2.new(1, -20, 0, 36)
inputBox.Position = UDim2.new(0, 10, 0, 140)
inputBox.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
inputBox.BorderSizePixel = 0
inputBox.Text = "Gunung A"
inputBox.TextColor3 = Color3.fromRGB(200, 200, 255)
inputBox.TextSize = 12
inputBox.Font = Enum.Font.Gotham
inputBox.PlaceholderText = "Nama route..."
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 100)
inputBox.ClearTextOnFocus = false
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local inputStroke = Instance.new("UIStroke", inputBox)
inputStroke.Color = Color3.fromRGB(60, 60, 100)
inputStroke.Thickness = 1
local inputPadding = Instance.new("UIPadding", inputBox)
inputPadding.PaddingLeft = UDim.new(0, 10)

local function createBtn(text, color, posY)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.12)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    return btn
end

local recordBtn = createBtn("⏺  Start Record", Color3.fromRGB(50, 170, 90), 188)
local stopBtn   = createBtn("⏹  Stop Record",  Color3.fromRGB(190, 60, 60),  236)
local saveBtn   = createBtn("💾  Save Route",   Color3.fromRGB(50, 100, 200), 284)

-- Functions
local function updateStatus(text, color)
    statusLabel.Text = "Status: " .. text
    statusLabel.TextColor3 = color or Color3.fromRGB(100, 100, 140)
end

local function updatePoints()
    pointsLabel.Text = "Points: " .. #recordedPath
end

local isPaused = false

local function startRecording()
    recordedPath = {}
    isRecording = true
    isPaused = false
    updateStatus("Recording...", Color3.fromRGB(80, 220, 110))
    recordBtn.Text = "⏸  Pause Record"
    local timer = 0
    recordConnection = RunService.Heartbeat:Connect(function(dt)
        if not isRecording then return end
        timer += dt
        if timer >= RECORD_INTERVAL then
            timer = 0
            local pos = rootPart.Position
            table.insert(recordedPath, {pos.X, pos.Y, pos.Z})
            updatePoints()
        end
    end)
end

local function pauseRecording()
    isRecording = false
    isPaused = true
    if recordConnection then recordConnection:Disconnect() recordConnection = nil end
    updateStatus("Paused (" .. #recordedPath .. " pts)", Color3.fromRGB(220, 170, 50))
    recordBtn.Text = "▶  Resume Record"
end

local function resumeRecording()
    isRecording = true
    isPaused = false
    updateStatus("Recording...", Color3.fromRGB(80, 220, 110))
    recordBtn.Text = "⏸  Pause Record"
    local timer = 0
    recordConnection = RunService.Heartbeat:Connect(function(dt)
        if not isRecording then return end
        timer += dt
        if timer >= RECORD_INTERVAL then
            timer = 0
            local pos = rootPart.Position
            table.insert(recordedPath, {pos.X, pos.Y, pos.Z})
            updatePoints()
        end
    end)
end

-- Button Events
recordBtn.MouseButton1Click:Connect(function()
    if not isRecording and not isPaused then
        startRecording()
    elseif isRecording then
        pauseRecording()
    elseif isPaused then
        resumeRecording()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    isRecording = false
    isPaused = false
    if recordConnection then recordConnection:Disconnect() recordConnection = nil end
    updateStatus("Stopped — " .. #recordedPath .. " pts", Color3.fromRGB(200, 100, 100))
    recordBtn.Text = "⏺  Start Record"
end)

saveBtn.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    if name == "" then updateStatus("Nama route kosong!", Color3.fromRGB(220, 80, 80)) return end
    if #recordedPath == 0 then updateStatus("Belum ada path!", Color3.fromRGB(220, 80, 80)) return end
    routes[name] = recordedPath
    saveRoutes()
    updateStatus("Saved: " .. name .. " ✓", Color3.fromRGB(80, 220, 150))
    recordedPath = {}
    updatePoints()
    recordBtn.Text = "⏺  Start Record"
    isPaused = false
end)

print("[PathRecorder] Loaded!")pointsLabel.TextSize = 11
pointsLabel.Font = Enum.Font.Gotham
pointsLabel.TextXAlignment = Enum.TextXAlignment.Left

local divider = Instance.new("Frame", mainFrame)
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 108)
divider.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
divider.BorderSizePixel = 0

local inputLabel = Instance.new("TextLabel", mainFrame)
inputLabel.Size = UDim2.new(1, -20, 0, 20)
inputLabel.Position = UDim2.new(0, 10, 0, 118)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "Nama Route:"
inputLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
inputLabel.TextSize = 11
inputLabel.Font = Enum.Font.Gotham
inputLabel.TextXAlignment = Enum.TextXAlignment.Left

local inputBox = Instance.new("TextBox", mainFrame)
inputBox.Size = UDim2.new(1, -20, 0, 36)
inputBox.Position = UDim2.new(0, 10, 0, 140)
inputBox.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
inputBox.BorderSizePixel = 0
inputBox.Text = "Gunung A"
inputBox.TextColor3 = Color3.fromRGB(200, 200, 255)
inputBox.TextSize = 12
inputBox.Font = Enum.Font.Gotham
inputBox.PlaceholderText = "Nama route..."
inputBox.PlaceholderColor3 = Color3.fromRGB(70, 70, 100)
inputBox.ClearTextOnFocus = false
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 8)
local inputStroke = Instance.new("UIStroke", inputBox)
inputStroke.Color = Color3.fromRGB(60, 60, 100)
inputStroke.Thickness = 1
local inputPadding = Instance.new("UIPadding", inputBox)
inputPadding.PaddingLeft = UDim.new(0, 10)

local function createBtn(text, color, posY)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.12)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    return btn
end

local recordBtn = createBtn("⏺  Start Record", Color3.fromRGB(50, 170, 90), 188)
local stopBtn   = createBtn("⏹  Stop Record",  Color3.fromRGB(190, 60, 60),  236)
local saveBtn   = createBtn("💾  Save Route",   Color3.fromRGB(50, 100, 200), 284)

-- Functions
local function updateStatus(text, color)
    statusLabel.Text = "Status: " .. text
    statusLabel.TextColor3 = color or Color3.fromRGB(100, 100, 140)
end

local function updatePoints()
    pointsLabel.Text = "Points: " .. #recordedPath
end

local isPaused = false

local function startRecording()
    recordedPath = {}
    isRecording = true
    isPaused = false
    updateStatus("Recording...", Color3.fromRGB(80, 220, 110))
    recordBtn.Text = "⏸  Pause Record"
    local timer = 0
    recordConnection = RunService.Heartbeat:Connect(function(dt)
        if not isRecording then return end
        timer += dt
        if timer >= RECORD_INTERVAL then
            timer = 0
            local pos = rootPart.Position
            table.insert(recordedPath, {pos.X, pos.Y, pos.Z})
            updatePoints()
        end
    end)
end

local function pauseRecording()
    isRecording = false
    isPaused = true
    if recordConnection then recordConnection:Disconnect() recordConnection = nil end
    updateStatus("Paused (" .. #recordedPath .. " pts)", Color3.fromRGB(220, 170, 50))
    recordBtn.Text = "▶  Resume Record"
end

local function resumeRecording()
    isRecording = true
    isPaused = false
    updateStatus("Recording...", Color3.fromRGB(80, 220, 110))
    recordBtn.Text = "⏸  Pause Record"
    local timer = 0
    recordConnection = RunService.Heartbeat:Connect(function(dt)
        if not isRecording then return end
        timer += dt
        if timer >= RECORD_INTERVAL then
            timer = 0
            local pos = rootPart.Position
            table.insert(recordedPath, {pos.X, pos.Y, pos.Z})
            updatePoints()
        end
    end)
end

-- Button Events
recordBtn.MouseButton1Click:Connect(function()
    if not isRecording and not isPaused then
        startRecording()
    elseif isRecording then
        pauseRecording()
    elseif isPaused then
        resumeRecording()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    isRecording = false
    isPaused = false
    if recordConnection then recordConnection:Disconnect() recordConnection = nil end
    updateStatus("Stopped — " .. #recordedPath .. " pts", Color3.fromRGB(200, 100, 100))
    recordBtn.Text = "⏺  Start Record"
end)

saveBtn.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    if name == "" then updateStatus("Nama route kosong!", Color3.fromRGB(220, 80, 80)) return end
    if #recordedPath == 0 then updateStatus("Belum ada path!", Color3.fromRGB(220, 80, 80)) return end
    routes[name] = recordedPath
    saveRoutes()
    updateStatus("Saved: " .. name .. " ✓", Color3.fromRGB(80, 220, 150))
    recordedPath = {}
    updatePoints()
    recordBtn.Text = "⏺  Start Record"
    isPaused = false
end)

print("[PathRecorder] Loaded!")
