--// Virellexlibrary.lua | Virellex Hub UI Library | Virellex Studio

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// Constants
local GUI_NAME = "VirellexHubLibrary"
local ICON_ID = "rbxassetid://92658862860549"
local TOGGLE_SIZE = 32
local DRAG_THRESHOLD = 5

local MouseButton1 = Enum.UserInputType.MouseButton1
local MouseMovement = Enum.UserInputType.MouseMovement
local Touch = Enum.UserInputType.Touch

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

--// Theme (premium dark grey, black & white contrast)
local Theme = {
    Background = Color3.fromRGB(30, 30, 34),
    Section = Color3.fromRGB(36, 36, 41),
    Element = Color3.fromRGB(46, 46, 52),
    ElementHover = Color3.fromRGB(58, 58, 66),
    Stroke = Color3.fromRGB(78, 78, 88),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(165, 165, 175),
    Accent = Color3.fromRGB(255, 255, 255),
    AccentDark = Color3.fromRGB(24, 24, 28),
    Off = Color3.fromRGB(80, 80, 90),
}

--// Helpers
local function create(class, props)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props) do
        if k == "Parent" then
            parent = v
        else
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function stroke(parent, color, thickness)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function textLabel(props)
    local p = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = "",
    }
    for k, v in pairs(props) do
        p[k] = v
    end
    return create("TextLabel", p)
end

local function textButton(props)
    local p = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = FONT,
        TextSize = 12,
        TextColor3 = Theme.Text,
        Text = "",
    }
    for k, v in pairs(props) do
        p[k] = v
    end
    return create("TextButton", p)
end

