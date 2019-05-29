class swift::storage (
    $statsd_host                   = undef,
    $statsd_port                   = 8125,
    $statsd_metric_prefix          = undef,
    $statsd_sample_rate_factor     = '1',
    $memcached_servers             = ['127.0.0.1:11211'],
    $object_replicator_concurrency = undef,
    $object_replicator_interval    = undef,
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
        max_connections => '20',
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
        content => template('swift/account-server.conf.erb'),
    }

    file { '/etc/swift/container-server.conf':
        content => template('swift/container-server.conf.erb'),
    }

    file { '/etc/swift/object-server.conf':
        content => template('swift/object-server.conf.erb'),
    }

    file { '/etc/swift/container-reconciler.conf':
        content => template('swift/container-reconciler.conf.erb'),
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

    # Swift object reconstructor is needed for storage using erasures codes
    # which we don't use.

    # Remove its unit so 'systemctl <action> swift*' exits zero.
    # If one of the units matching the wildcard is masked then systemctl
    # exits non-zero on e.g. restart.
    file { '/lib/systemd/system/swift-object-reconstructor.service':
        ensure => absent,
        notify => Exec['reload systemd daemon'],
    }
    exec { 'reload systemd daemon':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
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
        source => 'puppet:///modules/swift/swift-drive-audit.py',
    }
    file { '/etc/swift/swift-drive-audit.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => 'puppet:///modules/swift/swift-drive-audit.conf',
    }
    cron { 'swift-drive-audit':
        ensure  => present,
        command => '/usr/bin/swift-drive-audit /etc/swift/swift-drive-audit.conf',
        user    => 'root',
        minute  => '1',
        require => [File['/usr/bin/swift-drive-audit'],
                    File['/etc/swift/swift-drive-audit.conf']],
    }

    udev::rule{ 'swift_disks':
        source => 'puppet:///modules/swift/swift_disks.rules',
    }
}
