--[[============================================================
	ULTIMATE HUMANOID RADAR v14.8 - 3D ORIENTATION LOCK
	Clean & Organized Edition (Merged Tween & Freeze System + Minimize Restored)
============================================================]]

-- ============================================================
-- ⚙️ CONFIGURATION & DEFAULTS
-- ============================================================
local DEFAULT_RADIUS = 200  
local MIN_RADIUS = 10
local MAX_RADIUS = 500      
local SCAN_INTERVAL = 0.1   
local VOID_THRESHOLD = -50  

-- ============================================================
-- 🔧 SERVICES & INITIALIZATION
-- ============================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)

local MyCharacter = LocalPlayer.Character
if not MyCharacter or not MyCharacter.Parent then MyCharacter = LocalPlayer.CharacterAdded:Wait() end

-- ============================================================
-- 📊 STATE VARIABLES
-- ============================================================
local isDetectionEnabled = true
local isTweenEnabled = false       
local isForceFaceEnabled = false   
local isBringEnemiesEnabled = false 

local currentRadius = DEFAULT_RADIUS
local isGlobalScan = false 
local tweenStopDistance = 10 
local tweenSpeed = 60 
local priorityMode = "Jarak" 
local tweenPositionMode = "Up" 
local typeScanMode = "Humanoid" -- REVISI: Dijadikan Default sesuai request

local savedSpawnCFrame = nil
local customEnemyNames = {"zombie", "samurai", "titan", "bomber", "phantom", "spirit", "sukuna", "king of curses"} 

local currentDetectedModels = {}
local activeTargetModel = nil
local activeTween = nil
local lastTweenTarget = nil
local isTweeningNow = false 

local activeSlider = nil
local CachedModels = {}
local distanceHistory = {} 

-- Forward Declarations
local clearAllOutlines, stopTween, applyFreezeStatus

-- ============================================================
-- 💾 CACHE & PERFORMANCE SYSTEM
-- ============================================================
local function checkAndCacheModel(obj)
	if obj:IsA("Model") and obj ~= MyCharacter and not obj:IsDescendantOf(MyCharacter) then
		CachedModels[obj] = obj.Name:lower()
	end
end

task.spawn(function()
	local objects = Workspace:GetDescendants()
	for i = 1, #objects do
		local o = objects[i]
		if o then checkAndCacheModel(o) end
		if i % 100 == 0 then task.wait() end
	end
end)

Workspace.DescendantAdded:Connect(checkAndCacheModel)

Workspace.DescendantRemoving:Connect(function(obj)
	CachedModels[obj] = nil
	distanceHistory[obj] = nil 
	if currentDetectedModels[obj] then
		pcall(function() if currentDetectedModels[obj].Instance then currentDetectedModels[obj].Instance:Destroy() end end)
		currentDetectedModels[obj] = nil
	end
end)

-- ============================================================
-- 🎨 UI CREATION & SETUP (MINIMIZE RESTORED)
-- ============================================================
local oldGui = PlayerGui:FindFirstChild("UltimateHumanoidRadarV14")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimateHumanoidRadarV14"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 580) 
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(99, 102, 241)
MainStroke.Thickness = 1.5

-- Tombol Kecil Pengganti Saat di-Minimize
local SmallMinWidget = Instance.new("TextButton")
SmallMinWidget.Size = UDim2.new(0, 90, 0, 30)
SmallMinWidget.Position = UDim2.new(0.05, 0, 0.1, 0)
SmallMinWidget.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
SmallMinWidget.Text = "📡 RADAR"
SmallMinWidget.TextColor3 = Color3.fromRGB(255, 255, 255)
SmallMinWidget.Font = Enum.Font.GothamBold
SmallMinWidget.TextSize = 11
SmallMinWidget.Visible = false
SmallMinWidget.Active = true
SmallMinWidget.Draggable = true
SmallMinWidget.Parent = ScreenGui
Instance.new("UICorner", SmallMinWidget).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", SmallMinWidget).Color = Color3.fromRGB(255, 255, 255)

-- Tombol Minimize Di Atas Main Frame
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -35, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 55)
MinBtn.Text = "➖"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 10
MinBtn.Parent = MainFrame
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

MinBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	SmallMinWidget.Visible = true
	SmallMinWidget.Position = MainFrame.Position
end)

SmallMinWidget.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	SmallMinWidget.Visible = false
	MainFrame.Position = SmallMinWidget.Position
