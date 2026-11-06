# Advanced Installation

## Install using Git submodules (requires compiling)
- Git submodules will only function if your project is a Git repository. Version control with Git is highly recommended.
- Compiled binaries are gitignored, so a submodule is source code only. You will need to set up the compiling tools from [Compiling](compiling.md) before the plugin will load.

1. Navigate to your project's repo in your command prompt/terminal of choice (i.e. `cd C:/Users/MyUsername/Documents/MyGodotProject`)
2. Add the plugin as a Git submodule: `git submodule add https://github.com/addmix/godot_aerodynamic_physics addons/godot_aerodynamic_physics`
    - Be sure that the supplied path (eg. `addons/godot_aerodynamic_physics`) is the correct path to your Godot project's addons folder.
3. Fetch the nested `godot-cpp` submodule: `git submodule update --init --recursive`
4. Compile the plugin, following [Compiling](compiling.md)
    - Compile with the same precision as your Godot editor, a single-precision build will not load into double-precision Godot (or the reverse)
    - Every machine that clones your project needs to compile once, the binaries are not committed
5. Verify the plugin files:
    - The `.gdextension` file is at `res://addons/godot_aerodynamic_physics/godot_aerodynamic_physics.gdextension`
    - The `plugin.gd` script is at `res://addons/godot_aerodynamic_physics/plugin.gd`
    - Your compiled library is in `res://addons/godot_aerodynamic_physics/bin/<platform>/`
6. Enable plugin in project settings `Project > Project Settings > Plugins`
- The plugin can now be managed and version controlled through Git. I use the GitHub desktop app for convenience.

## Manual Install
1. Download release and un-zip files.
    - Release downloads include the compiled binaries, so no compiling is necessary.
    - Releases, after being extracted, will have this folder structure:
    `godot_aerodynamic_physics-v0.10.0/addons/godot_aerodynamic_physics/godot_aerodynamic_physics.gdextension`
    - Source code archives do not include the `godot-cpp` submodule, so they cannot be compiled as-is. See [Compiling](compiling.md) if you want to build from source.
2. Place the godot_aerodynamic_physics folder inside your project's `res://addons` folder.
    - Verify that the `plugin.gd` script is at `res://addons/godot_aerodynamic_physics/plugin.gd`
    - Verify that `res://addons/godot_aerodynamic_physics/bin/<platform>/` has a library matching your Godot build, the `.double` files are for double-precision Godot
    - Only the folders in `bin/` for your target platforms are needed, the rest can be deleted to keep your project small
3. Enable plugin in project settings `Project > Project Settings > Plugins`

## The plugin doesn't load
- Check the Output panel, the extension reports a failed load with `Extension failed to load`.
- Godot needs to be 4.5 or newer, the `.gdextension` sets `compatibility_minimum = 4.5`.
- The path in the `.gdextension` must match the file in `bin/<platform>/`. Missing or misnamed binaries will fail to load.
- The precision and build type must match. Double-precision Godot only loads `.double` binaries, exported projects only load `template_release` binaries.
- If you are working on a custom/modified build of Godot, you will need an extension API that matches your build. See the Extension API section of [Compiling](compiling.md).
