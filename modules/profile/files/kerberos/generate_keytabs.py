#!/usr/bin/python3
# -*- coding: utf-8 -*-

import argparse
import csv
import os
import pexpect
import subprocess
import sys


# List of roles supported by the keytab generator script
# format: service principal name, name of key tab file, user owner, group owner,
#         target directory below /etc/security/keytabs
keytab_specs = {
    'druid': ('druid', 'druid', 'druid', 'druid', 'druid'),
    'hdfs': ('hdfs', 'hdfs', 'hdfs', 'hadoop', 'hadoop'),
    'HTTP': ('HTTP', 'HTTP', 'hdfs', 'hadoop', 'hadoop'),
    'mapred': ('mapred', 'mapred', 'mapred', 'hadoop', 'hadoop'),
    'yarn': ('yarn', 'yarn', 'yarn', 'hadoop', 'hadoop'),
    'hive': ('hive', 'hive', 'hive', 'hive', 'hive'),
    'oozie': ('oozie', 'oozie', 'oozie', 'oozie', 'oozie'),
    'HTTP-oozie': ('HTTP', 'HTTP-oozie', 'oozie', 'oozie', 'oozie'),
    'analytics': ('analytics', 'analytics', 'analytics', 'analytics', 'analytics'),
}

actions = ['create_princ', 'create_keytab', 'merge_keytab', 'delete_keytab']


def parse_args(argv):
    p = argparse.ArgumentParser()
    p.add_argument('--realm', action='store', required=True,
                   help='The Kerberos realm for which the service principles will be generated')
    p.add_argument('--refresh-keytab', action='store_true', default=False,
                   help='If set, an existing keytab is removed/recreated')
    p.add_argument('--keytabs-output-base-dir', default='/srv/kerberos/keytabs',
                   help='Base directory where the keytabs will be created.')
    p.add_argument('--refresh-principals', action='store_true', default=False,
                   help='If set, an existing service principal is removed/recreated')
    p.add_argument('host_file', action='store',
                   help="Read all host definitions from a CSV file. Format for each row:"
                        " FQDN,({}),({})".format(
                            '|'.join(['create_princ', 'create_keytab',
                                      'merge_keytab', 'delete_keytab']),
                            '|'.join(keytab_specs.keys())))

    args = p.parse_args(argv)

    return args


def expand_principal(base_principal, hostname, realm):
    return base_principal + "/" + hostname + "@" + realm


def create_service_principal(principal, hostname, realm):
    sp = expand_principal(principal, hostname, realm)
    print(sp)
    subprocess.call(['/usr/sbin/kadmin.local', 'addprinc', '-randkey', sp])


def create_keytab(role, hostname, refresh, realm, output_base_dir):
    principal = keytab_specs.get(role)[0]
    keytab_name = keytab_specs.get(role)[1]
    target_directory = keytab_specs.get(role)[4]
    keytab_file = os.path.join(output_base_dir, hostname, target_directory, keytab_name + '.keytab')
    keytab_directory = os.path.join(output_base_dir, hostname, target_directory)

    if not os.path.exists(keytab_directory):
        os.makedirs(keytab_directory)

    if os.path.exists(keytab_file):
        if refresh:
            os.remove(keytab_file)
            print("Deleted previously existing keytab file %s", keytab_file)
        else:
            print("Keytab file %s already exists, but no refresh requested, skipping.", keytab_file)

    sp = expand_principal(principal, hostname, realm)

    try:
        subprocess.call(['/usr/sbin/kadmin.local', 'ktadd', '-norandkey', '-k', keytab_file, sp])
    except subprocess.CalledProcessError as e:
        print('Failed to create keytab file: %s', e.returncode)
        sys.exit(1)


def delete_keytab(role, hostname, realm, output_base_dir):
    keytab_name = keytab_specs.get(role)[1]
    target_directory = keytab_specs.get(role)[4]
    keytab_file = os.path.join(output_base_dir, hostname, target_directory, keytab_name + '.keytab')

    if not os.path.exists(keytab_file):
        print("%s does not exist, can't delete" % keytab_file)
        return
    else:
        print("Removing keytab %s" % keytab_file)
        os.remove(keytab_file)


def merge_keytab(target_role, new_keytab, hostname, realm, refresh, output_base_dir):
    keytab_name = keytab_specs.get(target_role)[1]
    target_directory = keytab_specs.get(target_role)[4]
    keytab_directory = os.path.join(output_base_dir, hostname, target_directory)
    target_keytab_filename = os.path.join(output_base_dir, hostname, target_directory,
                                          keytab_name + '.keytab')
    keytab_directory = os.path.join(output_base_dir, hostname, target_directory)
    if not os.path.exists(keytab_directory):
        os.makedirs(keytab_directory)

    for kt in (keytab_name, new_keytab):
        if not os.path.exists(os.path.join(output_base_dir, hostname, target_directory,
                                           kt + ".keytab")):
            print(os.path.join(output_base_dir, hostname, target_directory, kt))
            print("%s doesn't exist, bailing out" % kt)
            return

    # ktutil has no way to specify these via CLI parameters
    ktutil = pexpect.spawn('ktutil')
    ktutil.sendline('read_kt ' + os.path.join(output_base_dir, hostname,
                                              target_directory, keytab_name + ".keytab"))
    ktutil.sendline('read_kt ' + os.path.join(output_base_dir, hostname,
                                              target_directory, new_keytab + ".keytab"))
    ktutil.sendline('write_kt ' + target_keytab_filename)
    ktutil.sendline('quit')


def main():
    args = parse_args(sys.argv[1:])
    realm = args.realm.upper()
    keytabs_output_base_dir = args.keytabs_output_base_dir
    refresh_keytab = args.refresh_keytab
    host_file = args.host_file

    if not os.path.exists(keytabs_output_base_dir):
        print("%s doesn't exist, bailing out" % keytabs_output_base_dir)
        sys.exit(1)

    if not os.path.exists(host_file):
        print("%s doesn't exist, bailing out" % host_file)
        sys.exit(1)

    with open(host_file) as host_csv:
        csv_reader = csv.reader(host_csv, skipinitialspace=True, delimiter=',')
        for row in csv_reader:
            if len(row) >= 3:
                host = row[0].strip()
                action = row[1].strip()
                role = row[2].strip()
                if host.count(".") < 2:
                    print("The hostname needs to be passed as FQDN, skipping")
                    continue
                if action not in actions:
                    print('Invalid action %s, skipping', action)
                    continue
                if action == 'create_princ':
                    create_service_principal(role, host, realm)
                elif action == 'create_keytab':
                    create_keytab(role, host, refresh_keytab, realm,
                                  keytabs_output_base_dir)
                elif action == 'merge_keytab':
                    new_keytab = row[3].strip()
                    merge_keytab(role, new_keytab, host, realm, refresh_keytab,
                                 keytabs_output_base_dir)
                elif action == 'delete_keytab':
                    delete_keytab(role, host, realm, keytabs_output_base_dir)
            elif len(row) == 0:
                pass
            else:
                print("Invalid line, bailing out")
                sys.exit(1)


if __name__ == '__main__':
    if os.geteuid() != 0:
        print("Needs to be run as root")
        sys.exit(1)

    main()
