@echo off
rem Copy to the PARENT of chapter folders as environment.local.bat; edit once.
rem Alternatively set NETCODE_ENV to this file's custom location.
if not defined NETCODE_PYTHON set "NETCODE_PYTHON=D:\Tools\Python311\python.exe"
if not defined NETCODE_GODOT set "NETCODE_GODOT=D:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not defined NETCODE_GIT set "NETCODE_GIT=D:\Git\cmd\git.exe"
if not defined NETCODE_GITHUB set "NETCODE_GITHUB=D:\Tools\GitHubCLI\2.101.0\bin\gh.exe"
