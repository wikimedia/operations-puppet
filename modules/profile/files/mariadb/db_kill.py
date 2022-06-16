#!/usr/bin/python3

'''db_kill is a simple wrapper around pt-kill so that in a moment of panic one can
   quickly start killing queries with default safe options:
   * killing only webrequests/jobqueue, with the use of a specific user
   * setting sane defaults for interval, busy-time and idle-time, and killing
     running or sleeping queries
   * making easy to run against any instance, allowing using hostname:section
     (e.g. db1099:s1)
   * printing the full commandline, in case manual adjustments are needed
   * Logging all actions to a file
   * Having a --dry-run option to monitor effects without actuall kills
   * Using automatically the extra port, in case the defaul one is overloaded'''

import argparse
import os
import sys

import wmfmariadbpy.dbutil as dbutil


PT_KILL_PATH = '/usr/bin/pt-kill'


def parse_options():
    '''Retrieves the input command line arguments: the instance to run the kills on, and an
       optional "--dry-run"'''
    parser = argparse.ArgumentParser(description='Execute pt-kill on the given instance.')
    parser.add_argument('instance',
                        help=('Instance to connect to, in hostname, '
                              'host:port or host:section format'))
    parser.add_argument('--dry-run',
                        action='store_true',
                        default=False,
                        help=('It prints the queries that would be killed, '
                              'but does not send the kill commands'))
    return parser.parse_args()


def get_extra_port(port):
    '''Calculates the extra port, given the normal one: 3307 for single instance,
       and port + 20 for the multi-instance ones'''

    if port == 3306:
        return port + 1
    return port + 20


def build_command(host, port, dry_run=False, interval=5, time=10, user='wikiuser202206',
                  log='/var/log/db-kill.log'):
    '''return array with the pt-kill execution and its parameters, based on some
       input arguments:
       * host: the fqdn of the host to connect to
       * port: the port to use to connect to the host
       * dry_run: if true, it only prints the kill commands, it does not actually
                  run the kill commands
       * interval: every how many seconds the command should try to scan and kill
       * time: only queries being executed or sleeping connections over or equal this time
               should be killed, skipping short-running queries
       * user: only queries from this user should be killed
       * log: file where kills should be logged to
    '''
    cmd = [PT_KILL_PATH]
    if not dry_run:
        cmd.append('--kill')
    cmd.extend(['--print',
                '--victims', 'all',
                '--interval', f'{interval}',
                '--busy-time', f'{time}',
                '--idle-time', f'{time}',
                '--match-command', "'Query|Execute|Sleep'",
                '--match-user', f'{user}',
                '--log', f'{log}',
                f'h={host},P={port}'])
    return cmd


def main():
    '''main loop: parse input arguments and execute pt-kill'''
    options = parse_options()
    host, port = dbutil.addr_split(options.instance)
    host = dbutil.resolve(host)
    port = get_extra_port(port)
    cmd = build_command(host=host,
                        port=port,
                        dry_run=options.dry_run)
    print('Running:')
    print(' '.join(cmd))
    try:
        os.execv(cmd[0], cmd)
    except FileNotFoundError:
        print(f'ERROR: pt-kill ({PT_KILL_PATH}) not found')
        sys.exit(-1)
    except TypeError:
        print(f'ERROR: Incorrect arguments: {cmd}')
        sys.exit(-2)
    except OSError:
        print(f'ERROR: An error happened on exec. Arguments: {cmd}')
        sys.exit(-3)


if __name__ == "__main__":
    main()
