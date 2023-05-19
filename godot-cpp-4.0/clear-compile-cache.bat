for /r %%f in (*.lib) do del "%%f"
for /r %%f in (*.obj) do del "%%f"
for /r %%f in (*.exp) do del "%%f"
for /r %%f in (*.dll) do del "%%f"
for /r %%f in (*.dblite) do del "%%f"
for /r %%f in (*.pyc) do del "%%f"
rmdir /S /Q gen & ^
pause
