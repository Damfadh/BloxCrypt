local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local targetGui = RunService:IsStudio() and Player:WaitForChild("PlayerGui") or game:GetService("CoreGui")

-- Bersihkan sisa UI lama agar tidak menumpuk
if targetGui:FindFirstChild("ResHUB_Premium") then targetGui.ResHUB_Premium:Destroy() end

-- Konfigurasi Awal
local KUNCI_PREMIUM = "123"
local _G_AccentColor = Color3.fromRGB(0, 120, 255)

-- =================================================================
-- 1. MASTER CONTAINER GUI
-- =================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ResHUB_Premium"
ScreenGui.Parent = targetGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- FITUR DRAG LOKAL (Anti-Ghosting & Tidak Membaca Layar Luar)
local function MakeDraggable(frame, isMinimizeButton, mainFrameRef)
    local dragging = false
    local dragStart, startPos
    local hasMoved = false

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = frame.Position

            -- Dengarkan pergerakan secara lokal hanya saat mouse menempel pada frame ini
            local moveConnection
            moveConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    moveConnection:Disconnect() -- Putus koneksi segera setelah dilepas
                    
                    -- Logika Minimize: Hanya terpicu jika ini tombol minimize DAN mouse tidak digeser jauh
                    if isMinimizeButton and not hasMoved and mainFrameRef then
                        mainFrameRef.Visible = not mainFrameRef.Visible
                    end
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 5 then
                    hasMoved = true
                end
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

-- =================================================================
-- 2. SETUP INTERFACE LOGIN (KEY SYSTEM)
-- =================================================================
local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.Parent = ScreenGui
KeyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
KeyFrame.Position = UDim2.new(0.5, -150, 0.5, -80)
KeyFrame.Size = UDim2.new(0, 300, 0, 160)
KeyFrame.Active = true
MakeDraggable(KeyFrame, false, nil)

Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 8)
local KeyMainStroke = Instance.new("UIStroke", KeyFrame)
KeyMainStroke.Color = Color3.fromRGB(55, 55, 60)
KeyMainStroke.Thickness = 1.5

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Size = UDim2.new(1, 0, 0, 40)
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.Text = "ResHUB AUTHENTICATION"
KeyTitle.TextColor3 = Color3.new(1, 1, 1)
KeyTitle.TextSize = 13

local KeyInput = Instance.new("TextBox", KeyFrame)
KeyInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
KeyInput.Position = UDim2.new(0.5, -110, 0.45, -15)
KeyInput.Size = UDim2.new(0, 220, 0, 35)
KeyInput.Font = Enum.Font.Gotham
KeyInput.PlaceholderText = "Masukkan Key (123)"
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.new(1, 1, 1)
KeyInput.TextSize = 12
KeyInput.ClearTextOnFocus = false
Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", KeyInput).Color = Color3.fromRGB(50, 50, 55)

local VerifyBtn = Instance.new("TextButton", KeyFrame)
VerifyBtn.Name = "VerifyButton"
VerifyBtn.BackgroundColor3 = _G_AccentColor
VerifyBtn.Position = UDim2.new(0.5, -110, 0.75, -15)
VerifyBtn.Size = UDim2.new(0, 220, 0, 35)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.Text = "VERIFY KEY"
VerifyBtn.TextColor3 = Color3.new(1, 1, 1)
VerifyBtn.TextSize = 12
Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 6)

