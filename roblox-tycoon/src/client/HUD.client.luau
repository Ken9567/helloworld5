-- 画面上部の所持金表示と、画面下に出るお知らせ。
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Notify = ReplicatedStorage:WaitForChild("TycoonNotify")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TycoonHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local cashLabel = Instance.new("TextLabel")
cashLabel.AnchorPoint = Vector2.new(0.5, 0)
cashLabel.Position = UDim2.new(0.5, 0, 0, 12)
cashLabel.Size = UDim2.fromOffset(280, 48)
cashLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
cashLabel.BackgroundTransparency = 0.2
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextScaled = true
cashLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
cashLabel.Text = "..."
cashLabel.Parent = gui
Instance.new("UICorner").Parent = cashLabel
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = cashLabel

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -100)
toast.Size = UDim2.fromOffset(420, 40)
toast.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
toast.BackgroundTransparency = 0.2
toast.Font = Enum.Font.GothamBold
toast.TextScaled = true
toast.Visible = false
toast.Parent = gui
Instance.new("UICorner").Parent = toast

local function formatNumber(n)
	local formatted = tostring(math.floor(n))
	local count
	repeat
		formatted, count = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return formatted
end

local toastToken = 0
Notify.OnClientEvent:Connect(function(text, kind)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.TextColor3 = kind == "error" and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(120, 255, 150)
	toast.Visible = true
	task.delay(2.5, function()
		if toastToken == token then
			toast.Visible = false
		end
	end)
end)

local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild(Config.CURRENCY_NAME)
local function updateCash()
	cashLabel.Text = formatNumber(cash.Value) .. " " .. Config.CURRENCY_NAME
end
cash.Changed:Connect(updateCash)
updateCash()
