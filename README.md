# COMP 360 – Assignment 2  

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

All features are integrated into one main scene (Main.tscn), where the terrain, track, road mesh/collision, weather, camera, and UI work together to simulate a complete driving experience.

---

## Team Roles and Contributions 

| **Member** | **Main Responsibility** | **Files / Scenes Worked On** |
|-------------|------------------------|------------------------------|
| Bilal  | Track Curve / Spline Generator | `3DRoad.tscn` |
| Nicole | Road Mesh & Collision Builder | `RoadBuilder.gd`, `Road.tscn`, `Main.tscn`, `camera_3d.gd`, `textures` |
| Unnati | Vehicle / Camera Controls + Easing of Movement | `CameraCar.gd`, `CarController.gd`|
| Easton | Terrain Integration | `3dLandscape.tscn` |
| Bao | UI & Game Flow Logic | `HUD.tscn`, `HUD.gd`, `GameFlow.gd`, `StartTrigger.tscn`, `FinishTrigger.tscn` |
| Michael | AI Car & Ramps Feauture | `AICar.gd`, `AICar.tscn`, `Ramp.gd`, `Ramp.tscn` |
| Jasmine | Weather  | `WeatherController.gd`, `WeatherController.tscn` |

---

## Team Workflow

Each member worked in their own godot software and sent the scripts and scenes to Nicole (Road Mesh & Collision Builder). She maintained the main repository and integrated all individual .tscn scenes and .gd scripts into the main project.
This ensured consistent folder structure and correct scene linking inside Main.tscn.

---

## Core Features 

**Procedural Road System:** <br>
Built using RoadBuilder.gd and a spline (Track Path3D) to generate a smooth, collision-ready mesh.

**Dynamic Terrain Integration:** <br>
Terrain imported and positioned beneath the road; adjustable elevation for visual realism.

**Camera System:** <br>
Third-person chase camera (camera_3d.gd) with smooth follow and look-ahead functionality.

**HUD & Game Flow:** <br>
On-screen interface (HUD.tscn + hud.gd) displays time, speed, and laps.
Race logic handled by GameFlow.gd — includes countdown, lap tracking, and finish detection.

**Weather Effects:** <br>
Managed by WeatherController.gd, featuring toggleable rain and snow particle systems.

**AI Car & Ramps:** <br>
Implemented through AICar.gd and Ramp.gd — adds an AI-controlled vehicle and ramps for interaction.

**Start / Finish Triggers:** <br>
StartTrigger.tscn and FinishTrigger.tscn detect lap progression and control race state transitions.