end)

local function createLabel(text, yPos, sizeY)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -30, 0, sizeY or 20)
	label.Position = UDim2.new(0, 15, 0, yPos)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(160, 170, 190)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 10
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = MainFrame
	return label
end

local function createToggleButton(text, yPos, defaultState, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -30, 0, 24)
	btn.Position = UDim2.new(0, 15, 0, yPos)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.Parent = MainFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	
	local state = defaultState
	local function updateStyle()
		if state then
			btn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
			btn.Text = text .. ": ON"
		else
			btn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
			btn.Text = text .. ": OFF"
		end
	end
	btn.MouseButton1Click:Connect(function()
		state = not state
		updateStyle()
		callback(state)
	end)
	updateStyle()
	return btn
end

-- ============================================================
-- 🎯 MAIN UI ELEMENTS
-- ============================================================
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 35)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "📡 ULTIMATE RADAR v14.8"
TitleLabel.TextColor3 = Color3.fromRGB(225, 228, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

createToggleButton("RADAR DETECTOR", 35, true, function(val)
	isDetectionEnabled = val
	if not val then clearAllOutlines() activeTargetModel = nil stopTween() applyFreezeStatus(false) end
end)

createToggleButton("TWEEN & FREEZE PLAYER", 62, false, function(val)
	isTweenEnabled = val
	if not val then stopTween() end
	applyFreezeStatus(val)
end)

createToggleButton("BRING ENEMIES (TELEPORT MOB TO YOU)", 89, false, function(val)
	isBringEnemiesEnabled = val
end)

createToggleButton("FORCE FACE TARGET (3D MATRIKS)", 116, false, function(val)
	isForceFaceEnabled = val
end)

-- ============================================================
-- 📋 SCAN TYPE SELECTOR (HUMANOID DEFAULT)
-- ============================================================
createLabel("🔍 TYPE SCAN PREFERENCE:", 145)
local TypeScanBtn = Instance.new("TextButton")
TypeScanBtn.Size = UDim2.new(1, -30, 0, 24)
TypeScanBtn.Position = UDim2.new(0, 15, 0, 163)
TypeScanBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241) 
TypeScanBtn.Text = "⚙️ Type: Humanoid (Roblox)" -- Teks Default awal
TypeScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TypeScanBtn.Font = Enum.Font.GothamBold
TypeScanBtn.TextSize = 10
TypeScanBtn.Parent = MainFrame
Instance.new("UICorner", TypeScanBtn).CornerRadius = UDim.new(0, 6)

local scanModes = {"Humanoid", "Folder/Name", "Health Class", "Universal", "Script Detect", "Chase Detect"}
local scanDisplayNames = {
	["Humanoid"]      = "⚙️ Type: Humanoid (Roblox)",
	["Folder/Name"]   = "📁 Type: Folder / Name Custom",
	["Health Class"]  = "❤️ Type: Scan HP/Nyawa Object",
	["Universal"]     = "🌐 Type: Universal (All Models)",
	["Script Detect"] = "🤖 Type: Script AI Detect",
	["Chase Detect"]  = "🎯 Type: Chase Detect (Auto)"
}
local currentScanIdx = 1 -- Mengarah ke "Humanoid"

TypeScanBtn.MouseButton1Click:Connect(function()
	currentScanIdx = currentScanIdx + 1
	if currentScanIdx > #scanModes then currentScanIdx = 1 end
	typeScanMode = scanModes[currentScanIdx]
	TypeScanBtn.Text = scanDisplayNames[typeScanMode] or ("📋 " .. typeScanMode)
	clearAllOutlines()
	stopTween()
end)

