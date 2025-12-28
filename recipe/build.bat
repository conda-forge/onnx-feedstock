@echo on
set "ONNX_ML=1"
set CMAKE_BUILD_TYPE=Release

:REM See discussion in https://github.com/conda-forge/onnx-feedstock/pull/113
:REM set "CMAKE_ARGS=%CMAKE_ARGS% -DBUILD_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_PROTOBUF_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DProtobuf_USE_STATIC_LIBS=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_LITE_PROTO=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION"
set "CAMKE_ARGS=%CMAKE_ARGS% -DPython_EXECTUABLE=%PYTHON%"
set USE_MSVC_STATIC_RUNTIME=0
%PYTHON% -m pip install --no-deps --ignore-installed --verbose .
if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%

:REM without the ability to use the shared libraries
:REM the onnx shared library is huge since it likely vendors protobuf
:REM so for windows we still can't build it
:REM cmake --install .setuptools-cmake-build
:REM if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%
