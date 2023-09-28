# @summary Configure rsyslog to forward log events to a central server
# @param enable
#   Enable log forwarding. Should be set to false on the central server.
# @param central_hosts_tls
#   Central TLS enabled syslog servers
# @param send_logs
#   Types of logs to send. Possible values (string): 'standard' (default, send all logs with severity 'info',
#   but exclude logs with facility 'cron', 'authpriv' or 'mail'), 'auth-logs' (send all logs with facility 'auth'
#   or 'authpriv').
# @param queue_size
#   Local queue size, unit is messages. Setting to 0 disables the local queue.
# @param tls_client_auth
#   Whether to authenticate to the syslog server using TLS. Note: this is only
#   relevant for mutual authentication. Server verification (e.g. checks on
#   certificate authority or the Subject Alt Names) is not affected. Defaults to
#   true.
# @param tls_server_auth
#   Mode used to verify the authenticity of the leaf certificate presented by
#   the syslog server. Can be either 'x509/certvalid' (default, cerficate path
#   validation; a leaf certificate must be signed by the root CA listed in $tls_trusted_ca or
#   its intermediate certificates is or 'x509/name'. In the latter mode, besides the constraint
#   implied by 'x509/certvalid', the leaf certificate must contain an entry in its
#   subjectAltName or common name field that matches StreamDriverPermittedPeers
#   (defaults to the Target, but with the port number stripped).
#   Per RFC 5425 § 5.2, 'x509/name' is strongly preferred, but 'x509/certvalid' can be used
#   for legacy purposes.
# @param tls_netstream_driver
#   Rsyslog Network Stream driver to use for TLS support. Can be either 'gtls'
#   (GnuTLS, default) or 'ossl' (OpenSSL).
# @param tls_trusted_ca
#   ca file to use for netstream pki; defaults to using puppet CA
class profile::syslog::remote (
    Boolean                             $enable               = lookup('profile::syslog::remote::enable'),
    Profile::Syslog::Hosts              $central_hosts_tls    = lookup('profile::syslog::remote::central_hosts_tls'),
    Enum['auth-logs', 'standard']       $send_logs            = lookup('profile::syslog::remote::send_logs'),
    Integer                             $queue_size           = lookup('profile::syslog::remote::queue_size'),
    Boolean                             $tls_client_auth      = lookup('profile::syslog::remote::tls_client_auth'),
    Enum['x509/certvalid', 'x509/name'] $tls_server_auth      = lookup('profile::syslog::remote::tls_server_auth'),
    Enum['gtls', 'ossl']                $tls_netstream_driver = lookup('profile::syslog::remote::tls_netstream_driver'),
    Stdlib::Unixpath                    $tls_trusted_ca       = lookup('profile::syslog::remote::tls_trusted_ca'),
) {
    $owner = 'root'
    $group = 'root'
    # force ossl on buster #T351181
    $_tls_netstream_driver = debian::codename::le('buster').bool2str('ossl', $tls_netstream_driver)

    if $enable {
        if $central_hosts_tls.empty {
            fail('profile::syslog::remote: requires \$central_hosts_tls if enabled')
        }
        $_central_hosts_tls = pick($central_hosts_tls[$::site], $central_hosts_tls['default'])

        if $tls_netstream_driver == 'gtls' {
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

        file { '/etc/rsyslog':
            ensure => 'directory',
            owner  => $owner,
            group  => $group,
            mode   => '0400',
        }

        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs { '/etc/rsyslog':
            provide_private => true,
            user            => $owner,
            group           => $group,
            require         => File['/etc/rsyslog'],
        }
        $cert_file = '/etc/rsyslog/ssl/cert.pem'
        $key_file = '/etc/rsyslog/ssl/server.key'

        rsyslog::conf { 'remote_syslog':
            content  => template('profile/syslog/remote/syslog.conf.erb'),
            priority => 30,
        }
    }
    # No ensure=>absent handling is needed for the $enable == false case
    # because ::rsyslog uses recursive purge to manage the files in its config
    # directory. Simply not adding the file will cause Puppet to remove it if
    # present.
}
