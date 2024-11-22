#!/bin/bash
set -euxo pipefail

# This will technically rebuild the onnx librayr too......
export ONNX_ML=1
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"

# Ensure that these options match those of the libonnx compilation
export CMAKE_ARGS="${CMAKE_ARGS} -DONNX_ML=${ONNX_ML}"
export CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_SHARED_LIBS=ON"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_USE_STATIC_LIBS=OFF"
export CMAKE_ARGS="${CMAKE_ARGS} -DUSE_PROTOBUF_SHARED_LIBS=ON"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=$PREFIX/lib/libprotobuf${SHLIB_EXT}"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_INCLUDE_DIR:PATH=${PREFIX}/include"
export CMAKE_ARGS="${CMAKE_ARGS} -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
export CMAKE_ARGS="${CMAKE_ARGS} -DPython_FIND_STRATEGY=LOCATION"

# See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
# Does not apply to osx-arm64 as its SDK is higher
if [[ "${target_platform}" == osx-64 ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

$PYTHON -m pip install --no-deps --ignore-installed --verbose .
