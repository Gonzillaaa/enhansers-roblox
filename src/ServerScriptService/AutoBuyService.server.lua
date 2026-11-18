-- ServerScriptService/AutoBuyService (Script)
-- Server-authoritative auto-buy: players toggle it, the server checks money and buys.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local toggleEvent = Instance.new("RemoteEvent")
toggleEvent.Name = "ToggleAutoBuy"
toggleEvent.Parent = ReplicatedStorage

local enabled: { [Player]: boolean } = {}
local owned: { [Player]: { [string]: number } } = {}

local function getCurrency(player: Player): NumberValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(Config.CurrencyName) :: NumberValue?
end

-- Replace the body with however your game actually grants an item.
local function grantItem(player: Player, item)
	print(("%s bought %s"):format(player.Name, item.Name))
end

local function tryBuy(player: Player)
	local currency = getCurrency(player)
	if not currency then return end
	local counts = owned[player]

	for _, item in ipairs(Config.Items) do
		local have = counts[item.Id] or 0
		if have < item.MaxOwned and currency.Value >= item.Price then
			currency.Value -= item.Price
			counts[item.Id] = have + 1
			grantItem(player, item)
			return -- one purchase per tick keeps it predictable
		end
	end
end

toggleEvent.OnServerEvent:Connect(function(player, state)
	enabled[player] = state == true -- never trust client input beyond a boolean
end)

Players.PlayerAdded:Connect(function(player)
	owned[player] = {}
	enabled[player] = false
end)

Players.PlayerRemoving:Connect(function(player)
	enabled[player], owned[player] = nil, nil
end)

task.spawn(function()
	while true do
		task.wait(Config.BuyInterval)
		for player, on in pairs(enabled) do
			if on then tryBuy(player) end
		end
	end
end)
