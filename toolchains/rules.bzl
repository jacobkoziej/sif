# SPDX-License-Identifier: MPL-2.0
#
# rules.bzl -- toolchain rules
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

load("@sif//rules/alias.bzl", "alias_impl")

AsToolchainInfo = provider(
    fields={
        "name": provider_field(str),
        "object_flags": provider_field(list[str] | None, default=None),
        "include_prefix": provider_field(str | None, default=None),
        "output_flag": provider_field(str, default="-o"),
    },
)

LdToolchainInfo = provider(
    fields={
        "name": provider_field(str),
        "elf_flags": provider_field(list[str] | None, default=None),
        "script_flag": provider_field(str, default="-T"),
        "dep_file_flag": provider_field(str | None, default=None),
        "include_prefix": provider_field(str | None, default="--library-path="),
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
