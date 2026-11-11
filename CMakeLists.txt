cmake_minimum_required(VERSION 3.25)

# PicoGK 2.x native build integration, independent of the historical
# PicoGKRuntime/CMakeLists.txt and its nested dependencies.
cmake_policy(SET CMP0091 NEW)
project(PicoGKLegacyNative VERSION 26.2.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

include(cmake/PicoGKLegacyPlatform.cmake)

set(PICOGK_NATIVE_OUTPUT_DIR
    "${CMAKE_BINARY_DIR}/artifacts/runtimes/${PICOGK_RID}/native"
    CACHE PATH "Isolated output directory for experimental native binaries")
file(MAKE_DIRECTORY "${PICOGK_NATIVE_OUTPUT_DIR}")

# This integration deliberately does not run 'git submodule update --recursive':
# PicoGKRuntime still declares its historical nested dependencies.
foreach(required_file IN ITEMS
    "PicoGKRuntime/Source/PicoGKLibrary.cpp"
    "PicoGKRuntime/API/PicoGK.h"
    "native/PicoVDB/CMakeLists.txt"
    "third_party/openvdb/openvdb/openvdb/Grid.cc"
    "third_party/oneTBB/CMakeLists.txt"
    "third_party/glfw/CMakeLists.txt"
    "third_party/imgui/imgui.cpp")
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/${required_file}")
        message(FATAL_ERROR
            "Missing ${required_file}. Initialize the six direct submodules, "
            "but not the historical nested PicoGKRuntime submodules.")
    endif()
endforeach()

# Match PicoGK.Core's reduced oneTBB build. PicoVDB brings its own explicit
# OpenVDB source list and does NOT add the upstream OpenVDB CMake project.
set(TBB_TEST OFF CACHE BOOL "" FORCE)
set(TBB_EXAMPLES OFF CACHE BOOL "" FORCE)
set(TBB_INSTALL OFF CACHE BOOL "" FORCE)
set(TBBMALLOC_BUILD OFF CACHE BOOL "" FORCE)
set(TBBMALLOC_PROXY_BUILD OFF CACHE BOOL "" FORCE)
set(TBB_DISABLE_HWLOC_AUTOMATIC_SEARCH ON CACHE BOOL "" FORCE)
set(TCM_BUILD OFF CACHE BOOL "" FORCE)

# oneTBB must be a shared library: PicoGKRuntime packages its SONAME-facing
# dynamic binary alongside the native runtime. A stale BUILD_SHARED_LIBS=OFF
# CMakeCache entry must not silently turn it into an unsupported static build.
set(BUILD_SHARED_LIBS ON)
add_subdirectory(third_party/oneTBB ${CMAKE_BINARY_DIR}/third_party/oneTBB EXCLUDE_FROM_ALL)

# Other dependencies remain static. The native runtime target is explicitly SHARED.
set(BUILD_SHARED_LIBS OFF)

# The copied PicoVDB source list is from Core's OpenVDB revision. Do not
# silently mix it with the newer 13.2+/14 source tree (delayed loading removed).
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/openvdb/openvdb/openvdb/io/DelayedLoadMetadata.cc")
    message(FATAL_ERROR
        "OpenVDB revision mismatch: PicoVDB requires io/DelayedLoadMetadata.cc. "
        "Pin third_party/openvdb to PicoGK.Core's exact OpenVDB commit "
        "(or try tag v13.1.0), then configure with a fresh build directory.")
endif()

add_subdirectory(native/PicoVDB)
if(NOT TARGET PicoGK::PicoVDB)
    message(FATAL_ERROR
        "Expected PicoGK::PicoVDB target. Check the copied PicoGK.Core "
        "native/PicoVDB configuration.")
endif()
if(MSVC)
    target_compile_options(PicoVDB PRIVATE /bigobj)
endif()

# GLFW belongs to the legacy viewer. Do not request examples/tests/docs.
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)
set(GLFW_LIBRARY_TYPE STATIC CACHE STRING "" FORCE)
add_subdirectory(third_party/glfw ${CMAKE_BINARY_DIR}/third_party/glfw EXCLUDE_FROM_ALL)
find_package(OpenGL REQUIRED)

include(cmake/PicoGKLegacyRuntime.cmake)