-- ============================================================
-- 🏷️ TARGET FILTER
-- ============================================================
createLabel("📝 TARGET FILTER (Pisah dengan koma):", 190)
local NameFilterBox = Instance.new("TextBox")
NameFilterBox.Size = UDim2.new(1, -30, 0, 26)
NameFilterBox.Position = UDim2.new(0, 15, 0, 208)
NameFilterBox.BackgroundColor3 = Color3.fromRGB(30, 34, 55)
NameFilterBox.Text = "Zombie, Samurai, Titan, Bomber, Phantom, Spirit, Sukuna, King Of Curses" 
NameFilterBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameFilterBox.PlaceholderText = "Nama Target..."
NameFilterBox.Font = Enum.Font.GothamMedium
NameFilterBox.TextSize = 10
NameFilterBox.Parent = MainFrame
Instance.new("UICorner", NameFilterBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", NameFilterBox).Color = Color3.fromRGB(60, 65, 95)

local function updateCustomNamesList()
	local text = NameFilterBox.Text
	table.clear(customEnemyNames)
	for segment in string.gmatch(text, "([^,]+)") do
		local cleanName = string.gsub(segment, "^%s*(.-)%s*$", "%1"):lower()
		if cleanName ~= "" then table.insert(customEnemyNames, cleanName) end
	end
end
NameFilterBox.FocusLost:Connect(function() updateCustomNamesList() clearAllOutlines() stopTween() end)
updateCustomNamesList()

-- ============================================================
-- ⭐ PRIORITY MODE SELECTOR
-- ============================================================
createLabel("🎯 SKALA PRIORITAS TARGET:", 238)
local PriorityBtn = Instance.new("TextButton")
PriorityBtn.Size = UDim2.new(1, -30, 0, 24)
PriorityBtn.Position = UDim2.new(0, 15, 0, 256)
PriorityBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 55)
PriorityBtn.Text = "⭐ Prioritas: Jarak Terdekat"
PriorityBtn.TextColor3 = Color3.fromRGB(210, 218, 235)
PriorityBtn.Font = Enum.Font.GothamBold
PriorityBtn.TextSize = 10
PriorityBtn.Parent = MainFrame
Instance.new("UICorner", PriorityBtn).CornerRadius = UDim.new(0, 6)

local modes = {"Jarak", "HP Terendah", "Nama"}
PriorityBtn.MouseButton1Click:Connect(function()
	local currentModeIdx = (priorityMode == "Jarak" and 2) or (priorityMode == "HP Terendah" and 3) or 1
	priorityMode = modes[currentModeIdx]
	PriorityBtn.Text = "⭐ Prioritas: " .. (priorityMode == "Jarak" and "Jarak Terdekat" or priorityMode == "HP Terendah" and "HP Terendah" or "Nama (A-Z)")
end)

-- ============================================================
-- 🔄 POSITION MODE SELECTOR
-- ============================================================
createLabel("🔄 ARAH POSISI TWEEN:", 284)
local PositionBtn = Instance.new("TextButton")
PositionBtn.Size = UDim2.new(1, -30, 0, 24)
PositionBtn.Position = UDim2.new(0, 15, 0, 302)
PositionBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 55)
PositionBtn.Text = "⚡ Posisi Akhir: Up (Atas / Top)" 
PositionBtn.TextColor3 = Color3.fromRGB(210, 218, 235)
PositionBtn.Font = Enum.Font.GothamBold
PositionBtn.TextSize = 10
PositionBtn.Parent = MainFrame
Instance.new("UICorner", PositionBtn).CornerRadius = UDim.new(0, 6)

local posModes = {"Up", "Front", "Behind", "Down"}
PositionBtn.MouseButton1Click:Connect(function()
	local nextIdx = (tweenPositionMode == "Up" and 2) or (tweenPositionMode == "Front" and 3) or (tweenPositionMode == "Behind" and 4) or 1
	tweenPositionMode = posModes[nextIdx]
	PositionBtn.Text = "⚡ Posisi Akhir: " .. tweenPositionMode
	stopTween() 
end)

-- ============================================================
-- 🎚️ TRIPLE SLIDERS SYSTEM
-- ============================================================
local SliderLabel1 = createLabel("🔍 Radius Jarak Scan: " .. tostring(currentRadius) .. " studs", 330)
local SliderTrack1 = Instance.new("Frame")
SliderTrack1.Size = UDim2.new(1, -30, 0, 5)
SliderTrack1.Position = UDim2.new(0, 15, 0, 351)
SliderTrack1.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
SliderTrack1.Parent = MainFrame
local SliderFill1 = Instance.new("Frame")
SliderFill1.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
SliderFill1.Parent = SliderTrack1
local SliderKnob1 = Instance.new("TextButton")
SliderKnob1.Size = UDim2.new(0, 12, 0, 12)
SliderKnob1.AnchorPoint = Vector2.new(0.5, 0.5)
SliderKnob1.Parent = SliderTrack1

