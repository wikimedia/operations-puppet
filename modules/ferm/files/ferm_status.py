#!/usr/bin/env python3
"""script to compare the output of iptables-save/ip6tables-save with
the output of `ferm -nl /etc/ferm/ferm.conf` This enables us to ensure
the desired ruleset has been loaded by iptables"""
from argparse import ArgumentParser
from ipaddress import ip_network
from re import match
from socket import getservbyname
from subprocess import check_output


def get_quoted_string(words_array, idx):
    """read words array for a quoted string starting at idx

    This functions will parse words array looking for a quoted string starting
    at words_array[idx]. if we do find a quoted string, keep scanning
    words_array until we find the string terminator and return the found string.
    Otherwise return words_array[idx].

    Arguments:
        words_array (list): the words array to search
        idx (int): the idx pointing to the beginning of the quoted string

    Returns:
        str: if a quote string is found return that otherwise return words_array[idx]
    """
    if words_array[idx][0] not in ['"', "'"]:
        return words_array[idx]
    quote_mark = words_array[idx][0]
    msg = []
    for word in words_array[idx:]:
        msg.append(word)
        if word.endswith(quote_mark) and word[-2] != '\\':
            break
    return ' '.join(msg).strip(quote_mark)


class Tables(dict):
    """class to hold all tables"""

    def __str__(self):
        return '\n'.join([str(table) for table in self.values()])


class Table:
    """Class to hold an individual Table"""

    def __init__(self, name):
        self.name = name
        self._chains = {}

    def __eq__(self, obj):
        return (
            self.name == obj.name and sorted(self.chains) == sorted(obj.chains)
        )

    def __str__(self):
        lines = ['*{}'.format(self.name)]
        return '\n'.join(lines + [str(chain) for chain in self.chains.values()])

    def add(self, chain):
        """Add a chain to the table

        Parameters:
            chain (Chain): a chain to add to _chains
        """
        self._chains[chain.name] = chain

    def diff(self, table):
        """return  a diff or between self and table

        Parameters:
            table (Table): a Table object to compare
        return:
            list: a list of strings representing the difference between self and table
        """
        lines = []
        for missing in set(table.chains.keys()) - set(self.chains.keys()):
            lines.append('-:{}'.format(missing))
        for additional in set(self.chains.keys()) - set(table.chains.keys()):
            lines.append('+:{}'.format(additional))
        for name, chain in self.chains.items():
            if name in table.chains.keys():
                lines += chain.diff(table.chains[name])
        return lines

    @property
    def chains(self):
        """return all chains"""
        return self._chains


class Chain:
    """A class to maintain an iptables chain"""
    _header = ':{name} {policy}'

    def __init__(self, name, policy=None):
        self.name = name
        self.policy = policy  # one of ACCEPT, DROP, None
        self._rules = []

    def __eq__(self, obj):
        for token, value in vars(self).items():
            if value != vars(obj)[token]:
                return False
        return True

    def __str__(self):
        return '\n'.join([self.header()] + [str(rule) for rule in self.rules])

    def add(self, rule):
        """Add a rule to the chain

        Parameters:
            rule (Rule): a rule to add to _rules
        """
        self._rules.append(rule)

    def diff(self, chain):
        """return  a diff or between self and chain

        Parameters:
            table (Chain): a Chain object to compare
        return:
            list: a list of strings representing the difference between self and chain
        """
        lines = []
        if self.policy != chain.policy:
            lines.append([
                '-{}'.format(self.header()),
                '+{}'.format(self.header(chain)),
            ])
        for rule in set(self.rules) - set(chain.rules):
            lines.append('-{}'.format(str(rule)))
        for rule in set(chain.rules) - set(self.rules):
            lines.append('+{}'.format(str(rule)))
        return lines

    def header(self, obj=None):
        """Return a formated header"""
        if obj is not None:
            return self._header.format(name=obj.name, policy=obj.policy)
        return self._header.format(name=self.name, policy=self.policy)

    @property
    def rules(self):
        """Return all rules"""
        return self._rules


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
        '--comment': 'comments',
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
        self.comments = []
        self.limit = None
        self.limit_burst = None
        self.pkt_type = None
        self.jump = None
        self._parse()

    def __hash__(self):
        return hash(str(self))

    def __str__(self):
        output = ['-A {}'.format(self.chain)]
        for token, value in vars(self).items():
            if isinstance(value, str):
                value = [value]
            if token.startswith('_raw') or token == 'chain' or not isinstance(value, list):
                continue
            output += ['--{} {}'.format(token.replace('_', '-'), element) for element in value]
        return ' '.join(output)

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
                if word == '--comment':
                    # We can have multiple comments so this is an array
                    self.comments.append(get_quoted_string(self._raw_words, idx + 1))
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
            self.dport = Rule._resolve_port(self.dport)
        if self.sport is not None:
            self.sport = Rule._resolve_port(self.sport)


