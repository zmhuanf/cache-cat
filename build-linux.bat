@echo off
rem Cross-compile Linux amd64 binaries into dist\cache_cat-linux-amd64
rem Default: optimized without LTO (fast). Arg "lto": CI-identical full LTO build.

setlocal
set "TARGET=x86_64-unknown-linux-musl"
set "OUT=dist\cache_cat-linux-amd64"
set "BINS=cache_cat cache_cat_ping"

where zig >nul 2>nul || goto no_zig
cargo zigbuild --version >nul 2>nul || cargo install cargo-zigbuild --locked || goto fail
rustup target list --installed | findstr /x /c:%TARGET% >nul || rustup target add %TARGET% || goto fail

if /i "%~1"=="lto" goto lto

echo [INFO] build %TARGET% optimized without LTO
set "CARGO_PROFILE_RELEASE_LTO=false"
set "CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16"
goto build

:lto
echo [INFO] build %TARGET% with full LTO
set "CARGO_PROFILE_RELEASE_LTO=true"
set "CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1"

:build
cargo zigbuild --release --target %TARGET% --bin cache_cat --bin cache_cat_ping || goto fail

if not exist "%OUT%" mkdir "%OUT%"
for %%B in (%BINS%) do (
    if exist "%OUT%\%%B" echo [WARN] overwrite %OUT%\%%B
    copy /y "target\%TARGET%\release\%%B" "%OUT%\" >nul || goto fail
)

echo [INFO] output: %OUT%
dir /b "%OUT%"
endlocal
exit /b 0

:no_zig
echo [ERROR] zig not found in PATH
exit /b 1

:fail
echo [ERROR] build failed
exit /b 1
