# SPDX-License-Identifier: MPL-2.0
#
# hex-cat.bzl -- hex_cat rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//rules:types.bzl", "HexInfo")


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
