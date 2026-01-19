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
-- PHASE 3: CODE ANALYSIS & ARCHITECTURE ENGINE
-- ============================================================================

local CodeAnalyzer = {}

function CodeAnalyzer.analyzeRequires(scriptSource)
	local requires = {}
	for match in scriptSource:gmatch('require%(script[%w.:%s/"\']+(.-)[%w.:\'"%)]*%)', 1) do
		table.insert(requires, match)
	end
	return requires
end

function CodeAnalyzer.analyzeRemotes(scriptSource)
	local remotes = {}
	for match in scriptSource:gmatch('game:GetService%("ReplicatedStorage"%):WaitForChild%("([^"]+)"%) or WaitForChild("([^"]+)%) or matching patterns') do
		table.insert(remotes, match)
	end
	return remotes
end

function CodeAnalyzer.buildDependencyGraph(scripts)
	local graph = {}
	for _, script in ipairs(scripts) do
		graph[script.name] = {
			type = script.className,
			path = script.path,
			dependencies = {},
			dependents = {}
		}
	end
	return graph
end

function CodeAnalyzer.suggestOptimizations(code)
	local suggestions = {}
	
	if string.len(code) > 1000 and not string.find(code, "local function") then
		table.insert(suggestions, "• Consider breaking code into functions for reusability")
	end
	if string.find(code, "while true") or string.find(code, "for") then
		table.insert(suggestions, "• Add loop guards or breaks to prevent infinite loops")
	end
	if not string.find(code, "pcall") and not string.find(code, "xpcall") then
		table.insert(suggestions, "• Consider wrapping risky calls in pcall for error handling")
	end
	if not string.find(code, "task.wait") and not string.find(code, "wait%(%d") then
		table.insert(suggestions, "• Consider using task.wait() for modern yielding")
	end
	
	return suggestions
end

-- ============================================================================
-- PHASE 3: RELATIONSHIP VIEWER
-- ============================================================================

local RelationshipViewer = {}

function RelationshipViewer.generateArchitectureReport(context)
	local report = "=== PROJECT ARCHITECTURE ===\n\n"
	report = report .. "Total Scripts: " .. #context.scripts .. "\n"
	
	local byType = {Script = 0, LocalScript = 0, ModuleScript = 0}
	for _, script in ipairs(context.scripts) do
		byType[script.className] = (byType[script.className] or 0) + 1
	end
	
	report = report .. "\nBreakdown:\n"
	for scriptType, count in pairs(byType) do
		report = report .. "• " .. scriptType .. ": " .. count .. "\n"
	end
	
	return report
end

function RelationshipViewer.generateConnectionMap(context, userRequest)
	local map = "=== PROJECT MAP ===\n\n"
	map = map .. "Files related to '" .. userRequest .. "':\n"
	
	local relevant = ContextScanner.findRelevantScripts(userRequest, context)
	for i, script in ipairs(relevant) do
		if i <= 5 then
			map = map .. "• " .. script.path .. " (" .. script.lines .. "L)\n"
		end
	end
	
	return map
end

-- ============================================================================
-- PHASE 3: ADVANCED LEARNING SYSTEM
-- ============================================================================

local AdvancedLearning = {}
AdvancedLearning.feedback = {}
AdvancedLearning.preferences = {
	mostUsedStyle = "functional",
	errorHandlingPref = "pcall",
	namingConvention = "camelCase"
}

function AdvancedLearning.recordThumbsUp(code)
	table.insert(AdvancedLearning.feedback, {
		code = code,
		rating = "good",
		time = os.time()
	})
end

function AdvancedLearning.recordThumbsDown(code)
	table.insert(AdvancedLearning.feedback, {
		code = code,
		rating = "bad",
		time = os.time()
	})
end

function AdvancedLearning.getNextSuggestion()
	if #AdvancedLearning.feedback > 5 then
		return "Your preference detected: " .. AdvancedLearning.preferences.mostUsedStyle .. " style"
	end
	return nil
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

-- ============================================================================
-- CHECKPOINT SYSTEM (Version Management)
-- ============================================================================

local Checkpoint = {}
Checkpoint.history = {}

