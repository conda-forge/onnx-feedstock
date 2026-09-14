cmake_minimum_required(VERSION 3.20)
project(libonnx_exceptions CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Like any consumer built with hidden visibility (onnxruntime is), so this
# program's inline copies of the ONNX classes cannot stand in for libonnx's.
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

find_package(ONNX CONFIG REQUIRED)
find_package(Protobuf CONFIG REQUIRED)

add_executable(test_libonnx_exceptions test_libonnx_exceptions.cpp)
target_link_libraries(test_libonnx_exceptions PRIVATE ONNX::onnx ONNX::onnx_proto protobuf::libprotobuf)
