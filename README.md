# Playdate Starter

A minimal Playdate game project written in Lua. The starter screen shows a counter
that increases when you press **A**.

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

In VS Code, use **Terminal → Run Task** and choose **Playdate: Build** or
**Playdate: Build and Run**. The Lua extension is recommended for language
support and diagnostics.

## Project layout

- `Source/main.lua` — game update loop and starter interaction
- `Source/pdxinfo` — game metadata
- `Makefile` — SDK-backed build, run, and clean targets
