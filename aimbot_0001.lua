-- Full debugged & improved LocalScript
if _G.aimbot_loaded and _G.aimbot_loaded == true then return end
_G.aimbot_loaded = true

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local SELF = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- random string helper
local random_string = function()
	local length = math.random(32,64)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

-- safe parent lookup (as you had)
local PARENT
do
	local success, result = pcall(function()
		if gethui and typeof(gethui) == "function" then -- gethui is not available in studio environments
			return gethui()
		elseif CoreGui:FindFirstChild("RobloxGui") then
			return CoreGui
		else
			return SELF:WaitForChild("PlayerGui")
		end
	end)
	PARENT = (success and result) or SELF:WaitForChild("PlayerGui")
end

print("PARENT: "..(PARENT and PARENT:GetFullName() or "UNKNOWN"))
local gui = Instance.new("ScreenGui")
gui.Name = random_string()
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 9999
gui.Enabled = true
gui.Parent = PARENT

local currently_dragged = {}

local message = function(title, text, ptime, icon, button1, button2)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = ptime or 3,
			Icon = icon,
			Button1 = button1,
			Button2 = button2
		})
	end)
end

-- Adjust canvas size of a ScrollingFrame based on list/grid layout
local adjust_layout = function(object, adjust_x, adjust_y)
	local layout = object:FindFirstChildWhichIsA("UIListLayout") or object:FindFirstChildWhichIsA("UIGridLayout")
	local padding = object:FindFirstChildWhichIsA("UIPadding")
	if not layout then
		warn("Layout adjusting error: No UIListLayout or UIGridLayout found inside " .. object.Name)
		return
	end
	local updateCanvasSize = function()
		task.wait()
		local absContentSize = layout.AbsoluteContentSize

		local padX, padY = 0, 0
		if padding then
			padX = (padding.PaddingLeft.Offset + padding.PaddingRight.Offset)
			padY = (padding.PaddingTop.Offset + padding.PaddingBottom.Offset)
		end
		local totalX = absContentSize.X + padX + 10
		local totalY = absContentSize.Y + padY + 10

		if adjust_x and adjust_y then
			object.CanvasSize = UDim2.new(0, totalX, 0, totalY)
		elseif adjust_x then
			object.CanvasSize = UDim2.new(0, totalX, object.CanvasSize.Y.Scale, object.CanvasSize.Y.Offset)
		elseif adjust_y then
			object.CanvasSize = UDim2.new(object.CanvasSize.X.Scale, object.CanvasSize.X.Offset, 0, totalY)
		end
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
	object.ChildAdded:Connect(updateCanvasSize)
	object.ChildRemoved:Connect(updateCanvasSize)
	updateCanvasSize()
end

-- Draggable UI helper (hold 1 second to enable dragging)
local make_draggable = function(UIItem, y_draggable, x_draggable)
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local holdStartTime = nil
	local holdConnection = nil

	UIItem.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holdStartTime = tick()
			dragStart = input.Position
			startPos = UIItem.Position

			holdConnection = RunService.RenderStepped:Connect(function()
				if not dragging and (tick() - holdStartTime) >= 1 then
					message("Drag feature", "you can now drag "..(UIItem.Name or "this UI").." anywhere.", 1.5)
					dragging = true
					currently_dragged[UIItem] = true
					if holdConnection then
						holdConnection:Disconnect()
						holdConnection = nil
					end
				end
			end)

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if holdConnection then
						holdConnection:Disconnect()
						holdConnection = nil
					end
					if dragging then
						dragging = false
						task.delay(0.5, function()
							currently_dragged[UIItem] = nil
						end)
					end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart

			local newXOffset = x_draggable ~= false and (startPos.X.Offset + delta.X) or startPos.X.Offset
			local newYOffset = y_draggable ~= false and (startPos.Y.Offset + delta.Y) or startPos.Y.Offset

			UIItem.Position = UDim2.new(
				startPos.X.Scale, newXOffset,
				startPos.Y.Scale, newYOffset
			)
		end
	end)
end

-- UI creation
local aim_button = Instance.new("ImageButton")
local config_frame = Instance.new("ScrollingFrame")
local config_toggle = Instance.new("TextButton")
local config_layout = Instance.new("UIListLayout")

