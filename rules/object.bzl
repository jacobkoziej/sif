# SPDX-License-Identifier: MPL-2.0
#
# object.bzl -- object rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//utils:attrs.bzl", "attrs_to_dict")

ObjectEmitterInfo = provider(
    fields={
        "tool": provider_field(RunInfo),
        "flags": provider_field(list[str]),
        "include_prefix": provider_field(str, default="-I"),
        "output_flag": provider_field(str, default="-o"),
    },
)

object_toolchains: dict[str, str] = {
    ".s": "//toolchains:as",
}

_object_attrs: dict[str, Attr] = {
    "src": attrs.source(),
    "out": attrs.option(attrs.source(), default=None),
    "flags": attrs.list(attrs.string(), default=[]),
}


def _emit_object_impl(ctx: AnalysisContext) -> list[Provider]:
    toolchain = ctx.attrs.toolchain

    emitter = toolchain.get(ObjectEmitterInfo)

    if emitter == None:
        fail(
            "toolchain `{}` does not provide `ObjectEmitterInfo`",
            toolchain,
        )

    src = ctx.attrs.src
    out = ctx.attrs.out

    extension = src.extension

    if out == None:
        out = src.short_path.removesuffix(extension) + ".o"

    out = ctx.actions.declare_output(out)

    cmd = cmd_args(
        emitter.tool,
        emitter.flags,
        ctx.attrs.flags,
        emitter.output_flag,
        out.as_output(),
        src,
    )

    ctx.actions.run(cmd, category="object")

    return [
        DefaultInfo(
            default_output=out,
        ),
    ]


emit_object = anon_rule(
    impl=_emit_object_impl,
    attrs=_object_attrs
    | {
        "toolchain": attrs.dep(),
    },
    artifact_promise_mappings={
        "object": lambda x: x[DefaultInfo].default_outputs[0],
    },
)


def _object_impl(ctx: AnalysisContext) -> list[Provider]:
    src = ctx.attrs.src

    extension = src.extension

    if extension not in ctx.attrs.toolchains:
        fail("no object toolchain for extension: `{}`".format(extension))

    toolchain = ctx.attrs.toolchains[extension]

    out = ctx.actions.anon_target(
        emit_object,
        attrs_to_dict(ctx.attrs, _object_attrs.keys())
        | {
            "toolchain": toolchain,
        },
    ).artifact("object")

    return [
        DefaultInfo(
            default_output=out,
        ),
    ]


object = rule(
    impl=_object_impl,
    attrs=_object_attrs
    | {
        "toolchains": attrs.dict(
            key=attrs.string(),
            value=attrs.toolchain_dep(),
            default=object_toolchains,
        ),
    },
)
