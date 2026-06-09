-- ╔══════════════════════════════════════════════════════════╗
-- ║   BloxCrypt Tree Explorer v1.1 [OPTIMIZED & SECURED]     ║
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

local function getPath(inst)
    local parts = {}
    local cur = inst
    while cur and cur ~= game do
        table.insert(parts, 1, cur.Name)
        cur = cur.Parent
    end
    table.insert(parts, 1, "game")
    return table.concat(parts, ".")
end

-- Rekursi aman dengan pembatasan kedalaman (Maksimal 15 tingkat kedalaman)
local function getTreeText(inst, indent, out, depth)
    indent = indent or ""
    out    = out    or {}
    depth  = depth  or 0
    
    if depth > 15 then 
        table.insert(out, indent .. "[... Batas Kedalaman Tercapai ...]")
        return table.concat(out, "\n") 
    end
    
    local ok, ch = pcall(function() return inst:GetChildren() end)
    local marker = (ok and #ch > 0) and "▸ " or "· "
    
    -- Sanitasi nama agar tidak merusak log konsol (\n diubah jadi spasi)
    local sanitizedName = string.gsub(inst.Name, "[\n\r]", " ")
    table.insert(out, indent .. marker .. sanitizedName .. "  [" .. inst.ClassName .. "]")
    
    if ok then
        for i, c2 in ipairs(ch) do
            -- Beri nafas pada mesin jika memproses lebih dari 200 objek berturut-turut
            if i % 200 == 0 then task.wait() end
            getTreeText(c2, indent .. "    ", out, depth + 1)
        end
    end
    return table.concat(out, "\n")
end

local function copyText(text)
    local ok = pcall(function()
        if setclipboard then setclipboard(text) return end
        if Clipboard then Clipboard.set(text) return end
    end)
    
    -- Amankan cetakan ke konsol
    local cleanText = string.sub(text, 1, 5000) -- Batasi cetakan konsol maks 5000 karakter agar tidak lag
    if #text > 5000 then cleanText = cleanText .. "\n... [Teks Terlalu Panjang, Dipotong di Konsol] ..." end
    
    print("──────────── [BloxCrypt Copy] ────────────\n" .. cleanText .. "\n──────────────────────────────────────────")
    return ok
end

-- ─── Ikon Kelas ─────────────────────────────────────────────
local ICONS = {
    Workspace="🌍", Folder="📁", Model="🗂️", Part="🧱",
    MeshPart="🧱", UnionOperation="🧱", SpecialMesh="🔷",
    Script="📜", LocalScript="📜", ModuleScript="📦",
    RemoteEvent="📡", RemoteFunction="📡", BindableEvent="⚡",
    BindableFunction="⚡", StringValue="🔤", IntValue="🔢",
    NumberValue="🔢", BoolValue="✅", ObjectValue="🔗",
    Sound="🔊", SoundService="🔊", Animation="🎬",
    AnimationController="🎬", Humanoid="🧍", Tool="🔧",
    Players="👥", Player="👤", SpawnLocation="🚀",
    Lighting="💡", Sky="☁️", Atmosphere="🌫️",
    Camera="📷", Frame="⬜", TextLabel="🏷️",
    TextButton="🖱️", TextBox="✏️", ImageLabel="🖼️",
    ImageButton="🖼️", ScreenGui="🖥️", SurfaceGui="📺",
    BillboardGui="📌", SelectionBox="🔲", SelectionSphere="🔵",
    ReplicatedStorage="💾", ServerStorage="🗄️", StarterGui="🎨",
    StarterPack="🎒", StarterCharacterScripts="👤",
    StarterPlayerScripts="👤", Chat="💬", Teams="🚩",
    DataModel="🎮", ServiceProvider="⚙️",
}
local function getIcon(className)
    return ICONS[className] or "·"
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

local Win = Instance.new("Frame")
Win.Name = "Window"
Win.Size = UDim2.new(0, 500, 0, 640)
Win.Position = UDim2.new(0.5, -250, 0.5, -320)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel = 0
Win.ClipsDescendants = true
Win.Parent = Screen
round(Win, 14)
stroke(Win, C.ACCENT, 1.5)

-- Title Bar
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1, 0, 0, 52)
TBar.BackgroundColor3 = C.TITLEBAR
TBar.BorderSizePixel = 0
TBar.ZIndex = 10
TBar.Parent = Win
round(TBar, 14)

