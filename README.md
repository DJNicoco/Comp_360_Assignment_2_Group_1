**Project:** Interactive Driving Simulation  
**Course:** COMP 360 ON1 | Fall 2025  
**Due Date:** Oct 30, 2025  

---

## Overview

Our group created an **interactive driving simulation in Godot 4**, combining multiple gameplay and visual systems into one cohesive scene.
The **road** is procedurally generated using a **spline + space-filling curve**, positioned above our **Assignment 1 terrain landscape**.
Players can **drive a vehicle or follow with a smooth camera**, navigate the track, and interact with the environment through:

- Dynamic weather effects (rain and snow),
- Ramps and an AI-driven car opponent,
- Start/Finish triggers that control laps and timing, and
- A responsive HUD that displays the timer, speed, and lap progress.

All features are integrated into MainWorld.tscn, which serves as the final root scene, replacing the old Main.tscn.

---

## Team Roles and Contributions 

| **Member** | **Main Responsibility** | **Files / Scenes Worked On** |
|-------------|------------------------|------------------------------|
| Bilal  | Track Curve / Spline Generator | `Test3DRoad.tscn`, `Test3DRoad_2.tscn`  |
| Nicole | Road Mesh & Collision Builder | `TestRoadBuilder.tscn`, `TestRoadBuilder.gd`, `test_camera_3d.gd`,  `weather_tile.tscn`, `MainWorld.tscn`, scene linking, version cleanup |
| Unnati | Vehicle / Camera Controls + Easing of Movement | `TestCameraCar.gd`|
| Easton | Terrain Integration | `3dLandscape.tscn` |
| Bao | UI & Game Flow Logic | `hud.tscn`, `hud.gd`, `GameFlow.gd`, `StartTrigger.tscn`, `FinishTrigger.tscn` |
| Michael | AI Car & Ramps Feauture | `old_car.gd`, `Ramp.tscn`, `NewCarScript.gd`, `TestVehicleCamera.gd`, `test_vehicle_body_3d.gd` |
| Jasmine | Weather  | `weather_controller.gd`, `weather_controller.tscn` |

---

## Team Workflow

Each member worked independently in Godot and shared their scenes and scripts with Nicole, who maintained the main repository.
She integrated all .tscn and .gd files into the final project, ensuring a consistent folder structure and correct scene linking inside MainWorld.tscn.

---

### Project Refactor & Version Control Cleanup

During final integration, duplicate and legacy scenes (Main.tscn, TestWorld.tscn, old road and car files) were removed.
All systems — car, road, ramps, weather, HUD, AI, and triggers — were consolidated under MainWorld.tscn for clarity and stability.
A nested Git repository was also removed to prevent version control conflicts, ensuring a single clean repo for grading and future development.

---

## Core Features 

### Procedural Road System: <br>
Built using `RoadBuilder.gd` and a spline (`Track Path3D`) to generate a smooth, collision-ready mesh.

### Dynamic Terrain Integration: <br>
Terrain positioned beneath the track with adjustable elevation for visual realism.

### Camera System: <br>
Third-person chase camera providing smooth follow and look-ahead movement.

### HUD & Game Flow: <br>
Displays time, speed, and laps; race logic handles countdown, lap tracking, and finish detection.

### Dynamic Weather System (Updated) <br>
Managed by `WeatherController.gd`, featuring rain and snow that follow the player and align with the road surface.

### AI Car & Ramps: <br>
Adds an AI-controlled vehicle and interactive ramps for dynamic driving behavior.

### Start / Finish Triggers: <br>
Detect lap progression and control race start, lap count, and finish timing.

---

## Limitations & Future Improvements

- **Weather System:** The tile-based weather coverage (`weather_tile.tscn`) and dynamic follow logic were only partially implemented. Rain and snow remained static near the track center instead of following the player, and full-track coverage still requires optimization for performance.
- **Car:** The vehicle moves and interacts with ramps, but pathfinding and overtaking behaviors need refinement for smoother racing.  
- **Camera Tuning:** The third-person camera occasionally clips through ramps or terrain at high speeds and could benefit from collision-based repositioning.  
- **HUD Timer:** The HUD does not automatically start when the car begins moving; the race timer must be triggered manually. <br>
- **Physics Balancing:** Suspension and traction parameters need further tuning to prevent sliding during sharp turns.  

