# == Define: profile::syslog::centralserver
#
# Setup rsyslog as a receiver of cluster wide syslog messages.
#
# [*log_retention_days*]
#   number of days to keep logs before they are rotated
#
# [*log_deletion_grace_days*]
#   grace period between max retention time and deletion of logs (for cleanup of inactive hosts)
#
# [*use_kafka_relay*]
#   enables the syslog -> kafka relay compatability layer, used by devices without native
#   kafka output support
#
class profile::syslog::centralserver (
    Integer $log_retention_days      = lookup('profile::syslog::centralserver::log_retention_days'),
    Integer $log_deletion_grace_days = lookup('profile::syslog::centralserver::log_deletion_grace_days', {'default_value' => 45}),
    Boolean $use_kafka_relay         = lookup('profile::syslog::centralserver::use_kafka_relay', {'default_value' => true}),
){

    ferm::service { 'rsyslog-receiver_udp':
        proto   => 'udp',
        port    => 514,
        notrack => true,
        srange  => '($DOMAIN_NETWORKS $MGMT_NETWORKS)',
    }

    ferm::service { 'rsyslog-receiver_tcp':
        proto   => 'tcp',
        port    => 6514,
        notrack => true,
        srange  => '($DOMAIN_NETWORKS $MGMT_NETWORKS)',
    }

    class { 'rsyslog::receiver':
        log_retention_days => $log_retention_days,
    }

    # Prune old /srv/syslog/host directories on disk (from decommed hosts, etc.) after grace period expires
    $log_deletion_days = $log_retention_days + $log_deletion_grace_days

    systemd::timer::job { 'prune_old_srv_syslog_directories':
        ensure             => 'present',
        user               => 'root',
        description        => 'clean up logs from old hosts',
        command            => "/usr/bin/find /srv/syslog/ -mtime +${log_deletion_days} -delete",
        interval           => { 'start' => 'OnCalendar', 'interval' => 'daily' },
        monitoring_enabled => true,
    }

    if $use_kafka_relay {
        ferm::service { 'rsyslog-netdev_kafka_relay_udp':
            proto   => 'udp',
            port    => 10514,
            notrack => true,
            srange  => '($DOMAIN_NETWORKS $MGMT_NETWORKS $NETWORK_INFRA)',
        }

        class { 'profile::rsyslog::netdev_kafka_relay': }
    }


    monitoring::service { "syslog::centralserver ${::hostname} syslog-tls":
        description   => 'rsyslog TLS listener on port 6514',
        check_command => "check_ssl_on_host_port!${::fqdn}!${::fqdn}!6514",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Logs',
    }

    prometheus::blackbox::check::tcp { 'rsyslog-receiver':
        port        => 6514,
        force_tls   => true,
        server_name => $facts['networking']['fqdn'],
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

    mtail::program { 'ulogd':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/ulogd.mtail',
        notify => Service['mtail'],
    }
}