local SliderLabel2 = createLabel("📏 Jeda Jarak Berhenti: " .. tostring(tweenStopDistance) .. " studs", 362)
local SliderTrack2 = Instance.new("Frame")
SliderTrack2.Size = UDim2.new(1, -30, 0, 5)
SliderTrack2.Position = UDim2.new(0, 15, 0, 383)
SliderTrack2.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
SliderTrack2.Parent = MainFrame
local SliderFill2 = Instance.new("Frame")
SliderFill2.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
SliderFill2.Parent = SliderTrack2
local SliderKnob2 = Instance.new("TextButton")
SliderKnob2.Size = UDim2.new(0, 12, 0, 12)
SliderKnob2.AnchorPoint = Vector2.new(0.5, 0.5)
SliderKnob2.Parent = SliderTrack2

local SliderLabel3 = createLabel("⚡ Custom Tween Speed: " .. tostring(tweenSpeed) .. " studs/s", 394)
local SliderTrack3 = Instance.new("Frame")
SliderTrack3.Size = UDim2.new(1, -30, 0, 5)
SliderTrack3.Position = UDim2.new(0, 15, 0, 415)
SliderTrack3.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
SliderTrack3.Parent = MainFrame
local SliderFill3 = Instance.new("Frame")
SliderFill3.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
SliderFill3.Parent = SliderTrack3
local SliderKnob3 = Instance.new("TextButton")
SliderKnob3.Size = UDim2.new(0, 12, 0, 12)
SliderKnob3.AnchorPoint = Vector2.new(0.5, 0.5)
SliderKnob3.Parent = SliderTrack3

for _, track in pairs({SliderTrack1, SliderTrack2, SliderTrack3}) do Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0) end
for _, fill in pairs({SliderFill1, SliderFill2, SliderFill3}) do Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0) end
for _, knob in pairs({SliderKnob1, SliderKnob2, SliderKnob3}) do Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0) end

local TargetStatusLabel = createLabel("🎯 Target Saat Ini: None", 430, 45)
TargetStatusLabel.TextWrapped = true
TargetStatusLabel.TextColor3 = Color3.fromRGB(120, 135, 160)

local function updateSlider1(val)
	local pct = math.clamp((val - MIN_RADIUS) / (MAX_RADIUS - MIN_RADIUS), 0, 1)
	SliderKnob1.Position = UDim2.new(pct, 0, 0.5, 0)
	SliderFill1.Size = UDim2.new(pct, 0, 1, 0)
	isGlobalScan = (val >= MAX_RADIUS)
	SliderLabel1.Text = isGlobalScan and "🔍 Radius Jarak Scan: ♾️ Seluruh Map (Global)" or "🔍 Radius Jarak Scan: " .. math.round(val) .. " studs"
end

local function updateSlider2(val)
	local pct = math.clamp(val / 30, 0, 1)
	SliderKnob2.Position = UDim2.new(pct, 0, 0.5, 0)
	SliderFill2.Size = UDim2.new(pct, 0, 1, 0)
	SliderLabel2.Text = "📏 Jeda Jarak Berhenti: " .. math.round(val) .. " studs"
end

local function updateSlider3(val)
	local pct = math.clamp((val - 15) / (150 - 15), 0, 1)
	SliderKnob3.Position = UDim2.new(pct, 0, 0.5, 0)
	SliderFill3.Size = UDim2.new(pct, 0, 1, 0)
	SliderLabel3.Text = "⚡ Custom Tween Speed: " .. math.round(val) .. " studs/s"
end

SliderKnob1.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then activeSlider = "Radius" end end)
SliderKnob2.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then activeSlider = "StopDist" end end)
SliderKnob3.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then activeSlider = "Speed" end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then activeSlider = nil end end)

UIS.InputChanged:Connect(function(input)
	if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		if activeSlider == "Radius" then
			local pct = math.clamp((UIS:GetMouseLocation().X - SliderTrack1.AbsolutePosition.X) / SliderTrack1.AbsoluteSize.X, 0, 1)
			currentRadius = math.round(MIN_RADIUS + (pct * (MAX_RADIUS - MIN_RADIUS)))
			updateSlider1(currentRadius)
		elseif activeSlider == "StopDist" then
			local pct = math.clamp((UIS:GetMouseLocation().X - SliderTrack2.AbsolutePosition.X) / SliderTrack2.AbsoluteSize.X, 0, 1)
			tweenStopDistance = math.round(pct * 30)
			updateSlider2(tweenStopDistance)
		elseif activeSlider == "Speed" then
			local pct = math.clamp((UIS:GetMouseLocation().X - SliderTrack3.AbsolutePosition.X) / SliderTrack3.AbsoluteSize.X, 0, 1)
			tweenSpeed = math.round(15 + (pct * (150 - 15)))
			updateSlider3(tweenSpeed)
			if isTweeningNow then stopTween() end 
		end
	end
end)