local TBarFix = Instance.new("Frame")
TBarFix.Size = UDim2.new(1, 0, 0, 14)
TBarFix.Position = UDim2.new(0, 0, 1, -14)
TBarFix.BackgroundColor3 = C.TITLEBAR
TBarFix.BorderSizePixel = 0
TBarFix.ZIndex = 10
TBarFix.Parent = TBar

local TGrad = Instance.new("UIGradient")
TGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 28, 60)),
    ColorSequenceKeypoint.new(1, C.TITLEBAR),
})
TGrad.Rotation = 90
TGrad.Parent = TBar

label(TBar, {
    text  = "🌳  BloxCrypt Tree Explorer",
    sz    = UDim2.new(1, -110, 1, 0),
    pos   = UDim2.new(0, 16, 0, 0),
    font  = Enum.Font.GothamBold,
    size  = 15,
    color = Color3.fromRGB(225, 228, 255),
    xalign= Enum.TextXAlignment.Left,
})

local CloseBtn = button(TBar, {
    text = "✕", sz = UDim2.new(0, 30, 0, 30),
    pos  = UDim2.new(1, -42, 0.5, -15),
    bg   = C.RED, size = 14, r = 8,
})
CloseBtn.ZIndex = 11
CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

local MinBtn = button(TBar, {
    text = "─", sz = UDim2.new(0, 30, 0, 30),
    pos  = UDim2.new(1, -78, 0.5, -15),
    bg   = C.AMBER, size = 14, r = 8,
})
MinBtn.ZIndex = 11
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Win.Size = minimized and UDim2.new(0, 500, 0, 52) or UDim2.new(0, 500, 0, 640)
    MinBtn.Text = minimized and "□" or "─"
end)

-- Drag System
do
    local dragging, dragStart, startPos
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = i.Position
            startPos  = Win.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- Filter Root yang aman diakses Client
local ROOT_NAMES = {"game","Workspace","ReplicatedStorage","Players","Lighting","StarterGui","StarterPack","SoundService"}
local ROOT_OBJS  = {}
for _, n in ipairs(ROOT_NAMES) do
    if n == "game" then
        ROOT_OBJS[n] = game
    else
        local ok, res = pcall(function() return game:GetService(n) end)
        if ok and res then ROOT_OBJS[n] = res end
    end
end

local SelectorBg = Instance.new("Frame")
SelectorBg.Size = UDim2.new(1, -24, 0, 36)
SelectorBg.Position = UDim2.new(0, 12, 0, 58)
SelectorBg.BackgroundColor3 = C.PANEL
SelectorBg.BorderSizePixel = 0
SelectorBg.Parent = Win
round(SelectorBg, 8)

local SelectorScroll = Instance.new("ScrollingFrame")
SelectorScroll.Size = UDim2.new(1, -12, 1, -8)
SelectorScroll.Position = UDim2.new(0, 6, 0, 4)
SelectorScroll.BackgroundTransparency = 1
SelectorScroll.ScrollBarThickness = 0
SelectorScroll.ScrollingDirection = Enum.ScrollingDirection.X
SelectorScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SelectorScroll.Parent = SelectorBg

local SL = Instance.new("UIListLayout")
SL.FillDirection = Enum.FillDirection.Horizontal
SL.SortOrder = Enum.SortOrder.LayoutOrder
SL.Padding = UDim.new(0, 5)
SL.VerticalAlignment = Enum.VerticalAlignment.Center
SL.Parent = SelectorScroll

SL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SelectorScroll.CanvasSize = UDim2.new(0, SL.AbsoluteContentSize.X + 10, 0, 0)
end)

local currentRoot = "game"
local rootBtns = {}
local buildTree

