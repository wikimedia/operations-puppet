#!/usr/bin/python3
'''
Archives graphite metrics for labs hosts that have been deleted.

This is done for each project by:
    1. Gets list of hosts that have any metric defined
    2. Gets list of hosts in the project
    3. Diff (1) against (2), this is hosts with metrics but don't exist
    4. Assume these are all deleted hosts, and archive them.

This leaves out the instances that are deleted and then re-created
before this script runs with the same name, but that is perhaps ok
for now.

Logs to /var/log/graphite/instance-archiver.log
'''
import errno
import logging
import os
import time

import mwopenstackclients
from keystoneauth1.exceptions.http import Unauthorized as KeystoneUnauthorisedException

WHISPER_PATH = '/srv/carbon/whisper'


def makedirs_exist_ok(path, mode=0o777):
    try:
        os.makedirs(path, mode)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


def archive_host(project_name, host_name):
    '''
    Archives all metrics for a particular host in a particular project.

    Moves them to archived_metrics/<project-name>/<timestamp-instancename>
    '''
    cur_path = os.path.join(WHISPER_PATH, project_name, host_name)
    if os.path.exists(cur_path):
        archived_name = '%s-%s' % (
            time.strftime('%Y%m%d%H%M%S'),
            host_name
        )
        archived_path = os.path.join(
            WHISPER_PATH,
            'archived_metrics',
            project_name,
            archived_name
        )
        makedirs_exist_ok(os.path.dirname(archived_path), 0o755)
        os.rename(cur_path, archived_path)
        logging.info('Archived host %s, renamed to %s', host_name, archived_name)
    else:
        logging.warn('Metrics for host %s not found at path %s', host_name, cur_path)


def get_hosts_with_metrics(project_name):
    '''
    Get list of hosts with at least one metric from this project
    '''
    project_path = os.path.join(WHISPER_PATH, project_name)
    if os.path.exists(project_path):
        return os.listdir(project_path)
    else:
        return []


def get_deleted_instances():
    '''
    Get list of instances that have been deleted

    Returns a dictionary with key being the project name and value a set of deleted hostnames
    '''
    clients = mwopenstackclients.Clients(oscloud='novaobserver')
    allprojectslist = [project.name for project in clients.allprojects()]

    deleted_hosts = {}
    for project in allprojectslist:
        hosts_with_metrics = get_hosts_with_metrics(project)
        try:
            actual_hosts = [instance.name for instance in clients.allinstances(projectid=project)]
        except KeystoneUnauthorisedException:
            continue
        deleted = set(hosts_with_metrics) - set(actual_hosts)
        if deleted:
            deleted_hosts[project] = deleted
    return deleted_hosts


if __name__ == '__main__':
    logging.basicConfig(filename='/var/log/graphite/instance-archiver.log',
                        format='%(asctime)s %(message)s',
                        level=logging.INFO)
    try:
        deleted_hosts = get_deleted_instances()
        if not deleted_hosts:
            logging.info('No hosts to archive, all OK')
        else:
            logging.info('Found %d host(s) in %d project(s) to archive',
                         len(deleted_hosts),
                         sum([len(hosts) for hosts in list(deleted_hosts.values())]))
            for project, hosts in list(deleted_hosts.items()):
                for host in hosts:
                    archived_name = archive_host(project, host)
    except Exception:
        logging.exception('Exception!')
