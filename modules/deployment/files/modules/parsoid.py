'''
Parsoid deployment module for git-deploy / salt
'''

import os


def config_symlink(repo):
    '''
    Put a localsettings.js symlink in the Parsoid checkout pointing to the config checkout
    '''
    repolocs = __pillar__.get('repo_locations')
    repoloc = repolocs[repo]
    symlinkPath = repoloc + '/js/api/localsettings.js'
    if __salt__['file.file_exists'](symlinkPath):
        try:
            os.symlink('../../../config/localsettings.js', symlinkPath)
        except OSError:
            return 1

    return 0
