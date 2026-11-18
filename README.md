# enhansers-roblox
to help the game:)

## Auto-buy starter (Roblox Studio)

Server-authoritative auto-buy for a game you own, laid out for [Rojo](https://rojo.space).

- `src/ReplicatedStorage/ShopConfig.lua` – shop items, prices, currency name
- `src/ServerScriptService/AutoBuyService.server.lua` – buys the first affordable item for players who turned it on
- `src/StarterPlayerScripts/AutoBuyToggle.client.lua` – on/off button

Assumes a `leaderstats` value named `Cash`; replace `grantItem()` with your game's real item-granting logic.
Without Rojo, paste each file into Studio as a ModuleScript / Script / LocalScript in the matching service.

## Anti-cheat testing (Studio only)

`src/StarterPlayerScripts/ExploitSimulator.client.lua` simulates common cheater behaviour (speed/jump tampering,
teleporting, fuzzing and spamming RemoteEvents) so you can confirm your **server-side** anti-cheat reacts.
It exits immediately outside Roblox Studio. Run it via Test > Start (server + client) and watch the server output.
Toggle individual tests in `TESTS_ENABLED`.
