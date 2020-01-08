# === class profile::trafficserver::backend
#
# Sets up a Traffic Server backend instance with relevant Nagios checks.
#
class profile::trafficserver::backend (
    String $user=hiera('profile::trafficserver::user', 'trafficserver'),
    Stdlib::Port $port=hiera('profile::trafficserver::backend::port', 3128),
    Trafficserver::Outbound_TLS_settings $outbound_tls_settings=hiera('profile::trafficserver::backend::outbound_tls_settings'),
    Optional[Trafficserver::Network_settings] $network_settings=hiera('profile::trafficserver::backend::network_settings', undef),
    Optional[Trafficserver::HTTP_settings] $http_settings=hiera('profile::trafficserver::backend::http_settings', undef),
    Optional[Trafficserver::H2_settings] $h2_settings=hiera('profile::trafficserver::backend::h2_settings', undef),
    Boolean $enable_xdebug=hiera('profile::trafficserver::backend::enable_xdebug', false),
    Boolean $enable_compress=hiera('profile::trafficserver::backend::enable_compress', true),
    Boolean $origin_coalescing=hiera('profile::trafficserver::backend::origin_coalescing', true),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::backend::mapping_rules', []),
    Array[TrafficServer::Caching_rule] $caching_rules=hiera('profile::trafficserver::backend::caching_rules', []),
    Optional[TrafficServer::Negative_Caching] $negative_caching=hiera('profile::trafficserver::backend::negative_caching', undef),
    String $default_lua_script=hiera('profile::trafficserver::backend::default_lua_script', ''),
    Array[TrafficServer::Storage_element] $storage=hiera('profile::trafficserver::backend::storage_elements', []),
    Array[TrafficServer::Log_format] $log_formats=hiera('profile::trafficserver::backend::log_formats', []),
    Array[TrafficServer::Log_filter] $log_filters=hiera('profile::trafficserver::backend::log_filters', []),
    Array[TrafficServer::Log] $logs=hiera('profile::trafficserver::backend::logs', []),
    Wmflib::UserIpPort $prometheus_exporter_port=hiera('profile::trafficserver::backend::prometheus_exporter_port', 9122),
    Stdlib::Absolutepath $atsmtail_backend_progs=hiera('profile::trafficserver::backend::atsmtail_backend_progs', '/etc/atsmtail-backend'),
    Wmflib::UserIpPort $atsmtail_backend_port=hiera('profile::trafficserver::backend::atsmtail_backend_port', 3904),
    Boolean $systemd_hardening=hiera('profile::trafficserver::backend::systemd_hardening', true),
){
    $global_lua_script = $default_lua_script? {
        ''      => '',
        default => "/etc/trafficserver/lua/${default_lua_script}.lua",
    }

    # Add hostname to the configuration file read by the default global Lua
    # plugin
    file { "/etc/trafficserver/lua/${default_lua_script}.lua.conf":
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => "lua_hostname = '${::hostname}'\n",
        notify  => Service['trafficserver'],
    }

    file { '/usr/local/lib/nagios/plugins/check_default_ats_lua_conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0555',
        content => "#!/usr/bin/lua\ndofile('/etc/trafficserver/lua/${default_lua_script}.lua.conf')\nassert(lua_hostname)\nprint('OK')\n",
        require => File["/etc/trafficserver/lua/${default_lua_script}.lua.conf"],
    }

    nrpe::monitor_service { 'default_ats_lua_conf':
        description  => 'Default ATS Lua configuration file',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_default_ats_lua_conf',
        require      => File['/usr/local/lib/nagios/plugins/check_default_ats_lua_conf'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/ATS',
    }

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

    $default_instance = true
    $instance_name = 'backend'
    $paths = trafficserver::get_paths($default_instance, 'backend')

    trafficserver::instance { $instance_name:
        paths                 => $paths,
        conftool_service      => 'ats-be',
        default_instance      => $default_instance,
        port                  => $port,
        network_settings      => $network_settings,
        http_settings         => $http_settings,
        h2_settings           => $h2_settings,
        outbound_tls_settings => $outbound_tls_settings,
        enable_xdebug         => $enable_xdebug,
        enable_compress       => $enable_compress,
        origin_coalescing     => $origin_coalescing,
        global_lua_script     => $global_lua_script,
        storage               => $storage,
        ram_cache_size        => 2147483648, # 2G
        mapping_rules         => $mapping_rules,
        caching_rules         => $caching_rules,
        negative_caching      => $negative_caching,
        log_formats           => $log_formats,
        log_filters           => $log_filters,
        logs                  => $logs,
        error_page            => template('mediawiki/errorpage.html.erb'),
        systemd_hardening     => $systemd_hardening,
    }

    # Install default Lua script
    if $default_lua_script != '' {
        trafficserver::lua_script { $default_lua_script:
            source    => "puppet:///modules/profile/trafficserver/${default_lua_script}.lua",
            unit_test => "puppet:///modules/profile/trafficserver/${default_lua_script}_test.lua",
        }
    }

    trafficserver::lua_script { 'x-mediawiki-original':
        source    => 'puppet:///modules/profile/trafficserver/x-mediawiki-original.lua',
        unit_test => 'puppet:///modules/profile/trafficserver/x-mediawiki-original_test.lua',
    }

    trafficserver::lua_script { 'normalize-path':
        source    => 'puppet:///modules/profile/trafficserver/normalize-path.lua',
    }

    trafficserver::lua_script { 'rb-mw-mangling':
        source    => 'puppet:///modules/profile/trafficserver/rb-mw-mangling.lua',
    }

    trafficserver::lua_script { 'x-wikimedia-debug-routing':
        source    => 'puppet:///modules/profile/trafficserver/x-wikimedia-debug-routing.lua',
    }

    # Monitoring
    profile::trafficserver::monitoring { "trafficserver_${instance_name}_monitoring":
        paths                    => $paths,
        port                     => $port,
        prometheus_exporter_port => $prometheus_exporter_port,
        default_instance         => true,
        instance_name            => $instance_name,
        user                     => $user,
    }

    profile::trafficserver::logs { "trafficserver_${instance_name}_logs":
        instance_name => $instance_name,
        user          => $user,
        logs          => $logs,
        paths         => $paths,
    }

    profile::trafficserver::atsmtail { "trafficserver_${instance_name}_atsmtail":
        instance_name  => $instance_name,
        atsmtail_progs => $atsmtail_backend_progs,
        atsmtail_port  => $atsmtail_backend_port,
        wanted_by      => 'trafficserver.service',
    }

    mtail::program { 'atsbackend':
        source      => 'puppet:///modules/mtail/programs/atsbackend.mtail',
        destination => $atsmtail_backend_progs,
        notify      => Service["atsmtail@${instance_name}"],
    }

    # Parse Backend-Timing origin server response header and make the values
    # available to Prometheus
    mtail::program { 'atsbackendtiming':
        source      => 'puppet:///modules/mtail/programs/atsbackendtiming.mtail',
        destination => $atsmtail_backend_progs,
        notify      => Service["atsmtail@${instance_name}"],
    }

    # Make sure the default varnish.service is never started
    exec { 'mask_default_varnish':
        command => '/bin/systemctl mask varnish.service',
        creates => '/etc/systemd/system/varnish.service',
    }
}
