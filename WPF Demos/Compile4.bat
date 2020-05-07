@echo off
:: Markus Scholtes, 2017
:: Compile WPF examples with .Net 4.x

set COMPILER=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe

if NOT EXIST "%COMPILER%" echo C#-Kompiler nicht gefunden&exit /b

"%COMPILER%" /target:winexe "%~dp001 Window.cs" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
"%COMPILER%" /target:winexe "%~dp002 Mouseclick.cs" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
"%COMPILER%" /target:winexe "%~dp003 Button.cs" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
"%COMPILER%" /target:winexe "%~dp004 Window Without XAML.cs" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
"%COMPILER%" /target:winexe "%~dp005 Bitmap Icon.cs" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
"%COMPILER%" /target:winexe "%~dp006 Clock.cs" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
"%COMPILER%" /target:winexe "%~dp007 InkCanvas.cs" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"%ProgramFiles%\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
pause