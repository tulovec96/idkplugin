--[[
	Ollama AI Code Generator Pro
	Generate code + AI-powered action plans
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
	isGenerating = false
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
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OllamaAIGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = widget

-- Main content frame
local main = Instance.new("Frame")
main.Size = UDim2.new(1, 0, 1, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
main.BorderSizePixel = 0
main.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(100, 200, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Text = "🤖 Ollama AI Code Generator"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Content - 3 panels
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -70)
content.Position = UDim2.new(0, 0, 0, 70)
content.BackgroundTransparency = 1
content.Parent = main

-- Left panel - Input
local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0.33, -4, 1, 0)
leftPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
leftPanel.BorderSizePixel = 0
leftPanel.Parent = content

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 12)
leftCorner.Parent = leftPanel

-- Middle panel - Plan
local midPanel = Instance.new("Frame")
midPanel.Size = UDim2.new(0.33, -4, 1, 0)
midPanel.Position = UDim2.new(0.33, 2, 0, 0)
midPanel.BackgroundColor3 = Color3.fromRGB(28, 35, 45)
midPanel.BorderSizePixel = 0
midPanel.Parent = content

local midCorner = Instance.new("UICorner")
midCorner.CornerRadius = UDim.new(0, 12)
midCorner.Parent = midPanel

-- Right panel - Code
local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0.33, -4, 1, 0)
rightPanel.Position = UDim2.new(0.66, 4, 0, 0)
rightPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
rightPanel.BorderSizePixel = 0
rightPanel.Parent = content

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 12)
rightCorner.Parent = rightPanel

-- LEFT PANEL - Input
local leftTitle = Instance.new("TextLabel")
leftTitle.Size = UDim2.new(1, -20, 0, 30)
leftTitle.Position = UDim2.new(0, 10, 0, 10)
leftTitle.BackgroundTransparency = 1
leftTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
leftTitle.TextSize = 16
leftTitle.Font = Enum.Font.GothamBold
leftTitle.Text = "📝 Your Request"
leftTitle.TextXAlignment = Enum.TextXAlignment.Left
leftTitle.Parent = leftPanel

local modelLabel = Instance.new("TextLabel")
modelLabel.Size = UDim2.new(0.5, -10, 0, 20)
modelLabel.Position = UDim2.new(0, 10, 0, 45)
modelLabel.BackgroundTransparency = 1
modelLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
modelLabel.TextSize = 11
modelLabel.Font = Enum.Font.Gotham
modelLabel.Text = "Model:"
modelLabel.TextXAlignment = Enum.TextXAlignment.Left
modelLabel.Parent = leftPanel

local modelInput = Instance.new("TextBox")
modelInput.Size = UDim2.new(0.5, -10, 0, 22)
modelInput.Position = UDim2.new(0.5, 5, 0, 45)
modelInput.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
modelInput.BorderColor3 = Color3.fromRGB(100, 150, 200)
modelInput.BorderSizePixel = 1
modelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
modelInput.TextSize = 11
modelInput.Font = Enum.Font.Gotham
modelInput.Text = CONFIG.DEFAULT_MODEL
modelInput.Parent = leftPanel

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, -20, 0, 20)
promptLabel.Position = UDim2.new(0, 10, 0, 72)
promptLabel.BackgroundTransparency = 1
promptLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
promptLabel.TextSize = 12
promptLabel.Font = Enum.Font.GothamBold
promptLabel.Text = "What do you need?"
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Parent = leftPanel

local promptInput = Instance.new("TextBox")
promptInput.Size = UDim2.new(1, -20, 0, 200)
promptInput.Position = UDim2.new(0, 10, 0, 95)
promptInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
promptInput.BorderColor3 = Color3.fromRGB(100, 150, 200)
promptInput.BorderSizePixel = 1
promptInput.TextColor3 = Color3.fromRGB(255, 255, 255)
promptInput.TextSize = 12
promptInput.Font = Enum.Font.Gotham
promptInput.TextWrapped = true
promptInput.TextXAlignment = Enum.TextXAlignment.Left
promptInput.TextYAlignment = Enum.TextYAlignment.Top
promptInput.PlaceholderText = "Describe what you want to build..."
promptInput.Parent = leftPanel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 50)
statusLabel.Position = UDim2.new(0, 10, 0, 300)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "✓ Ready"
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = leftPanel

