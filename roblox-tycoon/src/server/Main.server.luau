-- サーバーの入口。区画を用意して、入ってきたプレイヤーに工場を割り当てる。
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Tycoon = require(script.Parent.Tycoon)
local SaveData = require(script.Parent.SaveData)

local plots = {}
for index, origin in ipairs(Config.PLOT_ORIGINS) do
	plots[index] = Tycoon.new(index, origin)
end

-- [player] = { tycoon = Tycoon, canSave = boolean }
local sessions = {}

local function findFreePlot()
	for _, plot in ipairs(plots) do
		if plot:IsFree() then
			return plot
		end
	end
	return nil
end

local function savePlayer(player)
	local session = sessions[player]
	if not session or not session.canSave then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild(Config.CURRENCY_NAME)
	if not cash then
		return
	end
	SaveData.save(player.UserId, {
		cash = cash.Value,
		purchased = session.tycoon:GetPurchasedList(),
	})
end

local function onPlayerAdded(player)
	local loaded, data = SaveData.load(player.UserId)
	if not player.Parent then
		return -- 読み込み中に抜けた
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = Config.CURRENCY_NAME
	cash.Value = (data and data.cash) or Config.STARTING_CASH
	cash.Parent = leaderstats
	leaderstats.Parent = player

	local plot = findFreePlot()
	if not plot then
		Tycoon.Notify:FireClient(player, "空いている工場がないよ。別のサーバーを試してね", "error")
		return
	end

	sessions[player] = { tycoon = plot, canSave = loaded }
	plot:Claim(player, (data and data.purchased) or {})
end

local function onPlayerRemoving(player)
	savePlayer(player)
	local session = sessions[player]
	if session then
		session.tycoon:Release()
		sessions[player] = nil
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_INTERVAL)
		for player in pairs(sessions) do
			task.spawn(savePlayer, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in pairs(sessions) do
		pending += 1
		task.spawn(function()
			savePlayer(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
