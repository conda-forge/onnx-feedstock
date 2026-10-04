cmake_minimum_required(VERSION 3.20)
project(libonnx_released_opsets CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ONNX CONFIG REQUIRED)
find_package(Protobuf CONFIG REQUIRED)

add_executable(test_libonnx_released_opsets test_libonnx_released_opsets.cpp)
target_link_libraries(test_libonnx_released_opsets PRIVATE ONNX::onnx ONNX::onnx_proto protobuf::libprotobuf)
