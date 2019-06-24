# == Class cdh::hadoop::datanode
# Installs and starts up a Hadoop DataNode.
#
class cdh::hadoop::datanode {
    Class['cdh::hadoop'] -> Class['cdh::hadoop::datanode']

    # install jobtracker daemon package
    package { 'hadoop-hdfs-datanode':
        ensure => 'installed'
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