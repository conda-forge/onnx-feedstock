@echo on
set "ONNX_ML=1"
set "CMAKE_BUILD_TYPE=Release"

REM Build only the ONNX C++ shared library (onnx.dll / onnx_proto.dll), its
REM headers and the ONNX CMake package. The Python bindings are built by
REM the separate onnx output. Patch 0003 (WINDOWS_EXPORT_ALL_SYMBOLS) makes
REM the DLLs export a usable import library.
cmake -G Ninja -S . -B build %CMAKE_ARGS% ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    -DBUILD_SHARED_LIBS=ON ^
    -DONNX_BUILD_PYTHON=OFF ^
    -DONNX_ML=1 ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DONNX_USE_PROTOBUF_SHARED_LIBS=ON ^
    -DProtobuf_USE_STATIC_LIBS=OFF ^
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON
if %ERRORLEVEL% neq 0 exit 1

cmake --build build
if %ERRORLEVEL% neq 0 exit 1

cmake --install build
if %ERRORLEVEL% neq 0 exit 1

REM Provide unversioned import libraries (onnx.lib / onnx_proto.lib) so
REM downstreams can link without the version suffix. Windows has no symlinks
REM for this, so copy them. They ship only in the single-version libonnx-dev
REM package; the versioned onnx-X.Y.dll (in the co-installable runtime) is what
REM keeps different ONNX versions from colliding on disk. The versioned import
REM library is discovered from the installed file (onnx-X.Y.lib) so it tracks
REM whatever version patch 0010 stamped in.
for %%F in ("%LIBRARY_PREFIX%\lib\onnx-*.lib") do copy /y "%%F" "%LIBRARY_PREFIX%\lib\onnx.lib"
if %ERRORLEVEL% neq 0 exit 1
for %%F in ("%LIBRARY_PREFIX%\lib\onnx_proto-*.lib") do copy /y "%%F" "%LIBRARY_PREFIX%\lib\onnx_proto.lib"
if %ERRORLEVEL% neq 0 exit 1
