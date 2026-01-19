--[[
	🍋 Lemonade.gg-Style Roblox AI Plugin - PHASE 2
	Advanced project scanning, pattern detection, and smart code generation
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
	local context = {scripts = {}, modules = {}, patterns = {}}
	
	local function scanFolder(folder, prefix)
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
				table.insert(context.scripts, {
					name = child.Name,
					className = child.ClassName,
					path = prefix .. child.Name,
					parent = folder.Name,
					lines = #string.split(child.Source, "\n")
				})
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
	prompt = prompt .. "PROJECT: " .. #context.scripts .. " scripts found\n"
	
	if #relevantScripts > 0 then
		prompt = prompt .. "\nRELEVANT FILES:\n"
		for i, script in ipairs(relevantScripts) do
			if i <= 3 then
				prompt = prompt .. "• " .. script.path .. "\n"
			end
		end
	end
	
	prompt = prompt .. "\nREQUEST: " .. userRequest .. "\n"
	prompt = prompt .. "Generate ONLY Lua code. No explanations.\n"
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
-- PHASE 2: PATTERN MATCHING ENGINE
-- ============================================================================

local PatternMatcher = {}

function PatternMatcher.detectScriptType(userRequest)
	local lower = string.lower(userRequest)
	if string.find(lower, "client") or string.find(lower, "player") or string.find(lower, "gui") then
		return "LocalScript"
	elseif string.find(lower, "server") or string.find(lower, "save") or string.find(lower, "data") then
		return "Script"
	else
		return "ModuleScript"
	end
end

function PatternMatcher.getSuggestedLocation(scriptType)
	if scriptType == "LocalScript" then
		local starter = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
		return starter or game:GetService("StarterPlayer")
	elseif scriptType == "Script" then
		return game:GetService("ServerScriptService")
	else
		return game:GetService("ReplicatedStorage")
	end
end

-- ============================================================================
-- PHASE 2: STUDIO INTEGRATION
-- ============================================================================

local StudioIntegration = {}

function StudioIntegration.insertCode(code, scriptType, location)
	local script = Instance.new(scriptType)
	script.Name = "Generated_" .. tostring(math.random(10000, 99999))
	script.Source = code
	script.Parent = location
	return script
end

-- ============================================================================
-- PHASE 2: GENERATE ALTERNATIVES
-- ============================================================================

local currentAlternatives = {}

local function generateAlternatives(basePrompt)
	currentAlternatives = {}
	for i = 1, 2 do
		local altPrompt = basePrompt .. "\n\n[ALTERNATIVE " .. i .. " - Different approach]"
		local success, code = OllamaClient.call(altPrompt, CONFIG.DEFAULT_MODEL)
		if success then
			table.insert(currentAlternatives, code)
		end
		task.wait(0.5)
	end
	return currentAlternatives
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
	context = ContextScanner.scanProject(),
	showingAlternatives = false,
	selectedAlt = 0
}

local function log(msg)
	print("[🍋 LemonadeAI] " .. msg)
end

log("✓ Scanned: " .. #STATE.context.scripts .. " scripts")

-- ============================================================================
-- UI: CHAT INTERFACE
-- ============================================================================

local toolbar = plugin:CreateToolbar("Lemonade AI")
local widget = plugin:CreateDockWidgetPluginGui(
	"Lemonade AI",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 1000, 700, 1000, 700)
)
widget.Title = "🍋 Lemonade AI - Phase 2"

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
chatContainer.Size = UDim2.new(1, 0, 1, -120)
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
	msgLabel.TextSize = isCode and 9 or 11
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
inputArea.Size = UDim2.new(1, 0, 0, 120)
inputArea.Position = UDim2.new(0, 0, 1, -120)
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
textInput.Size = UDim2.new(1, -60, 0, 45)
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
sendBtn.Size = UDim2.new(0, 50, 0, 45)
sendBtn.Position = UDim2.new(1, -50, 0, 0)
sendBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 100)
sendBtn.BorderSizePixel = 0
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 16
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Text = "→"
sendBtn.Parent = inputArea

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 6)
sendCorner.Parent = sendBtn

-- Alternative buttons
local altContainer = Instance.new("Frame")
altContainer.Size = UDim2.new(1, 0, 0, 35)
altContainer.Position = UDim2.new(0, 0, 1, -35)
altContainer.BackgroundTransparency = 1
altContainer.Parent = inputArea

local altLayout = Instance.new("UIListLayout")
altLayout.FillDirection = Enum.FillDirection.Horizontal
altLayout.Padding = UDim.new(0, 5)
altLayout.SortOrder = Enum.SortOrder.LayoutOrder
altLayout.Parent = altContainer

local insertBtn = Instance.new("TextButton")
insertBtn.Size = UDim2.new(0, 100, 0, 32)
insertBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 50)
insertBtn.BorderSizePixel = 0
insertBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
insertBtn.TextSize = 11
insertBtn.Font = Enum.Font.GothamBold
insertBtn.Text = "✓ Insert Code"
insertBtn.LayoutOrder = 1
insertBtn.Parent = altContainer

local insertCorner = Instance.new("UICorner")
insertCorner.CornerRadius = UDim.new(0, 6)
insertCorner.Parent = insertBtn

