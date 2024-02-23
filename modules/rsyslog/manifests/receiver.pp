# SPDX-License-Identifier: Apache-2.0
# @summary Setup the rsyslog daemon as a receiver for remote logs.
# @param udp_port Listen for UDP syslog on this port
# @param tcp_port Listen for TCP syslog on this port (TLS only)
# @param log_retention_days How long to keep logs in $archive_directory for
# @param log_directory Write logs to this directory, parent directory must already exist.
# @param archive_directory Archive logs into this directory, it is an error to set this equal to
#   $log_directory and vice versa.
# @param tls_auth_mode Specifies the authentication mode for syslog clients.
# @param tls_netstream_driver Rsyslog Network Stream driver to use for TLS support.
# @param file_template_property Property to be used for determining the file name (e.g.
#   /srv/syslog/<property>/syslog.log) of the log file.
# @param acme_cert_name name for acme-chief cert to use for tls clients
# @param ssl_provider Choose to use cfssl or the puppet agent certs
class rsyslog::receiver (
    Stdlib::Port                    $udp_port               = 514,
    Stdlib::Port                    $tcp_port               = 6514,
    Integer                         $log_retention_days     = 90,
    Stdlib::Unixpath                $log_directory          = '/srv/syslog',
    Stdlib::Unixpath                $archive_directory      = '/srv/syslog/archive',
    Rsyslog::TLS::Auth_mode         $tls_auth_mode          = 'x509/certvalid',
    Rsyslog::TLS::Driver            $tls_netstream_driver   = 'gtls',
    Enum['fromhost-ip', 'hostname'] $file_template_property = 'hostname',
    Optional[Stdlib::Fqdn]          $acme_cert_name         = undef,
    Enum['puppet', 'cfssl', 'acme'] $ssl_provider           = 'puppet',
) {
    # force acme if we have a acme_cert_name to remain backwards compatible
    $_ssl_provider = ($acme_cert_name =~ NotUndef).bool2str('acme', $ssl_provider)
    if $ssl_provider == 'acme' and $ssl_provider =~ Undef {
        fail('you must set \$acme_cert_name when \$ssl_provider is acme')
    }
    if $tls_netstream_driver == 'gtls' {
        # Unlike rsyslog-openssl (see below), rsyslog-gnutls is available
        # in buster, but on buster systems, we need a newer version of
        # rsyslog due to segfaults (T259780)
        $netstream_package = 'rsyslog-gnutls'
    } else {
        # rsyslog-openssl is available by default in bullseye and later,
        # the package has been backported to component/rsyslog-openssl for
        # buster systems (T324623)
        # component/rsyslog-openssl also incorporated the fix for
        # T259780 (see above), hence component/rsyslog is redundant
        $netstream_package = 'rsyslog-openssl'
    }

    ensure_packages($netstream_package)

    if ($log_directory == $archive_directory) {
        fail("rsyslog log and archive are the same: ${log_directory}")
    }

    # SSL configuration
    case $_ssl_provider {
        'acme': {
            $ca_file   = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.chained.crt"
            $cert_file = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.alt.chained.crt"
            $key_file  = "/etc/acmecerts/${acme_cert_name}/live/ec-prime256v1.key"
        }
        'puppet': {
            puppet::expose_agent_certs { '/etc/rsyslog-receiver':
                provide_private => true,
            }

            $ca_file = '/etc/ssl/certs/wmf-ca-certificates.crt'
            $cert_file = '/etc/rsyslog-receiver/ssl/cert.pem'
            $key_file = '/etc/rsyslog-receiver/ssl/server.key'
        }
        'cfssl': {
            $ssl_paths = profile::pki::get_cert('syslog')
            $cert_file = $ssl_paths['chained']
            $key_file = $ssl_paths['key']
            $ca_file = '/etc/ssl/certs/wmf-ca-certificates.crt'
        }
        default: { fail("unknown provider: ${ssl_provider}") }
    }

    systemd::service { 'rsyslog-receiver':
        ensure  => present,
        content => template('rsyslog/initscripts/rsyslog_receiver.systemd.erb'),
    }

    file { ['/etc/rsyslog-receiver', '/etc/rsyslog-receiver/conf.d']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0500',
    }

    file { '/var/spool/rsyslog-receiver':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    file { '/etc/rsyslog-receiver/main.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/rsyslog/receiver.conf',
    }

    prometheus::rsyslog_exporter { 'receiver':
        listen_port => 9110,
        instance    => 'receiver',
    }

    rsyslog::conf { 'input':
        content  => template("${module_name}/receiver.erb.conf"),
        priority => 10,
        instance => 'receiver',
    }

    logrotate::conf { 'rsyslog_receiver':
        ensure  => present,
        content => template("${module_name}/receiver_logrotate.erb.conf"),
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
