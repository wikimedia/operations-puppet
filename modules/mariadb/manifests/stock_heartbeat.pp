# Stock (non-customised) pt-heartbeat for Beta Cluster
#
# Enabling or disabling the service should be handled by orchestration when
# replication is started or stopped.
class mariadb::stock_heartbeat {
    file { '/etc/percona-toolkit/pt-heartbeat.conf':
        mode   => '0444',
        source => 'puppet:///modules/mariadb/pt-heartbeat.conf',
    }

    user { 'heartbeat':
        ensure => present,
        system => true,
    }

    systemd::service { 'pt-heartbeat':
        ensure         => present,
        content        => file('mariadb/pt-heartbeat.service'),
        service_params => {
            ensure => undef,
        }
    }
}
