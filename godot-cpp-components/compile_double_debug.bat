@echo off

echo.
echo Compiling godot-cpp
echo.

cd godot-cpp
scons platform=windows precision=double use_mingw=yes debug_symbols=yes custom_api_file=../extension_api_double.json
cd ..



echo Compiling Windows 64bit double precision
scons platform=windows target=template_debug arch=x86_64 precision=double use_mingw=yes debug_symbols=yes
pause