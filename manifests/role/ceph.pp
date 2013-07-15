@monitor_group { 'ceph': description => 'Ceph servers' }

class role::ceph::base {
    $cluster      = 'ceph'
    $nagios_group = 'ceph'

    include standard
}

class role::ceph::eqiad inherits role::ceph::base {
    system_role { 'role::ceph::eqiad': description => 'Ceph eqiad cluster' }

    include passwords::ceph::eqiad
    class { 'ceph':
        admin_key      => $passwords::ceph::eqiad::admin_key,
        config         => {
            fsid                => 'c9da36e1-694a-4166-b346-9d8d4d1d1ac1',
            mon_initial_members => [
                'ms-fe1001',
                'ms-fe1003',
                'ms-fe1004',
            ],
            mon_addresses       => [
                '10.64.0.167:6789',  # ms-fe1001
                '10.64.16.150:6789', # ms-fe1003
                '10.64.32.92:6789',  # ms-fe1004
            ],
            'global'            => {
                # eqiad hardware has H710s which have a BBU
                'osd fs mount options xfs'    => 'noatime,nobarrier',
            },
            'mon'               => {
                'mon osd down out interval'   => '600',
                # be more resilient to malfunctioning OSDs; see Ceph #4552 et al
                'mon osd min down reporters'  => '14',
            },
            'osd'               => {
                'osd journal'                 => '/var/lib/ceph/journal/$cluster-$id',
                'osd journal size'            => '10240',
            },
            'radosgw'           => {
                'rgw enable ops log'          => 'false',
                'rgw enable usage log'        => 'false',
                'rgw extended http attrs'     => 'x_content_duration',
                'debug rgw'                   => '1',
            },
        },
    }

    class mon inherits role::ceph::eqiad {
        system_role { 'role::ceph::eqiad::mon':
            description => 'Ceph eqiad monitor',
        }

        class { 'ceph::mon':
            monitor_secret => $passwords::ceph::eqiad::monitor_secret,
        }

        # FIXME: need a Ceph nagios check
    }

    class osd inherits role::ceph::eqiad {
        system_role { 'role::ceph::eqiad::osd':
            description => 'Ceph eqiad OSD',
        }

        include ceph::osd

        # I/O busy systems, tune a few knobs to avoid page alloc failures
        sysctl { 'sys.vm.min_free_kbytes':
            value => '512000',
        }
        sysctl { 'sys.vm.vfs_cache_pressure':
            value => '120',
        }
    }

    class radosgw inherits role::ceph::eqiad {
        system_role { 'role::ceph::eqiad::radosgw':
            description => 'Ceph eqiad radosgw',
        }

        class { "lvs::realserver": realserver_ips => [ "10.2.2.27" ] }

        include sysctlfile::high-http-performance

        class { 'ceph::radosgw':
            servername  => 'ms-fe.eqiad.wmnet',
            serveradmin => 'webmaster@wikimedia.org',
        }

        monitor_service { 'http-apache':
            description   => 'HTTP Apache',
            check_command => 'check_http_url!ms-fe.eqiad.wmnet!/monitoring/frontend',
        }
        monitor_service { 'http-radosgw':
            description   => 'HTTP radosgw',
            check_command => 'check_http_url!ms-fe.eqiad.wmnet!/monitoring/backend',
        }

        file { '/usr/lib/ganglia/python_modules/apache_status.py':
            source => 'puppet:///files/ganglia/plugins/apache_status.py',
            notify => Service['gmond'],
        }

        file { '/etc/ganglia/conf.d/apache_status.pyconf':
            source => 'puppet:///files/ganglia/plugins/apache_status.pyconf',
            notify => Service['gmond'],
        }
    }
}
