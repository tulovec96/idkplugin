--[[
	Ollama AI Code Generator Pro
	Chat interface with AI code generation
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
	messageCount = 0
}

local function log(msg)
	print("[🤖 OllamaAI] " .. msg)
end

local function callOllama(prompt, model)
	if STATE.isGenerating then return false, "Already generating" end
	STATE.isGenerating = true
	
	local body = HttpService:JSONEncode({
		model = model,
		prompt = prompt,
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
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 1200, 800, 1200, 800)
)
widget.Title = "🤖 Ollama AI Code Generator"

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
main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
main.BorderSizePixel = 0
main.Parent = widget

-- Chat messages container (scrolling)
local chatContainer = Instance.new("ScrollingFrame")
chatContainer.Size = UDim2.new(1, 0, 1, -80)
chatContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
chatContainer.BorderSizePixel = 0
chatContainer.ScrollBarThickness = 8
chatContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
chatContainer.CanvasSize = UDim2.new(1, 0, 0, 0)
chatContainer.Parent = main

-- Chat layout
local chatLayout = Instance.new("UIListLayout")
chatLayout.Padding = UDim.new(0, 8)
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
	msgLabel.BackgroundColor3 = isUser and Color3.fromRGB(0, 120, 180) or (isCode and Color3.fromRGB(30, 40, 50) or Color3.fromRGB(40, 50, 60))
	msgLabel.TextColor3 = isCode and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(220, 220, 220)
	msgLabel.TextSize = isCode and 10 or 12
	msgLabel.Font = isCode and Enum.Font.Code or Enum.Font.Gotham
	msgLabel.Text = text
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextYAlignment = Enum.TextYAlignment.Top
	msgLabel.Parent = msgFrame
	
	local msgCorner = Instance.new("UICorner")
	msgCorner.CornerRadius = UDim.new(0, 8)
	msgCorner.Parent = msgLabel
	
	local msgPadding = Instance.new("UIPadding")
	msgPadding.PaddingLeft = UDim.new(0, 10)
	msgPadding.PaddingRight = UDim.new(0, 10)
	msgPadding.PaddingTop = UDim.new(0, 8)
	msgPadding.PaddingBottom = UDim.new(0, 8)
	msgPadding.Parent = msgLabel
	
	-- Calculate text size
	local textSize = msgLabel.TextBounds
	msgLabel.Size = UDim2.new(1, 0, 0, math.max(textSize.Y + 16, 30))
	msgFrame.Size = UDim2.new(1, -24, 0, msgLabel.Size.Y.Offset)
	
	-- Scroll to bottom
	chatContainer.CanvasSize = UDim2.new(1, 0, 0, chatLayout.AbsoluteContentSize.Y + 24)
	chatContainer:TweenPosition(UDim2.new(0, 0, 1, -chatContainer.AbsoluteSize.Y), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true)
end

-- Input area
local inputContainer = Instance.new("Frame")
inputContainer.Size = UDim2.new(1, 0, 0, 70)
inputContainer.Position = UDim2.new(0, 0, 1, -70)
inputContainer.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
inputContainer.BorderSizePixel = 0
inputContainer.Parent = main

local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingLeft = UDim.new(0, 10)
inputPadding.PaddingRight = UDim.new(0, 10)
inputPadding.PaddingTop = UDim.new(0, 8)
inputPadding.PaddingBottom = UDim.new(0, 8)
inputPadding.Parent = inputContainer

-- Text input
local textInput = Instance.new("TextBox")
textInput.Size = UDim2.new(1, -60, 0, 50)
textInput.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
textInput.BorderColor3 = Color3.fromRGB(100, 150, 200)
textInput.BorderSizePixel = 1
textInput.TextColor3 = Color3.fromRGB(255, 255, 255)
textInput.TextSize = 12
textInput.Font = Enum.Font.Gotham
textInput.TextWrapped = true
textInput.TextXAlignment = Enum.TextXAlignment.Left
textInput.TextYAlignment = Enum.TextYAlignment.Top
textInput.PlaceholderText = "Ask me to generate code... (Enter to send)"
textInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
textInput.Parent = inputContainer

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = textInput

-- Send button
local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 50, 0, 50)
sendBtn.Position = UDim2.new(1, -50, 0, 0)
sendBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
sendBtn.BorderSizePixel = 0
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 20
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Text = "⬆️"
sendBtn.Parent = inputContainer

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 6)
sendCorner.Parent = sendBtn

-- Handle send
local function sendMessage()
	local prompt = textInput.Text:gsub("^%s+|%s+$", "")
	if prompt == "" or STATE.isGenerating then return end
	
	-- Add user message
	addMessage(prompt, true, false)
	textInput.Text = ""
	
	-- Generate response
	addMessage("⏳ Generating...", false, false)
	
	local success, code = callOllama(prompt, CONFIG.DEFAULT_MODEL)
	if success then
		-- Remove loading message
		chatContainer:FindFirstChildOfClass("Frame").Parent = nil
		-- Add code response
		addMessage(code, false, true)
		log("Generated: " .. string.len(code) .. " chars")
		
		-- Create script in workspace
		local script = Instance.new("LocalScript")
		script.Name = "OllamaGenerated_" .. tostring(math.random(10000, 99999))
		script.Source = code
		script.Parent = workspace
		addMessage("✓ Script created in workspace!", false, false)
	else
		-- Remove loading message
		chatContainer:FindFirstChildOfClass("Frame").Parent = nil
		addMessage("✗ Error: " .. code, false, false)
	end
end

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

log("✓ Ready! Chat interface loaded")
log("✓ Click 'Toggle' to open, then ask for code!")
