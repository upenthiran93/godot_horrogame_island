# Chapter 04 — The Old Village

> **PROPOSED (2026-10-16), previs built as a first draft.** The story it relies on (`BACKSTORY.md`) is still a draft, so beats may change. Shots do not follow the beat numbers below one-to-one: the table in **Previs** is the shot list.

## Summary
The fall from the pylon ladder drops the player into a sunken hollow below the service path: the ruins of the island's original village. The way back up is gone and the steps out are buried. No power reaches down here, so the owner can't see or speak to the player. The village tells its own story through carvings (the villagers), torn log pages (the colonist) and dig tags (the company), in an order that goes from warm, to wrong, to horror. At the burned quarter the player meets the creature properly and learns it is **the colonist**, not a monster from nowhere. The only way out is the company's cargo lift at the festival ring, which needs power and a code. Starting the dig-site generator is loud, it gives the owner his first real foothold, and he lies about the code. The chapter ends riding the lift up to the lit service path with the creature below.

## Location
- **Levels (one scene per area, shared world coordinates):**
  | # | Area | Contents |
  |---|------|----------|
  | A08 | Hollow Edge | Where the player lands. Tree roots, drag marks, the first houses, the buried steps |
  | A09 | Village Lanes | Homes, the guest house (where the crew were healed), the healing wall, the year marks |
  | A10 | Festival Ring | The standing-stone ring, the company dig site and generator, the cargo lift |
  | A11 | Burned Quarter | The massacre site, the pile of bones, the last carving, the creature |
- **Numbering note:** A07 (Service Path) already exists from Chapter 3. The player returns to it at the end of this chapter by the lift, so the area numbers are not in play order.
- **Markers to add (proposed):** `Mk_Ch04_Landing`, `Mk_Ch04_BuriedSteps`, `Mk_Ch04_GuestHouse`, `Mk_Ch04_HealingWall`, `Mk_Ch04_YearMarks`, `Mk_Ch04_Ring`, `Mk_Ch04_DigSite`, `Mk_Ch04_Generator`, `Mk_Ch04_Lift`, `Mk_Ch04_BurnedQuarter`, `Mk_Ch04_Bones`, `Mk_Ch04_LastCarving`, `Mk_Ch04_StalkerSpot`
- **Animated level nodes (proposed):** `Dynamic/Generator`, `Dynamic/FloodLights`, `Dynamic/Lift`, `Dynamic/DigRadio`

## Characters present
Protagonist; the creature (the colonist, **the Shepherd**; name TBD) in glimpses, then seen properly; the owner (voice only, from the dig radio, after the generator starts); Elias (named in the company dig log; possible ghost glimpse, optional).

## How the story is told
No one speaks to the player. The villagers' culture is gone, so nothing is explained; the player pieces it together.
- **The villagers:** carvings and painted stones, pictures only, no text.
- **The colonist:** pages of his ship's log in old English, found in the guest house.
- **The company:** modern dig tags, a dig log, trench tape and tarps, with Elias's team named.

Backstory Parts 1–3 are revealed here, mixed with Part 4 (the company recovering the crystals). The rule of the god ("gifts only work when given willingly") is *shown*, not stated, in the last two finds.

## The reveal order (warm, then wrong, then horror)
| # | Find | Area | What the player learns | Voice |
|---|------|------|------------------------|-------|
| A | **The festival ring:** a circle of standing stones with three empty sockets; carvings of open-handed figures facing a tall figure | A10 (seen from the lanes first) | A god visited and was welcome; the sockets are where the crystals sat | Villagers |
| B | **The healing wall:** sick figures lying down, then the same figures standing; each holds a small crystal | A09 | The god gave gifts and each villager kept one | Villagers |
| C | **The year marks:** tally strokes cut beside the door of every house, one per year | A09 | A festival every year, peaceful, for a very long time | Villagers |
| D | **The guest house:** beds laid out for strangers; log pages: the leg whole by morning, "they told us all of it" | A09 | Wrecked crew were healed and taught; the captain wanted it for his country | Colonist |
| E | **The dig site:** trenches, pry marks on the sockets, a tag "Crystal 1 of 3 — recovered", a dig log naming Elias | A10 | The company took the crystals from here, for the owner | Company |
| F | **The burned quarter:** a pile of bones by the ring's edge, one still gripping a healing crystal; carvings slashed with iron | A11 | The festival day was a massacre; one crystal stayed with a villager who gave it up willingly | Villagers + Colonist |
| G | **The last carving:** the tall figure turned black and thin and bowed, leading a man in a coat on a cord; a black stone rising from the sea | A11 | The god punished the captain: he is the creature, and the black stone means the door is near | Villagers |

