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
