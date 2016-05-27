#! /usr/bin/env python
"""
 purge.py       A small tool that allows you to easily purge old entries in
                the eventlog and syslog table

 Author:        Mathieu Poussin <mathieu.poussin@sodexo.com>
 Date:          Mar 2014

 Usage:         This program accepts many arguments :
                --syslog : Enable the syslog table purge
                --eventlog : Enable the eventlog table purge
                --perftimes : Enable the perftime table purge
                --devices-perftimes : Enable the device_pertimes table purge
                INTERVAL : A MySQL compatible interval like "1 YEAR" or
                "3 MONTH", this is how long you should keep your log,
                any entried older than the given interval will be deleted.
                (Defautl is 1 YEAR)


 Ubuntu Linux:  apt-get install python-mysqldb
 RHEL/CentOS:   yum install MySQL-python (Requires the EPEL repo!)
 FreeBSD:       cd /usr/ports/*/py-MySQLdb && make install clean

 Tested on:     Python 2.7.5 / Ubuntu 13.10
"""
try:
    import subprocess
    import sys
    import os
    import json
except:
    print "ERROR: missing one or more of the following python modules:"
    print "sys, subprocess, os, json"
    sys.exit(2)

try:
    import MySQLdb
except:
    print "ERROR: missing the mysql python module:"
    print "On Ubuntu: apt-get install python-mysqldb"
    print "On RHEL/CentOS: yum install MySQL-python"
    print "On FreeBSD: cd /usr/ports/*/py-MySQLdb && make install clean"
    sys.exit(2)


"""
    Parse Arguments
    Attempt to use argparse module.  Probably want to use this moving forward
    especially as more features want to be added to this wrapper.
    and
    Take the amount of threads we want to run in parallel from the commandline
    if None are given or the argument was garbage, fall back to default of 16
"""
try:
    import argparse
    parser = argparse.ArgumentParser(description='Purge task for Observium')
    parser.add_argument(
        'interval', nargs='?', type=str, default="1 YEAR", help='How much data to keep')
    parser.add_argument(
        '--syslog', help='Purge the syslog table', action='store_true', default=False)
    parser.add_argument(
        '--eventlog', help='Purge the eventlog table', action='store_true', default=False)
    parser.add_argument(
        '--perftimes', help='Purge the perf_times table', action='store_true', default=False)
    parser.add_argument(
        '--devices-perftimes', help='Purge the devices_pertimes table',
        action='store_true', default=False)
    args = parser.parse_args()
    interval = args.interval
    purge_syslog = args.syslog
    purge_eventlog = args.eventlog
    purge_perftimes = args.perftimes
    purge_devices_perftimes = args.devices_perftimes
except ImportError:
    print "WARNING: missing the argparse python module:"
    print "On Ubuntu: apt-get install libpython2.7-stdlib"
    print "On RHEL/CentOS: yum install python-argparse"
    print "On Debian: apt-get install python-argparse"
    sys.exit(2)


"""
    Fetch configuration details from the config_to_json.php script
"""

ob_install_dir = os.path.dirname(os.path.realpath(__file__))
config_file = ob_install_dir + '/config.php'


def get_config_data():
    config_cmd = ['/usr/bin/env', 'php', '%s/config_to_json.php' % ob_install_dir]
    try:
        proc = subprocess.Popen(config_cmd, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
    except:
        print "ERROR: Could not execute: %s" % config_cmd
        sys.exit(2)
    return proc.communicate()[0]

try:
    with open(config_file) as f:
        pass
except IOError as e:
    print "ERROR: Oh dear... %s does not seem readable" % config_file
    sys.exit(2)

try:
    config = json.loads(get_config_data())
except:
    print "ERROR: Could not load or parse observium configuration, are PATHs correct?"
    sys.exit(2)

db_username = config['db_user']
db_password = config['db_pass']
db_server = config['db_host']
db_dbname = config['db_name']

try:
    db = MySQLdb.connect(host=db_server, user=db_username, passwd=db_password, db=db_dbname)
    cursor = db.cursor()
except:
    print "ERROR: Could not connect to MySQL database!"
    sys.exit(2)


if purge_syslog:
    print "Purging syslog"
    query = """DELETE FROM syslog WHERE timestamp <= DATE(NOW() - INTERVAL %s);""" % (interval)
    # print query
    cursor.execute(query)


if purge_eventlog:
    print "Purging eventlog"
    query = """DELETE FROM eventlog WHERE datetime <= DATE(NOW() - INTERVAL %s);""" % (interval)
    # print query
    cursor.execute(query)

if purge_devices_perftimes:
    print "Purging devices_perftimes"
    query = ("DELETE FROM devices_perftimes "
             "WHERE from_unixtime(start) <= DATE(NOW() - INTERVAL %s);") % (interval)
    # print query
    cursor.execute(query)

if purge_perftimes:
    print "Purging perftimes"
    query = ("DELETE FROM perf_times "
             "WHERE from_unixtime(start) <= DATE(NOW() - INTERVAL %s);") % (interval)
    # print query
    cursor.execute(query)

db.commit()
print "Purge complete"
db.close()
