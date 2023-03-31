  
set "ONNX_ML=1"
set CONDA_PREFIX=%LIBRARY_PREFIX%
set CMAKE_BUILD_TYPE=Release
set "CMAKE_ARGS=-DBUILD_SHARED_LIBS=ON -DONNX_USE_LITE_PROTO=ON"
set "PYTHON_EXECUTABLE=%PYTHON%"
set "PYTHON_LIBRARIES=%LIBRARY_LIB%"
set USE_MSVC_STATIC_RUNTIME=0
%PYTHON% -m pip install --no-deps --no-use-pep517 --ignore-installed --verbose .
cmake --install .setuptools-cmake-build