local QUAD_OUT = Enum.EasingStyle.Quad
local function tween(inst, time, props, style)
    local t = TweenService:Create(inst, TweenInfo.new(time, style or QUAD_OUT, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function safeCall(cb, ...)
    if type(cb) ~= "function" then
        return
    end
    local ok, err = pcall(cb, ...)
    if not ok then
        warn("[Virellex] Callback error: " .. tostring(err))
    end
end

local function hover(btn, target, normal, over)
    btn.MouseEnter:Connect(function()
        tween(target, 0.12, { BackgroundColor3 = over })
    end)
    btn.MouseLeave:Connect(function()
        tween(target, 0.12, { BackgroundColor3 = normal })
    end)
end

local function canUseCoreGui()
    return (pcall(function()
        local probe = Instance.new("Folder")
        probe.Parent = CoreGui
        probe:Destroy()
    end))
end

local function resolveParent()
    local ok, result = pcall(function()
        return gethui and gethui()
    end)
    if ok and result then
        return result
    end
    if canUseCoreGui() then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function removeOld(parent)
    local containers = { parent, CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }
    for _, container in ipairs(containers) do
        local ok, old = pcall(container.FindFirstChild, container, GUI_NAME)
        if ok and old then
            pcall(old.Destroy, old)
        end
    end
end

--// Classes
local Library = {}
Library.__index = Library
Library.Theme = Theme

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

--------------------------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------------------------
function Library:Notify(cfg)
    local holder = self._notifyHolder
    if not holder or not holder.Parent then
        return
    end
    cfg = cfg or {}
    local duration = cfg.Duration or 4

    self._notifyOrder = (self._notifyOrder or 0) + 1

    local wrapper = create("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        LayoutOrder = self._notifyOrder,
        Parent = holder,
    })
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 1, -6),
        Position = UDim2.new(1, 10, 0, 0),
        BackgroundColor3 = Theme.Section,
        BorderSizePixel = 0,
        Parent = wrapper,
    })
    corner(card, 8)
    stroke(card, Theme.Stroke, 1)

    textLabel({
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 16),
        Font = FONT_BOLD,
        Text = tostring(cfg.Title or "Virellex Hub"),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card,
    })
    textLabel({
        Position = UDim2.new(0, 10, 0, 22),
        Size = UDim2.new(1, -20, 0, 26),
        TextSize = 11,
        TextColor3 = Theme.SubText,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(cfg.Content or ""),
        Parent = card,
    })
    local bar = create("Frame", {
        Position = UDim2.new(0, 8, 1, -4),
        Size = UDim2.new(1, -16, 0, 2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(bar, 1)

    tween(card, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
    TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

    task.delay(duration, function()
        if not wrapper.Parent then
            return
        end
        tween(card, 0.22, { Position = UDim2.new(1, 10, 0, 0) })
        task.delay(0.25, function()
            if wrapper.Parent then
                wrapper:Destroy()
            end
        end)
    end)
end

--------------------------------------------------------------------
-- WINDOW
--------------------------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    local title = tostring(config.Title or "Virellex Hub")
    local subtitle = tostring(config.Subtitle or "No Glow")
    local credit = tostring(config.Credit or "Virellex Studio")
    local icon = config.Icon or ICON_ID
    local toggleKey = config.ToggleKey
    if toggleKey == nil then
        toggleKey = Enum.KeyCode.RightShift
    end

    local parent = resolveParent()
    removeOld(parent)

    --// Compact, balanced dimensions for mobile + PC
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local camera = workspace.CurrentCamera
    local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
    local winW = isMobile and 430 or 500
    local winH = isMobile and 270 or 320
    if typeof(config.Size) == "UDim2" then
        winW, winH = config.Size.X.Offset, config.Size.Y.Offset
    end
    winW = math.max(math.min(winW, vp.X - 24), 300)
    winH = math.max(math.min(winH, vp.Y - 24), 200)
    local sidebarW = isMobile and 108 or 124
    local headerH = 46

    local self = setmetatable({}, Window)
    self._connections = {}
    self._tabs = {}
    self._visible = true
    self._token = 0

    local function track(conn)
        self._connections[#self._connections + 1] = conn
        return conn
    end
    self._track = track

    --// ScreenGui
    local gui = create("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
    self._gui = gui

    --// Main frame
    local main = create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(winW, winH),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = gui,
    })
    corner(main, 8)
    stroke(main, Theme.Stroke, 1.5)
    local mainScale = create("UIScale", { Scale = 1, Parent = main })
    self._main = main

    --// Header
    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, headerH),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = main,
    })
    local headerIcon = create("ImageLabel", {
        Position = UDim2.new(0, 12, 0, 10),
        Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1,
        Image = icon,
        ScaleType = Enum.ScaleType.Fit,
        Parent = header,
    })
    textLabel({
        Position = UDim2.new(0, 46, 0, 6),
        Size = UDim2.new(1, -130, 0, 18),
        Font = FONT_BOLD,
        TextSize = 14,
        Text = title,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = header,
    })
    local subtitleLabel = textLabel({
        Position = UDim2.new(0, 46, 0, 24),
        Size = UDim2.new(1, -130, 0, 14),
        TextSize = 11,
        TextColor3 = Theme.SubText,
        Text = subtitle,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = header,
    })
    self._subtitleLabel = subtitleLabel

    create("Frame", {
        Position = UDim2.new(0, 0, 0, headerH),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = main,
    })

    --// Window controls: minimize ("-") and close ("X")
    local minimizeBtn = textButton({
        Name = "Minimize",
        Position = UDim2.new(1, -68, 0, 9),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Element,
        Font = FONT_BOLD,
        TextSize = 16,
        Text = "-",
        Parent = header,
    })
    corner(minimizeBtn, 6)
    stroke(minimizeBtn, Theme.Stroke, 1)
    hover(minimizeBtn, minimizeBtn, Theme.Element, Theme.ElementHover)
    minimizeBtn.Activated:Connect(function()
        self:SetVisible(false)
    end)

    local closeBtn = textButton({
        Name = "Close",
        Position = UDim2.new(1, -36, 0, 9),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Element,
        Font = FONT_BOLD,
        TextSize = 13,
        Text = "X",
        Parent = header,
    })
    corner(closeBtn, 6)
    stroke(closeBtn, Theme.Stroke, 1)
    hover(closeBtn, closeBtn, Theme.Element, Theme.ElementHover)
    closeBtn.Activated:Connect(function()
        self:Destroy()
    end)

    --// Window dragging (mouse + touch), listeners exist only while dragging
    local dragArea = create("Frame", {
        Size = UDim2.new(1, -76, 1, 0),
        BackgroundTransparency = 1,
        Active = true,
        Parent = header,
    })
    local offX, offY = 0, 0
    local winDragging, winInput, winMove, winEnd = false, nil, nil, nil
    local function stopWinDrag()
        if winMove then
            winMove:Disconnect()
            winMove = nil
        end
        if winEnd then
            winEnd:Disconnect()
            winEnd = nil
        end
        winDragging = false
        winInput = nil
    end
    dragArea.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if winDragging or (t ~= MouseButton1 and t ~= Touch) then
            return
        end
        winDragging = true
        winInput = input
        local startX, startY = input.Position.X, input.Position.Y
        local baseX, baseY = offX, offY

        winMove = UserInputService.InputChanged:Connect(function(changed)
            local ct = changed.UserInputType
            if ct ~= MouseMovement and not (ct == Touch and changed == winInput) then
                return
            end
            local abs = gui.AbsoluteSize
            local limitX = math.max(abs.X / 2 + winW / 2 - 60, 0)
            local limitY = math.max(abs.Y / 2 + winH / 2 - 60, 0)
            offX = math.clamp(baseX + (changed.Position.X - startX), -limitX, limitX)
            offY = math.clamp(baseY + (changed.Position.Y - startY), -limitY, limitY)
            main.Position = UDim2.new(0.5, offX, 0.5, offY)
        end)
        winEnd = UserInputService.InputEnded:Connect(function(ended)
            if ended == winInput or (ended.UserInputType == MouseButton1 and winInput and winInput.UserInputType == MouseButton1) then
                stopWinDrag()
            end
        end)
    end)

    --// Sidebar
    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.new(0, 0, 0, headerH + 1),
        Size = UDim2.new(0, sidebarW, 1, -(headerH + 1)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = main,
    })
    create("Frame", {
        Position = UDim2.new(0, sidebarW, 0, headerH + 1),
        Size = UDim2.new(0, 1, 1, -(headerH + 1)),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = main,
    })

    local tabList = create("ScrollingFrame", {
        Name = "Tabs",
        Size = UDim2.new(1, 0, 1, -54),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = sidebar,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabList,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = tabList,
    })
    self._tabList = tabList

    --// Player card:   [Avatar]  Nickname
    --//                          @Username
    local card = create("Frame", {
        Name = "PlayerCard",
        Position = UDim2.new(0, 0, 1, -52),
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })
    create("Frame", {
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = card,
    })
    local avatar = create("ImageLabel", {
        Position = UDim2.new(0, 10, 0, 10),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Image = "",
        Parent = card,
    })
    corner(avatar, 16)
    stroke(avatar, Theme.Stroke, 1)

    local info = create("Frame", {
        Position = UDim2.new(0, 50, 0, 10),
        Size = UDim2.new(1, -56, 0, 32),
        BackgroundTransparency = 1,
        Parent = card,
    })
    textLabel({
        Position = UDim2.new(0, 0, 0, 1),
        Size = UDim2.new(1, 0, 0, 15),
        Font = FONT_BOLD,
        Text = LocalPlayer.DisplayName,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = info,
    })
    textLabel({
        Position = UDim2.new(0, 0, 0, 17),
        Size = UDim2.new(1, 0, 0, 14),
        TextSize = 11,
        TextColor3 = Theme.SubText,
        Text = "@" .. LocalPlayer.Name,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = info,
    })
    task.spawn(function()
        local ok, img = pcall(
            Players.GetUserThumbnailAsync,
            Players,
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
        if ok and avatar.Parent then
            avatar.Image = img
        end
    end)

    --// Content area
    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, sidebarW + 1, 0, headerH + 1),
        Size = UDim2.new(1, -(sidebarW + 1), 1, -(headerH + 1)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = main,
    })
    self._content = content

    --// Bottom-right watermark
    textLabel({
        Name = "Credit",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -10, 1, -3),
        Size = UDim2.fromOffset(120, 14),
        TextSize = 10,
        TextColor3 = Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = credit,
        ZIndex = 5,
        Parent = main,
    })

    --// Notification holder
    local holder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 48),
        Size = UDim2.new(0, 240, 1, -60),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder,
    })
    Library._notifyHolder = holder
    Library._notifyOrder = 0

    --// Preload icon (deferred, never blocks)
    task.defer(function()
        pcall(ContentProvider.PreloadAsync, ContentProvider, { headerIcon })
    end)

    ----------------------------------------------------------------
    -- Integrated mini circular floating toggle (32x32)
    ----------------------------------------------------------------
    local button = create("ImageButton", {
        Name = "Toggle",
        Size = UDim2.fromOffset(TOGGLE_SIZE, TOGGLE_SIZE),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Image = icon,
        ScaleType = Enum.ScaleType.Crop,
        ImageTransparency = 0,
        Active = true,
    })
    button.Position = UDim2.fromOffset(20, math.floor(vp.Y / 2 - TOGGLE_SIZE / 2))
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = button
    local btnScale = Instance.new("UIScale")
    btnScale.Scale = 1
    btnScale.Parent = button
    button.Parent = gui

    task.defer(function()
        pcall(ContentProvider.PreloadAsync, ContentProvider, { button })
    end)

    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local pressTween = TweenService:Create(btnScale, tweenInfo, { Scale = 0.9 })
    local releaseTween = TweenService:Create(btnScale, tweenInfo, { Scale = 1 })

    local function clampButton(x, y)
        local abs = gui.AbsoluteSize
        local maxX = math.max(abs.X - TOGGLE_SIZE, 0)
        local maxY = math.max(abs.Y - TOGGLE_SIZE, 0)
        return UDim2.fromOffset(math.clamp(x, 0, maxX), math.clamp(y, 0, maxY))
    end

    local dragging, moved, activeInput = false, false, nil
    local startX, startY, originX, originY = 0, 0, 0, 0
    local moveConn, endConn

    local function stopDrag()
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end
        if endConn then
            endConn:Disconnect()
            endConn = nil
        end
        dragging = false
        activeInput = nil
    end

    track(button.InputBegan:Connect(function(input)
        if dragging then
            return
        end
        local t = input.UserInputType
        if t ~= MouseButton1 and t ~= Touch then
            return
        end

        dragging = true
        moved = false
        activeInput = input

        local pos = input.Position
        startX, startY = pos.X, pos.Y
        local bp = button.Position
        originX, originY = bp.X.Offset, bp.Y.Offset

        pressTween:Play()

        moveConn = UserInputService.InputChanged:Connect(function(changed)
            local ct = changed.UserInputType
            if ct ~= MouseMovement and not (ct == Touch and changed == activeInput) then
                return
            end
            local p = changed.Position
            local dx, dy = p.X - startX, p.Y - startY
            if not moved then
                if dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD then
                    return
                end
                moved = true
            end
            button.Position = clampButton(originX + dx, originY + dy)
        end)

        endConn = UserInputService.InputEnded:Connect(function(ended)
            local et = ended.UserInputType
            if et ~= MouseButton1 and not (et == Touch and ended == activeInput) then
                return
            end
            local wasMoved = moved
            stopDrag()
            releaseTween:Play()
            if not wasMoved then
                self:Toggle()
            end
        end)
    end))

    track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local bp = button.Position
        button.Position = clampButton(bp.X.Offset, bp.Y.Offset)
    end))

    --// Keyboard toggle (PC)
    if toggleKey then
        track(UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == toggleKey then
                self:Toggle()
            end
        end))
    end

    --// Full cleanup on destroy
    gui.Destroying:Connect(function()
        stopDrag()
        stopWinDrag()
        pressTween:Cancel()
        releaseTween:Cancel()
        for i = 1, #self._connections do
            self._connections[i]:Disconnect()
        end
        table.clear(self._connections)
        if Library._notifyHolder == holder then
            Library._notifyHolder = nil
        end
    end)

    self._mainScale = mainScale
    gui.Parent = parent
    return self
