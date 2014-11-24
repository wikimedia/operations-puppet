'''
draft jenkins test to ensure changes to data.yaml do not
include ssh keys stored in ldap (hence possible labs keys)
'''

import yaml
import re
import subprocess
import sys


class LdapKeys(object):
    '''
    retrieval of keys from ldap
    '''

    @staticmethod
    def get_key_from_line(line):
        '''
        get and return the part of the line that has
        (part of) a key, or None if there is nothing

        not sure if key is legit without the key name/prompt
        but we'll ignore the issue
        '''
        if line is None:
            return None

        if (line.startswith('ssh-rsa AAA') or
            line.startswith('ssh-dss AAA') or
                line.startswith('ecdsa')):
            fields = line.split(' ')
            return fields[1]
        elif line.startswith('AAA'):
            return line.rsplit(' ', 1)[0]
        return None

    def __init__(self):
        self.ldap_keys_found = {}

    def get_ldap_keys(self):
        '''
        get all ldap keys for all users, via 'ldaplist'
        maybe it would be better to rely on a standard ldap client
        instead of our script?
        '''
        command = ['ldaplist', '-l', 'passwd', '-a', 'sshPublicKey']
        proc = subprocess.Popen(command, stdout=subprocess.PIPE)
        out, err_unused = proc.communicate()
        if not out:
            return {}

        entries = out.splitlines()
        if not entries:
            return None
        parser = self.parse_ldap_entries()
        parser.send(None)
        for entry in entries:
            entry = entry.strip()
            parser.send(entry)
        return self.ldap_keys_found

    def get_username_from_dn(self, line):
        '''
        from the distinguished name entry in ldap,
        get the username and return it
        '''
        # expect "dn: uid=username,ou=people..."
        username_pattern = '^dn: uid=(.*),ou=people'

        result = re.match(username_pattern, line)
        if result:
            username = result.group(1)
            if username not in self.ldap_keys_found:
                self.ldap_keys_found[username] = []
            return username
        return None

    def parse_ldap_entries(self):
        '''
        this coroutine requires that the first
        call to it is send(None), for initialization

        pass in line from ldap output stripped via send()
        returns nothing, key and user information is
        stashed in ldap_keys_found
        '''
        username = None
        returnme = (None, None)
        while username is None:
            line = yield
            if line is None:
                yield
            elif line.startswith('dn: '):
                username = self.get_username_from_dn(line)
                if username is not None:
                    break
        user_keys = []
        key_contents = key_line = None

        line = yield
        while line is not None:

            if line.startswith('dn: '):
                # start of new user, stash key for old user if any
                key_contents = LdapKeys.get_key_from_line(key_line)
                if key_contents is not None:
                    user_keys.append(key_contents)
                if username is not None and user_keys:
                    self.ldap_keys_found[username] = user_keys

                username = self.get_username_from_dn(line)
                user_keys = []
                key_contents = key_line = None

            elif line.startswith('#') or not line.strip():
                # comments, whitespace are skipped
                pass

            elif line.startswith('sshPublicKey: '):
                # stash previous key contents if any
                key_contents = LdapKeys.get_key_from_line(key_line)
                if key_contents is not None:
                    user_keys.append(key_contents)

                # start collecting new key contents
                key_line = line[len('sshPublicKey: '):]

            elif key_line is not None:
                # still retrieving key contents
                key_line += line

            line = yield returnme
            returnme = (None, None)

        #  stash the last entry
        key_contents = LdapKeys.get_key_from_line(key_line)
        if key_contents is not None:
            user_keys.append(key_contents)
        if username is not None and user_keys:
            self.ldap_keys_found[username] = user_keys

        line = yield


def get_key_data(entry):
    '''
    return the key data (b64 encoded string) or None if the
    data string cannot be located
    expect in entry possible option string, may have spaces in it,
    algorithm, b64-encoded string, comment (= key name)
    don't deal with ssh1 keys, sorry
    '''
    entry = entry.strip()
    if not (entry.startswith('ssh-') or entry.startswith('ecdsa')):
        fields = entry.rsplit(' ', 2)
        if len(fields) != 3:
            # problem with content
            return None
        alg_unused, key = fields[1], fields[2]
    else:
        alg_unused, key = entry.split(' ', 1)

    if key.startswith('AAA'):
        data, name_unused = key.split(' ', 1)
        return data
    else:
        # problem with content
        return None


def get_keys_from_yaml(filename):
    '''
    load a yaml file and dig the sh keys out of it
    this assumes a very specific structure to the yaml,
    namely 'users' as a top level item, and for each user
    the attributes 'ensure' (present) and 'ssh-keys' (list)
    '''
    keys = {}
    yaml_content = open(filename).read()
    yaml_data = yaml.load(yaml_content)
    if 'users' in yaml_data:
        for username in yaml_data['users']:
            if ('ensure' in yaml_data['users'][username] and
                    yaml_data['users'][username]['ensure'] == 'present'):
                if 'ssh_keys' in yaml_data['users'][username]:
                    keys[username] = [
                        get_key_data(entry)
                        for entry in yaml_data['users'][username]['ssh_keys']]
    return keys


def do_main():
    '''
    main entry point
    '''
    puppet_keys = get_keys_from_yaml('data.yaml')
    ldap_checker = LdapKeys()
    ldap_keys = ldap_checker.get_ldap_keys()

    errors = 0
    for user in puppet_keys:
        if user not in ldap_keys:
            continue
        for key in puppet_keys[user]:
            if key in ldap_keys[user]:
                print "user: ", user, "wikitech/lab key in production:", key
                errors = 1
    if errors:
        sys.exit(1)

if __name__ == '__main__':
    do_main()
