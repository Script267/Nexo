-- ScriptGui.lua
-- LocalScript → StarterPlayer > StarterPlayerScripts

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ══════════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════════
local FOV_RADIUS = 150
local SMOOTHNESS = 10
local AIM_SMOOTH = 8

-- ══════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════
local camlockEnabled = false
local aimlockEnabled = false
local targetLock     = false
local espEnabled     = false
local showFovCircle  = true

local lockedTarget   = nil
local espObjects     = {}   -- [Player] = { box, tracerLine, healthBar, nameLabel, distLabel }

-- ══════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "ScriptGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = player:WaitForChild("PlayerGui")

-- ── FOV Circle ──────────────────────────
local fovCircle = Instance.new("Frame")
fovCircle.Name                = "FovCircle"
fovCircle.Size                = UDim2.new(0, FOV_RADIUS*2, 0, FOV_RADIUS*2)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel     = 0
fovCircle.ZIndex              = 10
fovCircle.Visible             = false
fovCircle.Parent              = screenGui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color     = Color3.fromRGB(255, 80, 80)
fovStroke.Thickness = 1.5

-- ESP drawing layer (below menu)
local espLayer = Instance.new("Frame")
espLayer.Name                = "ESPLayer"
espLayer.Size                = UDim2.new(1, 0, 1, 0)
espLayer.BackgroundTransparency = 1
espLayer.ZIndex              = 2
espLayer.Parent              = screenGui

-- ── Menu Open Button ────────────────────
local menuBtn = Instance.new("TextButton")
menuBtn.Name            = "MenuBtn"
menuBtn.Size            = UDim2.new(0, 48, 0, 48)
menuBtn.Position        = UDim2.new(0, 20, 0, 20)
menuBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menuBtn.Text            = "☰"
menuBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
menuBtn.Font            = Enum.Font.GothamBold
menuBtn.TextSize        = 22
menuBtn.AutoButtonColor = false
menuBtn.ZIndex          = 20
menuBtn.Parent          = screenGui
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 10)

-- ── Menu Panel ──────────────────────────
local PANEL_W  = 220
local ROW_H    = 48
local HEADER_H = 44

local panel = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, PANEL_W, 0, 0)
panel.Position          = UDim2.new(0, 20, 0, 78)
panel.BackgroundColor3  = Color3.fromRGB(18, 18, 18)
panel.BorderSizePixel   = 0
panel.ClipsDescendants  = true
panel.Visible           = false
panel.ZIndex            = 15
panel.Parent            = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, -16, 0, HEADER_H)
titleLabel.Position           = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "🎯  Script Menu"
titleLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextSize           = 15
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.ZIndex             = 16
titleLabel.Parent             = panel

local sep = Instance.new("Frame")
sep.Size            = UDim2.new(1, -24, 0, 1)
sep.Position        = UDim2.new(0, 12, 0, HEADER_H)
sep.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sep.BorderSizePixel = 0
sep.ZIndex          = 16
sep.Parent          = panel

-- ══════════════════════════════════════════
--  ROW / SLIDER BUILDERS
-- ══════════════════════════════════════════
local function makeRow(labelText, index)
	local yPos = HEADER_H + 4 + (index - 1) * ROW_H
	local row  = Instance.new("Frame")
	row.Size            = UDim2.new(1, -24, 0, ROW_H - 6)
	row.Position        = UDim2.new(0, 12, 0, yPos + 3)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	row.BorderSizePixel = 0
	row.ZIndex          = 16
	row.Parent          = panel
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size              = UDim2.new(0, 120, 1, 0)
	lbl.Position          = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text              = labelText
	lbl.TextColor3        = Color3.fromRGB(220, 220, 220)
	lbl.Font              = Enum.Font.Gotham
	lbl.TextSize          = 14
	lbl.TextXAlignment    = Enum.TextXAlignment.Left
	lbl.ZIndex            = 17
	lbl.Parent            = row

	local togBtn = Instance.new("TextButton")
	togBtn.Size            = UDim2.new(0, 44, 0, 24)
	togBtn.Position        = UDim2.new(1, -54, 0.5, -12)
	togBtn.BackgroundColor3 = Color3.fromRGB(160, 35, 35)
	togBtn.Text            = ""
	togBtn.AutoButtonColor = false
	togBtn.ZIndex          = 18
	togBtn.Parent          = row
	Instance.new("UICorner", togBtn).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size            = UDim2.new(0, 20, 0, 20)
	knob.Position        = UDim2.new(0, 2, 0.5, -10)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.ZIndex          = 19
	knob.Parent          = togBtn
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	return togBtn, knob
end