end

function Window:SetVisible(state)
    state = state and true or false
    if self._visible == state then
        return
    end
    self._visible = state
    self._token += 1
    local mine = self._token
    local main, scale = self._main, self._mainScale

    if state then
        scale.Scale = 0.92
        main.Visible = true
        tween(scale, 0.15, { Scale = 1 })
    else
        tween(scale, 0.12, { Scale = 0.92 })
        task.delay(0.13, function()
            if self._token == mine and not self._visible and main.Parent then
                main.Visible = false
            end
        end)
    end
end

function Window:Toggle()
    self:SetVisible(not self._visible)
end

function Window:IsVisible()
    return self._visible
end

function Window:SetSubtitle(text)
    self._subtitleLabel.Text = tostring(text)
end

function Window:Notify(cfg)
    Library:Notify(cfg)
end

function Window:Destroy()
    if self._gui and self._gui.Parent then
        self._gui:Destroy()
    end
end

function Window:SelectTab(tab)
    if self._activeTab == tab then
        return
    end
    if self._activeTab then
        self._activeTab:_setActive(false)
    end
    self._activeTab = tab
    tab:_setActive(true)
end

--------------------------------------------------------------------
-- TABS
--------------------------------------------------------------------
function Window:CreateTab(name, icon)
    name = tostring(name or "Tab")
    local tab = setmetatable({}, Tab)
    tab._window = self
    tab._order = 0
    self._tabs[#self._tabs + 1] = tab

    local button = textButton({
        Name = name,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        BackgroundColor3 = Theme.Element,
        LayoutOrder = #self._tabs,
        Parent = self._tabList,
    })
    corner(button, 6)

    local indicator = create("Frame", {
        Position = UDim2.new(0, 0, 0.5, -7),
        Size = UDim2.fromOffset(3, 14),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = button,
    })
    corner(indicator, 2)

    local textX = 10
    local iconLabel
    if icon then
        iconLabel = create("ImageLabel", {
            Position = UDim2.new(0, 10, 0.5, -8),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = Theme.SubText,
            Parent = button,
        })
        textX = 32
    end
    local label = textLabel({
        Position = UDim2.new(0, textX, 0, 0),
        Size = UDim2.new(1, -textX - 4, 1, 0),
        Text = name,
        TextColor3 = Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = button,
    })

    local page = create("ScrollingFrame", {
        Name = name,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, -20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Stroke,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = self._content,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 10),
        Parent = page,
    })

    tab._button, tab._label, tab._icon, tab._indicator, tab._page = button, label, iconLabel, indicator, page

    button.Activated:Connect(function()
        self:SelectTab(tab)
    end)

    if #self._tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function Tab:_setActive(on)
    self._page.Visible = on
    tween(self._button, 0.15, { BackgroundTransparency = on and 0 or 1 })
    tween(self._indicator, 0.15, { BackgroundTransparency = on and 0 or 1 })
    tween(self._label, 0.15, { TextColor3 = on and Theme.Text or Theme.SubText })
    if self._icon then
        tween(self._icon, 0.15, { ImageColor3 = on and Theme.Text or Theme.SubText })
    end
