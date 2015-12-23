# A role that includes all the needed stuff to run a ganglia web frontend
class role::ganglia::web {
    include role::ganglia::config

    sslcert::certificate { 'ganglia.wikimedia.org': }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!ganglia.wikimedia.org',
    }

    $gmetad_root = '/srv/ganglia'
    $rrd_rootdir = "${gmetad_root}/rrds"
    $gmetad_socket = '/var/run/rrdcached-gmetad.sock'
    $gweb_socket = '/var/run/rrdcached-gweb.sock'

    class { 'ganglia::gmetad::rrdcached':
        rrdpath       => $rrd_rootdir,
        gmetad_socket => $gmetad_socket,
        gweb_socket   => $gwebsocket,
        journal_dir   => '/srv/rrdcached_journal',
    }

    # TODO: Automate the gmetad trusted hosts variable
    class { 'ganglia::gmetad':
        grid             => 'Wikimedia',
        authority        => 'http://ganglia.wikimedia.org',
        gmetad_root      => $gmetad_root,
        rrd_rootdir      => $rrd_rootdir,
        rrdcached_socket => $gmetad_socket,
        trusted_hosts    => [
                        '208.80.154.149', # bast1001
                        '208.80.154.14', # neon
                        '10.64.32.13', # terbium
                        ],
        data_sources     => $role::ganglia::config::data_sources,
        rra_sizes        => $role::ganglia::config::rra_sizes,
    }

    class { '::ganglia::web':
        rrdcached_socket => $gweb_socket,
        gmetad_root      => $gmetad_root,
    }

    ferm::service { 'ganglia_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'ganglia_https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::service { 'gmond_udp':
        proto  => 'udp',
        port   => '8649',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'gmond_tcp':
        proto  => 'tcp',
        port   => '8649',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'gmetad_xml':
        proto  => 'tcp',
        port   => '8653',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'gmetad':
        proto  => 'tcp',
        port   => '8654',
        srange => '$ALL_NETWORKS',
    }

    # Get better insight into how disks are faring
    ganglia::plugin::python { 'diskstat': }

    monitoring::service { 'ganglia_http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
    include role::backup::host
    backup::set { 'var-lib-ganglia': }
    backup::set { 'srv-ganglia': }

    Class['ganglia::gmetad::rrdcached'] -> Class['ganglia::gmetad']
    Class['ganglia::gmetad'] -> Class['ganglia::web']
}
