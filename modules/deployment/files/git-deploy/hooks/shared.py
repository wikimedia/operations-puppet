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

    deploylib.update_repos(prefix, tag)
    deploylib.fetch(prefix)
    if not deploylib.ask(prefix, 'fetch'):
        return 1
    deploylib.checkout(prefix, force)
    if not deploylib.ask(prefix, 'checkout', force):
        return 1

    serv.rpush("deploy:log", "!log {0} synchronized "
               "{1} '{2}'".format(getpass.getuser(), tag, log))

if __name__ == "__main__":
    main()
