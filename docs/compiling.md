# Compiling

## Prerequisites

Compiling the plugin requires the same tools and setup as [compiling Godot](https://docs.godotengine.org/en/stable/engine_details/development/compiling/index.html).

- C++ compiler
- Python 3.9+
- SCons 4.4+

Please follow Godot's [compiling guide](https://docs.godotengine.org/en/stable/engine_details/development/compiling/index.html) before continuing.

## Getting the Source

```sh
git clone --recurse-submodules https://github.com/addmix/godot_aerodynamic_physics.git
```

## Compiling via VS Code

VS Code is the quickest/easiest way to compile the plugin.

For the VS Code compiling setup to work, some configuration of `.vscode/settings.json` is needed:

Examples are provided, but adjustments will be necessary for your development environment.
- Uncomment the shell for your environment (Linux or Windows)
- Edit the filepath to point to your Godot editor binary
- Uncomment the Linux/Windows scons build command lines, and comment out the `distrobox` lines. (My environment requires me to use Distrobox, I'm sorry)

The plugin can be automatically compiled and the Godot editor/project launched using the `editor` or `project` launch options.

## Compiling Manually

The plugin can be compiled with the following command:
```sh
cd godot-cpp-components
scons custom_api_file=extension_api.json build_profile=build_profile.json
```

The compiled plugin binary will be placed in the plugin's `bin/` folder, ready to use.

## Double Precision / Large World Coordinates (recommended)

> See: [Large World Coordinates in Godot](https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html)

Due to the nature of aircraft, a double-precision build of Godot and the plugin are recommended. Compiling for double-precision is easy, with only slight modifications to the compile commands:

```sh
# Compile the plugin with double precision
cd godot-cpp-components
scons precision=double custom_api_file=extension_api_double.json build_profile=build_profile.json
```

If you are compiling via the VS Code tasks, double-precision versions of the compile/launch tasks are provided.

- Ensure that you have a double-precision editor build (you will need to compile Godot from source, as Godot doesn't ship double-precision binaries)

## Advanced

### Extension API

If you have a custom/modified build of Godot, you may need to generate Extension API files to match your build.

The API can be dumped from the editor using this command:
```sh
godot --headless --dump-extension-api
```

The output file will be named `extension_api.json`. Move this file into the `godot-cpp-components` folder to replace the existing API.
Rename the dumped file to `extension_api_double.json` if it was dumped from an editor that was compiled with `precision=double`.

There are two VS Code tasks for this, `extension-api (single)` and `extension-api (double)`, which use the corresponding `gap.godotEditorSingleBin` or `gap.godotEditorDoubleBin` binary paths. The filename is changed accordingly, and will be automatically placed in the `godot-cpp-components` folder.
