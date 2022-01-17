class profile::cache::envoy(
    Stdlib::Port                  $tls_port                  = lookup('profile::cache::envoy::tls_port'),
    Boolean                       $websockets                = lookup('profile::cache::envoy::websockets'),
    Float                         $upstream_connect_timeout  = lookup('profile::cache::envoy::upstream_connect_timeout'),
    Float                         $upstream_response_timeout = lookup('profile::cache::envoy::upstream_response_timeout'),
    Float                         $downstream_idle_timeout   = lookup('profile::cache::envoy::downstream_idle_timeout'),
    Float                         $stream_idle_timeout       = lookup('profile::cache::envoy::stream_idle_timeout'),
    Float                         $request_timeout           = lookup('profile::cache::envoy::request_timeout'),
    Float                         $request_headers_timeout   = lookup('profile::cache::envoy::request_headers_timeout'),
    Hash[String, Envoyproxy::TlsconfigV3] $available_unified_upstreams = lookup('profile::cache::envoy::available_unified_upstreams'),
    Optional[Hash[String, Envoyproxy::TlsconfigV3]] $extra_upstreams = lookup('profile::cache::envoy::extra_upstreams', {'default_value' => undef}),
    Optional[Array[String]]       $unified_certs             = lookup('profile::cache::envoy::unified_certs'),
    Boolean                       $unified_acme_chief        = lookup('profile::cache::envoy::unified_acme_chief'),
    Envoyproxy::Tlsparams         $tlsparams                 = lookup('profile::cache::envoy::tls_params'),
    Envoyproxy::Alpn              $alpn                      = lookup('profile::cache::envoy::alpn_protocols'),
    Envoyproxy::Http2options      $http2_options             = lookup('profile::cache::envoy::http2_options'),
    Integer                       $connection_buffer_limit   = lookup('profile::cache::envoy::connection_buffer_limit'),
    String $public_tls_unified_cert_vendor=lookup('public_tls_unified_cert_vendor'),
    Boolean $do_ocsp = lookup('profile::cache::envoy::do_ocsp'),
    String $ocsp_proxy = lookup('http_proxy'),
) {
    require profile::envoy
    if $do_ocsp {
        class { 'sslcert::ocsp::init':
            cache_group => 'envoy',
        }
    }

    apt::package_from_component { 'envoyproxy':
        component       => 'component/envoy-future',
        ensure_packages => false,
        before          => Package['envoyproxy'],
    }


    if !$available_unified_upstreams[$public_tls_unified_cert_vendor] {
        fail('The specified TLS unified cert vendor is not available')
    }

    $secrets_path = '/run/envoy-secrets'
    $stek_files = ["${secrets_path}/stek.key.0", "${secrets_path}/stek.key.1", "${secrets_path}/stek.key.2", "${secrets_path}/stek.key.3",]

    systemd::tmpfile { 'envoy_secrets_tmpfile':
        content => "d ${secrets_path} 0700 envoy envoy -",
        require => Package['envoyproxy'],
    }

    file { '/etc/systemd/system/envoyproxy.service.d/ocsp.conf':
        ensure  => bool2str($do_ocsp, 'present', 'absent'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "[Service]\nExecStartPre=/usr/local/sbin/update-ocsp-all\nReadWritePaths=/var/cache/ocsp\n",
        notify  => Exec['systemd daemon-reload for envoyproxy.service'],
    }

    # since LimitNOFILE is also defined on puppet-override.conf
    # we need a filename that triggers it to be evaluated *after*
    # puppet-override.conf
    file { '/etc/systemd/system/envoyproxy.service.d/traffic-limits.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "[Service]\nLimitNOFILE=500000\n",
        notify  => Exec['systemd daemon-reload for envoyproxy.service'],
    }

    unless empty($unified_certs) {
        $unified_certs.each |String $cert| {
            sslcert::certificate { $cert:
                group  => 'envoy',
                before => Envoyproxy::Tls_terminator["${tls_port}"], # lint:ignore:only_variable_string
            }
            if $do_ocsp {
                sslcert::ocsp::conf { $cert:
                    proxy  => $ocsp_proxy,
                    before => Envoyproxy::Tls_terminator["${tls_port}"], # lint:ignore:only_variable_string
                }
            }
        }
        if $do_ocsp {
            sslcert::ocsp::hook { 'envoyproxy-ocsp':
                content => file('profile/cache/update_ocsp_envoyproxy_hook.sh'),
            }
        }
    }

    if $unified_acme_chief {
        acme_chief::cert { 'unified':
            puppet_svc => 'envoyproxy.service',
            key_group  => 'envoy',
        }
    }

    if !empty($extra_upstreams) {
        $extra_upstreams.each |String $extra_cert_name, Envoyproxy::TlsconfigV3 $extra_upstream| {
            acme_chief::cert { $extra_cert_name:
                puppet_svc => 'envoyproxy.service',
                key_group  => 'envoy',
            }
        }
        $available_upstreams = [$available_unified_upstreams[$public_tls_unified_cert_vendor]] + values($extra_upstreams)
    } else {
        $available_upstreams = [$available_unified_upstreams[$public_tls_unified_cert_vendor]]
    }

    $upstreams = $available_upstreams.map |Envoyproxy::TlsconfigV3 $upstream| {
        $ret = {
            server_names   => $upstream['server_names'],
            certificates   => $upstream['certificates'],
            upstream       => $upstream['upstream'],
            tlsparams      => $tlsparams,
            alpn_protocols => $alpn,
        }
        $ret
    }

    ensure_packages('python3-pystemd')
    file { '/usr/local/sbin/envoy-stek-manager':
        ensure => present,
        source => 'puppet:///modules/profile/cache/envoy_stek_manager.py',
        owner  => root,
        group  => root,
        mode   => '0544',
    }

    systemd::timer::job { 'envoy_stek_job':
        ensure      => present,
        description => 'envoy STEK manager',
        command     => "/usr/local/sbin/envoy-stek-manager ${secrets_path}",
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
        require     => [File['/usr/local/sbin/envoy-stek-manager'], Systemd::Tmpfile['envoy_secrets_tmpfile'], Package['python3-pystemd']],
    }

    envoyproxy::tls_terminator { "${tls_port}": # lint:ignore:only_variable_string
        api_version               => $profile::envoy::api_version,
        upstreams                 => $upstreams,
        websockets                => $websockets,
        fast_open_queue           => 150,
        global_certs              => $available_unified_upstreams[$public_tls_unified_cert_vendor]['certificates'],
        retry_policy              => {'num_retries' => 0},
        use_remote_address        => true,
        header_key_format         => 'preserve_case',
        listen_ipv6               => true,
        generate_request_id       => false,
        global_tlsparams          => $tlsparams,
        global_alpn_protocols     => $alpn,
        lua_script                => file('profile/cache/envoy.lua'),
        stek_files                => $stek_files,
        http2_options             => $http2_options,
        connection_buffer_limit   => $connection_buffer_limit,
        downstream_idle_timeout   => $downstream_idle_timeout,
        connect_timeout           => $upstream_connect_timeout,
        upstream_response_timeout => $upstream_response_timeout,
        stream_idle_timeout       => $stream_idle_timeout,
        request_timeout           => $request_timeout,
        request_headers_timeout   => $request_headers_timeout,
        max_requests_per_conn     => 10000,
    }
}
