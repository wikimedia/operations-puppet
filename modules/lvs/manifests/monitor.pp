# lvs/monitor.pp

class lvs::monitor {
    include ::lvs::configuration

    $ip = $lvs::configuration::service_ips
    $lvs_services = $lvs::configuration::lvs_services

    # This is a hack. Use a template to get a yaml structure of a ruby hash,
    # then use parseyaml from puppetlabs/stdlib to get a puppet hash back
    $yaml_tmp_var = template('lvs/monitor_lvs.erb')
    $monitors = parseyaml($yaml_tmp_var)
    create_resources(lvs::monitor_service_http_https, $monitors)

    # Experimental load-balancer monitoring for services using service-checker
    include ::lvs::monitor_services
}
