# === class profile::trafficserver::backend
#
# Sets up a Traffic Server backend instance with relevant Nagios checks.
#
class profile::trafficserver::backend (
    String $user=hiera('profile::trafficserver::user', 'trafficserver'),
    Wmflib::IpPort $port=hiera('profile::trafficserver::backend::port', 3128),
    Trafficserver::Outbound_TLS_settings $outbound_tls_settings=hiera('profile::trafficserver::backend::outbound_tls_settings'),
    Boolean $enable_xdebug=hiera('profile::trafficserver::backend::enable_xdebug', false),
    Array[TrafficServer::Mapping_rule] $mapping_rules=hiera('profile::trafficserver::backend::mapping_rules', []),
    Array[TrafficServer::Caching_rule] $caching_rules=hiera('profile::trafficserver::backend::caching_rules', []),
    Optional[TrafficServer::Negative_Caching] $negative_caching=hiera('profile::trafficserver::backend::negative_caching', undef),
    String $default_lua_script=hiera('profile::trafficserver::backend::default_lua_script', ''),
    Array[TrafficServer::Storage_element] $storage=hiera('profile::trafficserver::backend::storage_elements', []),
    Array[TrafficServer::Log_format] $log_formats=hiera('profile::trafficserver::backend::log_formats', []),
    Array[TrafficServer::Log_filter] $log_filters=hiera('profile::trafficserver::backend::log_filters', []),
    Array[TrafficServer::Log] $logs=hiera('profile::trafficserver::backend::logs', []),
){
    # Add hostname as a parameter to the default global Lua plugin
    $global_lua_script = $default_lua_script? {
        ''      => '',
        default => "/etc/trafficserver/lua/${default_lua_script}.lua ${::hostname}",
    }

    # ATS is built against libhwloc5 1.11.12 from stretch-backports. Ensure we
    # install that version and not the earlier one from stretch.
    apt::pin { 'libhwloc5':
        pin      => 'release a=stretch-backports',
        package  => 'libhwloc5',
        priority => '1001',
        before   => Package['trafficserver', 'trafficserver-experimental-plugins'],
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
        content     => template('varnish/errorpage.body.html.erb'),
        # An explanation for these (and more) fields is available here:
        # https://docs.trafficserver.apache.org/en/latest/admin-guide/logging/formatting.en.html
        # Rendered example:
        # Request from 93.184.216.34 via cp1071.eqiad.wmnet, ATS/8.0.3
        # Error: 502, connect failed at 2019-04-04 12:22:08 GMT
        footer      => "<p>If you report this error to the Wikimedia System Administrators, please include the details below.</p><p class='text-muted'><code>Request from %<{X-Client-IP}cqh> via ${::fqdn}, %<{Server}psh><br>Error: %<pssc>, %<prrp> at %<cqtd> %<cqtt> GMT</code></p>",
    }

    trafficserver::instance { 'backend':
        default_instance      => true,
        port                  => $port,
        outbound_tls_settings => $outbound_tls_settings,
        enable_xdebug         => $enable_xdebug,
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

    prometheus::trafficserver_exporter { 'trafficserver_exporter':
        endpoint => "http://127.0.0.1:${port}/_stats",
    }

    # Nagios checks
    nrpe::monitor_service { 'traffic_manager':
        description  => 'Ensure traffic_manager is running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/traffic_manager --nosyslog"',
        require      => Class['::trafficserver'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    nrpe::monitor_service { 'traffic_server':
        description  => 'Ensure traffic_server is running',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/traffic_server -M --httpport ${port}'",
        require      => Class['::trafficserver'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    nrpe::monitor_service { 'trafficserver_exporter':
        description  => 'Ensure trafficserver_exporter is running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -a "/usr/bin/python3 /usr/bin/prometheus-trafficserver-exporter"',
        require      => Prometheus::Trafficserver_exporter['trafficserver_exporter'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    monitoring::service { 'traffic_manager_check_http':
        description   => 'Ensure traffic_manager binds on $port and responds to HTTP requests',
        check_command => "check_http_hostheader_port_url!localhost!${port}!/_stats",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    profile::trafficserver::nrpe_monitor_script { 'check_trafficserver_config_status':
        sudo_user => $user,
    }

    # XXX: Avoid `traffic_server -C verify_config` for now
    #profile::trafficserver::nrpe_monitor_script { 'check_trafficserver_verify_config':
    #    sudo_user => $user,
    #}

    $logs.each |TrafficServer::Log $log| {
        if $log['mode'] == 'ascii_pipe' {
            fifo_log_demux::instance { $log['filename']:
                user      => $user,
                fifo      => "/var/log/trafficserver/${log['filename']}.pipe",
                socket    => "/var/run/trafficserver/${log['filename']}.sock",
                wanted_by => 'trafficserver.service',
            }

            profile::trafficserver::nrpe_monitor_script { "check_trafficserver_log_fifo_${log['filename']}":
                sudo_user => 'root',
                checkname => 'check_trafficserver_log_fifo',
                args      => "/var/log/trafficserver/${log['filename']}.pipe",
            }
        }
    }

    # Wrapper script to print ATS logs to stdout using fifo-log-tailer
    file { '/usr/local/bin/atslog':
        ensure => present,
        source => 'puppet:///modules/profile/trafficserver/atslog.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    # Script to depool, restart and repool ATS
    file { '/usr/local/sbin/ats-backend-restart':
        ensure => present,
        source => 'puppet:///modules/profile/trafficserver/ats-backend-restart.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
