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
# Does not apply to osx-arm64 as its SDK is higher
if [[ "${target_platform}" == osx-64 ]]; then
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
    -DONNX_NAMESPACE="${ONNX_NAMESPACE}" \
    -DCMAKE_CXX_STANDARD=17 \
    -DProtobuf_PROTOC_EXECUTABLE="${PROTOC}" \
    -DProtobuf_LIBRARY="${PREFIX}/lib/libprotobuf${SHLIB_EXT}" \
    -DProtobuf_INCLUDE_DIR:PATH="${PREFIX}/include" \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON

cmake --build build
cmake --install build

# Provide unversioned development symlinks (libonnx${SHLIB_EXT} ->
# libonnx-X.Y${SHLIB_EXT}) so downstreams can link -lonnx without hard-coding
# the version. These ship only in the single-version libonnx-dev package; the
# versioned libraries (in the co-installable runtime) are what keep different
# ONNX versions from colliding on disk. The target is discovered from the
# installed file so it tracks whatever version patch 0010 stamped in.
for _lib in onnx onnx_proto; do
    versioned="$(basename "$(ls "${PREFIX}/lib/lib${_lib}-"*"${SHLIB_EXT}")")"
    ln -sf "${versioned}" "${PREFIX}/lib/lib${_lib}${SHLIB_EXT}"
done
