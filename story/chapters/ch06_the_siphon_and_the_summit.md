# Chapter 06 — The Siphon & The Summit

> **Design Document (v8) — Stages `S15–S17` (`A20–A23`).**
> **Target Playtime:** ~25 minutes.
> **Core Vibe:** Sci-fi cosmic horror climax (*SOMA* + *Call of Cthulhu*). You emerge from the ancient caves into Julian Vane's cold, brutalist scientific complex where **the building itself is possessed by Vane's mind**, confront Vane's half-mutated body inside the Neural Siphon Pod, and step out into the volcanic crater at `430 m` beneath a torn sky to decide the fate of everyone on the island.

---

## Summary
The 75-metre freight elevator carries the player—now holding **Tide-Stone #3** and the **Pale Shard**—into the basement of the **Research Center (`S15`)** at `300 m` elevation. Here, **Julian Vane** controls every circuit: he slams blast doors, kills corridor lights, vents freezing halon gas, and triggers alarms to herd the player while **The Shepherd** (who has climbed the cable car line to the Upper Station) prowls the compound. In **Dr. Mara Chen's Acoustics Lab**, the player discovers Mara's final recording and Vane's schematics, learning the full truth of the **Cosmic Law**: Vane's Siphon cannot save Elias or Mara; completing the forced circuit will only mutate Vane into a second Shepherd, whereas only **destroying the stone** or **willing ego-surrender** can end the cycle.

By pulling the manual server fuses in the Control Room, the player blinds Vane in the main building and climbs the wind-swept service road to the **Neural Siphon Facility (`S16`)** at `360 m`. Inside the surgical rotunda hangs **Julian Vane's physical body** inside a glass-and-brass **Faraday Pod**—half-calcified, black abyssal tendrils and copper wires growing through his ribs, his jaw beginning to split like Captain Locke's. While Vane begs and threatens through the wall speakers, the player sets the **Siphon Routing Console** (Leave Active, Overload Pod, or Sever Cables).

Finally, the player climbs the crater steps to **The Summit Ritual Site (`S17`)** at `430 m`. Above the peak hangs the **Black Halo**—a silent, floating ring of abyssal water tearing open the night sky. Two Tide-Stones blaze in the circle; the third socket waits. **The Shepherd** climbs over the crater rim for a desperate final confrontation among the standing stones. Using the Pale Shard at the summit totems to stun him, the player reaches the third socket and triggers one of the **Three Cosmic Horror Endings**.

---

## Location & Areas (`res://game/levels/`)
| # | Area | Stage | Elev. | Contents |
|---|------|-------|-------|----------|
| A20 | Research Center — Labs | S15 | 290 → 310 m | Freight lift arrival, Upper Cable Car Station dock (where Car 1 hangs wrecked), Mara's Bio-Acoustics Lab, halon gas corridor |
| A21 | Research Center — Control & Road | S15 | 310 → 361 m | Vane's Master Server Room (fuse puzzle), courtyard blast gate, steep service road up the volcanic cone |
| A22 | Neural Siphon Facility | S16 | 361 → 410 m | Brutalist concrete dome, superconducting cable conduits, Surgical Rotunda, **Julian Vane's Faraday Pod**, **Siphon Routing Console** |
| A23 | Summit Crater Circle | S17 | 410 → 431 m | Volcanic crater rim, the **Summit Stone Circle** (2 active Tide-Stones + 1 empty socket), 3 Resonance Totems, the **Black Halo** in the sky |

- **Proposed Markers:** `Mk_Ch06_LiftArrival`, `Mk_Ch06_UpperStation`, `Mk_Ch06_AcousticsLab`, `Mk_Ch06_MaraTape`, `Mk_Ch06_HalonCorridor`, `Mk_Ch06_ServerRoom`, `Mk_Ch06_FusePanel_1..3`, `Mk_Ch06_ServiceRoad`, `Mk_Ch06_SiphonDome`, `Mk_Ch06_VanePod`, `Mk_Ch06_SiphonConsole`, `Mk_Ch06_CraterSteps`, `Mk_Ch06_SummitCircle`, `Mk_Ch06_Socket3`, `Mk_Ch06_Totem_1..3`
- **Animated Level Nodes:** `Dynamic/BlastDoors`, `Dynamic/HalonVents`, `Dynamic/ServerFuses`, `Dynamic/VanePodBody`, `Dynamic/SiphonConsole`, `Dynamic/VoidHalo`, `Dynamic/Socket3Beam`

