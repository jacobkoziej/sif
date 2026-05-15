# SPDX-License-Identifier: MPL-2.0
#
# xip-elf.bzl -- XIP ELF rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//rules:elf.bzl", "ElfInfo")


def _xip_elf_impl(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.attrs.out

    if out == None:
        out = ctx.label.name

        if not out.endswith(".elf"):
            out += ".elf"

    out = ctx.actions.declare_output(out)

    xip_elf = ctx.attrs.xip_elf[RunInfo].args

    cmd = cmd_args(
        xip_elf,
        "--output",
        out.as_output(),
        ctx.attrs.elf[ElfInfo].elf,
    )

    if ctx.attrs.ehdr != None:
        cmd.add("--ehdr", ctx.attrs.ehdr)

    if ctx.attrs.phdrs != None:
        cmd.add("--phdrs", ctx.attrs.phdrs)

    ctx.actions.run(cmd, category="xip_elf")

    return [
        DefaultInfo(
            default_output=out,
        ),
        ElfInfo(
            elf=out,
        ),
    ]


xip_elf = rule(
    impl=_xip_elf_impl,
    attrs={
        "elf": attrs.dep(providers=[ElfInfo]),
        "out": attrs.option(attrs.string(), default=None),
        "ehdr": attrs.option(attrs.string(), default=None),
        "phdrs": attrs.option(attrs.string(), default=None),
        "xip_elf": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="//tools:xip-elf",
            ),
        ),
    },
)