local function selectRoot(name)
    currentRoot = name
    for n, b in pairs(rootBtns) do
        if n == name then
            b.BackgroundColor3 = C.ACCENT
            b.TextColor3 = Color3.new(1,1,1)
        else
            b.BackgroundColor3 = C.HOVER
            b.TextColor3 = C.SUBTEXT
        end
    end
    if ROOT_OBJS[name] then
        buildTree(ROOT_OBJS[name])
    end
end

-- Menghitung ukuran tombol root secara akurat menggunakan TextService
for i, name in ipairs(ROOT_NAMES) do
    if ROOT_OBJS[name] then
        local font = Enum.Font.Gotham
        local size = 12
        local neededSize = TextService:GetTextSize(name, size, font, Vector2.new(1000, 22))
        
        local b = Instance.new("TextButton")
        b.Text = name
        b.Size = UDim2.new(0, math.max(54, neededSize.X + 20), 0, 22)
        b.BackgroundColor3 = (i==1) and C.ACCENT or C.HOVER
        b.TextColor3 = (i==1) and Color3.new(1,1,1) or C.SUBTEXT
        b.Font = font
        b.TextSize = size
        b.BorderSizePixel = 0
        b.LayoutOrder = i
        b.Parent = SelectorScroll
        round(b, 6)
        rootBtns[name] = b
        b.MouseButton1Click:Connect(function() selectRoot(name) end)
    end
end

local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -24, 0, 24)
StatusBar.Position = UDim2.new(0, 12, 0, 100)
StatusBar.BackgroundTransparency = 1
StatusBar.Parent = Win

local StatusLbl = label(StatusBar, {
    text   = "Pilih root di atas, lalu klik ▶ untuk expand • Klik nama untuk select",
    sz     = UDim2.new(1, 0, 1, 0),
    color  = C.SUBTEXT,
    size   = 11,
    xalign = Enum.TextXAlignment.Left,
    truncate = Enum.TextTruncate.AtEnd,
})

local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, -24, 0, 1)
Sep.Position = UDim2.new(0, 12, 0, 126)
Sep.BackgroundColor3 = Color3.fromRGB(35, 40, 65)
Sep.BorderSizePixel = 0
Sep.Parent = Win

local TreeScroll = Instance.new("ScrollingFrame")
TreeScroll.Name = "TreeScroll"
TreeScroll.Size = UDim2.new(1, -24, 1, -248)
TreeScroll.Position = UDim2.new(0, 12, 0, 132)
TreeScroll.BackgroundColor3 = C.PANEL
TreeScroll.BorderSizePixel = 0
TreeScroll.ScrollBarThickness = 5
TreeScroll.ScrollBarImageColor3 = C.ACCENT
TreeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TreeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TreeScroll.Parent = Win
round(TreeScroll, 10)

local TreeLayout = Instance.new("UIListLayout")
TreeLayout.SortOrder = Enum.SortOrder.LayoutOrder
TreeLayout.Parent = TreeScroll

local TreePadding = Instance.new("UIPadding")
TreePadding.PaddingTop = UDim.new(0, 4)
TreePadding.PaddingBottom = UDim.new(0, 4)
TreePadding.Parent = TreeScroll

local EmptyLbl = label(TreeScroll, {
    text   = "🌳  Pilih root di atas untuk mulai",
    sz     = UDim2.new(1, 0, 0, 40),
    pos    = UDim2.new(0, 0, 0, 60),
    color  = C.SUBTEXT,
    size   = 13,
    xalign = Enum.TextXAlignment.Center,
})
EmptyLbl.LayoutOrder = 9999

-- Bottom Panel
local BottomPanel = Instance.new("Frame")
BottomPanel.Size = UDim2.new(1, -24, 0, 108)
BottomPanel.Position = UDim2.new(0, 12, 1, -120)
BottomPanel.BackgroundColor3 = C.PANEL
BottomPanel.BorderSizePixel = 0
BottomPanel.Parent = Win
round(BottomPanel, 10)

