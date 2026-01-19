--[[
	🍋 Lemonade.gg-Style Roblox AI Plugin
	Advanced project scanning, pattern detection, and smart code generation
	Connects to: http://23.88.19.42:11434/
]]

local plugin = plugin
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

if not RunService:IsEdit() then return end

local CONFIG = {
	OLLAMA_URL = "http://23.88.19.42:11434",
	DEFAULT_MODEL = "mistral",
	TEMPERATURE = 0.7,
}

-- ============================================================================
-- PHASE 1: PROJECT CONTEXT SCANNER
-- ============================================================================

local ContextScanner = {}

function ContextScanner.scanProject()
	local context = {
		scripts = {},
		modules = {},
		patterns = {}
	}
	
	local function scanFolder(folder, prefix)
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
				local path = prefix .. child.Name
				table.insert(context.scripts, {
					name = child.Name,
					className = child.ClassName,
					path = path,
					parent = folder.Name,
					lines = #string.split(child.Source, "\n")
				})
				if string.find(child.Source, "RemoteEvent") then
					table.insert(context.patterns, "RemoteEvent usage detected")
				end
			end
			if child:IsA("Folder") then
				scanFolder(child, prefix .. child.Name .. "/")
			end
		end
	end
	
	local locations = {
		game:GetService("ServerScriptService"),
		game:GetService("ServerStorage"),
		game:GetService("ReplicatedStorage"),
	}
	
	for _, location in ipairs(locations) do
		if location then
			scanFolder(location, location.Name .. "/")
		end
	end
	
	return context
end

function ContextScanner.findRelevantScripts(userRequest, context)
	local relevant = {}
	local lower = string.lower(userRequest)
	
	for _, script in ipairs(context.scripts) do
		if string.find(string.lower(script.name), lower) or string.find(lower, string.lower(script.name)) then
			table.insert(relevant, script)
		end
	end
	
	return relevant
end

-- ============================================================================
-- PHASE 1: OLLAMA CLIENT
-- ============================================================================

local OllamaClient = {}

function OllamaClient.buildPrompt(userRequest, context, relevantScripts)
	local prompt = "You are an expert Roblox Lua developer.\n\n"
	prompt = prompt .. "PROJECT: " .. #context.scripts .. " scripts, using RemoteEvents\n"
	
	if #relevantScripts > 0 then
		prompt = prompt .. "\nRELEVANT FILES:\n"
		for i, script in ipairs(relevantScripts) do
			if i <= 3 then
				prompt = prompt .. "• " .. script.path .. "\n"
			end
		end
	end
	
	prompt = prompt .. "\nREQUEST: " .. userRequest .. "\n"
	prompt = prompt .. "\nGenerate ONLY Lua code. No explanations.\n"
	return prompt
end

function OllamaClient.call(prompt, model)
	local body = HttpService:JSONEncode({
		model = model,
		prompt = prompt,
		stream = false,
		temperature = CONFIG.TEMPERATURE
	})
	
	local success, response = pcall(function()
		return HttpService:PostAsync(CONFIG.OLLAMA_URL .. "/api/generate", body, Enum.HttpContentType.ApplicationJson, false)
	end)
	
	if success then
		local decoded = HttpService:JSONDecode(response)
		return true, decoded.response or ""
	else
		return false, tostring(response)
	end
end

-- ============================================================================
-- PHASE 1: MEMORY SYSTEM
-- ============================================================================

local Memory = {}
Memory.history = {}

function Memory.save(request, code)
	table.insert(Memory.history, {request = request, code = code, time = os.time()})
end

-- ============================================================================
-- STATE
-- ============================================================================

local STATE = {
	isGenerating = false,
	messageCount = 0,
	scriptType = "LocalScript",
	context = ContextScanner.scanProject()
}

local function log(msg)
	print("[🍋 LemonadeAI] " .. msg)
end

