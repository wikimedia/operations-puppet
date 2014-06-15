#!/usr/bin/env python3
import json
import os
import pwd
import random
import string

from pymongo import MongoClient


class Tool():
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


class ToolsList():
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


class MongoCredsGenerator():
    def __init__(self, tool):
        self.tool = tool
        self.cred_path = os.path.join(tool.homedir, 'mongo.creds.json')

    def _create_creds(self, client, username, dbname, password):
        db = client[dbname]
        db.add_user(username, password, roles=['userAdmin', 'dbAdmin'])

    def _write_creds(self, username, dbname, password):
        creds = {
            'username': username,
            'dbname': dbname,
            'password': password
        }
        cred_file = open(self.cred_path, 'w')
        cred_file.write(json.dumps(creds))
        cred_file.close()
        os.chmod(self.cred_path, 0o400)
        # uid and gid are the same for all tools
        os.chown(self.cred_path, tool.uid, tool.uid)

    def create_if_needed(self, client):
        if os.path.exists(self.cred_path):
            return False
        username = 'u_%d' % self.tool.uid
        dbname = 'd_%d' % self.tool.uid
        password = generate_pass(12)
        self._create_creds(client, username, dbname, password)
        self._write_creds(username, dbname, password)
        return True


def generate_pass(length):
    password_char_classes = [
        string.ascii_lowercase,
        string.ascii_uppercase,
        string.digits
    ]
    password = []
    sysrand = random.SystemRandom()  # Uses /dev/urandom
    while len(password) < length:
        password.append(sysrand.choice(sysrand.choice(password_char_classes)))
    return ''.join(password)


if __name__ == '__main__':
    tools = ToolsList.from_filesystem('/data/project')
    client = MongoClient()
    for tool in tools.tools:
        mcg = MongoCredsGenerator(tool)
        if mcg.create_if_needed(client):
            print('Created creds for ' + tool.name)
        else:
            print('Skipped creds for ' + tool.name)
