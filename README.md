# Brainrot Bazaar

[![Make the best AI Roblox brainrot game](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Rank](https://make.fun/badge/roblox-brainrot-01/candaraz/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![Reward](https://make.fun/badge/roblox-brainrot-01/candaraz/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

**Brainrot Bazaar** is a 3D Roblox brainrot game, built for [make.fun's "Make the best AI Roblox brainrot game" bounty](https://make.fun/bounty/roblox-brainrot-01). Absurd meme-born characters march down a central conveyor belt; you buy them, stack them on your base, and watch the money tick up — while rival players try to steal your best ones and a tsunami sweeps the map every few minutes.

## How to play

- **Buy brainrots** off the belt: walk up to one and press **E**. Sixteen original characters — Waddles McTeapot, Sergeant Pickles, Queen Quokka, Grandma Giga and friends — across eight rarities from Common to OG, each with its own price and money-per-second.
- **Stack your base**: a bought brainrot walks home and sits on a slot, earning money every second. Rarer tiers earn far more, and Gold, Diamond, Divine and Rainbow mutations multiply income up to x10.
- **Steal and defend**: grab a brainrot from an unlocked rival base and dash home with it — you move slower while carrying. The owner can **slap** you (Q) to send it home. Lock your own base (**L**) to raise the laser gate for 60 seconds or more.
- **Rebirth** (R): trade cash plus a rare brainrot for a permanent income multiplier, a longer lock, faster feet and a golden star over your head. Five rebirths, up to x12.
- **Survive the tsunami**: every few minutes a warning banner gives you 20 seconds to get inside your base before a wall of water sweeps the map and knocks down everyone caught outside.
- **Cast list** (C): the whole cast, the rarity ladder and the rebirth requirements, on one panel.

## What is in this repository

- `default.project.json` — the Rojo project: the whole static 3D world (belt, eight bases, spawn plaza, volcano, portal, trees, signs) plus the script layout.
- `src/shared/BrainrotCatalog.luau` — the cast, rarities, mutations, rebirth ladder and tuning numbers.
- `src/shared/SharedFormat.luau` — money, rate and countdown formatting shared by server and client.
- `src/server/GameState.luau` — the one place server state lives: cash, bases, locks, rebirths, brainrot records.
- `src/server/BrainrotFactory.luau` — builds every character model from Parts, with its readable name/rarity/rate/price label.
- `src/server/StealController.luau` — stealing, carrying, delivery, slap returns and stuns.
- `src/server/TsunamiController.luau` — the wave warning, the moving wall and the knockback.
- `src/server/GameServer.server.luau` — the belt, buying, locks, rebirths, the earnings tick and all remotes.
- `src/client/BrainrotHud.client.luau` — money, income, next tier, lock/rebirth/slap buttons, event banner, toasts.
- `src/client/CollectionPanel.client.luau` — the cast list and rebirth ladder panel.
- `game.rbxl` — the place file, built with `rojo build default.project.json --output game.rbxl`.
- `main.ts` — hands the game in: copies the place, sources, screenshots and PLAY.json to the output and writes the dossier.
- `screenshots/` — captures of the game running in Roblox Studio; the first by name is the game's thumbnail on Roblox.
- `PLAY.json` — the link to the game's public place on Roblox.

## Build and check it

    rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Open `game.rbxl` in Roblox Studio and press Play to run the game. No external assets, no DataStores, no network calls: every character is built from Parts by the game's own code.
