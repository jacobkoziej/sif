# SPDX-License-Identifier: MPL-2.0
#
# alias.bzl -- alias rule
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>


def alias_impl(ctx: AnalysisContext) -> list[Provider]:
    if ctx.attrs.actual:
        return ctx.attrs.actual.providers

    return [DefaultInfo()]


alias = rule(
    impl=alias_impl,
    attrs={
        "actual": attrs.option(attrs.dep(), default=None),
    },
)