aim_button.Image = "rbxassetid://358948941"
aim_button.Parent = gui
aim_button.Visible = true
aim_button.Size = UDim2.new(0, 60, 0, 60)
aim_button.BackgroundTransparency = 0.5
aim_button.Name = "aim"

config_frame.Parent = gui
config_frame.Visible = true
config_frame.Position = UDim2.new(0.5, -100, 0.5, 100)
config_frame.Size = UDim2.new(0, 200, 0, 250)
config_frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
config_frame.BorderSizePixel = 0
config_frame.CanvasSize = UDim2.new(0,0,0,0)

config_toggle.Parent = gui
config_toggle.Visible = true
config_toggle.Position = UDim2.new(0.5, -50, 0.5, -140)
config_toggle.Size = UDim2.new(0, 100, 0, 50)
config_toggle.Text = "CONFIG"
config_toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
config_toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
config_toggle.BorderSizePixel = 0
config_toggle.Font = Enum.Font.GothamBold

config_layout.Parent = config_frame
config_layout.SortOrder = Enum.SortOrder.LayoutOrder
config_layout.Padding = UDim.new(0, 10)
config_layout.VerticalAlignment = Enum.VerticalAlignment.Top
config_layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
config_layout.FillDirection = Enum.FillDirection.Vertical

make_draggable(aim_button,true,true)
make_draggable(config_frame,true,true)
make_draggable(config_toggle,true,true)
adjust_layout(config_frame,false,true)

local create_config_button = function(name, variable, callback)
	local config__main = Instance.new("Frame")
	local config__title = Instance.new("TextLabel")
	local config__editable
	local varType = type(variable)
	if varType == "boolean" then
		config__editable = Instance.new("TextButton")
	elseif varType == "number" or varType == "string" then
		config__editable = Instance.new("TextBox")
	else
		config__editable = Instance.new("TextLabel") -- fallback read-only
	end
	config__main.Parent = config_frame
	config__main.Size = UDim2.new(1, 0, 0, 30)
	config__title.Parent = config__main
	config__title.Visible = true
	config__title.Position = UDim2.new(0, 0, 0, 0)
	config__title.Text = tostring(name)
	config__title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	config__title.Size = UDim2.new(0.5, 0, 1, 0)
	config__title.Font = Enum.Font.GothamBold
	config__title.TextColor3 = Color3.fromRGB(0, 0, 0)
	config__title.TextScaled = true
	config__title.TextXAlignment = Enum.TextXAlignment.Left
	config__editable.Parent = config__main
	config__editable.Visible = true
	config__editable.Position = UDim2.new(0.5, 0, 0, 0)
	config__editable.Text = tostring(variable)
	config__editable.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	config__editable.Size = UDim2.new(0.5, 0, 1, 0)
	config__editable.Font = Enum.Font.GothamBold
	config__editable.TextColor3 = Color3.fromRGB(0, 0, 0)
	config__editable.TextScaled = true
	if config__editable:IsA("TextBox") or config__editable:IsA("TextLabel") then
		config__editable.TextXAlignment = Enum.TextXAlignment.Left
	end
	if config__editable:IsA("TextBox") then
		config__editable.PlaceholderText = tostring(variable)
		config__editable.ClearTextOnFocus = false
		config__editable.FocusLost:Connect(function(enterpress)
			local newtxt = config__editable.Text
			if newtxt and newtxt ~= "" and (callback and type(callback) == "function") then
				if varType == "number" then
					local n = tonumber(newtxt)
					if n then
						callback(n)
					else
						message("Config", "Invalid number entered for "..tostring(name), 2)
						config__editable.Text = tostring(variable)
					end
				else
					callback(newtxt)
				end
			end
		end)
	elseif config__editable:IsA("TextButton") then
		config__editable.Text = tostring(variable and "ON" or "OFF")
		config__editable.MouseButton1Click:Connect(function()
			local newVal = not variable
			variable = newVal
			config__editable.Text = tostring(variable and "ON" or "OFF")
			if callback and type(callback) == "function" then
				callback(variable)
			end
		end)
	end
end

local lock_connection

