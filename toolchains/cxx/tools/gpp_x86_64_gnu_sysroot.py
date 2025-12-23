#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def _check_output(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)
    except FileNotFoundError as exc:
        raise SystemExit(f"g++-gnu-sysroot.py: failed to execute {cmd[0]!r}: {exc}") from exc
    except subprocess.CalledProcessError as exc:
        out = (exc.output or "").strip()
        msg = f"g++-gnu-sysroot.py: command failed: {' '.join(cmd)}"
        if out:
            msg += f"\n{out}"
        raise SystemExit(msg) from exc


def _rust_sysroot() -> Path:
    sysroot = _check_output(
        ["rustc", "+stable-x86_64-pc-windows-gnu", "--print", "sysroot"]
    ).strip()
    if not sysroot:
        raise SystemExit(
            "g++-gnu-sysroot.py: rustc +stable-x86_64-pc-windows-gnu --print sysroot returned empty output"
        )
    return Path(sysroot)


def main() -> int:
    sysroot = _rust_sysroot()
    self_contained = (
        sysroot / "lib" / "rustlib" / "x86_64-pc-windows-gnu" / "lib" / "self-contained"
    )
    if not self_contained.exists():
        raise SystemExit(
            f"g++-gnu-sysroot.py: self-contained dir not found: {self_contained!s}"
        )

    cmd = ["g++", f"-L{self_contained}", *sys.argv[1:]]
    try:
        return subprocess.call(cmd)
    except OSError as exc:
        raise SystemExit(f"g++-gnu-sysroot.py: failed to execute g++: {exc}") from exc


if __name__ == "__main__":
    raise SystemExit(main())
