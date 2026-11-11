# Legacy native runtime is an unmodified Git submodule. Define the target in
# the superproject instead of invoking PicoGKRuntime's old CMakeLists.txt.
set(PICOGK_LEGACY_RUNTIME_DIR "${PROJECT_SOURCE_DIR}/PicoGKRuntime")
set(PICOGK_IMGUI_DIR "${PROJECT_SOURCE_DIR}/third_party/imgui")

file(GLOB_RECURSE PICOGK_LEGACY_SOURCES CONFIGURE_DEPENDS
    "${PICOGK_LEGACY_RUNTIME_DIR}/Source/*.cpp"
    "${PICOGK_LEGACY_RUNTIME_DIR}/Source/*.c")
if(NOT PICOGK_LEGACY_SOURCES)
    message(FATAL_ERROR "No PicoGKRuntime/Source files found")
endif()

set(PICOGK_IMGUI_SOURCES
    "${PICOGK_IMGUI_DIR}/imgui.cpp"
    "${PICOGK_IMGUI_DIR}/imgui_draw.cpp"
    "${PICOGK_IMGUI_DIR}/imgui_tables.cpp"
    "${PICOGK_IMGUI_DIR}/imgui_widgets.cpp"
    "${PICOGK_IMGUI_DIR}/imgui_demo.cpp"
    "${PICOGK_IMGUI_DIR}/backends/imgui_impl_glfw.cpp"
    "${PICOGK_IMGUI_DIR}/backends/imgui_impl_opengl3.cpp")

add_library(PicoGKRuntime SHARED ${PICOGK_LEGACY_SOURCES} ${PICOGK_IMGUI_SOURCES})

target_compile_definitions(PicoGKRuntime PRIVATE
    PICOGK_BUILD_LIBRARY
    $<$<CONFIG:Debug>:DEBUG_BUILD>)

target_include_directories(PicoGKRuntime
    PUBLIC "${PICOGK_LEGACY_RUNTIME_DIR}/API"
    PRIVATE
        "${PICOGK_LEGACY_RUNTIME_DIR}/Source"
        "${PICOGK_IMGUI_DIR}"
        "${PICOGK_IMGUI_DIR}/backends")

target_link_libraries(PicoGKRuntime PRIVATE PicoGK::PicoVDB glfw OpenGL::GL)

set_target_properties(PicoGKRuntime PROPERTIES
    OUTPUT_NAME "picogk.26"
    PREFIX ""
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/archive"
    LIBRARY_OUTPUT_DIRECTORY "${PICOGK_NATIVE_OUTPUT_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${PICOGK_NATIVE_OUTPUT_DIR}"
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN YES
    DEBUG_POSTFIX "d")

# Multi-config Visual Studio/Xcode generators otherwise append Debug/Release.
foreach(_config DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    set_target_properties(PicoGKRuntime PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY_${_config} "${CMAKE_CURRENT_BINARY_DIR}/archive/${_config}"
        LIBRARY_OUTPUT_DIRECTORY_${_config} "${PICOGK_NATIVE_OUTPUT_DIR}"
        RUNTIME_OUTPUT_DIRECTORY_${_config} "${PICOGK_NATIVE_OUTPUT_DIR}")
endforeach()

if(MSVC)
    target_compile_options(PicoGKRuntime PRIVATE /bigobj)
endif()
if(APPLE)
    set_target_properties(PicoGKRuntime PROPERTIES
        XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
        BUILD_RPATH "@loader_path"
        INSTALL_RPATH "@loader_path")
elseif(UNIX)
    set_target_properties(PicoGKRuntime PROPERTIES
        BUILD_RPATH "$ORIGIN"
        INSTALL_RPATH "$ORIGIN")
endif()
set_target_properties(PicoGKRuntime PROPERTIES
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH_USE_LINK_PATH FALSE)

# oneTBB is dynamic. Copy the actual binary under its loader-facing SONAME.
if(UNIX)
    add_custom_command(TARGET PicoGKRuntime POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:TBB::tbb>"
            "${PICOGK_NATIVE_OUTPUT_DIR}/$<TARGET_SONAME_FILE_NAME:TBB::tbb>"
        COMMENT "Staging oneTBB alongside the experimental native runtime")
elseif(WIN32)
    add_custom_command(TARGET PicoGKRuntime POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
            "$<TARGET_FILE:TBB::tbb>"
            "${PICOGK_NATIVE_OUTPUT_DIR}/$<TARGET_FILE_NAME:TBB::tbb>"
        COMMENT "Staging oneTBB alongside the experimental native runtime")
endif()

option(PICOGK_BUILD_LEGACY_APITESTS "Build old API smoke test executable" OFF)
if(PICOGK_BUILD_LEGACY_APITESTS)
    add_executable(PicoGKLegacyAPITests "${PICOGK_LEGACY_RUNTIME_DIR}/APITests/main.cpp")
    target_link_libraries(PicoGKLegacyAPITests PRIVATE PicoGKRuntime)
endif()
