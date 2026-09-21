#!/bin/bash
set -euxo pipefail

export ONNX_ML=1

# protoc must run on the build platform when cross compiling.
if [[ ${CONDA_BUILD_CROSS_COMPILATION:-} == "1" ]]; then
    PROTOC="${BUILD_PREFIX}/bin/protoc"
else
    PROTOC="${PREFIX}/bin/protoc"
fi

# See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
# Needed on every osx target, not just osx-64: both deployment targets are
# 12.0, and onnx 1.23.0 formats floats with std::to_chars, which libc++
# annotates as introduced in macOS 13.3. conda-forge ships its own libcxx,
# which does export those overloads, so the availability check is what has to
# go -- not the deployment target.
if [[ "${target_platform}" == osx-* ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Build only the C++ shared library; the Python bindings are built by the
# separate onnx output.
cmake -G Ninja -S . -B build ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_SHARED_LIBS=ON \
    -DONNX_BUILD_PYTHON=OFF \
    -DONNX_ML=1 \
    -DCMAKE_CXX_STANDARD=17 \
    -DProtobuf_PROTOC_EXECUTABLE="${PROTOC}" \
    -DProtobuf_LIBRARY="${PREFIX}/lib/libprotobuf${SHLIB_EXT}" \
    -DProtobuf_INCLUDE_DIR:PATH="${PREFIX}/include" \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON

cmake --build build
cmake --install build
