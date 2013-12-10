'''
Return deployment data to a redis server

To enable this returner the minion will need the python client for redis
installed and the following values configured in the pillar config, these
are the defaults:

    deploy_redis.db: '0'
    deploy_redis.host: 'salt'
    deploy_redis.port: 6379
'''

import redis
import time


def __virtual__():
    return 'deploy_redis'


def _get_serv():
    '''
    Return a redis server object
    '''
    deployment_config = __pillar__.get('deployment_config')
    deploy_redis = deployment_config['redis']
    serv = redis.Redis(host=deploy_redis['host'],
                       port=int(deploy_redis['port']),
                       db=int(deploy_redis['db']))
    return serv


def returner(ret):
    '''
    Return data to a redis data store
    '''
    function = ret['fun']
    if not function.startswith('deploy.'):
        return False
    ret_data = ret['return']
    minion = ret['id']
    timestamp = time.time()
    serv = _get_serv()
    if function == "deploy.sync_all":
        for repo, functions in ret_data["stats"].items():
            for func, data in functions.items():
                _record_function(serv, func, timestamp, minion, data)
    else:
        _record_function(serv, function, timestamp, minion, ret_data)


def _record_function(serv, function, timestamp, minion, ret_data):
    dependencies = ret_data['dependencies']
    # Record data for all dependent repositories
    for dep_data in dependencies:
        _record(serv, function, timestamp, minion, dep_data)
    # Record data for this repo
    _record(serv, function, timestamp, minion, ret_data)


def _record(serv, function, timestamp, minion, ret_data):
    repo = ret_data['repo']
    redis_key = 'deploy:{0}:minions:{1}'.format(repo, minion)
    if function == "deploy.restart":
        if status in ret_data:
            serv.hset(redis_key, 'restart_status', ret_data['status'])
            serv.hset(redis_key, 'restart_timestamp', timestamp)
    if function == "deploy.fetch":
        if ret_data['status'] == 0:
            serv.hset(redis_key, 'fetch_tag', ret_data['tag'])
        serv.hset(redis_key, 'fetch_status', ret_data['status'])
        serv.hset(redis_key, 'fetch_timestamp', timestamp)
    if function == "deploy.checkout":
        if ret_data['status'] == 0:
            serv.hset(redis_key, 'tag', ret_data['tag'])
        serv.hset(redis_key, 'checkout_status', ret_data['status'])
        serv.hset(redis_key, 'checkout_timestamp', timestamp)
