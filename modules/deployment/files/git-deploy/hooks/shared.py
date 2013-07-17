#!/usr/bin/python

import os
import redis
import getpass
import deploylib


def main():
    prefix = os.environ['DEPLOY_ROLLOUT_PREFIX']
    tag = os.environ['DEPLOY_ROLLOUT_TAG']
    force = os.environ['DEPLOY_FORCE']
    if force:
        force = "True"
    else:
        force = "False"

    log = raw_input("Log message: ")
    serv = redis.Redis(host='localhost', port=6379, db=0)
    serv.rpush("deploy:log", "!log {0} started synchronizing "
               "{1} '{2}'".format(getpass.getuser(), tag, log))

    prefixlib = deploylib.DeployLib(prefix)
    if not prefixlib.get_config():
        return 1
    prefixlib.update_repos(tag)
    prefixlib.fetch()
    if not prefixlib.ask('fetch'):
        return 1
    prefixlib.checkout(force)
    if not prefixlib.ask('checkout', force):
        return 1

    serv.rpush("deploy:log", "!log {0} synchronized "
               "{1} '{2}'".format(getpass.getuser(), tag, log))

if __name__ == "__main__":
    main()
