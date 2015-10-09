# == Class camus
#
class camus {
    # Require that an HDFS client is installed by ensuring that cdh::hadoop
    # is included on this node.
    Class['cdh::hadoop'] -> Class['camus']

    $config_directory = '/etc/camus.d'
    $log_directory    = '/var/log/camus'

    file { $config_directory:
        ensure => 'directory',
    }

    file { $log_directory:
        ensure => 'directory'
        ensure => 'directory',
        owner  => 'root',
        group  => 'hdfs',
        # setgid bit here to make camus log files writeable
        # by users in the hdfs group.
        mode   => '2775',
    }

    # TODO: Add logrotate for camus logs
}
