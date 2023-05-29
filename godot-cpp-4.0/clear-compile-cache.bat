echo off
echo To not waste people's time accidentally clicking on this and recompiling the GDExtension, I set up a yes or no question.
set attempt_left=3
:start
set /p run=Run? [y/n]
if /i "%run%" EQU "n" exit
if /i not "%run%" EQU "y" set /a attempt_left-=1
echo You got %attempt_left% attempt left.
if /i "%attempt_left%" EQU "-1" exit
goto start

for /r %%f in (*.lib) do del "%%f"
for /r %%f in (*.obj) do del "%%f"
for /r %%f in (*.exp) do del "%%f"
for /r %%f in (*.dll) do del "%%f"
for /r %%f in (*.dblite) do del "%%f"
for /r %%f in (*.pyc) do del "%%f"
rmdir /S /Q gen & ^
pause
