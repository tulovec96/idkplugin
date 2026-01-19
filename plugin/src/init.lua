--[[
	Ollama Code Generator - AI Script Creator
	Generate and inject scripts directly into your Roblox game
]]

local plugin = plugin
local HttpService = game:GetService("HttpService")

local CONFIG = {
	OLLAMA_URL = "http://23.88.19.42:11434",
	DEFAULT_MODEL = "mistral",
	TEMPERATURE = 0.7,
}

local STATE = {
	isOpen = false,
	currentGui = nil,
	generatedCode = "",
	isGenerating = false
}

local function log(msg)
	print("[OllamaAI] " .. msg)
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

local function createGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OllamaAI"
	screenGui.ResetOnSpawn = false
	
	local main = Instance.new("Frame")
	main.Size = UDim2.new(0, 900, 0, 700)
	main.Position = UDim2.new(0.5, -450, 0.5, -350)
	main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	main.BorderSizePixel = 0
	main.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = main
	
	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	header.BorderSizePixel = 0
	header.Parent = main
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Text = "🤖 Ollama AI - Script Generator"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	local closeBtn = Instance.new("TextButton")
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
	
	-- Content area
	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, 0, 1, -60)
	content.Position = UDim2.new(0, 0, 0, 60)
	content.BackgroundTransparency = 1
	content.Parent = main
	
	-- Left panel
	local leftPanel = Instance.new("Frame")
	leftPanel.Size = UDim2.new(0.5, -5, 1, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = content
	
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 8)
	leftCorner.Parent = leftPanel
	
	-- Right panel
	local rightPanel = Instance.new("Frame")
	rightPanel.Size = UDim2.new(0.5, -5, 1, 0)
	rightPanel.Position = UDim2.new(0.5, 5, 0, 0)
	rightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = content
	
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 8)
	rightCorner.Parent = rightPanel
	
	-- Left: Model
	local modelLabel = Instance.new("TextLabel")
	modelLabel.Size = UDim2.new(0.5, -10, 0, 20)
	modelLabel.Position = UDim2.new(0, 10, 0, 10)
	modelLabel.BackgroundTransparency = 1
	modelLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	modelLabel.TextSize = 11
	modelLabel.Font = Enum.Font.Gotham
	modelLabel.Text = "Model:"
	modelLabel.TextXAlignment = Enum.TextXAlignment.Left
	modelLabel.Parent = leftPanel
	
	local modelInput = Instance.new("TextBox")
	modelInput.Size = UDim2.new(0.5, -10, 0, 20)
	modelInput.Position = UDim2.new(0.5, 5, 0, 10)
	modelInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	modelInput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	modelInput.BorderSizePixel = 1
	modelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	modelInput.TextSize = 11
	modelInput.Font = Enum.Font.Gotham
	modelInput.Text = CONFIG.DEFAULT_MODEL
	modelInput.Parent = leftPanel
	
	-- Left: Prompt
	local promptLabel = Instance.new("TextLabel")
	promptLabel.Size = UDim2.new(1, -15, 0, 20)
	promptLabel.Position = UDim2.new(0, 10, 0, 35)
	promptLabel.BackgroundTransparency = 1
	promptLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	promptLabel.TextSize = 12
	promptLabel.Font = Enum.Font.GothamBold
	promptLabel.Text = "What code do you want?"
	promptLabel.TextXAlignment = Enum.TextXAlignment.Left
	promptLabel.Parent = leftPanel
	
	local promptInput = Instance.new("TextBox")
	promptInput.Size = UDim2.new(1, -15, 0, 150)
	promptInput.Position = UDim2.new(0, 10, 0, 55)
	promptInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	promptInput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	promptInput.BorderSizePixel = 1
	promptInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptInput.TextSize = 12
	promptInput.Font = Enum.Font.Gotham
	promptInput.TextWrapped = true
	promptInput.TextXAlignment = Enum.TextXAlignment.Left
	promptInput.TextYAlignment = Enum.TextYAlignment.Top
	promptInput.PlaceholderText = "E.g., 'Create a script that adds a part to workspace every 5 seconds'"
	promptInput.Parent = leftPanel
	
	-- Status
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -15, 0, 40)
	statusLabel.Position = UDim2.new(0, 10, 0, 210)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Ready to generate code!"
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = leftPanel
	
	-- Buttons
	local generateBtn = Instance.new("TextButton")
	generateBtn.Size = UDim2.new(1, -15, 0, 35)
	generateBtn.Position = UDim2.new(0, 10, 0, 255)
	generateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
	generateBtn.BorderSizePixel = 0
	generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	generateBtn.TextSize = 14
	generateBtn.Font = Enum.Font.GothamBold
	generateBtn.Text = "⚡ Generate Code"
	generateBtn.Parent = leftPanel
	
	local genCorner = Instance.new("UICorner")
	genCorner.CornerRadius = UDim.new(0, 5)
	genCorner.Parent = generateBtn
	
	local executeBtn = Instance.new("TextButton")
	executeBtn.Size = UDim2.new(1, -15, 0, 35)
	executeBtn.Position = UDim2.new(0, 10, 0, 295)
	executeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	executeBtn.BorderSizePixel = 0
	executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	executeBtn.TextSize = 14
	executeBtn.Font = Enum.Font.GothamBold
	executeBtn.Text = "💉 Create Scripts in Game"
	executeBtn.Parent = leftPanel
	
	local exeCorner = Instance.new("UICorner")
	exeCorner.CornerRadius = UDim.new(0, 5)
	exeCorner.Parent = executeBtn
	
	-- Right: Code output
	local outputLabel = Instance.new("TextLabel")
	outputLabel.Size = UDim2.new(1, -15, 0, 20)
	outputLabel.Position = UDim2.new(0, 10, 0, 10)
	outputLabel.BackgroundTransparency = 1
	outputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	outputLabel.TextSize = 12
	outputLabel.Font = Enum.Font.GothamBold
	outputLabel.Text = "Generated Code"
	outputLabel.TextXAlignment = Enum.TextXAlignment.Left
	outputLabel.Parent = rightPanel
	
	local codeOutput = Instance.new("TextBox")
	codeOutput.Size = UDim2.new(1, -15, 0, 580)
	codeOutput.Position = UDim2.new(0, 10, 0, 35)
	codeOutput.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	codeOutput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	codeOutput.BorderSizePixel = 1
	codeOutput.TextColor3 = Color3.fromRGB(0, 255, 100)
	codeOutput.TextSize = 10
	codeOutput.Font = Enum.Font.GothamMonospace
	codeOutput.TextWrapped = true
	codeOutput.TextXAlignment = Enum.TextXAlignment.Left
	codeOutput.TextYAlignment = Enum.TextYAlignment.Top
	codeOutput.Parent = rightPanel
	
	return {
		gui = screenGui,
		modelInput = modelInput,
		promptInput = promptInput,
		statusLabel = statusLabel,
		codeOutput = codeOutput,
		generateBtn = generateBtn,
		executeBtn = executeBtn,
		closeBtn = closeBtn
	}
