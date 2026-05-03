# SPDX-License-Identifier: MPL-2.0
#
# hex.bzl -- hex rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//rules:elf.bzl", "ElfInfo")

HexInfo = provider(
    fields={
        "hex": provider_field(Artifact),
    },
)


def _hex_cat_impl(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.attrs.out

    if out == None:
        out = ctx.label.name

        if not out.endswith(".hex"):
            out += ".hex"

    out = ctx.actions.declare_output(out)

    srec_cat = ctx.attrs.srec_cat[RunInfo].args

    cmd = cmd_args(
        srec_cat,
        [cmd_args(hex[HexInfo].hex, "-Intel") for hex in ctx.attrs.hexes],
        "-Output",
        out.as_output(),
        "-Intel",
    )

    ctx.actions.run(cmd, category="hex_cat")

    return [
        DefaultInfo(
            default_output=out,
        ),
        HexInfo(
            hex=out,
        ),
    ]


hex_cat = rule(
    impl=_hex_cat_impl,
    attrs={
        "hexes": attrs.list(attrs.dep(providers=[HexInfo])),
        "out": attrs.option(attrs.string(), default=None),
        "srec_cat": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="//tools:srec_cat",
            ),
        ),
    },
)


def _to_hex_impl(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.attrs.out

    if out == None:
        out = ctx.label.name

        if not out.endswith(".hex"):
            out += ".hex"

    out = ctx.actions.declare_output(out)

    objcopy = ctx.attrs.objcopy[RunInfo].args

    cmd = cmd_args(
        objcopy,
        "--output-target=ihex",
        ctx.attrs.input[ElfInfo].elf,
        out.as_output(),
    )

    ctx.actions.run(cmd, category="to_hex")

    return [
        DefaultInfo(
            default_output=out,
        ),
        HexInfo(
            hex=out,
        ),
    ]


to_hex = rule(
    impl=_to_hex_impl,
    attrs={
        "input": attrs.dep(providers=[ElfInfo]),
        "out": attrs.option(attrs.string(), default=None),
        "objcopy": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="//tools/llvm:objcopy",
            ),
        ),
    },
)
