#!/usr/bin/python

import os
import deploylib

def main():
    prefix = os.environ['DEPLOY_ROLLOUT_PREFIX']
    tag = os.environ['DEPLOY_ROLLOUT_TAG']
    force = os.environ['DEPLOY_FORCE']
    if force:
        force = "True"
    else:
        force = "False"
    #TODO: Use this message to notify IRC
    #msg = os.environ['DEPLOY_DEPLOY_TEXT']

    deploylib.update_repos(prefix, tag)
    deploylib.fetch(prefix)
    deploylib.checkout(prefix, force)

if __name__ == "__main__":
    main()
