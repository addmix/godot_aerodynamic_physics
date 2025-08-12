@echo off
echo Compiling Windows 64bit double precision
scons platform=windows target=template_debug arch=x86_64 precision=double use_mingw=yes
pause