end

--------------------------------------------------------------------
-- SECTIONS
--------------------------------------------------------------------
function Tab:CreateSection(name)
    self._order += 1
    local section = setmetatable({}, Section)
    section._window = self._window
    section._page = self._page
    section._order = 0

    local frame = create("Frame", {
        Name = tostring(name or "Section"),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Section,
        BorderSizePixel = 0,
        LayoutOrder = self._order,
        Parent = self._page,
    })
    corner(frame, 8)
    stroke(frame, Theme.Stroke, 1)
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = frame,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = frame,
    })
    textLabel({
        Size = UDim2.new(1, 0, 0, 16),
        Font = FONT_BOLD,
        Text = tostring(name or "Section"),
        LayoutOrder = 0,
        Parent = frame,
    })
    section._holder = frame
    return section
end

local function newRow(section, height)
    section._order += 1
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        LayoutOrder = section._order,
        Parent = section._holder,
    })
    corner(row, 6)
    stroke(row, Theme.Stroke, 1)
    return row
end

--// Label
function Section:CreateLabel(text)
    self._order += 1
    local lbl = textLabel({
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextColor3 = Theme.SubText,
        TextWrapped = true,
        Text = tostring(text or ""),
        LayoutOrder = self._order,
        Parent = self._holder,
    })
    local obj = {}
    function obj:Set(t)
        lbl.Text = tostring(t)
    end
    return obj
