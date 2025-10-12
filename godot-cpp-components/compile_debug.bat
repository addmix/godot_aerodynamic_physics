@echo off
echo.
echo Compiling godot-cpp
echo.

::compile godot-cpp
cd godot-cpp
scons platform=windows debug_symbols=yes
cd ..

echo.
echo Compiling Windows 64bit
echo.

scons platform=windows target=template_debug arch=x86_64 use_mingw=yes debug_symbols=yes
pause