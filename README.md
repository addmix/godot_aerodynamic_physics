# Godot Aerodynamic Physics

## Usage
1. Enable plugin in project settings `project settings > plugins tab > enable`
2. Add an `AeroBody` to your scene, and add one or more `AeroSurface`s as children, adjust settings to change the characteristics.

## Development Direction
>Currently this plugin does not account for Reynolds number, nor Mach number, but it will (hopefully) be added soon.
1. KSP-style easy controls (in-progress)
2. User-defined substeps
3. Different Aero shapes (Sphere, Box, Cylinder, Plane)
4. Better stability: due to the nature of these equations, under certain conditions, the simulation can become unstable, and 'explode'. There is currently a naive `max_force` property to prevent this, but I would like to implement a better force limit.
