#!/bin/bash
set -euxo pipefail

# Copy over our python only cmake script
# it is mostly just the original cmake script with everything not
# related to python deleted
# cp ${RECIPE_DIR}/CMakeLists_python_only.txt CMakeLists.txt

# This will technically rebuild the onnx librayr too......
export ONNX_ML=1
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"

# Ensure that these options match those of the libonnx compilation
export CMAKE_ARGS="${CMAKE_ARGS} -DONNX_ML=${ONNX_ML}"
export CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_SHARED_LIBS=ON"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=$PREFIX/lib/libprotobuf${SHLIB_EXT}"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_INCLUDE_DIR:PATH=${PREFIX}/include"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"

$PYTHON -m pip install --no-deps --ignore-installed --verbose .
