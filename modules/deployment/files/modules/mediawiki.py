'''
MediaWiki deployment module for trebuchet
'''

import os
import subprocess


def generate_localization_cache(repo):
    '''
    Generate the localization cache in the shadow_reference repo.
    '''
    config = __salt__['deploy.get_config'](repo)
    common_config = __salt__['deploy.get_config']('mediawiki/common')
    cmd = 'php {0}/maintenance/mergeMessageFileList.php' \
          '--list-file={1}/wmf-config/extension-list' \
          '--output={1}/wmf-config/ExtensionMessages-{2}.php'
    cmd.format(config['shadow_location'],
               common_config['shadow_location'],
               os.path.basename(repo))
    status = __salt__['cmd.retcode'](cmd)
    if status != 0:
        return status
    cmd = 'php {0}/maintenance/rebuildLocalisationCache.php' \
          '--outdir={0}/cache/l10n --threads=12'
    cmd = cmd.format(config['shadow_location'])
    status = __salt__['cmd.retcode'](cmd)
    return status


def update_localization_cache(repo):
    '''
    Update the repo's localization cache, based on the reference repo's cache.
    '''
    config = __salt__['deploy.get_config'](repo)
    common_config = __salt__['deploy.get_config']('mediawiki/common')
    shadow_cache = '{0}/cache'.format(config['shadow_location'])
    current_cache = '{0}/cache'.format(config['location'])
    cmd = 'rsync -a {0}/l10n {1}'.format(shadow_cache, current_cache)
    status = __salt__['cmd.retcode'](cmd)
    if status != 0:
        return status
    messages = '{0}/wmf-config/ExtensionMessages-{1}.php'
    shadow_messages = messages.format(common_config['shadow_location'],
                                      os.path.basename(repo))
    current_messages = messages.format(common_config['location'],
                                       os.path.basename(repo))
    cmd = 'rsync -a {0} {1}'.format(shadow_messages, current_messages)
    status = __salt__['cmd.retcode'](cmd)
    return status
