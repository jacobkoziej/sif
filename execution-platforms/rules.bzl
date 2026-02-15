# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- execution platform rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def get_host_constraints() -> list[str]:
    constraints = []

    arch = host_info().arch

    if arch.is_aarch64:
        constraints += ["//constraints:arch[aarch64]"]

    if arch.is_x86_64:
        constraints += ["//constraints:arch[x86_64]"]

    os = host_info().os

    if os.is_linux:
        constraints += ["//constraints:os[linux]"]

    if os.is_macos:
        constraints += ["//constraints:os[macos]"]

    return constraints


def _execution_platform_impl(ctx: AnalysisContext) -> list[Provider]:
    constraints: dict[TargetLabel, ConstraintValueInfo] = {}

    for constraint in ctx.attrs.constraints:
        constraints.update(constraint[ConfigurationInfo].constraints)

    configuration = ConfigurationInfo(constraints=constraints, values={})

    execution = ctx.attrs.execution

    executor_config = CommandExecutorConfig(
        local_enabled=execution in ("local", "hybrid"),
        remote_enabled=execution in ("remote", "hybrid"),
    )

    platform = ExecutionPlatformInfo(
        label=ctx.label.raw_target(),
        configuration=configuration,
        executor_config=executor_config,
    )

    return [
        DefaultInfo(),
        platform,
        ExecutionPlatformRegistrationInfo(
            platforms=[platform],
        ),
    ]


execution_platform = rule(
    impl=_execution_platform_impl,
    attrs={
        "constraints": attrs.list(
            attrs.dep(providers=[ConfigurationInfo]),
            default=[],
        ),
        "execution": attrs.enum(
            ["local", "remote", "hybrid"],
            default="hybrid",
        ),
    },
)


def _execution_platforms_impl(ctx: AnalysisContext) -> list[Provider]:
    platform_registration_infos = [
        platform[ExecutionPlatformRegistrationInfo] for platform in ctx.attrs.platforms
    ]
    platforms = [
        platform
        for platform_registration_info in platform_registration_infos
        for platform in platform_registration_info.platforms
    ]

    return [
        DefaultInfo(),
        ExecutionPlatformRegistrationInfo(
            platforms=platforms,
        ),
    ]


execution_platforms = rule(
    impl=_execution_platforms_impl,
    attrs={
        "platforms": attrs.list(
            attrs.dep(providers=[ExecutionPlatformRegistrationInfo]),
            default=[],
        ),
    },
)
