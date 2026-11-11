# Restrict initial validation to the two platforms supported by PicoGK 2.x.
# An explicit PICOGK_RID is permitted only when it matches the host target.
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
        message(FATAL_ERROR "PicoGK 2.x Windows build must be x64")
    endif()
    set(_picogk_expected_rid "win-x64")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    # On an Apple Silicon runner, CMAKE_HOST_SYSTEM_PROCESSOR is arm64.
    # For a cross-target configuration pass -DCMAKE_OSX_ARCHITECTURES=arm64.
    if(CMAKE_OSX_ARCHITECTURES)
        if(NOT CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
            message(FATAL_ERROR "Expected macOS arm64; set CMAKE_OSX_ARCHITECTURES=arm64")
        endif()
    elseif(NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(arm64|aarch64)$")
        message(FATAL_ERROR "Expected macOS arm64; set CMAKE_OSX_ARCHITECTURES=arm64")
    endif()
    set(_picogk_expected_rid "osx-arm64")
else()
    message(FATAL_ERROR "Initial migration supports Windows x64 and macOS arm64 only")
endif()

if(DEFINED PICOGK_RID AND NOT PICOGK_RID STREQUAL _picogk_expected_rid)
    message(FATAL_ERROR "PICOGK_RID=${PICOGK_RID} disagrees with target ${_picogk_expected_rid}")
endif()
set(PICOGK_RID "${_picogk_expected_rid}" CACHE STRING "NuGet runtime identifier" FORCE)
