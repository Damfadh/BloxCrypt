--[[=================================================================
	BloxCrypt Premium Framework - Core Loop Controller
	Optimized Anti-Lag & Force Close Protected
=================================================================]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local targetGui = RunService:IsStudio() and Players.LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

if targetGui:FindFirstChild("ResHUB_Premium") then targetGui.ResHUB_Premium:Destroy() end

local KUNCI_PREMIUM = "123"
local _G_AccentColor = Color3.fromRGB(99, 102, 241)

local GITHUB_RADAR_URL = "https://raw.githubusercontent.com/Damfadh/BloxCrypt/main/Radar.lua"
local Radar = nil 

-- Setup Base ScreenGui Container
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ResHUB_Premium"
ScreenGui.Parent = targetGui
ScreenGui.ResetOnSpawn = false

-- Fitur Drag Drop Local Frame
local function MakeDraggable(frame, isMinimizeButton, mainFrameRef)
    local dragging, dragStart, startPos, hasMoved = false, nil, nil, false
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true hasMoved = false dragStart = input.Position startPos = frame.Position
            local moveConnection
            moveConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false moveConnection:Disconnect()
                    if isMinimizeButton and not hasMoved and mainFrameRef then mainFrameRef.Visible = not mainFrameRef.Visible end
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then hasMoved = true end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Key Authentication Frame System
local KeyFrame = Instance.new("Frame", ScreenGui)
KeyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
KeyFrame.Position = UDim2.new(0.5, -150, 0.5, -80)
KeyFrame.Size = UDim2.new(0, 300, 0, 160)
MakeDraggable(KeyFrame, false, nil)
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", KeyFrame).Color = Color3.fromRGB(55, 55, 60)

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.BackgroundTransparency = 1; KeyTitle.Size = UDim2.new(1, 0, 0, 40)
KeyTitle.Font = Enum.Font.GothamBold; KeyTitle.Text = "BLOXCRYPT AUTHENTICATION"
KeyTitle.TextColor3 = Color3.new(1, 1, 1); KeyTitle.TextSize = 13

local KeyInput = Instance.new("TextBox", KeyFrame)
KeyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35); KeyInput.Position = UDim2.new(0.5, -110, 0.45, -15); KeyInput.Size = UDim2.new(0, 220, 0, 35)
KeyInput.Font = Enum.Font.Gotham; KeyInput.PlaceholderText = "Masukkan Key (123)"; KeyInput.Text = ""; KeyInput.TextColor3 = Color3.new(1, 1, 1); KeyInput.TextSize = 12
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 6)

local VerifyBtn = Instance.new("TextButton", KeyFrame)
VerifyBtn.BackgroundColor3 = _G_AccentColor; VerifyBtn.Position = UDim2.new(0.5, -110, 0.75, -15); VerifyBtn.Size = UDim2.new(0, 220, 0, 35)
VerifyBtn.Font = Enum.Font.GothamBold; VerifyBtn.Text = "VERIFY KEY"; VerifyBtn.TextColor3 = Color3.new(1, 1, 1); VerifyBtn.TextSize = 12
Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 6)

