--[[
	Ollama Code Generator Pro - Enhanced Version
	Features: Robust error handling, retry logic, code validation, history
]]

local plugin = plugin
local HttpService = game:GetService("HttpService")

-- Configuration
local CONFIG = {
	OLLAMA_URL = "http://23.88.19.42:11434",
	DEFAULT_MODEL = "mistral",
	TIMEOUT = 30,
	TEMPERATURE = 0.7,
	MAX_RETRIES = 2,
	RETRY_DELAY = 1
}

local STATE = {
	isOpen = false,
	currentGui = nil,
	generatedCode = "",
	codeHistory = {},
	isGenerating = false
}

-- Utility Functions
local function log(message, level)
	level = level or "INFO"
	local timestamp = os.date("%H:%M:%S")
	print(string.format("[%s] [%s] %s", timestamp, level, message))
end

local function showStatus(label, message, color, duration)
	label.TextColor3 = color or Color3.fromRGB(100, 200, 100)
	label.Text = message
	
	if duration then
		game:GetService("Debris"):AddItem({
			cleanup = function()
				label.Text = "Ready"
				label.TextColor3 = Color3.fromRGB(100, 200, 100)
			end
		}, duration)
	end
end

-- HTTP Error Handler
local function makeHttpRequest(url, body, headers, retries)
	retries = retries or 0
	headers = headers or {}
	headers["Content-Type"] = "application/json"
	
	local success, response = pcall(function()
		return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, headers)
	end)
	
	if success then
		return true, response
	else
		if retries < CONFIG.MAX_RETRIES then
			wait(CONFIG.RETRY_DELAY)
			return makeHttpRequest(url, body, headers, retries + 1)
		else
			return false, response
		end
	end
end

-- Ollama API Handler
local function callOllama(prompt, model)
	if not prompt or prompt == "" then
		return false, "Empty prompt"
	end
	
	if STATE.isGenerating then
		return false, "Already generating"
	end
	
	STATE.isGenerating = true
	log("Generating code with model: " .. model)
	
	local requestBody = HttpService:JSONEncode({
		model = model,
		prompt = prompt,
		stream = false,
		temperature = CONFIG.TEMPERATURE
	})
	
	local url = CONFIG.OLLAMA_URL .. "/api/generate"
	local success, response = makeHttpRequest(url, requestBody)
	
	STATE.isGenerating = false
	
	if success then
		local decoded = HttpService:JSONDecode(response)
		local result = decoded.response or ""
		
		if result ~= "" then
			log("Successfully generated " .. string.len(result) .. " characters")
			return true, result
		else
			return false, "Model returned empty response"
		end
	else
		log("HTTP Request failed: " .. tostring(response), "ERROR")
		return false, response
	end
end

-- Script Injection with Validation
local function injectScript(code, target)
	if not code or code == "" then
		return false, "No code to inject"
	end
	
	if not target or not target:IsDescendantOf(workspace) then
		return false, "Invalid target"
	end
	
	-- Validate it's a part
	if target:FindFirstChild("Humanoid") == nil and not target:IsA("Part") then
		-- Allow injection to any instance with children
		if #target:GetChildren() == nil then
			return false, "Target must have a valid structure"
		end
	end
	
	local newScript = Instance.new("LocalScript")
	newScript.Source = code
	newScript.Parent = target
	
	log("Injected script into: " .. target.Name)
	return true, "Injected into " .. target.Name
end