local function makeSlider(labelText, index, minVal, maxVal, defaultVal)
	local yPos = HEADER_H + 4 + (index - 1) * ROW_H
	local row  = Instance.new("Frame")
	row.Size            = UDim2.new(1, -24, 0, ROW_H - 6)
	row.Position        = UDim2.new(0, 12, 0, yPos + 3)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	row.BorderSizePixel = 0
	row.ZIndex          = 16
	row.Parent          = panel
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size              = UDim2.new(0, 90, 0.5, 0)
	lbl.Position          = UDim2.new(0, 10, 0, 2)
	lbl.BackgroundTransparency = 1
	lbl.Text              = labelText
	lbl.TextColor3        = Color3.fromRGB(200, 200, 200)
	lbl.Font              = Enum.Font.Gotham
	lbl.TextSize          = 13
	lbl.TextXAlignment    = Enum.TextXAlignment.Left
	lbl.ZIndex            = 17
	lbl.Parent            = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Size              = UDim2.new(0, 36, 0.5, 0)
	valLbl.Position          = UDim2.new(1, -44, 0, 2)
	valLbl.BackgroundTransparency = 1
	valLbl.Text              = tostring(defaultVal)
	valLbl.TextColor3        = Color3.fromRGB(255, 80, 80)
	valLbl.Font              = Enum.Font.GothamBold
	valLbl.TextSize          = 13
	valLbl.TextXAlignment    = Enum.TextXAlignment.Right
	valLbl.ZIndex            = 17
	valLbl.Parent            = row

	local track = Instance.new("Frame")
	track.Size            = UDim2.new(1, -20, 0, 4)
	track.Position        = UDim2.new(0, 10, 1, -10)
	track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	track.BorderSizePixel = 0
	track.ZIndex          = 17
	track.Parent          = row
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size            = UDim2.new((defaultVal-minVal)/(maxVal-minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	fill.BorderSizePixel = 0
	fill.ZIndex          = 18
	fill.Parent          = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local thumb = Instance.new("TextButton")
	thumb.Size            = UDim2.new(0, 14, 0, 14)
	thumb.AnchorPoint     = Vector2.new(0.5, 0.5)
	thumb.Position        = UDim2.new((defaultVal-minVal)/(maxVal-minVal), 0, 0.5, 0)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.Text            = ""
	thumb.AutoButtonColor = false
	thumb.ZIndex          = 19
	thumb.Parent          = track
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

	local currentVal = defaultVal
	local dragging   = false
	thumb.MouseButton1Down:Connect(function() dragging = true end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	RunService.RenderStepped:Connect(function()
		if not dragging then return end
		local tPos  = track.AbsolutePosition
		local tSize = track.AbsoluteSize
		local mX    = UserInputService:GetMouseLocation().X
		local ratio = math.clamp((mX - tPos.X) / tSize.X, 0, 1)
		currentVal  = math.floor(minVal + ratio * (maxVal - minVal) + 0.5)
		fill.Size   = UDim2.new(ratio, 0, 1, 0)
		thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
		valLbl.Text = tostring(currentVal)
	end)
	return function() return currentVal end
end

-- ══════════════════════════════════════════
--  BUILD ROWS
-- ══════════════════════════════════════════
local TOTAL_ROWS   = 7
local PANEL_OPEN_H = HEADER_H + 8 + TOTAL_ROWS * ROW_H

local camlockBtn,  camlockKnob  = makeRow("🎥  Camlock",     1)
local aimlockBtn,  aimlockKnob  = makeRow("🎯  Aimbot",      2)
local targetBtn,   targetKnob   = makeRow("🔒  Target Lock", 3)
local espBtn,      espKnob      = makeRow("👁  ESP",         4)
local getFov       = makeSlider("FOV Radius",  5, 50, 400, FOV_RADIUS)
local getSmooth    = makeSlider("Smoothness",  6, 1,  20,  SMOOTHNESS)
local getAimSmooth = makeSlider("Aim Smooth",  7, 1,  20,  AIM_SMOOTH)

-- ══════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════
local function setToggle(btn, knob, state)
	local col = state and Color3.fromRGB(40, 190, 90) or Color3.fromRGB(160, 35, 35)
	local pos = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
	TweenService:Create(btn,  TweenInfo.new(0.15), {BackgroundColor3 = col}):Play()
	TweenService:Create(knob, TweenInfo.new(0.15), {Position = pos}):Play()
end

local function getNearestTarget(maxRadius)
	local myChar = player.Character
	if not myChar then return nil end
	local cx, cy = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
	local nearest, nearestDist = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local sp, onScreen = camera:WorldToViewportPoint(hrp.Position)
				if onScreen then
					local dx   = sp.X - cx
					local dy   = sp.Y - cy
					local dist = math.sqrt(dx*dx + dy*dy)
					if dist < (maxRadius or math.huge) and dist < nearestDist then
						nearest     = p
						nearestDist = dist
					end
				end
			end
		end
	end
	return nearest
end

-- ══════════════════════════════════════════
--  ESP SYSTEM
--  Per-player: corner box, side HP bar,
--  name label, distance, tracer line
-- ══════════════════════════════════════════

-- Draws a line between two screen points using a rotated Frame
local function makeLine(parent)
	local line = Instance.new("Frame")
	line.BackgroundColor3   = Color3.fromRGB(255, 50, 50)
	line.BorderSizePixel    = 0
	line.AnchorPoint        = Vector2.new(0, 0.5)
	line.ZIndex             = 3
	line.Parent             = parent
	return line
end

local function updateLine(line, x1, y1, x2, y2)
	local dx  = x2 - x1
	local dy  = y2 - y1
	local len = math.sqrt(dx*dx + dy*dy)
	local ang = math.atan2(dy, dx)
	line.Position = UDim2.new(0, x1, 0, y1)
	line.Size     = UDim2.new(0, len, 0, 1.5)
	line.Rotation = math.deg(ang)
end

-- Makes a corner-bracket box (4 corner L-shapes instead of full outline)
local function makeCornerBox(parent)
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.ZIndex = 3
	box.Parent = parent

	local CORNER = 6 -- length of each corner arm in pixels
	local THICK  = 2

	local corners = {}
	-- top-left, top-right, bottom-left, bottom-right
	local specs = {
		{h = {0,0,CORNER,THICK}, v = {0,0,THICK,CORNER}},
		{h = {1,-CORNER,CORNER,THICK}, v = {1,-THICK,THICK,CORNER}},
		{h = {0,0,CORNER,THICK}, v = {0,-CORNER,THICK,CORNER}},
		{h = {1,-CORNER,CORNER,THICK}, v = {1,-CORNER-THICK,THICK,CORNER}},
	}
	-- anchors for positioning each corner's h/v arms
	local anchors = {
		{hAnchor={0,0}, vAnchor={0,0}},
		{hAnchor={1,0}, vAnchor={1,0}},
		{hAnchor={0,1}, vAnchor={0,1}},
		{hAnchor={1,1}, vAnchor={1,1}},
	}

	for i = 1, 4 do
		-- horizontal arm
		local hArm = Instance.new("Frame")
		hArm.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		hArm.BorderSizePixel  = 0
		hArm.ZIndex           = 4
		hArm.Parent           = box

		-- vertical arm
		local vArm = Instance.new("Frame")
		vArm.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		vArm.BorderSizePixel  = 0
		vArm.ZIndex           = 4
		vArm.Parent           = box

		corners[i] = {h = hArm, v = vArm}
	end

	return box, corners
end

local function updateCornerBox(box, corners, sx, sy, ex, ey)
	local w  = ex - sx
	local h  = ey - sy
	local CL = math.max(6, math.min(w, h) * 0.25) -- corner length scales with box
	local TH = 2

	box.Position = UDim2.new(0, sx, 0, sy)
	box.Size     = UDim2.new(0, w, 0, h)

	-- top-left
	corners[1].h.Position = UDim2.new(0,  0,   0, 0);   corners[1].h.Size = UDim2.new(0, CL, 0, TH)
	corners[1].v.Position = UDim2.new(0,  0,   0, 0);   corners[1].v.Size = UDim2.new(0, TH, 0, CL)
	-- top-right
	corners[2].h.Position = UDim2.new(1, -CL,  0, 0);   corners[2].h.Size = UDim2.new(0, CL, 0, TH)
	corners[2].v.Position = UDim2.new(1, -TH,  0, 0);   corners[2].v.Size = UDim2.new(0, TH, 0, CL)
	-- bottom-left
	corners[3].h.Position = UDim2.new(0,  0,   1, -TH); corners[3].h.Size = UDim2.new(0, CL, 0, TH)
	corners[3].v.Position = UDim2.new(0,  0,   1, -CL); corners[3].v.Size = UDim2.new(0, TH, 0, CL)
	-- bottom-right
	corners[4].h.Position = UDim2.new(1, -CL,  1, -TH); corners[4].h.Size = UDim2.new(0, CL, 0, TH)
	corners[4].v.Position = UDim2.new(1, -TH,  1, -CL); corners[4].v.Size = UDim2.new(0, TH, 0, CL)
end

local function makeHealthBar(parent)
	local bg = Instance.new("Frame")
	bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	bg.BorderSizePixel  = 0
	bg.ZIndex           = 4
	bg.Parent           = parent
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 60)
	fill.BorderSizePixel  = 0
	fill.Size             = UDim2.new(1, 0, 1, 0)
	fill.ZIndex           = 5
	fill.Parent           = bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	return bg, fill
end

local function makeTextLabel(parent, size, color, bold)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency  = 1
	lbl.TextColor3              = color or Color3.new(1,1,1)
	lbl.Font                    = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	lbl.TextSize                = size or 12
	lbl.TextStrokeTransparency  = 0.3
	lbl.ZIndex                  = 5
	lbl.Parent                  = parent
	return lbl
end

-- ── Create ESP for one player ──
local function createESP(p)
	if espObjects[p] then
		for _, obj in pairs(espObjects[p]) do
			if typeof(obj) == "Instance" and obj.Parent then obj:Destroy() end
		end
		espObjects[p] = nil
	end

	local char = p.Character
	if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local box, corners = makeCornerBox(espLayer)
	local hpBg, hpFill = makeHealthBar(espLayer)
	local tracer        = makeLine(espLayer)
	local nameLbl       = makeTextLabel(espLayer, 12, Color3.fromRGB(255,60,60), true)
	local distLbl       = makeTextLabel(espLayer, 11, Color3.fromRGB(200,200,200), false)

	espObjects[p] = {
		box = box, corners = corners,
		hpBg = hpBg, hpFill = hpFill,
		tracer = tracer,
		nameLbl = nameLbl, distLbl = distLbl,
		char = char, hrp = hrp
	}
end

local function removeESP(p)
	local objs = espObjects[p]
	if not objs then return end
	for _, obj in pairs(objs) do
		if typeof(obj) == "Instance" and obj.Parent then obj:Destroy() end
	end
	espObjects[p] = nil
end

local function clearESP()
	for p in pairs(espObjects) do removeESP(p) end
end

local function refreshESP()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then createESP(p) end
	end
end

-- ── Watch for character respawns ──
local function watchPlayer(p)
	p.CharacterAdded:Connect(function()
		removeESP(p)
		task.wait(0.5)
		if espEnabled then createESP(p) end
	end)
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(removeESP)

-- ══════════════════════════════════════════
--  MENU OPEN / CLOSE
-- ══════════════════════════════════════════
local menuOpen = false

local function setMenu(state)
	menuOpen       = state
	panel.Visible  = true
	local targetH  = state and PANEL_OPEN_H or 0
	local tw = TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, PANEL_W, 0, targetH)
	})
	tw:Play()
	if not state then tw.Completed:Wait(); panel.Visible = false end
