#!/usr/bin/env python

import getpass
import os
import sys
import xml.etree.ElementTree as ET

usage = """%s [<hdfs-site-xml>]

Parses <hdfs-site-xml> (default /etc/hadoop/conf/hdfs-site.xml)
for a list of HDFS HA NameNode service IDs from the
dfs.ha.namenodes.analytics-hadoop property.  Each of these will be
examined for 'active' state.  If none are active, then this will print
CRITICAL.  Otherwise things will be OKAY!

Must be run as hdfs user or a user that can sudo -u hdfs
on a node with the hdfs CLI installed.
""" % sys.argv[0]


def get_namenode_state(namenode_service_id):
    command = 'hdfs haadmin -getServiceState %s' % namenode_service_id
    if getpass.getuser() != 'hdfs':
        command = 'sudo -u hdfs ' + command

    return os.popen(command).read().strip()


if __name__ == '__main__':
    hdfs_site_xml = '/etc/hadoop/conf/hdfs-site.xml'
    if len(sys.argv) > 1:
        if sys.argv[1] == '-h' or sys.argv[1] == '--help':
            print(usage)
            exit(0)
        else:
            hdfs_site_xml = sys.argv[1]

    # Load and parse hdfs-site.xml
    hdfs_properties = ET.parse(hdfs_site_xml).getroot()

    cluster_name = hdfs_properties.findall(
        "./property[name='dfs.nameservices']"
    )[0][1].text

    # Find the namenode service IDs
    namenodes = hdfs_properties.findall(
        "./property[name='dfs.ha.namenodes.{}']".format(cluster_name)
    )[0][1].text.split(',')

    for namenode in namenodes:
        if get_namenode_state(namenode) == 'active':
            print('Hadoop Active NameNode OKAY: %s' % namenode)
            sys.exit(0)

    # if we get this far, no NameNode was active
    print('Hadoop Active NameNode CRITICAL: no namenodes are active')
    sys.exit(2)
