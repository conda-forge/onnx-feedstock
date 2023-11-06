@echo on
mkdir build
cd build

set CONDA_PREFIX=%LIBRARY_PREFIX%
cmake %CMAKE_ARGS% ^
    -DONNX_ML=1 ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DONNX_USE_PROTOBUF_SHARED_LIBS=ON ^
    -DProtobuf_USE_STATIC_LIBS=OFF ^
    -DONNX_USE_LITE_PROTO=ON ^
    -DCMAKE_CXX_FLAGS="/DPROTOBUF_USE_DLLS=1 /EHsc /std:c++17" ^
    -DUSE_MSVC_STATIC_RUNTIME=0 ^
    -DBUILD_SHARED_LIBS=ON ^
    ..
if %ERRORLEVEL% neq 0 (type CMakeError.log && exit 1)

cmake --build . --target install --config Release
if %ERRORLEVEL% neq 0 exit 1
