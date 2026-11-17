# How DRAM Works — a six-part visual series

A short, self-contained explainer series about DRAM: what a bit physically is, why it leaks,
how the chip finds and reads it, what a read costs in time, how DDR moves data, and how the
pieces fit together on a module.

Everything is generated: the images are procedural point/line/triangle worlds rendered by
**Stateless Pointcloud World V11**, with typographic captions baked as overlay cards.
No stock footage, no 3D modelling, no animation software.

**Format:** 1920×1080, 60 fps, 4:2:0, H.264 · each episode 40–46 s · quiet ambient bed
· English on-screen explanations.

---

## Episodes

| # | Title | Runtime | What it explains |
|---|-------|---------|------------------|
| 01 | **The Leaky Bucket** | 0:46 | A DRAM bit is one transistor + one capacitor. Charge = 1, no charge = 0. The charge leaks away, so the bit must be refreshed. |
| 02 | **The Refresh Cycle** | 0:44 | The sense amplifier resolves a faint charge into a clean 1 or 0, and every row is read + rewritten every 64 ms — forever. |
| 03 | **Rows, Columns, Banks** | 0:40 | An address is a row and a column. The wordline opens a row, sense amps read the whole row in parallel, the column mux selects your bytes. |
| 04 | **The Read Transaction** | 0:44 | A read is a timed sequence: ACT → tRCD → RD → CL → data → PRE → tRP. Latency is dominated by opening and closing rows. |
| 05 | **Double Data Rate** | 0:42 | DDR transfers on both clock edges, reads a prefetch of 8 beats per access, and multiplies out to 5600 MT/s × 8 B = **44.8 GB/s** per channel. |
| 06 | **Inside a DIMM** | 0:44 | The module, the rank (8 chips ≈ 64-bit bus), the banks inside a chip, and the memory controller spreading addresses. |

The full series plays as one film in `deliverables/DRAM_Explained_Full_Series_1080p60.mp4`
(4.2 s title bumper + all six episodes, 4 min 24 s, ≈ 324 MB). Each episode is also available
standalone at roughly 45–60 MB, and `deliverables/VOICEOVER_SCRIPT.md` has a timed narration script
if you want to add a voice track.

---

## Files

```
generate_video.bat                              one click: rebuilds everything
tools/                                          build / render / assembly scripts
series/_content/                                episode scripts + caption card specs
series/_kit/                                    shared shaders, AngelScript kit, post chain
series/ep01…ep06/project/                       generated engine projects (git-ignored)

deliverables/
  DRAM_Explained_Full_Series_1080p60.mp4        the whole series, one file
  DRAM_Explained_Intro_1080p60.mp4              series title bumper (4.2 s)
  DRAM_Explained_EP01_The_Leaky_Bucket_1080p60.mp4
  DRAM_Explained_EP02_The_Refresh_Cycle_1080p60.mp4
  DRAM_Explained_EP03_Rows_Columns_Banks_1080p60.mp4
  DRAM_Explained_EP04_The_Read_Transaction_1080p60.mp4
  DRAM_Explained_EP05_Double_Data_Rate_1080p60.mp4
  DRAM_Explained_EP06_Inside_a_DIMM_1080p60.mp4
  README.md                                     this guide
  VOICEOVER_SCRIPT.md                           timed narration script, ready to record
  posters/                                      key frames + SERIES_CONTACT_SHEET.png
  thumbnails/                                   three alternate frames per episode
```

Every episode project is a complete, editable engine project (`scene.as`, `shaders/`, `post/`,
`lib/`, `textures/cards.png`). It is regenerated from `series/_content` + `series/_kit` on every
build, so edit the source there and rebuild rather than editing the project by hand.

---

## Regenerate everything

Double-click **`generate_video.bat`** (or run it from a terminal). It:

1. checks the engine / FFmpeg / Python + Pillow,
2. builds all six projects and their caption cards,
3. renders each episode with the engine's deterministic F9 path, minimized and unattended,
4. mixes the ambient bed, cuts posters and thumbnails,
5. concatenates the intro + episodes into the full series and writes the contact sheet.

Requirements: FFmpeg on `PATH`, Python 3 with Pillow, and the engine (auto-extracted from
`TheNewStatelessPointcloudEngine_V1_Runtime.zip` if the folder is missing).

