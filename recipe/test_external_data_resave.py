# Reading an external tensor with numpy_helper.to_array must not leave the
# model in a state that can no longer be saved. ONNX 1.23.0 populated
# raw_data on the tensor, and the following save then tried to rewrite the
# existing external data file, which 1.23 refuses to do.
# https://github.com/onnx/onnx/issues/8471, fixed in 1.23.1.
import os
import tempfile

import numpy as np

import onnx
from onnx import TensorProto, helper, numpy_helper

expected = np.arange(64 * 64, dtype=np.float32).reshape(64, 64)
graph = helper.make_graph(
    [helper.make_node("MatMul", ["x", "w"], ["y"])],
    "g",
    [helper.make_tensor_value_info("x", TensorProto.FLOAT, [1, 64])],
    [helper.make_tensor_value_info("y", TensorProto.FLOAT, [1, 64])],
    initializer=[numpy_helper.from_array(expected, name="w")],
)
model = helper.make_model(graph)

with tempfile.TemporaryDirectory() as tmpdir:
    path = os.path.join(tmpdir, "model.onnx")
    onnx.save(
        model,
        path,
        save_as_external_data=True,
        location="model.onnx.data",
        size_threshold=0,
    )
    model = onnx.load(path, load_external_data=False)
    (weight,) = model.graph.initializer
    np.testing.assert_array_equal(numpy_helper.to_array(weight, base_dir=tmpdir), expected)
    assert not weight.HasField("raw_data"), "to_array mutated the external tensor"
    onnx.save(model, path)

    (weight,) = onnx.load(path).graph.initializer
    np.testing.assert_array_equal(numpy_helper.to_array(weight), expected)
print("an external tensor can be read with to_array and the model saved again")
