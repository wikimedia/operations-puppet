class profile::cache::haproxy(
    Stdlib::Port $tls_port = lookup('profile::cache::haproxy::tls_port'),
    Hash[String, Haproxy::Tlscertificate] $available_unified_certificates = lookup('profile::cache::haproxy::available_unified_certificates'),
    Optional[Hash[String, Haproxy::Tlscertificate]] $extra_certificates = lookup('profile::cache::haproxy::extra_certificates', {'default_value' => undef}),
    Optional[Array[String]] $unified_certs = lookup('profile::cache::haproxy::unified_certs', {'default_value' => undef}),
    Boolean $unified_acme_chief = lookup('profile::cache::haproxy::unified_acme_chief'),
    Stdlib::Unixpath $varnish_socket = lookup('profile::cache::haproxy::varnish_socket'),
    String $tls_ciphers = lookup('profile::cache::haproxy::tls_ciphers'),
    String $tls13_ciphers = lookup('profile::cache::haproxy::tls13_ciphers'),
    Haproxy::Timeout $timeout = lookup('profile::cache::haproxy::timeout'),
    Haproxy::H2settings $h2settings = lookup('profile::cache::haproxy::h2settings'),
    Boolean $do_ocsp = lookup('profile::cache::haproxy::do_ocsp'),
    String $ocsp_proxy = lookup('http_proxy'),
    String $public_tls_unified_cert_vendor=lookup('public_tls_unified_cert_vendor'),
) {
    # variables used inside HAProxy's systemd unit
    $pid = '/run/haproxy/haproxy.pid'
    $exec_start = '/usr/sbin/haproxy -Ws'

    class { '::haproxy':
        systemd_content => template('profile/cache/haproxy.service.erb'),
        logging         => false,
    }

    require_package('python3-pystemd')
    file { '/usr/local/sbin/haproxy-stek-manager':
        ensure => present,
        source => 'puppet:///modules/profile/cache/haproxy_stek_manager.py',
        owner  => root,
        group  => root,
        mode   => '0544',
    }

    systemd::tmpfile { 'haproxy_secrets_tmpfile':
        content => 'd /run/haproxy-secrets 0700 haproxy haproxy -',
    }

    $tls_ticket_keys_path = '/run/haproxy-secrets/stek.keys'
    systemd::timer::job { 'haproxy_stek_job':
        ensure      => present,
        description => 'HAProxy STEK manager',
        command     => "/usr/local/sbin/haproxy-stek-manager ${tls_ticket_keys_path}",
        interval    => [
            {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 00/8:00:00', # every 8 hours
            },
            {
            'start'    => 'OnBootSec',
            'interval' => '0sec',
            },
        ],
        user        => 'root',
        require     => File['/usr/local/sbin/haproxy-stek-manager'],
    }

    if !$available_unified_certificates[$public_tls_unified_cert_vendor] {
        fail('The specified TLS unified cert vendor is not available')
    }

    unless empty($unified_certs) {
        $unified_certs.each |String $cert| {
            sslcert::certificate { $cert:
                before => Haproxy::Site['tls']
            }

            if $do_ocsp {
                sslcert::ocsp::conf { $cert:
                    proxy  => $ocsp_proxy,
                    before => Service['haproxy'],
                }
                # HAProxy expects the prefetched OCSP response on the same path as the certificate
                file { "/etc/ssl/private/${cert}.crt.key.ocsp":
                    ensure  => link,
                    target  => "/var/cache/ocsp/${cert}.ocsp",
                    require => Sslcert::Ocsp::Conf[$cert],
                }
            }
        }
        if $do_ocsp {
            sslcert::ocsp::hook { 'haproxy-ocsp':
                content => file('profile/cache/update_ocsp_haproxy_hook.sh'),
            }
        }
    }

    if $unified_acme_chief {
        acme_chief::cert { 'unified':
            puppet_svc => 'haproxy',
            key_group  => 'haproxy',
        }
    }

    if !empty($extra_certificates) {
        $extra_certificates.each |String $extra_cert_name, Hash $extra_cert| {
            acme_chief::cert { $extra_cert_name:
                puppet_svc => 'haproxy',
                key_group  => 'haproxy',
            }
        }
        $certificates = [$available_unified_certificates[$public_tls_unified_cert_vendor]] + values($extra_certificates)
    } else {
        $certificates = [$available_unified_certificates[$public_tls_unified_cert_vendor]]
    }

    haproxy::tls_terminator { 'tls':
        port                 => $tls_port,
        backend_socket       => $varnish_socket,
        certificates         => $certificates,
        tls_ciphers          => $tls_ciphers,
        tls13_ciphers        => $tls13_ciphers,
        timeout              => $timeout,
        h2settings           => $h2settings,
        tls_ticket_keys_path => $tls_ticket_keys_path,
    }
}
