# SPDX-License-Identifier: MPL-2.0
#
# elf.bzl -- elf rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//rules:include.bzl",
    "IncludeInfo",
    "get_include",
)
load("@sif//rules:object.bzl", "ObjectInfo")
load("@sif//toolchains:rules.bzl", "LdToolchainInfo")
load("@sif//utils:provider.bzl", "get_provider")


ElfInfo = provider(
    fields={
        "elf": provider_field(Artifact),
    },
)


def _elf_impl(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.attrs.out

    if out == None:
        out = ctx.label.name

        if not out.endswith(".elf"):
            out += ".elf"

    out = ctx.actions.declare_output(out)

    linker = ctx.attrs.linker[LdToolchainInfo]

    if len(ctx.attrs.includes) and not linker.include_prefix:
        fail("include paths specified but target doesn't specify an include prefix")

    include = get_include(
        actions=ctx.actions,
        includes=get_provider(ctx.attrs.includes, IncludeInfo),
        prefix=linker.include_prefix,
    )

    objects = cmd_args(
        [
            object[ObjectInfo].objects.project_as_args("args")
            for object in ctx.attrs.objects
        ],
    )

    tool = ctx.attrs.linker[RunInfo].args
    script = ctx.attrs.script

    cmd = cmd_args(
        tool,
        linker.elf_flags,
        hidden=include.files,
    )

    include_flags = include.flags

    dep_files = {}

    if linker.dep_file_flag:
        dep_wrapper = ctx.attrs.dep_wrapper[RunInfo].args
        dep_file = ctx.actions.declare_output(out.basename + ".d").as_output()

        cmd = cmd_args(
            dep_wrapper,
            "--input",
            dep_file,
            "--target",
            out.as_output(),
            "--",
            cmd,
        )

        deps_tag = ctx.actions.artifact_tag()

        script = deps_tag.tag_artifacts(script)
        include_flags = deps_tag.tag_artifacts(include_flags)
        objects = deps_tag.tag_artifacts(objects)
        dep_file = deps_tag.tag_artifacts(dep_file)

        cmd.add(cmd_args(dep_file, format=linker.dep_file_flag + "{}"))

        dep_files["deps"] = deps_tag

    cmd.add(
        cmd_args(script, format=linker.script_flag + "{}"),
        include_flags,
        objects,
        linker.output_flag,
        out.as_output(),
    )

    ctx.actions.run(
        cmd,
        category="elf",
        dep_files=dep_files,
    )

    return [
        DefaultInfo(
            default_output=out,
        ),
        ElfInfo(
            elf=out,
        ),
    ]


elf = rule(
    impl=_elf_impl,
    attrs={
        "out": attrs.option(attrs.string(), default=None),
        "script": attrs.source(),
        "includes": attrs.list(attrs.dep(providers=[IncludeInfo]), default=[]),
        "objects": attrs.list(attrs.dep(providers=[ObjectInfo]), default=[]),
        "linker": attrs.toolchain_dep(
            providers=[LdToolchainInfo],
            default="sif//toolchains:ld",
        ),
        "dep_wrapper": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="sif//tools:buck2-dep-format",
            ),
        ),
    },
)