function Checkpoint.save(code, scriptType, description)
	table.insert(Checkpoint.history, {
		code = code,
		scriptType = scriptType,
		description = description or "Generated code",
		timestamp = os.time(),
		id = #Checkpoint.history + 1
	})
end

function Checkpoint.restore(checkpointId)
	for i, checkpoint in ipairs(Checkpoint.history) do
		if checkpoint.id == checkpointId then
			lastGeneratedCode = checkpoint.code
			lastScriptType = checkpoint.scriptType
			return checkpoint
		end
	end
	return nil
end

function Checkpoint.getAll()
	return Checkpoint.history
end

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
widget.Title = "🍋 Lemonade AI - Clean"

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

-- Create three-panel layout: chat | checkpoints | investigation
local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0.7, 0, 1, -120)
leftPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
leftPanel.BorderSizePixel = 0
leftPanel.Parent = main

local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0.3, -1, 1, -120)
rightPanel.Position = UDim2.new(0.7, 1, 0, 0)
rightPanel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
rightPanel.BorderSizePixel = 0
rightPanel.Parent = main

-- Right panel label (Checkpoints)
local checkpointLabel = Instance.new("TextLabel")
checkpointLabel.Size = UDim2.new(1, 0, 0, 30)
checkpointLabel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
checkpointLabel.TextColor3 = Color3.fromRGB(100, 150, 200)
checkpointLabel.TextSize = 11
checkpointLabel.Font = Enum.Font.GothamBold
checkpointLabel.Text = "🔄 Checkpoints"
checkpointLabel.BorderSizePixel = 0
checkpointLabel.Parent = rightPanel

-- Checkpoint list
local checkpointList = Instance.new("ScrollingFrame")
checkpointList.Size = UDim2.new(1, 0, 1, -30)
checkpointList.Position = UDim2.new(0, 0, 0, 30)
checkpointList.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
checkpointList.BorderSizePixel = 0
checkpointList.ScrollBarThickness = 4
checkpointList.CanvasSize = UDim2.new(1, 0, 0, 0)
checkpointList.Parent = rightPanel

local checkpointLayout = Instance.new("UIListLayout")
checkpointLayout.Padding = UDim.new(0, 4)
checkpointLayout.FillDirection = Enum.FillDirection.Vertical
checkpointLayout.SortOrder = Enum.SortOrder.LayoutOrder
checkpointLayout.Parent = checkpointList

local checkpointPadding = Instance.new("UIPadding")
checkpointPadding.PaddingLeft = UDim.new(0, 6)
checkpointPadding.PaddingRight = UDim.new(0, 6)
checkpointPadding.PaddingTop = UDim.new(0, 6)
checkpointPadding.PaddingBottom = UDim.new(0, 6)
checkpointPadding.Parent = checkpointList

-- Chat area (left panel)
local chatContainer = Instance.new("ScrollingFrame")
chatContainer.Size = UDim2.new(1, 0, 1, 0)
chatContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
chatContainer.BorderSizePixel = 0
chatContainer.ScrollBarThickness = 6
chatContainer.CanvasSize = UDim2.new(1, 0, 0, 0)
chatContainer.Parent = leftPanel

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