local toggle_loop_lock = function()
	if lock_connection then
		lock_connection:Disconnect()
		lock_connection = nil
	else
		lock_connection = RunService.PreRender:Connect(function()
			if not cam then return end
			local character = SELF.Character
			local HRP = character:FindFirstChild("HumanoidRootPart")
			if not character or not HRP then return end
			local cameraPivot = cam.CFrame
			local look = cameraPivot.LookVector
			local x, y, z = cameraPivot:ToOrientation()
			local newPivot = CFrame.new(HRP.Position) * CFrame.Angles(0, y, 0)
			HRP:PivotTo(newPivot)
		end)
	end
end

local auto_aim_conn = nil
local target_updater_thread = nil
local lerpSpeed = 16
local target_head = nil
local aim_running = false
local snap_char_choice = false

local function find_closest_target()
	if not cam or not SELF then return nil end
	local camCF = cam.CFrame
	local selfChar = SELF.Character
	if not selfChar then return nil end
	local potentialTargetsSet = {}
	local potentialTargets = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= SELF and pl.Character and not potentialTargetsSet[pl.Character] then
			potentialTargetsSet[pl.Character] = true
			table.insert(potentialTargets, pl.Character)
		end
	end
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
			local alreadyPlayerChar = Players:GetPlayerFromCharacter(model) ~= nil
			if not alreadyPlayerChar and model ~= selfChar and not potentialTargetsSet[model] then
				potentialTargetsSet[model] = true
				table.insert(potentialTargets, model)
			end
		end
	end
	local closest, shortest = nil, math.huge
	for _, char in ipairs(potentialTargets) do
		local head = char:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			local dist = (head.Position - camCF.Position).Magnitude
			if dist < shortest then
				shortest = dist
				closest = head
			end
		end
	end
	return closest
end

local function update_target_loop()
	while aim_running do
		pcall(function()
			target_head = find_closest_target()
		end)
		task.wait(0.18)
	end
	target_head = nil
end

local function aim_at_target(dt)
	if not target_head or not cam then return end
	local camCF = cam.CFrame
	local head = target_head
	local targetVelocity = Vector3.new(0,0,0)
	local root = head.Parent and head.Parent:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		targetVelocity = root.Velocity
	elseif head and head:IsA("BasePart") then
		targetVelocity = head.Velocity
	end
	local distance = (head.Position - camCF.Position).Magnitude
	local predictionTime = math.clamp(distance / 150, 0.05, 0.25)
	local predictedPos = head.Position + targetVelocity * predictionTime
	local dir = (predictedPos - camCF.Position)
	if dir.Magnitude <= 0 then return end
	local desiredCF = CFrame.new(camCF.Position, camCF.Position + dir.Unit)
	local alpha = math.clamp(lerpSpeed * dt, 0, 1)
	cam.CFrame = camCF:Lerp(desiredCF, alpha)
end

local function auto_aim_function()
	if aim_running then
		aim_running = false
		if auto_aim_conn then
			auto_aim_conn:Disconnect()
			auto_aim_conn = nil
		end
		target_head = nil
		message("Auto Aim", "Auto-aim stopped", 1)
	else
		aim_running = true
		target_updater_thread = task.spawn(update_target_loop)
		auto_aim_conn = RunService.RenderStepped:Connect(function(dt)
			pcall(function() aim_at_target(dt) end)
		end)
		message("Auto Aim", "Auto-aim started", 1)
	end
end

create_config_button("Snap speed", lerpSpeed, function(new_value)
	if type(new_value) == "number" then
		lerpSpeed = new_value
	else
		local n = tonumber(new_value)
		if n then lerpSpeed = n end
	end
end)

create_config_button("Snap player character", snap_char_choice, function(new_val)
	if type(new_val) == "boolean" then
		snap_char_choice = new_val
		if snap_char_choice then
			toggle_loop_lock()
		else
			if lock_connection then
				lock_connection:Disconnect()
				lock_connection = nil
			end
		end
	end
end)

aim_button.Activated:Connect(auto_aim_function)
config_toggle.Activated:Connect(function()
	if next(currently_dragged) then return end
	config_frame.Visible = not config_frame.Visible
	if snap_char_choice then
		toggle_loop_lock()
	end
end)