log("✓ Scanned: " .. #STATE.context.scripts .. " scripts found")

-- ============================================================================
-- UI: CHAT INTERFACE
-- ============================================================================

local toolbar = plugin:CreateToolbar("Lemonade AI")
local widget = plugin:CreateDockWidgetPluginGui(
	"Lemonade AI",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 900, 600, 900, 600)
)
widget.Title = "🍋 Lemonade AI"

local toggleButton = toolbar:CreateButton("Toggle", "Show/Hide", "rbxasset://textures/DragLockedCursor.png")
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
end)

-- Main UI
local main = Instance.new("Frame")
main.Size = UDim2.new(1, 0, 1, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
main.BorderSizePixel = 0
main.Parent = widget

-- Chat area
local chatContainer = Instance.new("ScrollingFrame")
chatContainer.Size = UDim2.new(1, 0, 1, -100)
chatContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
chatContainer.BorderSizePixel = 0
chatContainer.ScrollBarThickness = 6
chatContainer.CanvasSize = UDim2.new(1, 0, 0, 0)
chatContainer.Parent = main

local chatLayout = Instance.new("UIListLayout")
chatLayout.Padding = UDim.new(0, 8)
chatLayout.FillDirection = Enum.FillDirection.Vertical
chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
chatLayout.Parent = chatContainer

local chatPadding = Instance.new("UIPadding")
chatPadding.PaddingLeft = UDim.new(0, 10)
chatPadding.PaddingRight = UDim.new(0, 10)
chatPadding.PaddingTop = UDim.new(0, 10)
chatPadding.PaddingBottom = UDim.new(0, 10)
chatPadding.Parent = chatContainer

-- Add message function
local function addMessage(text, isUser, isCode)
	STATE.messageCount = STATE.messageCount + 1
	
	local msgFrame = Instance.new("Frame")
	msgFrame.Size = UDim2.new(1, -20, 0, 0)
	msgFrame.BackgroundTransparency = 1
	msgFrame.LayoutOrder = STATE.messageCount
	msgFrame.Parent = chatContainer
	
	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, 0, 0, 0)
	msgLabel.BackgroundColor3 = isUser and Color3.fromRGB(0, 100, 150) or (isCode and Color3.fromRGB(25, 35, 45) or Color3.fromRGB(35, 45, 60))
	msgLabel.TextColor3 = isCode and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(220, 220, 220)
	msgLabel.TextSize = isCode and 10 or 12
	msgLabel.Font = isCode and Enum.Font.Code or Enum.Font.Gotham
	msgLabel.Text = text
	msgLabel.TextWrapped = true
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextYAlignment = Enum.TextYAlignment.Top
	msgLabel.Parent = msgFrame
	
	local msgCorner = Instance.new("UICorner")
	msgCorner.CornerRadius = UDim.new(0, 10)
	msgCorner.Parent = msgLabel
	
	local msgPadding = Instance.new("UIPadding")
	msgPadding.PaddingLeft = UDim.new(0, 10)
	msgPadding.PaddingRight = UDim.new(0, 10)
	msgPadding.PaddingTop = UDim.new(0, 8)
	msgPadding.PaddingBottom = UDim.new(0, 8)
	msgPadding.Parent = msgLabel
	
	local textSize = msgLabel.TextBounds
	msgLabel.Size = UDim2.new(1, 0, 0, math.max(textSize.Y + 16, 30))
	msgFrame.Size = UDim2.new(1, -20, 0, msgLabel.Size.Y.Offset)
	
	task.wait(0.05)
	chatContainer.CanvasSize = UDim2.new(1, 0, 0, chatLayout.AbsoluteContentSize.Y + 20)
	chatContainer.CanvasPosition = Vector2.new(0, math.max(0, chatLayout.AbsoluteContentSize.Y - chatContainer.AbsoluteSize.Y + 20))
end

-- Input area
local inputArea = Instance.new("Frame")
inputArea.Size = UDim2.new(1, 0, 0, 100)
inputArea.Position = UDim2.new(0, 0, 1, -100)
inputArea.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
inputArea.BorderSizePixel = 0
inputArea.Parent = main

