# === Class restbase::monitoring
#
# For now, a rudimentary check for restbase
class restbase::monitoring(
    $monitor_domain = 'en.wikipedia.org',
) {
    require ::restbase

    monitoring::service { 'restbase_http_root':
        description   => 'Restbase root url',
        check_command => "check_http_port_url!${::restbase::port}!/",
        contact_group => 'admins,team-services',
    }

    # Spec checking
    require service::monitoring

    $monitor_url = "http://127.0.0.1:${::restbase::port}/${monitor_domain}/v1"
    nrpe::monitor_service { 'endpoints_restbase':
        description  => 'Restbase endpoints health',
        nrpe_command => "/usr/local/lib/nagios/plugins/service_checker -t 5 127.0.0.1 ${monitor_url}"
    }
}
