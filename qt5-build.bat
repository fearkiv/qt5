@echo off

:check_args
if "%1"=="clone" goto clone
if "%1"=="compile" goto compile
if "%1"=="package" goto package
if "%1"=="clean" goto clean
echo Usage: %~n0 ^<clone^|compile^|clean^>
exit /b 1

:clone
::======================================================================
setlocal
set PATH=C:\Perl64\bin;C:\Python27\python.exe;%PATH%

:clone_check_perl
where perl >nul 2>&1 && perl --version|findstr "ActiveState" >nul 2>&1 && goto clone_check_git
echo There is no Perl in PATH (Perl from Cygwin won't do, use ActivePerl).
exit /b 1

:clone_check_git
where git >nul 2>&1 && goto clone_start
echo There is no Git in PATH.
exit /b 1

:clone_start
:: Clone upstream repo and submodules
call git clone https://github.com/qt/qt5.git
cd qt5
call git checkout 5.12.4 
perl init-repository --module-subset=default,-qtwebengine
:: Switch origin to our repos
call git remote set-url origin https://github.com/fearkiv/qt5.git
pushd qtbase
call git remote set-url origin https://github.com/fearkiv/qtbase.git
popd
:: Checkout to branch for in-house build
call git fetch origin 5.12.4-in-house
call git checkout 5.12.4-in-house
call git submodule update --recursive
exit /B 0
::======================================================================

:clean
::======================================================================
:clean_check_git
where git >nul 2>&1 && goto clean_start
echo There is no Git in PATH.
exit /b 1
:clean_start
pushd openssl
call git clean -ffdx -e %~nx0
call git submodule foreach "git clean -ffdx"
popd
exit /B %ERRORLEVEL%
::======================================================================

:compile
::======================================================================
setlocal
set PATH=C:\Perl64\bin;C:\Python27;C:\Qt\Tools\QtCreator\bin;%PATH%

:check_dev
if "%VisualStudioVersion%" GEQ "15" (
    set PREFIX=msvc2017
    goto check_perl
)
if "%VisualStudioVersion%" GEQ "14" (
    set PREFIX=msvc2015
    goto check_perl
)
echo You should run this from VS2015/VS2017 Developer Command Prompt window.
exit /b 1

:check_perl
where perl >nul 2>&1 && perl --version|findstr "ActiveState" >nul 2>&1 && goto compile_start
echo There is no Perl in PATH (Perl from Cygwin won't do, use ActivePerl).
exit /b 1

:compile_start
set OPENSSL_INC=D:\Sources\MDM\openssl-builds\%PREFIX%-release\include
set DEPLOY_PATH=D:\Sources\MDM\qt\%PREFIX%

echo.
echo OpenSSL include path: %OPENSSL_INC%
echo Binaries deploy path: %DEPLOY_PATH%
echo.

pushd qt5
if not exist qtbase\tools\configure\Makefile (
  call configure -prefix %DEPLOY_PATH% -developer-build -debug-and-release -force-debug-info -opensource -confirm-license -opengl dynamic -openssl -I %OPENSSL_INC% -ltcg -nomake examples -nomake tests -skip qtwebengine -mp -make-tool jom
  echo After that, run `jom install' to copy all the stuff to %DEPLOY_PATH%.
) else (
  echo Run `jom' to build Qt, then run `jom install' to copy all the stuff to %DEPLOY_PATH%.
)
exit /b 0
::======================================================================