updateSlider1(currentRadius)
updateSlider2(tweenStopDistance)
updateSlider3(tweenSpeed)

-- ============================================================
-- 🛠️ UTILITY & CORE FUNCTIONS
-- ============================================================
function clearAllOutlines()
	for model, highlight in pairs(currentDetectedModels) do
		if highlight then pcall(function() highlight:Destroy() end) end
		currentDetectedModels[model] = nil
	end
end

function stopTween()
	if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
	lastTweenTarget = nil
	isTweeningNow = false
	applyFreezeStatus(isTweenEnabled)
end

function applyFreezeStatus(state)
	if MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart") then
		local hrp = MyCharacter.HumanoidRootPart
		local humanoid = MyCharacter:FindFirstChildOfClass("Humanoid")
		
		hrp.Anchored = (state and not isTweeningNow)
		
		if humanoid then
			if state then
				humanoid.PlatformStand = true
				pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) hrp.AssemblyAngularVelocity = Vector3.new(0,0,0) end)
			else
				humanoid.PlatformStand = false
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end
	end
end

local function applyOutline(model, isTarget)
	if not model or not model.Parent then return end
	if not currentDetectedModels[model] then
		local success, hl = pcall(function()
			local h = Instance.new("Highlight") h.FillTransparency = 0.75 h.OutlineTransparency = 0 h.Adornee = model h.Parent = model return h
		end)
		if success then currentDetectedModels[model] = hl end
	end
	local highlight = currentDetectedModels[model]
	if highlight and highlight.Parent then
		highlight.FillColor = isTarget and Color3.fromRGB(245, 158, 11) or Color3.fromRGB(16, 185, 129)
		highlight.OutlineColor = isTarget and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 255, 128)
	end
end

local function getCalculatedTargetCFrame(targetHrp)
	local targetCFrame = targetHrp.CFrame
	if tweenPositionMode == "Front" then return (targetCFrame * CFrame.new(0, 0, -tweenStopDistance)).Position
	elseif tweenPositionMode == "Behind" then return (targetCFrame * CFrame.new(0, 0, tweenStopDistance)).Position
	elseif tweenPositionMode == "Up" then return (targetCFrame * CFrame.new(0, tweenStopDistance, 0)).Position 
	elseif tweenPositionMode == "Down" then return (targetCFrame * CFrame.new(0, -tweenStopDistance, 0)).Position
	end
	return targetCFrame.Position
end

if Workspace.FallenPartsDestroyHeight then VOID_THRESHOLD = Workspace.FallenPartsDestroyHeight + 5 end

LocalPlayer.CharacterAdded:Connect(function(char)
	MyCharacter = char stopTween() applyFreezeStatus(false)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if hrp then task.wait(0.3) savedSpawnCFrame = hrp.CFrame end
end)

task.spawn(function()
	if MyCharacter then
		local hrp = MyCharacter:FindFirstChild("HumanoidRootPart") or MyCharacter:WaitForChild("HumanoidRootPart", 5)
		if hrp then savedSpawnCFrame = hrp.CFrame end
	end
end)

-- ============================================================
-- 🔄 RENDER LOOP (ENGINE LOCK ORIENTASI 3D)
-- ============================================================
RunService.RenderStepped:Connect(function()
	if not MyCharacter then return end
	local myHrp = MyCharacter:FindFirstChild("HumanoidRootPart")
	local humanoid = MyCharacter:FindFirstChildOfClass("Humanoid")
	if not myHrp then return end
	
	if myHrp.Position.Y < VOID_THRESHOLD and savedSpawnCFrame then
		stopTween()
		myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		myHrp.CFrame = savedSpawnCFrame + Vector3.new(0, 3, 0)
	end
	
	if isForceFaceEnabled and activeTargetModel and activeTargetModel.Parent then
		local targetHrp = activeTargetModel:FindFirstChild("HumanoidRootPart") or activeTargetModel.PrimaryPart
		if targetHrp then
			if humanoid and not humanoid.PlatformStand then humanoid.PlatformStand = true end
			myHrp.CFrame = CFrame.lookAt(myHrp.Position, targetHrp.Position)
		end
	end
end)