local BP = Instance.new("UIPadding")
BP.PaddingLeft = UDim.new(0, 10)
BP.PaddingRight = UDim.new(0, 10)
BP.PaddingTop = UDim.new(0, 10)
BP.PaddingBottom = UDim.new(0, 10)
BP.Parent = BottomPanel

local PathBox = Instance.new("Frame")
PathBox.Size = UDim2.new(1, 0, 0, 30)
PathBox.BackgroundColor3 = C.BG
PathBox.BorderSizePixel = 0
PathBox.Parent = BottomPanel
round(PathBox, 6)
stroke(PathBox, Color3.fromRGB(40, 46, 75), 1)

label(PathBox, {
    text = "📍", sz = UDim2.new(0, 24, 1, 0),
    pos = UDim2.new(0, 4, 0, 0), size = 14,
    xalign = Enum.TextXAlignment.Center,
})

local PathLbl = label(PathBox, {
    text     = "Belum ada yang dipilih…",
    sz       = UDim2.new(1, -30, 1, 0),
    pos      = UDim2.new(0, 28, 0, 0),
    color    = C.SUBTEXT, size = 12,
    truncate = Enum.TextTruncate.AtEnd,
    xalign   = Enum.TextXAlignment.Left,
})

local InfoLbl = label(BottomPanel, {
    text   = "─",
    sz     = UDim2.new(1, 0, 0, 18),
    pos    = UDim2.new(0, 0, 0, 36),
    color  = C.SUBTEXT, size = 11,
    xalign = Enum.TextXAlignment.Left,
})

local BtnRow = Instance.new("Frame")
BtnRow.Size = UDim2.new(1, 0, 0, 34)
BtnRow.Position = UDim2.new(0, 0, 0, 58)
BtnRow.BackgroundTransparency = 1
BtnRow.Parent = BottomPanel

local BL = Instance.new("UIListLayout")
BL.FillDirection = Enum.FillDirection.Horizontal
BL.Padding = UDim.new(0, 8)
BL.SortOrder = Enum.SortOrder.LayoutOrder
BL.Parent = BtnRow

local function makeBtn(text, bg, ord)
    local b = Instance.new("TextButton")
    b.Text = text
    b.Size = UDim2.new(0.33, -6, 1, 0)
    b.BackgroundColor3 = bg
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.LayoutOrder = ord
    b.AutoButtonColor = false
    b.Parent = BtnRow
    round(b, 8)
    b.MouseEnter:Connect(function()
        b.BackgroundColor3 = Color3.new(
            math.min(bg.R+0.1,1), math.min(bg.G+0.1,1), math.min(bg.B+0.1,1))
    end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = bg end)
    return b
end

local BtnCopyPath  = makeBtn("📋  Copy Path",  C.ACCENT, 1)
local BtnCopyTree  = makeBtn("🌳  Copy Tree",  C.GREEN,  2)
local BtnRefresh   = makeBtn("🔄  Refresh",    C.AMBER,  3)

-- ═══════════════════════════════════════════════════════════
--   TREE LOGIC (OPTIMIZED)
-- ═══════════════════════════════════════════════════════════
local selectedInst = nil
local selectedPathStr = ""
local nodeCounter = 0

local function deselectAll(container)
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("TextButton") and child.Name == "RowBtn" then
            child.BackgroundTransparency = 1
            child.TextColor3 = C.TEXT
        end
    end
end

