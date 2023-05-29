echo You must quit the Godot by Ctrl+Shift+Q to stop Godot from locking the dll.
mkdir bin
cd game-lib && ^

del bin\libcosmic.windows.template_debug.x86_64.dll && ^
scons target=template_debug && ^
copy bin\libcosmic.windows.template_debug.x86_64.dll ..\..\project\bin && ^

del bin\libcosmic.windows.template_release.x86_64.dll
REM del bin\libcosmic.windows.template_release.x86_64.dll && ^
REM scons target=template_release && ^
REM copy bin\libcosmic.windows.template_release.x86_64.dll ..\..\project\bin