end

menuBtn.MouseButton1Click:Connect(function() setMenu(not menuOpen) end)

-- ══════════════════════════════════════════
--  TOGGLE CONNECTIONS
-- ══════════════════════════════════════════
camlockBtn.MouseButton1Click:Connect(function()
	camlockEnabled = not camlockEnabled
	setToggle(camlockBtn, camlockKnob, camlockEnabled)
	if not camlockEnabled then lockedTarget = nil end
end)

aimlockBtn.MouseButton1Click:Connect(function()
	aimlockEnabled = not aimlockEnabled
	setToggle(aimlockBtn, aimlockKnob, aimlockEnabled)
end)

targetBtn.MouseButton1Click:Connect(function()
	targetLock = not targetLock
	setToggle(targetBtn, targetKnob, targetLock)
	if not targetLock then lockedTarget = nil end
end)

espBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	setToggle(espBtn, espKnob, espEnabled)
	if espEnabled then refreshESP() else clearESP() end
end)

-- ══════════════════════════════════════════
--  FOV CIRCLE – follows mouse
-- ══════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	local r  = getFov()
	local mp = UserInputService:GetMouseLocation()
	fovCircle.Size     = UDim2.new(0, r*2, 0, r*2)
	fovCircle.Position = UDim2.new(0, mp.X - r, 0, mp.Y - r)
	fovCircle.Visible  = (aimlockEnabled or targetLock) and showFovCircle