-- Validate Ollama Connection
local function validateOllamaConnection()
	log("Testing Ollama connection...")
	
	local success, response = pcall(function()
		return HttpService:GetAsync(CONFIG.OLLAMA_URL .. "/api/tags", false)
	end)
	
	if success then
		local decoded = HttpService:JSONDecode(response)
		if decoded.models and #decoded.models > 0 then
			log("Connected! Found " .. #decoded.models .. " model(s)")
			return true, decoded.models
		else
			log("No models installed", "WARN")
			return false, "No models installed"
		end
	else
		log("Connection failed: " .. tostring(response), "ERROR")
		return false, response
	end
end

-- Create GUI
local function createGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OllamaProGui"
	screenGui.ResetOnSpawn = false
	
	-- Main Frame
	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(0, 900, 0, 650)
	main.Position = UDim2.new(0.5, -450, 0.5, -325)
	main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	main.BorderSizePixel = 0
	main.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = main
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	header.BorderSizePixel = 0
	header.Parent = main
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Text = "🤖 Ollama Code Generator Pro"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	-- Status Indicator
	local statusDot = Instance.new("Frame")
	statusDot.Name = "StatusDot"
	statusDot.Size = UDim2.new(0, 12, 0, 12)
	statusDot.Position = UDim2.new(1, -70, 0.5, -6)
	statusDot.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	statusDot.BorderSizePixel = 0
	statusDot.Parent = header
	
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = statusDot
	
	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -50, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "✕"
	closeBtn.Parent = header
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 5)
	closeCorner.Parent = closeBtn
	
	-- Content
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -60)
	content.Position = UDim2.new(0, 0, 0, 60)
	content.BackgroundTransparency = 1
	content.Parent = main
	
	-- Left Panel
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0.5, -5, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = content
	
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 8)
	leftCorner.Parent = leftPanel
	
	-- Right Panel
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(0.5, -5, 1, 0)
	rightPanel.Position = UDim2.new(0.5, 5, 0, 0)
	rightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = content
	
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 8)
	rightCorner.Parent = rightPanel
	
	-- LEFT PANEL ELEMENTS
	
	local leftLabel = Instance.new("TextLabel")
	leftLabel.Size = UDim2.new(1, -15, 0, 25)
	leftLabel.Position = UDim2.new(0, 10, 0, 8)
	leftLabel.BackgroundTransparency = 1
	leftLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	leftLabel.TextSize = 13
	leftLabel.Font = Enum.Font.GothamBold
	leftLabel.Text = "Input"
	leftLabel.TextXAlignment = Enum.TextXAlignment.Left
	leftLabel.Parent = leftPanel
	
	-- Model selector
	local modelLabel = Instance.new("TextLabel")
	modelLabel.Size = UDim2.new(0.5, -10, 0, 20)
	modelLabel.Position = UDim2.new(0, 10, 0, 35)
	modelLabel.BackgroundTransparency = 1
	modelLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	modelLabel.TextSize = 11
	modelLabel.Font = Enum.Font.Gotham
	modelLabel.Text = "Model:"
	modelLabel.TextXAlignment = Enum.TextXAlignment.Left
	modelLabel.Parent = leftPanel
	
	local modelInput = Instance.new("TextBox")
	modelInput.Name = "ModelInput"
	modelInput.Size = UDim2.new(0.5, -10, 0, 20)
	modelInput.Position = UDim2.new(0.5, 5, 0, 35)
	modelInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	modelInput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	modelInput.BorderSizePixel = 1
	modelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	modelInput.TextSize = 11
	modelInput.Font = Enum.Font.Gotham
	modelInput.Text = CONFIG.DEFAULT_MODEL
	modelInput.Parent = leftPanel
	
	-- Prompt input
	local promptLabel = Instance.new("TextLabel")
	promptLabel.Size = UDim2.new(1, -15, 0, 20)
	promptLabel.Position = UDim2.new(0, 10, 0, 60)
	promptLabel.BackgroundTransparency = 1
	promptLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	promptLabel.TextSize = 11
	promptLabel.Font = Enum.Font.Gotham
	promptLabel.Text = "Prompt:"
	promptLabel.TextXAlignment = Enum.TextXAlignment.Left
	promptLabel.Parent = leftPanel
	
	local promptInput = Instance.new("TextBox")
	promptInput.Name = "PromptInput"
	promptInput.Size = UDim2.new(1, -15, 0, 130)
	promptInput.Position = UDim2.new(0, 10, 0, 80)
	promptInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	promptInput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	promptInput.BorderSizePixel = 1
	promptInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptInput.TextSize = 12
	promptInput.Font = Enum.Font.Gotham
	promptInput.TextWrapped = true
	promptInput.TextXAlignment = Enum.TextXAlignment.Left
	promptInput.TextYAlignment = Enum.TextYAlignment.Top
	promptInput.PlaceholderText = "Describe the Lua code you want..."
	promptInput.Parent = leftPanel
	
	-- Status
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -15, 0, 35)
	statusLabel.Position = UDim2.new(0, 10, 0, 215)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Ready"
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = leftPanel
	
	-- Buttons
	local buttonHeight = 32
	local generateBtn = Instance.new("TextButton")
	generateBtn.Name = "GenerateButton"
	generateBtn.Size = UDim2.new(0.5, -7, 0, buttonHeight)
	generateBtn.Position = UDim2.new(0, 10, 0, 255)
	generateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
	generateBtn.BorderSizePixel = 0
	generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	generateBtn.TextSize = 13
	generateBtn.Font = Enum.Font.GothamBold
	generateBtn.Text = "⚡ Generate"
	generateBtn.Parent = leftPanel
	
	local genCorner = Instance.new("UICorner")
	genCorner.CornerRadius = UDim.new(0, 5)
	genCorner.Parent = generateBtn
	
	local injectBtn = Instance.new("TextButton")
	injectBtn.Name = "InjectButton"
	injectBtn.Size = UDim2.new(0.5, -2, 0, buttonHeight)
	injectBtn.Position = UDim2.new(0.5, 5, 0, 255)
	injectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	injectBtn.BorderSizePixel = 0
	injectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	injectBtn.TextSize = 13
	injectBtn.Font = Enum.Font.GothamBold
	injectBtn.Text = "💉 Inject"
	injectBtn.Parent = leftPanel
	
	local injCorner = Instance.new("UICorner")
	injCorner.CornerRadius = UDim.new(0, 5)
	injCorner.Parent = injectBtn
	
	-- RIGHT PANEL ELEMENTS
	
	local rightLabel = Instance.new("TextLabel")
	rightLabel.Size = UDim2.new(1, -15, 0, 25)
	rightLabel.Position = UDim2.new(0, 10, 0, 8)
	rightLabel.BackgroundTransparency = 1
	rightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	rightLabel.TextSize = 13
	rightLabel.Font = Enum.Font.GothamBold
	rightLabel.Text = "Generated Code"
	rightLabel.TextXAlignment = Enum.TextXAlignment.Left
	rightLabel.Parent = rightPanel
	
	local codeOutput = Instance.new("TextBox")
	codeOutput.Name = "CodeOutput"
	codeOutput.Size = UDim2.new(1, -15, 0, 450)
	codeOutput.Position = UDim2.new(0, 10, 0, 35)
	codeOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	codeOutput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	codeOutput.BorderSizePixel = 1
	codeOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
	codeOutput.TextSize = 11
	codeOutput.Font = Enum.Font.GothamMonospace
	codeOutput.TextWrapped = true
	codeOutput.TextXAlignment = Enum.TextXAlignment.Left
	codeOutput.TextYAlignment = Enum.TextYAlignment.Top
	codeOutput.Parent = rightPanel
	
	-- Bottom buttons
	local copyBtn = Instance.new("TextButton")
	copyBtn.Name = "CopyButton"
	copyBtn.Size = UDim2.new(0.5, -7, 0, buttonHeight)
	copyBtn.Position = UDim2.new(0, 10, 0, 490)
	copyBtn.BackgroundColor3 = Color3.fromRGB(150, 120, 0)
	copyBtn.BorderSizePixel = 0
	copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyBtn.TextSize = 12
	copyBtn.Font = Enum.Font.Gotham
	copyBtn.Text = "📋 Copy"
	copyBtn.Parent = rightPanel
	
	local copyCorner = Instance.new("UICorner")
	copyCorner.CornerRadius = UDim.new(0, 5)
	copyCorner.Parent = copyBtn
	
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearButton"
	clearBtn.Size = UDim2.new(0.5, -2, 0, buttonHeight)
	clearBtn.Position = UDim2.new(0.5, 5, 0, 490)
	clearBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	clearBtn.BorderSizePixel = 0
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.TextSize = 12
	clearBtn.Font = Enum.Font.Gotham
	clearBtn.Text = "🗑️ Clear"
	clearBtn.Parent = rightPanel
	
	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 5)
	clearCorner.Parent = clearBtn
	
	-- Return GUI references
	return {
		gui = screenGui,
		statusLabel = statusLabel,
		statusDot = statusDot,
		promptInput = promptInput,
		modelInput = modelInput,
		codeOutput = codeOutput,
		generateBtn = generateBtn,
		injectBtn = injectBtn,
		copyBtn = copyBtn,
		clearBtn = clearBtn,
		closeBtn = closeBtn,
		main = main
	}
