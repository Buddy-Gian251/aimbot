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
local ALLPLAYERS = Players:GetPlayers()

local random_string = function()
	local length = math.random(32,64)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

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
print("PARENT: "..PARENT:GetFullName())
task.wait()
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

local make_draggable = function(UIItem, y_draggable, x_draggable)
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local holdStartTime = nil
	local holdConnection = nil
	UIItem.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			holdStartTime = tick()
			dragStart = input.Position
			startPos = UIItem.Position
			holdConnection = RunService.RenderStepped:Connect(function()
				if not dragging and (tick() - holdStartTime) >= 1 then
					message("Drag feature", "you can now drag "..(UIItem.Name or "this UI").." anywhere.", 2)
					dragging = true
					currently_dragged[UIItem] = true
					holdConnection:Disconnect()
					holdConnection = nil
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
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
			input.UserInputType == Enum.UserInputType.Touch) then
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
config_frame.Position = UDim2.new(0.5, -50, 0.5, 100)
config_frame.Size = UDim2.new(0, 200, 0, 250)
config_frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
config_frame.BorderSizePixel = 0
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
config_layout.HorizontalFlex = Enum.UIFlexAlignment.None
config_layout.VerticalFlex = Enum.UIFlexAlignment.None

make_draggable(aim_button,true,true)
make_draggable(config_frame,true,true)
make_draggable(config_toggle,true,true)
adjust_layout(config_frame,false,true)

local create_config_button = function(name, variable, callback)
	local config__main = Instance.new("Frame")
	local config__title = Instance.new("TextLabel")
	local config__editable :TextButton
	if typeof(variable) == "boolean" then
		config__editable = Instance.new("TextButton")
	elseif typeof(variable) == "number" then
		config__editable = Instance.new("TextBox")
	elseif typeof(variable) == "string" then
		config__editable = Instance.new("TextBox")
	else
		config__editable = Instance.new("TextLabel") -- fallback to read-only
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
	config__editable.TextXAlignment = Enum.TextXAlignment.Left
	if config__editable:IsA("TextBox") then
		config__editable.PlaceholderText = tostring(variable)
		config__editable.FocusLost:Connect(function(enterpress)
			local newtxt = config__editable.Text
			if newtxt and newtxt ~= "" and (callback and typeof(callback) == "function") then
				callback(newtxt)
			end
		end)
	elseif config__editable:IsA("TextButton") then
		config__editable.MouseButton1Click:Connect(function()
			if (callback and typeof(callback) == "function") then
				callback()
			end
		end)
	end
end

local auto_aim_conn = nil
local lerpSpeed = 16

local auto_aim_function = function()
	if auto_aim_conn then
		auto_aim_conn:Disconnect()
		auto_aim_conn = nil
	else
		auto_aim_conn = RunService.RenderStepped:Connect(function(DT)
			local camCF = cam.CFrame
			local selfChar = SELF.Character
			if not selfChar or not cam then return end
			local potentialTargets = {}
			for _, OTHER in ipairs(Players:GetPlayers()) do
				if OTHER ~= SELF and OTHER.Character then
					table.insert(potentialTargets, OTHER.Character)
				end
			end
			for _, model in ipairs(workspace:GetDescendants()) do
				if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
					if not Players:GetPlayerFromCharacter(model) and model ~= selfChar then
						table.insert(potentialTargets, model)
					end
				end
			end
			local closest, shortest = nil, math.huge
			for _, char in ipairs(potentialTargets) do
				local head = char:FindFirstChild("Head")
				if head then
					local dist = (head.Position - camCF.Position).Magnitude
					if dist < shortest then
						shortest = dist
						closest = head
					end
				end
			end
			if closest then
				local head = closest
				local targetVelocity = Vector3.zero
				local root = head.Parent:FindFirstChild("HumanoidRootPart")
				if root then
					targetVelocity = root.Velocity
				elseif head:IsA("BasePart") then
					targetVelocity = head.Velocity
				end
				local distance = (head.Position - camCF.Position).Magnitude
				local predictionTime = math.clamp(distance / 150, 0.05, 0.25)
				local predictedPos = head.Position + targetVelocity * predictionTime
				local dir = (predictedPos - camCF.Position).Unit
				local desiredCF = CFrame.new(camCF.Position, camCF.Position + dir)
				cam.CFrame = camCF:Lerp(desiredCF, math.clamp(lerpSpeed * DT, 0, 1))
			end
		end)
	end
end

create_config_button("Snap speed", lerpSpeed, function(new_value)
	lerpSpeed = tonumber(new_value)
end)

aim_button.Activated:Connect(auto_aim_function)
config_toggle.Activated:Connect(function()
	if next(currently_dragged) then return end
	config_frame.Visible = not config_frame.Visible
end)
