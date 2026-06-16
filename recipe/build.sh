#!/bin/bash
set -euxo pipefail

export ONNX_ML=1
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"
# Build in parallel. scikit-build-core (the pip install below) and
# `cmake --build` both honor this, so neither step runs single-threaded.
export CMAKE_BUILD_PARALLEL_LEVEL=${CPU_COUNT}
# conda build environments ship ninja but not make, so pin the generator for
# both scikit-build-core and the manual cmake invocation below. Without this
# scikit-build-core defaults to "Unix Makefiles" and configure fails with
# "CMAKE_MAKE_PROGRAM is not set".
export CMAKE_GENERATOR="Ninja"
export CMAKE_ARGS="${CMAKE_ARGS}"
if [[ ${CONDA_BUILD_CROSS_COMPILATION:-} == "1" ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
else
    export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$PREFIX/bin/protoc"
fi
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=$PREFIX/lib/libprotobuf${SHLIB_EXT}"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_INCLUDE_DIR:PATH=${PREFIX}/include"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
export CMAKE_ARGS="${CMAKE_ARGS} -DNPY_TARGET_VERSION=NPY_1_19_API_VERSION"
export CMAKE_ARGS="${CMAKE_ARGS} -DPython_EXECUTABLE=$PYTHON"
export CMAKE_ARGS="${CMAKE_ARGS} -DFETCHCONTENT_FULLY_DISCONNECTED=ON"

# See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
# Does not apply to osx-arm64 as its SDK is higher
if [[ "${target_platform}" == osx-64 ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi
$PYTHON -m pip install --no-deps --ignore-installed --verbose .

# Reconfigure the build to produce the shared C++ libraries without the
# Python bindings, then install them. onnx's pyproject.toml sets
# ONNX_INSTALL=OFF for the wheel build, so we have to flip it back on here
# for `cmake --install` to emit the C++ targets and cmake config files.
cmake -S . -B .setuptools-cmake-build ${CMAKE_ARGS} \
    -DONNX_BUILD_PYTHON=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DONNX_INSTALL=ON
cmake --build .setuptools-cmake-build
cmake --install .setuptools-cmake-build