-- Update checkpoint list UI
local function updateCheckpointList()
	-- Clear existing checkpoints
	for _, child in ipairs(checkpointList:GetChildren()) do
		if child:IsA("Frame") and child ~= checkpointLayout and child ~= checkpointPadding then
			child:Destroy()
		end
	end
	
	-- Add new checkpoints
	for i, checkpoint in ipairs(Checkpoint.getAll()) do
		local cpFrame = Instance.new("Frame")
		cpFrame.Size = UDim2.new(1, 0, 0, 70)
		cpFrame.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
		cpFrame.BorderSizePixel = 0
		cpFrame.LayoutOrder = i
		cpFrame.Parent = checkpointList
		
		local cpCorner = Instance.new("UICorner")
		cpCorner.CornerRadius = UDim.new(0, 6)
		cpCorner.Parent = cpFrame
		
		-- Title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -10, 0, 20)
		titleLabel.Position = UDim2.new(0, 5, 0, 5)
		titleLabel.BackgroundTransparency = 1
		titleLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
		titleLabel.TextSize = 10
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.Text = "✓ " .. checkpoint.scriptType
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Parent = cpFrame
		
		-- Time
		local timeLabel = Instance.new("TextLabel")
		timeLabel.Size = UDim2.new(1, -10, 0, 15)
		timeLabel.Position = UDim2.new(0, 5, 0, 25)
		timeLabel.BackgroundTransparency = 1
		timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		timeLabel.TextSize = 8
		timeLabel.Font = Enum.Font.Gotham
		timeLabel.Text = os.date("%H:%M:%S", checkpoint.timestamp)
		timeLabel.TextXAlignment = Enum.TextXAlignment.Left
		timeLabel.Parent = cpFrame
		
		-- Restore button
		local restoreBtn = Instance.new("TextButton")
		restoreBtn.Size = UDim2.new(0, 55, 0, 20)
		restoreBtn.Position = UDim2.new(0, 5, 0, 48)
		restoreBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 150)
		restoreBtn.BorderSizePixel = 0
		restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		restoreBtn.TextSize = 9
		restoreBtn.Font = Enum.Font.GothamBold
		restoreBtn.Text = "↶ Restore"
		restoreBtn.Parent = cpFrame
		
		local restoreCorner = Instance.new("UICorner")
		restoreCorner.CornerRadius = UDim.new(0, 4)
		restoreCorner.Parent = restoreBtn
		
		restoreBtn.MouseButton1Click:Connect(function()
			local restored = Checkpoint.restore(checkpoint.id)
			if restored then
				addMessage("🔄 Restored to checkpoint: " .. restored.scriptType, false, false)
				addMessage(restored.code, false, true)
				lastGeneratedCode = restored.code
				lastScriptType = restored.scriptType
			end
		end)
		
		-- Copy button
		local copyBtn = Instance.new("TextButton")
		copyBtn.Size = UDim2.new(0, 55, 0, 20)
		copyBtn.Position = UDim2.new(0, 65, 0, 48)
		copyBtn.BackgroundColor3 = Color3.fromRGB(100, 120, 160)
		copyBtn.BorderSizePixel = 0
		copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		copyBtn.TextSize = 9
		copyBtn.Font = Enum.Font.GothamBold
		copyBtn.Text = "📋 Copy"
		copyBtn.Parent = cpFrame
		
		local copyCorner = Instance.new("UICorner")
		copyCorner.CornerRadius = UDim.new(0, 4)
		copyCorner.Parent = copyBtn
		
		copyBtn.MouseButton1Click:Connect(function()
			setclipboard(checkpoint.code)
			addMessage("✓ Copied to clipboard!", false, false)
		end)
	end
	
	-- Update canvas size
	task.wait(0.05)
	checkpointList.CanvasSize = UDim2.new(1, 0, 0, checkpointLayout.AbsoluteContentSize.Y + 12)
end

-- Add investigation log entry
local function logInvestigation(text)
	addMessage("🔍 " .. text, false, false)
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

-- Clean action buttons (no alternatives clutter)
local actionContainer = Instance.new("Frame")
actionContainer.Size = UDim2.new(1, 0, 0, 35)
actionContainer.Position = UDim2.new(0, 0, 1, -35)
actionContainer.BackgroundTransparency = 1
actionContainer.Parent = inputArea

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.Padding = UDim.new(0, 5)
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.Parent = actionContainer

-- Inject button (direct script injection into running game)
local injectBtn = Instance.new("TextButton")
injectBtn.Size = UDim2.new(0, 100, 0, 32)
injectBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 100)
injectBtn.BorderSizePixel = 0
injectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
injectBtn.TextSize = 11
injectBtn.Font = Enum.Font.GothamBold
injectBtn.Text = "💉 Inject"
injectBtn.LayoutOrder = 1
injectBtn.Parent = actionContainer

local injectCorner = Instance.new("UICorner")
injectCorner.CornerRadius = UDim.new(0, 6)
injectCorner.Parent = injectBtn

-- Copy to clipboard button
local copyClipBtn = Instance.new("TextButton")
copyClipBtn.Size = UDim2.new(0, 100, 0, 32)
copyClipBtn.BackgroundColor3 = Color3.fromRGB(100, 120, 160)
copyClipBtn.BorderSizePixel = 0
copyClipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyClipBtn.TextSize = 11
copyClipBtn.Font = Enum.Font.GothamBold
copyClipBtn.Text = "📋 Copy"
copyClipBtn.LayoutOrder = 2
copyClipBtn.Parent = actionContainer

