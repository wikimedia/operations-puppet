# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::master
# Wrapper class for Hadoop master node services:
# - NameNode
# - ResourceManager and HistoryServer (YARN)
#
# This requires that you run your primary NameNode and
# primary ResourceManager on the same host.  Standby services
# can be spread on any nodes.
#
class bigtop::hadoop::master(
    $excluded_hosts = [],
) {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::master']

    class { 'bigtop::hadoop::namenode::primary':
        excluded_hosts => $excluded_hosts,
    }

    class { 'bigtop::hadoop::resourcemanager': }

    class { 'bigtop::hadoop::historyserver': }

    # Install a check_active_namenode script, this can be run
    # from any Hadoop client, but we will only run it from master nodes.
    # This script is useful for nagios/icinga checks.
    file { '/usr/local/bin/check_hdfs_active_namenode':
        source => 'puppet:///modules/bigtop/hadoop/check_hdfs_active_namenode.py',
        owner  => 'root',
        group  => 'hdfs',
        mode   => '0555',
    }
}
