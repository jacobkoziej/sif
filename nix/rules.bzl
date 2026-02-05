# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- nix rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Mercury Technologies and Tweag.
# <https://github.com/tweag/buck2.nix/blob/038b031b84846101030b9d081445003e82e3be5c/flake.bzl>

_common_attrs: dict[str, Attr] = {
    "flake": attrs.string(),
    "system": attrs.option(attrs.string(), default=None),
    "derivation": attrs.list(attrs.string()),
    "output": attrs.string(default="out"),
    "flake_lock": attrs.source(allow_directory=True, default="//:flake.lock"),
}


def _derivation_output_impl(ctx: AnalysisContext) -> list[Provider]:
    derivation = ctx.attrs.derivation

    derivation.append(ctx.attrs.output)

    system = ctx.attrs.system

    if system != None:
        derivation.insert(1, system)

    inputs_from = cmd_args(ctx.attrs.flake_lock, parent=1)

    derivation = "{}#".format(ctx.attrs.flake) + ".".join(derivation)

    out_link = ctx.actions.declare_output(derivation)

    ctx.actions.run(
        [
            "env",
            "--",
            "nix",
            "build",
            "--log-format",
            "bar-with-logs",
            "--print-build-logs",
            "--inputs-from",
            inputs_from,
            "--out-link",
            out_link.as_output(),
            derivation,
        ],
        category="nix_build",
        identifier=derivation,
        local_only=True,
    )

    return [
        DefaultInfo(
            default_output=out_link,
        ),
    ]


derivation_output = anon_rule(
    impl=_derivation_output_impl,
    attrs=_common_attrs,
    artifact_promise_mappings={
        "output": lambda x: x[DefaultInfo].default_outputs[0],
    },
)


def _derivation_output_path_impl(ctx: AnalysisContext) -> list[Provider]:
    output = ctx.actions.anon_target(
        derivation_output,
        {key: getattr(ctx.attrs, key) for key in _common_attrs.keys()},
    ).artifact("output")

    return [
        DefaultInfo(
            default_output=output,
        ),
        RunInfo(
            args=cmd_args(output, ctx.attrs.path, delimiter="/"),
        ),
    ]


derivation_output_path = rule(
    impl=_derivation_output_path_impl,
    attrs=_common_attrs
    | {
        "path": attrs.list(attrs.string()),
    },
)


def binary(
    *,
    name: str,
    binary: str | None = None,
    flake: str,
    derivation: list[str],
    output: str | None = None,
    inputs_from: str | None = None,
    set_system: bool = True,
    visibility: list[str] | None = None,
) -> None:
    args: dict[str, typing.Any] = {
        "flake": flake,
        "derivation": derivation,
        "path": ["bin", binary or name],
    }

    if output != None:
        args["output"] = output

    if inputs_from != None:
        args["inputs_from"] = inputs_from

    if set_system:
        args["system"] = select(
            {
                "//constraints:os[linux]": select(
                    {
                        "//constraints:arch[x86_64]": "x86_64-linux",
                    }
                ),
            }
        )

    derivation_output_path(
        name=name,
        visibility=visibility,
        **args,
    )
