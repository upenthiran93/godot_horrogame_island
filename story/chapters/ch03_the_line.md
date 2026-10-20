# Chapter 03 — The Line

> **DRAFT — first part only (2026-10-14).** Chapters are edited one at a time, so nothing here is final. The part below is built in previs; everything after the forest is **not designed yet**.

## Summary
Car 2 climbs up the line above the camp through luminescent, ozone-scented fog. The ride jolts as it crosses the tower saddles, and **The Shepherd** can be seen on the steep slope outside—keeping pace with the machine, then appearing ahead of it by the next tower. Halfway up, **Elias's earlier sabotage** takes effect: a mechanical clamp bangs shut at **Pylon 3**, stopping the car dead and killing the cabin light (cutting off Julian Vane's radio reach). With no other way forward, the player climbs out and down the icy pylon ladder. A rusted rung snaps, dropping the player through the canopy into the sunken **Old Village hollow** (Chapter 4).

*(Note: Beats 7–9 in this previs scene—the Lit Service Path, Old Stream Plank Bridge, and Forest in `A07`—are traversed immediately after the player rides the Cargo Lift out of the Old Village at the end of Chapter 4, culminating in The Shepherd's bridge ambush that drops the player into the West Gully for Chapter 5.)*

## Location
- **Levels:** A06 Ropeway (the line, pylons, the stopped car), A07 Service Path (the path, forest, scree, stream and bridge). A05 is loaded at the start for the view back over the camp. The fall is the transition: A06 unloads and A07 loads, so the ropeway is never shown again.
- **Markers used:** `Mk_Ch03_Pylon_1..4`, `Mk_Ch03_CarStop`, `Mk_Ch03_PathStart`, `Mk_Ch03_PathTurn_*`, `Mk_Ch03_Bridge`, `Mk_Ch03_RideStart`
- **Animated level nodes:** `Dynamic/CableCar` (ride, shake, sway, breakdown), `CableCar/CabinLight`, `CableCar/RunLever`

## Characters present
Protagonist, the creature (on the slope; then by the next tower; then it's out of sight).

## Beats (built)
| # | Beat | Notes |
|---|------|-------|
| 1 | Chapter card "The Line" | |
| 2 | Above the camp: ride up; a jolt over the first tower saddle; cabin sways | |
| 3 | Something on the slope: the creature keeps pace with the car | creature visible outside |
| 4 | It's ahead: the creature is now ahead of the car, by the next tower | |
| 5 | The breakdown: grinding, a bang as the grip locks, the car stops dead, light flickers and dies | "No stop. Don't stop." |
| 6 | Climbing out and down the pylon ladder; a rung gives way | A06 ropeway loaded |
| 6b | **The fall:** the player drops the last metres to the ground; blur, then black. The ropeway (A06, the car and the line) unloads here: the point of no return. | A07 loaded, A06 unloaded |
| 6c | **Waking up:** blackout, breathing, the view clears and the player gets up on the forest side | |
| 7 | The lit path: fenced path under lamps, up toward the trees | |
| 8 | The old stream: crossing a plank bridge over the water | **PROPOSED** stream + bridge placement, see review notes |
| 9 | The forest: trees packed on both sides, loose scree underfoot | |
| 10 | End card: "End of Chapter 3 (so far)" | |

## What comes next
> **Cosmic Horror Route Integration (v8):**
> 1. **The Fall (`s07`)** drops the player into the unpowered **Old Village (`A08–A11`, Chapter 4)**.
> 2. At the end of **Chapter 4**, the player rides the **Village Cargo Lift (`A10`)** up to the **Lit Service Path (`A07`)**.
> 3. The player then walks the **Lit Path, Old Stream Plank Bridge, and Forest (`s08–s11`)**, where **The Shepherd ambushes them on the bridge**, collapsing it into the **West Gully (`S09`)** and starting **Chapter 5: The Belly of the Mountain**. All built `A06` and `A07` assets remain 100% used.

## Previs
- **Status:** draft (first part, with the fall)
- **Scene:** `res://previs/chapters/ch03_the_line/chapter03_the_line.tscn`
- **Length:** 191.0 s (3:11.0), 12 shots
- **Views:** first person by default (`Cam_FP`), V for cinematic. Gaze script: `res://previs/chapters/ch03_the_line/fp_gaze.json`. The fall uses screen blur and a roll in the first-person view.

| Beat | Marker | Timestamp | Length | Area |
|------|--------|-----------|--------|------|
| Chapter 3 | `s01_chapter_3` | 0:00.0 | 4.0 s | — |
| Above the camp | `s02_above_the_camp` | 0:04.0 | 20.0 s | AREA 06 · Ropeway |
| Something on the slope | `s03_something_on_the_slope` | 0:24.0 | 24.0 s | AREA 06 · Ropeway |
| It's ahead | `s04_it_s_ahead` | 0:48.0 | 14.0 s | AREA 06 · Ropeway |
| The breakdown | `s05_the_breakdown` | 1:02.0 | 22.0 s | AREA 06 · Ropeway |
| Climbing out | `s06_climbing_out` | 1:24.0 | 16.0 s | AREA 06 · Ropeway |
| The fall | `s07_the_fall` | 1:40.0 | 5.0 s | AREA 07 · Service Path |
| Waking up | `s08_waking_up` | 1:45.0 | 12.0 s | AREA 07 · Service Path |
| The lit path | `s09_the_lit_path` | 1:57.0 | 22.0 s | AREA 07 · Service Path |
| The old stream | `s10_the_old_stream` | 2:19.0 | 20.0 s | AREA 07 · Service Path |
| The forest | `s11_the_forest` | 2:39.0 | 26.0 s | AREA 07 · Service Path |
| End of Chapter 3 so far | `s12_end_of_chapter_3_so_far` | 3:05.0 | 6.0 s | — |

## Review notes
- 2026-10-14: First part built from your description: the ride, shaking, the creature outside, the breakdown, climbing out, and the walk up a fenced lit path, through a forest, with scree and an old stream on a plank bridge.
- 2026-10-14: Added the fall. The rung gives way on the ladder, the player lands hard, the screen blurs and goes black, the ropeway unloads, and the player wakes up on the forest side. There is no way back up to the car.
- To check on the first watch: the "SERVICE PATH — UPPER STATION" sign sits next to the landing spot and fills the view as the player wakes.
- 2026-10-16: Proposed splitting the village out as Chapter 4 and moving the lit path, stream and forest to Chapter 5 (see What comes next). Previs not changed yet.
- Not designed yet: what happens after the forest, what the research center looks like from here, and any puzzles on the way up.
