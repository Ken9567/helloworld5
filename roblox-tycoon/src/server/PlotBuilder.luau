-- 工場の建物をパーツで組み立てる関数たち。座標はすべて区画の中心からの相対位置。
--
-- 区画のレイアウト(上から見た図、-Z が奥):
--   z = -24      プリンター(slot 1〜6 が x = -26 から 6 間隔で並ぶ)
--   z = -18      コンベア(x = -30 → 21 へ流れる) → 塗装(x=11) → 検品(x=16) → 売り場(x=24)
--   z = 4, 14    購入ボタン
--   z = 24       スポーン地点
--   z = 30       看板
local PlotBuilder = {}

local CONVEYOR_Z = -18
local PRINTER_Z = -24

local function block(parent, name, cframe, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = cframe
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function billboard(adornee, text, offsetY, width)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 200, 50)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = 80
	gui.Adornee = adornee
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	return label
end

function PlotBuilder.buildPlot(plotCFrame, index, parent)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	block(model, "Base", plotCFrame * CFrame.new(0, 0.5, 0), Vector3.new(64, 1, 64), Color3.fromRGB(70, 74, 82), Enum.Material.Concrete)

	local conveyor = block(model, "Conveyor", plotCFrame * CFrame.new(-4.5, 1.5, CONVEYOR_Z), Vector3.new(51, 1, 4), Color3.fromRGB(40, 40, 45), Enum.Material.DiamondPlate)
	local railColor = Color3.fromRGB(240, 190, 40)
	block(model, "RailA", plotCFrame * CFrame.new(-4.5, 2.5, CONVEYOR_Z + 2.25), Vector3.new(51, 1, 0.5), railColor)
	block(model, "RailB", plotCFrame * CFrame.new(-4.5, 2.5, CONVEYOR_Z - 2.25), Vector3.new(51, 1, 0.5), railColor)
	block(model, "RailEnd", plotCFrame * CFrame.new(-30.25, 2.5, CONVEYOR_Z), Vector3.new(0.5, 1, 4.5), railColor)

	local seller = block(model, "Seller", plotCFrame * CFrame.new(24, 3, CONVEYOR_Z), Vector3.new(6, 4, 8), Color3.fromRGB(60, 180, 90))
	billboard(seller, "売り場", 4)

	local sign = block(model, "Sign", plotCFrame * CFrame.new(0, 4, 30), Vector3.new(16, 6, 1), Color3.fromRGB(30, 30, 35))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.Parent = sign
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.Parent = surface

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = plotCFrame * CFrame.new(0, 1.5, 24)
	spawn.Parent = model

	local function folder(name)
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = model
		return f
	end

	model.Parent = parent

	return {
		Model = model,
		Conveyor = conveyor,
		Seller = seller,
		SignLabel = signLabel,
		Spawn = spawn,
		Items = folder("Items"),
		Buttons = folder("Buttons"),
		Prints = folder("Prints"),
	}
end

-- プリンターを建てて、造形物が出てくる位置を返す
function PlotBuilder.buildPrinter(parent, plotCFrame, item)
	local x = -26 + (item.slot - 1) * 6
	local height = item.big and 8 or 6
	local bodyTop = 1 + height

	local model = Instance.new("Model")
	model.Name = item.id

	local bodyColor = item.resin and Color3.fromRGB(45, 45, 55) or Color3.fromRGB(230, 230, 235)
	local body = block(model, "Body", plotCFrame * CFrame.new(x, 1 + height / 2, PRINTER_Z), Vector3.new(5, height, 5), bodyColor)

	local window = block(model, "Window", plotCFrame * CFrame.new(x, 1 + height / 2, PRINTER_Z + 2.6), Vector3.new(3.5, height - 2, 0.2), Color3.fromRGB(120, 200, 255), Enum.Material.Glass)
	window.Transparency = 0.5

	block(model, "Arm", plotCFrame * CFrame.new(x, bodyTop - 0.5, (PRINTER_Z + CONVEYOR_Z) / 2), Vector3.new(1, 1, 6.5), Color3.fromRGB(90, 90, 100), Enum.Material.Metal)
	block(model, "Nozzle", plotCFrame * CFrame.new(x, bodyTop - 1.5, CONVEYOR_Z), Vector3.new(0.6, 1, 0.6), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)

	billboard(body, item.name, height / 2 + 1.5, 180)
	model.Parent = parent

	return plotCFrame * CFrame.new(x, bodyTop - 3, CONVEYOR_Z)
end

-- コンベアをまたぐゲート(塗装・検品)を建てて、通過判定用のセンサーを返す
function PlotBuilder.buildGate(parent, plotCFrame, x, name, color)
	local model = Instance.new("Model")
	model.Name = name

	local frameColor = Color3.fromRGB(90, 90, 100)
	block(model, "PillarA", plotCFrame * CFrame.new(x, 4, CONVEYOR_Z + 3), Vector3.new(1, 6, 1), frameColor, Enum.Material.Metal)
	block(model, "PillarB", plotCFrame * CFrame.new(x, 4, CONVEYOR_Z - 3), Vector3.new(1, 6, 1), frameColor, Enum.Material.Metal)
	local beam = block(model, "Beam", plotCFrame * CFrame.new(x, 7.5, CONVEYOR_Z), Vector3.new(1, 1, 7), color, Enum.Material.Neon)

	local sensor = block(model, "Sensor", plotCFrame * CFrame.new(x, 3.6, CONVEYOR_Z), Vector3.new(1.5, 4, 3.6), color, Enum.Material.ForceField)
	sensor.CanCollide = false
	sensor.CanQuery = false
	sensor.Transparency = 0.4

	billboard(beam, name, 2, 180)
	model.Parent = parent
	return sensor
end

-- 購入ボタン(踏むと買える床パネル)
function PlotBuilder.buildButton(parent, plotCFrame, index, item, currencyName)
	local x = -24 + ((index - 1) % 5) * 12
	local z = 4 + math.floor((index - 1) / 5) * 10

	local pad = block(parent, item.id, plotCFrame * CFrame.new(x, 1.2, z), Vector3.new(5, 0.4, 5), Color3.fromRGB(70, 200, 110), Enum.Material.Neon)
	local priceText = item.price == 0 and "無料" or (tostring(item.price) .. " " .. currencyName)
	billboard(pad, item.name .. "\n" .. priceText, 3, 220)
	return pad
end

return PlotBuilder
