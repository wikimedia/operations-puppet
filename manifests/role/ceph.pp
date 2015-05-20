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
                # lower from 5->3 and 10->5 respectively to ease up on the
                # recovery traffic; GbE has easilly been maxed out before
                'osd recovery max active'     => '3',
                'osd max backfills'           => '5',
            },
            'radosgw'           => {
                'rgw print continue'          => 'false',
                'rgw enable ops log'          => 'false',
                'rgw enable usage log'        => 'false',
                # default is 100, far too small for the nr. of req that we want
                'rgw thread pool size'        => '600',
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

        include ceph::nagios
    }

    class osd inherits role::ceph::eqiad {
        system_role { 'role::ceph::eqiad::osd':
            description => 'Ceph eqiad OSD',
        }

        include ceph::osd

        # I/O busy systems, tune a few knobs to avoid page alloc failures
        sysctl::parameters { 'ceph':
            values => {
                # Start freeing unused pages of memory sooner
                'vm.min_free_kbytes'    => 512000,

                # Prefer to reclaim dentries and inodes
                'vm.vfs_cache_pressure' => 120,
            },
        }
    }

    class radosgw inherits role::ceph::eqiad {
        system_role { 'role::ceph::eqiad::radosgw':
            description => 'Ceph eqiad radosgw',
        }

        class { "lvs::realserver": realserver_ips => [ "10.2.2.27" ] }

        sysctl::parameters { 'radosgw':
            values => {
                # Increase the number of ephemeral ports
                'net.ipv4.ip_local_port_range' =>  [ 1024, 65535 ],

                # Recommended to increase this for 1000 BT or higher
                'net.core.netdev_max_backlog'  =>  30000,

                # Increase the queue size of new TCP connections
                'net.core.somaxconn'           => 4096,
                'net.ipv4.tcp_max_syn_backlog' => 262144,
                'net.ipv4.tcp_max_tw_buckets'  => 360000,

                # Decrease FD usage
                'net.ipv4.tcp_fin_timeout'     => 3,
                'net.ipv4.tcp_max_orphans'     => 262144,
                'net.ipv4.tcp_synack_retries'  => 2,
                'net.ipv4.tcp_syn_retries'     => 2,
            },
        }

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
