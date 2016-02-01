'''
runner: key signer, assumes caller has checked that minion key is safe to sign
'''

import logging
import salt.key


def sign(minion):
    '''
    sign salt key for the specified minion
    '''
    pending = 'minions_pre'

    key = salt.key.Key(__opts__)
    matches = key.name_match(minion)
    keys = {}
    if pending in matches:
        keys[pending] = matches[pending]
    if not keys:
        log = logging.getLogger(__name__)
        log.warn("No unsigned key found for minion: {0}".format(minion))
        return
    key.accept(match_dict=keys)
