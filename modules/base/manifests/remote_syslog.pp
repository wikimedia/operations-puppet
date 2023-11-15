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
# [*tls_server_auth*]
#   Mode used to verify the authenticity of the leaf certificate presented by
#   the syslog server. Can be either 'x509/certvalid' (default, cerficate path
#   validation; a leaf certificate must be signed by the root CA listed in $tls_trusted_ca or
#   its intermediate certificates is or 'x509/name'. In the latter mode, besides the constraint
#   implied by 'x509/certvalid', the leaf certificate must contain an entry in its
#   subjectAltName or common name field that matches StreamDriverPermittedPeers
#   (defaults to the Target, but with the port number stripped).
#   Per RFC 5425 § 5.2, 'x509/name' is strongly preferred, but 'x509/certvalid' can be used
#   for legacy purposes.
# [*tls_netstream_driver*]
#   Rsyslog Network Stream driver to use for TLS support. Can be either 'gtls'
#   (GnuTLS, default) or 'ossl' (OpenSSL).
# [*tls_trusted_ca*]
#   ca file to use for netstream pki; defaults to using puppet CA
#

class base::remote_syslog (
    Boolean                             $enable,
    Array[String]                       $central_hosts_tls = [],
    Enum['auth-logs', 'standard']       $send_logs = 'standard',
    Integer                             $queue_size = 10000,
    Boolean                             $tls_client_auth = true,
    Enum['x509/certvalid', 'x509/name'] $tls_server_auth = 'x509/certvalid',
    Enum['gtls', 'ossl']                $tls_netstream_driver = 'gtls',
    Stdlib::Unixpath                    $tls_trusted_ca = '/var/lib/puppet/ssl/certs/ca.pem',
) {
    $owner = 'root'
    $group = 'root'
    # force ossl on buster #T351181
    $_tls_netstream_driver = debian::codename::le('buster').bool2str('ossl', $tls_netstream_driver)

    if $enable {
        if $_tls_netstream_driver == 'gtls' {
            ensure_packages('rsyslog-gnutls')
        } else {
            # for >= bullseye, available in debian main
            # otherwise through component/rsyslog-openssl (T324623)
            if debian::codename::eq('buster') {
                # On Buster syslog clients acting as syslog servers,
                # apt::package_from_component may have been defined
                # in rsyslog::receiver as well
                ensure_resource('apt::package_from_component', 'rsyslog-tls', {
                    component => 'component/rsyslog-openssl',
                    packages  => ['rsyslog-openssl', 'rsyslog-kafka', 'rsyslog'],
                    before    => Class['rsyslog'],
                })
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
