@echo on
sed -i '/CMAKE_CXX_STANDARD/d' CMakeLists.txt
if %ERRORLEVEL% neq 0 exit 1

REM Copy over our python only cmake script
REM it is mostly just the original cmake script with everything not
REM related to python deleted
REM I can't get this to work, so technically we will be building the same package multiple times
REM copy %RECIPE_DIR%\CMakeLists_python_only.txt CMakeLists.txt

set "ONNX_ML=1"
set CONDA_PREFIX=%LIBRARY_PREFIX%
set CMAKE_BUILD_TYPE=Release

set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_ML=1"
set "CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_CXX_STANDARD=17"
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_PROTOBUF_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DProtobuf_USE_STATIC_LIBS=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DDONNX_USE_LITE_PROTO=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DUSE_MSVC_STATIC_RUNTIME=0"

set "PYTHON_EXECUTABLE=%PYTHON%"
set "PYTHON_LIBRARIES=%LIBRARY_LIB%"
set USE_MSVC_STATIC_RUNTIME=0
%PYTHON% -m pip install --no-deps --no-use-pep517 --ignore-installed --verbose .
%PYTHON% -m pip install --no-deps --ignore-installed --verbose .