local alt1Btn = Instance.new("TextButton")
alt1Btn.Size = UDim2.new(0, 80, 0, 32)
alt1Btn.BackgroundColor3 = Color3.fromRGB(60, 100, 150)
alt1Btn.BorderSizePixel = 0
alt1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
alt1Btn.TextSize = 11
alt1Btn.Font = Enum.Font.GothamBold
alt1Btn.Text = "Option A"
alt1Btn.LayoutOrder = 2
alt1Btn.Parent = altContainer

local alt1Corner = Instance.new("UICorner")
alt1Corner.CornerRadius = UDim.new(0, 6)
alt1Corner.Parent = alt1Btn

local alt2Btn = Instance.new("TextButton")
alt2Btn.Size = UDim2.new(0, 80, 0, 32)
alt2Btn.BackgroundColor3 = Color3.fromRGB(60, 100, 150)
alt2Btn.BorderSizePixel = 0
alt2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
alt2Btn.TextSize = 11
alt2Btn.Font = Enum.Font.GothamBold
alt2Btn.Text = "Option B"
alt2Btn.LayoutOrder = 3
alt2Btn.Parent = altContainer

local alt2Corner = Instance.new("UICorner")
alt2Corner.CornerRadius = UDim.new(0, 6)
alt2Corner.Parent = alt2Btn

local contextLabel = Instance.new("TextLabel")
contextLabel.Size = UDim2.new(1, 0, 0, 20)
contextLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
contextLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
contextLabel.TextSize = 9
contextLabel.Font = Enum.Font.Gotham
contextLabel.Text = "📚 " .. #STATE.context.scripts .. " scripts | 🎯 Smart placement enabled"
contextLabel.Parent = inputArea

-- ============================================================================
-- CHAT LOGIC
-- ============================================================================

local lastGeneratedCode = ""
local lastScriptType = ""
local lastLocation = nil

local function handleMessage()
	local text = textInput.Text:gsub("^%s+|%s+$", "")
	if text == "" or STATE.isGenerating then return end
	
	STATE.isGenerating = true
	
	addMessage("👤 " .. text, true, false)
	textInput.Text = ""
	
	local lower = string.lower(text)
	if string.find(lower, "make") or string.find(lower, "create") or string.find(lower, "build") or string.find(lower, "add") then
		addMessage("🔍 Analyzing workspace & generating...", false, false)
		
		-- PHASE 2: Smart detection
		local scriptType = PatternMatcher.detectScriptType(text)
		local location = PatternMatcher.getSuggestedLocation(scriptType)
		lastScriptType = scriptType
		lastLocation = location
		
		local relevant = ContextScanner.findRelevantScripts(text, STATE.context)
		local prompt = OllamaClient.buildPrompt(text, STATE.context, relevant)
		
		local success, code = OllamaClient.call(prompt, CONFIG.DEFAULT_MODEL)
		
		local frames = chatContainer:FindFirstChildOfClass("Frame")
		if frames then frames.Parent = nil end
		
		if success then
			lastGeneratedCode = code
			addMessage(code, false, true)
			addMessage("💡 Detected: " .. scriptType .. " | Generating alternatives...", false, false)
			
			-- Generate alternatives
			local alts = generateAlternatives(prompt)
			currentAlternatives = alts
			STATE.showingAlternatives = true
			
			if #alts > 0 then
				addMessage("✓ Alternative A ready", false, false)
			end
			if #alts > 1 then
				addMessage("✓ Alternative B ready", false, false)
			end
			
			Memory.save(text, code)
		else
			addMessage("❌ Error: " .. code, false, false)
		end
	else
		-- Regular chat
		addMessage("💭 Thinking...", false, false)
		
		local body = HttpService:JSONEncode({
			model = CONFIG.DEFAULT_MODEL,
			prompt = text,
			stream = false,
			temperature = CONFIG.TEMPERATURE
		})
		
		local success, response = pcall(function()
			return HttpService:PostAsync(CONFIG.OLLAMA_URL .. "/api/generate", body, Enum.HttpContentType.ApplicationJson, false)
		end)
		
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

insertBtn.MouseButton1Click:Connect(function()
	if lastGeneratedCode == "" then
		addMessage("❌ Generate code first!", false, false)
		return
	end
	
	StudioIntegration.insertCode(lastGeneratedCode, lastScriptType, lastLocation)
	addMessage("✅ " .. lastScriptType .. " inserted into " .. lastLocation.Name, false, false)
	lastGeneratedCode = ""
end)

alt1Btn.MouseButton1Click:Connect(function()
	if currentAlternatives[1] then
		lastGeneratedCode = currentAlternatives[1]
		addMessage("✓ Selected Option A", false, false)
		addMessage(currentAlternatives[1], false, true)
	end
end)

alt2Btn.MouseButton1Click:Connect(function()
	if currentAlternatives[2] then
		lastGeneratedCode = currentAlternatives[2]
		addMessage("✓ Selected Option B", false, false)
		addMessage(currentAlternatives[2], false, true)
	end
end)

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

log("✓ Phase 2 loaded: Smart placement + alternatives!")
addMessage("🍋 Lemonade AI Phase 2\nAsk me to build something!", false, false)
