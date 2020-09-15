set CMAKE_GENERATOR="Visual Studio 15 2017"
set PYTHON_EXECUTABLE=%PYTHON%
set PYTHON_LIBRARIES=%LIBRARY_LIB%
set CONDA_PREFIX=%LIBRARY_PREFIX%
set ROOT_DIR=%cd%
set PROTOBUF_INSTALL_DIR=%root_dir%\protobuf\install

# Install static protobuf 
# Default using the latest protobuf
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
cd cmake
cmake -Dprotobuf_MSVC_STATIC_RUNTIME=OFF -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=%PROTOBUF_INSTALL_DIR%
msbuild protobuf.sln /m /p:Configuration=Release
msbuild INSTALL.vcxproj /p:Configuration=Release
set "PATH=%PROTOBUF_INSTALL_DIR%\bin;%PATH%"
cd %ROOT_DIR%

set ONNX_ML=1
set CMAKE_BUILD_TYPE=Release
set CMAKE_ARGS="-DONNX_USE_PROTOBUF_SHARED_LIBS=OFF -DProtobuf_USE_STATIC_LIBS=ON -DONNX_USE_LITE_PROTO=ON"
set USE_MSVC_STATIC_RUNTIME=0
%PYTHON% -m pip install --no-deps --no-use-pep517 --ignore-installed --verbose .
