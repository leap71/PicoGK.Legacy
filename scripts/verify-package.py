#!/usr/bin/env python3
"""Verify that the tagged PicoGK package contains only the intended RID assets."""
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import zipfile

EXPECTED_NATIVE = {
    "runtimes/osx-arm64/native/libtbb.12.dylib",
    "runtimes/osx-arm64/native/picogk.dylib",
    "runtimes/win-x64/native/picogk.dll",
    "runtimes/win-x64/native/tbb12.dll",
}


def verify(directory: Path, version: str) -> None:
    packages = list(directory.glob("PicoGK.*.nupkg"))
    expected_name = f"PicoGK.{version}.nupkg"
    if len(packages) != 1 or packages[0].name != expected_name:
        raise ValueError(f"Expected only {expected_name}; found {[p.name for p in packages]}")

    with zipfile.ZipFile(packages[0]) as archive:
        names = set(archive.namelist())
        native = {
            name for name in names
            if name.startswith("runtimes/") and not name.endswith("/")
        }
        if native != EXPECTED_NATIVE:
            raise ValueError(
                f"Unexpected native runtime payload.\n"
                f"Missing: {sorted(EXPECTED_NATIVE - native)}\n"
                f"Unexpected: {sorted(native - EXPECTED_NATIVE)}"
            )
        if "lib/net9.0/PicoGK.dll" not in names:
            raise ValueError("Missing managed assembly: lib/net9.0/PicoGK.dll")

        nuspecs = [name for name in names if name.endswith(".nuspec")]
        if len(nuspecs) != 1:
            raise ValueError(f"Expected one NuGet manifest, found {nuspecs}")
        root = ET.fromstring(archive.read(nuspecs[0]))
        identity = root.find(".//{*}metadata/{*}id")
        declared_version = root.find(".//{*}metadata/{*}version")
        if identity is None or identity.text != "PicoGK":
            raise ValueError("Unexpected NuGet package ID")
        if declared_version is None or declared_version.text != version:
            raise ValueError(f"Unexpected NuGet version: {declared_version.text if declared_version is not None else None}")

    symbols = list(directory.glob("PicoGK.*.snupkg"))
    if len(symbols) != 1 or symbols[0].name != f"PicoGK.{version}.snupkg":
        raise ValueError("Expected the corresponding PicoGK symbol package (.snupkg)")

    print(f"Verified {expected_name} and its symbols package")
    for path in sorted(EXPECTED_NATIVE):
        print("  ", path)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: verify-package.py <directory> <version>")
    verify(Path(sys.argv[1]), sys.argv[2])
