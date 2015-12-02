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
import logging

log = logging.getLogger(__name__)


def __virtual__():
    return 'deploy_redis'


def _get_serv():
    '''
    Return a redis server object
    '''
    deployment_config = __pillar__.get('deployment_config')
    deploy_redis = deployment_config['redis']
    socket_connect_timeout = deploy_redis.get('socket_connect_timeout')
    if socket_connect_timeout is not None:
        socket_connect_timeout = int(socket_connect_timeout)
    serv = redis.Redis(host=deploy_redis['host'],
                       port=int(deploy_redis['port']),
                       db=int(deploy_redis['db']),
                       socket_timeout=socket_connect_timeout)
    return serv


def returner(ret):
    '''
    Return data to a redis data store
    '''
    function = ret['fun']
    log.debug('Entering deploy_redis returner')
    log.debug('function: {0}'.format(function))
    if not function.startswith('deploy.'):
        return False
    ret_data = ret['return']
    log.debug('ret_data: {0}'.format(ret_data))
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
    minion_key = 'deploy:{0}:minions:{1}'.format(repo, minion)
    if function == "deploy.fetch":
        if ret_data['status'] == 0:
            serv.hset(minion_key, 'fetch_tag', ret_data['tag'])
        serv.hset(minion_key, 'fetch_status', ret_data['status'])
        serv.hset(minion_key, 'fetch_timestamp', timestamp)
    elif function == "deploy.checkout":
        if ret_data['status'] == 0:
            serv.hset(minion_key, 'tag', ret_data['tag'])
        serv.hset(minion_key, 'checkout_status', ret_data['status'])
        serv.hset(minion_key, 'checkout_timestamp', timestamp)
    elif function == "deploy.restart":
        if 'status' in ret_data:
            serv.hset(minion_key, 'restart_status', ret_data['status'])
            serv.hset(minion_key, 'restart_timestamp', timestamp)
