-- 📦 Load service
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- 🎨 GUI setup
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "RezUI"

local frame = Instance.new("Frame", gui)
frame.Position = UDim2.new(0.7, 0, 0.35, 0)
frame.Size = UDim2.new(0, 280, 0, 270)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local uiStroke = Instance.new("UIStroke", frame)
uiStroke.Thickness = 2
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
task.spawn(function()
	while true do
		for h = 0, 1, 0.01 do
			uiStroke.Color = Color3.fromHSV(h, 1, 1)
			task.wait()
		end
	end
end)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", frame)
title.Text = "💀 Rez 💀"
title.Position = UDim2.new(0, 0, 0, 5)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.FredokaOne
title.TextSize = 22

local subtitle = Instance.new("TextLabel", frame)
subtitle.Text = "by rez"
subtitle.Position = UDim2.new(0, 0, 0, 35)
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14

local buttonContainer = Instance.new("Frame", frame)
buttonContainer.Position = UDim2.new(0, 15, 0, 60)
buttonContainer.Size = UDim2.new(1, -30, 1, -70)
buttonContainer.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", buttonContainer)
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Padding = UDim.new(0, 10)

local function createButton(name)
	local btn = Instance.new("TextButton")
	btn.Text = name
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	btn.BackgroundTransparency = 0.2
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 14

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", btn)
	stroke.Thickness = 1.2
	stroke.Color = Color3.fromRGB(200, 200, 200)

	return btn
end

-- ⚙️ Config
local rotating = false
local target = nil
local targetType = "PLayer" -- hoặc "Player"
local radius = 18
local heightOffset = 0
local speed = 4
local angle = 0
local attacking = false
local autoCollect = false

-- 📍 Tìm player gần
local function getNearestPlayer(radiusSearch)
	local closest, minDist = nil, radiusSearch
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
			if dist < minDist then
				closest = player
				minDist = dist
			end
		end
	end
	return closest and closest.Character
end

-- 📍 Tìm boss gần
local function getNearestBoss(maxDist)
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local nearest, closest = nil, maxDist

	for _, m in pairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m:FindFirstChild("Humanoid") and m:FindFirstChild("HumanoidRootPart") and m ~= Character then
			local d = (root.Position - m.HumanoidRootPart.Position).Magnitude
			if d < closest then
				nearest, closest = m, d
			end
		end
	end

	return nearest
end

-- ▶️ Start orbit
local function startOrbit()
	if rotating then return end
	rotating = true
	angle = 0

	RunService:UnbindFromRenderStep("OrbitAroundTarget")
	RunService:BindToRenderStep("OrbitAroundTarget", Enum.RenderPriority.Character.Value, function(dt)
		if not rotating then return end

		-- boss chết → tìm boss mới
		if not target or not target:FindFirstChild("HumanoidRootPart") or (target:FindFirstChild("Humanoid") and target.Humanoid.Health <= 0) then
			target = (targetType == "Player") and getNearestPlayer(100) or getNearestBoss(100)
			if not target then return end
		end

		local center = target.HumanoidRootPart.Position + Vector3.new(0, heightOffset, 0)
		angle += dt * math.pi * 2 * speed

		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local orbitPosition = center + Vector3.new(x, 0, z)

		HumanoidRootPart.CFrame = CFrame.new(orbitPosition, center)
	end)
end

local function stopOrbit()
	rotating = false
	RunService:UnbindFromRenderStep("OrbitAroundTarget")
end

-- 🔘 UI Buttons
local ToggleAutoAttack = createButton("🗡️ Tự đánh khi cầm vũ khí")
local ToggleBossAttack = createButton("🔁 Xoay quanh Boss")
local ToggleCollect = createButton("📦 Tự nhặt vật phẩm / Đang Fix")
local ToggleHealth = createButton("📊 Hiển thị máu")
ToggleAutoAttack.Parent = buttonContainer
ToggleBossAttack.Parent = buttonContainer
ToggleCollect.Parent = buttonContainer
ToggleHealth.Parent = buttonContainer

-- 🗡️ Auto attack
task.spawn(function()
	while true do
		task.wait(0.2)
		if attacking then
			local tool = Character and Character:FindFirstChildOfClass("Tool")
			if tool then pcall(function() tool:Activate() end) end
		end
	end
end)

