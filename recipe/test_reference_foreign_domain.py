# onnx.reference must import even when another library sharing the ONNX
# schema registry (e.g. onnxruntime) registered an operator name in a
# non-ONNX domain (patch 0009).
import onnx.defs
schema = onnx.defs.OpSchema(
    "Relu", "test.foreign.domain", 1,
    inputs=[onnx.defs.OpSchema.FormalParameter("X", "T")],
    outputs=[onnx.defs.OpSchema.FormalParameter("Y", "T")],
    type_constraints=[("T", ["tensor(float)"], "")],
)
onnx.defs.register_schema(schema)
import onnx.reference  # noqa: E402
print("onnx.reference imports with a foreign-domain Relu registered")
