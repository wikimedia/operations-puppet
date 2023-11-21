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
# [*tls_auth_mode*]
#   specify client authentication mode for syslog clients
# [*tls_netstream_driver*]
#   Rsyslog Network Stream driver to use for TLS support. Can be either 'gtls'
#   (GnuTLS, default) or 'ossl' (OpenSSL).
# [*file_template_property*]
#   property to use for the destination log file name (either hostname or IP
#   address)
# [*acme_cert_name*]
#   optional name of acme_chief cert to use instead of puppet certs.
# [*ssl_provider*]
#   Choose to use cfssl or the puppet agent certs
#
class profile::syslog::centralserver (
    Integer $log_retention_days                                 = lookup('profile::syslog::centralserver::log_retention_days'),
    Integer $log_deletion_grace_days                            = lookup('profile::syslog::centralserver::log_deletion_grace_days', {'default_value' => 45}),
    Boolean $use_kafka_relay                                    = lookup('profile::syslog::centralserver::use_kafka_relay', {'default_value' => true}),
    Enum['anon', 'x509/certvalid', 'x509/name'] $tls_auth_mode  = lookup('profile::syslog::centralserver::tls_auth_mode', {'default_value' => 'x509/certvalid'}),
    Enum['gtls', 'ossl'] $tls_netstream_driver                  = lookup('profile::syslog::centralserver::tls_netstream_driver', {'default_value' => 'ossl'}),
    Enum['fromhost-ip', 'hostname'] $file_template_property     = lookup('profile::syslog::centralserver::file_template_property', {'default_value' => 'hostname'}),
    Optional[Stdlib::Fqdn]  $acme_cert_name                     = lookup('profile::syslog::centralserver::acme_cert_name', {'default_value' => undef}),
    Enum['puppet', 'cfssl'] $ssl_provider                      = lookup('profile::syslog::centralserver::ssl_provider', {'default_value' => 'puppet'}),
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

    if $acme_cert_name {
        acme_chief::cert { $acme_cert_name:
            puppet_svc => 'rsyslog',
        }
    }

    class { 'rsyslog::receiver':
        log_retention_days     => $log_retention_days,
        tls_auth_mode          => $tls_auth_mode,
        tls_netstream_driver   => $tls_netstream_driver,
        file_template_property => $file_template_property,
        acme_cert_name         => $acme_cert_name,
        ssl_provider           => $ssl_provider,
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
