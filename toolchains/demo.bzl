# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is dual-licensed under either the MIT license found in the
# LICENSE-MIT file in the root directory of this source tree or the Apache
# License, Version 2.0 found in the LICENSE-APACHE file in the root directory
# of this source tree. You may select, at your option, one of the
# above-listed licenses.

load("@buckal//toolchains/cxx:demo_cxx.bzl", "system_demo_cxx_toolchain")
load("@prelude//toolchains:genrule.bzl", "system_genrule_toolchain")
load(
    "@prelude//toolchains:python.bzl",
    "system_python_bootstrap_toolchain",
    "system_python_toolchain",
)
load("@buckal//toolchains/rust:demo_rust.bzl", "system_demo_rust_toolchain")

def system_demo_toolchains():
    """
    All the default toolchains, suitable for a quick demo or early prototyping.
    Most real projects should copy/paste the implementation to configure them.
    """
    system_demo_cxx_toolchain()
    system_demo_rust_toolchain()

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