-- =================================================================
-- 3. INTERFACE UTAMA RESHUB (WINDOW SETELAH LOGIN)
-- =================================================================
local function BukaWindowUtama()
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "Main"
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    Main.Position = UDim2.new(0.5, -250, 0.5, -150)
    Main.Size = UDim2.new(0, 500, 0, 300)
    Main.BackgroundTransparency = 0.05
    Main.Active = true
    MakeDraggable(Main, false, nil)

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    local MainFrameStroke = Instance.new("UIStroke", Main)
    MainFrameStroke.Color = Color3.fromRGB(55, 55, 60)
    MainFrameStroke.Thickness = 1.5

    local MinimizeIcon = Instance.new("ImageButton", ScreenGui)
    MinimizeIcon.Name = "MinimizeIcon"
    MinimizeIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    MinimizeIcon.Position = UDim2.new(0.02, 0, 0.75, 0)
    MinimizeIcon.Size = UDim2.new(0, 45, 0, 45)
    MinimizeIcon.Active = true
    MinimizeIcon.Image = "rbxassetid://6031094678" -- Menggunakan Icon Gear bawaan Roblox sementara
    MakeDraggable(MinimizeIcon, true, Main) 
    Instance.new("UICorner", MinimizeIcon).CornerRadius = UDim.new(0, 10)
    
    local MinStroke = Instance.new("UIStroke", MinimizeIcon)
    MinStroke.Color = _G_AccentColor
    MinStroke.Thickness = 1.5

    local ResTitle = Instance.new("TextLabel", Main)
    ResTitle.BackgroundTransparency = 1
    ResTitle.Position = UDim2.new(0, 15, 0, 12)
    ResTitle.Size = UDim2.new(0, 100, 0, 20)
    ResTitle.Font = Enum.Font.GothamBold
    ResTitle.Text = "ResHUB"
    ResTitle.TextColor3 = Color3.new(1, 1, 1)
    ResTitle.TextSize = 18
    ResTitle.TextXAlignment = Enum.TextXAlignment.Left

    local Sidebar = Instance.new("Frame", Main)
    Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    Sidebar.Position = UDim2.new(0, 10, 0, 45)
    Sidebar.Size = UDim2.new(0, 140, 1, -55)
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)

    local TabList = Instance.new("ScrollingFrame", Sidebar)
    TabList.Size = UDim2.new(1, -10, 1, -10)
    TabList.Position = UDim2.new(0, 5, 0, 5)
    TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 0
    Instance.new("UIListLayout", TabList).Padding = UDim.new(0, 4)

    local ContentArea = Instance.new("Frame", Main)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Position = UDim2.new(0, 160, 0, 45)
    ContentArea.Size = UDim2.new(1, -170, 1, -55)

    local function DynamicThemeUpdate(newColor)
        _G_AccentColor = newColor
        MinStroke.Color = newColor
        for _, item in pairs(ScreenGui:GetDescendants()) do
            if item.Name == "TabStroke" or item.Name == "ElementStroke" then
                item.Color = newColor
            end
        end
    end

    local Tabs = {}
    local function CreateTab(tabName, isFirst)
        local TabBtn = Instance.new("TextButton", TabList)
        TabBtn.Size = UDim2.new(1, 0, 0, 30)
        TabBtn.BackgroundColor3 = isFirst and Color3.fromRGB(35, 35, 40) or Color3.fromRGB(20, 20, 22)
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.Text = " " .. tabName
        TabBtn.TextColor3 = isFirst and Color3.new(1,1,1) or Color3.fromRGB(150, 150, 150)
        TabBtn.TextSize = 12
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 5)
        
        local TabStroke = Instance.new("UIStroke", TabBtn)
        TabStroke.Name = "TabStroke"
        TabStroke.Color = isFirst and _G_AccentColor or Color3.fromRGB(40, 40, 45)

        local Page = Instance.new("ScrollingFrame", ContentArea)
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.Visible = isFirst
        Page.ScrollBarThickness = 2
        Page.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        Instance.new("UIListLayout", Page).Padding = UDim.new(0, 6)

        TabBtn.MouseButton1Down:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false
                t.Stroke.Color = Color3.fromRGB(40, 40, 45)
                t.Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
                t.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
            Page.Visible = true
            TabStroke.Color = _G_AccentColor
            TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            TabBtn.TextColor3 = Color3.new(1,1,1)
        end)

        table.insert(Tabs, {Btn = TabBtn, Page = Page, Stroke = TabStroke})
        local Elements = {}
        
        function Elements.AddButton(text, callback)
            local btn = Instance.new("TextButton", Page)
            btn.Size = UDim2.new(1, -6, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            btn.Font = Enum.Font.GothamMedium
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.TextSize = 12
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            
            local elStroke = Instance.new("UIStroke", btn)
            elStroke.Name = "ElementStroke"
            elStroke.Color = Color3.fromRGB(45, 45, 50)
            
            btn.MouseButton1Down:Connect(function()
                task.spawn(callback)
            end)
        end

        function Elements.AddTextBox(placeholder, callback)
            local box = Instance.new("TextBox", Page)
            box.Size = UDim2.new(1, -6, 0, 35)
            box.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            box.Font = Enum.Font.Gotham
            box.PlaceholderText = placeholder
            box.Text = ""
            box.TextColor3 = Color3.new(1,1,1)
            box.TextSize = 12
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
            Instance.new("UIStroke", box).Color = Color3.fromRGB(45, 45, 50)
            
            box.FocusLost:Connect(function(enterPressed)
                if enterPressed then callback(box.Text) end
            end)
        end

        return Elements
    end

    -- Tambahkan Tab Fitur & Kustomisasi UI
    local FeaturesTab = CreateTab("Features", true)
    local SettingsTab = CreateTab("Settings", false)

    FeaturesTab.AddButton("Speed Hack (50)", function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.WalkSpeed = 50
        end
    end)
    FeaturesTab.AddButton("Normal Speed (16)", function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid.WalkSpeed = 16
        end
    end)

    SettingsTab.AddButton("Theme Accent: Electric Blue", function() DynamicThemeUpdate(Color3.fromRGB(0, 120, 255)) end)
    SettingsTab.AddButton("Theme Accent: Crimson Red", function() DynamicThemeUpdate(Color3.fromRGB(255, 50, 50)) end)
    SettingsTab.AddButton("Theme Accent: Mint Green", function() DynamicThemeUpdate(Color3.fromRGB(0, 255, 130)) end)
    SettingsTab.AddButton("Theme Accent: Cyber Purple", function() DynamicThemeUpdate(Color3.fromRGB(150, 50, 255)) end)

    SettingsTab.AddTextBox("Ubah Transparansi UI (0.0 - 0.9) + Enter", function(text)
        local val = tonumber(text)
        if val and val >= 0 and val <= 0.9 then Main.BackgroundTransparency = val end
    end)
end

-- =================================================================
-- 4. PROSES VERIFIKASI SEKURITI LOGIN
-- =================================================================
VerifyBtn.MouseButton1Down:Connect(function()
    local cleanedInput = string.gsub(KeyInput.Text, "%s+", "")
    
    if cleanedInput == KUNCI_PREMIUM then
        VerifyBtn.Text = "ACCESS GRANTED"
        VerifyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
        task.wait(0.4)
        
        KeyFrame:Destroy()
        BukaWindowUtama()
    else
        VerifyBtn.Text = "WRONG KEY!"
        VerifyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(1)
        VerifyBtn.Text = "VERIFY KEY"
        VerifyBtn.BackgroundColor3 = _G_AccentColor
    end
end)

print("ResHUB Premium Framework perfectly optimized!")