local function createNode(inst, depth)
    nodeCounter += 1
    local order = nodeCounter

    local ok, children = pcall(function() return inst:GetChildren() end)
    local hasChildren = ok and #children > 0
    local childCount  = ok and #children or 0

    local Wrap = Instance.new("Frame")
    Wrap.Name = "Wrap_" .. inst.Name
    Wrap.AutomaticSize = Enum.AutomaticSize.Y
    Wrap.Size = UDim2.new(1, 0, 0, 0)
    Wrap.BackgroundTransparency = 1
    Wrap.LayoutOrder = order

    local WL = Instance.new("UIListLayout")
    WL.SortOrder = Enum.SortOrder.LayoutOrder
    WL.Parent = Wrap

    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, C.ROW_HEIGHT)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = 1
    Row.Parent = Wrap

    if depth > 0 then
        local guide = Instance.new("Frame")
        guide.Size = UDim2.new(0, 1, 1, 0)
        guide.Position = UDim2.new(0, depth * 14 + 6, 0, 0)
        guide.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
        guide.BorderSizePixel = 0
        guide.Parent = Row
    end

    local ExpBtn = Instance.new("TextButton")
    ExpBtn.Size = UDim2.new(0, 16, 0, 16)
    ExpBtn.Position = UDim2.new(0, depth * 14 + 6, 0.5, -8)
    ExpBtn.BackgroundTransparency = 1
    ExpBtn.Text = hasChildren and "▶" or ""
    ExpBtn.TextColor3 = C.ACCENT
    ExpBtn.Font = Enum.Font.GothamBold
    ExpBtn.TextSize = 9
    ExpBtn.BorderSizePixel = 0
    ExpBtn.Parent = Row

    local RowBtn = Instance.new("TextButton")
    RowBtn.Name = "RowBtn"
    RowBtn.Size = UDim2.new(1, -(depth * 14 + 26), 1, 0)
    RowBtn.Position = UDim2.new(0, depth * 14 + 24, 0, 0)
    RowBtn.BackgroundTransparency = 1
    RowBtn.Text = getIcon(inst.ClassName) .. "  " .. inst.Name .. "   ·  " .. inst.ClassName
    RowBtn.TextColor3 = C.TEXT
    RowBtn.Font = Enum.Font.Gotham
    RowBtn.TextSize = 13
    RowBtn.TextXAlignment = Enum.TextXAlignment.Left
    RowBtn.BorderSizePixel = 0
    RowBtn.AutoButtonColor = false
    RowBtn.Parent = Row

    local ChildWrap = Instance.new("Frame")
    ChildWrap.AutomaticSize = Enum.AutomaticSize.Y
    ChildWrap.Size = UDim2.new(1, 0, 0, 0)
    ChildWrap.BackgroundTransparency = 1
    ChildWrap.Visible = false
    ChildWrap.LayoutOrder = 2
    ChildWrap.Parent = Wrap

    local CWL = Instance.new("UIListLayout")
    CWL.SortOrder = Enum.SortOrder.LayoutOrder
    CWL.Parent = ChildWrap

    local expanded     = false
    local childBuilt   = false

    RowBtn.MouseButton1Click:Connect(function()
        deselectAll(TreeScroll)
        selectedInst    = inst
        selectedPathStr = getPath(inst)

        RowBtn.BackgroundTransparency = 0
        RowBtn.BackgroundColor3 = C.SEL
        RowBtn.TextColor3 = C.SEL_TEXT

        PathLbl.Text  = selectedPathStr
        PathLbl.TextColor3 = C.SEL_TEXT

        local ok2, ch2 = pcall(function() return inst:GetChildren() end)
        local n = ok2 and #ch2 or 0
        InfoLbl.Text = "📌 " .. inst.Name .. "  ·  " .. inst.ClassName .. "  ·  " .. n .. " children"
        StatusLbl.Text = "Selected: " .. inst.Name
    end)

    RowBtn.MouseEnter:Connect(function()
        if inst ~= selectedInst then
            RowBtn.BackgroundTransparency = 0
            RowBtn.BackgroundColor3 = C.HOVER
        end
    end)
    RowBtn.MouseLeave:Connect(function()
        if inst ~= selectedInst then
            RowBtn.BackgroundTransparency = 1
        end
    end)

    local function toggleExpand()
        if not hasChildren then return end
        expanded = not expanded
        ExpBtn.Text = expanded and "▼" or "▶"

        if expanded and not childBuilt then
            childBuilt = true
            StatusLbl.Text = "⏳ Loading children..."
            
            task.defer(function()
                local ok3, ch3 = pcall(function() return inst:GetChildren() end)
                if ok3 then
                    for idx, child in ipairs(ch3) do
                        -- Fitur Anti-Lag: beri jeda tipis setiap 40 objek agar game tidak beku
                        if idx % 40 == 0 then task.wait() end 
                        if not expanded then break end -- batalkan jika keburu di-collapse pengguna
                        
                        local childNode = createNode(child, depth + 1)
                        childNode.Parent = ChildWrap
                    end
                end
                StatusLbl.Text = "Expanded: " .. inst.Name .. " (" .. childCount .. " children)"
            end)
        end
        ChildWrap.Visible = expanded
    end

    ExpBtn.MouseButton1Click:Connect(toggleExpand)
    RowBtn.MouseButton2Click:Connect(toggleExpand)

    return Wrap
