# SPDX-License-Identifier: MPL-2.0
#
# modifiers.bzl -- configuration modifiers
# Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
#
# Inspired by the original work of Meta Platforms, Inc. and affiliates.
# <https://github.com/facebook/buck2-prelude/tree/8c031a1936f91633c0321e8c3c894e35c9066b9b/cfg/modifier>

load("@sif//cfg/rules.bzl", "is_subset")
load(
    "@sif//utils/graph.bzl",
    "fill_empty_edges",
    "post_order_traversal",
)

Constraints = dict[TargetLabel, ConstraintValueInfo]
Refs = dict[str, ProviderCollection]

ModifierCliLocation = record()
ModifierPackageLocation = record(path=str)
ModifierTargetLocation = record()

ModifierLocation = (
    ModifierCliLocation | ModifierPackageLocation | ModifierTargetLocation
)

RawModifier = str
SelectModifier = dict[RawModifier, typing.Any]  # dict[RawModifier, SelectModifier]
Modifier = RawModifier | SelectModifier

SerialModifier = typing.Any
TaggedModifier = record(
    modifier=Modifier,
    location=ModifierLocation,
)

SelectModifierInfo = record(
    selectors=list[
        (ConfigurationInfo, typing.Any)
    ],  # list[(ConfigurationInfo, ModifierInfo)]
    default=typing.Any,  # ModifierInfo | None
)
ModifierInfo = ConstraintValueInfo | SelectModifierInfo

GatheredModifiers = record(
    package=list[TaggedModifier],
    target=list[TaggedModifier],
    cli=list[TaggedModifier],
)


def _location_to_str(location: ModifierLocation) -> str:
    if isinstance(location, ModifierCliLocation):
        return "<cli>"

    if isinstance(location, ModifierPackageLocation):
        return location.path

    if isinstance(location, ModifierTargetLocation):
        return "<target>"

    fail("unknow `{}` location of type `{}`".format(location, type(location)))


def _serialize_tagged_modifiers(
    modifiers: list[TaggedModifier],
) -> list[SerialModifier]:
    def serialize_modifier(modifier: TaggedModifier) -> SerialModifier:
        def serialize_location(location: ModifierLocation) -> dict[str, typing.Any]:
            serial_location = {key: getattr(location, key) for key in dir(location)}

            def location_type_to_str(location: ModifierLocation) -> str:
                if isinstance(location, ModifierCliLocation):
                    return "ModifierCliLocation"

                if isinstance(location, ModifierPackageLocation):
                    return "ModifierPackageLocation"

                if isinstance(location, ModifierTargetLocation):
                    return "ModifierTargetLocation"

                fail("unexpected location type: `{}`".format(location))

            serial_location.update(_type=location_type_to_str(location))

            return serial_location

        return {
            "modifier": modifier.modifier,
            "location": serialize_location(modifier.location),
        }

    return map(serialize_modifier, modifiers)


def _deserialize_serial_modifiers(
    modifiers: list[SerialModifier],
) -> list[TaggedModifier]:
    def deserialize_modifier(modifier: SerialModifier) -> TaggedModifier:
        def deserialize_location(location: typing.Any) -> ModifierLocation:
            type_to_constructor = {
                "ModifierCliLocation": ModifierCliLocation,
                "ModifierPackageLocation": ModifierPackageLocation,
                "ModifierTargetLocation": ModifierTargetLocation,
            }

            type = location.pop("_type")

            if type == None:
                fail("no location type specified: `{}`".format(location))

            constructor = type_to_constructor.get(type)

            if constructor == None:
                fail("unknown location type: `{}`".format(type))

            return constructor(**location)

        return TaggedModifier(
            modifier=modifier["modifier"],
            location=deserialize_location(modifier["location"]),
        )

    return map(deserialize_modifier, modifiers)


def gather_modifiers(
    *,
    package_modifiers: list[SerialModifier] | None,
    target_modifiers: list[Modifier] | None,
    cli_modifiers: list[RawModifier] | None,
    aliases: dict[str, RawModifier],
    **_,
) -> (list[str], GatheredModifiers):
    package_modifiers = package_modifiers or []
    target_modifiers = target_modifiers or []
    cli_modifiers = cli_modifiers or []

    package_modifiers = _deserialize_serial_modifiers(package_modifiers)

    def tag_target_modifier(modifier: Modifier) -> TaggedModifier:
        return TaggedModifier(
            modifier=modifier,
            location=ModifierTargetLocation(),
        )

    target_modifiers = map(tag_target_modifier, target_modifiers)

    def resolve_alias(modifier: Modifier) -> Modifier:
        return aliases.get(modifier, modifier)

    cli_modifiers = map(resolve_alias, cli_modifiers)

    def tag_cli_modifier(modifier: Modifier) -> TaggedModifier:
        return TaggedModifier(
            modifier=modifier,
            location=ModifierCliLocation(),
        )

    cli_modifiers = map(tag_cli_modifier, cli_modifiers)

    def tagged_modifiers_to_refs(modifiers: list[TaggedModifier]) -> list[str]:
        def modifier_to_refs(modifier: Modifier) -> list[str]:
            if isinstance(modifier, RawModifier):
                return [modifier]

            if not isinstance(modifier, SelectModifier):
                fail("unknown modifier type: `{}`".format(modifier))

            refs = []

            for ref, sub_modifier in modifier.items():
                refs += [ref] + modifier_to_refs(sub_modifier)

            return refs

        refs = []

        for modifier in modifiers:
            refs += modifier_to_refs(modifier.modifier)

        return refs

    refs = []

    for modifiers in [package_modifiers, target_modifiers, cli_modifiers]:
        refs += tagged_modifiers_to_refs(modifiers)

    return refs, GatheredModifiers(
        package=package_modifiers,
        target=target_modifiers,
        cli=cli_modifiers,
    )


