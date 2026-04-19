# SPDX-License-Identifier: MPL-2.0
#
# xip-elf.bzl -- XIP ELF rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//rules:elf.bzl", "ElfInfo")
load("//rules:types.bzl", "HexInfo")


def _xip_elf_impl(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.attrs.out

    if out == None:
        out = ctx.label.name

        if not out.endswith(".hex"):
            out += ".hex"

    out = ctx.actions.declare_output(out)

    xip_elf = ctx.attrs.xip_elf[RunInfo].args

    cmd = cmd_args(
        xip_elf,
        "--output",
        out.as_output(),
        ctx.attrs.elf[ElfInfo].elf,
    )

    if ctx.attrs.header_address != None:
        cmd.add("--header-address", "0x%x" % ctx.attrs.header_address)

    if ctx.attrs.program_headers_address != None:
        cmd.add("--program-headers-address", "0x%x" % ctx.attrs.program_headers_address)

    ctx.actions.run(cmd, category="xip_elf")

    return [
        DefaultInfo(
            default_output=out,
        ),
        HexInfo(
            hex=out,
        ),
    ]


xip_elf = rule(
    impl=_xip_elf_impl,
    attrs={
        "elf": attrs.dep(providers=[ElfInfo]),
        "out": attrs.option(attrs.string(), default=None),
        "header_address": attrs.option(attrs.int(), default=None),
        "program_headers_address": attrs.option(attrs.int(), default=None),
        "xip_elf": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="//tools:xip-elf",
            ),
        ),
    },
)
