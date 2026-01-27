# Getting Familiar with Aero Nodes.

- Full class reference is available within the Godot built-in docs.

    > Why do the docs sometimes refer to nodes as AeroInfluencers, instead of their specific type?
    - The AeroInfluencer3D class contains the core functionality for many features, including the input system, so it's usually clearer to reference the AeroInfluencer class as a whole, instead of a specific sub-class. The same applies to AeroSurface vs ManualAeroSurface3D. It's shorter and easier to read AeroSurface, and in most cases, the topic is relevant to all AeroSurfaces, not only ManualAeroSurfaces (there aren't any other types of AeroSurfaces at present).

# AeroBody3D

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

# AeroInfluencer3D

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

The following are all derivatives of the AeroInfluencer3D class:

## AeroSurface3D

The base class for wing-type AeroInfluencers, calculating some necessary values for wing area, angle of attack, sweep angle, etc. This class does not calculate any forces.

This class provides configuration for wing size through the AeroSurfaceConfig.

## ManualAeroSurface3D

This represents a wing or wing section. Lift, drag, and other properties are configured through the ManualAeroSurfaceConfig.

## AeroThruster3D

A simple force thruster with all of the AeroInfluencer3D and control system logic. Thrust magnitude is configured by the `max_thrust_force`.

## AeroJetThruster3D

An extension of the basic thruster that does calculates air mass acceleration to approximate a jet engine's thrust.

## AeroDragInfluencer3D

A simplified node that only creates drag, approximating a spherical shape.

## AeroMover3D

This class does calculations to ensure that all movements made are factored into velocity calculations. 

`disable_lift_dissymmetry` can be used to improve propeller classes when used on helicopters.

## AeroPropeller3D

Extends the AeroMover3D class with features to make it convenient to configure a multi-blade propeller.

## AeroCyclicPropeller3D

Extends the AeroPropeller3D class to provide cyclic control functionality. Used for main rotors of helicopters.

## AeroBuoyancy3D

The base class for AeroInfluencers that provide buoyant forces based on atmospheric density.

See: [Using Atmospheres](using_atmospheres.md)

## AeroBuoyancySphere3D

This calculates the buoyancy forces given the size of a sphere.

> Currently, this node applies buoyancy forces at the center of the sphere.

> Drag is not calculated by this node.

See: [Using Atmospheres](using_atmospheres.md)

## AeroBuoyancyMesh3D

This nodes calculates buoyancy, lift, and drag effects on a configured Mesh resource.

See: [Using Atmospheres](using_atmospheres.md)

# AeroAtmosphere3D

AeroAtmosphere3Ds allow customization of atmospheric properties within an Area3D.

By default, AeroAtmosphere3D nodes must be able to detect AeroBody3D nodes using physics layer 15. This is configurable in the project settings: `physics/aerodynamics/atmosphere_area_collision_layer`. Newly created AeroBodies will enable this layer by default. Ensure there are no conflicts with this layer.

See: [Using Atmospheres](using_atmospheres.md)

# AeroWaterAtmosphere3D

This node acts as a preset for AeroAtmosphere3D to make water easier to implement. It requires 1 or more CollisionShape3Ds to be configured to function.

For a simple water implementation, the waterline is set at this node's global y position.

For more detailed water, the `get_surface_height()` function should be overridden to match any wave displacement shader being used.

> Note: It is advised to make the AeroWaterAtmosphere3D's collision shape extend slightly beyond the expected water height. If an AeroBody3D exits the collision shape(s), atmosphere effects are no longer applied to that body.\

See: [Using Atmospheres](using_atmospheres.md)