end)

-- ══════════════════════════════════════════
--  MAIN RENDER LOOP
-- ══════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
	local fovR    = getFov()
	local smooth  = getSmooth()
	local aimSmth = getAimSmooth()
	local vp      = camera.ViewportSize
	local cx, cy  = vp.X / 2, vp.Y

	-- Target Lock – sticky acquire within FOV
	if targetLock then
		if not lockedTarget
			or not lockedTarget.Character
			or not (lockedTarget.Character:FindFirstChild("Humanoid"))
			or lockedTarget.Character.Humanoid.Health <= 0 then
			lockedTarget = getNearestTarget(fovR)
		end
	end

	-- Camlock – smooth camera toward target
	if camlockEnabled then
		local t = lockedTarget or getNearestTarget()
		if t and t.Character then
			local hrp = t.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local desired = CFrame.new(camera.CFrame.Position, hrp.Position)
				local alpha   = 1 - math.exp(-smooth * dt)
				camera.CFrame = camera.CFrame:Lerp(desired, alpha)
			end
		end
	end

	-- Aimbot – hold RMB to snap to head
	if aimlockEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local t = lockedTarget or getNearestTarget(fovR)
		if t and t.Character then
			local head = t.Character:FindFirstChild("Head")
			if head then
				local sp, onScreen = camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local alpha = 1 - math.exp(-aimSmth * dt)
					local dx    = (sp.X - vp.X/2) * alpha * 0.002
					local dy    = (sp.Y - vp.Y/2) * alpha * 0.002
					local cf    = camera.CFrame
					camera.CFrame = CFrame.new(cf.Position)
						* CFrame.Angles(0, -dx, 0)
						* CFrame.fromEulerAnglesYXZ(
							select(1, cf:ToEulerAnglesYXZ()) - dy,
							select(2, cf:ToEulerAnglesYXZ()), 0)
				end
			end
		end
	end

	-- ── ESP UPDATE ──────────────────────────
	for p, objs in pairs(espObjects) do
		local visible = false

		if espEnabled and p.Character and objs.hrp and objs.hrp.Parent then
			local char = p.Character
			local hrp  = objs.hrp
			local hum  = char:FindFirstChild("Humanoid")
			local head = char:FindFirstChild("Head")

			if hum and head and hum.Health > 0 then
				-- Project top/bottom of character to screen
				local rootSP, rootOn = camera:WorldToViewportPoint(hrp.Position)
				local headSP, headOn = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
				local feetSP, feetOn = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.8, 0))

				if rootOn then
					visible = true

					-- Box dimensions from head → feet projected
					local boxTop    = headSP.Y
					local boxBottom = feetSP.Y
					local boxH      = math.max(boxBottom - boxTop, 20)
					local boxW      = boxH * 0.55  -- ~character aspect ratio
					local boxLeft   = rootSP.X - boxW / 2
					local boxRight  = rootSP.X + boxW / 2

					-- Corner box
					updateCornerBox(objs.box, objs.corners, boxLeft, boxTop, boxRight, boxBottom)
					objs.box.Visible = true

					-- HP bar – left side of box, 4px wide
					local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
					objs.hpBg.Position = UDim2.new(0, boxLeft - 7, 0, boxTop)
					objs.hpBg.Size     = UDim2.new(0, 4, 0, boxH)
					objs.hpBg.Visible  = true

					-- Fill goes bottom-up
					objs.hpFill.AnchorPoint = Vector2.new(0, 1)
					objs.hpFill.Position    = UDim2.new(0, 0, 1, 0)
					objs.hpFill.Size        = UDim2.new(1, 0, hpRatio, 0)
					-- color: green → yellow → red
					local r = math.floor(255 * (1 - hpRatio))
					local g = math.floor(255 * hpRatio)
					objs.hpFill.BackgroundColor3 = Color3.fromRGB(r, g, 0)

					-- Name label – above box
					objs.nameLbl.Position = UDim2.new(0, rootSP.X - 60, 0, boxTop - 16)
					objs.nameLbl.Size     = UDim2.new(0, 120, 0, 14)
					objs.nameLbl.Text     = p.Name
					objs.nameLbl.Visible  = true

					-- Distance label – below box
					local myChar = player.Character
					if myChar and myChar:FindFirstChild("HumanoidRootPart") then
						local dist = math.floor((hrp.Position - myChar.HumanoidRootPart.Position).Magnitude)
						objs.distLbl.Text = dist .. " studs"
					end
					objs.distLbl.Position = UDim2.new(0, rootSP.X - 60, 0, boxBottom + 2)
					objs.distLbl.Size     = UDim2.new(0, 120, 0, 13)
					objs.distLbl.Visible  = true

					-- Tracer line – from bottom-center of screen to feet
					updateLine(objs.tracer, cx, cy, feetSP.X, feetSP.Y)
					objs.tracer.Visible = true
				end
			end
		end

		if not visible then
			if objs.box      then objs.box.Visible     = false end
			if objs.hpBg     then objs.hpBg.Visible    = false end
			if objs.tracer   then objs.tracer.Visible   = false end
			if objs.nameLbl  then objs.nameLbl.Visible  = false end
			if objs.distLbl  then objs.distLbl.Visible  = false end
		end
	end
end)
