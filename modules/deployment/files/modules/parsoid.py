'''
Parsoid deployment module for git-deploy / salt
'''

import os


def config_symlink(repo):
    '''
    Put a localsettings.js symlink in the Parsoid checkout pointing to the
    config checkout
    '''
    repolocs = __pillar__.get('repo_locations')
    repoloc = repolocs[repo]
    lsSymlinkPath = repoloc + '/js/api/localsettings.js'
    nmSymlinkPath = repoloc + '/js/node_modules'
    if not __salt__['file.file_exists'](lsSymlinkPath):
        try:
            os.symlink('../../../config/localsettings.js', lsSymlinkPath)
        except OSError:
            return 1
    if not __salt__['file.file_exists'](nmSymlinkPath):
        try:
            os.symlink('../../config/node_modules', nmSymlinkPath)
        except OSError:
            return 1

    return 0


def restart_parsoid(repo):
    '''
    restart the parsoid service
    '''
    if __salt__['service.restart']('parsoid'):
        return 0
    else:
        return 1
