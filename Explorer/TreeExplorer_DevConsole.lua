-- ╔══════════════════════════════════════════════════════════╗
-- ║   BloxCrypt Tree Explorer v1.5 [INTEGRATED CODE EDITOR]  ║
-- ║  Paste di Developer Console (F9) > Client > Command Line  ║
-- ╚══════════════════════════════════════════════════════════╝

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TextService  = game:GetService("TextService")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- Hapus GUI lama jika ada
if PlayerGui:FindFirstChild("BCTreeExplorer") then
	PlayerGui.BCTreeExplorer:Destroy()
end

-- ─── Warna & Konstanta ──────────────────────────────────────
local C = {
	BG         = Color3.fromRGB(11,  13,  20),
	PANEL      = Color3.fromRGB(18,  20,  32),
	TITLEBAR   = Color3.fromRGB(22,  25,  40),
	ACCENT     = Color3.fromRGB(99,  102, 241),
	GREEN      = Color3.fromRGB(16,  185, 129),
	AMBER      = Color3.fromRGB(245, 158, 11),
	RED        = Color3.fromRGB(239, 68,  68),
	TEXT       = Color3.fromRGB(210, 218, 235),
	SUBTEXT    = Color3.fromRGB(120, 135, 160),
	HOVER      = Color3.fromRGB(30,  34,  55),
	SEL        = Color3.fromRGB(25,  38,  60),
	SEL_TEXT   = Color3.fromRGB(129, 230, 217),
	ROW_HEIGHT = 26,
}

