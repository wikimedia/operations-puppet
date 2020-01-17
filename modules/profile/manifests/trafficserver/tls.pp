# === class profile::trafficserver::tls
#
# Class that sets up a Traffic Server TLS terminator instance.
#
class profile::trafficserver::tls (
    String $user=hiera('profile::trafficserver::tls::user', 'trafficserver'),
    Stdlib::Port $port=hiera('profile::trafficserver::tls::port', 8443),
    Optional[Trafficserver::Network_settings] $network_settings=hiera('profile::trafficserver::tls::network_settings', undef),
    Optional[Trafficserver::HTTP_settings] $http_settings=hiera('profile::trafficserver::tls::http_settings', undef),
    Optional[Trafficserver::H2_settings] $h2_settings=hiera('profile::trafficserver::tls::h2_settings', undef),
    Trafficserver::Inbound_TLS_settings $tls_settings=hiera('profile::trafficserver::tls::inbound_tls_settings'),
    Boolean $enable_xdebug=hiera('profile::trafficserver::tls::enable_xdebug', false),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::tls::mapping_rules', []),
    Array[TrafficServer::Log_format] $log_formats=hiera('profile::trafficserver::tls::log_formats', []),
    Array[TrafficServer::Log_filter] $log_filters=hiera('profile::trafficserver::tls::log_filters', []),
    Array[TrafficServer::Log] $logs=hiera('profile::trafficserver::tls::logs', []),
    Array[TrafficServer::Parent_rule] $parent_rules=hiera('profile::trafficserver::tls::parent_rules'),
    Wmflib::UserIpPort $prometheus_exporter_port=hiera('profile::trafficserver::tls::prometheus_exporter_port', 9322),
    Optional[Array[String]] $unified_certs = hiera('profile::trafficserver::tls::unified_certs', undef),
    Boolean $unified_acme_chief = hiera('profile::trafficserver::tls::unified_acme_chief', false),
    Boolean $websocket_support = hiera('profile::trafficserver::tls::websocket_support', false),
    Optional[String] $ocsp_proxy=hiera('http_proxy'),
    Boolean $systemd_hardening=hiera('profile::trafficserver::tls::systemd_hardening', true),
    Hash[String, Trafficserver::TLS_certificate] $available_unified_certs=hiera('profile::trafficserver::tls::available_unified_certs'),
    String $public_tls_unified_cert_vendor=hiera('public_tls_unified_cert_vendor'),
    Optional[Hash[String, Trafficserver::TLS_certificate]] $extra_certs=hiera('profile::trafficserver::tls::extra_certs', undef),
){
    $errorpage = {
        title       => 'Wikimedia Error',
        pagetitle   => 'Error',
        logo_link   => 'https://www.wikimedia.org',
        logo_src    => 'https://www.wikimedia.org/static/images/wmf-logo.png',
        logo_srcset => 'https://www.wikimedia.org/static/images/wmf-logo-2x.png 2x',
        logo_width  => '135',
        logo_height => '101',
        logo_alt    => 'Wikimedia',
        # An explanation for these (and more) fields is available here:
        # https://docs.trafficserver.apache.org/en/latest/admin-guide/logging/formatting.en.html
        # Rendered example:
        # Request from 93.184.216.34 via cp1071.eqiad.wmnet, ATS/8.0.3
        # Error: 502, connect failed at 2019-04-04 12:22:08 GMT
        footer      => "<p>If you report this error to the Wikimedia System Administrators, please include the details below.</p><p class='text-muted'><code>Request from %<{X-Client-IP}cqh> via ${::fqdn}, %<{Server}psh><br>Error: %<pssc>, %<prrp> at %<cqtd> %<cqtt> GMT</code></p>",
    }

    $instance_name = 'tls'
    $service_name = "trafficserver-${instance_name}"
    $paths = trafficserver::get_paths(false, $instance_name)
    $tls_lua_script_path = "${paths['sysconfdir']}/lua/tls.lua"
    $tls_material_path = "${paths['sysconfdir']}/tls"
    if !$available_unified_certs[$public_tls_unified_cert_vendor] {
        fail('The specified TLS unified cert vendor is not available')
    }
    $tls_paths = {
        'cert_path'          => $tls_material_path,
        'private_key_path'   => $tls_material_path,
        'ocsp_stapling_path' => $tls_material_path,
    }
    $paths_tls_settings = merge($tls_settings, $tls_paths)

    if !empty($extra_certs) {
        $extra_certs.each |String $extra_cert_name, Trafficserver::TLS_certificate $extra_cert| {
            if $extra_cert['default'] {
                fail("${extra_cert} cannot be the default certificate")
            }
            if !$extra_cert['acme_chief'] {
                fail("${extra_cert} must be an acme-chief managed certificate")
            }
        }
        $available_certs = [$available_unified_certs[$public_tls_unified_cert_vendor]] + values($extra_certs)
    } else {
        $available_certs = [$available_unified_certs[$public_tls_unified_cert_vendor]]
    }
    $inbound_tls_settings = merge($paths_tls_settings, {'certificates' => $available_certs})
    if $inbound_tls_settings['do_ocsp'] == 1 and empty($inbound_tls_settings['ocsp_stapling_path']) {
        fail('The provided Inbound TLS settings are insufficient to ensure prefetched OCSP stapling responses')
    }
    $inbound_tls_settings['certificates'].each |Trafficserver::TLS_certificate $certificate| {
        if $inbound_tls_settings['do_ocsp'] == 1 and empty($certificate['ocsp_stapling_files']) {
            fail('The provided Inbound TLS settings are insufficient to ensure prefetched OCSP stapling responses')
        }
    }

    $websocket_arg = bool2str($websocket_support)

    # Write configuration file for global TLS Lua script
    file { "${tls_lua_script_path}.conf":
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => "lua_websocket_support = ${websocket_arg}\n",
        notify  => Service[$service_name],
    }

    file { '/usr/local/lib/nagios/plugins/check_tls_lua_conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0555',
        content => "#!/usr/bin/lua\ndofile('${tls_lua_script_path}.conf')\nassert(lua_websocket_support ~= nil)\nprint('OK')\n",
        require => File["${tls_lua_script_path}.conf"],
    }

    nrpe::monitor_service { 'tls_lua_conf':
        description  => 'TLS Lua configuration file',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_tls_lua_conf',
        require      => File['/usr/local/lib/nagios/plugins/check_tls_lua_conf'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/ATS',
    }

    profile::trafficserver::tls_material { 'unified':
        instance_name      => $instance_name,
        service_name       => $service_name,
        tls_material_path  => $tls_material_path,
        ssl_multicert_path => $paths['ssl_multicert'],
        certs              => $unified_certs,
        acme_chief         => $unified_acme_chief,
        do_ocsp            => num2bool($inbound_tls_settings['do_ocsp']),
        ocsp_proxy         => $ocsp_proxy,
    }

    if !empty($extra_certs) {
        $extra_certs_names = keys($extra_certs)

        profile::trafficserver::tls_material { $extra_certs_names:
            instance_name      => $instance_name,
            service_name       => $service_name,
            tls_material_path  => $tls_material_path,
            ssl_multicert_path => $paths['ssl_multicert'],
            acme_chief         => true,
            do_ocsp            => num2bool($inbound_tls_settings['do_ocsp']),
            ocsp_proxy         => $ocsp_proxy,
        }
    }

    trafficserver::instance { $instance_name:
        paths                     => $paths,
        conftool_service          => 'nginx', # TODO: Rename it to ats-tls
        port                      => $port,
        keep_alive_origin_servers => 0,
        disable_dns_resolution    => 0,
        server_session_sharing    => 'none',
        network_settings          => $network_settings,
        http_settings             => $http_settings,
        h2_settings               => $h2_settings,
        inbound_tls_settings      => $inbound_tls_settings,
        enable_xdebug             => $enable_xdebug,
        mapping_rules             => $mapping_rules,
        global_lua_script         => $tls_lua_script_path,
        enable_caching            => false,
        log_formats               => $log_formats,
        log_filters               => $log_filters,
        logs                      => $logs,
        parent_rules              => $parent_rules,
        error_page                => template('mediawiki/errorpage.html.erb'),
        x_forwarded_for           => 1,
        systemd_hardening         => $systemd_hardening,
    }

    trafficserver::lua_script { 'tls':
        source        => 'puppet:///modules/profile/trafficserver/tls.lua',
        unit_test     => 'puppet:///modules/profile/trafficserver/tls_test.lua',
        service_name  => $service_name,
        config_prefix => $paths['sysconfdir'],
    }

    # Monitoring
    profile::trafficserver::monitoring { "trafficserver_${instance_name}_monitoring":
        paths                    => $paths,
        port                     => $port,
        prometheus_exporter_port => $prometheus_exporter_port,
        inbound_tls              => $inbound_tls_settings,
        instance_name            => $instance_name,
        acme_chief               => $unified_acme_chief,
        disable_config_check     => true,
        user                     => $user,
    }

    profile::trafficserver::logs { "trafficserver_${instance_name}_logs":
        instance_name   => $instance_name,
        user            => $user,
        service_name    => $service_name,
        logs            => $logs,
        paths           => $paths,
        atslog_filename => 'tls',
    }
}
