@echo on
set "ONNX_ML=1"
set CMAKE_BUILD_TYPE=Release
:REM Build in parallel. scikit-build-core (the pip install below) and
:REM `cmake --build` both honor this, so neither step runs single-threaded.
set "CMAKE_BUILD_PARALLEL_LEVEL=%CPU_COUNT%"

:REM See discussion in https://github.com/conda-forge/onnx-feedstock/pull/113
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_PROTOBUF_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DProtobuf_USE_STATIC_LIBS=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_LITE_PROTO=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION"
set "CMAKE_ARGS=%CMAKE_ARGS% -DFETCHCONTENT_FULLY_DISCONNECTED=ON"
set USE_MSVC_STATIC_RUNTIME=0
%PYTHON% -m pip install --no-deps --ignore-installed --verbose .
if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%
