# Class lvs::monitor_services
#
# Monitor services using service_checker

class lvs::monitor_services($contacts = 'admins,team-services', $critical = false) {

    Monitoring::Service {
        critical      => $critical,
        contact_group => $contacts,
    }

    # Mobileapps
    monitoring::service { 'check_mobileapps_cluster_eqiad':
        host          => 'mobileapps.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Mobileapps LVS eqiad',
        check_command => 'check_wmf_service!http://mobileapps.svc.eqiad.wmnet:8888!15',
        contact_group => 'admins,mobileapps',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mobileapps_(service)',
    }

    monitoring::service { 'check_mobileapps_cluster_codfw':
        host          => 'mobileapps.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Mobileapps LVS codfw',
        check_command => 'check_wmf_service!http://mobileapps.svc.codfw.wmnet:8888!15',
        contact_group => 'admins,mobileapps',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mobileapps_(service)',
    }

    # Graphoid
    monitoring::service { 'check_graphoid_cluster_eqiad':
        host          => 'graphoid.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Graphoid LVS eqiad',
        check_command => 'check_wmf_service!http://graphoid.svc.eqiad.wmnet:19000!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Graphoid',
    }

    monitoring::service { 'check_graphoid_cluster_codfw':
        host          => 'graphoid.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Graphoid LVS codfw',
        check_command => 'check_wmf_service!http://graphoid.svc.codfw.wmnet:19000!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Graphoid',
    }

    # Citoid
    monitoring::service { 'check_citoid_cluster_eqiad':
        host          => 'citoid.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Citoid LVS eqiad',
        check_command => 'check_wmf_service!http://citoid.svc.eqiad.wmnet:1970!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Citoid',
    }

    monitoring::service { 'check_citoid_cluster_codfw':
        host          => 'citoid.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Citoid LVS codfw',
        check_command => 'check_wmf_service!http://citoid.svc.codfw.wmnet:1970!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Citoid',
    }


