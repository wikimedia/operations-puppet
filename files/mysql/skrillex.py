#!/usr/bin/python

import _mysql
import sys

def parseCommandLine():
    """
    Parses the command line arguments, and sets configuration options
    in dictionary configuration.
    """
    
    import sys, argparse

    parser = argparse.ArgumentParser(description='skrillex [options] db::group  \"some sql;\"')
    parser.add_argument('-c','--config', help='Specify yaml config file. Default ./skrill.yaml')
    parser.add_argument('-q','--query', help='Specify a MySQL query to run', required=True)
    parser.add_argument('-g','--group', help='Specify a group of mysql instances on which to run a query', required=True)
    parser.add_argument('-a','--forall', action='store_true', help='Run on all databases in the MySQL instance')
    args = vars(parser.parse_args())

    return args

def loadConfig(configFile):
    import yaml

    stream = open(configFile, 'r')
    config = yaml.load(stream)
    stream.close()

    return config

def setInstances(commandLineArg, topology):
    import re
    executionDict = {}
    fail=False

    if commandLineArg == "all::all":
        for logicalGroup in topology:
            for shard in topology[logicalGroup]:
                key = logicalGroup + shard
                executionDict[key] = topology[logicalGroup][shard]
    elif re.match("sanitarium::", commandLineArg):
        shard = commandLineArg.split(":")[2]
        if re.match("s[1-7]", shard):
            executionDict = {shard: topology["sanitarium"][shard]}
        elif shard == "all"
            executionDict = topology["sanitarium"]
        else:
            fail = True
    elif re.match("labsdb::", commandLineArg):
        shard = commandLineArg.split(":")[2]
        if re.match("s[1-7]", shard):
            executionDict = {shard : topology["labsdb"][shard]}
        elif shard == "all"
            executionDict = topology["labsdb"]
        else:
            fail = True
    else:
        fail = True

    if fail == True:
        print "group must be one of the following:"
        print "all::all : all sanitarium and all labsdb instances"
        print "sanitarium::all : all sanitarium instances"
        print "labsdb::all : all labsdb instances"
        print "sanitarium::SHARD : specific sanitarium instance"
        print "labsdb::SHARD : specific labsdb instance"
        sys.exit(2)

    return executionDict

def executeQuery(instanceHost, instancePort, instancePassword, instanceQuery, forall):
    con = None

    try:
        con = _mysql.connect(host=instanceHost, port=instancePort, user="root", passwd=instancePassword)
        if forall == True:
            con.query("show databases like '%wik%';")
            d = con.store_result()
            dbtuple = sum(d.fetch_row(maxrows=0), ())
            for database in dbtuple:
                con.select_db(database)
                con.query(instanceQuery)
                r = con.store_result()
                rows = r.fetch_row(maxrows=0)
                print "Output from " + instanceHost + ":" + str(instancePort) + " on " + str(database) +  " : " + str(rows)
                
        else:
            con.query(instanceQuery)
            r = con.store_result()
            rows = r.fetch_row(maxrows=0)

            print "Output from " + instanceHost + ":" + str(instancePort) + " : " + str(rows)
    
    except _mysql.Error, e:
        print "Error %d: %s" % (e.args[0], e.args[1])
        sys.exit(1)

    finally:
        if con:
            con.close()

def main():
    ## Set any defaults that need setting
    yamlConfig='./skrillex.yaml'

    ## parse comnmand line and set defaults
    args = parseCommandLine()
    if args["config"] == None:
        args["config"] = yamlConfig
    if args["myconf"] == None:
        args["myconf"] = mysqlConfig

    ## load yaml file
    topology = loadConfig(args["config"])

    ## create dict of all instances that will be queried
    executionInstances = setInstances(args["group"], topology)

    ## iterate over dict and actuall run queries
    for instance in executionInstances:
        instanceHost =  executionInstances[instance]["host"]
        instancePort =  executionInstances[instance]["port"]
        instancePassword =  executionInstances[instance]["mysqlpasswd"]

        if args["forall"] == True:
            executeQuery(instanceHost, instancePort, instancePassword, args["query"], True)
        else:
            executeQuery(instanceHost, instancePort, instancePassword, args["query"], False)

if __name__ == '__main__':
    main()
