class swift_new::storage (
    $statsd_host               = undef,
    $statsd_metric_prefix      = undef,
    $statsd_sample_rate_factor = '1',
) {
    package {
        [ 'swift-account',
          'swift-container',
          'swift-object',
    ]:
        ensure => present,
    }

    class { 'rsync::server':
        log_file => '/var/log/rsyncd.log',
    }

    rsync::server::module { 'account':
        uid             => 'swift',
        gid             => 'swift',
        max_connections => '5',
        path            => '/srv/swift-storage/',
        read_only       => 'no',
        lock_file       => '/var/lock/account.lock',
    }
    rsync::server::module { 'container':
        uid             => 'swift',
        gid             => 'swift',
        max_connections => '5',
        path            => '/srv/swift-storage/',
        read_only       => 'no',
        lock_file       => '/var/lock/container.lock',
    }
    rsync::server::module { 'object':
        uid             => 'swift',
        gid             => 'swift',
        max_connections => '10',
        path            => '/srv/swift-storage/',
        read_only       => 'no',
        lock_file       => '/var/lock/object.lock',
    }

    # set up swift specific configs
    File {
        owner => 'swift',
        group => 'swift',
        mode  => '0440',
    }

    file { '/etc/swift/account-server.conf':
        content => template('swift_new/account-server.conf.erb'),
    }

    file { '/etc/swift/container-server.conf':
        content => template('swift_new/container-server.conf.erb'),
    }

    file { '/etc/swift/object-server.conf':
        content => template('swift_new/object-server.conf.erb'),
    }

    file { '/srv/swift-storage':
        ensure  => directory,
        require => Package['swift'],
        owner   => 'swift',
        group   => 'swift',
        # the 1 is to allow nagios to read the drives for check_disk
        mode    => '0751',
    }

    service { [
        'swift-account',
        'swift-account-auditor',
        'swift-account-reaper',
        'swift-account-replicator',
        'swift-container',
        'swift-container-auditor',
        'swift-container-replicator',
        'swift-container-updater',
        'swift-object',
        'swift-object-auditor',
        'swift-object-replicator',
        'swift-object-updater',
    ]:
        ensure => running,
    }


    # install swift-drive-audit as a cronjob;
    # it checks the disks every 60 minutes
    # and unmounts failed disks. It logs its actions to /var/log/syslog.

    # this file comes from the python-swift package
    # but there are local improvements
    # that are not yet merged upstream.
    file { '/usr/bin/swift-drive-audit':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/swift_new/swift-drive-audit',
    }
    file { '/etc/swift/swift-drive-audit.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => 'puppet:///modules/swift_new/swift-drive-audit.conf',
    }
    cron { 'swift-drive-audit':
        ensure  => present,
        command => '/usr/bin/swift-drive-audit /etc/swift/swift-drive-audit.conf',
        user    => 'root',
        minute  => '1',
        require => [File['/usr/bin/swift-drive-audit'],
                    File['/etc/swift/swift-drive-audit.conf']],
    }
}
