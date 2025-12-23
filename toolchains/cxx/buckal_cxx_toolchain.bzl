# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is dual-licensed under either the MIT license found in the
# LICENSE-MIT file in the root directory of this source tree or the Apache
# License, Version 2.0 found in the LICENSE-APACHE file in the root directory
# of this source tree. You may select, at your option, one of the
# above-listed licenses.

load("@prelude//decls:common.bzl", "buck")
load("@prelude//os_lookup:defs.bzl", "OsLookup")
load("@prelude//toolchains:cxx.bzl", "CxxToolsInfo", "cxx_tools_info_toolchain")

def _tool_or_value(tool, value, name):
    if tool != None and value != None:
        fail("buckal_cxx_tools: {} and {}_tool are mutually exclusive".format(name, name))
    if tool != None:
        return cmd_args(tool[RunInfo])
    return value

def _override_windows(default, override, default_value):
    if override == None:
        return default
    if type(override) == "string" and override == default_value:
        return default
    return override

def _override_non_windows(default, override):
    return default if override == None else override

def _buckal_cxx_tools_impl(ctx: AnalysisContext) -> list[Provider]:
    base = ctx.attrs.base[CxxToolsInfo]
    os = ctx.attrs._target_os_type[OsLookup].os.value

    compiler_override = _tool_or_value(ctx.attrs.compiler_tool, ctx.attrs.compiler, "compiler")
    cxx_compiler_override = _tool_or_value(ctx.attrs.cxx_compiler_tool, ctx.attrs.cxx_compiler, "cxx_compiler")
    linker_override = _tool_or_value(ctx.attrs.linker_tool, ctx.attrs.linker, "linker")
    archiver_override = _tool_or_value(ctx.attrs.archiver_tool, ctx.attrs.archiver, "archiver")
    rc_compiler_override = _tool_or_value(ctx.attrs.rc_compiler_tool, ctx.attrs.rc_compiler, "rc_compiler")
    cvtres_compiler_override = _tool_or_value(ctx.attrs.cvtres_compiler_tool, ctx.attrs.cvtres_compiler, "cvtres_compiler")

    compiler_type = base.compiler_type if ctx.attrs.compiler_type == None else ctx.attrs.compiler_type

    if os == "windows":
        compiler = _override_windows(base.compiler, compiler_override, "cl.exe")
        cxx_compiler = _override_windows(base.cxx_compiler, compiler_override, "cl.exe")
        asm_compiler = base.asm_compiler
        asm_compiler_type = base.asm_compiler_type
        rc_compiler = _override_windows(base.rc_compiler, rc_compiler_override, "rc.exe")
        cvtres_compiler = _override_windows(base.cvtres_compiler, cvtres_compiler_override, "cvtres.exe")
        archiver = _override_windows(base.archiver, archiver_override, "lib.exe")
        linker = _override_windows(base.linker, linker_override, "link.exe")
    else:
        compiler = _override_non_windows(base.compiler, compiler_override)
        cxx_compiler = _override_non_windows(base.cxx_compiler, cxx_compiler_override)
        asm_compiler = base.asm_compiler if compiler_override == None else compiler
        asm_compiler_type = base.asm_compiler_type if ctx.attrs.compiler_type == None else compiler_type
        rc_compiler = _override_non_windows(base.rc_compiler, rc_compiler_override)
        cvtres_compiler = _override_non_windows(base.cvtres_compiler, cvtres_compiler_override)
        archiver = _override_non_windows(base.archiver, archiver_override)
        linker = _override_non_windows(base.linker, linker_override)

    return [
        DefaultInfo(),
        CxxToolsInfo(
            compiler = compiler,
            compiler_type = compiler_type,
            cxx_compiler = cxx_compiler,
            asm_compiler = asm_compiler,
            asm_compiler_type = asm_compiler_type,
            rc_compiler = rc_compiler,
            cvtres_compiler = cvtres_compiler,
            archiver = archiver,
            archiver_type = base.archiver_type,
            linker = linker,
            linker_type = base.linker_type,
        ),
    ]

buckal_cxx_tools = rule(
    impl = _buckal_cxx_tools_impl,
    attrs = {
        "archiver": attrs.option(attrs.string(), default = None),
        "archiver_tool": attrs.option(attrs.exec_dep(providers = [RunInfo]), default = None),
        "compiler": attrs.option(attrs.string(), default = None),
        "compiler_tool": attrs.option(attrs.exec_dep(providers = [RunInfo]), default = None),
        "compiler_type": attrs.option(attrs.string(), default = None),
        "cvtres_compiler": attrs.option(attrs.string(), default = None),
        "cvtres_compiler_tool": attrs.option(attrs.exec_dep(providers = [RunInfo]), default = None),
        "cxx_compiler": attrs.option(attrs.string(), default = None),
        "cxx_compiler_tool": attrs.option(attrs.exec_dep(providers = [RunInfo]), default = None),
        "linker": attrs.option(attrs.string(), default = None),
        "linker_tool": attrs.option(attrs.exec_dep(providers = [RunInfo]), default = None),
        "rc_compiler": attrs.option(attrs.string(), default = None),
        "rc_compiler_tool": attrs.option(attrs.exec_dep(providers = [RunInfo]), default = None),
        "base": attrs.exec_dep(
            providers = [CxxToolsInfo],
            default = select({
                "DEFAULT": "prelude//toolchains/cxx/clang:path_clang_tools",
                "config//os:windows": "prelude//toolchains/msvc:msvc_tools",
            }),
        ),
        "_target_os_type": buck.target_os_type_arg(),
    },
)

def buckal_system_cxx_toolchain(name, visibility = None, **kwargs):
    tools_name = name + "_tools"
    tool_kwargs = {}
    for key in [
        "archiver",
        "archiver_tool",
        "compiler",
        "compiler_tool",
        "compiler_type",
        "cvtres_compiler",
        "cvtres_compiler_tool",
        "cxx_compiler",
        "cxx_compiler_tool",
        "linker",
        "linker_tool",
        "rc_compiler",
        "rc_compiler_tool",
    ]:
        if key in kwargs:
            tool_kwargs[key] = kwargs.pop(key)

    if "base" in kwargs:
        tool_kwargs["base"] = kwargs.pop("base")

    buckal_cxx_tools(
        name = tools_name,
        visibility = visibility,
        **tool_kwargs
    )

    cxx_tools_info_toolchain(
        name = name,
        cxx_tools_info = ":" + tools_name,
        visibility = visibility,
        **kwargs
    )
