# Tidewater — Story Map

> **PROPOSED (updated 2026-10-16).** This is the player's route through the whole island, from the beach to the summit. Stages marked *built* have a level scene. Everything else is this map's suggestion from your notes: **nothing is built, no chapter docs exist for it, and every number can change.** The data lives in [`map.json`](map.json); the 3D miniature reads it, so edit the file and look again.

![The whole route, seen from the south-west with the ground see-through](map_views/map_iso.png)

## What changed in this update
You said reaching the harbor and the first climbing ladder came too soon. The route now takes the player **west through the jungle**, across a river, past roadblocks and old vehicles, and only then to the trail and the ravine ladder:

| | Before | Now |
|---|--------|-----|
| Beach to the first climbing ladder (the ravine scaffold) | about 65 m | **about 470 m** (the extra is the jungle loop, 5 new stages) |
| Beach to the harbor gate | about 100 m | **about 650 m** (the jungle loop plus a second diversion by the old hamlet) |
| Whole route | 2.1 km | **2.65 km** |

![The jungle diversion from above](map_views/map_jungle_top.png)

![The jungle diversion in 3D](map_views/map_jungle_iso.png)

## The route in one line
```
Beach → [shore and river ford → jungle → old road with bridge convoy → rim overlook and gully] → Trail → Ravine
   → [cut road and old hamlet] → Old Harbor → Base Camp → Cable car → The fall → Old Village
   → down to the coast → Colonial ship wreck → Sea cave → Underground tunnel → Cave system
   → Research-center bunker → Research center → Second facility → Summit: the ritual
```
Brackets are the new inserts. The player starts at sea level, climbs to 106 m (the village), **drops back to sea level** at the wreck, goes **under the mountain**, comes up inside it to the research center (300 m), then the second facility (360 m) and the summit (430 m).

## Stages
`Chapter` is the existing chapter, where there is one. Area numbers for proposed stages are **suggested** (one scene per area, as now). Lengths are the through-route only (the line on the map), not every step in a room, so real play is longer. Elevations are metres above sea level.

| # | Stage | Where | Status | Chapter | Areas | Route | Elevation | How you get through |
|---|-------|-------|--------|---------|-------|-------|-----------|---------------------|
| S01 | Beach | south shore | built | 1 | A01 | 80 m | 0 → 9 | **changed:** leave west along the shore (the trail mouth is blocked) |
| S02 | Shore and river ford | shore, river mouth | proposed | 1 (insert) | A12 | 65 m | 9 → 8 | roadblock 1 shuts the trail; wade the ford |
| S03 | Jungle and first roadblock | west plateau | proposed | 1 (insert) | A13 | 123 m | 8 → 18 | a winding jungle path to an old barricade and jeep |
| S04 | The old road: bridge convoy | west plateau | proposed | 1 (insert) | A14 | 127 m | 18 | cross the collapsed bridge over the wrecked convoy (second river crossing) to a boom gate |
| S05 | Rim overlook and the gully | plateau edge, above the trail | proposed | 1 (insert) | A15 | 45 m | 18 → 3 | the first view of the whole island; a gully down to the trail |
| S06 | Trail | forest, inland | built | 1 | A02 | 29 m | 3 → 5 | fallen tree, wall, shrine (entered from the gully) |
| S07 | Ravine | island-wide trench | built | 1 | A03 | 35 m | 5 → 12 | the scaffold and **the first ladder**; it collapses behind you |
| S08 | The cut road and the old hamlet | west wall, north of the ravine | proposed | 1 (insert) | A16 | 138 m | 12 → 4 | a landslide cuts the road; climb to the hamlet, drop into the yard from the west |
| S09 | Old Harbor | fenced yard | built | 1 | A04 | 75 m | 4 | shed, tower, searchlight, cut the gate chain |
| S10 | Base Camp | supply depot | built | 2 | A05 | 57 m | 4 | power the cable car |
| S11 | The Line | cable car up the mountain | built | 3 | A06 | 200 m | 6 → 123 | the car stops; climb down the pylon ladder |
| S12 | The Fall | pylon 3 → the hollow | built | 3 | A06/A07 | 155 m | 107 | a rung gives way; **no way back up** |
| S13 | The Old Village | sunken hollow | built | 4 | A08–A11 | 234 m | 106 → 120 | *proposed change:* the south-west rim gap, not the cargo lift |
| S14 | Down to the coast | gully, west side | proposed | | A17 | 192 m | 120 → 3 | steep and loose: **one way** |
| S15 | Colonial ship wreck | the cove, west coast | proposed | | A18 | 56 m | 3 → 1 | through the hull, then wade along the waterline |
| S16 | Sea cave | cliff foot, from the water | proposed | | A19 | 30 m | 1 → 2 | inward, away from the sea |
| S17 | Underground tunnel | under the west slope | proposed | | A20 | 196 m | 2 → 28 | meets the cave system |
| S18 | Cave system | inside the mountain | proposed | | A21–A23 | 364 m | 28 → 200 | the longest climb: about 170 m up |
| S19 | Research-center bunker | under the research center | proposed | | A24 | 154 m | 200 → 290 | a sealed door, then a lift shaft (about 75 m) |
| S20 | Research center | top of the cable line | proposed | | A25–A26 | 154 m | 274 → 361 | service road up |
| S21 | Second facility | between the center and the summit | proposed | | A27 | 92 m | 361 → 431 | steps / funicular up |
| S22 | Summit: the ritual site | top of the mountain | proposed | | A28 | 6 m | 431 | the finale |

