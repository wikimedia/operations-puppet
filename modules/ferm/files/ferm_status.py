#!/usr/bin/env python3
"""script to compare the output of iptables-save/ip6tables-save with
the output of `ferm -nl /etc/ferm/ferm.conf` This enables us to ensure
the desired ruleset has been loaded by iptables"""
from argparse import ArgumentParser
from collections import defaultdict
from ipaddress import ip_network
from re import match
from socket import getservbyname
from subprocess import check_output


class Rule:
    """class to parse an iptables rule"""

    # pylint: disable=too-many-instance-attributes
    argument_switch = {
        '-A': 'chain',
        '-p': 'protocol',
        '--protocol': 'protocol',
        '-s': 'source',
        '--source': 'source',
        '-d': 'destination',
        '--destination': 'destination',
        '--dport': 'dport',
        '--sport': 'sport',
        '-m': 'match',
        '--match': 'match',
        '--state': 'state',
        '--limit': 'limit',
        # limit burst is not present in iptables-save
        # '--limit-burst': 'limit_burst',
        '--pkt-type': 'pkt_type',
        '-j': 'jump',
        '--jump': 'jump',
    }

    def __init__(self, raw):
        self._raw = raw
        self._raw_words = raw.split()
        self.chain = None
        self.source = None
        self.destination = None
        self.protocol = None
        self.dport = None
        self.sport = None
        self.match = None
        self.state = None
        self.limit = None
        self.limit_burst = None
        self.pkt_type = None
        self.jump = None
        self._parse()

    def __hash__(self):
        return hash(str(self))

    def __str__(self):
        output = '-A {}'.format(self.chain)
        for token, value in vars(self).items():
            if token.startswith('_raw') or token == 'chain':
                continue
            if value is not None:
                output += ' --{} {}'.format(token.replace('_', '-'), value)
        return output

    def __repr__(self):
        return 'Rule("{}")'.format(self._raw)

    def __eq__(self, obj):
        for token, value in vars(self).items():
            if token.startswith('_raw'):
                continue
            if value != vars(obj)[token]:
                return False
        return True

    @staticmethod
    def _resolve_port(port):
        """convert a port name to a number e.g. ssh -> 22"""
        # return ranges like 6800:7100
        if match(r'\d{1,5}:\d{1,5}', str(port)):
            return port
        try:
            return int(port)
        except ValueError:
            return getservbyname(port)

    def _parse(self):
        for idx, word in enumerate(self._raw_words):
            if word in self.argument_switch.keys():
                # don't track -m (tcp|udp)
                if word in ['-m', '--match'] and self._raw_words[idx + 1] in ['tcp', 'udp']:
                    continue
                vars(self)[self.argument_switch.get(word)] = self._raw_words[idx + 1]

        # perform a bit of normalisation
        if self.match == 'state':
            self.state = self.state.split(',').sort()
        if self.limit is not None:
            self.limit = self.limit.replace('second', 'sec')
        if self.protocol is not None:
            self.protocol = self.protocol.replace('icmpv6', 'ipv6-icmp')
        if self.source is not None:
            self.source = ip_network(self.source)
        if self.destination is not None:
            self.destination = ip_network(self.destination)
        if self.dport is not None:
            self.dport = self._resolve_port(self.dport)
        if self.sport is not None:
            self.sport = self._resolve_port(self.sport)


class Ruleset:
    """parse the output of iptables-save and create a python object"""

    # k8s creates dynamic rules prefixed with cali-
    # docker creates DOCKER and DOCKER_USER
    ignored_chain_prefix = ('DOCKER', 'cali-')

    def __init__(self, raw, table='filter'):
        self._raw = raw
        self.rules = defaultdict(list)
        self.input_policy = None
        self.output_policy = None
        self.forward_policy = None
        self.table = table
        self._parse()

    def __str__(self):
        policy = [':INPUT {}'.format(self.input_policy),
                  ':FORWARD {}'.format(self.forward_policy),
                  ':OUTPUT {}'.format(self.output_policy)]
        for _, rules in self.rules.items():
            policy += [str(rule) for rule in rules]
        return '\n'.join(policy)

    def __eq__(self, obj):
        for token, value in vars(self).items():
            if token.startswith('_raw'):
                continue
            if value != vars(obj)[token]:
                return False
        return True

    def _parse(self):
        in_table = False
        for line in self._raw.split('\n'):
            if line.startswith('*{}'.format(self.table)):
                in_table = True
            if not in_table:
                continue
            if line.startswith('COMMIT'):
                break
            if line.startswith(':INPUT'):
                self.input_policy = line.split()[1]
                continue
            if line.startswith(':OUTPUT'):
                self.output_policy = line.split()[1]
                continue
            if line.startswith(':FORWARD'):
                self.forward_policy = line.split()[1]
                continue
            if line.startswith('-A'):
                chain = line.split()[1]
                if chain.startswith(self.ignored_chain_prefix):
                    continue
                rule = Rule(line)
                if rule.jump and not rule.jump.startswith(self.ignored_chain_prefix):
                    self.rules[chain].append(rule)

    def diff(self, ruleset):
        """return  a diff or between self and ruleset

        Parameters:
            ruleset (Ruleset): a Ruleset object to compare
        return:
            str: a String representing the difference between self and ruleset
        """
        lines = []
        if self.table != ruleset.table:
            return 'ruleset and self have different tables\n-{}\n+{}'.format(
                self.table, ruleset.table)
        if self.input_policy != ruleset.input_policy:
            lines.append([
                '-:INPUT {}'.format(self.input_policy),
                '+:INPUT {}'.format(ruleset.input_policy),
            ])
        if self.forward_policy != ruleset.forward_policy:
            lines.append([
                '-:FORWARD {}'.format(self.forward_policy),
                '+:FORWARD {}'.format(ruleset.forward_policy),
            ])
        if self.output_policy != ruleset.output_policy:
            lines.append([
                '-:OUTPUT {}'.format(self.output_policy),
                '+:OUTPUT {}'.format(ruleset.output_policy),
            ])
        for chain in self.rules.keys():
            for rule in set(self.rules[chain]) - set(ruleset.rules[chain]):
                lines.append('-{}'.format(str(rule)))
            for rule in set(ruleset.rules[chain]) - set(self.rules[chain]):
                lines.append('+{}'.format(str(rule)))
        return '\n'.join(lines)


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='store_true')
    return parser.parse_args()


def main():
    """Main entry point"""
    args = get_args()
    iptables = check_output(['/sbin/iptables-save'])
    ferm = check_output('/usr/sbin/ferm -nl --domain ip /etc/ferm/ferm.conf'.split())
    ip6tables = check_output(['/sbin/ip6tables-save'])
    ferm6 = check_output('/usr/sbin/ferm -nl --domain ip6 /etc/ferm/ferm.conf'.split())

    ferm_parsed = Ruleset(ferm.decode())
    iptables_parsed = Ruleset(iptables.decode())
    ferm6_parsed = Ruleset(ferm6.decode())
    ip6tables_parsed = Ruleset(ip6tables.decode())

    ret_code = 0
    if ferm6_parsed != ip6tables_parsed:
        ret_code = 1
        if args.verbose:
            print('ipv6:\n{}'.format(ip6tables_parsed.diff(ferm6_parsed)))
    if ferm_parsed != iptables_parsed:
        ret_code = 1
        if args.verbose:
            print('ipv4:\n{}'.format(iptables_parsed.diff(ferm_parsed)))
    return ret_code


if __name__ == '__main__':
    raise SystemExit(main())
