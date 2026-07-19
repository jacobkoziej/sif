# SPDX-License-Identifier: MPL-2.0
#
# crate.bzl -- crate rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load(
    "@sif//rules:include.bzl",
    "IncludeInfo",
    "IncludeTSet",
    "get_include",
)
load(
    "@sif//rules:object.bzl",
    "ObjectInfo",
    "ObjectTSet",
)
load("@sif//toolchains:rustc.bzl", "RustcToolchainInfo")
load("@sif//utils:provider.bzl", "get_provider")

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


def _crate_name(ctx: AnalysisContext) -> str:
    return ctx.attrs.crate_name or ctx.label.name


def _output_name(ctx: AnalysisContext) -> str:
    crate_name = _crate_name(ctx)

    if ctx.attrs.type == "bin":
        return crate_name

    return "lib" + crate_name


def _resolve_root(ctx: AnalysisContext) -> Artifact:
    root = ctx.attrs.root

    if isinstance(root, Dependency):
        root = root[DefaultInfo].default_outputs[0]

    return root


def _crate_deps(ctx: AnalysisContext) -> list[Dependency]:
    return ctx.attrs.deps + ctx.attrs.aliased_deps.values()


def _externs(ctx: AnalysisContext) -> list[cmd_args]:
    return [
        cmd_args(dep[CrateInfo].name, dep[CrateInfo].metadata, delimiter="=")
        for dep in ctx.attrs.deps
    ] + [
        cmd_args(name, dep[CrateInfo].metadata, delimiter="=")
        for name, dep in ctx.attrs.aliased_deps.items()
    ]


def _incremental_arg(ctx: AnalysisContext, category: str) -> cmd_args:
    if not ctx.attrs.incremental:
        return cmd_args()

    return cmd_args(
        ctx.actions.declare_output(category + "-incremental", dir=True).as_output(),
        format="--codegen=incremental={}",
    )


def _crate_flags(ctx: AnalysisContext) -> cmd_args:
    search_paths = get_include(
        actions=ctx.actions,
        includes=get_provider(_crate_deps(ctx), IncludeInfo),
        prefix="-L",
    )

    return cmd_args(
        search_paths.flags,
        [cmd_args(extern, format="--extern={}") for extern in _externs(ctx)],
        [cmd_args(cfg, format="--cfg={}") for cfg in ctx.attrs.cfg],
        [
            cmd_args(feature, format='--cfg=feature="{}"')
            for feature in ctx.attrs.features
        ],
        cmd_args(_crate_name(ctx), format="--crate-name={}"),
    )


def _run_tool(
    ctx: AnalysisContext,
    *,
    category: str,
    type: str | None,
    out: Artifact,
    emits: dict[str, Artifact],
    extra_args: cmd_args = cmd_args(),
) -> None:
    dep_info = ctx.actions.artifact_tag()
    dep_file = ctx.actions.declare_output(category + ".d").as_output()

    src_deps = [dep[DefaultInfo].default_outputs[0] for dep in ctx.attrs.src_deps]

    cmd = cmd_args(
        ctx.attrs.dep_wrapper[RunInfo].args,
        "--input",
        dep_info.tag_artifacts(dep_file),
        "--target",
        out.as_output(),
        "--",
        ctx.attrs.rustc[RunInfo].args,
        _crate_flags(ctx),
        _incremental_arg(ctx, category),
        cmd_args(type, format="--crate-type={}") if type else cmd_args(),
        cmd_args(dep_file, format="--emit=dep-info={}"),
        [
            cmd_args(
                cmd_args(emit, out.as_output(), delimiter="="),
                format="--emit={}",
            )
            for (emit, out) in emits.items()
        ],
        cmd_args(out.as_output(), format="--emit=link"),
        "-o",
        out.as_output(),
        dep_info.tag_artifacts(_resolve_root(ctx)),
        extra_args,
        hidden=dep_info.tag_artifacts(
            cmd_args(
                ctx.attrs.srcs,
                src_deps,
            )
        ),
    )

    ctx.actions.run(
        cmd,
        category=category,
        dep_files={
            "dep-info": dep_info,
        },
        no_outputs_cleanup=ctx.attrs.incremental,
    )