local copyClipCorner = Instance.new("UICorner")
copyClipCorner.CornerRadius = UDim.new(0, 6)
copyClipCorner.Parent = copyClipBtn

local contextLabel = Instance.new("TextLabel")
contextLabel.Size = UDim2.new(1, 0, 0, 20)
contextLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
contextLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
contextLabel.TextSize = 9
contextLabel.Font = Enum.Font.Gotham
contextLabel.Text = "📚 " .. #STATE.context.scripts .. " scripts"
contextLabel.Parent = inputArea

-- Feedback buttons (below)
local feedbackContainer = Instance.new("Frame")
feedbackContainer.Size = UDim2.new(1, 0, 0, 35)
feedbackContainer.Position = UDim2.new(0, 0, 1, -70)
feedbackContainer.BackgroundTransparency = 1
feedbackContainer.Parent = inputArea

local feedbackLayout = Instance.new("UIListLayout")
feedbackLayout.FillDirection = Enum.FillDirection.Horizontal
feedbackLayout.Padding = UDim.new(0, 5)
feedbackLayout.SortOrder = Enum.SortOrder.LayoutOrder
feedbackLayout.Parent = feedbackContainer

local thumbsUpBtn = Instance.new("TextButton")
thumbsUpBtn.Size = UDim2.new(0, 60, 0, 32)
thumbsUpBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 80)
thumbsUpBtn.BorderSizePixel = 0
thumbsUpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
thumbsUpBtn.TextSize = 14
thumbsUpBtn.Font = Enum.Font.GothamBold
thumbsUpBtn.Text = "👍"
thumbsUpBtn.LayoutOrder = 1
thumbsUpBtn.Parent = feedbackContainer

local thumbsUpCorner = Instance.new("UICorner")
thumbsUpCorner.CornerRadius = UDim.new(0, 6)
thumbsUpCorner.Parent = thumbsUpBtn

local thumbsDownBtn = Instance.new("TextButton")
thumbsDownBtn.Size = UDim2.new(0, 60, 0, 32)
thumbsDownBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 50)
thumbsDownBtn.BorderSizePixel = 0
thumbsDownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
thumbsDownBtn.TextSize = 14
thumbsDownBtn.Font = Enum.Font.GothamBold
thumbsDownBtn.Text = "👎"
thumbsDownBtn.LayoutOrder = 2
thumbsDownBtn.Parent = feedbackContainer

local thumbsDownCorner = Instance.new("UICorner")
thumbsDownCorner.CornerRadius = UDim.new(0, 6)
thumbsDownCorner.Parent = thumbsDownBtn

local analyzeBtn = Instance.new("TextButton")
analyzeBtn.Size = UDim2.new(0, 90, 0, 32)
analyzeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
analyzeBtn.BorderSizePixel = 0
analyzeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
analyzeBtn.TextSize = 10
analyzeBtn.Font = Enum.Font.GothamBold
analyzeBtn.Text = "📊 Analyze"
analyzeBtn.LayoutOrder = 3
analyzeBtn.Parent = feedbackContainer

local analyzeCorner = Instance.new("UICorner")
analyzeCorner.CornerRadius = UDim.new(0, 6)
analyzeCorner.Parent = analyzeBtn

local optimizeBtn = Instance.new("TextButton")
optimizeBtn.Size = UDim2.new(0, 90, 0, 32)
optimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
optimizeBtn.BorderSizePixel = 0
optimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
optimizeBtn.TextSize = 10
optimizeBtn.Font = Enum.Font.GothamBold
optimizeBtn.Text = "⚡ Optimize"
optimizeBtn.LayoutOrder = 4
optimizeBtn.Parent = feedbackContainer

