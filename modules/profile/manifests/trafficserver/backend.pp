# SPDX-License-Identifier: Apache-2.0
# === class profile::trafficserver::backend
#
# Sets up a Traffic Server backend instance with relevant Nagios checks.
#
class profile::trafficserver::backend (
    String                                    $user                     = lookup('profile::trafficserver::user', {default_value => 'trafficserver'}),
    Integer                                   $max_lua_states           = lookup('profile::trafficserver::max_lua_states', {default_value => 256}),
    Stdlib::Port                              $http_port                = lookup('profile::trafficserver::backend::http_port', {default_value => 3128}),
    Trafficserver::Outbound_TLS_settings      $outbound_tls_settings    = lookup('profile::trafficserver::backend::outbound_tls_settings'),
    Optional[Trafficserver::Network_settings] $network_settings         = lookup('profile::trafficserver::backend::network_settings', {default_value => undef}),
    Optional[Trafficserver::HTTP_settings]    $http_settings            = lookup('profile::trafficserver::backend::http_settings', {default_value => undef}),
    Optional[Trafficserver::H2_settings]      $h2_settings              = lookup('profile::trafficserver::backend::h2_settings', {default_value => undef}),
    Boolean                                   $enable_xdebug            = lookup('profile::trafficserver::backend::enable_xdebug', {default_value => false}),
    Boolean                                   $enable_compress          = lookup('profile::trafficserver::backend::enable_compress', {default_value => true}),
    Boolean                                   $origin_coalescing        = lookup('profile::trafficserver::backend::origin_coalescing', {default_value => true}),
    Profile::Cache::Sites                     $req_handling             = lookup('cache::req_handling'),
    Profile::Cache::Sites                     $alternate_domains        = lookup('cache::alternate_domains', {'default_value' => {}}),
    Array[TrafficServer::Mapping_rule]        $mapping_rules            = lookup('profile::trafficserver::backend::mapping_rules', {default_value => []}),
    Optional[TrafficServer::Negative_Caching] $negative_caching         = lookup('profile::trafficserver::backend::negative_caching', {default_value => undef}),
    String                                    $default_lua_script       = lookup('profile::trafficserver::backend::default_lua_script', {default_value => ''}),
    Array[TrafficServer::Storage_element]     $storage                  = lookup('profile::trafficserver::backend::storage_elements', {default_value => []}),
    Integer                                   $ram_cache_size           = lookup('profile::trafficserver::backend::ram_cache_size', {default_value => 2147483648}),
    Array[TrafficServer::Log_format]          $log_formats              = lookup('profile::trafficserver::backend::log_formats', {default_value => []}),
    Array[TrafficServer::Log_filter]          $log_filters              = lookup('profile::trafficserver::backend::log_filters', {default_value => []}),
    Array[TrafficServer::Log]                 $logs                     = lookup('profile::trafficserver::backend::logs', {default_value => []}),
    Stdlib::Port::User                        $prometheus_exporter_port = lookup('profile::trafficserver::backend::prometheus_exporter_port', {default_value => 9122}),
    Stdlib::Absolutepath                      $atsmtail_backend_progs   = lookup('profile::trafficserver::backend::atsmtail_backend_progs', {default_value => '/etc/atsmtail-backend'}),
    Stdlib::Port::User                        $atsmtail_backend_port    = lookup('profile::trafficserver::backend::atsmtail_backend_port', {default_value => 3904}),
    String                                    $mtail_args               = lookup('profile::trafficserver::backend::mtail_args', {'default_value' => ''}),
    Boolean                                   $systemd_hardening        = lookup('profile::trafficserver::backend::systemd_hardening', {default_value => true}),
    Stdlib::Filesource                        $trusted_ca_source        = lookup('profile::trafficserver::backend::trusted_ca_source'),
    Stdlib::Unixpath                          $trusted_ca_path          = lookup('profile::trafficserver::backend::trusted_ca_path'),
    Boolean                                   $monitor_enable           = lookup('profile::trafficserver::backend::monitor_enable'),
    Integer[1]                                $cache_volumes            = lookup('profile::trafficserver::backend::cache_volumes', {default_value => 1}),
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

    nrpe::plugin { 'check_default_ats_lua_conf':
        content => "#!/usr/bin/lua\ndofile('/etc/trafficserver/lua/${default_lua_script}.lua.conf')\nassert(lua_hostname)\nprint('OK')\n",
        require => File["/etc/trafficserver/lua/${default_lua_script}.lua.conf"],
    }

    file { $trusted_ca_path:
        ensure => file,
        owner  => root,
        group  => root,
        mode   => '0444',
        source => $trusted_ca_source,
    }

    if $monitor_enable {
        nrpe::monitor_service { 'default_ats_lua_conf':
            description  => 'Default ATS Lua configuration file',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_default_ats_lua_conf',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/ATS',
        }
    }

    # Options to override the defaults in mediawiki::errorpage_content
    $errorpage = {
        # An explanation for these (and more) fields is available here:
        # https://docs.trafficserver.apache.org/en/latest/admin-guide/logging/formatting.en.html
        # Rendered example:
        # Request from 93.184.216.34 via cp1071.eqiad.wmnet, ATS/8.0.3
        # Error: 502, connect failed at 2019-04-04 12:22:08 GMT
        footer      => "<p>If you report this error to the Wikimedia System Administrators, please include the details below.</p><p class='text-muted'><code>Request from %<{X-Client-IP}cqh> via ${::fqdn}, %<{Server}psh><br>Error: %<pssc>, %<prrp> at %<cqtd> %<cqtt> GMT</code></p>",
    }

    $default_instance = true
    $instance_name = 'backend'
    $conftool_service = 'ats-be'
    $paths = trafficserver::get_paths($default_instance, 'backend')

    trafficserver::instance { $instance_name:
        paths                   => $paths,
        conftool_service        => $conftool_service,
        default_instance        => $default_instance,
        http_port               => $http_port,
        network_settings        => $network_settings,
        http_settings           => $http_settings,
        h2_settings             => $h2_settings,
        outbound_tls_settings   => $outbound_tls_settings,
        enable_xdebug           => $enable_xdebug,
        enable_compress         => $enable_compress,
        origin_coalescing       => $origin_coalescing,
        global_lua_script       => $global_lua_script,
        max_lua_states          => $max_lua_states,
        storage                 => $storage,
        ram_cache_size          => $ram_cache_size,
        mapping_rules           => $mapping_rules,
        guaranteed_max_lifetime => 86400, # 24 hours
        caching_rules           => profile::trafficserver_caching_rules($req_handling, $alternate_domains, $mapping_rules),
        negative_caching        => $negative_caching,
        log_formats             => $log_formats,
        log_filters             => $log_filters,
        logs                    => $logs,
        error_page              => mediawiki::errorpage_content($errorpage),
        systemd_hardening       => $systemd_hardening,
        cache_volumes           => $cache_volumes,
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

    trafficserver::lua_script { 'multi-dc':
        source    => 'puppet:///modules/profile/trafficserver/multi-dc.lua',
        unit_test => 'puppet:///modules/profile/trafficserver/multi-dc_test.lua',
        config    => 'puppet:///modules/profile/trafficserver/multi-dc.lua.conf',
    }

    trafficserver::lua_script { 'gateway-check':
        source    => 'puppet:///modules/profile/trafficserver/gateway-check.lua',
        unit_test => 'puppet:///modules/profile/trafficserver/gateway-check_test.lua',
        config    => 'puppet:///modules/profile/trafficserver/gateway-check.lua.conf',
    }

    if $monitor_enable {
        # Monitoring
        profile::trafficserver::monitoring { "trafficserver_${instance_name}_monitoring":
            paths                    => $paths,
            port                     => $http_port,
            prometheus_exporter_port => $prometheus_exporter_port,
            default_instance         => true,
            instance_name            => $instance_name,
            user                     => $user,
            network_settings         => $network_settings,
        }

        profile::trafficserver::logs { "trafficserver_${instance_name}_logs":
            instance_name    => $instance_name,
            user             => $user,
            logs             => $logs,
            paths            => $paths,
            conftool_service => $conftool_service,
        }

        profile::trafficserver::atsmtail { "trafficserver_${instance_name}_atsmtail":
            instance_name  => $instance_name,
            atsmtail_progs => $atsmtail_backend_progs,
            atsmtail_port  => $atsmtail_backend_port,
            wanted_by      => 'fifo-log-demux@notpurge.service',
            mtail_args     => $mtail_args,
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

    }

    # Make sure the default varnish.service is never started
    exec { 'mask_default_varnish':
        command => '/bin/systemctl mask varnish.service',
        creates => '/etc/systemd/system/varnish.service',
    }
}