Total through-route: about **2.65 km**, of which about 0.7 km is underground (S16–S19).

## The first half, in detail (new)
- **Roadblock 1 (S02), the trail mouth.** A jackknifed truck and a rockfall shut the canyon trail at the beach end. This is the reason to leave the beach to the west.
- **The river (S02, S04).** It runs north to south across the west plateau to the south coast, so it is seen from the beach (its mouth is just west of it). It is crossed **twice**: wading the **ford** at the south, and the **collapsed bridge** at the north.
- **The jungle (S03).** The west plateau is 13 to 25 m above the trail. The loop winds and doubles back, so the player loses the sense of direction. The ravine ahead is a trench across the *whole island* in the real terrain (it is 8 m deep and about 6 m wide at z 3 to 9), so the player **cannot bypass it**; the loop therefore stays south of it.
- **The old road (S04).** A military road runs east along the plateau. **Roadblock 2** at its west end is a barricade and a rusted jeep. On the bridge, **old vehicles from different eras** (an explorers' truck, an army jeep, a company truck) are stuck; the player crosses over and through them. **Roadblock 3** at the east end is a boom gate and a guard hut at the rim.
- **The rim overlook (S05).** From the plateau edge the player sees the whole island for the first time: the trail and the ravine below, the lit harbor, the cable line climbing, and a faint light on the summit.
- **The cut road and the hamlet (S08).** After the ravine a landslide has cut the road. A path climbs to the ruins of the **mainland fishermen's hamlet** (graves, a warning board), then a track drops into the harbor yard from the west.

### Early story elements to reveal here (suggestions)
| Where | What the player finds | What it plants |
|-------|----------------------|----------------|
| Roadblock 1 (S02) | A stencil "DET 9: ROAD CLOSED BY ORDER", and under it an older carved warning: "When the stone rises, go inside. Do not answer." | The military cover-up and the local folklore, in the first minutes |
| Jungle (S03) | Red cloth offerings tied to trees (like the shrine's bracelet); a half-buried stone with an open-hands carving | The island had people; seeds the village chapter |
| Bridge convoy (S04) | Vehicles from three decades: **expeditions keep coming and never leave.** A cassette in one cab: a driver says the stone rose and the road behind them was gone | Det. 9 is not the first; the rule of the stone |
| The same trucks | Crates stencilled TIDEWATER; a manifest line "Sample cases (sealed): DOWN ONLY" | Ties to the Ch2 manifest |
| Rim overlook (S05) | A faint light that pulses on the summit; the black stone offshore | The goal, from the start |
| The ford (S02) | A figure on the far bank, gone when you look again | The creature's "appear and vanish" rule, early |
| Hamlet (S08) | Mainland graves whose dates stop at the same night; a warning board like the one at the harbor | "The locals knew" |

## Where things are
Coordinates are the game's world metres: x east, **z south (up the mountain is negative z)**, y up. The grid in the miniature is 100 m.

| Place | x, z | Notes |
|-------|------|-------|
| Beach landing | 0, 66 | built |
| Roadblock 1 (trail mouth) | 0, 52 | proposed |
| River ford | −123, 76 | proposed |
| Jungle loop | −195 … −123, 24 … 76 | proposed |
| Collapsed bridge and convoy | −132, 26 | proposed |
| Rim overlook and boom gate | −40, 30 | proposed |
| Ravine | whole island, z 3 … 9 | built into the terrain |
| Old fishing hamlet | −58, −58 | proposed |
| Old Harbor gate | 10, −80 | built |
| Cable car lower station | 5, −140 | built |
| Pylon 3 / car stops | 5, −305 | built |
| Old village (floor) | −140 … −240, −335 | built; floor 105 m |
| Village west rim (the exit gap) | −258, −315 | proposed |
| The cove and ship wreck | −355, −300 | proposed; the real terrain has **no coast there yet** |
| Sea cave mouth | −388, −334 | proposed; at the waterline |
| Cave system | −60 … −205, −440 … −545 | proposed |
| Bunker | −45, −455, y 214 | proposed |
| Research center | 10, −470 | proposed; surface 300 m |
| Second facility | 10, −520 | proposed; surface 360 m |
| Summit ritual circle | 5, −560 | proposed; surface 430 m |

## Seeing it
| View | |
|------|---|
| ![Plan view](map_views/map_top.png) | **Plan.** The built areas are the white boxes. The route loops west through the jungle, comes back to the trail, goes up the middle, bends west at the village, round the coast, under the mountain, and back east to the summit. |
| ![Profile from the west](map_views/map_profile_west.png) | **Profile from the west.** Purple is underground. Note the drop from the village (106 m) to sea level, then the climb through the mountain. |
| ![Underground detail](map_views/map_underground.png) | **Underground detail** at the bunker. The research center sits 75 m above it. |

## How the player moves
- **Mostly one-way.** Points of no return: the ravine scaffold (S07), the ladder fall (S12), the gully down to the coast (S14). The player never backtracks to the beach, the camp or the cable line.
- **Two loops in the first half.** The jungle loop (S02–S05) and the hamlet detour (S08) leave the main line and rejoin it, so the first half is a chain of detours around roadblocks, with something new to find each time.
- **The big shape is a horseshoe.** Up the mountain (S11–S13), **down to sea level** (S14–S16), up *through* the mountain (S17–S19), then up *over* it (S20–S22): cable car, caves, summit.
- **Sea level is the middle of the game.** The wreck, sea cave and tunnel are the lowest, darkest part. The summit is visible from every outdoor stage, so it can pull the player on.

### Who can reach the player where (proposals)
| Place | The creature (the Shepherd) | The owner (power) |
|-------|------------------------------|-------------------|
| Jungle, old road | glimpses | no (no power yet) |
| Harbor, camp, cable line | glimpses | yes (lamps, gates, generator) |
| Village | yes (the colonist's home) | **no** (no power) |
| Wreck | yes (his ship) | no |
| Sea cave, tunnel | tracks it | only if the company lit the tunnel |
| Cave system | the god's place: neither feels welcome | no |
| Bunker, research center, facility | rarely | **yes** (everything runs on power) |
| Summit | the finale | yes |

### Shortcuts that would let the world loop (ideas, not decisions)
- The cable car, once powered again from the research center, takes the player down to camp.
- The village cargo lift (built in Ch4) goes up to the service path: a late shortcut from the village.
- The bunker door can only be opened from the research-center side, so the cave route becomes a one-way gate.

## Length
**Decision (2026-10-16): a longer game is wanted; no need to squeeze it to 90 minutes.** Rough estimate at the density already built (puzzles, exploring, reading): the first half (S01–S13) is now about **70 to 115 minutes** (the jungle loop and hamlet add about 25 to 40 minutes), and the second half (S14–S22) about 80 to 125, so the whole route is about **2.5 to 4 hours**. This is a guess from the previs lengths times 2 to 4, not a playtest; revisit it once a stage is playable.

## Conflicts with what is already written (please decide)
1. **Chapter 4 ends on the cargo lift up to the service path, but you now want the village to lead to the wreck.** This map makes the village exit the south-west rim gap, and leaves the lift as a built-but-unused shortcut. The Ch4 previs is **not changed**. Options: keep the lift as a *false* exit, or move it to a later shortcut.
2. **The lit path, stream and forest (Ch3 beats 7–9, drawn as the "service path (surface, bypassed)" line).** In this route the player never walks it; they reach the research center from below. Cut it, keep it optional, or use it in the finale?
3. **The research center now has two entrances.** The cable car (Ch2–3 promise "the car takes you to the research center") and the underground bunker. Which one does the player earn?
4. **`BACKSTORY.md` puts the ritual in "the research center and the chamber".** You now say the ritual is on the summit. That needs a backstory edit: where was the three-crystal circle opened (the village ring in the old festival, the summit, or both)? The "sandbar where Elias went" has no place on this map yet.
5. **The hollow under the island comes back.** It was cut from Ch2 (Elias's blast hatch at the harbor). The cave system is a natural home for it, and the hatch at (6, −129) could be a *second* way in.
6. **Terrain does not exist yet** for the west coast, the cove, the sea cave, the summit, the north slope, or the **river**. The miniature invents them in `game/map/island_height.gd` (the river channel is cut from `map.json`). Building those levels means adding them to the real height function in `tools/build_common.gd`.
7. **Chapter 1 (doc and previs) is unchanged.** The built Ch1 goes beach → trail → ravine → harbor in a straight line. This map needs: a west exit from the beach (A01) and a blocked trail mouth; the trail entered from the gully; the harbor entered from the west. The new stages S02–S05 and S08 need their own area scenes and a rewrite of the Ch1 beats before any of it is built.

## Open questions
- The **second facility**: what is it, and who is in it?
- The **colonial ship**: is the wreck the Shepherd's (the colonist's) ship, so the player learns his story at its source, or the company's?
- The **sea cave**: swim or boat? Is there a tide puzzle?
- The **tunnel**: man-made by the colonist, the company, or both? That decides whether the owner can reach it.
- Does the **summit** have an inside (a chamber in the crater), or is it all outdoors?
- The **jungle loop**: how dangerous? (Only atmosphere and glimpses, or a first chase?) Is the river crossing a puzzle or just a set piece?
- How many chapters? A suggestion: the jungle and hamlet inside Ch1, then S14–S16 one chapter, S17–S18 one, S19–S20 one, S21–S22 the finale. That is only a grouping idea.

## Using the miniature
Open the model (any folder):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path "/Users/tharumagulasingamupenthiran/Documents/GameIdea/island horror game /godot" res://game/map/island_miniature.tscn
```

Note the trailing space in `island horror game `, and keep the quotes.

| Control | |
|---------|--|
| Left-drag, right-drag, wheel | orbit, pan, zoom (WASD also pans, Q/E down/up) |
| `Space` | a white marker walks the whole route; `[` `]` change speed; `F` follows it |
| `,` `.` | previous / next stage (frames it) |
| `X` | ground see-through or solid |
| `L` `G` `A` | labels, 100 m grid, built-area outlines |
| `1` `2` `3` `4` | top, iso, south, west views |
| `H`, `Esc` | hide panels, quit |

Colours: **green** = built surface, **amber** = proposed surface, **purple** = underground, **blue** (thin) = cable car, **blue** (thick) = the river, **white** lines = the built areas A01–A11.

To plan a change: edit [`map.json`](map.json) (route points are `[x, z]` on the ground, or `[x, z, y]` at a fixed height), save, and open the model again. To print the stage table: add `-- --report` after the scene path with `--headless`. Screenshots and the `--view`, `--stage` and `--focus` options are described at the top of `game/map/island_miniature.gd`.

Files: `story/map.json` (data), `game/map/island_miniature.tscn` + `.gd` (viewer), `game/map/island_height.gd` (the miniature's terrain), `story/map_views/` (the pictures above).
