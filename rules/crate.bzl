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
}

CrateInfo = provider(
    fields={
        "name": provider_field(str),
        "type": provider_field(CrateType),
        "metadata": provider_field(Artifact),
        "out": provider_field(Artifact),
    },
)


def _crate_impl(ctx: AnalysisContext) -> list[Provider]:
    crate_name = ctx.attrs.out_name or ctx.label.name

    crate_type = ctx.attrs.type

    name = crate_name if crate_type == "bin" else "lib" + crate_name

    out = ctx.actions.declare_output(name + _crate_type[crate_type])
    rmeta = ctx.actions.declare_output(name + ".rmeta")
    obj = ctx.actions.declare_output(name + ".o")

    outputs: dict[str, Artifact] = {"metadata": rmeta, "obj": obj} | {
        emit: ctx.actions.declare_output(name + _emit[emit]) for emit in ctx.attrs.emit
    }

    incremental = (
        cmd_args(
            ctx.actions.declare_output("incremental", dir=True).as_output(),
            format="--codegen=incremental={}",
        )
        if ctx.attrs.incremental
        else []
    )

    dep_info = ctx.actions.artifact_tag()

    src_deps = [dep[DefaultInfo].default_outputs[0] for dep in ctx.attrs.src_deps]

    crate_deps = ctx.attrs.deps + ctx.attrs.aliased_deps.values()

    search_paths = get_include(
        actions=ctx.actions,
        includes=get_provider(crate_deps, IncludeInfo),
        prefix="-L",
    )

    externs = [
        cmd_args(dep[CrateInfo].name, dep[CrateInfo].metadata, delimiter="=")
        for dep in ctx.attrs.deps
    ] + [
        cmd_args(name, dep[CrateInfo].metadata, delimiter="=")
        for name, dep in ctx.attrs.aliased_deps.items()
    ]

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
        search_paths.flags,
        [cmd_args(extern, format="--extern={}") for extern in externs],
        [cmd_args(cfg, format="--cfg={}") for cfg in ctx.attrs.cfg],
        [
            cmd_args(feature, format='--cfg=feature="{}"')
            for feature in ctx.attrs.features
        ],
        incremental,
        cmd_args(crate_name, format="--crate-name={}"),
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
            )
        ),
    )

    ctx.actions.run(
        cmd,
        category="crate",
        dep_files={
            "dep-info": dep_info,
        },
        no_outputs_cleanup=ctx.attrs.incremental,
    )

    sub_targets: dict[str, list[Provider]] = {
        target: [DefaultInfo(default_output=output)]
        for target, output in outputs.items()
    }

    return [
        DefaultInfo(
            default_output=out,
            sub_targets=sub_targets,
        ),
        CrateInfo(
            name=crate_name,
            type=CrateType(crate_type),
            metadata=rmeta,
            out=out,
        ),
        ObjectInfo(
            objects=ctx.actions.tset(
                ObjectTSet,
                value=obj,
                children=[dep[ObjectInfo].objects for dep in crate_deps],
            ),
        ),
        IncludeInfo(
            paths=ctx.actions.tset(
                IncludeTSet,
                value=cmd_args(out.as_output(), parent=1),
            ),
            files=outputs.values(),
        ),
    ]


crate_unwrapped = rule(
    impl=_crate_impl,
    attrs={
        "root": attrs.one_of(attrs.source(), attrs.dep()),
        "srcs": attrs.list(attrs.source(), default=[]),
        "src_deps": attrs.list(attrs.dep(), default=[]),
        "deps": attrs.list(
            attrs.dep(
                providers=[
                    CrateInfo,
                    IncludeInfo,
                    ObjectInfo,
                ],
            ),
            default=[],
        ),
        "aliased_deps": attrs.dict(
            key=attrs.string(),
            value=attrs.dep(
                providers=[
                    CrateInfo,
                    IncludeInfo,
                    ObjectInfo,
                ],
            ),
            default={},
        ),
        "out_name": attrs.option(attrs.string(), default=None),
        "type": attrs.enum(_crate_type.keys(), default="rlib"),
        "emit": attrs.list(attrs.enum(_emit.keys()), default=[]),
        "cfg": attrs.list(attrs.string(), default=[]),
        "features": attrs.list(attrs.string(), default=[]),
        "flags": attrs.list(attrs.string(), default=[]),
        "incremental": attrs.bool(
            default=select(
                {
                    "//constraints:opt-level[0]": True,
                    "DEFAULT": False,
                },
            ),
        ),
        "rustc": attrs.toolchain_dep(default="//toolchains:rustc"),
        "dep_wrapper": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="//tools:buck2-dep-format",
            ),
        ),
    },
)


def crate(**kwargs: dict[str, typing.Any]) -> None:
    kwargs["deps"] = [
        "//vendor:core",
        "//vendor:compiler_builtins",
    ] + kwargs.get("deps", [])

    crate_unwrapped(**kwargs)
