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
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
export CMAKE_ARGS="${CMAKE_ARGS} -DPython_FIND_STRATEGY=LOCATION"

$PYTHON -m pip install --no-deps --ignore-installed --verbose .
