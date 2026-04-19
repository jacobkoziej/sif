# SPDX-License-Identifier: MPL-2.0
#
# object.bzl -- object rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "//rules:include.bzl",
    "IncludeInfo",
    "IncludeTSet",
)
load("//toolchains:rules.bzl", "AsToolchainInfo")
load("//utils:dict.bzl", "obj_to_dict")

_object_providers: list[typing.Any] = [
    AsToolchainInfo,
]

object_toolchains: dict[str, str] = {
    ".s": "//toolchains:as",
}

_object_field_attrs: dict[str, Attr] = {
    "object_flags": attrs.list(attrs.string()),
    "include_prefix": attrs.option(attrs.string(), default=None),
    "output_flag": attrs.string(),
}

_object_attrs: dict[str, Attr] = {
    "src": attrs.source(),
    "out": attrs.option(attrs.string(), default=None),
    "flags": attrs.list(attrs.string(), default=[]),
    "includes": attrs.list(attrs.dep(providers=[IncludeInfo]), default=[]),
}

ObjectInfo = provider(
    fields={
        "object": provider_field(Artifact),
    },
)


def _emit_object_impl(ctx: AnalysisContext) -> list[Provider]:
    src = ctx.attrs.src
    out = ctx.attrs.out

    extension = src.extension

    if out == None:
        out = src.basename.removesuffix(extension) + ".o"

    out = ctx.actions.declare_output(out)

    include_paths = [include[IncludeInfo].paths for include in ctx.attrs.includes]

    include_prefix = ctx.attrs.include_prefix

    if len(include_paths) and not include_prefix:
        fail("include paths specified but toolchain doesn't specify an include prefix")

    include_paths = ctx.actions.tset(IncludeTSet, children=include_paths)
    include_flags = include_paths.project_as_args(include_prefix, ordering="postorder")

    tool = ctx.attrs.toolchain[RunInfo].args

    cmd = cmd_args(
        tool,
        ctx.attrs.object_flags,
        include_flags,
        ctx.attrs.output_flag,
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
    | _object_field_attrs
    | {
        "toolchain": attrs.dep(providers=[RunInfo]),
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

    object_providers = [
        toolchain[provider]
        for provider in _object_providers
        if toolchain.get(provider) != None
    ]

    if len(object_providers) != 1:
        fail(
            "toolchain `{}` must specify only one object provider but found: {}".format(
                toolchain, object_providers
            )
        )

    object_provider = object_providers.pop()

    out = ctx.actions.anon_target(
        emit_object,
        obj_to_dict(ctx.attrs, _object_attrs.keys())
        | obj_to_dict(object_provider, _object_field_attrs.keys())
        | {
            "toolchain": toolchain,
        },
    ).artifact("object")

    return [
        DefaultInfo(
            default_output=out,
        ),
        ObjectInfo(
            object=out,
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
