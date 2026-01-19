--[[
	Advanced Roblox Ollama Plugin
	Features:
	- Connect to Ollama API
	- Generate Lua code from prompts
	- Inject scripts into selected instances
	- Chat-based interface
	- Code history
]]

local plugin = plugin
local HttpService = game:GetService("HttpService")

-- Configuration
local CONFIG = {
	OLLAMA_URL = "http://23.88.19.42:11434",
	DEFAULT_MODEL = "mistral",
	TIMEOUT = 30,
	TEMPERATURE = 0.7
}

-- Create toolbar
local toolbar = plugin:CreateToolbar("Ollama AI")
local mainButton = toolbar:CreateButton("Open Ollama AI", "Open Ollama Code Generator", "rbxasset://textures/Cursor.png")

-- GUI State
local isGuiOpen = false
local mainGui = nil
local codeHistory = {}

-- Function to create main GUI
local function createMainGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "OllamaAIGui"
	screenGui.ResetOnSpawn = false
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 800, 0, 600)
	container.Position = UDim2.new(0.5, -400, 0.5, -300)
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	container.BorderSizePixel = 0
	container.Parent = screenGui
	
	-- Add corner radius effect
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = container
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	header.BorderSizePixel = 0
	header.Parent = container
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = header
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Text = "Ollama Code Generator"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "✕"
	closeBtn.Parent = header
	
	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 5)
	closeBtnCorner.Parent = closeBtn
	
	-- Content area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -50)
	content.Position = UDim2.new(0, 0, 0, 50)
	content.BackgroundTransparency = 1
	content.Parent = container
	
	-- Left panel (Chat/Input)
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0.5, -5, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = content
	
	-- Right panel (Output)
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(0.5, -5, 1, 0)
	rightPanel.Position = UDim2.new(0.5, 5, 0, 0)
	rightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = content
	
	-- Left panel label
	local leftLabel = Instance.new("TextLabel")
	leftLabel.Size = UDim2.new(1, -10, 0, 25)
	leftLabel.Position = UDim2.new(0, 5, 0, 5)
	leftLabel.BackgroundTransparency = 1
	leftLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	leftLabel.TextSize = 12
	leftLabel.Font = Enum.Font.GothamBold
	leftLabel.Text = "Input"
	leftLabel.TextXAlignment = Enum.TextXAlignment.Left
	leftLabel.Parent = leftPanel
	
	-- Model selection
	local modelLabel = Instance.new("TextLabel")
	modelLabel.Size = UDim2.new(0.5, -10, 0, 20)
	modelLabel.Position = UDim2.new(0, 5, 0, 30)
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
	modelInput.Position = UDim2.new(0.5, 5, 0, 30)
	modelInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	modelInput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	modelInput.BorderSizePixel = 1
	modelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	modelInput.TextSize = 11
	modelInput.Font = Enum.Font.Gotham
	modelInput.Text = CONFIG.DEFAULT_MODEL
	modelInput.Parent = leftPanel
	
	-- Prompt input
	local promptInput = Instance.new("TextBox")
	promptInput.Name = "PromptInput"
	promptInput.Size = UDim2.new(1, -10, 0, 120)
	promptInput.Position = UDim2.new(0, 5, 0, 55)
	promptInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	promptInput.BorderColor3 = Color3.fromRGB(100, 100, 120)
	promptInput.BorderSizePixel = 1
	promptInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	promptInput.TextSize = 12
	promptInput.Font = Enum.Font.Gotham
	promptInput.TextWrapped = true
	promptInput.TextXAlignment = Enum.TextXAlignment.Left
	promptInput.TextYAlignment = Enum.TextYAlignment.Top
	promptInput.PlaceholderText = "Describe the code you want to generate..."
	promptInput.Parent = leftPanel
	
	-- Status label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -10, 0, 30)
	statusLabel.Position = UDim2.new(0, 5, 0, 180)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Ready"
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = leftPanel
	
	-- Buttons
	local buttonSize = UDim2.new(0.5, -7, 0, 35)
	
	local generateBtn = Instance.new("TextButton")
	generateBtn.Name = "GenerateButton"
	generateBtn.Size = buttonSize
	generateBtn.Position = UDim2.new(0, 5, 0, 215)
	generateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
	generateBtn.BorderSizePixel = 0
	generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	generateBtn.TextSize = 13
	generateBtn.Font = Enum.Font.GothamBold
	generateBtn.Text = "Generate"
	generateBtn.Parent = leftPanel
	
	local generateBtnCorner = Instance.new("UICorner")
	generateBtnCorner.CornerRadius = UDim.new(0, 5)
	generateBtnCorner.Parent = generateBtn
	
	local injectBtn = Instance.new("TextButton")
	injectBtn.Name = "InjectButton"
	injectBtn.Size = buttonSize
	injectBtn.Position = UDim2.new(0.5, 2, 0, 215)
	injectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	injectBtn.BorderSizePixel = 0
	injectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	injectBtn.TextSize = 13
	injectBtn.Font = Enum.Font.GothamBold
	injectBtn.Text = "Inject"
	injectBtn.Parent = leftPanel
	
	local injectBtnCorner = Instance.new("UICorner")
	injectBtnCorner.CornerRadius = UDim.new(0, 5)
	injectBtnCorner.Parent = injectBtn
	
	-- Right panel
	local rightLabel = Instance.new("TextLabel")
	rightLabel.Size = UDim2.new(1, -10, 0, 25)
	rightLabel.Position = UDim2.new(0, 5, 0, 5)
	rightLabel.BackgroundTransparency = 1
	rightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	rightLabel.TextSize = 12
	rightLabel.Font = Enum.Font.GothamBold
	rightLabel.Text = "Generated Code"
	rightLabel.TextXAlignment = Enum.TextXAlignment.Left
	rightLabel.Parent = rightPanel
	
	-- Output code
	local codeOutput = Instance.new("TextBox")
	codeOutput.Name = "CodeOutput"
	codeOutput.Size = UDim2.new(1, -10, 0, 400)
	codeOutput.Position = UDim2.new(0, 5, 0, 30)
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
	copyBtn.Size = UDim2.new(0.5, -7, 0, 30)
	copyBtn.Position = UDim2.new(0, 5, 0, 435)
	copyBtn.BackgroundColor3 = Color3.fromRGB(150, 120, 0)
	copyBtn.BorderSizePixel = 0
	copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyBtn.TextSize = 12
	copyBtn.Font = Enum.Font.Gotham
	copyBtn.Text = "Copy"
	copyBtn.Parent = rightPanel
	
	local copyBtnCorner = Instance.new("UICorner")
	copyBtnCorner.CornerRadius = UDim.new(0, 5)
	copyBtnCorner.Parent = copyBtn
	
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearButton"
	clearBtn.Size = UDim2.new(0.5, -2, 0, 30)
	clearBtn.Position = UDim2.new(0.5, 5, 0, 435)
	clearBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	clearBtn.BorderSizePixel = 0
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.TextSize = 12
	clearBtn.Font = Enum.Font.Gotham
	clearBtn.Text = "Clear"
	clearBtn.Parent = rightPanel
	
	local clearBtnCorner = Instance.new("UICorner")
	clearBtnCorner.CornerRadius = UDim.new(0, 5)
	clearBtnCorner.Parent = clearBtn
	
	-- Store references
	local gui = {
		screenGui = screenGui,
		container = container,
		statusLabel = statusLabel,
		promptInput = promptInput,
		modelInput = modelInput,
		codeOutput = codeOutput,
		generateBtn = generateBtn,
		injectBtn = injectBtn,
		copyBtn = copyBtn,
		clearBtn = clearBtn,
		closeBtn = closeBtn
	}
	
	return gui
