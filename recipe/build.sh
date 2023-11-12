#!/bin/bash
cd onnx

set -euxo pipefail
mkdir build
cd build

cmake ${CMAKE_ARGS} \
    -DONNX_ML=1 \
    -DBUILD_SHARED_LIBS=ON \
    -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc \
    -DProtobuf_LIBRARY=$PREFIX/lib/libprotobuf${SHLIB_EXT} \
    -DProtobuf_INCLUDE_DIR:PATH=${PREFIX}/include \
    ..

make -j${CPU_COUNT}
make install
