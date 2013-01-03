'''
Return deployment data to a redis server

To enable this returner the minion will need the python client for redis
installed and the following values configured in the pillar config, these
are the defaults:

    deploy_redis.db: '0'
    deploy_redis.host: 'salt'
    deploy_redis.port: 6379
'''

try:
    import redis
    has_redis = True
except ImportError:
    has_redis = False

import time

def __virtual__():
    #if not has_redis:
    #    return False
    return 'deploy_redis'


def _get_serv():
    '''
    Return a redis server object
    '''
    deploy_redis = __pillar__.get('deploy_redis')
    serv = redis.Redis(
            host=deploy_redis['host'],
            port=deploy_redis['port'],
            db=deploy_redis['db'])
    return serv


def returner(ret):
    '''
    Return data to a redis data store
    '''
    if not ret['fun'].startswith('deploy.'):
        return False
    timestamp = time.time()
    serv = _get_serv()
    ret_data = ret['return']
    repo = ret_data['repo']
    minion = ret['id']
    # Ensure this repo exist in the set of repos
    serv.sadd('deploy:repos', repo)
    # Ensure this minion exists in the set of minions
    serv.sadd('deploy:{0}:minions'.format(repo), minion)
    if ret['fun'] == "deploy.fetch" or ret['fun'] == "deploy.sync_all":
        serv.hset('deploy:{0}:minions:{1}'.format(repo, minion), 'fetch_status', ret_data['status'])
        serv.hset('deploy:{0}:minions:{1}'.format(repo, minion), 'fetch_timestamp', timestamp)
    if ret['fun'] == "deploy.checkout" or ret['fun'] == "deploy.sync_all":
        if ret_data['status'] == 0:
            serv.hset('deploy:{0}:minions:{1}'.format(repo, minion), 'tag', ret_data['tag'])
        serv.hset('deploy:{0}:minions:{1}'.format(repo, minion), 'checkout_status', ret_data['status'])
        serv.hset('deploy:{0}:minions:{1}'.format(repo, minion), 'checkout_timestamp', timestamp)
