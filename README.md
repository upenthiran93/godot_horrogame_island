# Tidewater (island horror game)

A first-person island horror game in Godot 4.7, built previs-first: story in `story/`, auto-playing chapter playblasts in `previs/`, level blockouts in `game/levels/`, and a 3D story map in `game/map/`.

- Story bible: `story/STORY.md` · backstory: `story/BACKSTORY.md` · island route: `story/MAP.md`
- Play the previs: open the project in Godot 4.7 and run it (main scene `previs/playblast_runner.tscn`), or run `res://previs/playblast_runner.tscn -- --chapter=4`.
- Island map miniature: run `res://game/map/island_miniature.tscn`.

## Assets
The Synty POLYGON Prototype model pack is licensed and is **not** in this repository (`assets/packs/` is git-ignored). Copy your own copy into `assets/packs/synty_prototype/` (see `tools/fix_pack_materials.gd`) before running scenes that use its pieces.
