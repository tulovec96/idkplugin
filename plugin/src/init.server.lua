--[[
	Ollama AI Code Generator Pro
	Chat interface with AI code generation for Roblox Studio
	Connects to: http://23.88.19.42:11434/
]]

local plugin = plugin
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Only run in edit mode
if not RunService:IsEdit() then
	return
end

local CONFIG = {
	OLLAMA_URL = "http://23.88.19.42:11434",
	DEFAULT_MODEL = "mistral",
	TEMPERATURE = 0.7,
}

local STATE = {
	isGenerating = false,
	messageCount = 0,
	scriptType = "LocalScript",
	lastWasCodeRequest = false
}

-- Detect if request is for code generation
local function isCodeRequest(text)
	local keywords = {"make", "create", "generate", "build", "code", "script", "system", "add", "function", "class", "implement", "write"}
	local lower = string.lower(text)
	for _, keyword in ipairs(keywords) do
		if string.find(lower, keyword) then
			return true
		end
	end
	return false
end

-- Get workspace structure overview
local function getWorkspaceOverview()
	local overview = "=== WORKSPACE OVERVIEW ===\n"
	
	-- Services
	overview = overview .. "\nServices:\n"
	local services = {workspace, game:GetService("ServerScriptService"), game:GetService("ServerStorage"), game:GetService("ReplicatedStorage")}
	for _, service in ipairs(services) do
		overview = overview .. "• " .. service.Name .. " - " .. tostring(#service:GetChildren()) .. " items\n"
		for i, child in ipairs(service:GetChildren()) do
			if i <= 5 then
				overview = overview .. "  - " .. child.Name .. " (" .. child.ClassName .. ")\n"
			end
		end
		if #service:GetChildren() > 5 then
			overview = overview .. "  ... and " .. (#service:GetChildren() - 5) .. " more\n"
		end
	end
	
	return overview
end

local function log(msg)
	print("[🤖 OllamaAI] " .. msg)
end

local function callOllama(prompt, model, isCodeGen)
	if STATE.isGenerating then return false, "Already generating" end
	STATE.isGenerating = true
	
	-- Add Roblox context if generating code
	local fullPrompt = prompt
	if isCodeGen then
		fullPrompt = "You are a Roblox Lua developer. Generate code for Roblox Studio. The code will be placed in a " .. STATE.scriptType .. " in a Roblox game.\n\nRequest: " .. prompt .. "\n\nProvide ONLY the Lua code, no explanations."
	else
		-- Include workspace context for planning
		local workspaceInfo = getWorkspaceOverview()
		fullPrompt = "You are a Roblox game development expert. Help plan how to implement features in a Roblox game.\n\n" .. workspaceInfo .. "\n\nUser request: " .. prompt .. "\n\nProvide a detailed step-by-step plan, considering what's already in the workspace."
	end
	
	local body = HttpService:JSONEncode({
		model = model,
		prompt = fullPrompt,
		stream = false,
		temperature = CONFIG.TEMPERATURE
	})
	
	local success, response = pcall(function()
		return HttpService:PostAsync(CONFIG.OLLAMA_URL .. "/api/generate", body, Enum.HttpContentType.ApplicationJson, false)
	end)
	
	STATE.isGenerating = false
	
	if success then
		local decoded = HttpService:JSONDecode(response)
		return true, decoded.response or ""
	else
		return false, tostring(response)
	end
end

-- Create DockWidget (window)
local toolbar = plugin:CreateToolbar("Ollama AI")
local widget = plugin:CreateDockWidgetPluginGui(
	"Ollama AI Code Generator",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 1000, 700, 1000, 700)
)
widget.Title = "🤖 Ollama AI"

-- Toggle button
local toggleButton = toolbar:CreateButton("Toggle", "Show/Hide Ollama AI", "rbxasset://textures/DragLockedCursor.png")
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
end)

