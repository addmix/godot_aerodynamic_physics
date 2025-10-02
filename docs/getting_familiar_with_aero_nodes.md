# Getting Familiar with Aero Nodes.

- Full class reference is available within the Godot built-in docs.

    > Why do the docs sometimes refer to nodes as AeroInfluencers, instead of their specific type?
    - The AeroInfluencer3D class contains the core functionality for many features, including the input system, so it's usually clearer to reference the AeroInfluencer class as a whole, instead of a specific sub-class. The same applies to AeroSurface vs ManualAeroSurface3D. It's shorter and easier to read AeroSurface, and in most cases, the topic is relevant to all AeroSurfaces, not only ManualAeroSurfaces (there aren't any other types of AeroSurfaces at present).

## AeroBody3D

The root node for bodies with simulated aerodynamics
AeroBody3D is the base node for simulating aerodynamic forces.
Aerodynamic forces are calculated using child `AeroInfluencer3D` nodes.

Steps to retain all functionality when extending this script:
1. Add `@tool` to the top of the script.
    - This allows the script to run in the editor, so that the debug vectors can update.
2. call `super()` when extending functions.

examples:
```swift
func _enter_tree():
    super()
    (...)
func _ready():
    super()
    (...)
func _physics_process(delta):
    super(delta)
    (...)
```

## AeroInfluencer3D

Base class for all aerodynamic nodes.

This class does not directly apply any forces to a body, requiring an `AeroBody3D` parent to 
manage the simulation.

`AeroInfluencer3D`s can also be arranged hierarchically, as long as they have a single 
`AeroBody3D` as an ancestor node, and all other ancestors are `AeroInfluencer3D`s.

Example node hierarchy:
```
v AeroBody3D
| v ManualAeroSurface3D
| | > ManualAeroSurface3D
| | # this node works, because it has an an ancestor AeroBody3D, and all other ancestor nodes
| | # are AerInfluencer3D derived classes
```

## AeroSurface3D

The base class for wing-type AeroInfluencers, calculating some necessary values for wing area, angle of attack, sweep angle, etc. This class does not calculate any forces.

This class provides configuration for wing size through the AeroSurfaceConfig.

## ManualAeroSurface3D

This represents a wing or wing section. Lift, drag, and other properties are configured through the ManualAeroSurfaceConfig.

## AeroThruster3D

A simple force thruster with all of the AeroInfluencer3D and control system logic. Thrust magnitude is configured by the `max_thrust_force`.

## AeroJetThruster3D

An extension of the basic thruster that does calculates air mass acceleration to approximate a jet engine's thrust.

## AeroMover3D

This class does calculations to ensure that all movements made are factored into velocity calculations. 

`disable_lift_dissymmetry` can be used to improve propeller classes when used on helicopters.

## AeroPropeller3D

Extends the AeroMover3D class with features to make it convenient to configure a multi-blade propeller.

## AeroCyclicPropeller3D

Extends the AeroPropeller3D class to provide cyclic control functionality. Used for main rotors of helicopters.