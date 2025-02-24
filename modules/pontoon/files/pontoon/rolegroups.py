#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
from typing import List, Dict, Any, Set


class RoleGroup:
    def __init__(
        self,
        name: str,
        roles: List[str] = [],
        settings: List[str] = [],
        includes: List[str] = [],
    ):
        self.name: str = name
        self.roles: Set[str] = set(roles or [])
        self.settings: Set[str] = set(settings or [])
        self.includes: List[str] = includes or []

    def merge(self, other: "RoleGroup") -> None:
        self.roles.update(other.roles)
        self.settings.update(other.settings)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "roles": list(self.roles),
            "settings": list(self.settings),
            "include": self.includes,
        }

    @classmethod
    def from_dict(cls, name: str, data: Dict[str, Any]) -> "RoleGroup":
        return cls(
            name=name,
            roles=data.get("roles", []),
            settings=data.get("settings", []),
            includes=data.get("include", []),
        )


class RoleGroups:
    def __init__(self, data: Dict[str, Any]) -> None:
        self.default_includes = {"__default"}
        self.groups = {
            name: RoleGroup.from_dict(name, data) for name, data in data.items()
        }

    def get_group(self, name: str) -> RoleGroup:
        return self._get_group(name, 0)

    def _get_group(self, name: str, level: int = 0) -> RoleGroup:
        """Retrieve a role group, merging included groups."""
        if name not in self.groups:
            return RoleGroup(name)

        base_group = self.groups[name]
        merged_group = RoleGroup(
            name,
            list(base_group.roles),
            list(base_group.settings),
            list(base_group.includes),
        )

        # Default includes apply at top level only
        if level == 0:
            base_group.includes.extend(self.default_includes - {name})

        for included in base_group.includes:
            included_group = self._get_group(included, level + 1)
            merged_group.merge(included_group)

        return merged_group
