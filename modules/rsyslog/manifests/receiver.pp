# SPDX-License-Identifier: Apache-2.0
# == Class: rsyslog::receiver
#
# Setup the rsyslog daemon as a receiver for remote logs.
#
# === Parameters
#
# [*udp_port*]
#   Listen for UDP syslog on this port
#
# [*tcp_port*]
#   Listen for TCP syslog on this port (TLS only)
#
# [*log_retention_days*]
#   How long to keep logs in $archive_directory for
#
# [*log_directory*]
#   Write logs to this directory, parent directory must already
#   exist.
#
# [*archive_directory*]
#   Archive logs into this directory, it is an error to set this equal to
#   $log_directory and vice versa.
# [*tls_auth_mode*]
#   Specifies the authentication mode for syslog clients. Default is
#   x509/certvalid (verify certificate for all clients).
# [*tls_netstream_driver*]
#   Rsyslog Network Stream driver to use for TLS support. Can be either 'gtls'
#   (GnuTLS, default) or 'ossl' (OpenSSL).
# [*file_template_property*]
#   Property to be used for determining the file name (e.g.
#   /srv/syslog/<property>/syslog.log) of the log file. Can be
#   either hostname ('host1001') or fromhost-ip (10.0.0.1). Default is hostname.
#
# [*acme_cert_name*]
#   Optional name for acme-chief cert to use for tls clients
class rsyslog::receiver (
    $udp_port                                                   = 514,
    $tcp_port                                                   = 6514,
    $log_retention_days                                         = 90,
    $log_directory                                              = '/srv/syslog',
    $archive_directory                                          = '/srv/syslog/archive',
    Enum['anon', 'x509/certvalid', 'x509/name'] $tls_auth_mode  = 'x509/certvalid',
    Enum['gtls', 'ossl'] $tls_netstream_driver                  = 'gtls',
    Enum['fromhost-ip', 'hostname'] $file_template_property     = 'hostname',
    Optional[Stdlib::Fqdn] $acme_cert_name                      = undef
) {
    if $tls_netstream_driver == 'gtls' {
        # Unlike rsyslog-openssl (see below), rsyslog-gnutls is available
        # in buster, but on buster systems, we need a newer version of
        # rsyslog due to segfaults (T259780)
        $buster_component = 'component/rsyslog'
        $netstream_package = 'rsyslog-gnutls'
    } else {
        # rsyslog-openssl is available by default in bullseye and later,
        # the package has been backported to component/rsyslog-openssl for
        # buster systems (T324623)
        # component/rsyslog-openssl also incorporated the fix for
        # T259780 (see above), hence component/rsyslog is redundant
        $buster_component = 'component/rsyslog-openssl'
        $netstream_package = 'rsyslog-openssl'
    }

    if debian::codename::eq('buster') {
        # On Buster syslog servers acting as syslog clients,
        # apt::package_from_component may have been defined
        # in base::remote_syslog as well
        ensure_resource('apt::package_from_component', 'rsyslog-tls', {
            component => $buster_component,
            packages  => [$netstream_package, 'rsyslog-kafka', 'rsyslog'],
            before    => Class['rsyslog'],
        })
    } else {
        ensure_packages($netstream_package)
    }

    if ($log_directory == $archive_directory) {
        fail("rsyslog log and archive are the same: ${log_directory}")
    }

    if $acme_cert_name {
        $ca_file   = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.chained.crt"
        $cert_file = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.alt.chained.crt"
        $key_file  = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.key"
    } else {
        # SSL configuration
        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs { '/etc/rsyslog-receiver':
            provide_private => true,
        }

        $ca_file = '/var/lib/puppet/ssl/certs/ca.pem'
        $cert_file = '/etc/rsyslog-receiver/ssl/cert.pem'
        $key_file = '/etc/rsyslog-receiver/ssl/server.key'
    }

    systemd::unit { 'rsyslog':
        ensure   => present,
        override => true,
        content  => template('rsyslog/initscripts/rsyslog_receiver.systemd_override.erb'),
    }

    file { '/etc/rsyslog-receiver':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
    }

    rsyslog::conf { 'receiver':
        content  => template("${module_name}/receiver.erb.conf"),
        priority => 10,
    }

    logrotate::conf { 'rsyslog_receiver':
        ensure  => present,
        content => template("${module_name}/receiver_logrotate.erb.conf"),
    }

    # disable DNS lookup for remote messages
    file { '/etc/default/rsyslog':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => 'RSYSLOGD_OPTIONS="-x"',
        notify  => Service['rsyslog'],
    }

    file { $log_directory:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $archive_directory:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Plumb rsync pull from eqiad by codfw centrallog hosts, useful for re-syncing logs
    # inactive (ensure => absent, auto_sync => false)  but kept here to be
    # quickly enabled when needed.
    rsync::quickdatacopy { 'centrallog':
        ensure              => present,
        source_host         => 'centrallog1001.eqiad.wmnet',
        dest_host           => 'centrallog1002.eqiad.wmnet',
        auto_sync           => false,
        module_path         => '/srv',
        server_uses_stunnel => true,
        progress            => true,
    }
}
