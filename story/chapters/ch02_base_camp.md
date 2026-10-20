# Chapter 02 — Base Camp

> Reworked 2026-10-14 from "The Closed Area". No underground: the hatch, blast site, command building, door code, incident report and the hollow are cut. Everything marked **PROPOSED** is new and needs your OK.

## Summary
Through the gate, the ground still vibrating with a low oceanic hum: the Black Stone has risen, meaning no boat is coming. The closed area turns out to be a **supply base camp** for **Vane Bio-Marine's Project TIDEWATER** (operating under the cover of Detachment 9). Everything here is crated and stamped for the **Research Center and Upper Crater Array at the top of the mountain**, fed by a heavy **cargo cable car**. The car's lower station is dead. It runs off Substation B, whose generator is dry, so the player gets fuel from the barracks (finding Elias's locker with a photo of **Elias and Dr. Mara Chen** and a draft warning never to trust his phone, then hiding in a locker when **The Shepherd** enters dripping seawater and mimicking dead voices). They start the generator, set the breakers in order, and power returns across the camp—giving **Julian Vane** (fused into the grid) his voice. At the station, the intercom plays a message in **Elias's spliced voice** luring them up the mountain. The player boards Car 2 and throws the RUN lever. The drive winds up while The Shepherd sprints across the yard, and the car lurches out just as it slams against the platform rail.

## Location
- **Level:** `res://game/levels/a05_base_camp/a05_base_camp_blockout.tscn` (A04 Old Harbor is also loaded for the opening aerial shot)
- **Markers used:** `Mk_Ch02_GateInside`, `Mk_Ch02_SupplyYard`, `Mk_Ch02_Manifest`, `Mk_Ch02_Station`, `Mk_Ch02_Booth`, `Mk_Ch02_CableCar`, `Mk_Ch02_Generator`, `Mk_Ch02_BreakerPanel`, `Mk_Ch02_BarracksDoor`, `Mk_Ch02_EliasLocker`, `Mk_Ch02_FuelCan`, `Mk_Ch02_HideLocker`
- **Level nodes animated:** `Dynamic/BasePower` (camp + station lights), `FuelCan`, `Lever_Lighting/Comms/Main`, `CableCar` (+ `CabinLight`, `RunLever`); the gate (A04) starts open.

## Characters present
Protagonist, The Shepherd / Capt. Alistair Locke (stalks barracks, charges platform), Julian Vane (speaks over the station intercom using spliced recordings of Sgt. Elias).

## Beats
| # | Beat | Target time | Notes |
|---|------|-------------|-------|
| 1 | Chapter card; aerial over the camp, rising to the cable line going up into the fog | 0:00 | **PROPOSED** reveal of the line in the opening shot |
| 2 | **PROPOSED:** Supply yard: crates stencilled UPPER STATION, the supply manifest → "this whole camp feeds something up the mountain" | 0:19 | |
| 3 | **PROPOSED:** Cable car lower station: car 2 parked, the drive switch is dead → "everything runs off that substation" | 0:42 | reuses the old keypad line |
| 4 | Generator is dry → barracks: Elias's locker, fuel can | 1:04 | duty roster cut (its door-code notice belonged to the command building) |
| 5 | **Encounter 1:** it comes through the barracks door; hide in a locker | 1:58 | unchanged |
| 6 | Fuel and start the generator; breakers (wrong order → bang; right order → power) | 2:28 | the power now runs to the cable car |
| 7 | **PROPOSED:** Back at the station, car 2 is lit | 3:15 | |
| 8 | **PROPOSED:** Intercom: Elias's message from the upper station (rewritten: he went up) | 3:35 | |
| 9 | **PROPOSED:** Board car 2, throw RUN; the drive winds up while it charges across the yard; the car lurches out as it reaches the platform | 4:12 | replaces the hatch race |
| 10 | End card: "Chapter 3 — The Line" (**PROPOSED** title) | 4:42 | |

## Scares
| Setup | Payoff | Timing |
|-------|--------|--------|
| Fuel can taken | Door bangs; it walks the barracks while you hide | 1:58 → 2:28 |
| Note: "it hears the bang" | Main breaker first → sparks, BANG | 3:02 |
| Intercom: "it's climbing the line" | You need the car anyway | 4:05 |
| RUN thrown, drive winding up | A wail; it sprints across the yard; the car leaves with it at the platform rail, watching you go | 4:19 → 4:42 |

## Narration / dialogue (placeholder text)
Unchanged lines come from the original chapter 2 text (arrival, generator, fuel, encounter 1, breakers, Elias's locker, panel note). **PROPOSED** new lines are in `tools/story_text.gd` (`T2B`, `NOTE_MANIFEST`, `RADIO_UP`):
- **PROPOSED** thoughts: "(Rations. Diesel. Medical. All of it stamped for the upper station. This whole camp just feeds something up the mountain.)" · "(A cable car. The line goes up into the fog... all the way to the top.)" · "(Power. The cable car should run now.)" · "(It's lit. It works.)" · "(Moving. It's moving.)" · "(It's standing where I was. Watching me go up.)"
- **PROPOSED** Supply Manifest: cargo for car 2 to the upper station; personnel transfer by car only, the mountain road CLOSED; in pencil: *"Car 1 never came back down."*
- **PROPOSED** Elias on the intercom (replaces the radio):
  1. "...if anyone's still on this frequency. This is Sergeant Elias, Detachment 9." (unchanged)
  2. "I'm at the upper station. The research center. What's left of the survey team made it up here with me."
  3. "The camp isn't safe. It came up out of the water, and it walks the yard every night."
  4. "I sent car one back down for anyone still alive. Nobody came."
  5. "If you're hearing this, whoever you are: do not follow me. And if it calls you by name, don't answer." (unchanged)
  6. "...[static]... it's on the line. It's climbing the line—"

## Previs
- **Status:** draft (reworked)
- **Scene:** `res://previs/chapters/ch02_base_camp/chapter02_base_camp.tscn`
- **Length:** 289.3 s (4:49.3), 15 shots
- **Views:** first person by default (`Cam_FP`), V for cinematic. Gaze script: `res://previs/chapters/ch02_base_camp/fp_gaze.json`.

| Beat | Marker | Timestamp | Length | Area |
|------|--------|-----------|--------|------|
| Chapter 2 | `s01_chapter_2` | 0:00.0 | 4.0 s | — |
| The base camp | `s02_the_base_camp` | 0:04.0 | 15.0 s | AREA 05 · Base Camp |
| The supply yard | `s03_the_supply_yard` | 0:19.0 | 23.0 s | AREA 05 · Base Camp |
| The cable car station | `s04_the_cable_car_station` | 0:42.0 | 22.0 s | AREA 05 · Base Camp |
| The generator | `s05_the_generator` | 1:04.0 | 19.0 s | AREA 05 · Base Camp |
| Into the barracks | `s06_into_the_barracks` | 1:23.0 | 9.0 s | AREA 05 · Base Camp |
| Elias's locker | `s07_elias_s_locker` | 1:32.0 | 12.0 s | AREA 05 · Base Camp |
| The fuel can | `s08_the_fuel_can` | 1:44.0 | 14.0 s | AREA 05 · Base Camp |
| Footsteps at the door | `s09_footsteps_at_the_door` | 1:58.0 | 30.0 s | AREA 05 · Base Camp |
| Fuelling the generator | `s10_fuelling_the_generator` | 2:28.0 | 23.0 s | AREA 05 · Base Camp |
| The breakers | `s11_the_breakers` | 2:51.0 | 24.0 s | AREA 05 · Base Camp |
| Back to the station | `s12_back_to_the_station` | 3:15.0 | 20.0 s | AREA 05 · Base Camp |
| The intercom | `s13_the_intercom` | 3:35.0 | 37.3 s | AREA 05 · Base Camp |
| The cable car | `s14_the_cable_car` | 4:12.3 | 30.0 s | AREA 05 · Base Camp |
| End of Chapter 2 | `s15_end_of_chapter_2` | 4:42.3 | 7.0 s | — |

## Review notes
- 2026-10-14: Reworked per feedback: no underground; the camp is the supply base for the research center on the mountain; the generator powers the cable car; the command building is cut; Elias went up the mountain. The new beats and lines are PROPOSED.
- To judge: does the supply yard → station → generator order read? (The player sees the dead station before knowing about the generator, so the generator has a reason.) Is 30 s right for the departure?