end

--// Button
function Section:CreateButton(cfg)
    cfg = cfg or {}
    self._order += 1
    local btn = textButton({
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Element,
        Text = tostring(cfg.Name or "Button"),
        LayoutOrder = self._order,
        Parent = self._holder,
    })
    corner(btn, 6)
    stroke(btn, Theme.Stroke, 1)
    hover(btn, btn, Theme.Element, Theme.ElementHover)
    btn.Activated:Connect(function()
        btn.BackgroundColor3 = Theme.Accent
        btn.TextColor3 = Theme.AccentDark
        tween(btn, 0.2, { BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text })
        safeCall(cfg.Callback)
    end)
    return btn
end

--// Toggle
function Section:CreateToggle(cfg)
    cfg = cfg or {}
    local state = cfg.Default == true
    local callback = cfg.Callback

    local row = newRow(self, 32)
    textLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -62, 1, 0),
        Text = tostring(cfg.Name or "Toggle"),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    local track = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(36, 18),
        BackgroundColor3 = state and Theme.Accent or Theme.Off,
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(track, 9)
    local knob = create("Frame", {
        Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = state and Theme.AccentDark or Theme.Text,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(knob, 6)
    local hit = textButton({ Size = UDim2.new(1, 0, 1, 0), Parent = row })

    local obj = {}
    local function render()
        tween(track, 0.15, { BackgroundColor3 = state and Theme.Accent or Theme.Off })
        tween(knob, 0.15, {
            Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = state and Theme.AccentDark or Theme.Text,
        })
    end
    function obj:Set(v, silent)
        v = v == true
        if v == state then
            return
        end
        state = v
        render()
        if not silent then
            safeCall(callback, state)
        end
    end
    function obj:Get()
        return state
    end
    hit.Activated:Connect(function()
        obj:Set(not state)
    end)
    if callback then
        task.defer(safeCall, callback, state)
    end
    return obj
end

--// Slider
function Section:CreateSlider(cfg)
    cfg = cfg or {}
    local min, max = cfg.Min or 0, cfg.Max or 100
    local inc = cfg.Increment or 1
    local suffix = cfg.Suffix or ""
    local callback = cfg.Callback

    local decimals = 0
    local incStr = tostring(inc)
    local dot = incStr:find("%.")
    if dot then
        decimals = #incStr - dot
    end
    local function snap(v)
        v = math.clamp(v, min, max)
        v = math.floor((v - min) / inc + 0.5) * inc + min
        v = math.clamp(v, min, max)
        return tonumber(string.format("%." .. decimals .. "f", v))
    end
    local value = snap(cfg.Default or min)

    local row = newRow(self, 46)
    textLabel({
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -90, 0, 16),
        Text = tostring(cfg.Name or "Slider"),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    local valueLabel = textLabel({
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 5),
        Size = UDim2.fromOffset(72, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = Theme.SubText,
        Parent = row,
    })
    local track = create("Frame", {
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0,
        Parent = row,
    })
    corner(track, 3)
    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(fill, 3)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = fill,
    })
    corner(knob, 6)
    stroke(knob, Theme.AccentDark, 1)

    local function render()
        local a = (max == min) and 0 or (value - min) / (max - min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        valueLabel.Text = tostring(value) .. suffix
    end
    render()

    local function setFromX(x)
        local w = track.AbsoluteSize.X
        if w <= 0 then
            return
        end
        local a = math.clamp((x - track.AbsolutePosition.X) / w, 0, 1)
        local nv = snap(min + (max - min) * a)
        if nv ~= value then
            value = nv
            render()
            safeCall(callback, value)
        end
    end

    local hit = create("TextButton", {
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 1, -20),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })

    local page = self._page
    local dragging, activeInput, moveConn, endConn = false, nil, nil, nil
    local function stop()
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end
        if endConn then
            endConn:Disconnect()
            endConn = nil
        end
        dragging = false
        activeInput = nil
        if page and page.Parent then
            page.ScrollingEnabled = true
        end
    end

    hit.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if dragging or (t ~= MouseButton1 and t ~= Touch) then
            return
        end
        dragging = true
        activeInput = input
        page.ScrollingEnabled = false
        setFromX(input.Position.X)

        moveConn = UserInputService.InputChanged:Connect(function(changed)
            local ct = changed.UserInputType
            if ct == MouseMovement or (ct == Touch and changed == activeInput) then
                setFromX(changed.Position.X)
            end
        end)
        endConn = UserInputService.InputEnded:Connect(function(ended)
            if ended == activeInput or (ended.UserInputType == MouseButton1 and activeInput and activeInput.UserInputType == MouseButton1) then
                stop()
            end
        end)
    end)

    local obj = {}
    function obj:Set(v, silent)
        local nv = snap(tonumber(v) or min)
        if nv == value then
            return
        end
        value = nv
        render()
        if not silent then
            safeCall(callback, value)
        end
    end
    function obj:Get()
        return value
    end
    if callback then
        task.defer(safeCall, callback, value)
    end
    return obj