    # Restbase
    monitoring::service { 'check_restbase_cluster_eqiad':
        host          => 'restbase.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Restbase LVS eqiad',
        check_command => 'check_wmf_service!http://restbase.svc.eqiad.wmnet:7231/en.wikipedia.org/v1!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }

    monitoring::service { 'check_restbase_cluster_codfw':
        host          => 'restbase.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Restbase LVS codfw',
        check_command => 'check_wmf_service!http://restbase.svc.codfw.wmnet:7231/en.wikipedia.org/v1!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }


    # Mathoid
    monitoring::service { 'check_mathoid_cluster_eqiad':
        host          => 'mathoid.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Mathoid LVS eqiad',
        check_command => 'check_wmf_service!http://mathoid.svc.eqiad.wmnet:10042!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mathoid',
    }

    monitoring::service { 'check_mathoid_cluster_codfw':
        host          => 'mathoid.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Mathoid LVS codfw',
        check_command => 'check_wmf_service!http://mathoid.svc.codfw.wmnet:10042!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Mathoid',
    }

    # Cxserver
    monitoring::service { 'check_cxserver_cluster_eqiad':
        host          => 'cxserver.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Cxserver LVS eqiad',
        check_command => 'check_wmf_service!http://cxserver.svc.eqiad.wmnet:8080!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/CX',
    }

    monitoring::service { 'check_cxserver_cluster_codfw':
        host          => 'cxserver.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Cxserver LVS codfw',
        check_command => 'check_wmf_service!http://cxserver.svc.codfw.wmnet:8080!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/CX'
    }

    # Kartotherian
    monitoring::service { 'check_kartotherian_cluster_eqiad':
        host          => 'kartotherian.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Kartotherian LVS eqiad',
        check_command => 'check_wmf_service!http://kartotherian.svc.eqiad.wmnet:6533!15',
        contact_group => 'admins,team-interactive',
        critical      => true,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps#Kartotherian',
    }

    monitoring::service { 'check_kartotherian_cluster_codfw':
        host          => 'kartotherian.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Kartotherian LVS codfw',
        check_command => 'check_wmf_service!http://kartotherian.svc.codfw.wmnet:6533!15',
        contact_group => 'admins,team-interactive',
        critical      => true,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps#Kartotherian',
    }

    # eventgate-analytics
    monitoring::service { 'check_eventgate_analytics_cluster_eqiad':
        host          => 'eventgate-analytics.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'eventgate-analytics LVS eqiad',
        check_command => 'check_wmf_service!http://eventgate-analytics.svc.eqiad.wmnet:31192!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Event*#EventGate_(repository)',
    }

    monitoring::service { 'check_eventgate_analytics_cluster_codfw':
        host          => 'eventgate-analytics.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'eventgate-analytics LVS codfw',
        check_command => 'check_wmf_service!http://eventgate-analytics.svc.codfw.wmnet:31192!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Event*#EventGate_(repository)',
    }

    # docker-registry
    monitoring::service { 'check_docker_registry_cluster_eqiad':
        host          => 'docker-registry.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'docker-registry LVS eqiad',
        check_command => 'check_https_url_for_string!docker-registry.svc.eqiad.wmnet!/v2/!\'\\\\{\\\\}\'',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Docker-registry-runbook',
    }

    monitoring::service { 'check_docker_registry_cluster_codfw':
        host          => 'docker-registry.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'docker-registry LVS codfw',
        check_command => 'check_https_url_for_string!docker-registry.svc.codfw.wmnet!/v2/!\'\\\\{\\\\}\'',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Docker-registry-runbook',
    }

    # External monitoring for restbase and kartotherian, at the TLS terminators

    monitoring::service { 'check_maps_eqiad':
        host          => 'upload-lb.eqiad.wikimedia.org',
        group         => 'lvs',
        description   => 'Maps edge eqiad',
        check_command => 'check_wmf_service!https://maps.wikimedia.org!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
    }

    monitoring::service { 'check_restbase_eqiad':
        host          => 'text-lb.eqiad.wikimedia.org',
        group         => 'lvs',
        description   => 'Restbase edge eqiad',
        check_command => 'check_wmf_service!https://en.wikipedia.org/api/rest_v1!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }

    monitoring::service { 'check_maps_codfw':
        host          => 'upload-lb.codfw.wikimedia.org',
        group         => 'lvs',
        description   => 'Maps edge codfw',
        check_command => 'check_wmf_service!https://maps.wikimedia.org!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
    }

    monitoring::service { 'check_restbase_codfw':
        host          => 'text-lb.codfw.wikimedia.org',
        group         => 'lvs',
        description   => 'Restbase edge codfw',
        check_command => 'check_wmf_service!https://en.wikipedia.org/api/rest_v1!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }

    monitoring::service { 'check_maps_esams':
        host          => 'upload-lb.esams.wikimedia.org',
        group         => 'lvs',
        description   => 'Maps edge esams',
        check_command => 'check_wmf_service!https://maps.wikimedia.org!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
    }

    monitoring::service { 'check_restbase_esams':
        host          => 'text-lb.esams.wikimedia.org',
        group         => 'lvs',
        description   => 'Restbase edge esams',
        check_command => 'check_wmf_service!https://en.wikipedia.org/api/rest_v1!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }

    monitoring::service { 'check_maps_ulsfo':
        host          => 'upload-lb.ulsfo.wikimedia.org',
        group         => 'lvs',
        description   => 'Maps edge ulsfo',
        check_command => 'check_wmf_service!https://maps.wikimedia.org!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
    }

    monitoring::service { 'check_restbase_ulsfo':
        host          => 'text-lb.ulsfo.wikimedia.org',
        group         => 'lvs',
        description   => 'Restbase edge ulsfo',
        check_command => 'check_wmf_service!https://en.wikipedia.org/api/rest_v1!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }

    monitoring::service { 'check_maps_eqsin':
        host          => 'upload-lb.eqsin.wikimedia.org',
        group         => 'lvs',
        description   => 'Maps edge eqsin',
        check_command => 'check_wmf_service!https://maps.wikimedia.org!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
    }

    monitoring::service { 'check_restbase_eqsin':
        host          => 'text-lb.eqsin.wikimedia.org',
        group         => 'lvs',
        description   => 'Restbase edge eqsin',
        check_command => 'check_wmf_service!https://en.wikipedia.org/api/rest_v1!15',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }

}
