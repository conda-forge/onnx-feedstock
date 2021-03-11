export ONNX_ML=1 
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
$PYTHON -m pip install --no-deps --ignore-installed --verbose .