```bat
generate_video.bat                       :: everything, final 1080p60 quality
generate_video.bat -Quick                :: fast 960x540 previews only (no deliverables)
generate_video.bat -Episodes ep03        :: just one episode, then rebuild deliverables
generate_video.bat -SkipAssemble         :: re-render episodes without re-cutting the series
```

Roughly 8–12 minutes for the whole series on a mid-range GPU. Individual steps are also
available: `tools\build_episode.ps1 -Episode ep03 -Mode final`, `tools\render.ps1 -ProjectDir
series\ep03`, `tools\assemble.ps1`. Previews are written to `series/<ep>/previews/`, so a `-Quick`
pass never overwrites the 1080p masters.

`generate_video.bat` runs the engine with its window minimized and never takes focus, so you can
keep using the machine while it renders.

---

## Version control

`.gitignore` keeps the repository to source only: **no videos, no rendered stills, no engine
runtime, no scratch files**. What is tracked:

- `series/_content` — one AngelScript scene + one caption spec per episode,
- `series/_kit` — the shared shader/AngelScript kit,
- `tools` — the generator scripts,
- `deliverables/README.md`, `deliverables/VOICEOVER_SCRIPT.md`,
- `generate_video.bat` and the engine zip.

Everything else is regenerated by the batch file into the same paths, so `git status` stays clean
after a run.

---

## How the visuals are made

- **Holographic slabs** — an instanced box layer (`box.vert/.frag`) with edge-glow shading, used for
  capacitors, transistors, packages and the DIMM board.
- **Glowing wire** — a screen-facing ribbon layer (`beam.vert/.frag`) that draws arbitrary 3D line
  segments with a soft core, halo and optional travelling pulse. Timing diagrams, wordlines,
  bitlines and brackets are all beams.
- **Arrays of cells** — a procedural point layer (`cells.vert/.frag`) with per-row charge decay and a
  refresh sweep driven entirely by time uniforms.
- **Charge / leakage** — volume particles (`spark.vert/.frag`) gated by a fill level, plus a liquid
  surface drawn as an emissive slab, so the "bucket" has a readable waterline.
- **Data in motion** — packet streams along arbitrary paths (`flow.vert/.frag`).
- **Typography** — captions are rendered to a 1920×1080-per-card atlas with Pillow (Segoe UI Light,
  Bahnschrift, Consolas), then composited by a full-screen overlay layer so every glyph lands on an
  exact pixel. Fades and a small rise are animated per beat.
- **Post chain** — sRGB path: bright pass → separable Gaussian bloom → filmic contrast, split-tone
  grade, vignette, chromatic aberration on the world only, film grain.

All motion is a pure function of time (`time = frame / fps`), so renders are deterministic and
reproducible frame-for-frame.

---

## Content notes

- The cell model is the standard **1T1C** DRAM cell. The visual "bucket" is a teaching metaphor for
  the storage capacitor; a real capacitor is a trench or stacked structure.
- Retention is on the order of tens of milliseconds at room temperature; the JEDEC refresh window is
  **64 ms** (8192 rows / 64 ms for a typical device, with tREFI = 3.9 µs).
- A DDR5 DIMM is split into two 32-bit sub-channels; episode 06 keeps the older "one 64-bit channel,
  8 chips" picture because it is the clearest way to explain a rank. DDR5-5600 = 5600 MT/s × 8 B =
  44.8 GB/s per 64-bit channel (89.6 GB/s per DIMM).
- Prefetch is 8n on DDR4/DDR5, so one column access fills 8 beats; 8 beats × 8 B = 64 B, exactly one
  cache line — which is why memory is read in 64-byte lines.
- Numbers in the episodes are illustrative but consistent with JEDEC DDR5-5600 timings
  (tRCD ≈ 14–16 ns, CL ≈ 14 ns, tRP ≈ 14 ns → roughly 60–80 ns loaded latency).

The audio is a slowly moving ambient drone generated from scratch (`tools/make_audio.py`), mixed
about 20 dB under speech level so the films can be re-voiced without remixing. The engine's silent
masters are kept in `series/epXX/project/renders/` if you prefer no music.
