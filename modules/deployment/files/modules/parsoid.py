'''
Parsoid deployment module for git-deploy / salt
'''

import os
import subprocess


def config_symlink(repo):
    '''
    Put a localsettings.js symlink in the Parsoid checkout pointing to the
    config checkout
    '''
    config = __salt__['deploy.get_config'](repo)
    lsSymlinkPath = config['location'] + '/src/api/localsettings.js'
    if not __salt__['file.file_exists'](lsSymlinkPath):
        try:
            os.symlink('../../../config/localsettings.js', lsSymlinkPath)
        except OSError:
            return 1

    return 0

# SSS FIXME: I assume this is not needed anymore
#
#def restart_parsoid(repo):
#    '''
#    restart the parsoid service
#    '''
#    ret = subprocess.call("/etc/init.d/parsoid restart", shell=True)
#    return ret
