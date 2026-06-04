@echo on
set "ONNX_ML=1"
set "CMAKE_BUILD_TYPE=Release"

REM Build the ONNX Python package. The onnx_cpp2py_export extension links
REM the libonnx shared library (patch 0005) instead of recompiling ONNX.
set "CMAKE_ARGS=%CMAKE_ARGS% -DBUILD_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_PROTOBUF_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DProtobuf_USE_STATIC_LIBS=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_CXX_STANDARD=17"
REM Must match the namespace libonnx was built with so the extension resolves
REM its onnx_<ver>:: symbols at run time.
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_NAMESPACE=%ONNX_NAMESPACE%"
set "CMAKE_ARGS=%CMAKE_ARGS% -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION"
set "CMAKE_ARGS=%CMAKE_ARGS% -DPython_EXECUTABLE=%PYTHON%"
set "CMAKE_ARGS=%CMAKE_ARGS% -DFETCHCONTENT_FULLY_DISCONNECTED=ON"
set "USE_MSVC_STATIC_RUNTIME=0"

REM Only the Python package is installed; the C++ library, headers and
REM CMake package are shipped by the libonnx output.
%PYTHON% -m pip install --no-deps --ignore-installed --verbose .
if %ERRORLEVEL% neq 0 exit 1
