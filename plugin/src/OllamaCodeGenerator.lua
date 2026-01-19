--[[
	Roblox Ollama Code Generator Plugin
	Connects to Ollama API and generates code with script injection capabilities
	Ollama Host: http://23.88.19.42:11434/
]]

local plugin = plugin
local toolbar = plugin:CreateToolbar("Ollama AI")
local button = toolbar:CreateButton("Generate Code", "Generate code with Ollama AI", "rbxasset://textures/Cursor.png")

local OLLAMA_URL = "http://23.88.19.42:11434"
local MODEL_NAME = "mistral" -- Change this to your preferred model (e.g., "neural-chat", "orca-mini", etc.)

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OllamaCodeGeneratorGui"
screenGui.ResetOnSpawn = false

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 500)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.BorderSizePixel = 0
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Ollama Code Generator"
titleLabel.Parent = mainFrame

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeButton.BorderSizePixel = 0
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.Parent = mainFrame

-- Prompt label
local promptLabel = Instance.new("TextLabel")
promptLabel.Name = "PromptLabel"
promptLabel.Size = UDim2.new(1, -20, 0, 30)
promptLabel.Position = UDim2.new(0, 10, 0, 50)
promptLabel.BackgroundTransparency = 1
promptLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
promptLabel.TextSize = 14
promptLabel.Font = Enum.Font.Gotham
promptLabel.Text = "Describe the code you want to generate:"
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Parent = mainFrame

-- Prompt input box
local promptTextBox = Instance.new("TextBox")
promptTextBox.Name = "PromptTextBox"
promptTextBox.Size = UDim2.new(1, -20, 0, 80)
promptTextBox.Position = UDim2.new(0, 10, 0, 85)
promptTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
promptTextBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
promptTextBox.BorderSizePixel = 1
promptTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
promptTextBox.TextSize = 12
promptTextBox.Font = Enum.Font.Gotham
promptTextBox.TextWrapped = true
promptTextBox.TextXAlignment = Enum.TextXAlignment.Left
promptTextBox.TextYAlignment = Enum.TextYAlignment.Top
promptTextBox.PlaceholderText = "e.g., 'Create a function that prints hello world'"
promptTextBox.ClearTextOnFocus = false
promptTextBox.Parent = mainFrame

-- Model selection label
local modelLabel = Instance.new("TextLabel")
modelLabel.Name = "ModelLabel"
modelLabel.Size = UDim2.new(0.5, -15, 0, 25)
modelLabel.Position = UDim2.new(0, 10, 0, 170)
modelLabel.BackgroundTransparency = 1
modelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
modelLabel.TextSize = 12
modelLabel.Font = Enum.Font.Gotham
modelLabel.Text = "Model:"
modelLabel.TextXAlignment = Enum.TextXAlignment.Left
modelLabel.Parent = mainFrame

-- Model input
local modelTextBox = Instance.new("TextBox")
modelTextBox.Name = "ModelTextBox"
modelTextBox.Size = UDim2.new(0.5, -15, 0, 25)
modelTextBox.Position = UDim2.new(0.5, 5, 0, 170)
modelTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
modelTextBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
modelTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
modelTextBox.TextSize = 12
modelTextBox.Font = Enum.Font.Gotham
modelTextBox.Text = MODEL_NAME
modelTextBox.Parent = mainFrame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Ready"
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Generate button
local generateButton = Instance.new("TextButton")
generateButton.Name = "GenerateButton"
generateButton.Size = UDim2.new(0.5, -10, 0, 35)
generateButton.Position = UDim2.new(0, 10, 0, 240)
generateButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
generateButton.BorderSizePixel = 0
generateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
generateButton.TextSize = 14
generateButton.Font = Enum.Font.GothamBold
generateButton.Text = "Generate"
generateButton.Parent = mainFrame

-- Inject button
local injectButton = Instance.new("TextButton")
injectButton.Name = "InjectButton"
injectButton.Size = UDim2.new(0.5, -10, 0, 35)
injectButton.Position = UDim2.new(0.5, 10, 0, 240)
injectButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
injectButton.BorderSizePixel = 0
injectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
injectButton.TextSize = 14
injectButton.Font = Enum.Font.GothamBold
injectButton.Text = "Inject Script"
injectButton.Parent = mainFrame

-- Output label
local outputLabel = Instance.new("TextLabel")
outputLabel.Name = "OutputLabel"
outputLabel.Size = UDim2.new(1, -20, 0, 25)
outputLabel.Position = UDim2.new(0, 10, 0, 280)
outputLabel.BackgroundTransparency = 1
outputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
outputLabel.TextSize = 12
outputLabel.Font = Enum.Font.Gotham
outputLabel.Text = "Generated Code:"
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.Parent = mainFrame

