#!/usr/bin/python3
"""
Source of canonical truth is the tokenauth.csv file.


 - Get a list of all the users from LDAP
 - Load the current file
 - Do a diff, find new users
 - Add them to file, and also add them to:
   - .kube/config on the user's homedir
   - abac.json for access config
   - create the namespace with appropriate annotation
"""
import argparse
import csv
import json
import logging
import os
import random
import stat
import string
import subprocess
import time

import ldap3
import yaml
TOOL_ALLOWED_RESOURCES = [
    'pods',
    'replicationcontrollers',
    'services',
    'secrets',
    'deployments',
    'replicasets',
    'configmaps',
    'jobs',
    'cronjobs',  # k8s 1.5.x
    'scheduledjobs'  # k8s 1.4.x
]


class User:
    VALID_GROUPS = ('tool', 'infrastructure-readwrite', 'infrastructure-readonly')

    def __init__(self, name, id, token=None, group='tool'):
        """
        'group' can be one of 'tool', 'infrastructure-readwrite' or 'infrastructure-readonly'
        """
        if group not in User.VALID_GROUPS:
            raise ValueError('group should be one of {valid_groups}, found {group} instead'.format(
                valid_groups=', '.join(User.VALID_GROUPS),
                group=group
            ))
        self.name = name
        self.id = id
        self.token = token
        self.group = group


def generate_pass(length):
    """
    Generate a secure password of given length
    """
    password_chars = string.ascii_letters + string.digits
    sysrandom = random.SystemRandom()  # Uses /dev/urandom
    return ''.join([sysrandom.choice(password_chars) for _ in range(length)])


