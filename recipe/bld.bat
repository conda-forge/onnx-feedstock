@echo on
set "ONNX_ML=1"
set CONDA_PREFIX=%LIBRARY_PREFIX%
set CMAKE_BUILD_TYPE=Release
%PYTHON% -m pip install --no-deps --ignore-installed --verbose .
