#!/bin/bash
set -euxo pipefail

export ONNX_ML=1
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"
export CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_SHARED_LIBS=ON -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DProtobuf_LIBRARY=$PREFIX/lib/libprotobuf${SHLIB_EXT} -DProtobuf_INCLUDE_DIR:PATH=${PREFIX}/include -DCMAKE_CXX_STANDARD=17 -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION"
$PYTHON -m pip install --no-deps --ignore-installed --verbose .
cmake --install .setuptools-cmake-build
