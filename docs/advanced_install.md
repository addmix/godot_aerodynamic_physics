# Advanced Installation

## Install using Git submodules (Preferred)
- Git submodules will only function if your project is a Git repository. Version control with Git is highly recommended.

- Using Git CLI:
1. Navigate to your project's repo in your command prompt/terminal of choice (i.e. `cd C:/Users/MyUsername/Documents/MyGodotProject`)
2. Add the plugin as a Git submodule: `git submodule add https://github.com/addmix/godot_aerodynamic_physics addons/godot_aerodynamic_physics`
    - Be sure that the supplied path (eg. `addons/godot_aerodynamic_physics`) is the correct path to your Godot project's addons folder.
    - Verify that the `plugin.gd` script is at `res://addons/godot_aerodynamic_physics/plugin.gd`
3. Enable plugin in project settings `Project > Project Settings > Plugins`
- The plugin can now be managed and version controlled through Git. I use the GitHub desktop app for convenience.

## Manual Install
1. Download release and un-zip files.
    - The folder structure of downloads may differ between source code and releases.
        - These folder structures are what is created by default when extracting on Windows. Linux may produce slightly different filepaths, due to omitting the root folder
    - Releases, after being extracted, will have this folder structure: 
    `godot_aerodynamic_physics-v0.8.0/addons/godot_aerodynamic_physics/plugin.gd`
    - Source code, after being extracted, will have this folder structure: 
    `godot_aerodynamic_physics-main/godot_aerodynamic_physics/plugin.gd`
3. Place the godot_aerodynamic_physics folder inside your project's `res://addons` folder.
    - Verify that the `plugin.gd` script is at `res://addons/godot_aerodynamic_physics/plugin.gd`
4. Enable plugin in project settings `Project > Project Settings > Plugins`