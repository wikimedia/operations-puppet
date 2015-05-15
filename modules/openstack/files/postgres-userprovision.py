#!/usr/bin/env python3
from __future__ import print_function
import json
import os
import pwd
import random
import string
import json

import psycopg2


class Tool(object):
    def __init__(self, name, uname, uid, homedir):
        self.name = name
        self.uid = uid
        self.uname = uname
        self.homedir = homedir

    @classmethod
    def from_ent(cls, ent):
        return cls(
            os.path.basename(ent.pw_dir),
            ent.pw_name, ent.pw_uid, ent.pw_dir
        )


class ToolsList(object):
    def __init__(self, tools):
        self.tools = tools

    @classmethod
    def from_filesystem(cls, base_path):
        tools = []
        for name in os.listdir(base_path):
            tool_path = os.path.join(base_path, name)
            if os.path.isdir(tool_path) and not name.startswith('.'):
                try:
                    ent = pwd.getpwnam('tools.' + name)
                except:
                    # Not a tool, since there's no corresponding user entry.
                    continue
                tools.append(Tool.from_ent(ent))
        return cls(tools)


class PostgresCredsGenerator(object):
    def __init__(self, host, user, password, cred_file_name):
        conn_string = "host='%s' user='%s' password='%s'" % (host, user, password)j
        self.db = psycopg2.connect(conn_string)
        self.cred_file_name = cred_file_name

    def _create_creds(self, username, password):
        cur = self.db.cursor()
        cur.execute('CREATE ROLE %s PASSWORD %s', (username, password))
        cur.close()

    def _write_creds(self, username, password):
        creds = {
            'username': username,
            'password': password
        }
        cred_file = open(self.cred_path, 'w')
        cred_file.write(json.dumps(creds))
        cred_file.close()
        os.chmod(self.cred_path, 0o400)

    def create_if_needed(self, tool):
        cred_file_path = os.path.join(tool.homedir, self.cred_filename)
        if os.path.exists(cred_file_path):
            return False
        username = 'u_%d' % tool.uid
        password = generate_pass(12)
        self._create_creds(username, password)
        self._write_creds(username, password)
        return True


def generate_pass(length):
    password_chars = string.ascii_letters + string.digits
    sysrandom = random.SystemRandom()  # Uses /dev/urandom
    return ''.join(sysrandom.sample(password_chars, length))


if __name__ == '__main__':
    tools = ToolsList.from_filesystem('/exp/project/tools/project')
    with open('/etc/postgres-userprovision.json') as f:
        config = json.load(f)
    cg = PostgresCredsGenerator(config['host'], config['user'],
                                config['password'], config['cred_filename'])
    for tool in tools.tools:
        if cg.create_if_needed(tool):
            print('Created creds for ' + tool.name)
        else:
            print('Skipped creds for ' + tool.name)
