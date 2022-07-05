# SPDX-License-Identifier: Apache-2.0
class swift::storage (
    $statsd_host                      = undef,
    $statsd_port                      = 8125,
    $statsd_metric_prefix             = undef,
    $statsd_sample_rate_factor        = '1',
    $memcached_servers                = ['localhost'],
    $memcached_port                   = 11211,
    $container_replicator_concurrency = '1',
    $container_replicator_interval    = undef,
    $object_replicator_concurrency    = '3',
    $object_replicator_interval       = undef,
    $object_server_default_workers    = undef,
    $servers_per_port                 = 3,
    $backends                         = [],
    $replication_limit_memory_percent = 0,
    $loopback_device_size             = undef,
    $loopback_device_count            = 0,
    Boolean $disable_fallocate        = false,
) {
    package {
        [ 'swift-account',
          'swift-container',
          'swift-object',
    ]:
        ensure => present,
    }

    # eventlet + getaddrinfo is busted in Bullseye, thus use addresses
    # https://phabricator.wikimedia.org/T283714
    $memcached_addresses = $memcached_servers.map |$server| {
        $addr = ipresolve($server, 4); "${addr}:${memcached_port}"
    }

    $loopback_dir = '/var/lib/swift/'

    # Install overrides for object replication daemons (rsync, swift-object-replicator) to be able
    # to limit their memory usage
    systemd::service { 'rsync':
        ensure   => present,
        content  => init_template('rsync', 'systemd_override'),
        override => true,
        restart  => true,
    }

    systemd::service { 'swift-object-replicator':
        ensure   => present,
        content  => init_template('swift-object-replicator', 'systemd_override'),
        override => true,
        restart  => true,
    }

    class { 'rsync::server':
        log_file => '/var/log/rsyncd.log',
    }

    rsync::server::module { 'account':
        uid             => 'swift',
        gid             => 'swift',
        max_connections => Integer(length($backends) * 2),
        path            => '/srv/swift-storage/',
        read_only       => 'no',
        lock_file       => '/var/lock/account.lock',
    }
    rsync::server::module { 'container':
        uid             => 'swift',
        gid             => 'swift',
        max_connections => Integer(length($backends) * 2),
        path            => '/srv/swift-storage/',
        read_only       => 'no',
        lock_file       => '/var/lock/container.lock',
    }
    rsync::server::module { 'object':
        uid             => 'swift',
        gid             => 'swift',
        max_connections => Integer(length($backends) * 2),
        path            => '/srv/swift-storage/',
        read_only       => 'no',
        lock_file       => '/var/lock/object.lock',
    }

    # set up swift specific configs
    file {
        default:
            owner => 'swift',
            group => 'swift',
            mode  => '0440';
        '/etc/swift/account-server.conf':
            content => template('swift/account-server.conf.erb');
        '/etc/swift/container-server.conf':
            content => template('swift/container-server.conf.erb');
        '/etc/swift/object-server.conf':
            content => template('swift/object-server.conf.erb');
        '/etc/swift/container-reconciler.conf':
            content => template('swift/container-reconciler.conf.erb');
        # The uwsgi configurations are similar to what Debian ships but logging to syslog
        '/etc/swift/swift-account-server-uwsgi.ini':
            content => template('swift/swift-account-server-uwsgi.ini.erb');
        '/etc/swift/swift-container-server-uwsgi.ini':
            content => template('swift/swift-container-server-uwsgi.ini.erb');
        '/srv/swift-storage':
            ensure  => directory,
            require => Package['swift'],
            # the 1 is to allow nagios to read the drives for check_disk
            mode    => '0751';
        '/usr/bin/swift-grow-ssd-part':
            mode   => '0555',
            source => 'puppet:///modules/swift/grow_ssd_part.py',
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
        'swift-object-updater',
    ]:
        ensure => running,
    }

    # object-reconstructor and container-sharder are not used in WMF deployment, yet are enabled
    # by the Debian package.
    # Remove their unit so 'systemctl <action> swift*' exits zero.
    # If one of the units matching the wildcard is masked then systemctl
    # exits non-zero on e.g. restart.
    ['swift-object-reconstructor', 'swift-container-sharder'].each |String $unit| {
        file { "/lib/systemd/system/${unit}.service":
            ensure => absent,
            notify => Exec['reload systemd daemon'],
        }
    }

    exec { 'reload systemd daemon':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
    }

    if debian::codename::le('buster') {
        # this file comes from the python3-swift package
        # but there are local improvements
        # that are not yet merged upstream.
        file { '/usr/bin/swift-drive-audit':
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
            source => 'puppet:///modules/swift/swift-drive-audit.py',
        }

        # install swift-drive-audit as a systemd timer job;
        # it checks the disks every 60 minutes
        # and unmounts failed disks. It logs its actions to /var/log/syslog.
        systemd::timer::job { 'swift-drive-audit':
            ensure      => present,
            description => 'Regular jobs to unmount failed disks',
            user        => 'root',
            command     => '/usr/bin/swift-drive-audit /etc/swift/swift-drive-audit.conf',
            interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:01:00'},
            require     => [
                File['/usr/bin/swift-drive-audit'],
                File['/etc/swift/swift-drive-audit.conf']
            ],
        }
    } else {
        # Drop our modifications starting with Bullseye, not enough wins
        # to keep carrying the (minor) patch from upstream.
        # See also https://review.opendev.org/c/openstack/swift/+/124398/
        package { 'swift-drive-audit':
            ensure => present,
        }
    }

    file { '/etc/swift/swift-drive-audit.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => 'puppet:///modules/swift/swift-drive-audit.conf',
    }

    udev::rule{ 'swift_disks':
        source => 'puppet:///modules/swift/swift_disks.rules',
    }

    # Loopback storage has been requested, initialize it and make sure devices exist at boot
    if $loopback_device_count > 0 {
        systemd::unit { 'loopback-device@':
            ensure  => 'present',
            content => systemd_template('loopback-device@'),
        }

        # Hack: rename /dev/loop0 to /dev/ld[a-d] to match a physical device and workaround XFS' label
        # length limitation (12 chars)
        udev::rule{ 'swift_loop':
            source => 'puppet:///modules/swift/swift_loop.rules',
        }

        range(0, $loopback_device_count - 1).each |$i| {
            exec { 'Initialize loop storage device':
                command => "/usr/bin/truncate -s ${loopback_device_size} ${loopback_dir}/loop${i}.img",
                creates => "${loopback_dir}/loop${i}.img",
            }

            service { "loopback-device@${i}.service":
                ensure  => running,
                enable  => true,
                require => Systemd::Unit['loopback-device@'],
            }
        }
    }
}
