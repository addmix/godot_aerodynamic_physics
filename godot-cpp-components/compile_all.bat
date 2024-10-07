@echo off
echo.
echo Compiling godot-cpp
echo.

::compile godot-cpp
cd godot-cpp
scons platform=windows custom_api_file=../extension_api.json
cd ..

echo.
echo Compiling Windows builds
echo.

::compile
echo Compiling Windows 64bit
scons platform=windows target=template_debug arch=x86_64
scons platform=windows target=template_release arch=x86_64

echo Compiling Windows 32bit
scons platform=windows target=template_debug arch=x86_32
scons platform=windows target=template_release arch=x86_32

::scons platform=linux
::scons platform=macos arch=x86_64
pause