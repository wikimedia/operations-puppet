#!/usr/bin/env python
# written in 2.6.6 on CentOS 6. All other versions untested.
#Header Info
__author__= 'Kirk Hammond'
__email__ = 'kirkdhammond@gmail.com'
__version__ = '1.0'
__license__ = "GPLv3"
__maintainer__ = "Kirk Hammond"
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


# parse command arguemnts and return options
def parse_args():
    parser = OptionParser()
    parser.description = "Check streaming replication delay"
    parser.version = __version__
    parser.add_option("-H", "--host", dest="hostname", default="127.0.0.1",
                      help="Name of the host you are checking")
    parser.add_option("-O", "--port", dest="port", default="5432",
                       help="Port you will connect to the database with")
    parser.add_option("-U", "--user", dest="username", default="postgres",
                       help="Username for the database")
    parser.add_option("-P", "--password", dest="password",
                       help="Password the database")
    parser.add_option("-D", "--database", dest="database",
                       help="Datbase you are checking") 
    parser.add_option("-W", "--warn", dest="warn", default="300",
                       help="Warning alert delay in seconds") 
    parser.add_option("-C", "--crit", dest="crit", default="1800",
                       help="Critical alert delay in seconds") 
    (options, args) = parser.parse_args()
    return options


# check delay using options from parse_args
def check_delay(options):
    username = str(options.username)
    password = str(options.password)
    port = str(options.port)
    hostname = str(options.hostname)
    database = str(options.database)
    conn_string = "host=" + hostname + " dbname=" + database + " user=" + username + " password=" + password
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    cursor.execute('SELECT CASE WHEN pg_last_xlog_receive_location() = pg_last_xlog_replay_location() THEN 0 ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp()) END AS log_delay;')
    delay = cursor.fetchall()
    delay = delay.pop()
    delay = delay[0]
    return delay


# return results and graphing data to Nagios
def nagios(delay,options):
    #nagios return codes
    UNKNOWN = -1
    OK = 0
    WARNING = 1
    CRITICAL = 2
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

    # execute command using options from parse_args
    delay = check_delay(options)

    #call nagios process
    nagios(delay,options)


# call main function
if __name__ == '__main__':
  main()