## Beats (proposed)
| # | Beat | Area | Notes (camera / sound / mood) |
|---|------|------|-------------------------------|
| 1 | Chapter card "The Old Village" | — | black |
| 2 | **Waking up:** blackout fades to ground-level view, ringing in the ears, a cracked phone with a dead voicemail screen | A08 | the fall from Ch3 hands over here |
| 3 | The hollow: lamps of the lit path are visible high up through the trees; the steps out are buried under a rockfall; drag marks leading to where you woke | A08 | no way up, no way back |
| 4 | The first houses: roofless stone walls, the lane runs in; the **festival ring** seen far off between the houses | A08 → A09 | quiet, wind only |
| 5 | The year marks: the player notices tally strokes by every door (find C) | A09 | first unease |
| 6 | The healing wall (find B) | A09 | warm; a beat of beauty |
| 7 | The guest house: beds, a rusted lantern, the log pages (find D); a floorboard creaks upstairs | A09 | sound changes here |
| 8 | **First glimpse:** through a window, a tall figure in a coat stands in the lane the player just walked; gone when they look again | A09 | stinger |
| 9 | The festival ring and the carvings (find A); the dig site tarps and trenches (find E) | A10 | the modern layer over the old one |
| 10 | The generator: needs fuel and a breaker thrown (a short puzzle); the player starts it, loud | A10 | **loud event: the creature hears it** |
| 11 | Floodlights blaze; the dig radio crackles; **the owner's first voice** gives a lift code, in Elias's recorded voice | A10 | he can lie |
| 12 | The code is wrong. The lift also needs the **guard's keycard**, which is somewhere beyond, in the burned quarter | A10 | forces the player on |
| 13 | The burned quarter: collapsed houses, the pile of bones, a dead guard with a radio and the keycard (find F) | A11 | the horror turn |
| 14 | The creature seen properly: the coat, a brass button matching the log, standing among the burned houses | A11 | it turns when lit or when the player is close |
| 15 | The last carving (find G): the creature was the captain | A11 | the tie is made |
| 16 | **Stalking:** it hunts the player back through the burned quarter to the ring (standard rules: sees close or lit, hears walking ~7 m, running ~16 m, loud events) | A11 → A10 | hiding spots: stone houses, the ring |
| 17 | The player finds the **real lift code** in the dig log (it differs from the owner's) and uses the keycard | A10 | puzzle payoff |
| 18 | The lift rises slowly; the creature comes out of the dark into the floodlights below and stops at the edge | A10 | it can't or won't follow |
| 19 | The top: the lit path, and the lamps switch on one by one as the owner finds the player again | → A07 | end card "End of Chapter 4" |

## Puzzles
- **Generator (beat 10):** carry a fuel can from the dig tents to the generator, throw the breaker. It is loud; the creature hears it from anywhere in the hollow.
- **The false code (beats 11, 12, 17):** the owner can't press keypads, so he gives the code over the radio, and it is wrong. The real code is in the company dig log, written for the lift crew. This is the first time the player is shown the owner's "he can lie" rule.
- **The keycard (beats 12, 13):** found on a dead company guard in the burned quarter, the only reason to go in there.

## Scares
| Setup | Payoff | Notes |
|-------|--------|-------|
| The waking drag marks | The marks lead off into the village, so something moved the player here | beat 3 |
| Tally marks by every door | The marks stop abruptly at the same year on every doorframe | beat 5 |
| A creak upstairs in the guest house | Nothing there; the log page on the table is now turned over | beat 7 |
| The figure in the window | Gone; muddy coat-prints on the sill outside | beat 8 |
| Generator pull-cord | The roar, then the whole hollow goes silent and the creature's footfalls answer | beat 10 |
| The friendly radio voice | The code is wrong | beats 11, 17 |
| Burned quarter lit by a flare | The creature stands in the glow, motionless | beat 14 |
| Lift ride | The creature at the edge of the floodlights, then the lights go out | beat 18 |

## Narration / dialogue (placeholder text)
**Inner thoughts (protagonist):**
- *(waking)* "...Elias? ...No. Where am I?"
- *(ring)* "Three empty sockets. Something sat in each of these."
- *(burned quarter)* "They didn't leave. They were killed."

**Log pages (old English, the colonist's, draft):**
1. "...the savages have kept us alive past all reason. Hartley's leg, broken in three places, was whole by morning. I have seen the stone they used. They show it freely..."
2. "...I have asked them how. They told us everything, down to the yearly gathering and the three stones. They think of me as a guest."
3. "...My country must have this. I will join their feast. I will take what they will not sell..."

**Dig tags and log (the company, draft):**
- Tag on the ring: "SOCKET 1/3 — CRYSTAL RECOVERED — E.R."
- Log, last page: "E. (security) objected to the circle being opened. Overruled by the owner. Lift crew: code is **\_\_\_\_** — change after the ceremony." *(the real lift code)*
- Marker flag on a trench: "DO NOT REMOVE — OWNER'S ORDERS."

**Owner's radio (draft):** "Don't be afraid. It's me. I'll get you out. The lift code is..." *(the wrong code)*

## Previs
- **Status:** draft (built 2026-10-16)
- **Scene:** `res://previs/chapters/ch04_the_old_village/chapter04_the_old_village.tscn`
- **Length:** 503.0 s (8:23.0), 21 shots, one camera per shot (`Cam_NN_Name`)
- **Views:** first person by default (`Cam_FP`), V switches to the cinematic coverage cameras. Gaze script: `res://previs/chapters/ch04_the_old_village/fp_gaze.json`. Rebuild `Cam_FP` with `godot --headless --path . --script res://tools/add_fp_camera.gd -- --only=4`.
- **Levels:** `res://game/levels/a08_hollow_edge`, `a09_village_lanes`, `a10_festival_ring`, `a11_burned_quarter` (blockouts, primitives only; each shot loads its own area). The hollow is a sunken bowl cut into the mountain 80 to 130 m west of the service path (see `VILLAGE_*` in `tools/build_common.gd`).
- **Generators:** `tools/village_builders.gd` (area geometry), `build_ch04()` in `tools/build_chapters.gd` (shots), text in `tools/story_text.gd` (`T4`, `LOG_PAGES`, `DIG_*`, `NOTE_LIFT_*`, `OWNER_RADIO`).
- **Play it:** `godot --path . res://previs/playblast_runner.tscn -- --chapter=4`, or `-- --from=3 --to=4`.

| Beat | Marker | Timestamp | Length | Area |
|------|--------|-----------|--------|------|
| Chapter 4 | `s01_chapter_4` | 0:00.0 | 4.0 s | — |
| Waking up | `s02_waking_up` | 0:04.0 | 14.0 s | AREA 08 · Hollow Edge |
| The hollow | `s03_the_hollow` | 0:18.0 | 22.0 s | AREA 08 · Hollow Edge |
| The first houses | `s04_the_first_houses` | 0:40.0 | 20.0 s | AREA 08 · Hollow Edge |
| The year marks | `s05_the_year_marks` | 1:00.0 | 14.0 s | AREA 09 · Village Lanes |
| The healing wall | `s06_the_healing_wall` | 1:14.0 | 19.0 s | AREA 09 · Village Lanes |
| The guest house | `s07_the_guest_house` | 1:33.0 | 36.0 s | AREA 09 · Village Lanes |
| The figure in the window | `s08_the_figure_in_the_window` | 2:09.0 | 14.0 s | AREA 09 · Village Lanes |
| The festival ring | `s09_the_festival_ring` | 2:23.0 | 24.0 s | AREA 10 · Festival Ring |
| The dig site | `s10_the_dig_site` | 2:47.0 | 24.0 s | AREA 10 · Festival Ring |
| The generator | `s11_the_generator` | 3:11.0 | 26.0 s | AREA 10 · Festival Ring |
| The radio | `s12_the_radio` | 3:37.0 | 34.0 s | AREA 10 · Festival Ring |
| The wrong code | `s13_the_wrong_code` | 4:11.0 | 24.0 s | AREA 10 · Festival Ring |
| The burned quarter | `s14_the_burned_quarter` | 4:35.0 | 30.0 s | AREA 11 · Burned Quarter |
| The keycard | `s15_the_keycard` | 5:05.0 | 20.0 s | AREA 11 · Burned Quarter |
| It stands there | `s16_it_stands_there` | 5:25.0 | 20.0 s | AREA 11 · Burned Quarter |
| The last carving | `s17_the_last_carving` | 5:45.0 | 24.0 s | AREA 11 · Burned Quarter |
| It hunts | `s18_it_hunts` | 6:09.0 | 34.0 s | AREA 11 · Burned Quarter |
| The real code | `s19_the_real_code` | 6:43.0 | 50.0 s | AREA 10 · Festival Ring |
| The cargo lift | `s20_the_cargo_lift` | 7:33.0 | 44.0 s | AREA 10 · Festival Ring |
| End of Chapter 4 so far | `s21_end_of_chapter_4_so_far` | 8:17.0 | 6.0 s | — |

## Review notes
- 2026-10-16: First outline, from the user's idea that the player falls into the old village and learns the story "story by story", and that the village needs its own chapter. Decisions I made that you didn't ask for: the creature is the colonist (matches `BACKSTORY.md` Part 2); the owner has no reach in the hollow until the generator starts; the exit is a company cargo lift with a keypad and a keycard, so the owner's lie works as a puzzle; the villagers' side is pictures only because their culture is gone.
- Open: is the healing crystal in the skeleton's hand pickable, and is it one of the three ritual crystals (see `STORY.md` open questions)? Is Elias seen here as a ghost, or only named in the dig log? What is the colonist's name?
- 2026-10-16: First previs built from the outline, 21 shots. Choices made while building that you didn't ask for: the guard's keycard comes with a road flare, which is how the creature is first seen (shot 16); the owner's radio voice speaks as "Sgt. Elias (radio)" (matches Ch2's intercom); the creature does not chase at a run here, it stalks and watches (shot 18), and it stops at the edge of the floodlights at the lift; the lift is an inclined rail up the north wall, not a vertical tower; the lamps of the lit path are drawn as a line of lamp posts along the north rim; the false code is 7392, the real one 2604. The chapter ends on the lift top (A10), not in A07; Ch5 would start there.
- Things to judge on first watch: shot 7 (36 s, the log pages) and shot 19 (50 s walk with the creature following) are the longest; the carving reveal (shot 17) is told by a caption, not a close-up, because the carving is only primitives.
- Not built: Elias as a ghost here; the healing crystal is a prop in the bone pile but cannot be picked up (no gameplay in previs).