end

-- Membangun ulang Root pohon objek secara bertahap (Anti-Lag)
buildTree = function(rootInst)
    for _, c in ipairs(TreeScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    
    nodeCounter = 0
    selectedInst = nil
    selectedPathStr = ""
    PathLbl.Text = "Belum ada yang dipilih…"
    PathLbl.TextColor3 = C.SUBTEXT
    InfoLbl.Text = "─"
    StatusLbl.Text = "⏳ Sedang memuat objek root..."

    local ok, children = pcall(function() return rootInst:GetChildren() end)
    if not ok or #children == 0 then
        EmptyLbl.Text = "⚠  Root ini kosong atau tidak dapat diakses client"
        EmptyLbl.Parent = TreeScroll
        StatusLbl.Text = "Gagal memuat root."
        return
    end

    -- Muat bertahap agar tidak memicu micro-stuttering
    task.defer(function()
        for idx, child in ipairs(children) do
            if idx % 50 == 0 then task.wait() end
            local node = createNode(child, 0)
            node.Parent = TreeScroll
        end
        StatusLbl.Text = "✅ Berhasil memuat " .. #children .. " item di root. Klik ▶ untuk membuka."
    end)
end

-- ─── Button Actions ──────────────────────────────────────────
BtnCopyPath.MouseButton1Click:Connect(function()
    if not selectedInst then
        StatusLbl.Text = "⚠  Pilih item terlebih dahulu!"
        return
    end
    local copied = copyText(selectedPathStr)
    BtnCopyPath.Text = "✅  Tersalin!"
    BtnCopyPath.BackgroundColor3 = C.GREEN
    task.delay(2, function()
        BtnCopyPath.Text = "📋  Copy Path"
        BtnCopyPath.BackgroundColor3 = C.ACCENT
    end)
    StatusLbl.Text = (copied and "✅" or "📋  Output") .. " Path berhasil disalin."
end)

BtnCopyTree.MouseButton1Click:Connect(function()
    if not selectedInst then
        StatusLbl.Text = "⚠  Pilih item terlebih dahulu!"
        return
    end
    StatusLbl.Text = "⏳ Memproses penyusunan teks Tree (Mohon tunggu)..."
    task.defer(function()
        local treeText = getTreeText(selectedInst)
        local copied = copyText(treeText)
        BtnCopyTree.Text = "✅  Tersalin!"
        task.delay(2, function() BtnCopyTree.Text = "🌳  Copy Tree" end)
        local lineCount = select(2, treeText:gsub("\n", "")) + 1
        StatusLbl.Text = (copied and "✅" or "📋  Output") .. " Berhasil menyalin " .. lineCount .. " baris tree."
    end)
end)

BtnRefresh.MouseButton1Click:Connect(function()
    if ROOT_OBJS[currentRoot] then
        buildTree(ROOT_OBJS[currentRoot])
        BtnRefresh.Text = "✅ Done!"
        task.delay(1.5, function() BtnRefresh.Text = "🔄 Refresh" end)
    end
end)

-- ─── Initial Load ────────────────────────────────────────────
buildTree(game)

print([[
╔═══════════════════════════════════════════╗
║   BloxCrypt Tree Explorer v1.1 — AMAN ✅  ║
║                                           ║
║  🌳 GUI diaktifkan dengan lancar         ║
║  🚀 Proteksi Lag & Batas Crash aktif      ║
║  📋 Klik item → Copy Path / Copy Tree     ║
╚═══════════════════════════════════════════╝
]])