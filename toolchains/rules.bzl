# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- toolchain rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("//rules/alias.bzl", "alias_impl")

AsToolchainInfo = provider(
    fields={
        "name": provider_field(str),
        "object_flags": provider_field(list[str] | None, default=None),
        "include_prefix": provider_field(str | None, default=None),
        "output_flag": provider_field(str, default="-o"),
    },
)

toolchain_alias = rule(
    impl=alias_impl,
    is_toolchain_rule=True,
    attrs={
        "actual": attrs.option(attrs.toolchain_dep(), default=None),
    },
)