def apply_modifiers(
    *,
    refs: Refs,
    params: GatheredModifiers,
) -> PlatformInfo:
    def get_modifier_infos(
        modifier: Modifier | None,
        location: ModifierLocation,
    ) -> list[(TargetLabel, ModifierInfo)]:
        if modifier == None:
            fail(
                "expected modifier at `{}` but found `None`".format(
                    _location_to_str(location)
                )
            )

        if isinstance(modifier, RawModifier):
            constraints = refs[modifier][ConfigurationInfo].constraints
            return list(constraints.items())

        if not isinstance(modifier, SelectModifier):
            fail(
                "found unknown `{}` modifier of type `{}` at `{}`".format(
                    modifier, type(modifier), _location_to_str(location)
                )
            )

        constraint_labels = set()

        selectors: list[(ConfigurationInfo, ModifierInfo)] = []
        default = None

        for key, sub_modifier in modifier.items():
            sub_modifiers_infos = get_modifier_infos(sub_modifier, location)

            if len(sub_modifiers_infos) != 1:
                fail(
                    "found more than one constraint for selector at `{}`:\n".format(
                        _location_to_str(location)
                    )
                    + "\n\t".join([str(label) for (label, _) in sub_modifiers_infos])
                )

            label, sub_modifier_info = sub_modifiers_infos[0]
            constraint_labels.add(label)

            if key == "DEFAULT" and sub_modifier:
                default = sub_modifier_info
                continue

            configuration_info = refs[key][ConfigurationInfo]
            selectors.append((configuration_info, sub_modifier_info))

        if len(constraint_labels) != 1:
            fail(
                "found more than one constraint for selector at `{}`:\n".format(
                    _location_to_str(location)
                )
                + "\n\t".join(map(str, constraint_labels))
            )

        label = constraint_labels.pop()

        return [(label, SelectModifierInfo(selectors=selectors, default=default))]

    def resolve_modifier_infos(
        label_to_modifier_infos: dict[TargetLabel, list[ModifierInfo]],
        modifiers: list[TaggedModifier],
    ) -> None:
        for modifier in modifiers:
            location = modifier.location
            modifier = modifier.modifier

            for label, modifier_infos in get_modifier_infos(modifier, location):
                updated_modifier_infos = label_to_modifier_infos.get(label, [])
                updated_modifier_infos.append(modifier_infos)

                label_to_modifier_infos[label] = updated_modifier_infos

    label_to_modifier_infos: dict[TargetLabel, list[ModifierInfo]] = {}

    for modifiers in [getattr(params, param) for param in ["package", "target", "cli"]]:
        resolve_modifier_infos(label_to_modifier_infos, modifiers)

    def modifier_deps(modifier_info: ModifierInfo) -> list[TargetLabel]:
        if not isinstance(modifier_info, SelectModifierInfo):
            return []

        deps = []

        for key, sub_modifier in modifier_info.selectors:
            for label in key.constraints:
                deps.append(label)

                deps += modifier_deps(sub_modifier)

        if modifier_info.default:
            deps += modifier_deps(modifier_info.default)

        return deps

    modifier_dep_graph = {
        label: [
            dep
            for modifier_info in modifier_infos
            for dep in dedupe(modifier_deps(modifier_info))
        ]
        for label, modifier_infos in label_to_modifier_infos.items()
    }

    fill_empty_edges(modifier_dep_graph)

    ordered_modifier_labels = post_order_traversal(modifier_dep_graph)

    def resolve_modifier(
        configuration: ConfigurationInfo,
        modifier: ModifierInfo | None,
    ) -> ConstraintValueInfo | None:
        if not isinstance(modifier, SelectModifierInfo):
            return modifier

        for sub_configuration, sub_modifier in modifier.selectors:
            if is_subset(sub_configuration, configuration):
                return resolve_modifier(configuration, sub_modifier)

        return resolve_modifier(configuration, modifier.default)

    configuration = ConfigurationInfo(constraints={}, values={})

    for label in ordered_modifier_labels:
        for modifier_info in label_to_modifier_infos.get(label, []):
            constraint_value = resolve_modifier(configuration, modifier_info)

            if constraint_value:
                configuration.constraints[label] = constraint_value

    def constraints_to_label(constraints: Constraints) -> str:
        labels = [constraint.label for constraint in constraints.values()]

        names = sorted(
            [
                "{}:{}[{}]".format(
                    label.path, label.name, (label.sub_target or ["<empty>"])[0]
                )
                for label in labels
            ]
        )

        return ",".join(names) or "<empty>"

    return PlatformInfo(
        label=constraints_to_label(configuration.constraints),
        configuration=configuration,
    )


def get_buckconfig_cfg_modifiers(
    section: str = "cfg_modifiers",
    key: str = "modifiers",
) -> list[RawModifier]:
    raw_modifiers = read_root_config(section, key, "")

    if not raw_modifiers:
        return []

    return [
        modifier.strip() for modifier in raw_modifiers.split(",") if modifier.strip()
    ]


def set_cfg_modifiers(*modifiers: tuple[Modifier, ...]) -> None:
    parent_modifiers = get_parent_modifiers() or []

    def tag_modifier(modifier: Modifier) -> TaggedModifier:
        return TaggedModifier(
            modifier=modifier,
            location=ModifierPackageLocation(
                path="{}//{}/PACKAGE".format(get_cell_name(), get_base_path()),
            ),
        )

    modifiers = _serialize_tagged_modifiers(map(tag_modifier, modifiers))

    set_modifiers(parent_modifiers + modifiers)
