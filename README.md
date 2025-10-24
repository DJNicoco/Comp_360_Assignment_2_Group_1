# COMP 360 – Assignment 2  

**Project:** Interactive Driving Simulation  
**Course:** COMP 360 ON1 | Fall 2025  
**Due Date:** Oct 30, 2025  

---

## Overview
Our group created an interactive driving simulation in **Godot 4**.  
The road is generated using a spline + space-filling curve, placed above our Assignment 1 landscape.  
Players can drive the camera (or visible car) along the path, experience environmental effects, and view UI feedback such as timer and speed.

---

## Team Roles and Contributions 

| **Member** | **Main Responsibility** | **Files / Scenes Worked On** |
|-------------|------------------------|------------------------------|
| Bilal  | Track Curve / Spline Generator | `3DRoad.tscn` |
| Nicole | Road Mesh & Collision Builder | `RoadBuilder.gd`, `Road.tscn`, `Main.tscn`, `camera_3d.gd`, `textures` |
| Unnati | Vehicle / Camera Controls + Easing of Movement | `CameraCar.gd`, `CarController.gd`, `InputMap`(godot setting) |
| Easton | World Integration + Terrain Import | `3dLandscape.tscn`, `World.tscn` |
| Bao | UI & Game Flow Logic | `HUD.tscn`, `HUD.gd`, `GameFlow.gd` |
| Michael | AI Car & Ramps Feauture | `AICar.gd`, `AICar.tscn`, `Ramp.gd`, `Ramp.tscn` |
| Jasmine | Weather  | `WeatherController.gd`, `WeatherController.tscn` |

---

## Team Workflow

Each member worked in their own godot software and sent the scripts and scenes to Nicole (Road Mesh & Collision Builder). She maintained the main repository and integrated all individual .tscn scenes and scripts into the main project.
This ensured consistent folder structure and correct scene linking inside Main.tscn.

---

## Core Features 
- **Spline-based Road:** Hilbert-style space-filling curve segment hovering above terrain.  
- **Camera Driving:** Smooth acceleration and look-ahead motion with easing functions.  
- **AI Opponent:** Secondary car moves via `PathFollow3D`.  
- **Gates & Timer Bonus:** Adds extra time on trigger.  
- **Weather System:** Rain, dust, and smoke simulated with particle effects.
- **HUD:** Displays timer, speed, and lap count