local optimizeCorner = Instance.new("UICorner")
optimizeCorner.CornerRadius = UDim.new(0, 6)
optimizeCorner.Parent = optimizeBtn

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
		-- Investigation phase (lemonade.gg style)
		logInvestigation("Analyzing project structure...")
		task.wait(0.3)
		
		logInvestigation("Scanned " .. #STATE.context.scripts .. " scripts")
		task.wait(0.2)
		
		-- PHASE 2: Smart detection
		local scriptType = PatternMatcher.detectScriptType(text)
		local location = PatternMatcher.getSuggestedLocation(scriptType)
		lastScriptType = scriptType
		lastLocation = location
		
		logInvestigation("Detected type: " .. scriptType)
		task.wait(0.2)
		
		local relevant = ContextScanner.findRelevantScripts(text, STATE.context)
		logInvestigation("Found " .. #relevant .. " relevant scripts")
		task.wait(0.2)
		
		local prompt = OllamaClient.buildPrompt(text, STATE.context, relevant)
		
		logInvestigation("Generating code from Ollama...")
		
		local success, code = OllamaClient.call(prompt, CONFIG.DEFAULT_MODEL)
		
		local frames = chatContainer:FindFirstChildOfClass("Frame")
		if frames then frames.Parent = nil end
		
		if success then
			lastGeneratedCode = code
			
			-- Save checkpoint
			Checkpoint.save(code, scriptType, "Generated for: " .. text:sub(1, 30))
			updateCheckpointList()
			
			addMessage(code, false, true)
			logInvestigation("✓ Code generated successfully")
			
			Memory.save(text, code)
		else
			addMessage("❌ Error: " .. code, false, false)
		end
	else
		-- Regular chat
		logInvestigation("Processing request...")
		task.wait(0.2)
		
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

-- ============================================================================
-- SCRIPT INJECTION & BUTTON HANDLERS
-- ============================================================================

-- Inject code into running game
injectBtn.MouseButton1Click:Connect(function()
	if lastGeneratedCode == "" then
		addMessage("❌ Generate code first!", false, false)
		return
	end
	
	-- Create a LocalScript in StarterPlayer to inject code
	local injectionCode = "load(" .. string.format("%q", "local code = " .. string.format("%q", lastGeneratedCode) .. "; load(code)()") .. ")()"
	
	-- Try multiple injection points
	local starterPlayer = game:GetService("StarterPlayer")
	
	-- Try StarterPlayerScripts first
	local starterScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
	if not starterScripts then
		starterScripts = Instance.new("LocalScript")
		starterScripts.Name = "StarterPlayerScripts"
		starterScripts.Parent = starterPlayer
	end
	
	local injectedScript = Instance.new("LocalScript")
	injectedScript.Name = "Injected_" .. tostring(math.random(10000, 99999))
	injectedScript.Source = injectionCode
	injectedScript.Parent = starterScripts
	
	addMessage("💉 Code injected into StarterPlayerScripts", false, false)
	addMessage("⚠️ Requires game restart to execute", false, false)
	
	-- Also log the action
	Memory.save("Injected: " .. lastScriptType, lastGeneratedCode)
end)

-- Copy to clipboard
copyClipBtn.MouseButton1Click:Connect(function()
	if lastGeneratedCode == "" then
		addMessage("❌ Generate code first!", false, false)
		return
	end
	
	setclipboard(lastGeneratedCode)
	addMessage("📋 Copied " .. tostring(#lastGeneratedCode) .. " chars to clipboard!", false, false)
end)

-- Feedback buttons
thumbsUpBtn.MouseButton1Click:Connect(function()
	if lastGeneratedCode == "" then
		addMessage("❌ Generate code first!", false, false)
		return
	end
	
	AdvancedLearning.recordThumbsUp(lastGeneratedCode)
	addMessage("✅ Liked! Learning your style...", false, false)
end)

thumbsDownBtn.MouseButton1Click:Connect(function()
	if lastGeneratedCode == "" then
		addMessage("❌ Generate code first!", false, false)
		return
	end
	
	AdvancedLearning.recordThumbsDown(lastGeneratedCode)
	addMessage("👎 Disliked. I'll avoid this approach.", false, false)
end)
		return
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

log("✓ Phase 3.2 loaded: Clean UI + Script injection!")
addMessage("🍋 Lemonade AI (Clean)\n💉 Inject code into running game\n📋 Copy to clipboard\n🔄 Checkpoint system\n🎯 Investigation logs", false, false)
