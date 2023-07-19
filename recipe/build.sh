#!/bin/bash

set -euxo pipefail

# Let us set the C++ Standard
sed -i '/CMAKE_CXX_STANDARD/d' CMakeLists.txt

export ONNX_ML=1
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"
export CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_SHARED_LIBS=ON -DONNX_USE_LITE_PROTO=ON -DONNX_USE_PROTOBUF_SHARED_LIBS=OFF -DProtobuf_USE_STATIC_LIBS=ON -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DProtobuf_LIBRARY=$PREFIX/lib/libprotobuf.a -DCMAKE_CXX_STANDARD=17"
$PYTHON -m pip install --no-deps --ignore-installed --verbose .
cmake --install .setuptools-cmake-build
