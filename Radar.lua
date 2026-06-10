--[[=================================================================
	BloxCrypt - Radar Module Core (Standalone Engine)
	Default Scan: Humanoid
=================================================================]]

local RadarModule = {}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local MyCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- State Variables (Shared via Module)
RadarModule.isDetectionEnabled = false
RadarModule.isTweenEnabled = false
RadarModule.isForceFaceEnabled = false
RadarModule.isBringEnemiesEnabled = false

local DEFAULT_RADIUS = 200  
local SCAN_INTERVAL = 0.1   

local currentRadius = DEFAULT_RADIUS
local tweenStopDistance = 10 
local tweenSpeed = 60 
local typeScanMode = "Humanoid" -- Default sesuai request

local currentDetectedModels = {}
local activeTargetModel = nil
local activeTween = nil
local lastTweenTarget = nil
local isTweeningNow = false 

local CachedModels = {}

-- Initialize Character
LocalPlayer.CharacterAdded:Connect(function(char)
	MyCharacter = char
	RadarModule.StopTween()
end)

local function checkAndCacheModel(obj)
	if obj:IsA("Model") and obj ~= MyCharacter and not obj:IsDescendantOf(MyCharacter) then
		CachedModels[obj] = obj.Name:lower()
	end
end

task.spawn(function()
	for _, o in ipairs(Workspace:GetDescendants()) do
		checkAndCacheModel(o)
	end
end)
Workspace.DescendantAdded:Connect(checkAndCacheModel)

function RadarModule.ClearAllOutlines()
	for model, highlight in pairs(currentDetectedModels) do
		if highlight then pcall(function() highlight:Destroy() end) end
		currentDetectedModels[model] = nil
	end
end

function RadarModule.StopTween()
	if activeTween then pcall(function() activeTween:Cancel() end) activeTween = nil end
	lastTweenTarget = nil
	isTweeningNow = false
	RadarModule.ApplyFreezeStatus(RadarModule.isTweenEnabled)
end

function RadarModule.ApplyFreezeStatus(state)
	if MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart") then
		local hrp = MyCharacter.HumanoidRootPart
		local humanoid = MyCharacter:FindFirstChildOfClass("Humanoid")
		hrp.Anchored = (state and not isTweeningNow)
		if humanoid then
			if state then
				humanoid.PlatformStand = true
				pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end)
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
	return (targetHrp.CFrame * CFrame.new(0, tweenStopDistance, 0)).Position -- Default Mode Up
end

RunService.RenderStepped:Connect(function()
	if not MyCharacter or not RadarModule.isDetectionEnabled then return end
	local myHrp = MyCharacter:FindFirstChild("HumanoidRootPart")
	if not myHrp then return end
	
	if RadarModule.isForceFaceEnabled and activeTargetModel and activeTargetModel.Parent then
		local targetHrp = activeTargetModel:FindFirstChild("HumanoidRootPart") or activeTargetModel.PrimaryPart
		if targetHrp then
			myHrp.CFrame = CFrame.lookAt(myHrp.Position, targetHrp.Position)
		end
	end
end)

local function handleDynamicTween()
	if not RadarModule.isTweenEnabled or not activeTargetModel or not activeTargetModel.Parent then RadarModule.StopTween() return end
	local targetHrp = activeTargetModel:FindFirstChild("HumanoidRootPart") or activeTargetModel.PrimaryPart
	local myHrp = MyCharacter:FindFirstChild("HumanoidRootPart")
	if not targetHrp or not myHrp then return end
	
	local destinationPoint = getCalculatedTargetCFrame(targetHrp)
	local currentDistance = (myHrp.Position - destinationPoint).Magnitude
	
	if currentDistance < 1.5 then 
		if isTweeningNow then isTweeningNow = false RadarModule.StopTween() end return 
	end
	
	if lastTweenTarget ~= activeTargetModel or not activeTween or not isTweeningNow then
		lastTweenTarget = activeTargetModel
		isTweeningNow = true
		RadarModule.ApplyFreezeStatus(true) 
		local duration = currentDistance / tweenSpeed
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		if activeTween then pcall(function() activeTween:Cancel() end) end
		local finalRotationCFrame = CFrame.lookAt(destinationPoint, targetHrp.Position)
		activeTween = TweenService:Create(myHrp, tweenInfo, {CFrame = finalRotationCFrame})
		activeTween:Play()
	end
end

function RadarModule.ScanAndExecute()
	if not RadarModule.isDetectionEnabled or not MyCharacter then return end
	local myHrp = MyCharacter:FindFirstChild("HumanoidRootPart") if not myHrp then return end
	local myPos = myHrp.Position
	local validList = {}
	local activeThisScan = {}
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {MyCharacter}
	local partsInRadius = Workspace:GetPartBoundsInRadius(myPos, currentRadius, overlapParams)
	
	for i = 1, #partsInRadius do
		local model = partsInRadius[i] and partsInRadius[i].Parent
		if model and model:IsA("Model") and not validList[model] then
			local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
			if hrp then
				local shouldAdd = false
				if typeScanMode == "Humanoid" then
					local humanoid = model:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then shouldAdd = true end
				elseif typeScanMode == "Universal" then
					if model.Name ~= "Workspace" then shouldAdd = true end
				end
				
				if shouldAdd then
					validList[model] = { Instance = model, Hrp = hrp, Distance = (myPos - hrp.Position).Magnitude }
					activeThisScan[model] = true
				end
			end
		end
	end
	
	local sortedTargets = {}
	for _, data in pairs(validList) do table.insert(sortedTargets, data) end
	
	if RadarModule.isBringEnemiesEnabled then
		for _, data in ipairs(sortedTargets) do
			pcall(function() if data.Hrp then data.Hrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -4) end end)
		end
	end
	
	if #sortedTargets > 0 then
		table.sort(sortedTargets, function(a, b) return a.Distance < b.Distance end)
		activeTargetModel = sortedTargets[1].Instance
		handleDynamicTween()
	else
		activeTargetModel = nil RadarModule.StopTween()
	end
	
	for model, _ in pairs(validList) do applyOutline(model, (model == activeTargetModel)) end
	for existingModel, highlight in pairs(currentDetectedModels) do
		if not activeThisScan[existingModel] or not existingModel.Parent then
			if highlight then pcall(function() highlight:Destroy() end) end 
			currentDetectedModels[existingModel] = nil
		end
	end
end

function RadarModule.GetActiveTargetName()
	return activeTargetModel and activeTargetModel.Name or "None"
end

function RadarModule.SetScanMode(mode)
	typeScanMode = mode
	RadarModule.ClearAllOutlines()
	RadarModule.StopTween()
end

function RadarModule.SetSpeed(speed)
	tweenSpeed = speed
	if isTweeningNow then RadarModule.StopTween() end
end

-- Engine Loop
task.spawn(function()
	while true do
		if RadarModule.isDetectionEnabled then pcall(RadarModule.ScanAndExecute) end
		task.wait(SCAN_INTERVAL)
	end
end)

return RadarModule