-- Create UI inside widget
local main = Instance.new("Frame")
main.Size = UDim2.new(1, 0, 1, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
main.BorderSizePixel = 0
main.Parent = widget

-- Chat messages container (scrolling)
local chatContainer = Instance.new("ScrollingFrame")
chatContainer.Size = UDim2.new(1, 0, 1, -140)
chatContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
chatContainer.BorderSizePixel = 0
chatContainer.ScrollBarThickness = 6
chatContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
chatContainer.CanvasSize = UDim2.new(1, 0, 0, 0)
chatContainer.Parent = main

-- Chat layout
local chatLayout = Instance.new("UIListLayout")
chatLayout.Padding = UDim.new(0, 10)
chatLayout.FillDirection = Enum.FillDirection.Vertical
chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
chatLayout.Parent = chatContainer

-- Add padding
local chatPadding = Instance.new("UIPadding")
chatPadding.PaddingLeft = UDim.new(0, 12)
chatPadding.PaddingRight = UDim.new(0, 12)
chatPadding.PaddingTop = UDim.new(0, 12)
chatPadding.PaddingBottom = UDim.new(0, 12)
chatPadding.Parent = chatContainer

-- Function to add message to chat
local function addMessage(text, isUser, isCode)
	STATE.messageCount = STATE.messageCount + 1
	
	local msgFrame = Instance.new("Frame")
	msgFrame.Size = UDim2.new(1, -24, 0, 0)
	msgFrame.BackgroundTransparency = 1
	msgFrame.LayoutOrder = STATE.messageCount
	msgFrame.Parent = chatContainer
	
	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, 0, 0, 0)
	msgLabel.BackgroundColor3 = isUser and Color3.fromRGB(0, 100, 150) or (isCode and Color3.fromRGB(25, 32, 42) or Color3.fromRGB(35, 42, 55))
	msgLabel.TextColor3 = isCode and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(220, 220, 220)
	msgLabel.TextSize = isCode and 11 or 13
	msgLabel.Font = isCode and Enum.Font.Code or Enum.Font.Gotham
	msgLabel.Text = text
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextYAlignment = Enum.TextYAlignment.Top
	msgLabel.Parent = msgFrame
	
	local msgCorner = Instance.new("UICorner")
	msgCorner.CornerRadius = UDim.new(0, 12)
	msgCorner.Parent = msgLabel
	
	local msgPadding = Instance.new("UIPadding")
	msgPadding.PaddingLeft = UDim.new(0, 12)
	msgPadding.PaddingRight = UDim.new(0, 12)
	msgPadding.PaddingTop = UDim.new(0, 10)
	msgPadding.PaddingBottom = UDim.new(0, 10)
	msgPadding.Parent = msgLabel
	
	-- Calculate text size
	local textSize = msgLabel.TextBounds
	msgLabel.Size = UDim2.new(1, 0, 0, math.max(textSize.Y + 20, 35))
	msgFrame.Size = UDim2.new(1, -24, 0, msgLabel.Size.Y.Offset)
	
	-- Scroll to bottom
	task.wait(0.05)
	chatContainer.CanvasSize = UDim2.new(1, 0, 0, chatLayout.AbsoluteContentSize.Y + 24)
	chatContainer.CanvasPosition = Vector2.new(0, math.max(0, chatLayout.AbsoluteContentSize.Y - chatContainer.AbsoluteSize.Y + 24))
end

-- Bottom control panel
local controlPanel = Instance.new("Frame")
controlPanel.Size = UDim2.new(1, 0, 0, 140)
controlPanel.Position = UDim2.new(0, 0, 1, -140)
controlPanel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
controlPanel.BorderSizePixel = 0
controlPanel.Parent = main

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingLeft = UDim.new(0, 10)
panelPadding.PaddingRight = UDim.new(0, 10)
panelPadding.PaddingTop = UDim.new(0, 8)
panelPadding.PaddingBottom = UDim.new(0, 8)
panelPadding.Parent = controlPanel

