# == Class cdh::hadoop::master
# Wrapper class for Hadoop master node services:
# - NameNode
# - ResourceManager and HistoryServer (YARN)
#
# This requires that you run your primary NameNode and
# primary ResourceManager on the same host.  Standby services
# can be spread on any nodes.
#
class cdh::hadoop::master(
    $use_kerberos = false,
    $excluded_hosts = [],
) {
    Class['cdh::hadoop'] -> Class['cdh::hadoop::master']

    class { 'cdh::hadoop::namenode::primary':
        use_kerberos   => $use_kerberos,
        excluded_hosts => $excluded_hosts,
    }

    class { 'cdh::hadoop::resourcemanager':
        use_kerberos => $use_kerberos,
    }

    class { 'cdh::hadoop::historyserver':
        use_kerberos => $use_kerberos,
    }

    # Install a check_active_namenode script, this can be run
    # from any Hadoop client, but we will only run it from master nodes.
    # This script is useful for nagios/icinga checks.
    file { '/usr/local/bin/check_hdfs_active_namenode':
        source => 'puppet:///modules/cdh/hadoop/check_hdfs_active_namenode.py',
        owner  => 'root',
        group  => 'hdfs',
        mode   => '0555',
    }
}
