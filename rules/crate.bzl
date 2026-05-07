# SPDX-License-Identifier: MPL-2.0
#
# crate.bzl -- crate rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "//rules:include.bzl",
    "IncludeInfo",
    "IncludeTSet",
    "get_include",
)
load(
    "//rules:object.bzl",
    "ObjectInfo",
    "ObjectTSet",
)
load("//utils:provider.bzl", "get_provider")

_crate_type: dict[str, str] = {
    "bin": ".elf",
    "cdylib": ".so",
    "dylib": ".so",
    "proc-macro": ".so",
    "rlib": ".rlib",
    "staticlib": ".a",
}

CrateType = enum(*_crate_type.keys())

_emit: dict[str, str] = {
    "asm": ".s",
    "llvm-bc": ".bc",
    "llvm-ir": ".ll",
    "mir": ".mir",
    "obj": ".o",
}

CrateInfo = provider(
    fields={
        "type": provider_field(CrateType),
        "metadata": provider_field(Artifact),
        "out": provider_field(Artifact),
    },
)


def _crate_impl(ctx: AnalysisContext) -> list[Provider]:
    name = ctx.attrs.out_name or ctx.label.name

    crate_type = ctx.attrs.type

    out = ctx.actions.declare_output(name + _crate_type[crate_type])
    rmeta = ctx.actions.declare_output(name + ".rmeta")

    outputs: dict[str, Artifact] = {
        "metadata": rmeta,
    } | {
        emit: ctx.actions.declare_output(name + _emit[emit]) for emit in ctx.attrs.emit
    }

    dep_info = ctx.actions.artifact_tag()

    include = get_include(
        actions=ctx.actions,
        includes=get_provider(ctx.attrs.includes, IncludeInfo),
        prefix="-L",
    )

    src_deps = [dep[DefaultInfo].default_outputs[0] for dep in ctx.attrs.src_deps]

    root = ctx.attrs.root

    if isinstance(root, Dependency):
        root = root[DefaultInfo].default_outputs[0]

    dep_file = ctx.actions.declare_output(name + ".d").as_output()

    dep_wrapper = ctx.attrs.dep_wrapper[RunInfo].args
    rustc = ctx.attrs.rustc[RunInfo].args

    cmd = cmd_args(
        dep_wrapper,
        "--input",
        dep_info.tag_artifacts(dep_file),
        "--target",
        out.as_output(),
        "--",
        rustc,
        include.flags,
        cmd_args(name, format="--crate-name={}"),
        cmd_args(crate_type, format="--crate-type={}"),
        cmd_args(dep_file, format="--emit=dep-info={}"),
        [
            cmd_args(
                cmd_args(emit, out.as_output(), delimiter="="),
                format="--emit={}",
            )
            for (emit, out) in outputs.items()
        ],
        cmd_args(out.as_output(), format="--emit=link"),
        "-o",
        out.as_output(),
        dep_info.tag_artifacts(root),
        hidden=dep_info.tag_artifacts(
            cmd_args(
                ctx.attrs.srcs,
                src_deps,
                include.files,
            )
        ),
    )

    ctx.actions.run(
        cmd,
        category="crate",
        dep_files={
            "dep-info": dep_info,
        },
    )

    sub_targets: dict[str, list[Provider]] = {
        target: [DefaultInfo(default_output=output)]
        for target, output in outputs.items()
    }

    if "obj" in outputs:
        sub_targets["obj"].append(
            ObjectInfo(
                objects=ctx.actions.tset(
                    ObjectTSet,
                    value=outputs["obj"],
                ),
            ),
        )

    return [
        DefaultInfo(
            default_output=out,
            sub_targets=sub_targets,
        ),
        CrateInfo(
            type=CrateType(crate_type),
            metadata=rmeta,
            out=out,
        ),
        IncludeInfo(
            paths=ctx.actions.tset(
                IncludeTSet,
                value=cmd_args(out.as_output(), parent=1),
            ),
            files=outputs.values(),
        ),
    ]


crate = rule(
    impl=_crate_impl,
    attrs={
        "root": attrs.one_of(attrs.source(), attrs.dep()),
        "srcs": attrs.list(attrs.source(), default=[]),
        "src_deps": attrs.list(attrs.dep(), default=[]),
        "out_name": attrs.option(attrs.string(), default=None),
        "type": attrs.enum(_crate_type.keys(), default="rlib"),
        "emit": attrs.list(attrs.enum(_emit.keys()), default=[]),
        "flags": attrs.list(attrs.string(), default=[]),
        "includes": attrs.list(attrs.dep(providers=[IncludeInfo]), default=[]),
        "rustc": attrs.toolchain_dep(default="//toolchains:rustc"),
        "dep_wrapper": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="//tools:buck2-dep-format",
            ),
        ),
    },
)
