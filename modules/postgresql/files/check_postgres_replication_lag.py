#!/usr/bin/env python
# written in 2.6.6 on CentOS 6. All other versions untested.
# WMF edited and maintained by Alexandros Kosiaris. Tested on Debian Jessie
#Header Info
__author__= 'Kirk Hammond'
__email__ = 'kirkdhammond@gmail.com'
__version__ = '1.0'
__license__ = "GPLv3"
__maintainer__ = "Alexandros Kosiaris"
__status__ = "Production"
__credits__ = "Kirk Hammond"

"""
This script will check the hot standby replication delay of a postgresql database.
It is more secure to provide the user executing the script with a .pgpass file than to include the password in the script.
"""


#import libraries
from optparse import OptionParser, OptionGroup
import psycopg2
import sys
import socket

#nagios return codes
UNKNOWN = -1
OK = 0
WARNING = 1
CRITICAL = 2

# parse command arguemnts and return options
def parse_args():
    parser = OptionParser()
    parser.description = "Check streaming replication delay"
    parser.version = __version__
    parser.add_option("-H", "--host", dest="hostname", default="127.0.0.1",
                      help="Name of the host you are checking")
    parser.add_option("-m", "--master", dest="master",
                      help="Name of the master of the host you are checking")
    parser.add_option("-O", "--port", dest="port", default="5432",
                       help="Port you will connect to the database with")
    parser.add_option("-U", "--user", dest="username", default="postgres",
                       help="Username for the database")
    parser.add_option("-P", "--password", dest="password",
                       help="Password the database")
    parser.add_option("-D", "--database", dest="database",
                       help="Database you are checking")
    parser.add_option("-W", "--warn", dest="warn", default="300",
                       help="Warning alert delay in seconds")
    parser.add_option("-C", "--crit", dest="crit", default="1800",
                      help="Critical alert delay in seconds")
    parser.add_option("-R", "--raw", action="store_true", dest="raw", default=False,
                      help="Only outputs the current lag, with no formatting")
    (options, args) = parser.parse_args()
    if not options.master:
        parser.error('master not given')
    if not options.password:
        parser.error('password not given')
    if not options.database:
        parser.error('database not given')
    return options


# execute SQL query using options from parse_args
# This function creates and closes connections to clear up after itself. This is
# not the most efficient thing to do but for a monitoring app it is probably fine
def execute_query(query, options, on_master=False):
    username = str(options.username)
    password = str(options.password)
    port = str(options.port)
    if on_master:
        hostname = str(options.master)
    else:
        hostname = str(options.hostname)
    database = str(options.database)
    conn_string = "host=" + hostname + " dbname=" + database + " user=" + username + " password=" + password
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    cursor.execute(query)
    result = cursor.fetchall()
    cursor.close()
    conn.close()
    return result

# check we are in recovery
def check_recovery(options):
    query = 'SELECT pg_is_in_recovery();'
    recovery = execute_query(query, options)
    recovery = recovery.pop()
    recovery = recovery[0]
    return recovery


def check_master_active(options):
    query = 'SELECT * from pg_stat_replication;'
    slaves = execute_query(query, options, True)
    if len(slaves) == 0:
        return False
    else:
        # Note: suboptimal and does not cover all corner cases but ok for now
        my_ip = socket.gethostbyname(socket.gethostname())
        for slave in slaves:
            # 4th field (counting from 0) is client_addr
            if slave[4] == my_ip:
                return True
    return False


# check delay using options from parse_args
def check_delay(options):
    query = 'SELECT CASE WHEN pg_last_xlog_receive_location() = pg_last_xlog_replay_location() THEN 0 ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp()) END AS log_delay;'
    delay = execute_query(query, options)
    delay = delay.pop()
    delay = delay[0]
    return delay


# return results and graphing data to Nagios
def nagios_delay(delay, options):
    warn = float(options.warn)
    crit = float(options.crit)
    #pop delay out of list and get float out of tuple for direct comparison to warn/crit float values
    if delay > crit:
        print  "CRITICAL - Rep Delay is:", str(delay), 'Seconds', '| Seconds=' + str(delay) + 's' + str(";") + str(warn) + str(";") + str(crit) + str(";" ) + str("14400")
        sys.exit(CRITICAL)
    elif delay > warn:
        print "WARNING  - Rep Delay is:", str(delay), 'Seconds', '| Seconds=' + str(delay) + 's' + str(";") + str(warn) + str(";") + str(crit) + str(";" ) + str("14400")
        sys.exit(WARNING)
    elif delay < warn and delay < crit:
        print "OK - Rep Delay is:", str(delay), 'Seconds', '| Seconds=' + str(delay) + 's' + str(";") + str(warn) + str(";") + str(crit) + str(";" ) + str("14400")
        sys.exit(OK)
    else:
        print  "UNKNOWN"
        sys.exit(UNKNOWN)


# main function, controls flow of script
def main():

    #call parse_arges and return options for script
    options = parse_args()

    # Check first that we are indeed in recovery
    is_in_recovery = check_recovery(options)
    if not is_in_recovery:
        print "CRITICAL: Server is not in recovery"
        sys.exit(CRITICAL)

    # Then check that we have an active connection to a master
    master_active = check_master_active(options)
    if not master_active:
        print "CRITICAL: Master reports slave not active"
        sys.exit(CRITICAL)

    # execute command using options from parse_args
    delay = check_delay(options)
    if options.raw:
        print delay
    else:
        nagios_delay(delay, options)


# call main function
if __name__ == '__main__':
  main()
