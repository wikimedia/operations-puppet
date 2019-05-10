#!/usr/bin/python

import errno
import grp
import os
import pwd
import time

import MySQLdb


def wmflabs_project():
    try:
        return wmflabs_project.project_name
    except AttributeError:
        with open('/etc/wmflabs-project', 'r') as f:
            wmflabs_project.project_name = f.read().rstrip('\n')
        return wmflabs_project.project_name


def update_tools_table(db):
    def read_normalized_file(path, default=None):
        try:
            with open(path, 'r') as f:
                return ' '.join(l.rstrip('\n') for l in f.readlines())
        except IOError as e:
            if e.errno in (errno.EACCES, errno.ENOENT):
                return default
            raise

    def get_tool_description(homedir):
        return read_normalized_file(homedir + '/.description', '')

    def get_tool_toolinfo(homedir):
        return read_normalized_file(
            homedir + '/toolinfo.json',
            read_normalized_file(homedir + '/public_html/toolinfo.json', ''))

    # Get list of all accounts starting with "tools.".
    tool_accounts = {account.pw_name[len(wmflabs_project()) + 1:]:
                     {'home': account.pw_dir.rstrip('/'),
                      'id': account.pw_uid,
                      'maintainers': ' '.join(grp.getgrnam(account.pw_name)[3])}
                     for account in pwd.getpwall() if account.pw_name.startswith(
                         wmflabs_project() + '.') and os.access(account.pw_dir, os.X_OK)}

    # Update tools table.
    cur = db.cursor()
    cur.execute('DELETE FROM tools')
    for tool_account_name, tool_account in tool_accounts.iteritems():
        cur.execute(
                ('INSERT INTO tools (name, id, home, maintainers, description,',
                 'toolinfo, updated) VALUES (%s, %s, %s, %s, %s, %s, UNIX_TIMESTAMP())'),
                (tool_account_name,
                 tool_account['id'],
                 tool_account['home'],
                 tool_account['maintainers'],
                 get_tool_description(tool_account['home']),
                 get_tool_toolinfo(tool_account['home'])))
    db.commit()


def update_users_table(db):
    # Get list of all accounts in the project-tools group.
    project_members = grp.getgrnam('project-%s' % wmflabs_project())[3]

    # Update users table.
    cur = db.cursor()
    cur.execute('DELETE FROM users')
    for project_member in project_members:
        account = pwd.getpwnam(project_member)
        cur.execute('INSERT INTO users (name, id, wikitech, home) VALUES (%s, %s, %s, %s)',
                    (account.pw_name,
                     account.pw_uid,
                     str.upper(account.pw_gecos[0]) + account.pw_gecos[1:],
                     account.pw_dir))
    db.commit()


if __name__ == '__main__':
    while True:
        db = MySQLdb.connect(host='tools.labsdb',
                             db='toollabs_p',
                             read_default_file=pwd.getpwuid(os.getuid()).pw_dir + '/replica.my.cnf')
        update_tools_table(db)
        update_users_table(db)
        db.close()
        time.sleep(120)
