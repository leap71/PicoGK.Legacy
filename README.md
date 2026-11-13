# PicoGK.Legacy

**Build and distribution infrastructure for PicoGK 2.x**

[PicoGK](https://picogk.org) is an open-source computational geometry library developed by [LEAP 71](https://leap71.com/). It provides voxel-based modeling, signed distance fields, meshes, and related geometric operations for computational engineering.

PicoGK.Legacy brings the existing C# library and native C++ runtime together in a pinned-source build environment. Its GitHub Actions workflow builds native runtimes, assembles NuGet packages, checks their contents, and runs native-loading smoke tests on each target platform. Tagged releases can be published to NuGet.org through a gated release job.

## Purpose

PicoGK 2.x is moving into maintenance mode while its successor, [PicoGK.Core](https://github.com/leap71/PicoGK.Core), is developed.

This repository replaces manual native compilation and packaging with an automated pipeline. The goal is to preserve existing functionality and public interfaces, not to redesign the legacy architecture.

## Repository Structure

```text
PicoGK.Legacy/
├── PicoGK/                 # Managed C# library and package definition (submodule)
├── PicoGKRuntime/          # Native C++ runtime (submodule)
├── cmake/                  # Platform checks and legacy runtime integration
├── native/PicoVDB/         # Reduced OpenVDB build configuration
├── third_party/            # Pinned OpenVDB, oneTBB, GLFW, and ImGui submodules
├── scripts/                # NuGet payload verification
├── tests/                  # NuGet consumer native-loading smoke test
├── CMakeLists.txt
├── Directory.Build.targets # Adds staged native binaries during legacy packaging
└── .github/workflows/      # Build, package, smoke-test, and release pipeline
```

The two main components remain independent repositories:

- [**PicoGK**](https://github.com/leap71/PicoGK) contains the managed library, geometry abstractions, viewer integration, and NuGet package definition. It currently targets .NET 9.
- [**PicoGKRuntime**](https://github.com/leap71/PicoGKRuntime) contains the native geometry kernel and its C-compatible interface.

Submodules preserve their development histories and pin the source revisions used by each PicoGK.Legacy commit. The top-level CMake project integrates the native runtime with the dependencies in `third_party/`. The pinned submodules currently have no nested submodules.

### PicoVDB

PicoVDB compiles the OpenVDB components required by PicoGK directly rather than building the complete upstream distribution. Its reduced configuration was derived from PicoGK.Core but is maintained locally here; building Legacy does not require a PicoGK.Core checkout.

Keep the OpenVDB submodule at the revision pinned by this repository. The explicit PicoVDB source list is revision-dependent; updating OpenVDB requires checking that configuration and using a fresh build directory.

## Building Locally

### Platforms and prerequisites

| Platform | Runtime identifier (RID) | Status |
| --- | --- | --- |
| macOS ARM64 | `osx-arm64` | Release target |
| Windows x64 | `win-x64` | Release target |
| Linux x64 | `linux-x64` | Experimental build target |

All three are included in the CI build and package-consumer matrix. Linux builds the legacy viewer against X11; CI does not exercise the graphical viewer.

Native builds require Git, CMake 3.25 or later, a C++20-capable compiler, and the platform's OpenGL development environment. Use an x64 compiler/toolchain on Windows. Managed builds require an SDK capable of targeting .NET 9; CI uses the .NET 10 SDK and installs .NET 9 for the consumer smoke test. Package verification also requires Python 3.

On Ubuntu 22.04, CI installs these native build dependencies:

```sh
sudo apt-get update
sudo apt-get install -y xorg-dev libgl1-mesa-dev libxkbcommon-dev pkg-config
```

### Clone and initialize dependencies

```sh
git clone https://github.com/leap71/PicoGK.Legacy.git
cd PicoGK.Legacy
```

Initialize the pinned submodules:

```sh
git submodule update --init --recursive
```

Run the same command after updating the superproject to synchronize the submodules with its pins. The historical nested dependencies have been removed from PicoGKRuntime; recursive initialization is safe for the current pinned revisions.

### Build the native runtime

From the repository root:

```sh
cmake -S . -B build-legacy -DCMAKE_BUILD_TYPE=Release
cmake --build build-legacy --config Release --target PicoGKRuntime --parallel 2
```

For an explicit macOS ARM64 configuration, add `-DCMAKE_OSX_ARCHITECTURES=arm64` to the configure command. CMake selects the RID from the target platform; an optional `-DPICOGK_RID=<rid>` must agree with that target. Setting a RID alone does not configure cross-compilation.

With the default output configuration, binaries are staged under:

```text
build-legacy/artifacts/runtimes/<rid>/native/
```

The staged runtime consists of `picogk.26` with the platform-specific extension (`.dylib`, `.dll`, or `.so`) and the oneTBB runtime (`libtbb.12.dylib`, `tbb12.dll`, or `libtbb.so.12`). The versioned native basename matches the managed P/Invoke import and avoids a Windows filename collision with the managed `PicoGK.dll`.

The build output stays separate from the source submodules. Use `build-legacy` when following the packaging workflow: `Directory.Build.targets` reads native assets from that directory.

## CI, Packaging, and Releases

The [GitHub Actions workflow](.github/workflows/build.yml) runs on pushes to `main`, `v*` tags, pull requests, and manual dispatches.

### Build and validation

1. Build the native runtime on macOS ARM64, Windows x64, and Linux x64.
2. Check expected native outputs and audit macOS/Linux dependency paths and resolution.
3. Collect all three platforms' binaries and pack the managed project as the **`PicoGK`** NuGet package, with a corresponding `.snupkg` symbol package.
4. Verify package identity, version, managed assembly, and exact native payload using [`scripts/verify-package.py`](scripts/verify-package.py).
5. Restore a separate consumer from that workflow's package and run the native-loading smoke test on each platform. Package source mapping ensures the consumer uses the newly built `PicoGK` package, not a published copy.

Packaging enables `PicoGKLegacyPack=true`, which causes `Directory.Build.targets` to include the staged native libraries. A single local native build produces only the current target's assets; it is not sufficient to reproduce the complete three-platform CI package.

The consumer smoke test checks the managed import name and loads the native library. It does **not** invoke geometry operations or test graphical viewer behavior, so it is not a full functional or ABI compatibility test.

### Versions and artifacts

- Tagged builds derive the package version by removing the leading `v` from the tag.
- Non-tagged builds use `2.4.0-ci.<run-id>.<attempt>`.
- Native binaries are uploaded as `native-<rid>` workflow artifacts.
- NuGet and symbol packages are uploaded as the `PicoGK-NuGet` artifact.

The NuGet package ID remains `PicoGK`, not `PicoGK.Legacy`. Package versions are supplied by the superproject workflow rather than taken from the managed submodule's default version.

### Publishing

Publishing runs only after package validation and all consumer smoke tests succeed, and only when:

- The event is a push of a `v*` tag in `leap71/PicoGK.Legacy`.
- The repository variable `NUGET_PUBLISH_ENABLED` is set to `true`.
- The job can proceed through the `release` environment and authenticate to NuGet.org using `NuGet/login` with the `NUGET_USER` variable.

Authentication uses GitHub OIDC. The workflow configuration alone does not establish that the required repository variables, environment protections, or NuGet trusted publishing settings have been configured.

## Maintenance Policy

Maintaining compatibility with existing PicoGK 2.x applications is the primary consideration. Appropriate changes include:

- Bug fixes and correctness improvements.
- Compatibility fixes for supported platforms.
- Security and dependency updates where necessary.
- Small, well-contained improvements that do not destabilize existing functionality.

Major architectural changes, new geometry abstractions, and substantial new functionality should generally target PicoGK.Core instead.

## PicoGK.Core

[PicoGK.Core](https://github.com/leap71/PicoGK.Core) is the next-generation geometry kernel, with a redesigned native runtime and simplified architecture. It is not currently intended as a drop-in replacement for PicoGK 2.x.

The projects coexist while the new architecture evolves. Legacy draws on build infrastructure developed for Core but remains independent of it.

## Contributing

Submit bug reports and changes to existing library functionality to the respective source repositories:

- [PicoGK — C# library](https://github.com/leap71/PicoGK)
- [PicoGKRuntime — C++ runtime](https://github.com/leap71/PicoGKRuntime)

Changes to the unified build system, dependency pins, packaging, documentation, and release infrastructure belong in this repository.

## License

PicoGK.Legacy's first-party build infrastructure, scripts, tests, and documentation are licensed under the [Apache License, Version 2.0](LICENSE.txt) (`Apache-2.0`), unless otherwise noted.

Submodules, including PicoGK and PicoGKRuntime, and third-party dependencies retain their respective licenses and notices. The root license does not replace those terms; refer to the individual repositories and dependency directories for details.
