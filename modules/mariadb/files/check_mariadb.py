#!/usr/bin/env python3

import argparse
import configparser
from datetime import datetime
import ipaddress
import json
import math
import os
# requires python3-pymysql
import pymysql
import re
import socket
import subprocess
import sys
import time


class WMFMariaDB:
    """
    Wrapper class to connect to MariaDB instances within the Wikimedia
    Foundation cluster. It simplifys all authentication methods by providing a
    unique, clean way to do stuff on the databases.
    """

    connection = None
    host = None
    port = None
    database = None
    __last_error = None
    __debug = False

    @staticmethod
    def get_credentials(host, port, database):
        """
        Given a database instance, return the authentication method, including
        the user, password, socket and ssl configuration.
        """
        if host == 'localhost':
            # connnect to localhost using plugin_auth:
            config = configparser.ConfigParser(interpolation=None,
                                               allow_no_value=True)
            config.read('/etc/my.cnf')
            if os.getuid() == 0:
                user = 'root'
            else:
                user = os.getlogin()
            if port == 3306:
                mysql_sock = config['client']['socket']
            else:
                mysql_sock = '/run/mysqld/mysqld.s' + str(port)[-1:] + '.sock'
            ssl = None
            password = None
            charset = None
        elif not host.startswith('labsdb'):
            # connect to a production remote host, use ssl
            config = configparser.ConfigParser(interpolation=None,
                                               allow_no_value=True)
            config.read('/root/.my.cnf')
            user = config['client']['user']
            password = config['client']['password']
            ssl = {'ca': '/etc/ssl/certs/Puppet_Internal_CA.pem'}
            mysql_sock = None
            charset = None
        else:
            # connect to a labs remote host, use ssl
            config = configparser.ConfigParser(interpolation=None)
            config.read('/root/.my.cnf')
            user = config['labsdb']['user']
            password = config['labsdb']['password']
            ssl = {'ca': '/etc/ssl/certs/Puppet_Internal_CA.pem'}
            mysql_sock = None
            charset = None

        return (user, password, mysql_sock, ssl, charset)

    @property
    def debug(self):
        """debug getter"""
        return self.__debug

    @debug.setter
    def debug(self, debug):
        """debug setter"""
        if not debug:
            self.__debug = False
        else:
            self.__debug = True

    @property
    def last_error(self):
        """last_error getter"""
        return self.__last_error

    @staticmethod
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
            elif re.match('^[a-z]+5[0-9][0-9][0-9]$', host) is not None:
                domain = '.eqsin.wmnet'
            else:
                localhost_fqdn = socket.getfqdn()
                if '.' in localhost_fqdn and len(localhost_fqdn) > 1:
                    domain = localhost_fqdn[localhost_fqdn.index('.'):]
            host = host + domain
        return host

    def __init__(self, host, port=3306, database=None, debug=False,
                 connect_timeout=10.0):
        """
        Try to connect to a mysql server instance and returns a python
        connection identifier, which you can use to send one or more queries.
        """

        self.debug = debug
        host = WMFMariaDB.resolve(host)
        (user, password, socket, ssl, charset) = WMFMariaDB.get_credentials(
            host, port, database)

        if self.debug:
            if host == 'localhost':
                address = '{}[socket={}]'.format(host, socket)
            else:
                address = '{}:{}'.format(host, port)
            print('Connecting to {}/{}'.format(address, database))
        try:
            self.connection = pymysql.connect(
                host=host, port=port, user=user, password=password,
                db=database, charset='utf8mb4', unix_socket=socket, ssl=ssl,
                connect_timeout=connect_timeout)
        except (pymysql.err.OperationalError,
                pymysql.err.InternalError,
                FileNotFoundError) as e:  # noqa
            self.connection = None
            self.__last_error = [e.args[0], e.args[1]]
            if self.debug:
                print('ERROR {}: {}'.format(e.args[0], e.args[1]))
        self.host = host
        self.port = int(port)
        self.database = database
        self.connect_timeout = connect_timeout

    def change_database(self, database):
        """
        Changes the current database without having to disconnect and reconnect
        """
        # cursor = self.connection.cursor()
        # cursor.execute('use `{}`'.format(database))
        # cursor.close()
        if self.connection is None:
            print('ERROR: There is no connection active; could not change db')
            return
        try:
            self.connection.select_db(database)
        except (pymysql.err.OperationalError, pymysql.err.InternalError) as e:
            self.__last_error = [e.args[0], e.args[1]]
            if self.debug:
                print('ERROR {}: {}'.format(e.args[0], e.args[1]))
            return
        self.database = database
        if self.debug:
            print('Changed database to \'{}\''.format(self.database))

    def execute(self, command, dryrun=False):
        """
        Sends a single query to a previously connected server instance, returns
        if that query was successful, and the rows read if it was a SELECT
        """

        # we are not connected, abort immediately
        if self.connection is None:
            return {"query": command, "host": self.host, "port": self.port,
                    "database": self.database, "success": False,
                    "errno": self.last_error[0], "errmsg": self.last_error[1]}
        cursor = self.connection.cursor()
        try:
            if dryrun:
                print(("We will *NOT* execute \'{}\' on {}:{}/{} because"
                       "this is a dry run.").format(
                    command, self.host, self.port, self.database))
                cursor.execute('SELECT \'success\' as dryrun')
            else:
                if self.debug:
                    print('Executing \'{}\''.format(command))
                cursor.execute(command)
        except (pymysql.err.ProgrammingError, pymysql.err.OperationalError) as e:
            cursor.close()
            query = command
            host = self.host
            port = self.port
            database = self.database
            self.__last_error = [e.args[0], e.args[1]]
            if self.debug:
                print('ERROR {}: {}'.format(e.args[0], e.args[1]))
            return {"query": query, "host": host, "port": port,
                    "database": database, "success": False,
                    "errno": self.last_error[0], "errmsg": self.last_error[1]}

        rows = None
        fields = None
        query = command
        host = self.host
        port = self.port
        database = self.database
        if cursor.rowcount > 0:
            rows = cursor.fetchall()
            fields = tuple([x[0] for x in cursor.description])
        numrows = cursor.rowcount
        cursor.close()

        return {"query": query, "host": host, "port": port,
                "database": database, "success": True, "numrows": numrows,
                "rows": rows, "fields": fields}

    def disconnect(self):
        """
        Ends the connection to a database, freeing resources. No more queries
        will be able to be sent to this connection id after this is executed
        until a new connection is open.
        """
        if self.debug:
            print('Disconnecting from {}:{}/{}'.format(self.port, self.host,
                                                       self.database))
        if self.connection is not None:
            self.connection.close()
            self.connection = None