-- ============================================================
-- 🗺️ OBJECTIVE FINDER
-- ============================================================
local function findAlternativeObjective()
	local bestObj = nil local closestDist = math.huge
	local myHrp = MyCharacter:FindFirstChild("HumanoidRootPart") if not myHrp then return nil end

	for _, v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Model") then
			local name = v.Name:lower()
			if name:find("arrow") or name:find("shining") or name:find("objective") or name:find("checkpoint") or v:FindFirstChildOfClass("Sparkles") or v:FindFirstChildOfClass("ParticleEmitter") then
				local part = v:IsA("BasePart") and v or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
				if part and part ~= myHrp and not v:IsDescendantOf(MyCharacter) then
					local dist = (myHrp.Position - part.Position).Magnitude
					if dist < closestDist and dist > 2 then
						closestDist = dist bestObj = part
					end
				end
			end
		end
	end
	return bestObj, closestDist
end

-- ============================================================
-- 🤖 CHASE DETECTION SYSTEM
-- ============================================================
local chaseKeywords = {
	"ai", "chase", "follow", "pathfind", "pursue", "patrol",
	"enemy", "attack", "hunt", "seek", "aggro", "hostile",
	"npc", "mob", "zombie", "monster", "wander", "brain"
}

local function hasChaseScript(model)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("Script") or child:IsA("ModuleScript") then
			local nameLower = child.Name:lower()
			for i = 1, #chaseKeywords do if nameLower:find(chaseKeywords[i], 1, true) then return true end end
		end
	end
	return false
end

local function isChasing(hrp, myHrp)
	local vel = hrp.AssemblyLinearVelocity if vel.Magnitude < 0.5 then return false end
	local toPlayer = myHrp.Position - hrp.Position if toPlayer.Magnitude < 0.1 then return false end
	return vel.Unit:Dot(toPlayer.Unit) > 0.65
end

