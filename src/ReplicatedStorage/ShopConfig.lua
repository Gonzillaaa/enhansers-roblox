-- ReplicatedStorage/ShopConfig (ModuleScript)
-- Edit this list to match your game's shop. Items are bought in order (first = highest priority).
return {
	CurrencyName = "Cash", -- name of the IntValue/NumberValue under player.leaderstats
	BuyInterval = 1,       -- seconds between auto-buy checks
	Items = {
		{ Id = "AxeBasic",   Name = "Basic Axe",   Price = 100,  MaxOwned = 1 },
		{ Id = "AxeStrong",  Name = "Strong Axe",  Price = 500,  MaxOwned = 1 },
		{ Id = "SawmillLv",  Name = "Sawmill Lvl", Price = 250,  MaxOwned = 10 },
	},
}