ToggleAutoAttack.MouseButton1Click:Connect(function()
	attacking = not attacking
	ToggleAutoAttack.Text = attacking and "✅ Đang lọ" or "🗡️ Tự đánh khi cầm vũ khí"
end)

-- 📦 Auto collect
local function Prompt(proximityPrompt)
	task.wait(0.1)
	if proximityPrompt then
		pcall(function()
			proximityPrompt.Enabled = true
			proximityPrompt.HoldDuration = 0
			fireproximityprompt(proximityPrompt, 1, true)
		end)
	end
end

spawn(function()
	while task.wait(1) do
		if not autoCollect then continue end
		pcall(function()
			for _, folderName in pairs({"CityNPCs", "GiangHo2", "Npc2"}) do
				local folder = workspace:FindFirstChild(folderName)
				if folder and folder:FindFirstChild("Drop") then
					for _, drop in pairs(folder.Drop:GetChildren()) do
						local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
						if prompt then Prompt(prompt) end
					end
				end
			end
		end)
	end
end)

ToggleCollect.MouseButton1Click:Connect(function()
	autoCollect = not autoCollect
	ToggleCollect.Text = autoCollect and "Đã nói là đang fix" or "📦 Tự nhặt vật phẩm / Đang Fix"
end)

ToggleBossAttack.MouseButton1Click:Connect(function()
	if rotating then
		stopOrbit()
		ToggleBossAttack.Text = "🔁 Xoay quanh Boss"
	else
		startOrbit()
		if target then
			ToggleBossAttack.Text = "❌ Có mẹ nào ở gần đâu ?"
		else
			ToggleBossAttack.Text = "✅ Đang xoay quanh Boss"
		end
	end
end)


-- 📊 Hiển thị máu
local showHealth = false
local healthUI = {}

ToggleHealth.MouseButton1Click:Connect(function()
	showHealth = not showHealth
	ToggleHealth.Text = showHealth and "✅ Đang hiển thị máu..." or "📊 Hiển thị máu"
	if not showHealth then
		for _, gui in pairs(healthUI) do if gui and gui.Parent then gui:Destroy() end end
		healthUI = {}
	end
end)

task.spawn(function()
	while task.wait(0.3) do
		if showHealth then
			for _, model in pairs(workspace:GetDescendants()) do
				if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") and model ~= Character then
					local head = model.Head
					local humanoid = model.Humanoid
					if not healthUI[model] or not healthUI[model].Parent then
						local bill = Instance.new("BillboardGui")
						bill.Size = UDim2.new(4, 0, 0.5, 0)
						bill.StudsOffset = Vector3.new(0, 2.5, 0)
						bill.Adornee = head
						bill.AlwaysOnTop = true
						bill.Parent = head

						local bg = Instance.new("Frame", bill)
						bg.Size = UDim2.new(1, 0, 1, 0)
						bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
						bg.BorderSizePixel = 0

						local hpBar = Instance.new("Frame", bg)
						hpBar.Name = "HP"
						hpBar.Size = UDim2.new(1, 0, 1, 0)
						hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
						hpBar.BorderSizePixel = 0

						local hpText = Instance.new("TextLabel", bg)
						hpText.Size = UDim2.new(1, 0, 1, 0)
						hpText.BackgroundTransparency = 1
						hpText.TextColor3 = Color3.new(1, 1, 1)
						hpText.TextStrokeTransparency = 0.5
						hpText.TextScaled = true
						hpText.Font = Enum.Font.GothamBold

						healthUI[model] = bill
					end

					local bg = healthUI[model]:FindFirstChild("BG") or healthUI[model]:FindFirstChildOfClass("Frame")
					if bg and bg:FindFirstChild("HP") and bg:FindFirstChildOfClass("TextLabel") then
						local hp = humanoid.Health
						local max = humanoid.MaxHealth
						bg.HP.Size = UDim2.new(math.clamp(hp / max, 0, 1), 0, 1, 0)
						bg.TextLabel.Text = string.format("%d / %d", hp, max)
					end
				end
			end
		end
	end
end)


-- ❌ Đóng UI
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Text = "✖"
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Size = UDim2.new(0, 30, 0, 25)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)


