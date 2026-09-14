// Exceptions thrown inside the shared ONNX library must be catchable by their
// exact type in a separate module. Consumers such as onnxruntime catch
// onnx::InferenceError to downgrade shape-inference problems to warnings; if
// the exception classes' typeinfo is not exported (macOS compares it by
// identity), the catch clause silently does not match (patch 0008).

#include <onnx/checker.h>
#include <onnx/defs/schema.h>
#include <onnx/defs/shape_inference.h>
#include <onnx/onnx_pb.h>
#include <onnx/shape_inference/implementation.h>

#include <cstdlib>
#include <iostream>
#include <string>

namespace {

int failures = 0;

void Report(const std::string& what, bool ok) {
  std::cout << (ok ? "PASS " : "FAIL ") << what << std::endl;
  if (!ok) ++failures;
}

onnx::ModelProto ReluModel(int64_t input_dim, int64_t declared_output_dim) {
  onnx::ModelProto model;
  model.set_ir_version(onnx::IR_VERSION);
  auto* opset = model.add_opset_import();
  opset->set_domain("");
  opset->set_version(21);
  auto* graph = model.mutable_graph();
  graph->set_name("g");
  auto* node = graph->add_node();
  node->set_op_type("Relu");
  node->add_input("x");
  node->add_output("y");
  auto add_value = [](onnx::ValueInfoProto* info, const char* name, int64_t dim) {
    info->set_name(name);
    auto* t = info->mutable_type()->mutable_tensor_type();
    t->set_elem_type(onnx::TensorProto::FLOAT);
    t->mutable_shape()->add_dim()->set_dim_value(dim);
    t->mutable_shape()->add_dim()->set_dim_value(dim);
  };
  add_value(graph->add_input(), "x", input_dim);
  add_value(graph->add_output(), "y", declared_output_dim);
  return model;
}

}  // namespace

int main() {
  // InferenceError: declared output shape contradicts Relu's inferred shape.
  try {
    auto model = ReluModel(2, 3);
    onnx::shape_inference::InferShapes(model, onnx::OpSchemaRegistry::Instance(),
                                       onnx::ShapeInferenceOptions(true, 1, false));
    Report("InferenceError thrown", false);
  } catch (const onnx::InferenceError& e) {
    Report(std::string("InferenceError caught by type: ") + e.what(), true);
  } catch (const std::exception& e) {
    Report(std::string("InferenceError caught only as std::exception: ") + e.what(), false);
  }

  // ValidationError: a model without an IR version.
  try {
    auto model = ReluModel(2, 2);
    model.clear_ir_version();
    onnx::checker::check_model(model);
    Report("ValidationError thrown", false);
  } catch (const onnx::checker::ValidationError& e) {
    Report(std::string("ValidationError caught by type: ") + e.what(), true);
  } catch (const std::exception& e) {
    Report(std::string("ValidationError caught only as std::exception: ") + e.what(), false);
  }

  // SchemaError: a duplicate type constraint name (thrown inside libonnx's schema.cc).
  try {
    onnx::OpSchema schema;
    schema.TypeConstraint("T", {"tensor(float)"}, "").TypeConstraint("T", {"tensor(float)"}, "");
    Report("SchemaError thrown", false);
  } catch (const onnx::SchemaError& e) {
    Report(std::string("SchemaError caught by type: ") + e.what(), true);
  } catch (const std::exception& e) {
    Report(std::string("SchemaError caught only as std::exception: ") + e.what(), false);
  }

  return failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
