// In a released ONNX, the last released opset of every domain must be the
// highest opset the schema registry knows. Consumers such as onnxruntime use
// LastReleaseVersionMap() to reject models stamped with an opset that is
// still under development; ONNX 1.23.0 and 1.23.1 reported 27 for ai.onnx
// while shipping opset 28 (patch 0011).

#include <onnx/defs/schema.h>

#include <cstdlib>
#include <iostream>

int main() {
  const auto& range = onnx::OpSchemaRegistry::DomainToVersionRange::Instance();
  const auto& released = range.LastReleaseVersionMap();
  int failures = 0;
  for (const auto& [domain, versions] : range.Map()) {
    const auto it = released.find(domain);
    const bool ok = it != released.end() && it->second == versions.second;
    std::cout << (ok ? "PASS " : "FAIL ") << "domain '" << domain << "': max opset " << versions.second
              << ", last released opset " << (it == released.end() ? -1 : it->second) << std::endl;
    if (!ok) ++failures;
  }
  return failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
