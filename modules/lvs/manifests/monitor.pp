# lvs/monitor.pp

class lvs::monitor {
    include lvs::configuration

    $ip = $lvs::configuration::service_ips
    $lvs_services = $lvs::configuration::lvs_services

    # This is a hack. Use a template to get a yaml structure of a ruby hash,
    # then use parseyaml from puppetlabs/stdlib to get a puppet hash back
    $yaml_tmp_var = template('lvs/monitor_lvs.erb')
    $monitors = parseyaml($yaml_tmp_var)
    create_resources(lvs::monitor_service_http_https, $monitors)

    # Experimental load-balancer monitoring for services using service-checker
    @monitoring::service { 'check_mobileapps_cluster':
        host          => 'mobileapps.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Mobileapps LVS eqiad',
        check_command => 'check_wmf_service!http://mobileapps.svc.eqiad.wmnet:8888!15',
        critical      => false,
        contact_group => 'admins,team-services',
    }

    # Experimental load-balancer monitoring for services using service-checker
    @monitoring::service { 'check_mobileapps_cluster':
        host          => 'mobileapps.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Mobileapps LVS eqiad',
        check_command => 'check_wmf_service!http://mobileapps.svc.codfw.wmnet:8888!15',
        critical      => false,
        contact_group => 'admins,team-services',
    }
}
