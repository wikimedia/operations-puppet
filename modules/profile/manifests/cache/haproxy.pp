# SPDX-License-Identifier: Apache-2.0
class profile::cache::haproxy(
    Stdlib::Port $tls_port = lookup('profile::cache::haproxy::tls_port'),
    Stdlib::Port $prometheus_port = lookup('profile::cache::haproxy::prometheus_port', {'default_value'                                          => 9422}),
    Hash[String, Haproxy::Tlscertificate] $available_unified_certificates = lookup('profile::cache::haproxy::available_unified_certificates'),
    Optional[Hash[String, Haproxy::Tlscertificate]] $extra_certificates = lookup('profile::cache::haproxy::extra_certificates', {'default_value' => undef}),
    Optional[Array[String]] $unified_certs = lookup('profile::cache::haproxy::unified_certs', {'default_value'                                   => undef}),
    Boolean $unified_acme_chief = lookup('profile::cache::haproxy::unified_acme_chief'),
    Haproxy::Backend $varnish_socket = lookup('profile::cache::haproxy::varnish_socket'),
    String $tls_ciphers = lookup('profile::cache::haproxy::tls_ciphers'),
    String $tls13_ciphers = lookup('profile::cache::haproxy::tls13_ciphers'),
    Integer[0] $tls_cachesize = lookup('profile::cache::haproxy::tls_cachesize'),
    Integer[0] $tls_session_lifetime = lookup('profile::cache::haproxy::tls_session_lifetime'),
    Haproxy::Timeout $timeout = lookup('profile::cache::haproxy::timeout'),
    Haproxy::H2settings $h2settings = lookup('profile::cache::haproxy::h2settings'),
    Optional[Haproxy::Proxyprotocol] $proxy_protocol = lookup('profile::cache::haproxy::proxy_protocol', {'default_value'                        => undef}),
    Hash[String, Array[Haproxy::Var]] $vars = lookup('profile::cache::haproxy::vars'),
    Hash[String, Array[Haproxy::Acl]] $acls = lookup('profile::cache::haproxy::acls'),
    Hash[String, Array[Haproxy::Header]] $add_headers = lookup('profile::cache::haproxy::add_headers'),
    Hash[String, Array[Haproxy::Header]] $del_headers = lookup('profile::cache::haproxy::del_headers'),
    Optional[Hash[String, Array[Haproxy::Action]]] $pre_acl_actions = lookup('profile::cache::haproxy::pre_acl_actions', {'default_value'                      => undef}),
    Optional[Hash[String, Array[Haproxy::Action]]] $post_acl_actions = lookup('profile::cache::haproxy::post_acl_actions', {'default_value'                    => undef}),
    Optional[Array[Haproxy::Sticktable]] $sticktables = lookup('profile::cache::haproxy::sticktables', {'default_value'                          => undef}),
    Boolean $do_ocsp = lookup('profile::cache::haproxy::do_ocsp'),
    Boolean $http_disable_keepalive = lookup('profile::cache::haproxy::http_disable_keepalive', {'default_value'                                 => false}),
    Optional[Stdlib::HTTPUrl] $ocsp_proxy = lookup('http_proxy', {'default_value'                                                                => undef}),
    String $public_tls_unified_cert_vendor=lookup('public_tls_unified_cert_vendor'),
    Stdlib::Unixpath $mtail_dir = lookup('profile::cache::haproxy::mtail_dir', {'default_value'                                                  => '/etc/haproxymtail'}),
    Stdlib::Port::User $mtail_port = lookup('profile::cache::haproxy::mtail_port', {'default_value'                                              => 3906}),
    Stdlib::Unixpath $mtail_fifo = lookup('profile::cache::haproxy::mtail_fifo', {'default_value'                                                => '/var/log/haproxy.fifo'}),
    Boolean $monitoring_enabled = lookup('profile::cache::haproxy::monitoring_enabled'),
    Haproxy::Version $haproxy_version = lookup('profile::cache::haproxy::version', {'default_value'                                              => 'haproxy24'}),
    Boolean $do_systemd_hardening = lookup('profile::cache::haproxy::do_systemd_hardening', {'default_value'                                     => false}),
    Boolean $enable_coredumps = lookup('profile::cache::haproxy::enable_coredumps', {'default_value'                                             => false}),
    Optional[Stdlib::Port] $http_redirection_port = lookup('profile::cache::haproxy::http_redirection_port', {'default_value'                    => 80}),
    Optional[Haproxy::Timeout] $redirection_timeout = lookup('profile::cache::haproxy::redirection_timeout', {'default_value'                    => undef}),
    Optional[Array[Haproxy::Filter]] $filters = lookup('profile::cache::haproxy::filters', {'default_value'                                      => undef}),
    Boolean $dedicated_hc_backend = lookup('profile::cache::haproxy::dedicated_hc_backend', {'default_value'                                     => false}),
    Boolean $extended_logging = lookup('profile::cache::haproxy::extended_logging', {'default_value'                                             => false}),
    Boolean $use_benthos = lookup('profile::cache::base::use_benthos', {'default_value'                                                          => false}),
    String $benthos_socket = lookup('profile::cache::base::benthos_socket_address', {'default_value'                                             => '127.0.0.1:1221'}),
    Optional[Array[Stdlib::IP::Address]] $hc_sources = lookup('haproxy_allowed_healthcheck_sources', {'default_value'                            => undef}),
    Boolean $install_haproxy26_component = lookup('profile::cache::haproxy::install_haproxy26_component', {'default_value'                       => false}),
    Optional[Integer] $log_length = lookup('profile::cache::haproxy::log_length', {'default_value'                                               => 8192}),
) {
    class { 'sslcert::dhparam':
    }
    if $do_ocsp {
        class { 'sslcert::ocsp::init':
        }
    }

    # variable used inside HAProxy's systemd unit
    $pid = '/run/haproxy/haproxy.pid'

    # If we want to install haproxy from component/haproxy26 on bookworm, built
    # against OpenSSL 1.1.1; see T352744.
    if $install_haproxy26_component and debian::codename::eq('bookworm') {
        $component = 'component/haproxy26'
    } else {
        $component = "thirdparty/${haproxy_version}"
    }

    apt::package_from_component { 'haproxy':
        component       => $component,
        before          => Class['::haproxy'],
        priority        => 1002, # Take precedence over main
        ensure_packages => false, # this is handled by ::haproxy
    }

    # If numa_networking is turned on, use interface_primary for NUMA hinting,
    # otherwise use 'lo' for this purpose.  Assumes NUMA data has "lo" interface
    # mapped to all cpu cores in the non-NUMA case.  The numa_iface variable is
    # in turn consumed by the systemd unit and config templates.
    if $::numa_networking != 'off' {
        $numa_iface = $facts['interface_primary']
    } else {
        $numa_iface = 'lo'
    }

    # used on haproxy.cfg.erb
    $socket = '/run/haproxy/haproxy.sock'

    class { '::haproxy':
        config_content        => template('profile/cache/haproxy.cfg.erb'),
        systemd_content       => template('profile/cache/haproxy.service.erb'),
        logging               => false,
        monitor_check_haproxy => false,
    }

    ensure_packages('python3-pystemd')
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
                file { "/etc/ssl/private/${cert}.chained.crt.key.ocsp":
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

    file { '/etc/haproxy/tls.lua':
        ensure  => absent,
        owner   => 'haproxy',
        group   => 'haproxy',
        mode    => '0444',
        content => file('profile/cache/haproxy-tls.lua'),
    }

    haproxy::tls_terminator { 'tls':
        port                   => $tls_port,
        backend                => $varnish_socket,
        certificates           => $certificates,
        tls_ciphers            => $tls_ciphers,
        tls13_ciphers          => $tls13_ciphers,
        timeout                => $timeout,
        h2settings             => $h2settings,
        proxy_protocol         => $proxy_protocol,
        tls_cachesize          => $tls_cachesize,
        tls_session_lifetime   => $tls_session_lifetime,
        tls_ticket_keys_path   => $tls_ticket_keys_path,
        http_reuse             => 'always',
        vars                   => $vars,
        acls                   => $acls,
        add_headers            => $add_headers,
        del_headers            => $del_headers,
        pre_acl_actions        => $pre_acl_actions,
        post_acl_actions       => $post_acl_actions,
        prometheus_port        => $prometheus_port,
        numa_iface             => $numa_iface,
        sticktables            => $sticktables,
        haproxy_version        => $haproxy_version,
        http_redirection_port  => $http_redirection_port,
        redirection_timeout    => $redirection_timeout,
        http_disable_keepalive => $http_disable_keepalive,
        filters                => $filters,
        dedicated_hc_backend   => $dedicated_hc_backend,
        hc_sources             => $hc_sources,
        extended_logging       => $extended_logging,
        wikimedia_trust        => $profile::cache::base::wikimedia_trust,
    }

    if $monitoring_enabled {
      profile::cache::haproxy::monitoring { 'haproxy_tls_monitoring':
          port         => $tls_port,
          certificates => $certificates,
          do_ocsp      => $do_ocsp,
          acme_chief   => $unified_acme_chief,
          require      => Haproxy::Tls_terminator['tls'],
      }
    }

    systemd::service { 'haproxy-mtail@tls.socket':
        content => systemd_template('haproxy-mtail@.socket'),
    }

    systemd::service { 'haproxy-mtail@tls':
        content => systemd_template('haproxy-mtail@'),
    }

    rsyslog::conf { 'haproxy@tls':
        priority => 20,
        content  => template('profile/cache/haproxy.rsyslog.conf.erb'),
    }

    mtail::program { 'cache_haproxy':
        source      => 'puppet:///modules/mtail/programs/cache_haproxy.mtail',
        destination => $mtail_dir,
        notify      => Service['haproxy-mtail@tls'],
    }

    file { '/usr/local/sbin/haproxy-restart':
        ensure  => present,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => file('profile/cache/haproxy_restart.sh'),
    }

}
