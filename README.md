# PicoGK.Legacy

**Build and distribution infrastructure for PicoGK 2.x**

[PicoGK](https://picogk.org) is an open-source computational geometry library developed by [LEAP 71](https://leap71.com/). It provides a programmable geometry kernel for creating complex three-dimensional objects using voxel-based modeling, signed distance fields, meshes, and related geometric operations.

PicoGK.Legacy brings together the existing PicoGK 2.x C# library and its native C++ runtime into a unified, reproducible build environment.

## Purpose

PicoGK 2.x is a mature software library with an established user base. It remains actively used in computational engineering applications and continues to receive community contributions and bug reports.

We are moving PicoGK 2.x into maintenance mode while developing its successor, [PicoGK.Core](https://github.com/leap71/PicoGK.Core).

This repository is intended to make maintaining PicoGK 2.x sustainable by replacing the historically manual native compilation, dependency management, and distribution process with an automated build pipeline.

The goal is to preserve the existing functionality and public interfaces, not to redesign the legacy architecture.

## Repository Structure

```
PicoGK.Legacy/
├── PicoGK/                 # C# library (Git submodule)
├── PicoGKRuntime/          # Native C++ runtime (Git submodule)
├── native/
│   └── PicoVDB/            # Reduced OpenVDB build configuration
├── third_party/
│   ├── openvdb/
│   ├── oneTBB/
│   ├── glfw/
│   └── imgui/
├── CMakeLists.txt
└── .github/
    └── workflows/
```

The two main components remain independent repositories:

- [**PicoGK**](https://github.com/leap71/PicoGK) contains the managed C# library, geometry abstractions, viewer integration, and NuGet package definition.
- [**PicoGKRuntime**](https://github.com/leap71/PicoGKRuntime) contains the native C++ geometry kernel and its C-compatible interface.

Both are included as Git submodules, preserving their existing development histories and contribution workflows.

Third-party dependencies are pinned to specific revisions to ensure that a given PicoGK.Legacy commit identifies a consistent set of source dependencies.

### PicoVDB

The native build uses a reduced OpenVDB configuration derived from PicoGK.Core.

Rather than building the complete OpenVDB distribution, PicoVDB compiles the components required by PicoGK directly, with a simplified dependency structure.

PicoVDB is maintained locally in this repository. It is not a shared dependency on PicoGK.Core, allowing the legacy runtime to remain stable as the newer architecture evolves.

## Building

The build system is based on CMake and is intended to produce native runtimes for Windows x64 and macOS ARM64.

### Clone the repository

```
git clone https://github.com/leap71/PicoGK.Legacy.git
cd PicoGK.Legacy
```

Initialize the required submodules:

```
git submodule update --init \
    PicoGK \
    PicoGKRuntime \
    third_party/openvdb \
    third_party/oneTBB \
    third_party/glfw \
    third_party/imgui
```

The explicit submodule list avoids unnecessarily initializing historical nested dependencies inside PicoGKRuntime.

### Native build

Once the unified build configuration is complete, the intended build process is:

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel
```

Build artifacts will be collected separately from the existing precompiled native libraries, so that the new runtime can be validated before replacing the current distribution.

The longer-term objective is to have GitHub Actions build, test, package, and publish PicoGK 2.x releases without requiring manual compilation or packaging.

## Maintenance Policy

PicoGK 2.x is entering maintenance mode.

We intend to continue accepting:

- Bug fixes and correctness improvements.
- Compatibility fixes for supported platforms.
- Security and dependency updates where necessary.
- Small, well-contained improvements that do not destabilize existing functionality.

Major architectural changes, new geometry abstractions, and substantial new functionality should generally be developed in PicoGK.Core instead.

Maintaining compatibility with existing PicoGK 2.x applications is the primary consideration.

## PicoGK.Core

[PicoGK.Core](https://github.com/leap71/PicoGK.Core) is the next-generation computational geometry kernel developed by LEAP 71.

It introduces a redesigned native runtime, a simplified architecture, and a modernized build and distribution system.

PicoGK.Core is not currently intended to be a drop-in replacement for PicoGK 2.x. Both projects will coexist while the new architecture evolves.

The build infrastructure in this repository draws on lessons and components from PicoGK.Core, but the legacy runtime remains independent.

## Contributing

Bug reports and contributions to the existing functionality should continue to be submitted to the respective source repositories:

- [PicoGK — C# library](https://github.com/leap71/PicoGK)
- [PicoGKRuntime — C++ runtime](https://github.com/leap71/PicoGKRuntime)

Changes to the unified build system, dependency configuration, and release infrastructure belong in this repository.

## License

PicoGK and PicoGKRuntime retain their respective licenses. Third-party dependencies are distributed under their own licenses.

Refer to the individual repositories and dependency directories for the applicable license terms.