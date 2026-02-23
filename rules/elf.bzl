# SPDX-License-Identifier: MPL-2.0
#
# elf.bzl -- elf rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "//rules:include.bzl",
    "IncludeInfo",
    "IncludeTSet",
)
load("//rules:object.bzl", "ObjectInfo")
load("//toolchains:rules.bzl", "LdToolchainInfo")


def _elf_impl(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.attrs.out

    if out == None:
        out = ctx.label.name

        if not out.endswith(".elf"):
            out += ".elf"

    out = ctx.actions.declare_output(out)

    include_paths = [include[IncludeInfo].paths for include in ctx.attrs.includes]
    objects = [object[ObjectInfo].object for object in ctx.attrs.objects]

    linker = ctx.attrs.linker[LdToolchainInfo]

    include_prefix = linker.include_prefix

    if len(include_paths) and not include_prefix:
        fail("include paths specified but target doesn't specify an include prefix")

    include_paths = ctx.actions.tset(IncludeTSet, children=include_paths)
    include_flags = include_paths.project_as_args(include_prefix, ordering="postorder")

    tool = ctx.attrs.linker[RunInfo].args
    script = ctx.attrs.script

    cmd = cmd_args(
        tool,
        linker.elf_flags,
        linker.script_flag,
        script,
        include_flags,
        objects,
        linker.output_flag,
        out.as_output(),
    )

    ctx.actions.run(cmd, category="elf")

    return [
        DefaultInfo(default_output=out),
    ]


elf = rule(
    impl=_elf_impl,
    attrs={
        "out": attrs.option(attrs.source(), default=None),
        "script": attrs.source(),
        "includes": attrs.list(attrs.dep(providers=[IncludeInfo]), default=[]),
        "objects": attrs.list(attrs.dep(providers=[ObjectInfo]), default=[]),
        "linker": attrs.toolchain_dep(
            providers=[LdToolchainInfo],
            default="//toolchains:ld",
        ),
    },
)
