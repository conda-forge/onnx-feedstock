export ONNX_ML=1 
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"
$PYTHON -m pip install --no-deps --ignore-installed --verbose .
