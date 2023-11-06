mkdir build
cd build

cmake %CMAKE_ARGS% ^
    -DCMAKE_CXX_STANDARD=17 ^
    -DBUILD_SHARED_LIBS=ON ^
    -DONNX_USE_PROTOBUF_SHARED_LIBS=ON ^
    -DProtobuf_USE_STATIC_LIBS=OFF ^
    -DDONNX_USE_LITE_PROTO=ON ^
    -DCMAKE_CXX_FLAGS="/DPROTOBUF_USE_DLLS=1 /EHsc /std:c++17" ^
    ..
if %ERRORLEVEL% neq 0 (type CMakeError.log && exit 1)

cmake --build . --target install --config Release
if %ERRORLEVEL% neq 0 exit 1