def _rlib(ctx: AnalysisContext) -> (Artifact, dict[str, Artifact]):
    out_name = _output_name(ctx)
    crate_type = ctx.attrs.type

    out = ctx.actions.declare_output(out_name + _crate_type[crate_type])
    rmeta = ctx.actions.declare_output(out_name + ".rmeta")
    obj = ctx.actions.declare_output(out_name + ".o")

    emits: dict[str, Artifact] = {"metadata": rmeta, "obj": obj} | {
        emit: ctx.actions.declare_output(out_name + _emit[emit])
        for emit in ctx.attrs.emit
    }

    _run_tool(
        ctx,
        category="crate",
        type=crate_type,
        out=out,
        emits=emits,
    )

    return out, emits


def _docs(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.actions.declare_output("docs", dir=True)

    src_deps = [dep[DefaultInfo].default_outputs[0] for dep in ctx.attrs.src_deps]

    cmd = cmd_args(
        ctx.attrs.rustc[RustcToolchainInfo].rustdoc.args,
        _crate_flags(ctx),
        cmd_args(out.as_output(), format="--out-dir={}"),
        _resolve_root(ctx),
        hidden=cmd_args(
            ctx.attrs.srcs,
            src_deps,
        ),
    )

    ctx.actions.run(
        cmd,
        category="crate_docs",
    )

    return [
        DefaultInfo(
            default_output=out,
        ),
    ]


def _tests(ctx: AnalysisContext) -> list[Provider]:
    out = ctx.actions.declare_output(_crate_name(ctx) + "-tests")

    _run_tool(
        ctx,
        category="crate_test",
        type=None,
        out=out,
        emits={},
        extra_args=cmd_args(
            "--test",
        ),
    )

    return [
        DefaultInfo(
            default_output=out,
        ),
        RunInfo(
            args=cmd_args(out),
        ),
        ExternalRunnerTestInfo(
            type="rust",
            command=[out],
        ),
    ]


def _crate_impl(ctx: AnalysisContext) -> list[Provider]:
    crate_name = _crate_name(ctx)
    crate_deps = _crate_deps(ctx)

    out, emits = _rlib(ctx)

    sub_targets: dict[str, list[Provider]] = {
        target: [DefaultInfo(default_output=output)] for target, output in emits.items()
    }

    sub_targets["docs"] = _docs(ctx)

    if ctx.attrs.unit_tests:
        sub_targets["tests"] = _tests(ctx)

    return [
        DefaultInfo(
            default_output=out,
            sub_targets=sub_targets,
        ),
        CrateInfo(
            name=crate_name,
            type=CrateType(ctx.attrs.type),
            metadata=emits["metadata"],
            out=out,
        ),
        ObjectInfo(
            objects=ctx.actions.tset(
                ObjectTSet,
                value=emits["obj"],
                children=[dep[ObjectInfo].objects for dep in crate_deps],
            ),
        ),
        IncludeInfo(
            paths=ctx.actions.tset(
                IncludeTSet,
                value=cmd_args(out.as_output(), parent=1),
            ),
            files=emits.values(),
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
        "crate_name": attrs.option(attrs.string(), default=None),
        "type": attrs.enum(_crate_type.keys(), default="rlib"),
        "emit": attrs.list(attrs.enum(_emit.keys()), default=[]),
        "cfg": attrs.list(attrs.string(), default=[]),
        "features": attrs.list(attrs.string(), default=[]),
        "flags": attrs.list(attrs.string(), default=[]),
        "incremental": attrs.bool(
            default=select(
                {
                    "sif//constraints:opt-level[0]": True,
                    "DEFAULT": False,
                },
            ),
        ),
        "unit_tests": attrs.bool(
            default=select(
                {
                    "sif//constraints:os[sif]": False,
                    "DEFAULT": True,
                }
            ),
        ),
        "rustc": attrs.toolchain_dep(
            providers=[RunInfo, RustcToolchainInfo],
            default="sif//toolchains:rustc",
        ),
        "dep_wrapper": attrs.default_only(
            attrs.exec_dep(
                providers=[RunInfo],
                default="sif//tools:buck2-dep-format",
            ),
        ),
    },
)


def crate(**kwargs: dict[str, typing.Any]) -> None:
    disable_sysroot = "sif//constraints/rust:disable-sysroot"

    kwargs["deps"] = select(
        {
            (disable_sysroot + "[true]"): [
                "sif//vendor:core",
                "sif//vendor:compiler_builtins",
            ],
            (disable_sysroot + "[false]"): [],
        }
    ) + kwargs.get("deps", [])

    crate_unwrapped(**kwargs)
