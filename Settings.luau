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
local gameplayPausedState = true
local purchasePromptsState = true

local function loadSettings()
	if isfile and isfile(settingsFile) then
		local s, r = pcall(function()
			return httpService:JSONDecode(readfile(settingsFile))
		end)
		if s and type(r) == "table" then
			if r.AutoJump ~= nil then autoJumpEnabled = r.AutoJump end
			if r.SemiTransparency ~= nil then semiTransparencyEnabled = r.SemiTransparency end
			if r.GameplayPaused ~= nil then gameplayPausedState = r.GameplayPaused end
			if r.PurchasePrompts ~= nil then purchasePromptsState = r.PurchasePrompts end
		end
	end
end

local function saveSettings()
	if writefile then
		pcall(function()
			writefile(settingsFile, httpService:JSONEncode({
				AutoJump = autoJumpEnabled,
				SemiTransparency = semiTransparencyEnabled,
				GameplayPaused = gameplayPausedState,
				PurchasePrompts = purchasePromptsState
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

if localPlayer.Character then
	task.spawn(applyAutoJumpToHumanoid, localPlayer.Character)
	applyTransAll = setupCharacterTransparency(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(function(char)
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
				sel1.Text = config.TextOn or "On" 
				sel1.TextXAlignment = Enum.TextXAlignment.Center
				sel1.AnchorPoint = Vector2.new(0.5, 0.5)
				sel1.Size = UDim2.new(1, 0, 1, 0)
				sel1.Visible = true
			end
			if sel2:IsA("TextLabel") then 
				sel2.Text = config.TextOff or "Off" 
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
				local fbFrame = page:FindFirstChild("Give Translation FeedbackFrame")
				if fbFrame and not page:FindFirstChild("Open ConsoleFrame") then
					local cloneFb = fbFrame:Clone()
					cloneFb.Name = "Open ConsoleFrame"
					local lblFb = cloneFb:FindFirstChild("Give Translation FeedbackLabel")
					if lblFb then
						lblFb.Text = "Open Dev Console"
					end
					local btnFb = cloneFb:FindFirstChild("toggleFeedbackModeButtonButton")
					if btnFb then
						local txtFb = btnFb:FindFirstChild("toggleFeedbackModeButtonTextLabel")
						if txtFb then
							txtFb.Text = "Open"
						end
						local handlerFb = Instance.new("TextButton")
						handlerFb.Size = UDim2.new(1, 0, 1, 0)
						handlerFb.BackgroundTransparency = 1
						handlerFb.Text = ""
						handlerFb.ZIndex = 10
						handlerFb.Parent = btnFb
						handlerFb.MouseButton1Click:Connect(function()
							if keypress and keyrelease then
								keypress(0x78)
								task.wait(0.05)
								keyrelease(0x78)
							end
						end)
					end
					cloneFb.Parent = page
				end

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
						FrameName = "Gameplay PausedFrame", RowName = "GameplayPausedRow", 
						LabelName = "GameplayPausedLabel", DescName = "GameplayPausedDesc",
						LabelText = "Gameplay Paused", DescText = "Control network paused",
						TextOn = "Show", TextOff = "Hide",
						GetState = function() return gameplayPausedState end,
						ToggleState = function() 
							gameplayPausedState = not gameplayPausedState
							saveSettings()
							if not gameplayPausedState then
								pcall(function()
									game:GetService("CoreGui").RobloxGui["CoreScripts/NetworkPause"]:Destroy()
								end)
							end
						end
					})

					createToggle(page, badgesFrame, {
						FrameName = "Purchase PromptsFrame", RowName = "PurchasePromptsRow", 
						LabelName = "PurchasePromptsLabel", DescName = "PurchasePromptsDesc",
						LabelText = "Purchase Prompts", DescText = "Show or hide annoying purchase prompts",
						TextOn = "Show", TextOff = "Hide",
						GetState = function() return purchasePromptsState end,
						ToggleState = function() 
							purchasePromptsState = not purchasePromptsState
							saveSettings()
							if not purchasePromptsState then
								pcall(function()
									game.CoreGui.PurchasePromptApp.Enabled = false
									local FoundationOverlay = game.CoreGui:FindFirstChild("FoundationOverlay")
									if not FoundationOverlay then
										local connection
										connection = game.CoreGui.ChildAdded:Connect(function(ins)
											if ins.Name == "FoundationOverlay" then
												ins.Enabled = false
											end
										end)
									else
										game.CoreGui.FoundationOverlay.Enabled = false
									end
								end)
							else
								pcall(function()
									game.CoreGui.PurchasePromptApp.Enabled = true
									local FoundationOverlay = game.CoreGui:FindFirstChild("FoundationOverlay")
									if not FoundationOverlay then
										local connection
										connection = game.CoreGui.ChildAdded:Connect(function(ins)
											if ins.Name == "FoundationOverlay" then
												ins.Enabled = true
											end
										end)
									else
										game.CoreGui.FoundationOverlay.Enabled = true
									end
								end)
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




local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local path = {
    "SettingsClippingShield",
    "SettingsShield",
    "MenuContainer",
    "Page",
    "PageViewClipper",
    "PageView",
    "PageViewInnerFrame",
    "LeaveGamePage",
    "LeaveButtonsContainer",
    "LeaveButtonsContainer",
    "LeaveGameButton"
}

local function startWait()
    task.spawn(function()
        local current = CoreGui:WaitForChild("RobloxGui")
        for i = 1, #path do
            current = current:WaitForChild(path[i])
        end
        
        if current.Parent:FindFirstChild("CustomRejoinButton") then
            current.Parent.CustomRejoinButton:Destroy()
        end
        
        local clone = current:Clone()
        clone.Name = "CustomRejoinButton"
        clone.Parent = current.Parent
        
        local textLabel = clone:FindFirstChild("text", true) or clone:FindFirstChildWhichIsA("TextLabel", true)
        if textLabel then
            pcall(function() textLabel.Text = "Rejoin" end)
        end
        
        local clickConn = clone.MouseButton1Click:Connect(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
        end)
        
        local ancestryConn
        ancestryConn = current.AncestryChanged:Connect(function(_, newParent)
            if not newParent then
                ancestryConn:Disconnect()
                clickConn:Disconnect()
                if clone and clone.Parent then
                    clone:Destroy()
                end
                startWait()
            end
        end)
    end)
end

startWait()




local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local loopConnection = nil
local processedRows = {}

local currentViewTarget = nil
local playerViewIcons = {}
local targetCharAddedConn = nil
local playerRemovingConn = nil
local localPlayerCharAddedConn = nil

local SearchTable = {""}

local stopViewGui = Instance.new("ScreenGui")
stopViewGui.Name = "Stop View Button"
stopViewGui.ResetOnSpawn = false
stopViewGui.DisplayOrder = 9e9
stopViewGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local stopViewBtn = Instance.new("TextButton")
stopViewBtn.Size = UDim2.new(0, 30, 0, 30)
stopViewBtn.Position = UDim2.new(0.5, -15, 0.75, -15)
stopViewBtn.BackgroundColor3 = Color3.new(0, 0, 0)
stopViewBtn.TextColor3 = Color3.new(1, 1, 1)
stopViewBtn.Text = "X"
stopViewBtn.TextScaled = true
stopViewBtn.Visible = false
stopViewBtn.Parent = stopViewGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = stopViewBtn

local function stopViewing()
	if targetCharAddedConn then
		targetCharAddedConn:Disconnect()
		targetCharAddedConn = nil
	end
	if playerRemovingConn then
		playerRemovingConn:Disconnect()
		playerRemovingConn = nil
	end
	if localPlayerCharAddedConn then
		localPlayerCharAddedConn:Disconnect()
		localPlayerCharAddedConn = nil
	end
	
	if currentViewTarget and playerViewIcons[currentViewTarget] then
		playerViewIcons[currentViewTarget].Image = "rbxassetid://13321848320"
	end
	
	currentViewTarget = nil
	stopViewBtn.Visible = false
	
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then
			Camera.CameraSubject = hum
		end
	end
end

stopViewBtn.Activated:Connect(stopViewing)

local function getDescendantByName(parent, name)
	for _, child in ipairs(parent:GetDescendants()) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

local function findFirstClass(parent, className)
	if parent:IsA(className) then return parent end
	for _, child in ipairs(parent:GetDescendants()) do
		if child:IsA(className) then return child end
	end
	return nil
end

local function getPeopleList()
	local current = CoreGui
	local path = {"RobloxGui", "SettingsClippingShield", "SettingsShield", "MenuContainer", "Page", "PageViewClipper", "PageView", "PageViewInnerFrame", "peoplepage", "FocusRoot", "PeopleReactView", "People", "PeopleList"}
	for _, name in ipairs(path) do
		current = current:FindFirstChild(name)
		if not current then return nil end
	end
	return current
end

local function getCoreButtonRow()
	local current = CoreGui
	local path = {"RobloxGui", "SettingsClippingShield", "SettingsShield", "MenuContainer", "Page", "PageViewClipper", "PageView", "PageViewInnerFrame", "peoplepage", "FocusRoot", "PeopleReactView", "PeopleHeader", "CoreButtonRow"}
	for _, name in ipairs(path) do
		current = current:FindFirstChild(name)
		if not current then return nil end
	end
	return current
end

local function getLabel(row, labelName)
	local rc = row:FindFirstChild("RowContent")
	if rc then
		local lc = rc:FindFirstChild("LeftContent")
		if lc then
			local nc = lc:FindFirstChild("NameContainer")
			if nc then
				local lbl = nc:FindFirstChild(labelName)
				if lbl then return lbl end
			end
		end
	end
	return getDescendantByName(row, labelName)
end

local function getInspect(row)
	local rc = row:FindFirstChild("RowContent")
	if rc then
		local rtc = rc:FindFirstChild("RightContent")
		if rtc then
			local pbr = rtc:FindFirstChild("PersonButtonRow")
			if pbr then
				local insp = pbr:FindFirstChild("inspect")
				if insp then return insp, pbr end
			end
		end
	end
	local insp = getDescendantByName(row, "inspect")
	if insp then return insp, insp.Parent end
	return nil, nil
end

local function processRow(row)
	local displayNameContainer = getLabel(row, "DisplayName")
	local userNameContainer = getLabel(row, "UserName")

	if not displayNameContainer or not userNameContainer then return end

	local displayLabel = findFirstClass(displayNameContainer, "TextLabel")
	local userLabel = findFirstClass(userNameContainer, "TextLabel")

	if not displayLabel or not userLabel then return end

	local rawName = string.gsub(userLabel.Text, "^@", "")
	local player = Players:FindFirstChild(rawName)

	if not player then return end

	if player.Team then
		displayLabel.TextColor3 = player.TeamColor.Color
	end

	if processedRows[row] then return end
	processedRows[row] = true

	if player == LocalPlayer then return end

	local inspectBtn, buttonRow = getInspect(row)
	if not inspectBtn or not buttonRow then return end

	local viewBtn = inspectBtn:Clone()
	viewBtn.Name = "View"
	viewBtn.Parent = buttonRow

	for _, child in ipairs(viewBtn:GetDescendants()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local viewIcon = findFirstClass(viewBtn, "ImageLabel") or findFirstClass(viewBtn, "ImageButton")
	if viewIcon then
		playerViewIcons[rawName] = viewIcon
		if currentViewTarget == rawName then
			viewIcon.Image = "rbxassetid://125716871945612"
		else
			viewIcon.Image = "rbxassetid://13321848320"
		end
		viewIcon.ImageRectSize = Vector2.new(0, 0)
		viewIcon.ImageRectOffset = Vector2.new(0, 0)
	end

	local function onViewActivate()
		if currentViewTarget == rawName then
			stopViewing()
		else
			stopViewing()
			
			currentViewTarget = rawName
			if viewIcon then
				viewIcon.Image = "rbxassetid://125716871945612"
			end
			stopViewBtn.Visible = true
			
			local function attachCamera(char)
				if char then
					local head = char:WaitForChild("Head", 5)
					if head then
						Camera.CameraSubject = head
					end
				end
			end
			
			attachCamera(player.Character)
			
			targetCharAddedConn = player.CharacterAdded:Connect(attachCamera)
			
			localPlayerCharAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
				newChar:WaitForChild("Humanoid", 5)
				if currentViewTarget == rawName then
					attachCamera(player.Character)
				end
			end)
			
			playerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
				if leavingPlayer == player then
					stopViewing()
				end
			end)
		end
	end

	local viewHandler = Instance.new("ImageButton")
	viewHandler.Name = "ViewClickHandler"
	viewHandler.Size = UDim2.new(1, 0, 1, 0)
	viewHandler.Position = UDim2.new(0, 0, 0, 0)
	viewHandler.BackgroundTransparency = 1
	viewHandler.Image = ""
	viewHandler.ZIndex = 100
	viewHandler.Active = true
	viewHandler.Parent = viewBtn
	viewHandler.Activated:Connect(onViewActivate)

	local tpBtn = inspectBtn:Clone()
	tpBtn.Name = "Teleport"
	tpBtn.Parent = buttonRow

	for _, child in ipairs(tpBtn:GetDescendants()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local tpIcon = findFirstClass(tpBtn, "ImageLabel") or findFirstClass(tpBtn, "ImageButton")
	if tpIcon then
		tpIcon.Image = "rbxassetid://6723742952"
		tpIcon.ImageRectSize = Vector2.new(0, 0)
		tpIcon.ImageRectOffset = Vector2.new(0, 0)
	end

	local function onTpActivate()
		local tChar = player.Character
		local lChar = LocalPlayer.Character
		if tChar and lChar then
			local tRoot = tChar:FindFirstChild("HumanoidRootPart")
			local lRoot = lChar:FindFirstChild("HumanoidRootPart")
			if tRoot and lRoot then
				lRoot.CFrame = tRoot.CFrame
			end
		end
	end

	local tpHandler = Instance.new("ImageButton")
	tpHandler.Name = "TpClickHandler"
	tpHandler.Size = UDim2.new(1, 0, 1, 0)
	tpHandler.Position = UDim2.new(0, 0, 0, 0)
	tpHandler.BackgroundTransparency = 1
	tpHandler.Image = ""
	tpHandler.ZIndex = 100
	tpHandler.Active = true
	tpHandler.Parent = tpBtn
	tpHandler.Activated:Connect(onTpActivate)
end

GuiService.MenuOpened:Connect(function()
	if not loopConnection then
		loopConnection = RunService.RenderStepped:Connect(function()
			local cbr = getCoreButtonRow()
			local currentSearchBox = nil
			
			if cbr then
				local ps = cbr:FindFirstChild("PeopleSearch")
				if not ps then
					local inviteFriends = cbr:FindFirstChild("inviteFriends")
					if inviteFriends then
						ps = inviteFriends:Clone()
						ps.Name = "PeopleSearch"
						for _, c in ipairs(ps:GetChildren()) do
							c:Destroy()
						end
						
						local tb = Instance.new("TextBox")
						tb.Size = UDim2.new(1, 0, 1, 0)
						tb.Position = UDim2.new(0, 0, 0, 0)
						tb.BackgroundTransparency = 1
						tb.ClearTextOnFocus = false
						tb.Text = SearchTable[1] or ""
						tb.Interactable = true
						tb.PlaceholderText = "Put display/real names(e.g Player123), or teams(e.g Swat)"
						tb.TextScaled = true
						tb.TextColor3 = Color3.new(1, 1, 1)
						tb.Parent = ps
						
						tb:GetPropertyChangedSignal("Text"):Connect(function()
							SearchTable[1] = tb.Text
						end)
						
						ps.Parent = cbr
						currentSearchBox = tb
					end
				else
					currentSearchBox = ps:FindFirstChildOfClass("TextBox")
				end
			end
			
			local filterText = currentSearchBox and string.lower(currentSearchBox.Text) or ""
			local peopleList = getPeopleList()
			
			if peopleList then
				for _, child in ipairs(peopleList:GetChildren()) do
					if child.Name == "PersonRow" then
						processRow(child)
						
						if filterText == "" then
							child.Visible = true
						else
							local match = false
							local uContainer = getLabel(child, "UserName")
							local dContainer = getLabel(child, "DisplayName")
							local rName = ""
							
							if uContainer then
								local tl = findFirstClass(uContainer, "TextLabel")
								if tl then
									rName = string.gsub(tl.Text, "^@", "")
									if string.find(string.lower(rName), filterText, 1, true) then
										match = true
									end
								end
							end
							
							if not match and dContainer then
								local tl = findFirstClass(dContainer, "TextLabel")
								if tl then
									if string.find(string.lower(tl.Text), filterText, 1, true) then
										match = true
									end
								end
							end
							
							if not match and rName ~= "" then
								local pObj = Players:FindFirstChild(rName)
								if pObj and pObj.Team then
									if string.find(string.lower(pObj.Team.Name), filterText, 1, true) then
										match = true
									end
								end
							end
							
							child.Visible = match
						end
					end
				end
			end
		end)
	end
end)

GuiService.MenuClosed:Connect(function()
	if loopConnection then
		loopConnection:Disconnect()
		loopConnection = nil
	end
	processedRows = {}
end)



if game.PlaceId == 9391468976 then
    return
end

local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local bindable = Instance.new("BindableEvent")

bindable.Event:Connect(function()
    game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
end)

local coreGuiMetamethod = getrawmetatable(StarterGui)
setreadonly(coreGuiMetamethod, false)

local oldSetCore
oldSetCore = hookfunction(StarterGui.SetCore, function(self, coreName, ...)
    local args = {...}
    if not checkcaller() and (coreName == "ResetButtonCallback" or args[1] == "ResetButtonCallback") then
        return
    end
    return oldSetCore(self, coreName, ...)
end)

setreadonly(coreGuiMetamethod, true)

task.spawn(function()
    pcall(function()
        StarterGui:SetCore("ResetButtonCallback", bindable)
    end)
end)