local function isApproachingPlayer(model, hrp, myHrp)
	local dist = (hrp.Position - myHrp.Position).Magnitude
	if not distanceHistory[model] then distanceHistory[model] = {} end
	local history = distanceHistory[model] table.insert(history, dist)
	if #history > 5 then table.remove(history, 1) end
	if #history < 3 then return false end
	return (history[1] - history[#history]) > 1.5 
end

-- ============================================================
-- 🚀 DYNAMIC TWEEN CONTROLLER
-- ============================================================
local function handleDynamicTween()
	if not isTweenEnabled or not activeTargetModel or not activeTargetModel.Parent then
		stopTween()
		return
	end
	
	local targetHrp = activeTargetModel:FindFirstChild("HumanoidRootPart") or activeTargetModel.PrimaryPart
	local myHrp = MyCharacter:FindFirstChild("HumanoidRootPart")
	if not targetHrp or not myHrp then return end
	
	local destinationPoint = getCalculatedTargetCFrame(targetHrp)
	local currentDistance = (myHrp.Position - destinationPoint).Magnitude
	
	if currentDistance < 1.5 then 
		if isTweeningNow then isTweeningNow = false stopTween() end
		return 
	end
	
	if currentDistance > 500 then
		stopTween()
		myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		myHrp.CFrame = CFrame.new(destinationPoint + Vector3.new(0, 3, 0), targetHrp.Position)
		task.wait(0.1)
		return
	end
	
	if lastTweenTarget ~= activeTargetModel or not activeTween or not isTweeningNow then
		lastTweenTarget = activeTargetModel
		isTweeningNow = true
		applyFreezeStatus(true) 
		
		local duration = currentDistance / tweenSpeed
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		
		if activeTween then pcall(function() activeTween:Cancel() end) end
		isTweeningNow = true
		
		local finalRotationCFrame = CFrame.lookAt(destinationPoint, targetHrp.Position)
		activeTween = TweenService:Create(myHrp, tweenInfo, {CFrame = finalRotationCFrame})
		activeTween:Play()
		
		activeTween.Completed:Connect(function()
			activeTween = nil
			isTweeningNow = false
			applyFreezeStatus(isTweenEnabled)
		end)
	end
end

-- ============================================================
-- 📡 MAIN RADAR ENGINE v14.8
-- ============================================================
local function scanAndExecute()
	if not isDetectionEnabled or not MyCharacter then return end
	local myHrp = MyCharacter:FindFirstChild("HumanoidRootPart") if not myHrp then return end
	
	local myPos = myHrp.Position
	local validList = {}
	local activeThisScan = {}
	
	if isGlobalScan then
		for obj, nameLower in pairs(CachedModels) do
			if obj and obj.Parent then
				local hrp = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				if hrp then
					local shouldAdd = false
					local finalHealth = 100
					
					if typeScanMode == "Folder/Name" then
						if #customEnemyNames > 0 then
							for i = 1, #customEnemyNames do
								if string.find(nameLower, customEnemyNames[i], 1, true) then shouldAdd = true break end
							end
						else
							if string.find(nameLower, "enemy", 1, true) or string.find(nameLower, "monster", 1, true) or string.find(nameLower, "mob", 1, true) then shouldAdd = true end
						end
						finalHealth = obj:GetAttribute("Health") or obj:GetAttribute("HP") or 100
						
					elseif typeScanMode == "Humanoid" then
						local humanoid = obj:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							shouldAdd = true
							finalHealth = humanoid.Health
						end
						
					elseif typeScanMode == "Health Class" then
						local humanoid = obj:FindFirstChildOfClass("Humanoid")
						local customHealthAttr = obj:GetAttribute("Health") or obj:GetAttribute("HP") or obj:GetAttribute("health") or obj:GetAttribute("hp")
						if (humanoid and humanoid.Health > 0) then
							shouldAdd = true finalHealth = humanoid.Health
						elseif customHealthAttr and tonumber(customHealthAttr) and tonumber(customHealthAttr) > 0 then
							shouldAdd = true finalHealth = tonumber(customHealthAttr)
						end
						
					elseif typeScanMode == "Universal" then
						if obj.Name ~= "Workspace" and not obj:IsDescendantOf(Workspace:FindFirstChild("Terrain")) then shouldAdd = true end
						
					elseif typeScanMode == "Script Detect" then
						if hasChaseScript(obj) then shouldAdd = true end
						finalHealth = obj:GetAttribute("Health") or obj:GetAttribute("HP") or 100
						
					elseif typeScanMode == "Chase Detect" then
						local approaching = isApproachingPlayer(obj, hrp, myHrp)
						local chasing = isChasing(hrp, myHrp)
						local scriptMatch = hasChaseScript(obj)
						local score = (scriptMatch and 1 or 0) + (chasing and 1 or 0) + (approaching and 1 or 0)
						if score >= 2 then shouldAdd = true end
						finalHealth = obj:GetAttribute("Health") or obj:GetAttribute("HP") or 100
					end
					
					if shouldAdd then
						validList[obj] = { Instance = obj, Hrp = hrp, Distance = (myPos - hrp.Position).Magnitude, Health = finalHealth, Name = nameLower }
						activeThisScan[obj] = true
					end
				end
			else CachedModels[obj] = nil end
		end
	else
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {MyCharacter}
		local partsInRadius = Workspace:GetPartBoundsInRadius(myPos, currentRadius, overlapParams)
		
		for i = 1, #partsInRadius do
			local model = partsInRadius[i] and partsInRadius[i].Parent
			if model and model:IsA("Model") and not validList[model] then
				local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
				if hrp then
					local shouldAdd = false local finalHealth = 100 local nameLower = model.Name:lower()
					
					if typeScanMode == "Folder/Name" then
						if #customEnemyNames > 0 then
							for n = 1, #customEnemyNames do
								if string.find(nameLower, customEnemyNames[n], 1, true) then shouldAdd = true break end
							end
						else
							if string.find(nameLower, "enemy", 1, true) or string.find(nameLower, "monster", 1, true) or string.find(nameLower, "mob", 1, true) then shouldAdd = true end
						end
						finalHealth = model:GetAttribute("Health") or model:GetAttribute("HP") or 100
						
					elseif typeScanMode == "Humanoid" then
						local humanoid = model:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then shouldAdd = true finalHealth = humanoid.Health end
						
					elseif typeScanMode == "Health Class" then
						local humanoid = model:FindFirstChildOfClass("Humanoid")
						local customHealthAttr = model:GetAttribute("Health") or model:GetAttribute("HP") or model:GetAttribute("health") or model:GetAttribute("hp")
						if (humanoid and humanoid.Health > 0) then
							shouldAdd = true finalHealth = humanoid.Health
						elseif customHealthAttr and tonumber(customHealthAttr) and tonumber(customHealthAttr) > 0 then
							shouldAdd = true finalHealth = tonumber(customHealthAttr)
						end
						
					elseif typeScanMode == "Universal" then
						if model.Name ~= "Workspace" and not model:IsDescendantOf(Workspace:FindFirstChild("Terrain")) then shouldAdd = true end
						
					elseif typeScanMode == "Script Detect" then
						if hasChaseScript(model) then shouldAdd = true end
						finalHealth = model:GetAttribute("Health") or model:GetAttribute("HP") or 100
						
					elseif typeScanMode == "Chase Detect" then
						local approaching = isApproachingPlayer(model, hrp, myHrp)
						local chasing = isChasing(hrp, myHrp)
						local scriptMatch = hasChaseScript(model)
						local score = (scriptMatch and 1 or 0) + (chasing and 1 or 0) + (approaching and 1 or 0)
						if score >= 2 then shouldAdd = true end
						finalHealth = model:GetAttribute("Health") or model:GetAttribute("HP") or 100
					end
					
					if shouldAdd then
						validList[model] = { Instance = model, Hrp = hrp, Distance = (myPos - hrp.Position).Magnitude, Health = finalHealth, Name = nameLower }
						activeThisScan[model] = true
					end
				end
			end
		end
	end
	
	local sortedTargets = {}
	for _, data in pairs(validList) do table.insert(sortedTargets, data) end
	
	if isBringEnemiesEnabled then
		for _, data in ipairs(sortedTargets) do
			pcall(function()
				if data.Hrp and data.Instance ~= MyCharacter then
					data.Hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					data.Hrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -4) 
				end
			end)
		end
	end
	
	if #sortedTargets > 0 then
		if priorityMode == "Jarak" then table.sort(sortedTargets, function(a, b) return a.Distance < b.Distance end)
		elseif priorityMode == "HP Terendah" then table.sort(sortedTargets, function(a, b) return a.Health < b.Health end)
		elseif priorityMode == "Nama" then table.sort(sortedTargets, function(a, b) return a.Name < b.Name end) end
		
		local primeTarget = sortedTargets[1] activeTargetModel = primeTarget.Instance
		TargetStatusLabel.Text = string.format("🎯 Target: %s\n[Jarak: %.1f | HP: %d | Mode: %s]", primeTarget.Instance.Name, primeTarget.Distance, math.round(primeTarget.Health), typeScanMode)
		TargetStatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
		handleDynamicTween()
	else
		local objObjective, objDist = findAlternativeObjective()
		if objObjective and isTweenEnabled then
			activeTargetModel = objObjective.Parent:IsA("Model") and objObjective.Parent or objObjective
			TargetStatusLabel.Text = string.format("✨ Tracking Objective: %s\n[Jarak: %.1f studs]", objObjective.Name, objDist)
			TargetStatusLabel.TextColor3 = Color3.fromRGB(56, 189, 248) 
			handleDynamicTween()
		else
			activeTargetModel = nil
			TargetStatusLabel.Text = "🎯 Target Saat Ini: None (Mencari Penunjuk Jalan...)"
			TargetStatusLabel.TextColor3 = Color3.fromRGB(120, 135, 160)
			stopTween()
		end
	end
	
	for model, _ in pairs(validList) do applyOutline(model, (model == activeTargetModel)) end
	
	for existingModel, highlight in pairs(currentDetectedModels) do
		if not activeThisScan[existingModel] or not existingModel.Parent then
			if highlight then pcall(function() highlight:Destroy() end) end 
			currentDetectedModels[existingModel] = nil distanceHistory[existingModel] = nil 
		end
	end
	
	applyFreezeStatus(isTweenEnabled)
end

-- ============================================================
-- 🔄 MAIN EXECUTION LOOP
-- ============================================================
task.spawn(function()
	while true do
		if ScreenGui and ScreenGui.Parent then
			local success, err = pcall(scanAndExecute)
			if not success then warn("📡 Radar Core Exception: " .. tostring(err)) end
		else break end
		task.wait(SCAN_INTERVAL)
	end
end)

print("✅ 📡 Ultimate Radar v14.8 (Humanoid Default & Minimize Restored) Loaded Successfully!")