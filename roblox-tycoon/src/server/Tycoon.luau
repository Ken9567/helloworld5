-- 1人分の工場(区画)を管理するクラス。
-- 持ち主の割り当て、ボタンでの購入、プリンターの稼働、売上の計算を担当する。
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)
local PlotBuilder = require(script.Parent.PlotBuilder)

local Notify = ReplicatedStorage:FindFirstChild("TycoonNotify")
if not Notify then
	Notify = Instance.new("RemoteEvent")
	Notify.Name = "TycoonNotify"
	Notify.Parent = ReplicatedStorage
end

local tycoonsFolder = workspace:FindFirstChild("Tycoons")
if not tycoonsFolder then
	tycoonsFolder = Instance.new("Folder")
	tycoonsFolder.Name = "Tycoons"
	tycoonsFolder.Parent = workspace
end

local PRINT_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(200, 200, 200),
	Color3.fromRGB(240, 220, 180),
	Color3.fromRGB(180, 200, 220),
}
local PRINT_SHAPES = { Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder }

local Tycoon = {}
Tycoon.__index = Tycoon
Tycoon.Notify = Notify

function Tycoon.new(index, origin)
	local self = setmetatable({}, Tycoon)
	self.CFrame = CFrame.new(origin)
	self.Owner = nil
	self.Purchased = {}
	self.Buttons = {}
	self.Connections = {}
	self.Busy = {}
	self.LastWarning = {}
	-- 持ち主が変わるたびに増やす。古いプリンターのループはこれを見て止まる。
	self.Generation = 0

	local refs = PlotBuilder.buildPlot(self.CFrame, index, tycoonsFolder)
	self.Conveyor = refs.Conveyor
	self.SignLabel = refs.SignLabel
	self.Spawn = refs.Spawn
	self.ItemsFolder = refs.Items
	self.ButtonsFolder = refs.Buttons
	self.PrintsFolder = refs.Prints

	refs.Seller.Touched:Connect(function(hit)
		self:_sell(hit)
	end)

	self:_resetConveyor()
	self.SignLabel.Text = "空き工場"
	return self
end

function Tycoon:IsFree()
	return self.Owner == nil
end

function Tycoon:Claim(player, purchasedList)
	self.Owner = player
	self.SignLabel.Text = player.DisplayName .. " の3Dプリント工場"
	player.RespawnLocation = self.Spawn

	local saved = {}
	for _, id in ipairs(purchasedList) do
		saved[id] = true
	end
	for _, item in ipairs(Config.ITEMS) do
		if saved[item.id] then
			self.Purchased[item.id] = true
			self:_build(item)
		end
	end

	self:_createButtons()
	self:_refreshButtons()

	if player.Character then
		player.Character:PivotTo(self.Spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

function Tycoon:Release()
	self.Generation += 1
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}
	for _, button in pairs(self.Buttons) do
		button:Destroy()
	end
	self.Buttons = {}
	self.ItemsFolder:ClearAllChildren()
	self.PrintsFolder:ClearAllChildren()
	self.Purchased = {}
	self.Busy = {}
	self.LastWarning = {}
	self.Owner = nil
	self.SignLabel.Text = "空き工場"
	self:_resetConveyor()
end

function Tycoon:GetPurchasedList()
	local list = {}
	for _, item in ipairs(Config.ITEMS) do
		if self.Purchased[item.id] then
			table.insert(list, item.id)
		end
	end
	return list
end

function Tycoon:_getCash()
	local owner = self.Owner
	local leaderstats = owner and owner:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(Config.CURRENCY_NAME)
end

function Tycoon:_resetConveyor()
	self.Conveyor.AssemblyLinearVelocity = self.CFrame.RightVector * Config.CONVEYOR_SPEED
	self.Conveyor.Color = Color3.fromRGB(40, 40, 45)
end

function Tycoon:_createButtons()
	for index, item in ipairs(Config.ITEMS) do
		local pad = PlotBuilder.buildButton(self.ButtonsFolder, self.CFrame, index, item, Config.CURRENCY_NAME)
		self.Buttons[item.id] = pad
		table.insert(self.Connections, pad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if not player or player ~= self.Owner then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				self:_tryPurchase(item)
			end
		end))
	end
end

