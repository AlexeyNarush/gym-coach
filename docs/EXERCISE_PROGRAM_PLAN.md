# Comprehensive exercise program plan

This document matches the **seed exercise library** and the app’s **Day A / B / C templates** (`WorkoutTemplateRepository`). It is written for general conditioning strength training, not sport-specific peaking.

## Design principles

1. **Movement patterns over muscle “days.”** Every session should cover the major patterns the app already encodes: horizontal push, vertical push, horizontal pull, vertical pull, squat, hip hinge, single-leg work, and some core (stability, flexion, or rotation). Isolation (curls, extensions, raises) is accessory volume, not the spine of the program.

2. **Intensity is learned, not guessed.** For the MVP, use **RPE 6–8** on compounds (you could finish 2–3 more good reps if needed), and **strict form** on machines and cables. Add load or reps only when the last set still feels like the target RPE.

3. **Frequency.** **3 non-consecutive days per week** (e.g. Mon / Wed / Fri) rotating A → B → C → A… If you can train **4 days**, repeat the weakest pattern day or add a light full-body “D” using the same exercise pool at lower volume.

4. **Warm-up and finishers.** Keep warm-ups **general and short** (2 movements, easy pace). Finishers are optional **low-skill** core or single-leg work; stop if technique degrades.

## Built-in weekly rotation (app templates)

| Day | Title (app) | Warm-up IDs | Main IDs | Finisher IDs |
|-----|-------------|-------------|----------|--------------|
| A | Push + Core | `bw_squat`, `plank` | `db_bench_press`, `machine_chest_press`, `db_shoulder_press`, `triceps_pushdown` | `dead_bug` |
| B | Pull + Legs | `glute_bridge`, `dead_bug` | `lat_pulldown`, `seated_cable_row`, `goblet_squat`, `db_rdl` | `walking_lunge` |
| C | Full Body Basics | `bw_squat`, `plank` | `bw_push_up`, `db_row`, `leg_press`, `db_curl` | `bike_crunch` |

**Pattern coverage across the week**

- **Horizontal push:** A (bench, machine press), C (`bw_push_up`).
- **Vertical push:** A (`db_shoulder_press`).
- **Vertical / horizontal pull:** B (`lat_pulldown`, `seated_cable_row`), C (`db_row`).
- **Squat / legs:** B (`goblet_squat`), C (`leg_press`), warm-ups (`bw_squat`).
- **Hinge:** B (`db_rdl`), warm-up (`glute_bridge`).
- **Arms / isolation:** A (`triceps_pushdown`), C (`db_curl`).
- **Core:** A/C warm-ups and finishers (`plank`, `dead_bug`, `bike_crunch`), B finisher (`walking_lunge` for single-leg pattern).

This is intentionally **simple and balanced** for a beginner-friendly MVP.

## Sets and reps (starting prescription)

Use **2–4 sets** per exercise depending on time. If an exercise is new, stay at **2–3 sets** for the first two weeks.

| Category | Reps | Rest | Notes |
|----------|------|------|--------|
| Compound push / pull / squat / hinge | 6–10 | 2–3 min | Add load when all sets are clean at top of range. |
| Machine / cable isolation | 10–15 | 90 s | Control the negative. |
| Core / single-leg finishers | 8–15 or timed | 60 s | Quality over speed. |

**Example first block (weeks 1–4):** 3×8 on main compounds, 2×12 on isolation and core. **Week 5+:** either add one set to one main lift per day, or move main compounds toward 4×6 with the same RPE cap.

## Progression rules

1. **Same exercise, same rep range:** when the **last set** is clearly below RPE 7, add **2.5–5 lb total** (or one smallest increment on machines) next session.
2. **Stall twice in a row** at the same load: drop **10%** and climb back with perfect reps, or swap to an **alternative** from the app (same pattern, different exercise).
3. **Joint-friendly days:** use the app’s alternative suggestions (e.g. `wall_push_up` / `incline_push_up` instead of `bw_push_up` when wrists or shoulders need relief).

## Deload (every 4–6 weeks or after poor sleep / travel)

- Cut **sets by ~40%** (e.g. 3×8 → 2×8) and keep loads **moderate** (RPE 6).
- Keep **all patterns** represented but skip optional finishers if fatigued.
- Return to normal volume for one week before pushing loads again.

## Equipment substitutions

The seed already encodes **alternatives** (equipment unavailable, joint-friendly). General rules:

- **No cable stack:** prefer dumbbell or machine options with the same pattern (row for pulldown, etc.).
- **No dumbbells:** use machine or bodyweight options listed as alternatives for that ID.
- **No bench:** favor standing or floor variations where available (`farmer_carry`, `walking_lunge`, etc.).

## Exercise illustrations in the app

Illustrations are **simple SVGs per movement pattern** (not photos of a single named exercise). That avoids misleading “wrong exercise” imagery while still cueing the **direction of force** and body shape. Paths: `assets/exercises/patterns/<movementPattern>.svg`.

## Quick reference: pattern → example exercises in seed

| Pattern | Example exercise IDs |
|---------|----------------------|
| `horizontal_push` | `bw_push_up`, `db_bench_press`, `machine_chest_press`, … |
| `vertical_pull` | `lat_pulldown`, `straight_arm_pulldown` |
| `horizontal_pull` | `seated_cable_row`, `db_row` |
| `squat` | `bw_squat`, `goblet_squat`, `leg_press` |
| `hip_hinge` | `db_rdl`, `glute_bridge`, `hip_thrust` |
| `vertical_push` | `db_shoulder_press`, `machine_shoulder_press` |
| `core_stability` | `plank`, `dead_bug`, `side_plank`, `bird_dog` |
| `core_flexion` | `bike_crunch` |
| `core_rotation` | `russian_twist` |
| `core_dynamic` | `mountain_climber` |
| `single_leg` | `walking_lunge`, `step_up` |
| `elbow_flexion` | `db_curl`, `hammer_curl` |
| `elbow_extension` | `triceps_pushdown`, `db_overhead_triceps` |
| `knee_extension` | `leg_extension` |
| `knee_flexion` | `lying_leg_curl` |
| `shoulder_raise` | `db_lateral_raise`, `db_front_raise` |
| `carry` | `farmer_carry` |
| `back_extension` | `superman_hold` |
| `squat_to_press` | `db_thruster` |

---

*This plan is meant to stay aligned with `SeedExerciseSource` and `WorkoutTemplateRepository` as those lists evolve; update the tables if template IDs change.*