local generateBtn = Instance.new("TextButton")
generateBtn.Size = UDim2.new(1, -20, 0, 45)
generateBtn.Position = UDim2.new(0, 10, 0, 360)
generateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
generateBtn.BorderSizePixel = 0
generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
generateBtn.TextSize = 15
generateBtn.Font = Enum.Font.GothamBold
generateBtn.Text = "⚡ Generate Code"
generateBtn.Parent = leftPanel

local genCorner = Instance.new("UICorner")
genCorner.CornerRadius = UDim.new(0, 8)
genCorner.Parent = generateBtn

local planBtn = Instance.new("TextButton")
planBtn.Size = UDim2.new(1, -20, 0, 45)
planBtn.Position = UDim2.new(0, 10, 0, 410)
planBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
planBtn.BorderSizePixel = 0
planBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
planBtn.TextSize = 15
planBtn.Font = Enum.Font.GothamBold
planBtn.Text = "📋 Generate Plan"
planBtn.Parent = leftPanel

local planCorner = Instance.new("UICorner")
planCorner.CornerRadius = UDim.new(0, 8)
planCorner.Parent = planBtn

local executeBtn = Instance.new("TextButton")
executeBtn.Size = UDim2.new(1, -20, 0, 45)
executeBtn.Position = UDim2.new(0, 10, 0, 460)
executeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
executeBtn.BorderSizePixel = 0
executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
executeBtn.TextSize = 15
executeBtn.Font = Enum.Font.GothamBold
executeBtn.Text = "💉 Create in Game"
executeBtn.Parent = leftPanel

local exeCorner = Instance.new("UICorner")
exeCorner.CornerRadius = UDim.new(0, 8)
exeCorner.Parent = executeBtn

-- MIDDLE PANEL - Plan
local planTitle = Instance.new("TextLabel")
planTitle.Size = UDim2.new(1, -20, 0, 30)
planTitle.Position = UDim2.new(0, 10, 0, 10)
planTitle.BackgroundTransparency = 1
planTitle.TextColor3 = Color3.fromRGB(150, 180, 100)
planTitle.TextSize = 16
planTitle.Font = Enum.Font.GothamBold
planTitle.Text = "📋 Action Plan"
planTitle.TextXAlignment = Enum.TextXAlignment.Left
planTitle.Parent = midPanel

local planOutput = Instance.new("TextBox")
planOutput.Size = UDim2.new(1, -20, 1, -50)
planOutput.Position = UDim2.new(0, 10, 0, 45)
planOutput.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
planOutput.BorderColor3 = Color3.fromRGB(100, 150, 150)
planOutput.BorderSizePixel = 1
planOutput.TextColor3 = Color3.fromRGB(150, 200, 150)
planOutput.TextSize = 11
planOutput.Font = Enum.Font.Code
planOutput.TextWrapped = true
planOutput.TextXAlignment = Enum.TextXAlignment.Left
planOutput.TextYAlignment = Enum.TextYAlignment.Top
planOutput.PlaceholderText = "AI will generate a step-by-step plan here..."
planOutput.Parent = midPanel

-- RIGHT PANEL - Code
local codeTitle = Instance.new("TextLabel")
codeTitle.Size = UDim2.new(1, -20, 0, 30)
codeTitle.Position = UDim2.new(0, 10, 0, 10)
codeTitle.BackgroundTransparency = 1
codeTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
codeTitle.TextSize = 16
codeTitle.Font = Enum.Font.GothamBold
codeTitle.Text = "💻 Generated Code"
codeTitle.TextXAlignment = Enum.TextXAlignment.Left
codeTitle.Parent = rightPanel

