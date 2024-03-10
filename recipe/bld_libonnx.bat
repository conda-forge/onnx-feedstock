@echo on
mkdir build
cd build

cmake %CMAKE_ARGS% ^
    -DONNX_ML=1 ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DBUILD_SHARED_LIBS=OFF ^
    -DONNX_USE_PROTOBUF_SHARED_LIBS=ON ^
    -DProtobuf_USE_STATIC_LIBS=OFF ^
    -DUSE_MSVC_STATIC_RUNTIME=0 ^
    ..
if %ERRORLEVEL% neq 0 (type CMakeError.log && exit 1)

cmake --build . --target install --config Release
if %ERRORLEVEL% neq 0 (type CMakeError.log && exit 1)