-- Output text box
local outputTextBox = Instance.new("TextBox")
outputTextBox.Name = "OutputTextBox"
outputTextBox.Size = UDim2.new(1, -20, 0, 150)
outputTextBox.Position = UDim2.new(0, 10, 0, 310)
outputTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
outputTextBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
outputTextBox.BorderSizePixel = 1
outputTextBox.TextColor3 = Color3.fromRGB(0, 255, 0)
outputTextBox.TextSize = 10
outputTextBox.Font = Enum.Font.GothamMonospace
outputTextBox.TextWrapped = true
outputTextBox.TextXAlignment = Enum.TextXAlignment.Left
outputTextBox.TextYAlignment = Enum.TextYAlignment.Top
outputTextBox.ReadOnly = false
outputTextBox.Parent = mainFrame

-- Copy button
local copyButton = Instance.new("TextButton")
copyButton.Name = "CopyButton"
copyButton.Size = UDim2.new(0.5, -10, 0, 30)
copyButton.Position = UDim2.new(0, 10, 0, 465)
copyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
copyButton.BorderSizePixel = 0
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 12
copyButton.Font = Enum.Font.Gotham
copyButton.Text = "Copy Code"
copyButton.Parent = mainFrame

-- Clear button
local clearButton = Instance.new("TextButton")
clearButton.Name = "ClearButton"
clearButton.Size = UDim2.new(0.5, -10, 0, 30)
clearButton.Position = UDim2.new(0.5, 10, 0, 465)
clearButton.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
clearButton.BorderSizePixel = 0
clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
clearButton.TextSize = 12
clearButton.Font = Enum.Font.Gotham
clearButton.Text = "Clear"
clearButton.Parent = mainFrame

-- Variables to store generated code
local generatedCode = ""

-- Function to make HTTP request to Ollama
local function callOllama(prompt, model)
	statusLabel.Text = "Connecting to Ollama..."
	
	local success, response = pcall(function()
		local HttpService = game:GetService("HttpService")
		
		local requestBody = HttpService:JSONEncode({
			model = model,
			prompt = prompt,
			stream = false,
			temperature = 0.7
		})
		
		local headers = {
			["Content-Type"] = "application/json"
		}
		
		local url = OLLAMA_URL .. "/api/generate"
		local result = HttpService:PostAsync(url, requestBody, Enum.HttpContentType.ApplicationJson, false, headers)
		
		return result
	end)
	
	if success then
		local HttpService = game:GetService("HttpService")
		local decoded = HttpService:JSONDecode(response)
		statusLabel.Text = "Generation complete!"
		return decoded.response or "No response from model"
	else
		statusLabel.Text = "Error: " .. tostring(response)
		return "Error: " .. tostring(response)
	end
end

-- Function to inject script into workspace
local function injectScript(code)
	local selection = plugin:GetSelectedInstances()
	
	if #selection == 0 then
		statusLabel.Text = "Error: Select a part to inject into"
		return
	end
	
	local targetInstance = selection[1]
	
	-- Create a new LocalScript
	local newScript = Instance.new("LocalScript")
	newScript.Source = code
	newScript.Parent = targetInstance
	
	statusLabel.Text = "Script injected into: " .. targetInstance.Name
end

-- Generate button click
generateButton.MouseButton1Click:Connect(function()
	local prompt = promptTextBox.Text
	local model = modelTextBox.Text
	
	if prompt == "" then
		statusLabel.Text = "Error: Enter a prompt"
		return
	end
	
	generatedCode = callOllama(prompt, model)
	outputTextBox.Text = generatedCode
end)

-- Inject button click
injectButton.MouseButton1Click:Connect(function()
	if generatedCode == "" then
		statusLabel.Text = "Error: Generate code first"
		return
	end
	
	injectScript(generatedCode)
end)

-- Copy button click
copyButton.MouseButton1Click:Connect(function()
	local HttpService = game:GetService("HttpService")
	plugin:GetMouse().TargetFilter = outputTextBox
	outputTextBox:CaptureFocus()
	statusLabel.Text = "Code copied to clipboard (Ctrl+C)"
end)

-- Clear button click
clearButton.MouseButton1Click:Connect(function()
	outputTextBox.Text = ""
	promptTextBox.Text = ""
	generatedCode = ""
	statusLabel.Text = "Cleared"
end)

-- Close button click
closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Toggle GUI visibility
button.Click:Connect(function()
	if screenGui.Parent == nil then
		screenGui.Parent = plugin:FindFirstChild("_ExtendedGui") or game:GetService("CoreGui")
	else
		screenGui:Destroy()
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "OllamaCodeGeneratorGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = plugin:FindFirstChild("_ExtendedGui") or game:GetService("CoreGui")
		-- Recreate all GUI elements...
	end
end)

-- Initial GUI setup
screenGui.Parent = plugin:FindFirstChild("_ExtendedGui") or game:GetService("CoreGui")

print("Ollama Code Generator Plugin loaded successfully!")
print("Ollama Server: " .. OLLAMA_URL)
print("Default Model: " .. MODEL_NAME)
