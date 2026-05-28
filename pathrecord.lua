-- ================================================
--   PATH RECORDER v1.0
--   Rekam route & simpan ke file lokal
--   By: kamu sendiri :)
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- State
local isRecording = false
local recordedPath = {}
local recordConnection = nil
local RECORD_INTERVAL = 0.15
local SAVE_FILE = "walker_routes.json"

-- Load Routes
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

-- GUI
if player.PlayerGui:FindFirstChild("PathRecorderGUI") then
    player.PlayerGui.PathRecorderGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PathRecorderGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 340)
mainFrame.Position = UDim2.new(0, 20, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(60, 60, 100)
stroke.Thickness = 1.2

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
titleLabel.Text = "◉  PATH RECORDER"
titleLabel.TextColor3 = Color3.fromRGB(160, 160, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, -20, 0, 24)
statusLabel.Position = UDim2.new(0, 10, 0, 58)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local pointsLabel = Instance.new("TextLabel", mainFrame)
pointsLabel.Size = UDim2.new(1, -20, 0, 20)
pointsLabel.Position = UDim2.new(0, 10, 0, 80)
pointsLabel.BackgroundTransparency = 1
pointsLabel.Text = "Points: 0"
pointsLabel.TextColor3 = Color3.fromRGB(80, 80, 120)
pointsLabel.TextSize = 11
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