local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingLeft = UDim.new(0, 8)
inputPadding.PaddingRight = UDim.new(0, 8)
inputPadding.PaddingTop = UDim.new(0, 8)
inputPadding.PaddingBottom = UDim.new(0, 8)
inputPadding.Parent = inputArea

-- Text input
local textInput = Instance.new("TextBox")
textInput.Size = UDim2.new(1, -60, 0, 40)
textInput.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
textInput.BorderColor3 = Color3.fromRGB(80, 120, 180)
textInput.BorderSizePixel = 1
textInput.TextColor3 = Color3.fromRGB(255, 255, 255)
textInput.TextSize = 12
textInput.Font = Enum.Font.Gotham
textInput.TextWrapped = true
textInput.PlaceholderText = "Describe what to build..."
textInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
textInput.Parent = inputArea

local textCorner = Instance.new("UICorner")
textCorner.CornerRadius = UDim.new(0, 6)
textCorner.Parent = textInput

-- Send button
local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 50, 0, 40)
sendBtn.Position = UDim2.new(1, -50, 0, 0)
sendBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 100)
sendBtn.BorderSizePixel = 0
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 18
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Text = "→"
sendBtn.Parent = inputArea

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 6)
sendCorner.Parent = sendBtn

-- Context info
local contextLabel = Instance.new("TextLabel")
contextLabel.Size = UDim2.new(1, 0, 0, 25)
contextLabel.Position = UDim2.new(0, 0, 1, -25)
contextLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
contextLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
contextLabel.TextSize = 10
contextLabel.Font = Enum.Font.Gotham
contextLabel.Text = "📚 " .. #STATE.context.scripts .. " scripts scanned"
contextLabel.Parent = inputArea

-- ============================================================================
-- CHAT LOGIC
-- ============================================================================

local function handleMessage()
	local text = textInput.Text:gsub("^%s+|%s+$", "")
	if text == "" or STATE.isGenerating then return end
	
	STATE.isGenerating = true
	
	addMessage("👤 " .. text, true, false)
	textInput.Text = ""
	
	-- Check if code request
	local lower = string.lower(text)
	if string.find(lower, "make") or string.find(lower, "create") or string.find(lower, "build") or string.find(lower, "add") then
		addMessage("🔍 Analyzing...", false, false)
		
		local relevant = ContextScanner.findRelevantScripts(text, STATE.context)
		local prompt = OllamaClient.buildPrompt(text, STATE.context, relevant)
		
		local success, code = OllamaClient.call(prompt, CONFIG.DEFAULT_MODEL)
		
		-- Remove loading
		local frames = chatContainer:FindFirstChildOfClass("Frame")
		if frames then frames.Parent = nil end
		
		if success then
			addMessage(code, false, true)
			Memory.save(text, code)
		else
			addMessage("❌ Error: " .. code, false, false)
		end
	else
		-- Regular chat
		addMessage("💭 Let me think...", false, false)
		
		local body = HttpService:JSONEncode({
			model = CONFIG.DEFAULT_MODEL,
			prompt = text,
			stream = false,
			temperature = CONFIG.TEMPERATURE
		})
		
		local success, response = pcall(function()
			return HttpService:PostAsync(CONFIG.OLLAMA_URL .. "/api/generate", body, Enum.HttpContentType.ApplicationJson, false)
		end)
		
		-- Remove loading
		local frames = chatContainer:FindFirstChildOfClass("Frame")
		if frames then frames.Parent = nil end
		
		if success then
			local decoded = HttpService:JSONDecode(response)
			addMessage(decoded.response or "", false, false)
		else
			addMessage("❌ Error", false, false)
		end
	end
	
	STATE.isGenerating = false
end

sendBtn.MouseButton1Click:Connect(handleMessage)
textInput.InputEnded:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.Return then
		handleMessage()
	end
end)

plugin.Unloading:Connect(function()
	widget:Destroy()
end)

log("✓ Lemonade AI loaded and ready!")
addMessage("🍋 Lemonade AI\nAsk me to build something!", false, false)
