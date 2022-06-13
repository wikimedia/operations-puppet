# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::datanode
# Installs and starts up a Hadoop DataNode.
#
class bigtop::hadoop::datanode {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::datanode']

    # install jobtracker daemon package
    package { 'hadoop-hdfs-datanode':
        ensure  => 'installed',
        require => User['hdfs'],
    }

    # install datanode daemon package
    service { 'hadoop-hdfs-datanode':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        alias      => 'datanode',
        require    => Package['hadoop-hdfs-datanode'],
    }
}