end

-- Main toolbar button
local toolbar = plugin:CreateToolbar("Ollama AI")
local mainButton = toolbar:CreateButton("Ollama AI", "AI Script Generator", "rbxasset://textures/Cursor.png")

mainButton.Click:Connect(function()
	if STATE.isOpen and STATE.currentGui then
		STATE.currentGui.gui:Destroy()
		STATE.currentGui = nil
		STATE.isOpen = false
	else
		STATE.currentGui = createGui()
		STATE.isOpen = true
		STATE.currentGui.gui.Parent = game:GetService("CoreGui")
		log("Plugin opened")
		
		-- Generate button
		STATE.currentGui.generateBtn.MouseButton1Click:Connect(function()
			local prompt = STATE.currentGui.promptInput.Text
			local model = STATE.currentGui.modelInput.Text
			
			if prompt == "" then
				STATE.currentGui.statusLabel.Text = "✗ Enter a prompt!"
				STATE.currentGui.statusLabel.TextColor3 = Color3.fromRGB(200, 100, 0)
				return
			end
			
			STATE.currentGui.statusLabel.Text = "⏳ Generating..."
			STATE.currentGui.statusLabel.TextColor3 = Color3.fromRGB(150, 150, 0)
			
			local success, code = callOllama(prompt, model)
			if success then
				STATE.generatedCode = code
				STATE.currentGui.codeOutput.Text = code
				STATE.currentGui.statusLabel.Text = "✓ Code generated! Click 'Create Scripts in Game' to add it."
				STATE.currentGui.statusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
				log("Code generated: " .. string.len(code) .. " chars")
			else
				STATE.currentGui.codeOutput.Text = "Error: " .. code
				STATE.currentGui.statusLabel.Text = "✗ Error: " .. code
				STATE.currentGui.statusLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
			end
		end)
		
		-- Execute button - creates scripts in workspace
		STATE.currentGui.executeBtn.MouseButton1Click:Connect(function()
			if STATE.generatedCode == "" then
				STATE.currentGui.statusLabel.Text = "✗ Generate code first!"
				STATE.currentGui.statusLabel.TextColor3 = Color3.fromRGB(200, 100, 0)
				return
			end
			
			STATE.currentGui.statusLabel.Text = "⏳ Creating scripts..."
			STATE.currentGui.statusLabel.TextColor3 = Color3.fromRGB(150, 150, 0)
			
			-- Create a container script
			local script = Instance.new("LocalScript")
			script.Name = "OllamaGenerated"
			script.Source = STATE.generatedCode
			script.Parent = workspace
			
			STATE.currentGui.statusLabel.Text = "✓ Scripts created in workspace!"
			STATE.currentGui.statusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
			log("Scripts injected into workspace")
		end)
		
		-- Close button
		STATE.currentGui.closeBtn.MouseButton1Click:Connect(function()
			STATE.currentGui.gui:Destroy()
			STATE.currentGui = nil
			STATE.isOpen = false
			log("Plugin closed")
		end)
	end
end)

log("✓ Plugin loaded - Ollama AI Script Generator")
