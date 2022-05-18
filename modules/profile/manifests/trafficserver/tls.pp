# === class profile::trafficserver::tls
#
# Class that sets up a Traffic Server TLS terminator instance.
#
class profile::trafficserver::tls (
    String $user=lookup('profile::trafficserver::tls::user', {default_value => 'trafficserver'}),
    Stdlib::Port $https_port=lookup('profile::trafficserver::tls::https_port', {default_value => 443}),
    Optional[Trafficserver::Network_settings] $network_settings=lookup('profile::trafficserver::tls::network_settings', {default_value => undef}),
    Optional[Trafficserver::HTTP_settings] $http_settings=lookup('profile::trafficserver::tls::http_settings', {default_value => undef}),
    Optional[Trafficserver::H2_settings] $h2_settings=lookup('profile::trafficserver::tls::h2_settings', {default_value => undef}),
    Trafficserver::Inbound_TLS_settings $tls_settings=lookup('profile::trafficserver::tls::inbound_tls_settings'),
    Boolean $enable_xdebug=lookup('profile::trafficserver::tls::enable_xdebug', {default_value => false}),
    Array[TrafficServer::Mapping_rule] $mapping_rules=lookup('profile::trafficserver::tls::mapping_rules', {default_value => []}),
    Array[TrafficServer::Log_format] $log_formats=lookup('profile::trafficserver::tls::log_formats', {default_value => []}),
    Array[TrafficServer::Log_filter] $log_filters=lookup('profile::trafficserver::tls::log_filters', {default_value => []}),
    Array[TrafficServer::Log] $logs=lookup('profile::trafficserver::tls::logs', {default_value => []}),
    Array[TrafficServer::Parent_rule] $parent_rules=lookup('profile::trafficserver::tls::parent_rules'),
    Stdlib::Port::User $prometheus_exporter_port=lookup('profile::trafficserver::tls::prometheus_exporter_port', {default_value => 9322}),
    Optional[Array[String]] $unified_certs = lookup('profile::trafficserver::tls::unified_certs', {default_value => undef}),
    Boolean $unified_acme_chief = lookup('profile::trafficserver::tls::unified_acme_chief', {default_value => false}),
    Boolean $websocket_support = lookup('profile::trafficserver::tls::websocket_support', {default_value => false}),
    Optional[String] $ocsp_proxy=lookup('http_proxy'),
    Boolean $systemd_hardening=lookup('profile::trafficserver::tls::systemd_hardening', {default_value => true}),
    Hash[String, Trafficserver::TLS_certificate] $available_unified_certs=lookup('profile::trafficserver::tls::available_unified_certs'),
    String $public_tls_unified_cert_vendor=lookup('public_tls_unified_cert_vendor'),
    Optional[Hash[String, Trafficserver::TLS_certificate]] $extra_certs=lookup('profile::trafficserver::tls::extra_certs', {default_value => undef}),
    String $conftool_service=lookup('profile::trafficserver::tls::conftool_service', {default_value => 'ats-tls'}),
    Optional[Integer[0,2]] $res_track_memory=lookup('profile::trafficserver::tls::res_track_memory', {'default_value' => undef}),
    Stdlib::Absolutepath $atsmtail_progs=lookup('profile::trafficserver::tls::atsmtail_tls_progs', {'default_value' => '/etc/atsmtail-tls'}),
    Stdlib::Port::User $atsmtail_port=lookup('profile::trafficserver::tls::atsmtail_tls_port', {'default_value' => 3905}),
    String $mtail_args=lookup('profile::trafficserver::tls::mtail_args', {'default_value' => ''}),
    Boolean $monitor_enable=lookup('profile::trafficserver::tls::monitor_enable'),
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

    if $inbound_tls_settings['session_ticket_enable'] == 1 and empty($inbound_tls_settings['session_ticket_filename']) {
        fail('Invalid TLS session ticket settings. Please provide a ticket filename')
    }

    $websocket_arg = bool2str($websocket_support)
    if !empty($http_settings) and $http_settings['keep_alive_enabled_out'] == 1 {
        $keepalive_arg = 'true'  # lint:ignore:quoted_booleans
    } else {
        $keepalive_arg = 'false' # lint:ignore:quoted_booleans
    }

    if num2bool($inbound_tls_settings['do_ocsp']) {
        class { 'sslcert::ocsp::init':
        }
    }

    systemd::tmpfile { "trafficserver_${instance_name}_secrets_tmpfile":
        content => "d ${paths['secretsdir']} 0700 root root -",
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
        secrets_fullpath   => $paths['secretsdir'],
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

    if $inbound_tls_settings['session_ticket_enable'] == 1 {
        $ensure_stek = present
        ensure_packages('python3-pystemd')
    } else {
        $ensure_stek = absent
    }

    file { '/usr/local/sbin/ats-stek-manager':
        ensure => $ensure_stek,
        source => 'puppet:///modules/profile/trafficserver/ats_stek_manager.py',
        owner  => root,
        group  => root,
        mode   => '0544',
    }

    systemd::timer::job { "trafficserver_${instance_name}_stek_job":
        ensure      => $ensure_stek,
        description => "trafficserver-${instance_name} STEK manager",
        command     => "/usr/local/sbin/ats-stek-manager ${paths['stekfile']}",
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
        require     => File['/usr/local/sbin/ats-stek-manager'],
    }

    trafficserver::instance { $instance_name:
        paths                  => $paths,
        conftool_service       => $conftool_service,
        https_port             => $https_port,
        disable_dns_resolution => 1,
        network_settings       => $network_settings,
        http_settings          => $http_settings,
        h2_settings            => $h2_settings,
        inbound_tls_settings   => $inbound_tls_settings,
        enable_xdebug          => $enable_xdebug,
        mapping_rules          => $mapping_rules,
        global_lua_script      => $tls_lua_script_path,
        enable_caching         => false,
        log_formats            => $log_formats,
        log_filters            => $log_filters,
        logs                   => $logs,
        parent_rules           => $parent_rules,
        error_page             => template('mediawiki/errorpage.html.erb'),
        x_forwarded_for        => 1,
        systemd_hardening      => $systemd_hardening,
        res_track_memory       => $res_track_memory,
    }

    trafficserver::lua_script { 'tls':
        source        => 'puppet:///modules/profile/trafficserver/tls.lua',
        unit_test     => 'puppet:///modules/profile/trafficserver/tls_test.lua',
        service_name  => $service_name,
        config_prefix => $paths['sysconfdir'],
    }

    if $monitor_enable {
        # Monitoring
        profile::trafficserver::monitoring { "trafficserver_${instance_name}_monitoring":
            paths                    => $paths,
            port                     => $https_port,
            prometheus_exporter_port => $prometheus_exporter_port,
            inbound_tls              => $inbound_tls_settings,
            instance_name            => $instance_name,
            acme_chief               => $unified_acme_chief,
            disable_config_check     => true,
            user                     => $user,
        }
    }

    profile::trafficserver::logs { "trafficserver_${instance_name}_logs":
        instance_name    => $instance_name,
        user             => $user,
        service_name     => $service_name,
        conftool_service => $conftool_service,
        logs             => $logs,
        paths            => $paths,
        atslog_filename  => 'analytics',
    }

    profile::trafficserver::atsmtail { "trafficserver_${instance_name}_atsmtail":
        instance_name  => $instance_name,
        atsmtail_progs => $atsmtail_progs,
        atsmtail_port  => $atsmtail_port,
        wanted_by      => 'fifo-log-demux@analytics.service',
        mtail_args     => $mtail_args,
    }

    mtail::program { 'atstls':
        source      => 'puppet:///modules/mtail/programs/atstls.mtail',
        destination => $atsmtail_progs,
        notify      => Service["atsmtail@${instance_name}"],
    }
}
