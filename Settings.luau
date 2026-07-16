if not game:IsLoaded() then
    game.Loaded:Wait()
end

local uniqueKey = "Script_" .. tostring(math.random(100000, 999999)) .. "_" .. tostring(tick())

if getgenv()[uniqueKey] then return end
getgenv()[uniqueKey] = true

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local stats = game:GetService("Stats")
local guiService = game:GetService("GuiService")
local coreGui = game:GetService("CoreGui")
local httpService = game:GetService("HttpService")
local tweenService = game:GetService("TweenService")

local localPlayer = players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MenuStatsGui"
screenGui.DisplayOrder = 9e9
screenGui.Enabled = false
screenGui.Parent = coreGui

local mainFrame = Instance.new("Frame")
mainFrame.BackgroundTransparency = 1
mainFrame.Size = UDim2.new(0, 0, 0, 36)
mainFrame.AnchorPoint = Vector2.new(1, 1)
mainFrame.AutomaticSize = Enum.AutomaticSize.X
mainFrame.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = mainFrame

local statFrames = {}

local function createBaseStatFrame(name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 0, 1, 0)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
	frame.BackgroundTransparency = 0.5
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = frame

	local layout2 = Instance.new("UIListLayout")
	layout2.FillDirection = Enum.FillDirection.Horizontal
	layout2.VerticalAlignment = Enum.VerticalAlignment.Center
	layout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout2.Padding = UDim.new(0, 6)
	layout2.Parent = frame

	frame.Parent = mainFrame
	table.insert(statFrames, frame)
	return frame
end

local function createStat(name, iconId)
	local frame = createBaseStatFrame(name)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 20, 0, 20)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://" .. iconId
	icon.Parent = frame

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(0, 0, 0, 20)
	text.AutomaticSize = Enum.AutomaticSize.X
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.BuilderSansBold
	text.TextSize = 16
	text.Text = ""
	text.Parent = frame
	return text
end

local function setupPlaceCounter(frame)
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 20, 0, 20)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://11894535915"
	icon.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 0
	scroll.ClipsDescendants = true
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.Parent = frame
	
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.BuilderSansBold
	text.TextSize = 16
	text.Text = ""
	text.Parent = scroll

	task.spawn(function()
		local s, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
		local pName = (s and info and info.Name) and info.Name or game.Name
		local tService = game:GetService("TextService")
		local pBounds = tService:GetTextSize(pName, 16, Enum.Font.BuilderSansBold, Vector2.new(9999, 20))
		local maxBounds = tService:GetTextSize("123456789012345", 16, Enum.Font.BuilderSansBold, Vector2.new(9999, 20))
		
		text.Text = pName
		text.Size = UDim2.new(0, pBounds.X, 0, 20)
		scroll.CanvasSize = UDim2.new(0, pBounds.X, 0, 20)
		scroll.Size = UDim2.new(0, math.min(pBounds.X, maxBounds.X), 0, 20)
	end)
end

local placeFrame = createBaseStatFrame("PlaceName")
setupPlaceCounter(placeFrame)

local clockText = createStat("Clock", "129358516003681")
local fpsText = createStat("FPS", "15914066897")
local pingText = createStat("Ping", "113948757329652")
local playersText = createStat("Players", "118410078119588")

local renderConnection = nil
local lastTime = 0
local frameCount = 0

local function getPing()
	local success, pingStr = pcall(function()
		return stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
	end)
	if success and pingStr then
		local pingNum = pingStr:match("%d+%.?%d*")
		return tonumber(pingNum) or 0
	end
	return 0
end

local settingsFile = "SettingsConfigurationLOLO.json"
local autoJumpEnabled = true
local semiTransparencyEnabled = false
local fpsCapUnlocked = false
local fpsUnlockedOnce = false

local function applyFpsUnlock()
	if fpsCapUnlocked and not fpsUnlockedOnce then
		fpsUnlockedOnce = true
		if setfpscap then setfpscap(999) end
	end
end

