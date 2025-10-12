@echo off
echo.
echo Compiling godot-cpp
echo.

::compile godot-cpp
cd godot-cpp
scons platform=windows custom_api_file=../extension_api_double.json precision=double use_mingw=yes debug_symbols=yes
cd ..

echo.
echo Compiling Windows builds
echo.

::compile
echo Compiling Windows 64bit double precision
scons platform=windows target=template_debug arch=x86_64 precision=double use_mingw=yes debug_symbols=yes
::scons platform=windows target=template_release arch=x86_64 precision=double use_mingw=yes

echo Compiling Windows 32bit double precision
::scons platform=windows target=template_debug arch=x86_32 precision=double use_mingw=yes
::scons platform=windows target=template_release arch=x86_32 precision=double use_mingw=yes

::scons platform=linux precision=double
::scons platform=macos arch=x86_64 precision=double
pause