def parse_args():
    """
    Performs the parsing of execution parameters, and returns the object
    containing them
    """
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--host', '-h', help="""the hostname or dns to connect
                        to.""", default='localhost')
    parser.add_argument('--port', '-P', type=int, help='the port to connect',
                        default=3306)
    parser.add_argument('--verbose', '-v', action='store_true', dest='debug',
                        help='Enable debug mode for execution trace.')
    parser.add_argument('--slave-status', action='store_true', dest='slave_status',
                        help='Enable SHOW SLAVE STATUS execution (blocking).')
    parser.add_argument('--process', action='store_true', dest='process',
                        help='Return the list of processes running (only available for localhost).')
    parser.add_argument('--icinga', action='store_true', dest='icinga',
                        help='Output in icinga format rather than just the status.')
    parser.add_argument('--connect-timeout', type=float, default=1.0, dest='connect_timeout',
                        help='How much time to wait for mysql to connect.')
    parser.add_argument('--query-timeout', type=float, default=1.0, dest='query_timeout',
                        help='Max execution query limit.')
    parser.add_argument('--shard', default=None,
                        help='Only check this replication channel/heartbeat row.')
    parser.add_argument('--primary-dc', dest='primary_dc', default='eqiad',
                        help='Set primary datacenter (by default, eqiad).')
    parser.add_argument('--check_read_only', dest='read_only', default=None,
                        help='Check read_only variable matches the given value.')
    parser.add_argument('--check_warn_lag', type=float, dest='warn_lag', default=15.0,
                        help='Lag from which a Warning is returned. By default, 15 seconds.')
    parser.add_argument('--check_crit_lag', type=float, dest='crit_lag', default=300.0,
                        help='Lag from which a Critical is returned. By default, 300 seconds.')
    parser.add_argument('--check_num_processes', type=int, dest='num_processes', default=None,
                        help='Number of mysqld processes expected. Requires --process')
    parser.add_argument('--check_warn_connections', type=int, dest='warn_connections', default=1000,
                        help='Lag from which a Warning is returned. By default, 15 seconds.')
    parser.add_argument('--check_crit_connections', type=int, dest='crit_connections', default=4995,
                        help='Lag from which a Critical is returned. By default, 300 seconds.')
    parser.add_argument('--help', '-?', '-I', action='help',
                        help='show this help message and exit')
    return parser


def get_var(conn, name, scope='GLOBAL', type='VARIABLES'):
    if scope in ['GLOBAL', 'SESSION'] and type in ['VARIABLES', 'STATUS']:
        result = conn.execute("SHOW {} {} like '{}'".format(scope, type, name))
        if result["success"]:
            return result["rows"][0][1]
    return None


def get_replication_status(conn, connection_name=None):
    """
    Provides replication status information to the given host.
    If connection_name is given, and such a named replication channel exists
    (MariaDB only), it returns a dictionary with the specific connection
    information.
    If no connection_name is given, it will return an array of dictionaries,
    one per replication channel.
    None will be returned if no replication channels are found (or none are found
    with the given name).
    """
    if connection_name is None:
        result = conn.execute("SHOW ALL SLAVES STATUS")
    else:
        result = conn.execute("SHOW SLAVE '{}' STATUS".format(connection_name))
    if result["success"] and result["numrows"] > 0:
        status = list()
        for channel in result["rows"]:
            status.append(dict(zip(result["fields"], channel)))
        return status
    else:
        return None


def get_heartbeat_status(conn, shard=None, primary_dc='eqiad', db='heartbeat', table='heartbeat'):
    if primary_dc not in ['eqiad', 'codfw']:
        return None
    if shard is None:
        query = """
        SELECT shard,
               min(greatest(0, TIMESTAMPDIFF(MICROSECOND, ts, UTC_TIMESTAMP(6)) - 500000)) AS lag
        FROM {}.{}
        WHERE datacenter = '{}'
        GROUP BY shard
        """.format(db, table, primary_dc)
    else:
        query = """
        SELECT shard,
               min(greatest(0, TIMESTAMPDIFF(MICROSECOND, ts, UTC_TIMESTAMP(6)) - 500000)) AS lag
        FROM {}.{}
        WHERE datacenter = '{}'
        AND shard = '{}'
        """.format(db, table, primary_dc, shard)
    result = conn.execute(query)
    if result["success"] and result["numrows"] > 0:
        status = dict()
        for channel in result["rows"]:
            if channel[1] is not None:
                status[channel[0].decode('utf-8')] = int(channel[1])/1000000
        if len(status) == 0:
            return None
        else:
            return status
    else:
        return None


def get_processes(process_name):
    try:
        return list(map(int, subprocess.check_output(['/bin/pidof', process_name]).split()))
    except subprocess.CalledProcessError:
        return list()


def get_status(options):
    status = dict()

    if options.process and options.host != 'localhost':
        print("ERROR: Checking process is only allowed on localhost")
        sys.exit(-1)
    elif options.process:
        mysqld_processes = get_processes('mysqld')
        status['mysqld_processes'] = mysqld_processes

    time_before_connect = time.time()
    mysql = WMFMariaDB(host=options.host, port=options.port,
                       connect_timeout=options.connect_timeout,
                       debug=options.debug)
    time_after_connect = time.time()

    wait_timeout = math.ceil(options.query_timeout)
    result = mysql.execute("""SET SESSION innodb_lock_wait_timeout = {0},
                                  SESSION lock_wait_timeout = {0},
                                  SESSION wait_timeout = {0}""".format(wait_timeout))

    if mysql.connection is None or result is None:
        status['connection'] = None
    else:
        status['connection'] = 'ok'
        version = get_var(mysql, 'version')
        read_only = get_var(mysql, 'read_only')
        uptime = get_var(mysql, 'Uptime', type='STATUS')
        ssl = get_var(mysql, 'Ssl_cipher', type='STATUS')
        ssl_expiration = get_var(mysql, 'Ssl_server_not_after', type='STATUS')
        threads_connected = get_var(mysql, 'Threads\_connected', type='STATUS')
        total_queries = get_var(mysql, 'Queries', type='STATUS')
        now = time.time()  # get the time here for more exact QPS calculations
        if options.slave_status:
            replication = get_replication_status(mysql)

        time_before_heartbeat = time.time()
        heartbeat = get_heartbeat_status(mysql,
                                         primary_dc=options.primary_dc,
                                         shard=options.shard)
        time_after_heartbeat = time.time()
        mysql.disconnect()

        if version is not None:
            status['version'] = version
        if read_only is not None:
            status['read_only'] = read_only == 'ON'

        if uptime is not None:
            status['uptime'] = int(uptime)

        if ssl is None or ssl == '':
            status['ssl'] = False
        else:
            status['ssl'] = True
            if ssl_expiration is not None and ssl_expiration != '':
                try:
                    # We assume we will be always using GMT
                    status['ssl_expiration'] = time.mktime(datetime.strptime(
                            ssl_expiration, '%b %d %H:%M:%S %Y %Z').timetuple())
                except ValueError:
                    status['ssl_expiration'] = None

        if total_queries is not None:
            status['total_queries'] = int(total_queries)

        if threads_connected is not None:
            status['datetime'] = now
            status['threads_connected'] = int(threads_connected)

        if heartbeat is not None and len(heartbeat) > 0:
            status['heartbeat'] = heartbeat
            status['query_latency'] = time_after_heartbeat - time_before_heartbeat

        if options.slave_status and replication is not None and len(replication) > 0:
            status['replication'] = dict()
            for channel in replication:
                replication_status = dict()
                replication_status['Slave_IO_Running'] = channel['Slave_IO_Running']
                replication_status['Slave_SQL_Running'] = channel['Slave_SQL_Running']
                replication_status['Seconds_Behind_Master'] = channel['Seconds_Behind_Master']
                io_error = channel['Last_IO_Error']
                replication_status['Last_IO_Error'] = io_error if io_error != '' else None
                # FIXME may contain private data, needs filtering:
                sql_error = channel['Last_SQL_Error']
                replication_status['Last_SQL_Error'] = sql_error if sql_error != '' else None
                status['replication'][channel['Connection_name']] = replication_status

        status['connection_latency'] = time_after_connect - time_before_connect

    return status


def icinga_check(options):
    OK = 0
    WARNING = 1
    CRITICAL = 2
    UNKNOWN = 3

    status = get_status(options)
    if status['connection'] is None:
        print("Could not connect to {}:{}".format(options.host, options.port))
        sys.exit(CRITICAL)

    time.sleep(1)
    second_status = get_status(options)

    msg = ''
    unknown_msg = []
    warn_msg = []
    crit_msg = []
    ok_msg = []

    # Version and uptime for now cannot generate alerts
    ok_msg.append('Version {}'.format(status['version']))
    ok_msg.append('Uptime {}s'.format(status['uptime']))

    # check processes
    if options.num_processes is not None:
        if 'mysqld_processes' not in status:
            unknown_msg.append("Process monitoring was requested, but it wasn't configured")
        else:
            num_processes = len(status['mysqld_processes'])
            if num_processes != options.num_processes:
                crit_msg.append('{} mysqld process(es) running, expected {}'.format(
                        num_processes, options.num_processes))
            else:
                ok_msg.append('{} mysqld process(es)'.format(len(status['mysqld_processes'])))
    elif 'mysqld_processes' in status:
        ok_msg.append('{} mysqld process(es)'.format(len(status['mysqld_processes'])))

    # check read only is correct
    if options.read_only is not None:
        expected_read_only = options.read_only.lower() in ['true', '1', 'on', 'yes', 't', 'y']
        if status['read_only'] != expected_read_only:
            crit_msg.append('read_only: "{}", expected "{}"'.format(status['read_only'],
                            expected_read_only))
        else:
            ok_msg.append('read_only: {}'.format(status['read_only']))
    else:
        ok_msg.append('read_only: {}'.format(status['read_only']))

    # check lag
    if 'heartbeat' in status:
        for connection_name, lag in status['heartbeat'].items():
            if options.crit_lag and lag >= options.crit_lag:
                crit_msg.append('{} lag is {:.2f}s'.format(connection_name, lag))
            elif options.crit_lag and lag >= options.warn_lag:
                warn_msg.append('{} lag is {:.2f}s'.format(connection_name, lag))
            else:
                ok_msg.append('{} lag: {:.2f}s'.format(connection_name, lag))

    # check crit_connections
    if (options.crit_connections is not None and
            status['threads_connected'] >= options.crit_connections):
        crit_msg.append('{} client(s)'.format(status['threads_connected']))
    elif (options.warn_connections is not None and
            status['threads_connected'] >= options.warn_connections):
        warn_msg.append('{} client(s)'.format(status['threads_connected']))
    else:
        ok_msg.append('{} client(s)'.format(status['threads_connected']))

    # QPS and latencies (cannot yet generate alarms)
    # Note the monitoring will create ~10 QPS more than if monitoring wasn't active
    qps = ((second_status['total_queries'] - status['total_queries']) /
           (second_status['datetime'] - status['datetime']))
    ok_msg.append('{:.2f} QPS'.format(qps))

    ok_msg.append('connection latency: {:.6f}s'.format(status['connection_latency']))
    if 'query_latency' in status:
        ok_msg.append('query latency: {:.6f}s'.format(status['query_latency']))

    exit_code = None
    if len(crit_msg) > 0:
        msg = msg + 'CRIT: ' + ', '.join(crit_msg) + '; '
        if exit_code is None:
            exit_code = CRITICAL

    if len(warn_msg) > 0:
        msg = msg + 'WARN: ' + ', '.join(warn_msg) + '; '
        if exit_code is None:
            exit_code = WARNING

    if len(unknown_msg) > 0:
        msg = msg + 'UNKNOWN: ' + ', '.join(unknown_msg) + '; '
        if exit_code is None:
            exit_code = UNKNOWN

    if len(ok_msg) > 0:
        if exit_code is None:
            msg = msg + ', '.join(ok_msg)
            exit_code = OK
        else:
            msg = msg + 'OK: ' + ', '.join(ok_msg)

    print(msg)
    sys.exit(exit_code)


def main():
    parser = parse_args()
    options = parser.parse_args()

    if options.icinga:
        icinga_check(options)
    else:
        status = get_status(options)
        print(json.dumps(status))


if __name__ == "__main__":
    main()