-- 買える状態のボタンだけを表示する
function Tycoon:_refreshButtons()
	for _, item in ipairs(Config.ITEMS) do
		local pad = self.Buttons[item.id]
		if pad then
			local unlocked = item.requires == nil or self.Purchased[item.requires]
			pad.Parent = (unlocked and not self.Purchased[item.id]) and self.ButtonsFolder or nil
		end
	end
end

function Tycoon:_tryPurchase(item)
	if self.Purchased[item.id] or self.Busy[item.id] then
		return
	end
	local cash = self:_getCash()
	if not cash then
		return
	end

	if cash.Value < item.price then
		local now = os.clock()
		if (self.LastWarning[item.id] or 0) + 2 < now then
			self.LastWarning[item.id] = now
			Notify:FireClient(self.Owner, string.format("%sが足りないよ(あと %d)", Config.CURRENCY_NAME, item.price - cash.Value), "error")
		end
		return
	end

	self.Busy[item.id] = true
	cash.Value -= item.price
	self.Purchased[item.id] = true
	self:_build(item)
	self:_refreshButtons()
	self.Busy[item.id] = nil
	Notify:FireClient(self.Owner, item.name .. " を手に入れた!", "success")
end

function Tycoon:_build(item)
	if item.kind == "printer" then
		local spawnCFrame = PlotBuilder.buildPrinter(self.ItemsFolder, self.CFrame, item)
		self:_startPrinter(item, spawnCFrame)
	elseif item.kind == "paint" then
		local sensor = PlotBuilder.buildGate(self.ItemsFolder, self.CFrame, 11, item.name, Color3.fromRGB(255, 80, 200))
		table.insert(self.Connections, sensor.Touched:Connect(function(hit)
			if hit:GetAttribute("IsPrint") and not hit:GetAttribute("Painted") then
				hit:SetAttribute("Painted", true)
				hit.Color = Color3.fromHSV(math.random(), 0.8, 1)
				hit.Material = Enum.Material.Neon
			end
		end))
	elseif item.kind == "qc" then
		local sensor = PlotBuilder.buildGate(self.ItemsFolder, self.CFrame, 16, item.name, Color3.fromRGB(80, 160, 255))
		table.insert(self.Connections, sensor.Touched:Connect(function(hit)
			if hit:GetAttribute("IsPrint") then
				hit:SetAttribute("Checked", true)
			end
		end))
	elseif item.kind == "conveyor" then
		self.Conveyor.AssemblyLinearVelocity = self.CFrame.RightVector * Config.FAST_CONVEYOR_SPEED
		self.Conveyor.Color = Color3.fromRGB(30, 60, 110)
	end
end

function Tycoon:_startPrinter(item, spawnCFrame)
	local generation = self.Generation
	task.spawn(function()
		while self.Generation == generation do
			task.wait(item.interval)
			if self.Generation ~= generation then
				break
			end
			self:_spawnPrint(item, spawnCFrame)
		end
	end)
end

function Tycoon:_spawnPrint(item, spawnCFrame)
	if #self.PrintsFolder:GetChildren() >= Config.MAX_PRINTS_PER_PLOT then
		return
	end

	local piece = Instance.new("Part")
	piece.Name = "Print"
	piece.Shape = PRINT_SHAPES[math.random(#PRINT_SHAPES)]
	piece.Size = item.big and Vector3.new(2, 2, 2) or Vector3.new(1.2, 1.2, 1.2)
	piece.Color = PRINT_COLORS[math.random(#PRINT_COLORS)]
	if item.resin then
		piece.Material = Enum.Material.Glass
		piece.Transparency = 0.3
	else
		piece.Material = Enum.Material.SmoothPlastic
	end
	piece.CFrame = spawnCFrame
	piece:SetAttribute("IsPrint", true)
	piece:SetAttribute("Value", item.value)
	piece.Parent = self.PrintsFolder
	piece:SetNetworkOwner(nil)
	Debris:AddItem(piece, Config.PRINT_LIFETIME)
end

function Tycoon:_sell(hit)
	if not hit:IsDescendantOf(self.PrintsFolder) or hit:GetAttribute("Sold") then
		return
	end
	hit:SetAttribute("Sold", true)

	local value = hit:GetAttribute("Value") or 0
	if hit:GetAttribute("Painted") then
		value *= Config.PAINT_MULTIPLIER
	end
	if hit:GetAttribute("Checked") then
		value *= Config.QC_MULTIPLIER
	end
	hit:Destroy()

	local cash = self:_getCash()
	if cash then
		cash.Value += math.floor(value + 0.5)
	end
end

return Tycoon
