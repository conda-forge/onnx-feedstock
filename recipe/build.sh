#!/bin/bash
set -euxo pipefail

export ONNX_ML=1
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"
export CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_SHARED_LIBS=ON -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DProtobuf_LIBRARY=$PREFIX/lib/libprotobuf${SHLIB_EXT} -DProtobuf_INCLUDE_DIR:PATH=${PREFIX}/include -DCMAKE_CXX_STANDARD=17 -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION -DPYBIND11_FINDPYTHON=ON -DPython_EXECUTABLE=$PYTHON"

# Ensure pybind11 is searched before we run find_package(Python)
sed -i '0,/cmake_policy(SET CMP0063 NEW)/a find_package(pybind11 REQUIRED)' CMakeLists.txt


# See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
# Does not apply to osx-arm64 as its SDK is higher
if [[ "${target_platform}" == osx-64 ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi
$PYTHON -m pip install --no-deps --ignore-installed --verbose .
cmake --install .setuptools-cmake-build
