export ONNX_ML=1  # [unix] 
# build script looks at this, but not set on
export CONDA_PREFIX="$PREFIX"  # [unix]
$PYTHON -m pip install --no-deps --ignore-installed --verbose .
