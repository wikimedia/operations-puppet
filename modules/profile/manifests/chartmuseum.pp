# == Class: profile::chartmuseum
#
# This class sets up a ChartMuseum instance with swift storage back-end.
#
# Envoy will be run as tls-terminator, so ChartMuseum may listen on localhost
# only.
#
# === Parameters
# [*hostname*] The hostname to use in Host header for monitoring.
#
# [*swift_backend*] Optional configuration of a Swift storage backend (URL,
#                   continer name, username and password). If this parameter is
#                   not set, local storage in "/var/lib/chartmuseum" is used.
#
# [*basic_auth*] Optional username and password to enable HTTP basic auth.
#
class profile::chartmuseum(
    Stdlib::Fqdn                        $hostname                = lookup('profile::chartmuseum::hostname'),
    Optional[ChartMuseum::SwiftBackend] $swift_backend           = lookup('profile::chartmuseum::swift_backend'),
    Optional[ChartMuseum::BasicAuth]    $basic_auth              = lookup('profile::chartmuseum::basic_auth'),
){
    require ::profile::tlsproxy::envoy # TLS termination

    $listen_host = 'localhost'
    $listen_port = 8080
    $repository_depth = 1
    $disable_delete = true
    $disable_force_overwrite = true
    $allow_anonymous_get = true
    $debug = false

    class { '::chartmuseum':
        listen_host             => $listen_host,
        listen_port             => $listen_port,
        repository_depth        => $repository_depth,
        disable_delete          => $disable_delete,
        disable_force_overwrite => $disable_force_overwrite,
        allow_anonymous_get     => $allow_anonymous_get,
        swift_backend           => $swift_backend,
        basic_auth              => $basic_auth,
        debug                   => $debug,
    }

    # Monitoring
    $monitoring_notes_url = 'https://wikitech.wikimedia.org/wiki/ChartMuseum'
    nrpe::monitor_systemd_unit_state{ 'chartmuseum.service':
        ensure      => present,
        description => 'Check that ChartMuseum is running',
        retries     => 2,
        notes_url   => $monitoring_notes_url,
    }

    monitoring::service { 'check_chartmuseum_http':
        description   => 'ChartMuseum HTTP',
        check_command => "check_https_url_for_string!${hostname}!/health!true",
        notes_url     => $monitoring_notes_url,
    }
}