local function BukaWindowUtama()
    -- 📡 LOAD modul radar dari GitHub secara aman
    local success, result = pcall(function()
        return loadstring(game:HttpGet(GITHUB_RADAR_URL))()
    end)
    
    if success and type(result) == "table" then
        Radar = result
    else
        warn("❌ Gagal Mengambil Radar.lua dari GitHub: " .. tostring(result))
        return
    end

    local Main = Instance.new("Frame", ScreenGui)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 22); Main.Position = UDim2.new(0.5, -250, 0.5, -160); Main.Size = UDim2.new(0, 500, 0, 320)
    MakeDraggable(Main, false, nil)
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", Main).Color = Color3.fromRGB(55, 55, 60)

    local MinimizeIcon = Instance.new("ImageButton", ScreenGui)
    MinimizeIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 22); MinimizeIcon.Position = UDim2.new(0.02, 0, 0.75, 0); MinimizeIcon.Size = UDim2.new(0, 45, 0, 45)
    MinimizeIcon.Image = "rbxassetid://6031094678"
    MakeDraggable(MinimizeIcon, true, Main)
    Instance.new("UICorner", MinimizeIcon).CornerRadius = UDim.new(0, 10)
    local MinStroke = Instance.new("UIStroke", MinimizeIcon)
    MinStroke.Color = _G_AccentColor

    local ResTitle = Instance.new("TextLabel", Main)
    ResTitle.BackgroundTransparency = 1; ResTitle.Position = UDim2.new(0, 15, 0, 12); ResTitle.Size = UDim2.new(0, 200, 0, 20)
    ResTitle.Font = Enum.Font.GothamBold; ResTitle.Text = "BloxCrypt Premium"; ResTitle.TextColor3 = Color3.new(1, 1, 1); ResTitle.TextSize = 18; ResTitle.TextXAlignment = Enum.TextXAlignment.Left

    local Sidebar = Instance.new("Frame", Main)
    Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 28); Sidebar.Position = UDim2.new(0, 10, 0, 45); Sidebar.Size = UDim2.new(0, 140, 1, -55)
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)

    local TabList = Instance.new("ScrollingFrame", Sidebar)
    TabList.Size = UDim2.new(1, -10, 1, -10); TabList.Position = UDim2.new(0, 5, 0, 5); TabList.BackgroundTransparency = 1; TabList.ScrollBarThickness = 0
    Instance.new("UIListLayout", TabList).Padding = UDim.new(0, 4)

    local ContentArea = Instance.new("Frame", Main)
    ContentArea.BackgroundTransparency = 1; ContentArea.Position = UDim2.new(0, 160, 0, 45); ContentArea.Size = UDim2.new(1, -170, 1, -55)

    local Tabs = {}
    local function CreateTab(tabName, isFirst)
        local TabBtn = Instance.new("TextButton", TabList)
        TabBtn.Size = UDim2.new(1, 0, 0, 30); TabBtn.BackgroundColor3 = isFirst and Color3.fromRGB(35, 35, 40) or Color3.fromRGB(20, 20, 22)
        TabBtn.Font = Enum.Font.GothamMedium; TabBtn.Text = " " .. tabName; TabBtn.TextColor3 = isFirst and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150); TabBtn.TextSize = 12; TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 5)
        local TabStroke = Instance.new("UIStroke", TabBtn)
        TabStroke.Color = isFirst and _G_AccentColor or Color3.fromRGB(40, 40, 45)

        local Page = Instance.new("ScrollingFrame", ContentArea)
        Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = isFirst; Page.ScrollBarThickness = 2; Page.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        Instance.new("UIListLayout", Page).Padding = UDim.new(0, 6)

        TabBtn.MouseButton1Down:Connect(function()
            for _, t in pairs(Tabs) do t.Page.Visible = false t.Stroke.Color = Color3.fromRGB(40, 40, 45) t.Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 22) t.Btn.TextColor3 = Color3.fromRGB(150, 150, 150) end
            Page.Visible = true TabStroke.Color = _G_AccentColor TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40) TabBtn.TextColor3 = Color3.new(1,1,1)
        end)

        table.insert(Tabs, {Btn = TabBtn, Page = Page, Stroke = TabStroke})
        local Elements = {}
        
        function Elements.AddButton(text, callback)
            local btn = Instance.new("TextButton", Page)
            btn.Size = UDim2.new(1, -6, 0, 32); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            btn.Font = Enum.Font.GothamMedium; btn.Text = text; btn.TextColor3 = Color3.fromRGB(220, 220, 220); btn.TextSize = 11
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            Instance.new("UIStroke", btn).Color = Color3.fromRGB(45, 45, 50)
            
            if callback then
                btn.MouseButton1Down:Connect(function() pcall(callback, btn) end)
            end
            return btn
        end

        function Elements.AddToggle(text, defaultState, callback)
            local btn = Instance.new("TextButton", Page)
            btn.Size = UDim2.new(1, -6, 0, 32); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            Instance.new("UIStroke", btn).Color = Color3.fromRGB(45, 45, 50)

            local state = defaultState
            local function updateStyle()
                if state then btn.BackgroundColor3 = Color3.fromRGB(16, 185, 129) btn.Text = text .. " [ON]"
                else btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) btn.Text = text .. " [OFF]" end
            end
            btn.MouseButton1Down:Connect(function()
                state = not state updateStyle() pcall(callback, state)
            end)
            updateStyle()
            return btn
        end

        function Elements.AddLabel(text)
            local label = Instance.new("TextLabel", Page)
            label.Size = UDim2.new(1, -6, 0, 25); label.BackgroundTransparency = 1; label.Font = Enum.Font.GothamMedium; label.Text = text; label.TextColor3 = Color3.fromRGB(150, 160, 180); label.TextSize = 10; label.TextXAlignment = Enum.TextXAlignment.Left
            return label
        end

        return Elements
    end

    local RadarTab = CreateTab("Radar Humanoid", true)
    local SettingsTab = CreateTab("Settings HUB", false)

    local RadarStatus = RadarTab.AddLabel("📡 Status Radar: Scanning Inactive")
    RadarStatus.TextColor3 = Color3.fromRGB(245, 158, 11)

    RadarTab.AddToggle("Radar Detector Master", false, function(val)
        Radar.isDetectionEnabled = val
        if not val then 
            Radar.ClearAllOutlines() 
            Radar.StopTween() 
            Radar.ApplyFreezeStatus(false) 
            RadarStatus.Text = "📡 Status Radar: Scanning Inactive"
        end
    end)

    RadarTab.AddToggle("Tween & Lock Player Position", false, function(val)
        Radar.isTweenEnabled = val
        if not val then Radar.StopTween() end
        Radar.ApplyFreezeStatus(val)
    end)

    RadarTab.AddToggle("Bring Teleport Enemies to Me", false, function(val)
        Radar.isBringEnemiesEnabled = val
    end)

    RadarTab.AddToggle("Force Face Target (Lock 3D)", false, function(val)
        Radar.isForceFaceEnabled = val
    end)

    local scanModesList = {"Humanoid", "Universal"}
    local currentIdx = 1
    RadarTab.AddButton("🔍 Scan Mode: Humanoid (Default)", function(buttonInstance)
        currentIdx = currentIdx + 1
        if currentIdx > #scanModesList then currentIdx = 1 end
        local chosenMode = scanModesList[currentIdx]
        buttonInstance.Text = "🔍 Scan Mode: " .. chosenMode
        Radar.SetScanMode(chosenMode)
    end)

    local tSpeed = 60
    RadarTab.AddButton("⚡ Tween Speed: 60 studs/s (Klik +15)", function(buttonInstance)
        tSpeed = tSpeed + 15
        if tSpeed > 150 then tSpeed = 30 end
        buttonInstance.Text = "⚡ Tween Speed: " .. tSpeed .. " studs/s"
        Radar.SetSpeed(tSpeed)
    end)

    -- 🛡️ CONTROL LOOP MASTER (Dipusatkan di Main untuk Mencegah Force Close)
    RunService.RenderStepped:Connect(function()
        if Radar and Radar.isDetectionEnabled then
            pcall(Radar.UpdateForceFace)
        end
    end)

    task.spawn(function()
        while task.wait(0.1) do
            if not ScreenGui or not ScreenGui.Parent then break end
            if Radar and Radar.isDetectionEnabled then
                -- Jalankan fungsi pencarian engine radar secara aman
                pcall(Radar.ScanAndExecute)
                
                -- Update Status Teks Target UI
                local currentTarget = Radar.GetActiveTargetName()
                if currentTarget and currentTarget ~= "None" then
                    RadarStatus.Text = "🎯 Target: " .. currentTarget
                else
                    RadarStatus.Text = "🔍 Searching Targets..."
                end
            end
        end
    end)
end

-- Security Handle Login
VerifyBtn.MouseButton1Down:Connect(function()
    if string.gsub(KeyInput.Text, "%s+", "") == KUNCI_PREMIUM then
        VerifyBtn.Text = "ACCESS GRANTED"; VerifyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
        task.wait(0.4) KeyFrame:Destroy() BukaWindowUtama()
    else
        VerifyBtn.Text = "WRONG KEY!"; VerifyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 55)
        task.wait(1) VerifyBtn.Text = "VERIFY KEY"; VerifyBtn.BackgroundColor3 = _G_AccentColor
    end
end)