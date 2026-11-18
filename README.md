# enhansers-roblox
to help the game:)

## Auto-buy starter (Roblox Studio)

Server-authoritative auto-buy for a game you own, laid out for [Rojo](https://rojo.space).

- `src/ReplicatedStorage/ShopConfig.lua` – shop items, prices, currency name
- `src/ServerScriptService/AutoBuyService.server.lua` – buys the first affordable item for players who turned it on
- `src/StarterPlayerScripts/AutoBuyToggle.client.lua` – on/off button

Assumes a `leaderstats` value named `Cash`; replace `grantItem()` with your game's real item-granting logic.
Without Rojo, paste each file into Studio as a ModuleScript / Script / LocalScript in the matching service.
