-- DataStore への保存と読み込み。
-- Studio で試すときは「ゲーム設定 > セキュリティ > API サービスへの Studio アクセスを有効にする」が必要。
-- 無効のままでもゲームは遊べる(保存されないだけ)。
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SaveData = {}

local store = nil
local ok, err = pcall(function()
	store = DataStoreService:GetDataStore(Config.DATASTORE_NAME)
end)
if not ok then
	warn("[SaveData] DataStore が使えないので保存なしで動かします:", err)
end

local function keyFor(userId)
	return "player_" .. userId
end

-- 戻り値: (読み込めたか, データ or nil)
-- 読み込めなかったときに保存すると元のデータを上書きしてしまうので、呼び出し側で保存を止める。
function SaveData.load(userId)
	if not store then
		return false, nil
	end
	for attempt = 1, 3 do
		local success, result = pcall(function()
			return store:GetAsync(keyFor(userId))
		end)
		if success then
			return true, result
		end
		warn(string.format("[SaveData] 読み込み失敗 (%d/3): %s", attempt, tostring(result)))
		task.wait(attempt)
	end
	return false, nil
end

function SaveData.save(userId, data)
	if not store then
		return false
	end
	local success, result = pcall(function()
		store:SetAsync(keyFor(userId), data)
	end)
	if not success then
		warn("[SaveData] 保存失敗:", result)
	end
	return success
end

return SaveData