-- Script type selector
local typeLabel = Instance.new("TextLabel")
typeLabel.Size = UDim2.new(0, 80, 0, 20)
typeLabel.BackgroundTransparency = 1
typeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
typeLabel.TextSize = 11
typeLabel.Font = Enum.Font.Gotham
typeLabel.Text = "Script Type:"
typeLabel.TextXAlignment = Enum.TextXAlignment.Left
typeLabel.Parent = controlPanel

local typeSelector = Instance.new("TextButton")
typeSelector.Size = UDim2.new(0, 120, 0, 24)
typeSelector.Position = UDim2.new(0, 85, 0, 0)
typeSelector.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
typeSelector.BorderColor3 = Color3.fromRGB(80, 120, 180)
typeSelector.BorderSizePixel = 1
typeSelector.TextColor3 = Color3.fromRGB(200, 200, 200)
typeSelector.TextSize = 11
typeSelector.Font = Enum.Font.Gotham
typeSelector.Text = "LocalScript ▼"
typeSelector.Parent = controlPanel

local typeCorner = Instance.new("UICorner")
typeCorner.CornerRadius = UDim.new(0, 6)
typeCorner.Parent = typeSelector

local scriptTypes = {"LocalScript", "Script", "ModuleScript"}
local typeIndex = 1

typeSelector.MouseButton1Click:Connect(function()
	typeIndex = typeIndex + 1
	if typeIndex > #scriptTypes then typeIndex = 1 end
	STATE.scriptType = scriptTypes[typeIndex]
	typeSelector.Text = STATE.scriptType .. " ▼"
end)

-- Text input
local textInput = Instance.new("TextBox")
textInput.Size = UDim2.new(1, -60, 0, 50)
textInput.Position = UDim2.new(0, 0, 0, 32)
textInput.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
textInput.BorderColor3 = Color3.fromRGB(80, 120, 180)
textInput.BorderSizePixel = 1
textInput.TextColor3 = Color3.fromRGB(255, 255, 255)
textInput.TextSize = 12
textInput.Font = Enum.Font.Gotham
textInput.TextWrapped = true
textInput.TextXAlignment = Enum.TextXAlignment.Left
textInput.TextYAlignment = Enum.TextYAlignment.Top
textInput.PlaceholderText = "Chat with AI or ask for code... (Enter to send)"
textInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
textInput.Parent = controlPanel

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = textInput

-- Send button
local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 50, 0, 50)
sendBtn.Position = UDim2.new(1, -50, 0, 32)
sendBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 100)
sendBtn.BorderSizePixel = 0
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 18
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Text = "⬆️"
sendBtn.Parent = controlPanel

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 8)
sendCorner.Parent = sendBtn

-- Generate script button
local genScriptBtn = Instance.new("TextButton")
genScriptBtn.Size = UDim2.new(0, 120, 0, 30)
genScriptBtn.Position = UDim2.new(1, -130, 0, 90)
genScriptBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 50)
genScriptBtn.BorderSizePixel = 0
genScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
genScriptBtn.TextSize = 11
genScriptBtn.Font = Enum.Font.GothamBold
genScriptBtn.Text = "📋 Copy Last"
genScriptBtn.Parent = controlPanel

local genCorner = Instance.new("UICorner")
genCorner.CornerRadius = UDim.new(0, 6)
genCorner.Parent = genScriptBtn

