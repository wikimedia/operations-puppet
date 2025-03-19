#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

from fnmatch import fnmatch
from typing import Callable, List, Optional, TypeVar, Generic
from functools import total_ordering


@total_ordering
class Host:
    def __init__(self, fqdn: str, role: str = "unknown"):
        self.fqdn = fqdn
        self.role = role

    def __repr__(self):
        return f"Host(fqdn='{self.fqdn}', role='{self.role}')"

    def __eq__(self, other) -> bool:
        if not isinstance(other, Host):
            return NotImplemented
        return (self.fqdn, self.role) == (other.fqdn, other.role)

    def __lt__(self, other) -> bool:
        if not isinstance(other, Host):
            return NotImplemented
        return (self.fqdn, self.role) < (other.fqdn, other.role)

    def __hash__(self) -> int:
        return hash((self.fqdn, self.role))


# Type variable for Host or any subclass of Host
H = TypeVar("H", bound=Host)


class Filter(Generic[H]):
    def __init__(self, hosts: List[H]):
        self._hosts = hosts

    def __iter__(self):
        for host in self._hosts:
            yield host

    def __len__(self):
        return len(self._hosts)

    def __repr__(self):
        return repr(self._hosts)

    def apply(self, *conditions: Callable[[H], bool]) -> "Filter[H]":
        """Filters using multiple conditions combined with AND logic."""
        hosts = self._hosts.copy()
        for condition in conditions:
            hosts = [host for host in hosts if condition(host)]
        return Filter(hosts)

    @staticmethod
    def by_fqdn(pattern: Optional[str]) -> Callable[[H], bool]:
        """Filter hosts by FQDN or hostname pattern.

        Args:
            pattern: Glob pattern to match against hostname or FQDN

        Returns:
            A callable filter function
        """
        if pattern is None:
            return lambda _: False

        def match(host):
            # include hostname
            hostname = host.fqdn.split(".", 1)[0]
            return fnmatch(hostname, pattern) or fnmatch(host.fqdn, pattern)

        return match

    @staticmethod
    def by_role(role: Optional[str]) -> Callable[[H], bool]:
        """Filter hosts by exact role match.

        Args:
            role: Role name to match

        Returns:
            A callable filter function
        """
        if role is None:
            return lambda _: False
        return lambda host: host.role == role

    @staticmethod
    def any(*conditions: Callable[[H], bool]) -> Callable[[H], bool]:
        """Combine multiple conditions with OR logic.

        Args:
            *conditions: Filter functions to combine

        Returns:
            A combined filter function that returns True if any condition is True
        """
        return lambda host: any(condition(host) for condition in conditions)

    @staticmethod
    def not_(condition: Callable[[H], bool]) -> Callable[[H], bool]:
        """Negate a condition.

        Args:
            condition: Filter function to negate

        Returns:
            A filter function that returns the opposite of the input condition
        """
        return lambda host: not condition(host)
