# Playdate Starter

A Playdate platformer prototype written in Lua. Race across the warehouse, collect
the parcel, carry it to the shipping box, and turn the crank to tape it shut before
time runs out.

## Requirements

- Playdate SDK
- macOS (the run target opens the Playdate Simulator)
- GNU Make

The Makefile uses `PLAYDATE_SDK_PATH` when set, otherwise it reads `SDKRoot` from
`~/.Playdate/config`.

## Build and run

```sh
make build
make run
```

`make run` builds the game and opens it in the Playdate Simulator. The compiled
game is written to `build/PlaydateStarter.pdx`.

## Controls

- **Left / Right** — move
- **A** — jump
- **B** — pick up a parcel or place it in the box when nearby
- **Crank** — tape a parcel into the box when standing beside it

Each shift opens with a briefing card and has its own obstacle layout and moving
forklift. Hitting a forklift or running out of time fails the shift; press **A**
to restart it from the briefing.

Levels span two or three horizontally scrolling screens. Jump onto the warehouse
racks and raised walkways using the step platforms; the HUD shows your current
screen number.

In VS Code, use **Terminal → Run Task** and choose **Playdate: Build** or
**Playdate: Build and Run**. The Lua extension is recommended for language
support and diagnostics.

## Project layout

- `Source/main.lua` — game update loop and starter interaction
- `Source/pdxinfo` — game metadata
- `Makefile` — SDK-backed build, run, and clean targets