end

-- Function to call Ollama API
local function callOllama(prompt, model, statusLabel)
	statusLabel.Text = "Connecting to Ollama..."
	
	local success, response = pcall(function()
		local requestBody = HttpService:JSONEncode({
			model = model,
			prompt = prompt,
			stream = false,
			temperature = CONFIG.TEMPERATURE
		})
		
		local url = CONFIG.OLLAMA_URL .. "/api/generate"
		local result = HttpService:PostAsync(url, requestBody, Enum.HttpContentType.ApplicationJson, false)
		
		return result
	end)
	
	if success then
		local decoded = HttpService:JSONDecode(response)
		statusLabel.Text = "✓ Generation complete"
		return decoded.response or "No response"
	else
		statusLabel.Text = "✗ Error: " .. tostring(response)
		return "Error: " .. tostring(response)
	end
end

-- Function to inject script
local function injectScriptToSelection(code, statusLabel)
	local selection = plugin:GetSelectedInstances()
	
	if #selection == 0 then
		statusLabel.Text = "✗ Error: Select a part to inject into"
		return false
	end
	
	local target = selection[1]
	local newScript = Instance.new("LocalScript")
	newScript.Source = code
	newScript.Parent = target
	
	statusLabel.Text = "✓ Injected into " .. target.Name
	return true
end

-- Setup main button
mainButton.Click:Connect(function()
	if isGuiOpen and mainGui then
		mainGui.screenGui:Destroy()
		mainGui = nil
		isGuiOpen = false
	else
		mainGui = createMainGui()
		isGuiOpen = true
		
		-- Setup event handlers
		mainGui.generateBtn.MouseButton1Click:Connect(function()
			local prompt = mainGui.promptInput.Text
			local model = mainGui.modelInput.Text
			
			if prompt == "" then
				mainGui.statusLabel.Text = "✗ Error: Enter a prompt"
				return
			end
			
			local code = callOllama(prompt, model, mainGui.statusLabel)
			mainGui.codeOutput.Text = code
			table.insert(codeHistory, code)
		end)
		
		mainGui.injectBtn.MouseButton1Click:Connect(function()
			local code = mainGui.codeOutput.Text
			if code == "" then
				mainGui.statusLabel.Text = "✗ Error: No code to inject"
				return
			end
			injectScriptToSelection(code, mainGui.statusLabel)
		end)
		
		mainGui.copyBtn.MouseButton1Click:Connect(function()
			mainGui.codeOutput:CaptureFocus()
			mainGui.statusLabel.Text = "✓ Ready to copy (Ctrl+C)"
		end)
		
		mainGui.clearBtn.MouseButton1Click:Connect(function()
			mainGui.codeOutput.Text = ""
			mainGui.promptInput.Text = ""
			mainGui.statusLabel.Text = "Cleared"
		end)
		
		mainGui.closeBtn.MouseButton1Click:Connect(function()
			mainGui.screenGui:Destroy()
			mainGui = nil
			isGuiOpen = false
		end)
		
		mainGui.screenGui.Parent = game:GetService("CoreGui")
	end
end)

print("✓ Ollama Code Generator Plugin loaded")
print("  Server: " .. CONFIG.OLLAMA_URL)
print("  Default Model: " .. CONFIG.DEFAULT_MODEL)
