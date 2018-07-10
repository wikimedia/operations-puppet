#!/usr/bin/python3

import ipaddress
import os
import re
import socket
import sys


"""
mysql.py intends to be a wrapper around the mysql command line client,
adapted to WMF cluster convenience -intended for its usage on command
line/bash scripts only. It allows to skip full domain name
and auto-completes it in a best-effor manner. It also forces the usage
of TLS, unless socket based authentication is used (localhost).
It allow to define hosts in host:port format.
Finally, it handles the several domains by chosing the right default
password (e.g. labsdb hosts have its own, separate password.
Other than automatically add some extra parameters, the script just
execs mysql, behaving like it.
"""


def get_host_tuple(host):
    """
    It parses a host argument (which can be in format 'host:port' and
    returns a (host, port) tuple
    """
    if ':' in host:
        # we do not support ipv6 yet
        host, port = host.split(':')
        port = int(port)
    else:
        port = 3306
    return (host, port)


def resolve(host):
    """
    Return the full qualified domain name for a database hostname. Normally
    this return the hostname itself, except in the case where the
    datacenter and network parts have been omitted, in which case, it is
    completed as a best effort.
    If the original address is an IPv4 or IPv6 address, leave it as is
    """
    try:
        ipaddress.ip_address(host)
        return host
    except ValueError:
        pass
    if '.' not in host and host != 'localhost':
        domain = ''
        if re.match('^[a-z]+1[0-9][0-9][0-9]$', host) is not None:
            domain = '.eqiad.wmnet'
        elif re.match('^[a-z]+2[0-9][0-9][0-9]$', host) is not None:
            domain = '.codfw.wmnet'
        elif re.match('^[a-z]+3[0-9][0-9][0-9]$', host) is not None:
            domain = '.esams.wmnet'
        elif re.match('^[a-z]+4[0-9][0-9][0-9]$', host) is not None:
            domain = '.ulsfo.wmnet'
        else:
            localhost_fqdn = socket.getfqdn()
            if '.' in localhost_fqdn and len(localhost_fqdn) > 1:
                domain = localhost_fqdn[localhost_fqdn.index('.'):]
        host = host + domain
    return host


def find_host(arguments):
    """
    Determines the host, if any, provided on command line and
    and index on where that host is defined. Trickier than it
    should as mysql accepts --host=host, -hhost, -h host and
    --host host.
    """
    i = 0
    host = None
    host_index = []
    for argument in arguments:
        if argument.startswith('-h'):
            if len(argument[2:]) > 0:
                host = argument[2:]
                host_index.append(i)
            elif argument == '-h' and len(arguments) > (i + 1):
                host = arguments[i + 1]
                host_index.append(i)
                host_index.append(i + 1)
        elif argument.startswith('--host'):
            if argument[6:7] == '=':
                host = argument[7:]
                host_index.append(i)
            elif argument == '--host' and len(arguments) > (i + 1):
                host = arguments[i + 1]
                host_index.append(i)
                host_index.append(i + 1)
        i += 1
    return (host, host_index)


def override_arguments(arguments):
    """
    Finds the host parameters and applies ssl config, host/port
    transformations and default section (password) used
    """
    (host, host_index) = find_host(arguments)

    # Just add skip-ssl for localhost
    if host == 'localhost' or host is None:
        arguments.append('--skip-ssl')
    else:
        port = None
        if ':' in host:
            (host, port) = get_host_tuple(host)

        host = resolve(host)

        for i in host_index:
            del arguments[host_index[0]]
        arguments.insert(host_index[0], '--host={}'.format(host))
        if port is not None:
            arguments.insert(host_index[0] + 1, '--port={}'.format(port))

        if host.startswith('labsdb'):
            arguments.insert(1, '--defaults-group-suffix=labsdb')
    return arguments


def main():
    arguments = override_arguments(sys.argv)
    sys.exit(os.execvp('mysql', arguments))


if __name__ == "__main__":
    main()
