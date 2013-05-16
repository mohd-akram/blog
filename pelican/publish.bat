@echo off

rmdir /s /q ..\2013
rmdir /s /q ..\author
rmdir /s /q ..\category
rmdir /s /q ..\feeds
rmdir /s /q ..\tag
rmdir /s /q ..\theme

del "..\archives.html"
del "..\categories.html"
del "..\index.html"
del "..\tags.html"

@echo on

pelican -s publishconf.py -o ..\