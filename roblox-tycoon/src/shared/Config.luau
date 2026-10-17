-- ゲームバランスの設定はここにまとめてある。値を変えるだけで調整できる。
local Config = {}

Config.CURRENCY_NAME = "コイン"
Config.STARTING_CASH = 0

Config.DATASTORE_NAME = "PrintFactoryTycoon_v1"
Config.AUTOSAVE_INTERVAL = 60

-- 1区画に同時に存在できる造形物の上限(重くならないように)
Config.MAX_PRINTS_PER_PLOT = 80
-- 造形物が売れずに残ったときに自動で消えるまでの秒数
Config.PRINT_LIFETIME = 60

Config.CONVEYOR_SPEED = 8
Config.FAST_CONVEYOR_SPEED = 14

-- 塗装ステーションを通った造形物の売値の倍率
Config.PAINT_MULTIPLIER = 2
-- 検品ラインを通った造形物の売値の倍率
Config.QC_MULTIPLIER = 1.5

-- 区画(工場)の位置。人数分だけ並べる。
Config.PLOT_ORIGINS = {
	Vector3.new(-40, 0, -40),
	Vector3.new(40, 0, -40),
	Vector3.new(-40, 0, 40),
	Vector3.new(40, 0, 40),
}

-- 購入ボタンの一覧。上から順にボタンが並ぶ。
-- requires: このアイテムを買うと次のボタンが出てくる
-- printer の slot はコンベア沿いの設置場所(1〜6)
Config.ITEMS = {
	{ id = "printer1", name = "3Dプリンター 1号機", price = 0, kind = "printer", slot = 1, interval = 2, value = 5 },
	{ id = "printer2", name = "3Dプリンター 2号機", price = 100, requires = "printer1", kind = "printer", slot = 2, interval = 2, value = 8 },
	{ id = "paint", name = "塗装ステーション", price = 250, requires = "printer2", kind = "paint" },
	{ id = "printer3", name = "3Dプリンター 3号機", price = 400, requires = "paint", kind = "printer", slot = 3, interval = 2, value = 12 },
	{ id = "fastConveyor", name = "高速コンベア", price = 700, requires = "printer3", kind = "conveyor" },
	{ id = "printer4", name = "3Dプリンター 4号機", price = 1200, requires = "fastConveyor", kind = "printer", slot = 4, interval = 1.5, value = 15 },
	{ id = "qc", name = "検品ライン", price = 2000, requires = "printer4", kind = "qc" },
	{ id = "printer5", name = "大型プリンター", price = 3500, requires = "qc", kind = "printer", slot = 5, interval = 3, value = 50, big = true },
	{ id = "printer6", name = "レジンプリンター", price = 7000, requires = "printer5", kind = "printer", slot = 6, interval = 2, value = 70, resin = true },
}

return Config
