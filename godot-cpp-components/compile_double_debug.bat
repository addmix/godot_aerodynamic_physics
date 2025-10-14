@echo off

echo.
echo Compiling godot-cpp
echo.

cd godot-cpp
::scons platform=windows precision=double debug_symbols=yes dev_build=yes custom_api_file=../extension_api_double.json build_profile=../build_profile.json
cd ..



echo Compiling Windows 64bit double precision
scons target=template_debug arch=x86_64 platform=windows precision=double debug_symbols=yes dev_build=yes custom_api_file=extension_api_double.json build_profile=build_profile.json
::pause