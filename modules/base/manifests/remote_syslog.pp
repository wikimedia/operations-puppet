# == Class: base::remote_syslog
#
# Configure rsyslog to forward log events to a central server
#
# === Parameters
#
# [*enable*]
#   Enable log forwarding. Should be set to false on the central server.
#
# [*central_hosts_tls*]
#   A list of host:port (port is *required*) to forward syslog using TLS.
#   (e.g. ["centrallog1001.eqiad.wmnet:6514"])
#
# [*send_logs*]
#   Types of logs to send. Possible values (string): 'standard' (default, send all logs with severity 'info',
#   but exclude logs with facility 'cron', 'authpriv' or 'mail'), 'auth-logs' (send all logs with facility 'auth'
#   or 'authpriv').
# [*queue_size*]
#   Local queue size, unit is messages. Setting to 0 disables the local queue.
# [*tls_client_auth*]
#   Whether to authenticate to the syslog server using TLS. Note: this is only
#   relevant for mutual authentication. Server verification (e.g. checks on
#   certificate authority or the Subject Alt Names) is not affected. Defaults to
#   true.
# [*tls_netstream_driver*]
#   Rsyslog Network Stream driver to use for TLS support. Can be either 'gtls'
#   (GnuTLS, default) or 'ossl' (OpenSSL).

class base::remote_syslog (
    Boolean                         $enable,
    Array[String]                   $central_hosts_tls = [],
    Enum['auth-logs', 'standard']   $send_logs = 'standard',
    Integer                         $queue_size = 10000,
    Boolean                         $tls_client_auth = true,
    Enum['gtls', 'ossl']            $tls_netstream_driver = 'gtls',
) {
    $owner = 'root'
    $group = 'root'

    if $enable {
        if $tls_netstream_driver == 'gtls' {
            ensure_packages('rsyslog-gnutls')
        } else {
            # for >= bullseye, available in debian main
            # otherwise through component/rsyslog-openssl (T324623)
            if debian::codename::eq('buster') {
                apt::package_from_component { 'rsyslog_receiver':
                    component => 'component/rsyslog-openssl',
                    packages  => ['rsyslog-openssl', 'rsyslog-kafka', 'rsyslog'],
                    before    => Class['rsyslog'],
                }
            } else {
                ensure_packages('rsyslog-openssl')
            }
        }

        if empty($central_hosts_tls) {
            fail('::base::remote_syslog::central_hosts_tls is required')
        }

        if ! empty($central_hosts_tls) {
            file { '/etc/rsyslog':
                ensure => 'directory',
                owner  => $owner,
                group  => $group,
                mode   => '0400',
                before => Puppet::Expose_agent_certs['/etc/rsyslog'],
            }

            # TODO: consider using profile::pki::get_cert
            puppet::expose_agent_certs { '/etc/rsyslog':
                provide_private => true,
                user            => $owner,
                group           => $group,
            }
        }

        rsyslog::conf { 'remote_syslog':
            content  => template('base/remote_syslog.conf.erb'),
            priority => 30,
        }
    }
    # No ensure=>absent handling is needed for the $enable == false case
    # because ::rsyslog uses recursive purge to manage the files in its config
    # directory. Simply not adding the file will cause Puppet to remove it if
    # present.
}
