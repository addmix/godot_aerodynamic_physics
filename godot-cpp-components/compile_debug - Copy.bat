@echo off
echo.
echo Compiling godot-cpp
echo.

::compile godot-cpp
cd godot-cpp
::scons platform=windows
cd ..

echo.
echo Compiling Windows 64bit
echo.

scons platform=windows target=template_debug arch=x86_64 precision=double use_mingw=yes
pause