local codeOutput = Instance.new("TextBox")
codeOutput.Size = UDim2.new(1, -20, 1, -110)
codeOutput.Position = UDim2.new(0, 10, 0, 45)
codeOutput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
codeOutput.BorderColor3 = Color3.fromRGB(100, 200, 100)
codeOutput.BorderSizePixel = 1
codeOutput.TextColor3 = Color3.fromRGB(0, 255, 0)
codeOutput.TextSize = 10
codeOutput.Font = Enum.Font.Code
codeOutput.TextWrapped = true
codeOutput.TextXAlignment = Enum.TextXAlignment.Left
codeOutput.TextYAlignment = Enum.TextYAlignment.Top
codeOutput.PlaceholderText = "Generated Lua code will appear here..."
codeOutput.Parent = rightPanel

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.5, -7, 0, 35)
copyBtn.Position = UDim2.new(0, 10, 1, -40)
copyBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 50)
copyBtn.BorderSizePixel = 0
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.TextSize = 12
copyBtn.Font = Enum.Font.Gotham
copyBtn.Text = "📋 Copy"
copyBtn.Parent = rightPanel

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 6)
copyCorner.Parent = copyBtn

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.5, -2, 0, 35)
clearBtn.Position = UDim2.new(0.5, 5, 1, -40)
clearBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
clearBtn.BorderSizePixel = 0
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.TextSize = 12
clearBtn.Font = Enum.Font.Gotham
clearBtn.Text = "🗑️ Clear"
clearBtn.Parent = rightPanel

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 6)
clearCorner.Parent = clearBtn

-- Event handlers
local generatedCode = ""
local generatedPlan = ""

generateBtn.MouseButton1Click:Connect(function()
	local prompt = promptInput.Text
	local model = modelInput.Text
	
	if prompt == "" then
		statusLabel.Text = "✗ Enter a request!"
		statusLabel.TextColor3 = Color3.fromRGB(200, 100, 0)
		return
	end
	
	statusLabel.Text = "⏳ Generating code..."
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 0)
	
	local success, code = callOllama(prompt, model)
	if success then
		generatedCode = code
		codeOutput.Text = code
		statusLabel.Text = "✓ Code generated!"
		statusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
		log("Generated code: " .. string.len(code) .. " chars")
	else
		statusLabel.Text = "✗ Error: " .. code
		statusLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
	end
end)

planBtn.MouseButton1Click:Connect(function()
	local prompt = promptInput.Text
	local model = modelInput.Text
	
	if prompt == "" then
		statusLabel.Text = "✗ Enter a request first!"
		statusLabel.TextColor3 = Color3.fromRGB(200, 100, 0)
		return
	end
	
	statusLabel.Text = "⏳ Creating action plan..."
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 0)
	
	local planPrompt = "Create a step-by-step action plan for: " .. prompt .. "\nFormat as numbered list of specific, actionable steps."
	local success, plan = callOllama(planPrompt, model)
	
	if success then
		generatedPlan = plan
		planOutput.Text = plan
		statusLabel.Text = "✓ Plan generated!"
		statusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
		log("Generated plan: " .. string.len(plan) .. " chars")
	else
		statusLabel.Text = "✗ Error: " .. plan
		statusLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
	end
end)

executeBtn.MouseButton1Click:Connect(function()
	if generatedCode == "" then
		statusLabel.Text = "✗ Generate code first!"
		statusLabel.TextColor3 = Color3.fromRGB(200, 100, 0)
		return
	end
	
	statusLabel.Text = "⏳ Executing..."
	statusLabel.TextColor3 = Color3.fromRGB(150, 150, 0)
	
	local script = Instance.new("LocalScript")
	script.Name = "OllamaGenerated_" .. tostring(math.random(10000, 99999))
	script.Source = generatedCode
	script.Parent = workspace
	
	statusLabel.Text = "✓ Scripts created in workspace!"
	statusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
	log("Scripts injected!")
end)

copyBtn.MouseButton1Click:Connect(function()
	codeOutput:CaptureFocus()
	statusLabel.Text = "✓ Copy with Ctrl+C"
	statusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
end)

clearBtn.MouseButton1Click:Connect(function()
	codeOutput.Text = ""
	planOutput.Text = ""
	generatedCode = ""
	generatedPlan = ""
	statusLabel.Text = "✓ Cleared"
	statusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
end)

-- Cleanup
plugin.Unloading:Connect(function()
	widget:Destroy()
end)

log("✓ Ready! Server: " .. CONFIG.OLLAMA_URL)
log("✓ Click 'Toggle' button in toolbar to open Ollama AI window")