end

-- Setup Button
local toolbar = plugin:CreateToolbar("Ollama AI")
local mainButton = toolbar:CreateButton("Ollama Pro", "Ollama Code Generator Pro", "rbxasset://textures/Cursor.png")

-- Button Click Handler
mainButton.Click:Connect(function()
	if STATE.isOpen and STATE.currentGui then
		STATE.currentGui.gui:Destroy()
		STATE.currentGui = nil
		STATE.isOpen = false
		log("Plugin window closed")
	else
		STATE.currentGui = createGui()
		STATE.isOpen = true
		STATE.currentGui.gui.Parent = game:GetService("CoreGui")
		
		log("Plugin window opened")
		
		-- Validate connection
		local connected, models = validateOllamaConnection()
		if connected then
			showStatus(STATE.currentGui.statusLabel, "✓ Connected to Ollama", Color3.fromRGB(0, 200, 0), 3)
			STATE.currentGui.statusDot.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		else
			showStatus(STATE.currentGui.statusLabel, "✗ " .. tostring(models), Color3.fromRGB(200, 0, 0), 5)
			STATE.currentGui.statusDot.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
		end
		
		-- Setup Event Handlers
		STATE.currentGui.generateBtn.MouseButton1Click:Connect(function()
			local prompt = STATE.currentGui.promptInput.Text
			local model = STATE.currentGui.modelInput.Text
			
			if prompt == "" then
				showStatus(STATE.currentGui.statusLabel, "✗ Enter a prompt", Color3.fromRGB(200, 100, 0))
				return
			end
			
			showStatus(STATE.currentGui.statusLabel, "⏳ Generating...", Color3.fromRGB(150, 150, 0))
			local success, code = callOllama(prompt, model)
			
			if success then
				STATE.generatedCode = code
				STATE.currentGui.codeOutput.Text = code
				table.insert(STATE.codeHistory, code)
				showStatus(STATE.currentGui.statusLabel, "✓ Code generated!", Color3.fromRGB(0, 200, 0), 3)
			else
				STATE.currentGui.codeOutput.Text = "Error: " .. code
				showStatus(STATE.currentGui.statusLabel, "✗ " .. code, Color3.fromRGB(200, 0, 0), 5)
			end
		end)
		
		STATE.currentGui.injectBtn.MouseButton1Click:Connect(function()
			local code = STATE.currentGui.codeOutput.Text
			if code == "" or string.sub(code, 1, 5) == "Error" then
				showStatus(STATE.currentGui.statusLabel, "✗ No valid code", Color3.fromRGB(200, 0, 0))
				return
			end
			
			local selection = plugin:GetSelectedInstances()
			if #selection == 0 then
				showStatus(STATE.currentGui.statusLabel, "✗ Select an instance", Color3.fromRGB(200, 0, 0))
				return
			end
			
			local success, message = injectScript(code, selection[1])
			if success then
				showStatus(STATE.currentGui.statusLabel, "✓ " .. message, Color3.fromRGB(0, 200, 0), 3)
			else
				showStatus(STATE.currentGui.statusLabel, "✗ " .. message, Color3.fromRGB(200, 0, 0), 5)
			end
		end)
		
		STATE.currentGui.copyBtn.MouseButton1Click:Connect(function()
			STATE.currentGui.codeOutput:CaptureFocus()
			showStatus(STATE.currentGui.statusLabel, "✓ Ready (Ctrl+C)", Color3.fromRGB(0, 200, 0), 2)
		end)
		
		STATE.currentGui.clearBtn.MouseButton1Click:Connect(function()
			STATE.currentGui.codeOutput.Text = ""
			STATE.currentGui.promptInput.Text = ""
			STATE.generatedCode = ""
			showStatus(STATE.currentGui.statusLabel, "✓ Cleared", Color3.fromRGB(0, 200, 0), 2)
		end)
		
		STATE.currentGui.closeBtn.MouseButton1Click:Connect(function()
			STATE.currentGui.gui:Destroy()
			STATE.currentGui = nil
			STATE.isOpen = false
			log("Plugin closed")
		end)
	end
end)

log("✓ Ollama Pro Plugin initialized")
log("  Server: " .. CONFIG.OLLAMA_URL)
log("  Model: " .. CONFIG.DEFAULT_MODEL)