-- ─── Utility ────────────────────────────────────────────────
local function round(frame, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = frame
	return c
end

local function stroke(frame, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or C.ACCENT
	s.Thickness = thick or 1
	s.Parent = frame
	return s
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = props.font or Enum.Font.Gotham
	l.TextSize = props.size or 13
	l.TextColor3 = props.color or C.TEXT
	l.TextXAlignment = props.xalign or Enum.TextXAlignment.Left
	l.Text = props.text or ""
	l.Size = props.sz or UDim2.new(1, 0, 0, 24)
	l.Position = props.pos or UDim2.new(0, 0, 0, 0)
	l.TextTruncate = props.truncate or Enum.TextTruncate.None
	l.Parent = parent
	return l
end

local function button(parent, props)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = props.bg or C.ACCENT
	b.TextColor3 = props.tc or Color3.new(1,1,1)
	b.Font = props.font or Enum.Font.GothamBold
	b.TextSize = props.size or 13
	b.Text = props.text or ""
	b.Size = props.sz or UDim2.new(0, 100, 0, 32)
	b.Position = props.pos or UDim2.new(0,0,0,0)
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Parent = parent
	round(b, props.r or 8)

	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = Color3.new(
			math.min(b.BackgroundColor3.R + 0.08, 1),
			math.min(b.BackgroundColor3.G + 0.08, 1),
			math.min(b.BackgroundColor3.B + 0.08, 1)
		)
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = props.bg or C.ACCENT
	end)
	return b
end

-- ─── Icon Lookup (didefinisikan sebelum fungsi yang membutuhkan) ──
local ICONS = {
	Workspace="🌍", Folder="📁", Model="🗂️", Part="🧱",
	Script="📜", LocalScript="📜", ModuleScript="📦",
	RemoteEvent="📡", RemoteFunction="📡", BindableEvent="⚡",
	StringValue="🔤", IntValue="🔢", NumberValue="🔢", BoolValue="✅",
	Players="👥", Player="👤", ReplicatedStorage="💾", ServerStorage="🗄️", StarterGui="🎨"
}
local function getIcon(className) return ICONS[className] or "·" end

-- ─── Path & Tree Text ───────────────────────────────────────

-- getPath: O(n) — build terbalik lalu reverse
-- Menggunakan bracket notation ["Name"] jika nama bukan identifier Lua yang valid
-- (mengandung spasi, titik, kutip, diawali angka, dll)
local function getPath(inst)
	local segments = {}
	local cur = inst
	while cur and cur ~= game do
		local n = cur.Name
		if n == "" or not n:find("^[_%a][_%w]*$") then
			-- Escape backslash dan double-quote untuk bracket notation
			local escaped = n:gsub("\\", "\\\\"):gsub('"', '\\"')
			segments[#segments + 1] = '["' .. escaped .. '"]'
		else
			segments[#segments + 1] = "." .. n
		end
		cur = cur.Parent
	end
	segments[#segments + 1] = "game"
	for i = 1, math.floor(#segments / 2) do
		segments[i], segments[#segments - i + 1] = segments[#segments - i + 1], segments[i]
	end
	return table.concat(segments, "")
end

-- getTreeText: menggunakan table buffer untuk menghindari O(n²) string concatenation
local function getTreeText(inst, depth, maxDepth, buffer)
	depth = depth or 0
	maxDepth = maxDepth or 8
	buffer = buffer or {}
	if depth > maxDepth then
		buffer[#buffer + 1] = string.rep("  ", depth) .. "... (truncated)"
		return buffer
	end
	local indent = string.rep("  ", depth)
	buffer[#buffer + 1] = indent .. getIcon(inst.ClassName) .. " " .. inst.Name .. " [" .. inst.ClassName .. "]"
	local ok, children = pcall(function() return inst:GetChildren() end)
	if ok then
		for _, child in ipairs(children) do
			buffer[#buffer + 1] = "\n"
			getTreeText(child, depth + 1, maxDepth, buffer)
		end
	end
	return buffer
end

-- Helper: konversi buffer getTreeText ke string
local function getTreeTextString(inst)
	local buf = getTreeText(inst)
	return table.concat(buf, "")
end

-- copyText: mengembalikan true hanya jika clipboard benar-benar tersedia dan berhasil
local function copyText(text)
	local ok, result = pcall(function()
		if setclipboard then setclipboard(text) return true end
		if Clipboard then Clipboard.set(text) return true end
		return false
	end)
	return ok and result == true
end

-- ═══════════════════════════════════════════════════════════
--   GUI ROOT
-- ═══════════════════════════════════════════════════════════
local Screen = Instance.new("ScreenGui")
Screen.Name = "BCTreeExplorer"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder = 999
Screen.Parent = PlayerGui

-- Main Container (Menyatukan Main Window & Editor)
local MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(0, 520, 0, 680)
MainContainer.Position = UDim2.new(0.5, -260, 0.5, -340)
MainContainer.BackgroundTransparency = 1
MainContainer.Parent = Screen

local Win = Instance.new("Frame")
Win.Name = "Window"
Win.Size = UDim2.new(1, 0, 1, 0)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel = 0
Win.ClipsDescendants = true
Win.Parent = MainContainer
round(Win, 14)
stroke(Win, C.ACCENT, 1.5)

-- ─── PANEL JENDELA EDITOR (SEBELAH KANAN) ───────────────────
local EditorWin = Instance.new("Frame")
EditorWin.Name = "EditorWindow"
EditorWin.Size = UDim2.new(0, 450, 1, 0)
EditorWin.Position = UDim2.new(1, 15, 0, 0)
EditorWin.BackgroundColor3 = C.BG
EditorWin.Visible = false
EditorWin.Parent = MainContainer
round(EditorWin, 14)
stroke(EditorWin, C.AMBER, 1.5)

local ETBar = Instance.new("Frame")
ETBar.Size = UDim2.new(1, 0, 0, 52)
ETBar.BackgroundColor3 = C.TITLEBAR
ETBar.Parent = EditorWin
round(ETBar, 14)
Instance.new("Frame", ETBar).Size = UDim2.new(1, 0, 0, 14)
ETBar.Frame.Position = UDim2.new(0, 0, 1, -14)
ETBar.Frame.BackgroundColor3 = C.TITLEBAR
ETBar.Frame.BorderSizePixel = 0

local EditorTitle = label(ETBar, {text = "📝 Script Editor", sz = UDim2.new(1, -60, 1, 0), pos = UDim2.new(0, 16, 0, 0), font = Enum.Font.GothamBold, size = 14, color = C.AMBER})
local ECloseBtn = button(ETBar, {text = "✕", sz = UDim2.new(0, 30, 0, 30), pos = UDim2.new(1, -42, 0.5, -15), bg = C.RED, size = 13})
ECloseBtn.MouseButton1Click:Connect(function()
	EditorWin.Visible = false
	MainContainer.Size = UDim2.new(0, 520, 0, 680)
end)

local CodeScroll = Instance.new("ScrollingFrame")
CodeScroll.Size = UDim2.new(1, -24, 1, -120)
CodeScroll.Position = UDim2.new(0, 12, 0, 64)
CodeScroll.BackgroundColor3 = C.PANEL
CodeScroll.ScrollBarThickness = 5
CodeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CodeScroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
CodeScroll.Parent = EditorWin
round(CodeScroll, 8)

local CodeInput = Instance.new("TextBox")
CodeInput.Size = UDim2.new(1, -10, 1, -10)
CodeInput.Position = UDim2.new(0, 10, 0, 10)
CodeInput.BackgroundTransparency = 1
CodeInput.Text = "-- Klik Edit Source pada script untuk memuat kode..."
CodeInput.TextColor3 = Color3.fromRGB(240, 240, 240)
CodeInput.Font = Enum.Font.Code
CodeInput.TextSize = 13
CodeInput.ClearTextOnFocus = false
CodeInput.MultiLine = true
CodeInput.TextXAlignment = Enum.TextXAlignment.Left
CodeInput.TextYAlignment = Enum.TextYAlignment.Top
CodeInput.AutomaticSize = Enum.AutomaticSize.XY
CodeInput.Parent = CodeScroll

local BtnSaveCode = button(EditorWin, {text = "💾 Save Code Changes", bg = C.GREEN, sz = UDim2.new(1, -24, 0, 36), pos = UDim2.new(0, 12, 1, -48), size = 13, r = 8})

-- ─── TITLE BAR MAIN WINDOW ──────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1, 0, 0, 52)
TBar.BackgroundColor3 = C.TITLEBAR
TBar.ZIndex = 10
TBar.Parent = Win
round(TBar, 14)
local TBarFix = Instance.new("Frame", TBar)
TBarFix.Size = UDim2.new(1, 0, 0, 14)
TBarFix.Position = UDim2.new(0, 0, 1, -14)
TBarFix.BackgroundColor3 = C.TITLEBAR
TBarFix.BorderSizePixel = 0

label(TBar, {text = "🌳  BloxCrypt Tree Explorer v1.5", sz = UDim2.new(1, -110, 1, 0), pos = UDim2.new(0, 16, 0, 0), font = Enum.Font.GothamBold, size = 15, color = Color3.fromRGB(225, 228, 255)})
local CloseBtn = button(TBar, {text = "✕", sz = UDim2.new(0, 30, 0, 30), pos = UDim2.new(1, -42, 0.5, -15), bg = C.RED, size = 14})
CloseBtn.ZIndex = 11
CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

-- Drag System (mendukung Mouse + Touch)
do
	local dragging, dragStart, startPos
	TBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = i.Position
			startPos = MainContainer.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			MainContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- Selector Root
local ROOT_NAMES = {"game","Workspace","ReplicatedStorage","Players","Lighting","StarterGui"}
local ROOT_OBJS  = {}
for _, n in ipairs(ROOT_NAMES) do
	local ok, res = pcall(function() return n == "game" and game or game:GetService(n) end)
	if ok and res then ROOT_OBJS[n] = res end
end

local SelectorBg = Instance.new("Frame")
SelectorBg.Size = UDim2.new(1, -24, 0, 36)
SelectorBg.Position = UDim2.new(0, 12, 0, 58)
SelectorBg.BackgroundColor3 = C.PANEL
SelectorBg.Parent = Win
round(SelectorBg, 8)

local SelectorScroll = Instance.new("ScrollingFrame")
SelectorScroll.Size = UDim2.new(1, -12, 1, -8)
SelectorScroll.Position = UDim2.new(0, 6, 0, 4)
SelectorScroll.BackgroundTransparency = 1
SelectorScroll.ScrollBarThickness = 0
SelectorScroll.ScrollingDirection = Enum.ScrollingDirection.X
SelectorScroll.Parent = SelectorBg
local SL = Instance.new("UIListLayout", SelectorScroll)
SL.FillDirection = Enum.FillDirection.Horizontal
SL.SortOrder = Enum.SortOrder.LayoutOrder
SL.Padding = UDim.new(0, 5)
SL.VerticalAlignment = Enum.VerticalAlignment.Center
SL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	SelectorScroll.CanvasSize = UDim2.new(0, SL.AbsoluteContentSize.X + 10, 0, 0)
end)

local currentRoot = "game"
local rootBtns = {}
local buildTree

local function selectRoot(name)
	currentRoot = name
	for n, b in pairs(rootBtns) do
		b.BackgroundColor3 = (n == name) and C.ACCENT or C.HOVER
		b.TextColor3 = (n == name) and Color3.new(1,1,1) or C.SUBTEXT
	end
	if ROOT_OBJS[name] then buildTree(ROOT_OBJS[name]) end
end

for i, name in ipairs(ROOT_NAMES) do
	if ROOT_OBJS[name] then
		local nSize = TextService:GetTextSize(name, 12, Enum.Font.Gotham, Vector2.new(1000, 22))
		local b = Instance.new("TextButton")
		b.Text = name
		b.Size = UDim2.new(0, nSize.X + 20, 0, 22)
		b.BackgroundColor3 = (i==1) and C.ACCENT or C.HOVER
		b.TextColor3 = (i==1) and Color3.new(1,1,1) or C.SUBTEXT
		b.Font = Enum.Font.Gotham
		b.TextSize = 12
		b.BorderSizePixel = 0
		b.LayoutOrder = i
		b.Parent = SelectorScroll
		round(b, 6)
		rootBtns[name] = b
		b.MouseButton1Click:Connect(function() selectRoot(name) end)
	end
end

local StatusLbl = label(Win, {text = "Pilih item untuk modifikasi / edit...", sz = UDim2.new(1, -24, 0, 20), pos = UDim2.new(0, 12, 0, 98), color = C.SUBTEXT, size = 11})

-- Tree Explorer Area
local TreeScroll = Instance.new("ScrollingFrame")
TreeScroll.Size = UDim2.new(1, -24, 1, -340)
TreeScroll.Position = UDim2.new(0, 12, 0, 122)
TreeScroll.BackgroundColor3 = C.PANEL
TreeScroll.ScrollBarThickness = 5
TreeScroll.ScrollBarImageColor3 = C.ACCENT
TreeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TreeScroll.Parent = Win
round(TreeScroll, 10)
Instance.new("UIListLayout", TreeScroll).SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", TreeScroll).PaddingTop = UDim.new(0, 4)

-- Bottom Control Panel
local BottomPanel = Instance.new("Frame")
BottomPanel.Size = UDim2.new(1, -24, 0, 190)
BottomPanel.Position = UDim2.new(0, 12, 1, -202)
BottomPanel.BackgroundColor3 = C.PANEL
BottomPanel.Parent = Win
round(BottomPanel, 10)

local PathBox = Instance.new("Frame")
PathBox.Size = UDim2.new(1, -20, 0, 30)
PathBox.Position = UDim2.new(0, 10, 0, 10)
PathBox.BackgroundColor3 = C.BG
PathBox.Parent = BottomPanel
round(PathBox, 6)
stroke(PathBox, Color3.fromRGB(40, 46, 75), 1)
label(PathBox, {text = "📍", sz = UDim2.new(0, 24, 1, 0), pos = UDim2.new(0, 4, 0, 0), size = 12})
local PathLbl = label(PathBox, {text = "Belum ada objek yang dipilih…", sz = UDim2.new(1, -34, 1, 0), pos = UDim2.new(0, 28, 0, 0), color = C.SUBTEXT, size = 12, truncate = Enum.TextTruncate.AtEnd})

local InfoLbl = label(BottomPanel, {text = "No Target Selected", sz = UDim2.new(1, -20, 0, 18), pos = UDim2.new(0, 10, 0, 45), color = C.SUBTEXT, size = 11})

-- Quick Instance Creator Inputs
local CreatorTitle = label(BottomPanel, {text = "🛠️  Quick Operations & Creation", sz = UDim2.new(1, -20, 0, 18), pos = UDim2.new(0, 10, 0, 68), font = Enum.Font.GothamBold, color = C.ACCENT, size = 11})
local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0, 130, 0, 28)
NameInput.Position = UDim2.new(0, 10, 0, 90)
NameInput.BackgroundColor3 = C.BG
NameInput.Text = "NewScript"
NameInput.TextColor3 = C.TEXT
NameInput.Font = Enum.Font.Gotham
NameInput.TextSize = 12
NameInput.Parent = BottomPanel
round(NameInput, 6)
stroke(NameInput, Color3.fromRGB(50, 55, 80), 1)

local ClassInput = Instance.new("TextBox")
ClassInput.Size = UDim2.new(0, 130, 0, 28)
ClassInput.Position = UDim2.new(0, 150, 0, 90)
ClassInput.BackgroundColor3 = C.BG
ClassInput.Text = "Script"
ClassInput.TextColor3 = C.AMBER
ClassInput.Font = Enum.Font.GothamBold
ClassInput.TextSize = 12
ClassInput.Parent = BottomPanel
round(ClassInput, 6)
stroke(ClassInput, Color3.fromRGB(50, 55, 80), 1)

label(BottomPanel, {text = "✏️ Nama Objek / Value", sz = UDim2.new(0, 130, 0, 14), pos = UDim2.new(0, 10, 0, 120), color = C.SUBTEXT, size = 10})
label(BottomPanel, {text = "⚙️ Class / Properti Value", sz = UDim2.new(0, 130, 0, 14), pos = UDim2.new(0, 150, 0, 120), color = C.SUBTEXT, size = 10})

-- ACTION BUTTONS
local BtnCreate = button(BottomPanel, {text = "➕ Create", bg = C.GREEN, sz = UDim2.new(0, 85, 0, 28), pos = UDim2.new(0, 290, 0, 90), size = 12, r = 6})
local BtnEditSource = button(BottomPanel, {text = "📝 Edit Source", bg = C.AMBER, sz = UDim2.new(0, 110, 0, 28), pos = UDim2.new(0, 385, 0, 90), size = 12, r = 6})
BtnEditSource.Visible = false -- Hanya muncul saat memilih tipe Script

local BtnCopyPath = button(BottomPanel, {text = "📋 Path", bg = C.ACCENT, sz = UDim2.new(0, 80, 0, 28), pos = UDim2.new(1, -180, 0, 148), size = 11, r = 6})
local BtnCopyTree = button(BottomPanel, {text = "🌳 Tree", bg = C.ACCENT, sz = UDim2.new(0, 80, 0, 28), pos = UDim2.new(1, -95, 0, 148), size = 11, r = 6})
local BtnRefresh  = button(BottomPanel, {text = "🔄 Refresh", bg = C.HOVER, sz = UDim2.new(0, 80, 0, 28), pos = UDim2.new(0, 10, 0, 148), size = 11, r = 6})
BtnRefresh.TextColor3 = C.TEXT

-- ═══════════════════════════════════════════════════════════
--   LOGIC INTERAKSI (PROPERTIES & CODE EDITOR)
-- ═══════════════════════════════════════════════════════════
local selectedInst = nil
local selectedPathStr = ""
local selectedRowBtn = nil  -- Track button terpilih untuk deselect efisien
local nodeCounter = 0
local nodeRefs = {}
local createDebounce = false

-- Helper: set status dengan warna, auto-reset ke SUBTEXT setelah 3 detik
local statusResetTimer = nil
local function setStatus(text, color)
	StatusLbl.Text = text
	StatusLbl.TextColor3 = color or C.SUBTEXT
	-- Batalkan timer sebelumnya untuk mencegah race condition
	if statusResetTimer then
		task.cancel(statusResetTimer)
		statusResetTimer = nil
	end
	if color and color ~= C.SUBTEXT then
		statusResetTimer = task.delay(3, function()
			statusResetTimer = nil
			if StatusLbl then StatusLbl.TextColor3 = C.SUBTEXT end
		end)
	end
end

-- setStatus sudah auto-reset, tidak perlu helper terpisah

-- Helper: cek apakah instance masih valid (belum di-destroy)
local function isInstValid(inst)
	if inst == nil then return false end
	return pcall(function() inst.Name = inst.Name end)
end

-- deselectAll: versi efisien — hanya reset button yang terpilih, bukan iterasi semua descendant
local function deselectAll()
	if selectedRowBtn and selectedRowBtn.Parent then
		selectedRowBtn.BackgroundTransparency = 1
		selectedRowBtn.TextColor3 = C.TEXT
	end
	selectedRowBtn = nil
end

local function createNode(inst, depth)
	nodeCounter += 1
	local order = nodeCounter
	local ok, children = pcall(function() return inst:GetChildren() end)
	local hasChildren = ok and #children > 0

	local Wrap = Instance.new("Frame")
	Wrap.Name = "Wrap_" .. inst.Name
	Wrap.AutomaticSize = Enum.AutomaticSize.Y
	Wrap.Size = UDim2.new(1, 0, 0, 0)
	Wrap.BackgroundTransparency = 1
	Wrap.LayoutOrder = order

	local Row = Instance.new("Frame")
	Row.Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT)
	Row.BackgroundTransparency = 1
	Row.Parent = Wrap

	if depth > 0 then
		local guide = Instance.new("Frame")
		guide.Size = UDim2.new(0, 1, 1, 0)
		guide.Position = UDim2.new(0, depth * 14 + 6, 0, 0)
		guide.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
		guide.Parent = Row
	end

	local ExpBtn = Instance.new("TextButton")
	ExpBtn.Size = UDim2.new(0, 16, 0, 16)
	ExpBtn.Position = UDim2.new(0, depth * 14 + 6, 0.5, -8)
	ExpBtn.BackgroundTransparency = 1
	ExpBtn.Text = hasChildren and "▶" or "·"
	ExpBtn.TextColor3 = C.ACCENT
	ExpBtn.Font = Enum.Font.GothamBold
	ExpBtn.TextSize = 9
	ExpBtn.Parent = Row

	local RowBtn = Instance.new("TextButton")
	RowBtn.Name = "RowBtn"
	RowBtn.Size = UDim2.new(1, -(depth * 14 + 26), 1, 0)
	RowBtn.Position = UDim2.new(0, depth * 14 + 24, 0, 0)
	RowBtn.BackgroundTransparency = 1
	RowBtn.Text = getIcon(inst.ClassName) .. "  " .. inst.Name
	RowBtn.TextColor3 = C.TEXT
	RowBtn.Font = Enum.Font.Gotham
	RowBtn.TextSize = 13
	RowBtn.TextXAlignment = Enum.TextXAlignment.Left
	RowBtn.Parent = Row

	local ChildWrap = Instance.new("Frame")
	ChildWrap.AutomaticSize = Enum.AutomaticSize.Y
	ChildWrap.Size = UDim2.new(1, 0, 0, 0)
	ChildWrap.BackgroundTransparency = 1
	ChildWrap.Visible = false
	ChildWrap.LayoutOrder = 2
	ChildWrap.Parent = Wrap
	Instance.new("UIListLayout", ChildWrap).SortOrder = Enum.SortOrder.LayoutOrder

	local expanded, childBuilt = false, false

	local function loadMyChildren()
		if not expanded or childBuilt then return end
		childBuilt = true
		task.defer(function()
			local ok3, ch3 = pcall(function() return inst:GetChildren() end)
			if ok3 and expanded then
				for idx, child in ipairs(ch3) do
					if idx % 40 == 0 then task.wait() end
					if not expanded then break end
					local childNode = createNode(child, depth + 1)
					childNode.Parent = ChildWrap
				end
			end
		end)
	end

	-- Simpan referensi ringan untuk refresh (bukan closure penuh)
	nodeRefs[inst] = ChildWrap

	-- DETEKSI KLIK PADA FILE / OBJEK
	RowBtn.MouseButton1Click:Connect(function()
		deselectAll()
		selectedInst = inst
		selectedPathStr = getPath(inst)
		selectedRowBtn = RowBtn

		RowBtn.BackgroundTransparency = 0
		RowBtn.BackgroundColor3 = C.SEL
		RowBtn.TextColor3 = C.SEL_TEXT
		PathLbl.Text = selectedPathStr

		-- Ambil child count secara segar (bukan dari cache hasChildren)
		local okCount, childCount = pcall(function() return #inst:GetChildren() end)
		InfoLbl.Text = "🎯 Class: " .. inst.ClassName .. "  |  Children: " .. (okCount and childCount or 0)
		setStatus("Target dikunci: " .. inst.Name)

		-- Sembunyikan / Tampilkan tombol Edit Source tergantung tipe objek
		if inst:IsA("LuaSourceContainer") or inst.ClassName:find("Script") then
			BtnEditSource.Visible = true
		else
			BtnEditSource.Visible = false
		end

		-- EDIT MODE UNTUK VALUE OBJECTS
		if inst.ClassName:find("Value") and not inst.ClassName:find("Object") then
			NameInput.Text = tostring(inst.Name)
			ClassInput.Text = tostring(inst.Value)
			CreatorTitle.Text = "✏️  Edit Object Value Mode"
			BtnCreate.Text = "💾 Save Val"
			BtnCreate.BackgroundColor3 = C.AMBER
		else
			NameInput.Text = "NewScript"
			ClassInput.Text = "Script"
			CreatorTitle.Text = "🛠️  Quick Operations & Creation"
			BtnCreate.Text = "➕ Create"
			BtnCreate.BackgroundColor3 = C.GREEN
		end
	end)

	local function toggle()
		-- Re-check hasChildren secara live (bukan dari cache saat node dibuat)
		local okLive, liveChildren = pcall(function() return inst:GetChildren() end)
		if not okLive or #liveChildren == 0 then return end
		hasChildren = true
		expanded = not expanded
		ExpBtn.Text = expanded and "▼" or "▶"
		loadMyChildren()
		ChildWrap.Visible = expanded
	end
	ExpBtn.MouseButton1Click:Connect(toggle)
	RowBtn.MouseButton2Click:Connect(toggle)
	return Wrap
end

buildTree = function(rootInst)
	-- Tutup editor jika terbuka saat ganti root
	if EditorWin.Visible then
		EditorWin.Visible = false
		MainContainer.Size = UDim2.new(0, 520, 0, 680)
	end

	-- Bersihkan nodeRefs lama (sekarang hanya menyimpan referensi GUI, bukan closure)
	nodeRefs = {}

	-- Bersihkan SEMUA children TreeScroll (termasuk UIListLayout, UIPadding, dll)
	for _, c in ipairs(TreeScroll:GetChildren()) do
		c:Destroy()
	end

	-- Re-create layout yang di-destroy
	local newLayout = Instance.new("UIListLayout", TreeScroll)
	newLayout.SortOrder = Enum.SortOrder.LayoutOrder
	Instance.new("UIPadding", TreeScroll).PaddingTop = UDim.new(0, 4)

	nodeCounter = 0
	selectedInst = nil
	selectedRowBtn = nil
	PathLbl.Text = "Belum ada objek yang dipilih…"
	InfoLbl.Text = "No Target Selected"
	BtnEditSource.Visible = false

	local ok, children = pcall(function() return rootInst:GetChildren() end)
	if ok then
		task.defer(function()
			for idx, child in ipairs(children) do
				if idx % 50 == 0 then task.wait() end
				local node = createNode(child, 0)
				node.Parent = TreeScroll
			end
			setStatus("✅ Berhasil memuat " .. #children .. " objek di root.")
		end)
	end
end

-- ─── EKSEKUSI EDIT CODE (BUKA WINDOW EDITOR) ─────────────────
BtnEditSource.MouseButton1Click:Connect(function()
	if not selectedInst or not isInstValid(selectedInst) then
		setStatus("❌ Objek tidak valid atau sudah dihapus!", C.RED)
		return
	end

	local success, sourceCode = pcall(function()
		return selectedInst.Source
	end)

	if success then
		CodeInput.Text = sourceCode
		EditorTitle.Text = "📝 Editing: " .. selectedInst.Name
		MainContainer.Size = UDim2.new(0, 985, 0, 680)
		EditorWin.Visible = true
		setStatus("Editor dibuka untuk script: " .. selectedInst.Name)
	else
		setStatus("❌ Gagal: Lingkungan eksekusi Anda memblokir modifikasi properti '.Source'", C.RED)
	end
end)

-- ─── TOMBOL SIMPAN PERUBAHAN SCRIPT ──────────────────────────
local saveDebounce = false
BtnSaveCode.MouseButton1Click:Connect(function()
	if not selectedInst or not isInstValid(selectedInst) then
		setStatus("❌ Objek tidak valid atau sudah dihapus!", C.RED)
		return
	end
	if saveDebounce then return end
	saveDebounce = true
	task.delay(0.5, function() saveDebounce = false end)

	local success, err = pcall(function()
		selectedInst.Source = CodeInput.Text
	end)

	if success then
		setStatus("💾 Sukses menyimpan source code terbaru ke " .. selectedInst.Name .. "!", C.GREEN)
	else
		setStatus("❌ Gagal Menyimpan: " .. tostring(err), C.RED)
	end
end)

-- ─── TOMBOL CREATE / SAVE VALUE ──────────────────────────────
BtnCreate.MouseButton1Click:Connect(function()
	if not selectedInst or not isInstValid(selectedInst) then
		setStatus("❌ Objek tidak valid atau sudah dihapus!", C.RED)
		return
	end

	-- Debounce: cegah double-click membuat objek duplikat
	if createDebounce then return end
	createDebounce = true
	task.delay(0.5, function() createDebounce = false end)

	-- JIKA DALAM MODE EDIT VALUE
	if selectedInst.ClassName:find("Value") and not selectedInst.ClassName:find("Object") then
		local targetValue = ClassInput.Text
		local targetName = NameInput.Text

		local success, err = pcall(function()
			selectedInst.Name = targetName
			if selectedInst:IsA("IntValue") or selectedInst:IsA("NumberValue") then
				selectedInst.Value = tonumber(targetValue) or 0
			elseif selectedInst:IsA("BoolValue") then
				selectedInst.Value = (targetValue:lower() == "true" or targetValue == "1")
			else
				selectedInst.Value = targetValue
			end
		end)

		if success then
			setStatus("✅ Properti Value berhasil diperbarui!", C.GREEN)
			if ROOT_OBJS[currentRoot] then buildTree(ROOT_OBJS[currentRoot]) end
		else
			setStatus("❌ Gagal memperbarui nilai objek: " .. tostring(err), C.RED)
		end
		return
	end

	-- JIKA DALAM MODE BUAT OBJEK BARU (CREATE)
	local className = ClassInput.Text
	local objName = NameInput.Text
	local success, newObj = pcall(function()
		local obj = Instance.new(className)
		obj.Name = objName
		obj.Parent = selectedInst
		return obj
	end)

	if success and newObj then
		setStatus("✅ Sukses membuat [" .. className .. "] di dalam " .. selectedInst.Name .. "!", C.GREEN)
		if ROOT_OBJS[currentRoot] then
			buildTree(ROOT_OBJS[currentRoot])
		end
	else
		setStatus("❌ Gagal: ClassName tidak valid atau error!", C.RED)
	end
end)

-- Utility Button Events
BtnCopyPath.MouseButton1Click:Connect(function()
	if selectedPathStr ~= "" then
		local ok = copyText(selectedPathStr)
		if ok then
			setStatus("✅ Path tersalin!", C.GREEN)
		else
			setStatus("⚠️ Clipboard tidak tersedia di lingkungan ini", C.AMBER)
		end
	end
end)

BtnCopyTree.MouseButton1Click:Connect(function()
	if selectedInst and isInstValid(selectedInst) then
		task.defer(function()
			local treeText = getTreeTextString(selectedInst)
			local ok = copyText(treeText)
			if ok then
				setStatus("✅ Tree disalin!", C.GREEN)
			else
				setStatus("⚠️ Clipboard tidak tersedia di lingkungan ini", C.AMBER)
			end
		end)
	end
end)

BtnRefresh.MouseButton1Click:Connect(function()
	if ROOT_OBJS[currentRoot] then buildTree(ROOT_OBJS[currentRoot]) end
end)

buildTree(game)