#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import re
import sys
import textwrap

# pypuppetdb 3 required
from pypuppetdb import connect


class IcingaAudit(object):
    port_re = re.compile(r"[0-9]{4,6}")
    ipv4_re = re.compile(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
    ipv6_re = re.compile(r"(([a-f0-9]+):)+([a-f0-9]+)", re.I)
    site_re = re.compile(r"(eqiad|codfw|drmrs|ulsfo|eqsin|esams|magru)", re.I)
    net_device_re = re.compile(
            r"(\S+) (BFD|BGP|OSPF|Juniper|VCP|VRRP|interfaces)")
    pdu_re = re.compile(r"(\S+)(-infeed-load.*)")
    cassandra_re = re.compile(r"(cassandra-)[a-z](-.*)")
    checks_query = r"""
    resources [parameters, tags, title, line, file] {
        type = 'Monitoring::Service' and
        parameters.ensure = 'present'
    }
    """
    title_notes = {
        "check_SYSTEMD-UNIT_status": "Superseded by SystemdUnitFailed",
        "carbon-cache@ID-state": "graphite-only check",
        "carbon-cache_many_creates": "graphite-only check",
        "carbon-cache_overflow": "graphite-only check",
        "carbon-cache_write_error": "graphite-only check",
        "carbon-frontend-relay-state": "graphite-only check",
        "carbon-frontend-relay_drops": "graphite-only check",
        "carbon-local-relay-state": "graphite-only check",
        "carbon-local-relay_drops": "graphite-only check",
    }

    def fetch(self, db):
        known = []
        res = []
        results = db.pql(self.checks_query)

        for result in results:
            out = {}
            out["title"] = self.dedup_title(result["title"])
            try:
                out["profile"] = [
                    r for r in result["tags"] if r.startswith("profile::")
                ][0]
            except IndexError:
                out["profile"] = "not-found"

            out["notes"] = self.title_notes.get(out["title"], "")

            if repr(out) in known:
                continue
            else:
                known.append(repr(out))
            res.append(out)

        return self._from_results(res)

    def _from_results(self, out):
        ret = IcingaAudit()
        ret.results = out
        return ret

    def phabricator_table(self):
        unique_checks = set([x["title"] for x in self.results])
        unique_profiles = set([x["profile"] for x in self.results])

        uniques = f"""
        | # checks | # profiles
        | ---      | ---
        | {len(unique_checks)} | {len(unique_profiles)}
        """
        print(textwrap.dedent(uniques))

        headers = self.results[0].keys()
        print("| " + " | ".join([x.capitalize() for x in headers]))
        print("| ---" + " | --- ".join([""] * len(headers)))
        for result in sorted(self.results, key=lambda x: x["title"]):
            print("| " + " | ".join(result.values()))

    def dedup_title(self, t):
        if t.startswith("mariadb"):
            t = re.sub("[_-][a-z]{1,2}[0-9]$", "_SHARD", t)
            t = re.sub("_[a-z]{1,2}[0-9]_", "_SHARD_", t)

        if t.startswith("check_certificate_expiry_"):
            t = "check_certificate_expiry_CFSSLCA"

        if t.startswith("https_ncredir_non-canonical-redirect-"):
            t = "https_ncredir_non-canonical-redirect-ID"

        if t.startswith("carbon-cache@"):
            t = "carbon-cache@ID-state"

        if t.startswith("check_") and t.endswith("_status"):
            t = "check_SYSTEMD-UNIT_status"

        m = self.net_device_re.match(t)
        if m:
            t = "DEVICE " + m.group(2)

        m = self.pdu_re.match(t)
        if m:
            t = "PDU" + m.group(2)

        m = self.cassandra_re.match(t)
        if m:
            t = m.group(1) + "ID" + m.group(2)

        t = self.site_re.sub("SITE", t)
        t = self.ipv6_re.sub("IPV6", t)
        t = self.ipv4_re.sub("IPV4", t)
        t = self.port_re.sub("PORT", t)

        return t


def main():
    a = IcingaAudit()
    a.fetch(connect()).phabricator_table()


if __name__ == "__main__":
    sys.exit(main())
