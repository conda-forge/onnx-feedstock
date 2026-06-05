@echo on
set "ONNX_ML=1"
set CMAKE_BUILD_TYPE=Release

:REM onnx 1.22 builds with scikit-build-core; it honours the CMAKE_ARGS
:REM environment variable, the same as the setuptools backend used to.

:REM On Windows we only build/install the Python package (the extension links
:REM onnx_core statically). BUILD_SHARED_LIBS stays OFF so no libonnx.dll is
:REM produced. See discussion in
:REM https://github.com/conda-forge/onnx-feedstock/pull/113
:REM set "CMAKE_ARGS=%CMAKE_ARGS% -DBUILD_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_PROTOBUF_SHARED_LIBS=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DProtobuf_USE_STATIC_LIBS=OFF"
set "CMAKE_ARGS=%CMAKE_ARGS% -DONNX_USE_LITE_PROTO=ON"
set "CMAKE_ARGS=%CMAKE_ARGS% -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION"
set "CMAKE_ARGS=%CMAKE_ARGS% -DFETCHCONTENT_FULLY_DISCONNECTED=ON"

:REM scikit-build-core writes Python_EXECUTABLE / Python_ROOT_DIR /
:REM Python_INCLUDE_DIR into its generated CMakeInit.txt with CACHE ... FORCE,
:REM but it cannot locate the Python import libraries on conda Windows
:REM (sysconfig LIBDIR is empty), so it leaves Python_LIBRARY /
:REM Python_SABI_LIBRARY unset and find_package(Python ... Development.Module
:REM Development.SABIModule) fails. Inject the two libraries into that same init
:REM cache via scikit-build-core's cmake.define (passing them through CMAKE_ARGS
:REM instead collides with the FORCE entries and corrupts version detection).
:REM The abi3 floor is CPython 3.12 (nanobind stable-ABI requirement), so the
:REM versioned lib is python312.lib; python3.lib is the stable-ABI import lib.
set USE_MSVC_STATIC_RUNTIME=0
%PYTHON% -m pip install --no-deps --ignore-installed --verbose . ^
  --config-settings=cmake.define.Python_LIBRARY=%PREFIX%\libs\python312.lib ^
  --config-settings=cmake.define.Python_SABI_LIBRARY=%PREFIX%\libs\python3.lib
if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%

:REM without the ability to use the shared libraries
:REM the onnx shared library is huge since it likely vendors protobuf
:REM so for windows we still can't build it
:REM cmake --install .setuptools-cmake-build
:REM if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%