class Parser:
    """A class to parse the output of iptabls-save and ferm -nl"""

    parser_methods = {
        '*': 'table',
        ':': 'chain',
        '-': 'rule',
    }

    def __init__(self, lines, ignored_chain_prefixes=(),
                 ignored_comment_prefixs=(), autoparse=True):
        self._lines = lines
        self._table = None
        self._chain = None
        self.ignored_chain_prefixes = ignored_chain_prefixes
        self.ignored_comment_prefixs = ignored_comment_prefixs
        self._tables = Tables()
        if autoparse:
            self.parse()

    def __eq__(self, obj):
        return self.tables == obj.tables

    def __str__(self):
        return str(self.tables)

    @property
    def tables(self):
        """Return all tables"""
        return self._tables

    def parse(self):
        """Parse the all lines"""
        for line in self._lines.splitlines():
            if not line:
                continue
            first_char = line[0]
            if first_char in self.parser_methods:
                getattr(self, '_parse_{}'.format(self.parser_methods[first_char]))(line)

    def diff(self, parser):
        """return a diff between self and parser

        Parameters:
            table (Parser): a Parser object to compare
        return:
            list: a list of strings representing the difference between self and parser
        """
        lines = []
        for missing in set(parser.tables.keys()) - set(self.tables.keys()):
            lines.append('-*{}'.format(missing))
        for additional in set(self.tables.keys()) - set(parser.tables.keys()):
            lines.append('+*{}'.format(additional))
        for name, table in self.tables.items():
            if name in parser.tables:
                lines += table.diff(parser.tables[name])
        return '\n'.join(lines)

    def _parse_table(self, line):
        self._table = Table(line[1:])
        self._tables[self._table.name] = self._table
        self._chain = None

    def _parse_chain(self, line):
        parts = line.split()
        if parts[0][1:].startswith(self.ignored_chain_prefixes):
            return
        if parts[1] == '-':
            parts[1] = None
        self._chain = Chain(parts[0][1:], parts[1])
        self._table.add(self._chain)

    def _parse_rule(self, line):
        chain = line.split()[1]
        rule = Rule(line)
        if chain.startswith(self.ignored_chain_prefixes):
            return
        if rule.jump and rule.jump.startswith(self.ignored_chain_prefixes):
            return
        if rule.comments and any(comment for comment in rule.comments
                                 if comment.startswith(self.ignored_comment_prefixs)):
            return
        self._chain = self._table.chains[chain]
        self._chain.add(Rule(line))


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='store_true')
    return parser.parse_args()


def main():
    """Main entry point"""
    args = get_args()

    # calico creates dynamic rules in chains prefixed with cali-
    # as well as the following chains  KUBE-SERVICES, KUBE-FIREWALL and KUBE-FORWARD
    # docker creates DOCKER and DOCKER_USER
    ignored_chain_prefix = ('DOCKER', 'cali-', 'KUBE-')
    ignored_comment_prefixs = ('cali:')

    iptables = check_output(['iptables-save'])
    ferm = check_output('ferm -nl --domain ip /etc/ferm/ferm.conf'.split())
    ip6tables = check_output(['ip6tables-save'])
    ferm6 = check_output('ferm -nl --domain ip6 /etc/ferm/ferm.conf'.split())

    ferm_parsed = Parser(ferm.decode(), ignored_chain_prefix, ignored_comment_prefixs)
    iptables_parsed = Parser(iptables.decode(), ignored_chain_prefix, ignored_comment_prefixs)
    ferm6_parsed = Parser(ferm6.decode(), ignored_chain_prefix, ignored_comment_prefixs)
    ip6tables_parsed = Parser(ip6tables.decode(), ignored_chain_prefix, ignored_comment_prefixs)

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
