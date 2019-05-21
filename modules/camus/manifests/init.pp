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
        ensure => 'directory',
        owner  => 'root',
        group  => 'analytics',
        # setgid bit here to make camus log files writeable
        # by users in the hdfs group.
        mode   => '2775',
    }

    # logrotate camus log files
    logrotate::rule { 'camus':
        ensure       => present,
        file_glob    => '/var/log/camus/*.log',
        frequency    => 'weekly',
        rotate       => 4,
        missing_ok   => true,
        not_if_empty => true,
        no_create    => true,
        su           => 'root analytics',
    }
}