---

## Characters Present
- **Protagonist** (carries **Tide-Stone #3** and **The Pale Shard**).
- **Julian Vane:** Controls the Research Center systems in `A20–A21`; seen in person (his mutating physical body inside the Faraday Pod) in `A22`; speaks over the summit loudspeakers in `A23`.
- **The Shepherd (Capt. Alistair Locke):** Enters via the Upper Cable Car Station (`A20`), stalks the Server Room (`A21`), and faces the player in the final stand at the Summit Crater (`A23`).
- **Dr. Mara Chen:** Heard on her final audio log in `A20` and as a harmonic vision at the Summit Circle in `A23`.
- **Sgt. Elias:** Appears in Ending 3 (alive on the beach at dawn).

---

## Beats
| # | Beat | Stage / Area | Target Playtime | Notes (Camera / Sound / Gameplay) |
|---|------|--------------|-----------------|-----------------------------------|
| 1 | Chapter Card: "Chapter 6 — The Siphon & The Summit" | — | 0:00 | Hum of high-voltage transformers and howling mountain wind |
| 2 | **Upper Station Arrival:** Exiting the freight lift into `A20`; through the glass of the Upper Cable Car dock, wrecked **Car 1** sways in the wind—with wet barnacle tracks leading inside from the cable line | S15 · A20 | 2 min | Establishes how The Shepherd reached the top of the mountain |
| 3 | **Vane's Electronic Trap:** Vane locks the main exit door via magnetic seal and vents freezing white halon gas into the hallway; the player must smash an maintenance vent to bypass his lock | S15 · A20 | 2 min | First encounter with the building itself as an enemy |
| 4 | **Dr. Mara Chen's Acoustics Lab:** Finding Mara's spectrogram recordings of the Sleeper and her final hidden cassette tape warning that Vane's Siphon is a lie | S15 · A20 | 3 min | Essential lore payoff; unlocks the secret behind Ending 3 |
| 5 | **The Server Room Stalk (Blinding Vane):** To open the magnetic blast gate to the upper road, the player must pull **3 manual high-voltage fuses** in the Server Room (`A21`); each fuse pulled darkens a section of the room while Vane triggers loud klaxons to draw **The Shepherd** | S15 · A21 | 3 min | High-tension stealth puzzle combining both villains |
| 6 | **The Volcanic Service Road:** Escaping through the unpowered blast gate onto the ash-covered road (`310 m → 360 m`); above, the sky is glowing with an eerie violet-black ring | S15 · A21 | 2 min | Brief outdoor breather before the Siphon Lab |
| 7 | **The Neural Siphon Facility:** Entering the concrete rotunda (`A22`); thick superconducting cables pulse like veins along the floor, leading from the ceiling down into a central glass-and-brass **Faraday Pod** | S16 · A22 | 2 min | Industrial body-horror atmosphere |
| 8 | **Face-to-Face with Julian Vane:** Inside the pod floats **Vane's physical body**—emaciated, half-covered in black deep-sea barnacles and copper filaments, one eye turned completely black like the Sleeper's. He speaks through a ring of speakers around his tank | S16 · A22 | 3 min | The puppeteer revealed as a terrified, mutating parasite |
| 9 | **The Siphon Routing Console (Choice Part 1):** Before taking the stairs to the crater, the player interacts with the **Siphon Routing Console** beside Vane's pod: **(A) Leave Siphon Routed to Vane**, **(B) Arm Pod Overload**, or **(C) Sever Conduit Cables** | S16 · A22 | 1 min | Sets the state for the 3 Endings |
| 10 | **The Summit Crater (`430 m`):** Stepping out into the open volcanic caldera (`A23`). Directly overhead, the clouds are parted around the **Black Halo**—an inverted ocean floating in the sky. Offshore, 430 m below, the Black Stone blazes | S17 · A23 | 2 min | Peak cosmic horror visual spectacle |
| 11 | **The Shepherd's Last Stand:** As you carry **Tide-Stone #3** toward the empty third socket of the Summit Circle, **The Shepherd** climbs over the crater rim, roaring in a chorus of twenty stolen voices | S17 · A23 | 3 min | Final boss/evasion sequence: charge the **Pale Shard** at the 3 outer resonance totems to stun him and reach the center |
| 12 | **The Final Decision (Choice Part 2 & Ending):** At the third socket, choose what to do with **Tide-Stone #3** and witness one of the **Three Endings** | S17 · A23 | 2 min | Roll credits (~2.5 hours total playtime) |

---

## Puzzles & Climax Mechanics
1. **The Server Fuse Blackout (`A21`):** Julian Vane holds the upper courtyard blast doors shut using electromagnetic locks. Because Vane cannot touch physical switches, the player must manually pull 3 heavy copper bus-fuses (`Fuse_North`, `Fuse_East`, `Fuse_Core`). Each fuse pulled cuts Vane's cameras and lights in that quadrant, but triggers a 90 dB fail-safe buzzer that brings The Shepherd running—forcing the player to pull a fuse, immediately cut their flashlight, and relocate in the dark.
2. **The Siphon Console (`A22`):** A physical three-position rotary switch + manual cable clamp outside Vane's Faraday Pod:
   - *Position 1 (Default):* `SIPHON ACTIVE — CONDUIT TO POD`.
   - *Position 2:* `REVERSE POLARITY — THERMAL OVERLOAD` (primes Vane's pod to burn out if the Summit breach collapses).
   - *Manual Lever:* `DISCONNECT CONDUIT` (physically uncouples Vane's cables from the Summit Circle so the circle operates in pure ancient communion).
3. **The Summit Circle & Totem Overloads (`A23`):** The Shepherd is faster under the open Void Halo and cannot be hidden from for long. Around the perimeter of the Summit Circle stand **three ancient resonance totems**. The player must sprint from totem to totem, holding up the **Pale Shard** to discharge three harmonic flashes that drive The Shepherd back to the crater rim, opening the path to the central altar.

---

## Key Dialogue & Lore Texts (Draft)

### 1. Dr. Mara Chen's Final Audio Log — Found in the Acoustics Lab (`A20`)
> *"Log entry 44—Mara Chen. If Elias finds this: don't let Vane near the summit circle. I finished translating the lower cavern glyphs. The entity beneath the island isn't a battery you can tap with a wire. It is a mirror. When the villagers gave their grief willingly, it gave them life. When Captain Locke tried to take that life in chains, the mirror inverted and turned him into The Shepherd. Vane thinks his Faraday Siphon will filter out the curse and pump the cure into his tank. It won't. Even if he forces a second person to complete the ring, the Deep knows what is stolen. The only way to close the wound is to shatter the third stone—or step into the ring with open hands and no machine at all."*

### 2. Julian Vane — In the Surgical Rotunda (`A22` Neural Siphon Facility)
1. *(As you approach the glowing Faraday Pod, the malformed figure inside twitches; six wall speakers speak in unison)* "Don't look at the glass like that. Look at the monitors. Six hours left before the black cartilage reaches my brainstem."
2. "Do you know what it feels like to be stretched across four miles of copper wire while your body turns into barnacles and brine in a jar?!"
3. "Captain Locke was a primitive brute with iron chains. I built a clean filter! It was working—until your brother tore the third stone out and left me half-digested by this thing!"
4. *(If the player touches the Siphon Console)* "Don't touch that console! Listen to me! If you complete the circuit with the siphon running, it takes sixty seconds to flush my nervous system and release the breach. Sixty seconds, and you can walk down to the beach. Smash that stone, and you murder me—and you erase whatever is left of Elias in the dark!"

---

## The Three Endings (Shot & Script Breakdown)

### Ending 1: "The Severed Cord" (Keep Elias's Promise)
- **Trigger:** Set Siphon Console to `OVERLOAD` (or leave it) and **smash Tide-Stone #3** against the center altar at the Summit (`A23`).
- **Cinematic Sequence:**
  1. You raise the heavy black stone above your head and bring it down onto the jagged basalt altar. **Tide-Stone #3 splits in two**, releasing a blinding white shockwave of trapped harmonic pressure.
  2. Above the crater, the **Black Halo** collapses inward like a punctured lung. Down in the Siphon Facility (`A22`), every transformer explodes in a shower of blue arcs; Vane's voice screams through the crater horns before dissolving into dead static forever.
  3. At the rim of the crater, **The Shepherd** stops mid-stride. He looks up at the clearing sky, drops to his knees, and lowers his bowed head—his 240-year compulsion finally going quiet as, far out at sea, the **Black Stone sinks back beneath the waves**.
  4. **Final Shot:** Grey dawn breaks over the island. You sit on the crater steps looking south. Far out past the point, the tiny yellow lamp of the **Captain's fishing boat** turns back toward the beach. You look down at your reflection in your cracked phone screen—alive, though a faint, dark ring now circles your pupils.

### Ending 2: "The New Shepherd" (Obey Vane / Forced Circuit)
- **Trigger:** Leave Siphon Console `ACTIVE` and **place Tide-Stone #3 into the empty socket** at the Summit (`A23`).
- **Cinematic Sequence:**
  1. You slide Tide-Stone #3 into the socket. All three stones blaze violet-black, and a roaring pillar of abyssal resonance shoots down the superconducting cables into the Siphon Facility.
  2. Over the loudspeakers, Julian Vane gasps in ecstasy: *"It's working! My hands—I can feel my hands inside the pod! The decay is reversing!"*
  3. Then the harmonic tone inverts into a sickening, discordant shriek. **The Cosmic Law takes effect:** *Taken by force, it corrupts.*
  4. Down in the Siphon Facility, the glass pod shatters outward. Over the PA, Vane's laughter turns into wet, choking horror as his jaw unhinges and black cartilage erupts through his spine—**mutating him into the new Shepherd**.
  5. Beside you at the crater rim, Captain Alistair Locke (the 1784 Shepherd) exhales a long breath of sea-mist and crumbles into empty naval cloth and salt—his replacement having been found.
  6. **Final Shot:** Because your hands completed the stolen circuit, the Black Halo descends over the circle. The last thing you see as the dark water closes over your vision is Vane's tall, twisted silhouette rising from the shattered dome below—while your voice joins the stolen chorus inside his throat.

### Ending 3: "Willing Communion" (Secret Cosmic Transcendence Ending)
- **Trigger:** Have the **Pale Shard**, listen to **Mara's Audio Log (`A20`)**, **sever Vane's Siphon Cables (`A22`)**, place Tide-Stone #3 in the socket, and **step into the center of the circle yourself with open hands**.
- **Cinematic Sequence:**
  1. With Vane's machine disconnected, you place Tide-Stone #3 into the socket and walk into the center of the ring, holding up the glowing **Pale Shard**.
  2. Vane rages impotently over the dying battery speakers: *"What are you doing?! You disconnected the pod! Without the filter, it will take your mind!"*
  3. Dr. Mara Chen's warm harmonic whisper surrounds you: *"Only what is given willingly."* You open your hands, offering your own memories and ego in exchange for your brother's life.
  4. The violent storm stops in an instant. The **Black Halo** above does not tear—it ripples like a calm tide pool, washing over you in warm, golden-white bioluminescence.
  5. **Final Shot:** Fade in from white to the **Beach (`A01`)** at sunrise. Lying on the dry sand beside the trail is **Sgt. Elias**—alive, breathing steadily, the black veins completely gone from his skin, as the fishing Captain's boat noses onto the shore to rescue him.
  6. You stand at the water's edge watching your brother wake up. You try to call his name, "Elias," but only a peaceful, resonant hum comes from your throat. Looking down at your hands, they are pale and translucent as sea-glass. Unafraid, you turn and walk calmly into the surf toward the sinking Black Stone, descending to join Mara and the **Deep Chorus** in the dreaming dark.