end

--// Dropdown (single or multi)
function Section:CreateDropdown(cfg)
    cfg = cfg or {}
    local options = {}
    for i, o in ipairs(cfg.Options or {}) do
        options[i] = tostring(o)
    end
    local multi = cfg.Multi == true
    local callback = cfg.Callback

    local selected = {} -- multi: set
    local single = nil -- single: string
    if multi then
        for _, v in ipairs(type(cfg.Default) == "table" and cfg.Default or {}) do
            selected[tostring(v)] = true
        end
    elseif cfg.Default ~= nil then
        single = tostring(cfg.Default)
    end

    self._order += 1
    local box = create("Frame", {
        Name = tostring(cfg.Name or "Dropdown"),
        Size = UDim2.new(1, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = self._order,
        Parent = self._holder,
    })
    corner(box, 6)
    stroke(box, Theme.Stroke, 1)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })

    local head = textButton({
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = 1,
        Parent = box,
    })
    textLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0.5, -10, 1, 0),
        Text = tostring(cfg.Name or "Dropdown"),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = head,
    })
    local valueLabel = textLabel({
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0.5, -30, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = head,
    })
    local arrow = textLabel({
        Position = UDim2.new(1, -24, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        Font = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextColor3 = Theme.SubText,
        Text = ">",
        Parent = head,
    })

    local listFrame = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Stroke,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        LayoutOrder = 2,
        Parent = box,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listFrame,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = listFrame,
    })

    local optionButtons = {}
    local opened = false

    local function currentValue()
        if multi then
            local out = {}
            for _, o in ipairs(options) do
                if selected[o] then
                    out[#out + 1] = o
                end
            end
            return out
        end
        return single
    end

    local function refreshVisual()
        for name, b in pairs(optionButtons) do
            local on
            if multi then
                on = selected[name] == true
            else
                on = single == name
            end
            b.BackgroundColor3 = on and Theme.ElementHover or Theme.Element
            b.TextColor3 = on and Theme.Text or Theme.SubText
        end
        local v = currentValue()
        if multi then
            valueLabel.Text = (#v > 0) and table.concat(v, ", ") or "None"
        else
            valueLabel.Text = v and tostring(v) or "None"
        end
    end

    local function setOpen(state)
        opened = state
        listFrame.Visible = state
        tween(arrow, 0.15, { Rotation = state and 90 or 0 })
    end

    local function rebuild()
        for _, b in pairs(optionButtons) do
            b:Destroy()
        end
        table.clear(optionButtons)
        for i, opt in ipairs(options) do
            local b = textButton({
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 0,
                BackgroundColor3 = Theme.Element,
                Text = opt,
                TextColor3 = Theme.SubText,
                LayoutOrder = i,
                Parent = listFrame,
            })
            corner(b, 5)
            b.Activated:Connect(function()
                if multi then
                    selected[opt] = (not selected[opt]) or nil
                else
                    single = opt
                    setOpen(false)
                end
                refreshVisual()
                safeCall(callback, currentValue())
            end)
            optionButtons[opt] = b
        end
        listFrame.Size = UDim2.new(1, 0, 0, math.min(#options * 28 + 8, 150))
        refreshVisual()
    end
    rebuild()

    head.Activated:Connect(function()
        setOpen(not opened)
    end)
    hover(head, box, Theme.Element, Theme.ElementHover)

    local obj = {}
    function obj:Get()
        return currentValue()
    end
    function obj:Set(v, silent)
        if multi then
            table.clear(selected)
            for _, x in ipairs(type(v) == "table" and v or {}) do
                selected[tostring(x)] = true
            end
        else
            single = v ~= nil and tostring(v) or nil
        end
        refreshVisual()
        if not silent then
            safeCall(callback, currentValue())
        end
    end
    function obj:Refresh(newOptions)
        options = {}
        for i, o in ipairs(newOptions or {}) do
            options[i] = tostring(o)
        end
        local valid = {}
        for _, o in ipairs(options) do
            valid[o] = true
        end
        for k in pairs(selected) do
            if not valid[k] then
                selected[k] = nil
            end
        end
        if single and not valid[single] then
            single = nil
        end
        rebuild()
    end
    function obj:Open()
        setOpen(true)
    end
    function obj:Close()
        setOpen(false)
    end

    if callback and ((multi and next(selected)) or (not multi and single)) then
        task.defer(safeCall, callback, currentValue())
    end
    return obj
end

--// Textbox
function Section:CreateTextbox(cfg)
    cfg = cfg or {}
    local callback = cfg.Callback
    local row = newRow(self, 32)
    textLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -150, 1, 0),
        Text = tostring(cfg.Name or "Textbox"),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    local box = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(130, 22),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Font = FONT,
        TextSize = 12,
        TextColor3 = Theme.Text,
        PlaceholderText = tostring(cfg.Placeholder or ""),
        PlaceholderColor3 = Theme.SubText,
        Text = tostring(cfg.Default or ""),
        ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    corner(box, 5)
    stroke(box, Theme.Stroke, 1)
    box.FocusLost:Connect(function()
        safeCall(callback, box.Text)
    end)
    local obj = {}
    function obj:Set(t)
        box.Text = tostring(t)
    end
    function obj:Get()
        return box.Text
    end
    return obj
end

--// Keybind
function Section:CreateKeybind(cfg)
    cfg = cfg or {}
    local key = cfg.Default
    local callback = cfg.Callback
    local listening = false

    local row = newRow(self, 32)
    textLabel({
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -96, 1, 0),
        Text = tostring(cfg.Name or "Keybind"),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    local btn = textButton({
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(76, 22),
        BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Background,
        Text = key and key.Name or "None",
        Parent = row,
    })
    corner(btn, 5)
    stroke(btn, Theme.Stroke, 1)

    btn.Activated:Connect(function()
        listening = true
        btn.Text = "..."
    end)

    self._window._track(UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                if input.KeyCode ~= Enum.KeyCode.Escape then
                    key = input.KeyCode
                end
                btn.Text = key and key.Name or "None"
            end
            return
        end
        if not processed and key and input.KeyCode == key then
            safeCall(callback, key)
        end
    end))

    local obj = {}
    function obj:Set(k)
        key = k
        btn.Text = key and key.Name or "None"
    end
    function obj:Get()
        return key
    end
    return obj
end

return Library