local function loadSettings()
	if isfile and isfile(settingsFile) then
		local s, r = pcall(function()
			return httpService:JSONDecode(readfile(settingsFile))
		end)
		if s and type(r) == "table" then
			if r.AutoJump ~= nil then autoJumpEnabled = r.AutoJump end
			if r.SemiTransparency ~= nil then semiTransparencyEnabled = r.SemiTransparency end
			if r.FpsCapUnlocked ~= nil then fpsCapUnlocked = r.FpsCapUnlocked end
		end
	end
	applyFpsUnlock()
end

local function saveSettings()
	if writefile then
		pcall(function()
			writefile(settingsFile, httpService:JSONEncode({
				AutoJump = autoJumpEnabled,
				SemiTransparency = semiTransparencyEnabled,
				FpsCapUnlocked = fpsCapUnlocked
			}))
		end)
	end
end

loadSettings()

local autoJumpConnection = nil
local applyTransAll = nil
local transparencyConn = nil

local function applyAutoJumpToHumanoid(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	if autoJumpConnection then
		autoJumpConnection:Disconnect()
	end
	
	humanoid.AutoJumpEnabled = autoJumpEnabled
	
	autoJumpConnection = humanoid:GetPropertyChangedSignal("AutoJumpEnabled"):Connect(function()
		if humanoid.AutoJumpEnabled ~= autoJumpEnabled then
			humanoid.AutoJumpEnabled = autoJumpEnabled
		end
	end)
end

local function setupCharacterTransparency(char)
	if transparencyConn then transparencyConn:Disconnect() end
	local function process(p, state)
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			if state then
				p.Transparency = 0.5
			elseif p.Transparency == 0.5 then
				p.Transparency = 0
			end
		end
	end
	local function applyAll(state)
		for _, p in ipairs(char:GetDescendants()) do process(p, state) end
	end
	
	applyAll(semiTransparencyEnabled)
	
	transparencyConn = char.DescendantAdded:Connect(function(p)
		task.wait()
		if semiTransparencyEnabled then process(p, true) end
	end)
	
	return applyAll
end

local desyncActive = false
local phantomMarker = nil
local cameraPart = nil

local function disableDesync()
	desyncActive = false
	if phantomMarker then
		phantomMarker:Destroy()
		phantomMarker = nil
	end
	if cameraPart then
		cameraPart:Destroy()
		cameraPart = nil
	end
	local camera = workspace.CurrentCamera
	local char = localPlayer.Character
	if camera and char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function enableDesync()
	if desyncActive then return end
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	desyncActive = true

	phantomMarker = Instance.new("Part")
	phantomMarker.Size = Vector3.new(2, 2, 1)
	phantomMarker.Color = Color3.fromRGB(255, 0, 0)
	phantomMarker.CanCollide = false
	phantomMarker.Anchored = true
	phantomMarker.Transparency = 0.5
	phantomMarker.CFrame = root.CFrame
	phantomMarker.Parent = workspace

	cameraPart = Instance.new("Part")
	cameraPart.Size = Vector3.new(1, 1, 1)
	cameraPart.Transparency = 1
	cameraPart.CanCollide = false
	cameraPart.Anchored = true
	cameraPart.Parent = workspace
end

runService.Heartbeat:Connect(function()
	if desyncActive then
		local char = localPlayer.Character
		if not char then
			disableDesync()
			return
		end
		local root = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		
		if root and head and phantomMarker and cameraPart then
			cameraPart.CFrame = head.CFrame
			
			local fakeCFrame = phantomMarker.CFrame
			local oldCFrame = root.CFrame
			
			root.CFrame = fakeCFrame
			runService.RenderStepped:Wait()
			if root.Parent then
				root.CFrame = oldCFrame
			end
		else
			disableDesync()
		end
	end
end)

runService.RenderStepped:Connect(function()
	if desyncActive and cameraPart then
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraSubject = cameraPart
		end
	end
end)

if localPlayer.Character then
	task.spawn(applyAutoJumpToHumanoid, localPlayer.Character)
	applyTransAll = setupCharacterTransparency(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(function(char)
	if desyncActive then
		disableDesync()
	end
	applyAutoJumpToHumanoid(char)
	applyTransAll = setupCharacterTransparency(char)
end)

local menuIsOpen = false
local injectionThread = nil

local function startLogging()
	if renderConnection then return end
	
	lastTime = tick()
	frameCount = 0
	clockText.Text = os.date("%H:%M:%S")
	fpsText.Text = "0"
	pingText.Text = "0ms"
	playersText.Text = tostring(#players:GetPlayers())
	
	screenGui.Enabled = true
	
	renderConnection = runService.RenderStepped:Connect(function()
		frameCount = frameCount + 1
		local now = tick()
		
		clockText.Text = os.date("%H:%M:%S")
		
		if now - lastTime >= 1 then
			local fps = frameCount / (now - lastTime)
			local ping = getPing()
			local plrCount = #players:GetPlayers()
			
			fpsText.Text = string.format("%.0f", fps)
			pingText.Text = string.format("%dms", ping)
			playersText.Text = tostring(plrCount)
			
			frameCount = 0
			lastTime = now
		end
		
		local s, hBar = pcall(function()
			return coreGui.RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer.Page.HubBar
		end)
		
		if s and hBar then
			local pos = hBar.AbsolutePosition
			local size = hBar.AbsoluteSize
			mainFrame.Position = UDim2.new(0, pos.X + size.X, 0, pos.Y - 12)
		end
	end)
end

local function stopLogging()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	screenGui.Enabled = false
end

local function createToggle(page, badgesFrame, config)
	if page:FindFirstChild(config.FrameName) then return end
	
	local clone = badgesFrame:Clone()
	clone.Name = config.FrameName
	
	local row = clone:FindFirstChild("My BadgesRowLabelAndDescriptionFrame")
	if row then
		row.Name = config.RowName
		
		local label = row:FindFirstChild("My BadgesLabel")
		if label then
			label.Name = config.LabelName
			if label:IsA("TextLabel") then label.Text = config.LabelText end
		end
		
		local desc = row:FindFirstChild("My BadgesDescription")
		if desc then
			desc.Name = config.DescName
			if desc:IsA("TextLabel") then desc.Text = config.DescText end
		end
	end
	
	local selector = clone:FindFirstChild("Selector", true)
	if selector then
		local removeList = {"AutoSelectButton"}
		for _, v in ipairs(removeList) do
			local child = selector:FindFirstChild(v)
			if child then child:Destroy() end
		end
		
		local clickHandler = Instance.new("TextButton")
		clickHandler.Name = config.HandlerName or "ClickHandler"
		clickHandler.Size = UDim2.new(1, 0, 1, 0)
		clickHandler.BackgroundTransparency = 1
		clickHandler.Text = ""
		clickHandler.ZIndex = 10
		clickHandler.Parent = selector
		
		local sel1 = selector:FindFirstChild("Selection1")
		local sel2 = selector:FindFirstChild("Selection2")
		
		if sel1 and sel2 then
			if sel1:IsA("TextLabel") then 
				sel1.Text = "On" 
				sel1.TextXAlignment = Enum.TextXAlignment.Center
				sel1.AnchorPoint = Vector2.new(0.5, 0.5)
				sel1.Size = UDim2.new(1, 0, 1, 0)
				sel1.Visible = true
			end
			if sel2:IsA("TextLabel") then 
				sel2.Text = "Off" 
				sel2.TextXAlignment = Enum.TextXAlignment.Center
				sel2.AnchorPoint = Vector2.new(0.5, 0.5)
				sel2.Size = UDim2.new(1, 0, 1, 0)
				sel2.Visible = true
			end
			
			local function updateVis(animate)
				local isEnabled = config.GetState()
				local p1, p2
				local t1, t2
				if isEnabled then
					p1 = UDim2.new(0.5, 0, 0.5, 0)
					p2 = UDim2.new(0.5, 20, 0.5, 0)
					t1 = 0
					t2 = 1
				else
					p1 = UDim2.new(0.5, -20, 0.5, 0)
					p2 = UDim2.new(0.5, 0, 0.5, 0)
					t1 = 1
					t2 = 0
				end
				
				if animate then
					local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					tweenService:Create(sel1, ti, {Position = p1, TextTransparency = t1}):Play()
					tweenService:Create(sel2, ti, {Position = p2, TextTransparency = t2}):Play()
				else
					sel1.Position = p1
					sel2.Position = p2
					sel1.TextTransparency = t1
					sel2.TextTransparency = t2
				end
			end
			
			updateVis(false)
			
			clickHandler.MouseButton1Click:Connect(function()
				config.ToggleState()
				updateVis(true)
			end)
		end
	end
	
	clone.Parent = page
end

guiService.MenuOpened:Connect(function()
	menuIsOpen = true
	startLogging()
	
	if injectionThread then task.cancel(injectionThread) end
	
	injectionThread = task.spawn(function()
		while menuIsOpen do
			local s, page = pcall(function()
				return coreGui.RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer.Page.PageViewClipper.PageView.PageViewInnerFrame.Page
			end)
			
			if s and page then
				local badgesFrame = page:FindFirstChild("My BadgesFrame")
				if badgesFrame then
					createToggle(page, badgesFrame, {
						FrameName = "Auto JumpFrame", RowName = "AutoJumpRowLabelAndDescriptionFrame", 
						LabelName = "Auto JumpLabel", DescName = "Auto JumpDescription",
						LabelText = "Auto Jump", DescText = "Toogle Auto Jumping",
						GetState = function() return autoJumpEnabled end,
						ToggleState = function() 
							autoJumpEnabled = not autoJumpEnabled
							saveSettings()
							if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
								localPlayer.Character.Humanoid.AutoJumpEnabled = autoJumpEnabled
							end
						end
					})

					createToggle(page, badgesFrame, {
						FrameName = "SemiTransparencyFrame", RowName = "SemiTransRowLabelAndDescriptionFrame", 
						LabelName = "SemiTransLabel", DescName = "SemiTransDescription",
						LabelText = "Semi-Transparency Parts", DescText = "Character parts, become semi-transparency",
						GetState = function() return semiTransparencyEnabled end,
						ToggleState = function() 
							semiTransparencyEnabled = not semiTransparencyEnabled
							saveSettings()
							if applyTransAll then applyTransAll(semiTransparencyEnabled) end
						end
					})

					createToggle(page, badgesFrame, {
						FrameName = "FpsCapFrame", RowName = "FpsCapRowLabelAndDescriptionFrame", 
						LabelName = "FpsCapLabel", DescName = "FpsCapDescription",
						LabelText = "Unlock Fps", DescText = "Unlock Unlimited FPS",
						GetState = function() return fpsCapUnlocked end,
						ToggleState = function() 
							fpsCapUnlocked = not fpsCapUnlocked
							saveSettings()
							applyFpsUnlock()
						end
					})
					
					createToggle(page, badgesFrame, {
						FrameName = "DesyncFrame", RowName = "DesyncRowLabelAndDescriptionFrame", 
						LabelName = "DesyncLabel", DescName = "DesyncDescription",
						LabelText = "Desync", DescText = "Turn on or off desync",
						GetState = function() return desyncActive end,
						ToggleState = function() 
							if desyncActive then
								disableDesync()
							else
								enableDesync()
							end
						end
					})
				end
			end
			task.wait(0.5)
		end
	end)
end)

guiService.MenuClosed:Connect(function()
	menuIsOpen = false
	stopLogging()
end)

if game.PlaceId == 9391468976 then
    return
end

local StarterGui = game:GetService("StarterGui")
local bindable = Instance.new("BindableEvent")

bindable.Event:Connect(function()
	game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if not checkcaller() and self == StarterGui and (method == "SetCore" or method == "setCore") and args[1] == "ResetButtonCallback" then
        return
    end
    return oldNamecall(self, ...)
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and self == StarterGui and (key == "SetCore" or key == "setCore") then
        return function(instance, ...)
            local args = {...}
            if args[1] == "ResetButtonCallback" then
                return
            end
            return oldIndex(instance, key)(instance, ...)
        end
    end
    return oldIndex(self, key)
end)

task.spawn(function()
    while true do
        pcall(function()
            StarterGui:SetCore("ResetButtonCallback", bindable)
        end)
        game:GetService("RunService").RenderStepped:Wait() 
    end
end)
