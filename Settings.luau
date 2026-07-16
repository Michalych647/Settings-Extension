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

local function createStat(name, iconId)
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

	frame.Parent = mainFrame
	table.insert(statFrames, frame)
	
	return text
end

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

local function loadSettings()
	if isfile and isfile(settingsFile) then
		local s, r = pcall(function()
			return httpService:JSONDecode(readfile(settingsFile))
		end)
		if s and type(r) == "table" and r.AutoJump ~= nil then
			autoJumpEnabled = r.AutoJump
		end
	end
end

local function saveSettings()
	if writefile then
		pcall(function()
			writefile(settingsFile, httpService:JSONEncode({AutoJump = autoJumpEnabled}))
		end)
	end
end

loadSettings()

local autoJumpConnection = nil

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

if localPlayer.Character then
	task.spawn(applyAutoJumpToHumanoid, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(applyAutoJumpToHumanoid)

local menuIsOpen = false
local injectionThread = nil

local function updateToggleVisuals(sel1, sel2, animate)
	local p1, p2
	local t1, t2
	if autoJumpEnabled then
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
		local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		tweenService:Create(sel1, ti, {Position = p1, TextTransparency = t1}):Play()
		tweenService:Create(sel2, ti, {Position = p2, TextTransparency = t2}):Play()
	else
		sel1.Position = p1
		sel2.Position = p2
		sel1.TextTransparency = t1
		sel2.TextTransparency = t2
	end
end

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
					if not page:FindFirstChild("Auto JumpFrame") then
						local clone = badgesFrame:Clone()
						clone.Name = "Auto JumpFrame"
						
						local row = clone:FindFirstChild("My BadgesRowLabelAndDescriptionFrame")
						if row then
							row.Name = "AutoJumpRowLabelAndDescriptionFrame"
							
							local label = row:FindFirstChild("My BadgesLabel")
							if label then
								label.Name = "Auto JumpLabel"
								if label:IsA("TextLabel") then label.Text = "Auto Jump" end
							end
							
							local desc = row:FindFirstChild("My BadgesDescription")
							if desc then
								desc.Name = "Auto JumpDescription"
								if desc:IsA("TextLabel") then desc.Text = "Toogle Auto Jumping" end
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
							clickHandler.Name = "AutoJumpClickHandler"
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
								
								updateToggleVisuals(sel1, sel2, false)
								
								clickHandler.MouseButton1Click:Connect(function()
									autoJumpEnabled = not autoJumpEnabled
									saveSettings()
									if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
										localPlayer.Character.Humanoid.AutoJumpEnabled = autoJumpEnabled
									end
									updateToggleVisuals(sel1, sel2, true)
								end)
							end
						end
						
						clone.Parent = page
					end
					break
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
local RunService = game:GetService("RunService")
local bindable = Instance.new("BindableEvent")

bindable.Event:Connect(function()
    local player = game:GetService("Players").LocalPlayer
local character = player.Character

if character then
    local neck = character:FindFirstChild("Neck", true) 
    
    if neck and neck:IsA("Motor6D") then
        neck:Destroy()
    end
end 
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
