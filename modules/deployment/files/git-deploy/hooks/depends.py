#!/usr/bin/python

import os
import deploylib


def main():
    prefix = os.environ['DEPLOY_ROLLOUT_PREFIX']
    tag = os.environ['DEPLOY_ROLLOUT_TAG']
    force = os.environ['DEPLOY_FORCE']
    #TODO: Use this message to notify IRC
    #msg = os.environ['DEPLOY_DEPLOY_TEXT']

    deploylib.update_repos(prefix, tag)
    # In general, for dependent repos, the parent repo is handling
    # fetch and checkout. Some dependent repos also update outside
    # of their parent repos. If the repo forces a sync, then we should
    # handle it.
    if force:
        deploylib.fetch(prefix)
        deploylib.checkout(prefix, "True")

if __name__ == "__main__":
    main()
