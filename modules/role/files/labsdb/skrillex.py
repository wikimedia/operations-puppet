#!/usr/bin/python

import _mysql
import argparse
import re
import sys
import yaml


def parseCommandLine():
    """
    Parses the command line arguments, and sets configuration options
    in dictionary configuration.
    """

    parser = argparse.ArgumentParser(
        description='skrillex [options] db::group  \"some sql;\"',
        epilog='group must be one of the following: '
        'all::all : all sanitarium and all labsdb instances '
        'sanitarium::all : all sanitarium instances '
        'labsdb::all : all labsdb instances '
        'sanitarium::SHARD : specific sanitarium instance '
        'labsdb::SHARD : specific labsdb instance')
    parser.add_argument('-c', '--config',
                        help='Specify yaml config file. '
                             'Default /etc/skrill.yaml')
    parser.add_argument('-q', '--query',
                        help='Specify a MySQL query to run', required=True)
    parser.add_argument('-g', '--group',
                        help='Specify a group of mysql instances '
                             'on which to run a query',
                        required=True)
    parser.add_argument('-a', '--forall', action='store_true',
                        help='Run on all databases in the MySQL instance')
    args = vars(parser.parse_args())

    return args


def loadConfig(configFile):
    stream = open(configFile, 'r')
    config = yaml.load(stream)
    stream.close()

    return config


def setInstances(commandLineArg, topology):
    executionDict = {}
    fail = False

    if commandLineArg == "all::all":
        for logicalGroup, shard in topology.items():
            key = logicalGroup + shard
            executionDict[key] = topology[logicalGroup][shard]
    elif re.match("(sanitarium|labsdb)::", commandLineArg):
        logicalGroup = commandLineArg.split(":")[0]
        shard = commandLineArg.split(":")[2]
        if re.match("s[1-7]", shard):
            executionDict = {shard: topology[logicalGroup][shard]}
        elif shard == "all":
            executionDict = topology[logicalGroup]
        else:
            fail = True
    else:
        fail = True

    if fail is True:
        print "Could not parse db/group. Please see help"
        sys.exit(2)

    return executionDict


def executeQuery(instanceHost, instancePort,
                 instancePassword, instanceQuery, forall):
    con = None

    try:
        con = _mysql.connect(host=instanceHost, port=instancePort, user="root",
                             passwd=instancePassword)
        if forall is True:
            con.query("show databases like '%wik%';")
            d = con.store_result()
            dbtuple = sum(d.fetch_row(maxrows=0), ())
            for database in dbtuple:
                con.select_db(database)
                con.query(instanceQuery)
                r = con.store_result()
                rows = r.fetch_row(maxrows=0)
                print "Output from {0}:{1} on {2} : {3}".format(
                    instanceHost, str(instancePort), str(database), str(rows))

        else:
            con.query(instanceQuery)
            r = con.store_result()
            rows = r.fetch_row(maxrows=0)

            print "Output from {0} on {1} : {2}".format(
                instanceHost, str(database), str(rows))

    except _mysql.Error, e:
        print "Error %d: %s" % (e.args[0], e.args[1])
        sys.exit(1)

    finally:
        if con:
            con.close()


def main():
    # Set any defaults that need setting
    yamlConfig = '/etc/skrillex.yaml'

    # parse comnmand line and set defaults
    args = parseCommandLine()
    if args["config"] is None:
        args["config"] = yamlConfig

    # load yaml file
    topology = loadConfig(args["config"])

    # create dict of all instances that will be queried
    executionInstances = setInstances(args["group"], topology)

    # iterate over dict and actuall run queries
    for instance in executionInstances:
        instanceHost = executionInstances[instance]["host"]
        instancePort = executionInstances[instance]["port"]
        instancePassword = executionInstances[instance]["mysqlpasswd"]

        executeQuery(instanceHost, instancePort,
                     instancePassword, args["query"], args["forall"])

if __name__ == '__main__':
    main()