def get_users_from_csv(path):
    """
    Builds list of users from a CSV file in tokenauth format.

    The tokenauth format is documented in http://kubernetes.io/docs/admin/authentication/
    The fields are:
      1. token
      2. username
      3. user id
      4. comma-separated list of groups the user is part of
    """
    users = {}
    with open(path, encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            user = User(row[1], row[2], row[0], row[3])
            users[user.id] = user

    return users


def get_tools_from_ldap(conn, projectname):
    """
    Builds list of all tools from LDAP
    """

    conn.search(
        'ou=people,ou=servicegroups,dc=wikimedia,dc=org',
        '(cn=%s.*)' % projectname,
        ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
        attributes=['uidNumber', 'cn'],
        time_limit=5,
        paged_size=1000
    )

    tools = {}

    for resp in conn.response:
        attrs = resp['attributes']
        tool = User(
            attrs['cn'][0][len(projectname) + 1:],
            attrs['uidNumber'][0],
            group='tool'
        )
        tools[tool.id] = tool

    cookie = conn.result['controls']['1.2.840.113556.1.4.319']['value']['cookie']
    while cookie:
        conn.search('ou=people,ou=servicegroups,dc=wikimedia,dc=org',
                    '(cn=%s.*)' % projectname,
                    ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
                    attributes=['uidNumber', 'cn'],
                    time_limit=5,
                    paged_size=1000,
                    paged_cookie=cookie)
        cookie = conn.result['controls']['1.2.840.113556.1.4.319']['value']['cookie']
        for resp in conn.response:
            attrs = resp['attributes']
            tool = User(
                attrs['cn'][0][len(projectname) + 1:],
                attrs['uidNumber'][0],
                group='tool'
            )
            tools[tool.id] = tool

    return tools


def write_tokenauth(users, path):
    """
    Write a tokenauth file for given list of users

    See http://kubernetes.io/docs/admin/authentication/ for info
    on format of the tokenauth file.
    """
    with open(path, 'w', encoding='utf-8') as f:
        writer = csv.writer(f)
        for user in users:
            writer.writerow((
                user.token,
                user.name,
                user.id,
                user.group
            ))


def write_abac(users, path):
    """
    Write ABAC file for authorization of users and resources they can access

    See http://kubernetes.io/docs/admin/authorization/ for info on format
    of the ABAC file
    """
    def abac_tool_generator(user):
        for resource in TOOL_ALLOWED_RESOURCES:
            yield {
                "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
                "kind": "Policy",
                "spec": {
                    "user": user.name,
                    "namespace": user.name,
                    "resource": resource,
                    "apiGroup": "*"
                }
            }

    def abac_infra_generator(user, readonly=True):
        rule = {
            "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
            "kind": "Policy",
            "spec": {
                "user": user.name,
                "namespace": "*",
                "resource": "*",
                "apiGroup": "*",
            }
        }

        if readonly:
            rule["spec"]["readonly"] = True

        yield rule

    def abac_rule_generator(users):
        yield {
            "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
            "kind": "Policy",
            "spec": {
                "user": "*",
                "nonResourcePath": "*",
                "readonly": True
            }
        }
        yield {
            "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
            "kind": "Policy",
            "spec": {
                "user": "*",
                "resource": "nodes",
                "readonly": True,
                "apiGroup": "*",
            }
        }
        # This allows all users to get info about all namespaces,
        # but not to edit them. This is important, because
        # readonly access to all namespaces is needed for helm
        # to work, but we must make sure users can't write to
        # namespaces - since that could allow them to modify the
        # RunAsUser annotation and gain root on the cluster.
        yield {
            "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
            "kind": "Policy",
            "spec": {
                "user": "*",
                "resource": "namespaces",
                "readonly": True,
                "apiGroup": "*",
                "namespace": "*"
            }
        }

        for user in users:
            if user.group == 'tool':
                # ignore flake8 error as check is currently python2 T184435
                yield from abac_tool_generator(user)  # noqa: E999
            elif user.group == 'infrastructure-readonly':
                yield from abac_infra_generator(user, readonly=True)
            elif user.group == 'infrastructure-readwrite':
                yield from abac_infra_generator(user, readonly=False)
            else:
                raise Exception(
                    'User {tool} has unknown group {group}'.format(tool=user.name, group=user.group)
                )

    with open(path, 'w', encoding='utf-8') as f:
        for rule in abac_rule_generator(users):
            f.write(json.dumps(rule) + '\n')


def write_kubeconfig(user, master):
    """
    Write an appropriate .kube/config for given user to access given master.

    See http://kubernetes.io/docs/user-guide/kubeconfig-file/ for format
    """
    config = {
        'apiVersion': 'v1',
        'kind': 'Config',
        'clusters': [{
            'cluster': {
                'server': master
            },
            'name': 'default'
        }],
        'users': [{
            'user': {
                'token': user.token,
            },
            'name': user.name,
        }],
        'contexts': [{
            'context': {
                'cluster': 'default',
                'user': user.name,
                'namespace': user.name,
            },
            'name': 'default'
        }],
        'current-context': 'default'
    }
    dirpath = os.path.join('/data', 'project', user.name, '.kube')
    path = os.path.join(dirpath, 'config')
    # exist_ok=True is fine here, and not a security issue (Famous last words?).
    os.makedirs(dirpath, mode=0o775, exist_ok=True)
    os.chown(dirpath, int(user.id), int(user.id))
    f = os.open(path, os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW)
    try:
        os.write(f, json.dumps(config, indent=4, sort_keys=True).encode('utf-8'))
        # uid == gid
        os.fchown(f, int(user.id), int(user.id))
        os.fchmod(f, 0o400)
        logging.info('Wrote config in %s', path)
    except os.error:
        logging.exception('Error creating %s', path)
        raise
    finally:
        os.close(f)


def create_homedir(user):
    """
    Create homedirs for new users

    """
    homepath = os.path.join('/data', 'project', user.name)
    if not os.path.exists(homepath):
        # Try to not touch it if it already exists
        # This prevents us from messing with permissions while also
        # not crashing if homedirs already do exist
        # This also protects against the race exploit that can be done
        # by having a symlink from /data/project/$username point as a symlink
        # to anywhere else. The ordering we have here prevents it - if
        # it already exists in the race between the 'exists' check and the makedirs,
        # we will just fail. Then we switch mode but not ownership, so attacker
        # can not just delete and create a symlink to wherever. The chown
        # happens last, so should be ok.

        os.makedirs(homepath, mode=0o775, exist_ok=False)
        os.chmod(homepath, 0o775 | stat.S_ISGID)
        os.chown(homepath, int(user.id), int(user.id))

        logs_dir = os.path.join(homepath, 'logs')
        os.makedirs(logs_dir, mode=0o775, exist_ok=False)
        os.chmod(logs_dir, 0o775 | stat.S_ISGID)
        os.chown(homepath, int(user.id), int(user.id))
    else:
        logging.info('Homedir already exists for %s', homepath)


def create_namespace(user):
    """
    Creates a namespace for the given user if it doesn't exist
    """
    p = subprocess.Popen([
        '/usr/bin/kubectl',
        'create',
        '--validate=false',
        '-f',
        '-'
    ], stdout=subprocess.PIPE, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
    namespace = {
        "kind": "Namespace",
        "apiVersion": "v1",
        "metadata": {
            "name": user.name,
            "labels": {
                "name": user.name
            },
            "annotations": {
                "RunAsUser": str(user.id)
            }
        }
    }
    logging.info(p.communicate(json.dumps(namespace).encode()))


def main():
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--ldapconfig', help='Path to YAML LDAP config file',
                           default='/etc/ldap.yaml')
    argparser.add_argument('--infrastructure-users',
                           help=('Path to CSV file with infrastructure users config'
                                 ' (tokenauth format)'),
                           default='/etc/kubernetes/infrastructure-users.csv')
    argparser.add_argument('--debug', help='Turn on debug logging',
                           action='store_true')
    argparser.add_argument('--project', help='Project name to fetch LDAP users from',
                           default='tools')
    argparser.add_argument('--interval', help='Seconds between between runs',
                           default=60)
    argparser.add_argument('--once', help='Run once and exit',
                           action='store_true')
    argparser.add_argument('kube_master_url', help='Full URL of Kubernetes Master')
    argparser.add_argument('tokenauth_output_path', help='Path to output tokenauth CSV file')
    argparser.add_argument('abac_output_path', help='Path to output abac JSONL file')

    args = argparser.parse_args()

    loglvl = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(format='%(message)s', level=loglvl)

    with open(args.ldapconfig, encoding='utf-8') as f:
        ldapconfig = yaml.safe_load(f)

    cur_users = get_users_from_csv(args.tokenauth_output_path)

    infra_users = get_users_from_csv(args.infrastructure_users)

    while True:
        logging.info('starting a run')
        servers = ldap3.ServerPool([
            ldap3.Server(s, connect_timeout=1)
            for s in ldapconfig['servers']
        ], ldap3.POOLING_STRATEGY_ROUND_ROBIN, active=True, exhaust=True)
        with ldap3.Connection(
            servers,
            read_only=True,
            user=ldapconfig['user'],
            auto_bind=True,
            password=ldapconfig['password']
        ) as conn:
            tools = get_tools_from_ldap(conn, args.project)

        new_tools = set(tools).union(set(infra_users)) - set(cur_users)
        if new_tools:
            # There are at least some new tools, so we have to:
            #  1. Regenerate the entire tokenauth file
            #  2. Regenerate entire ABAC file
            #  3. Write out kubeconfig files for all the new tools
            #  4. Restart the apiserver
            for uid in new_tools:
                if uid in tools:
                    tools[uid].token = generate_pass(64)
                    create_homedir(tools[uid])
                    write_kubeconfig(tools[uid], args.kube_master_url)
                    create_namespace(tools[uid])
                    cur_users[uid] = tools[uid]
                    logging.info('Provisioned creds for tool %s', tools[uid].name)
                elif uid in infra_users:
                    cur_users[uid] = infra_users[uid]
                    logging.info('Provisioned creds for infra user %s', infra_users[uid].name)
            write_tokenauth(cur_users.values(), args.tokenauth_output_path)
            write_abac(cur_users.values(), args.abac_output_path)
            subprocess.check_call([
                '/bin/systemctl',
                'restart',
                'kube-apiserver'
            ])
        logging.info('finished run, wrote %s new accounts', len(new_tools))

        if args.once:
            break

        time.sleep(args.interval)


if __name__ == '__main__':
    main()
