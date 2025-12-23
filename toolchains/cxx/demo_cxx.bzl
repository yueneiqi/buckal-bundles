# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is dual-licensed under either the MIT license found in the
# LICENSE-MIT file in the root directory of this source tree or the Apache
# License, Version 2.0 found in the LICENSE-APACHE file in the root directory
# of this source tree. You may select, at your option, one of the
# above-listed licenses.

load("@buckal//config/toolchains/cxx:buckal_cxx_toolchain.bzl", "buckal_system_cxx_toolchain")
load(
    "@prelude//toolchains:python.bzl",
    "system_python_bootstrap_toolchain",
    "system_python_toolchain",
)
load("@prelude//toolchains:genrule.bzl", "system_genrule_toolchain")

def system_demo_cxx_toolchain():
    # Override the demo toolchains so we can avoid forcing `-fuse-ld=lld`.
    # The bundled demo cxx toolchain uses clang++ and adds `-fuse-ld=lld` on Linux,
    # but some environments don't have lld installed. We also guard Linux cross
    # compiler selection by OS so this file works on macOS/Windows too.
    buckal_system_cxx_toolchain(
        name = "cxx",
        compiler = select({
            "prelude//os/constraints:linux": select({
                "prelude//cpu/constraints:arm64": "aarch64-linux-gnu-gcc",
                "prelude//cpu/constraints:x86_32": "i686-linux-gnu-gcc",
                "DEFAULT": "gcc",
            }),
            "prelude//os/constraints:macos": "clang",
            "prelude//os/constraints:windows": select({
                "prelude//abi/constraints:gnu": "gcc",
                "DEFAULT": "cl.exe",
            }),
            "DEFAULT": "cc",
        }),
        # Keep `g++` as the C++ compiler on Linux so the prelude doesn't inject
        # `-fuse-ld=lld` (lld isn't guaranteed to exist). Other OSes use their
        # native compilers.
        cxx_compiler = select({
            "prelude//os/constraints:linux": select({
                "prelude//cpu/constraints:arm64": "aarch64-linux-gnu-g++",
                "prelude//cpu/constraints:x86_32": "i686-linux-gnu-g++",
                "DEFAULT": "g++",
            }),
            "prelude//os/constraints:macos": "clang++",
            "prelude//os/constraints:windows": select({
                "prelude//abi/constraints:gnu": "g++",
                "DEFAULT": "cl.exe",
            }),
            "DEFAULT": "c++",
        }),
        linker = select({
            "prelude//os/constraints:linux": select({
                "prelude//cpu/constraints:arm64": "aarch64-linux-gnu-g++",
                "prelude//cpu/constraints:x86_32": "i686-linux-gnu-g++",
                "DEFAULT": "g++",
            }),
            "prelude//os/constraints:macos": "clang++",
            "prelude//os/constraints:windows": None,
            "DEFAULT": "c++",
        }),
        linker_tool = select({
            "prelude//os/constraints:windows": select({
                # MSVC targets: use Rust's bundled lld-link for non-x86_64 targets.
                # This avoids relying on prelude's `msvc_tools` paths (which currently
                # assume x64-hosted MSVC bin/lib layouts).
                "prelude//abi/constraints:msvc": select({
                    "prelude//cpu/constraints:arm64": "buckal//config/toolchains/cxx/tools:lld-link-aarch64",
                    "prelude//cpu/constraints:x86_32": "buckal//config/toolchains/cxx/tools:lld-link-i686",
                    "DEFAULT": None,
                }),
                # GNU targets must use a GNU-like driver; link.exe uses MSVC flag syntax.
                "prelude//abi/constraints:gnu": "buckal//config/toolchains/cxx/tools:g++-x86_64-gnu-sysroot",
                "DEFAULT": select({
                    "prelude//cpu/constraints:arm64": "buckal//config/toolchains/cxx/tools:lld-link-aarch64",
                    "prelude//cpu/constraints:x86_32": "buckal//config/toolchains/cxx/tools:lld-link-i686",
                    "DEFAULT": None,
                }),
            }),
            "DEFAULT": None,
        }),
        # Buck prelude's system C++ toolchain injects `-fuse-ld=lld` into the
        # linker wrapper. Some environments don't ship `ld.lld`,
        # so append `-fuse-ld=bfd` to override it for Linux targets.
        link_flags = select({
            "prelude//os/constraints:linux": ["-fuse-ld=bfd"],
            "DEFAULT": [],
        }),
        visibility = ["PUBLIC"],
    )

    system_python_bootstrap_toolchain(
        name = "python_bootstrap",
        visibility = ["PUBLIC"],
    )

    system_python_toolchain(
        name = "python",
        visibility = ["PUBLIC"],
    )

    system_genrule_toolchain(
        name = "genrule",
        visibility = ["PUBLIC"],
    )