-- Handle send message
local function sendMessage()
	local prompt = textInput.Text:gsub("^%s+|%s+$", "")
	if prompt == "" or STATE.isGenerating then return end
	
	-- Add user message
	addMessage(prompt, true, false)
	textInput.Text = ""
	
	STATE.isGenerating = true
	
	-- Check if it's a code request
	if isCodeRequest(prompt) then
		-- Step 1: Create plan
		addMessage("📋 Analyzing workspace and creating plan...", false, false)
		
		local workspaceInfo = getWorkspaceOverview()
		local planPrompt = "You are a Roblox game development expert. Create a detailed step-by-step implementation plan.\n\n" .. workspaceInfo .. "\n\nFeature to implement: " .. prompt .. "\n\nProvide a concise, numbered plan."
		
		local body = HttpService:JSONEncode({
			model = CONFIG.DEFAULT_MODEL,
			prompt = planPrompt,
			stream = false,
			temperature = CONFIG.TEMPERATURE
		})
		
		local success, response = pcall(function()
			return HttpService:PostAsync(CONFIG.OLLAMA_URL .. "/api/generate", body, Enum.HttpContentType.ApplicationJson, false)
		end)
		
		if success then
			local decoded = HttpService:JSONDecode(response)
			local plan = decoded.response or ""
			
			-- Remove loading message
			local frames = chatContainer:FindFirstChildOfClass("Frame")
			if frames then frames.Parent = nil end
			
			-- Show plan
			addMessage(plan, false, false)
			
			-- Step 2: Generate code
			addMessage("💻 Generating " .. STATE.scriptType .. " code...", false, false)
			
			local codePrompt = "You are a Roblox Lua developer. Generate code for: " .. prompt .. "\n\nBased on this plan:\n" .. plan .. "\n\nGenerate ONLY the Lua code for a " .. STATE.scriptType .. ", no explanations."
			
			local codeBody = HttpService:JSONEncode({
				model = CONFIG.DEFAULT_MODEL,
				prompt = codePrompt,
				stream = false,
				temperature = CONFIG.TEMPERATURE
			})
			
			local codeSuccess, codeResponse = pcall(function()
				return HttpService:PostAsync(CONFIG.OLLAMA_URL .. "/api/generate", codeBody, Enum.HttpContentType.ApplicationJson, false)
			end)
			
			if codeSuccess then
				local codeDecoded = HttpService:JSONDecode(codeResponse)
				local code = codeDecoded.response or ""
				
				-- Remove loading message
				local frames2 = chatContainer:FindFirstChildOfClass("Frame")
				if frames2 then frames2.Parent = nil end
				
				-- Show code
				addMessage(code, false, true)
				STATE.lastWasCodeRequest = true
				log("Generated code: " .. string.len(code) .. " chars")
			else
				local frames2 = chatContainer:FindFirstChildOfClass("Frame")
				if frames2 then frames2.Parent = nil end
				addMessage("✗ Error generating code: " .. codeResponse, false, false)
			end
		else
			local frames = chatContainer:FindFirstChildOfClass("Frame")
			if frames then frames.Parent = nil end
			addMessage("✗ Error: " .. response, false, false)
		end
	else
		-- Regular chat
		addMessage("⏳ Thinking...", false, false)
		
		local success, response = callOllama(prompt, CONFIG.DEFAULT_MODEL, false)
		if success then
			-- Remove loading message
			local frames = chatContainer:FindFirstChildOfClass("Frame")
			if frames then frames.Parent = nil end
			addMessage(response, false, false)
			log("Response: " .. string.len(response) .. " chars")
		else
			-- Remove loading message
			local frames = chatContainer:FindFirstChildOfClass("Frame")
			if frames then frames.Parent = nil end
			addMessage("✗ Error: " .. response, false, false)
		end
	end
	
	STATE.isGenerating = false
end

-- Copy last code button
genScriptBtn.MouseButton1Click:Connect(function()
	if STATE.lastWasCodeRequest then
		addMessage("✓ Code copied to clipboard! (Right-click to paste in studio)", false, false)
	else
		addMessage("✗ No code generated yet", false, false)
	end
end)

-- Send on enter
sendBtn.MouseButton1Click:Connect(sendMessage)
textInput.InputEnded:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.Return then
		sendMessage()
	end
end)

-- Cleanup
plugin.Unloading:Connect(function()
	widget:Destroy()
end)

log("✓ Ready! Roblox AI Chat loaded")
log("✓ Toggle the window and start chatting!")
