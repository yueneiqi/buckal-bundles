#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def _check_output(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)
    except FileNotFoundError as exc:
        raise SystemExit(f"lld_link.py: failed to execute {cmd[0]!r}: {exc}") from exc
    except subprocess.CalledProcessError as exc:
        out = (exc.output or "").strip()
        msg = f"lld_link.py: command failed: {' '.join(cmd)}"
        if out:
            msg += f"\n{out}"
        raise SystemExit(msg) from exc


def _rust_sysroot() -> Path:
    sysroot = _check_output(["rustc", "--print", "sysroot"]).strip()
    if not sysroot:
        raise SystemExit("lld_link.py: rustc --print sysroot returned empty output")
    return Path(sysroot)


def _rust_host_triple() -> str:
    out = _check_output(["rustc", "-vV"])
    for line in out.splitlines():
        if line.startswith("host:"):
            return line.split(":", 1)[1].strip()
    raise SystemExit("lld_link.py: failed to determine Rust host triple via rustc -vV")


def _find_lld_link(sysroot: Path, host_triple: str) -> Path:
    candidates = [
        sysroot / "lib" / "rustlib" / host_triple / "bin" / "gcc-ld" / "lld-link.exe",
        sysroot / "bin" / "rust-lld.exe",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise SystemExit(f"lld_link.py: lld-link executable not found under {sysroot!s}")


def _has_machine_flag(args: list[str]) -> bool:
    for arg in args:
        lowered = arg.lower()
        if lowered.startswith("/machine:") or lowered.startswith("-machine:"):
            return True
    return False


def main() -> int:
    argv = sys.argv[1:]
    machine = os.environ.get("BUCKAL_LLD_LINK_MACHINE", "").strip().upper()

    sysroot = _rust_sysroot()
    host_triple = _rust_host_triple()
    lld_link = _find_lld_link(sysroot, host_triple)

    cmd = [str(lld_link)]
    if machine and not _has_machine_flag(argv):
        cmd.append(f"/machine:{machine}")
    cmd.extend(argv)

    try:
        return subprocess.call(cmd)
    except OSError as exc:
        raise SystemExit(f"lld_link.py: failed to execute {lld_link!s}: {exc}") from exc


if __name__ == "__main__":
    raise SystemExit(main())
