"""Validate that CI produces architecture-specific release builds, never debug APKs."""
import json
import os
import pathlib
import subprocess
import zipfile

build_tools = pathlib.Path(os.environ["ANDROID_HOME"]) / "build-tools"
aapt = max((p / "aapt" for p in build_tools.iterdir() if (p / "aapt").exists()), key=lambda p: tuple(int(x) for x in p.parent.name.split(".") if x.isdigit()))
files = sorted(pathlib.Path("build/app/outputs/flutter-apk").glob("*-release.apk"))
assert len(files) == 3, "Expected arm64, armv7 and x86_64 APKs"
report = []
for apk in files:
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        abis = {name.split("/")[1] for name in names if name.startswith("lib/") and name.endswith(".so")}
        assert len(abis) == 1, f"Mixed architectures in {apk.name}"
        assert any(name.endswith("/libapp.so") for name in names), "Missing AOT application"
        assert not any(name.endswith("kernel_blob.bin") for name in names), "Debug Dart kernel in release"
    manifest = subprocess.check_output([str(aapt), "dump", "badging", str(apk)], text=True)
    assert "application-debuggable" not in manifest, "APK has Android debug enabled"
    report.append({"file": apk.name, "bytes": apk.stat().st_size, "abi": sorted(abis), "debuggable": False})
print("RELEASE_APK_REPORT=" + json.dumps(report))
