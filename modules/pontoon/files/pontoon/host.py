#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

from fnmatch import fnmatch
from typing import Callable, List, Optional
from functools import total_ordering


@total_ordering
class Host:
    def __init__(self, fqdn: str, role: str):
        self.fqdn = fqdn
        self.role = role

    def __repr__(self):
        return f"Host(fqdn='{self.fqdn}', role='{self.role}')"

    def __eq__(self, other: "Host") -> bool:
        if not isinstance(other, Host):
            return NotImplemented
        return (self.fqdn, self.role) == (other.fqdn, other.role)

    def __lt__(self, other: "Host") -> bool:
        if not isinstance(other, Host):
            return NotImplemented
        return (self.fqdn, self.role) < (other.fqdn, other.role)

    def __hash__(self) -> int:
        return hash((self.fqdn, self.role))


class Filter(object):
    def __init__(self, hosts: List[Host]):
        self._hosts = hosts

    def __iter__(self):
        for host in self._hosts:
            yield host

    def __len__(self):
        return len(self._hosts)

    def __repr__(self):
        return repr(self._hosts)

    def apply(self, *conditions: Callable[[Host], bool]) -> "Filter":
        """Filters using multiple conditions combined with AND logic."""

        hosts = self._hosts.copy()
        for condition in conditions:
            hosts = [host for host in hosts if condition(host)]
        return Filter(hosts)

    @staticmethod
    def by_fqdn(pattern: Optional[str]) -> Callable[[Host], bool]:
        if pattern is None:
            return lambda _: False

        def match(host):
            # include hostname
            hostname = host.fqdn.split(".", 1)[0]
            return fnmatch(hostname, pattern) or fnmatch(host.fqdn, pattern)

        return match

    @staticmethod
    def by_role(role: Optional[str]) -> Callable[[Host], bool]:
        if role is None:
            return lambda _: False
        return lambda host: host.role == role

    @staticmethod
    def any(*conditions: Callable[[Host], bool]) -> Callable[[Host], bool]:
        return lambda host: any(condition(host) for condition in conditions)

    @staticmethod
    def not_(condition: Callable[[Host], bool]) -> Callable[[Host], bool]:
        return lambda host: not condition(host)
