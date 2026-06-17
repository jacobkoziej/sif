# SPDX-License-Identifier: MPL-2.0
#
# graph.bzl -- graph utilities
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Meta Platforms, Inc. and affiliates.
# <https://github.com/facebook/buck2-prelude/blob/8c031a1936f91633c0321e8c3c894e35c9066b9b/utils/graph_utils.bzl>

Node = typing.Any
Graph = dict[Node, list[Node]]


def fill_empty_edges(graph: Graph) -> None:
    for deps in graph.values():
        for node in deps:
            if node not in graph:
                graph[node] = []


def post_order_traversal(graph: Graph) -> list[Node]:
    outgoing_degrees: dict[Node, int] = {}
    reverse_deps: dict[Node, list[Node]] = {node: [] for node in graph}

    for node, deps in graph.items():
        deps = dedupe(deps)
        outgoing_degrees[node] = len(deps)

        for dep in deps:
            reverse_deps[dep].append(node)

    terminal_nodes = [
        node
        for node, outgoing_degree in outgoing_degrees.items()
        if outgoing_degree == 0
    ]

    ordered: list[Node] = []

    for _ in range(len(outgoing_degrees)):
        if len(terminal_nodes) == 0:
            fail("cycle exists in graph: `{}`".format(graph))

        node = terminal_nodes.pop()
        ordered.append(node)

        for dep in reverse_deps[node]:
            outgoing_degrees[dep] -= 1

            if outgoing_degrees[dep] == 0:
                terminal_nodes.append(dep)

    if terminal_nodes:
        fail(
            "finished before processing nodes: `[{}]`".format(
                ", ".join(map(str, terminal_nodes))
            )
        )

    if len(ordered) != len(graph):
        fail("missing or duplicate nodes in topological sort")

    return ordered
