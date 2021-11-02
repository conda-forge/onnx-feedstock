export ONNX_ML=1
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc -DProtobuf_LIBRARY=$PREFIX/include"
export CMAKE_ARGS="-DONNX_USE_PROTOBUF_SHARED_LIBS=OFF"
$PYTHON -m pip install --no-deps --ignore-installed --verbose .
