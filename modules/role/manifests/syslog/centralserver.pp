# == Class role::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
class role::syslog::centralserver (
    $prometheus_nodes = hiera('prometheus_nodes', []), # lint:ignore:wmf_styleguide
) {
    include ::standard
    include ::profile::base::firewall
    include ::profile::backup::host

    system::role { 'syslog::centralserver':
        description => 'Central syslog server'
    }

    ferm::service { 'rsyslog-receiver_udp':
        proto   => 'udp',
        port    => 514,
        notrack => true,
        srange  => '($PRODUCTION_NETWORKS $MGMT_NETWORKS)',
    }

    ferm::service { 'rsyslog-receiver_tcp':
        proto   => 'tcp',
        port    => 6514,
        notrack => true,
        srange  => '($PRODUCTION_NETWORKS $MGMT_NETWORKS)',
    }

    class { 'rsyslog::receiver': }

    monitoring::service { "syslog::centralserver ${::hostname} syslog-tls":
        description   => 'rsyslog TLS listener on port 6514',
        check_command => "check_ssl_on_host_port!${::fqdn}!${::fqdn}!6514",
    }

    mtail::program { 'kernel':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/kernel.mtail',
        notify => Service['mtail'],
    }

    mtail::program { 'systemd':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/systemd.mtail',
        notify => Service['mtail'],
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'mtail':
        proto  => 'tcp',
        port   => '3903',
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
