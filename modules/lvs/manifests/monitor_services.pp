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
    }

    monitoring::service { 'check_mobileapps_cluster_codfw':
        host          => 'mobileapps.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Mobileapps LVS eqiad',
        check_command => 'check_wmf_service!http://mobileapps.svc.codfw.wmnet:8888!15',
    }

    # Graphoid
    monitoring::service { 'check_graphoid_cluster_eqiad':
        host          => 'graphoid.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Graphoid LVS eqiad',
        check_command => 'check_wmf_service!http://graphoid.svc.eqiad.wmnet:19000!15',
    }

    monitoring::service { 'check_graphoid_cluster_codfw':
        host          => 'graphoid.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Graphoid LVS eqiad',
        check_command => 'check_wmf_service!http://graphoid.svc.codfw.wmnet:19000!15',
    }

    # Citoid
    monitoring::service { 'check_citoid_cluster_eqiad':
        host          => 'citoid.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Citoid LVS eqiad',
        check_command => 'check_wmf_service!http://citoid.svc.eqiad.wmnet:1970!15',
    }

    monitoring::service { 'check_citoid_cluster_codfw':
        host          => 'citoid.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Citoid LVS eqiad',
        check_command => 'check_wmf_service!http://citoid.svc.codfw.wmnet:1970!15',
    }


    # Restbase
    monitoring::service { 'check_restbase_cluster_eqiad':
        host          => 'restbase.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Restbase LVS eqiad',
        check_command => 'check_wmf_service!http://restbase.svc.eqiad.wmnet:7231/en.wikipedia.org/v1!15',
    }

    monitoring::service { 'check_restbase_cluster_codfw':
        host          => 'restbase.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Restbase LVS eqiad',
        check_command => 'check_wmf_service!http://restbase.svc.codfw.wmnet:7231/en.wikipedia.org/v1!15',
    }


    # Matoid
    monitoring::service { 'check_mathoid_cluster_eqiad':
        host          => 'mathoid.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Mathoid LVS eqiad',
        check_command => 'check_wmf_service!http://mathoid.svc.eqiad.wmnet:10042!15',
    }

    monitoring::service { 'check_mathoid_cluster_codfw':
        host          => 'mathoid.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Mathoid LVS eqiad',
        check_command => 'check_wmf_service!http://mathoid.svc.codfw.wmnet:10042!15',
    }

    # Cxserver
    monitoring::service { 'check_cxserver_cluster_eqiad':
        host          => 'cxserver.svc.eqiad.wmnet',
        group         => 'lvs',
        description   => 'Cxserver LVS eqiad',
        check_command => 'check_wmf_service!http://cxserver.svc.eqiad.wmnet:8080!15',
    }

    monitoring::service { 'check_cxserver_cluster_codfw':
        host          => 'cxserver.svc.codfw.wmnet',
        group         => 'lvs',
        description   => 'Cxserver LVS eqiad',
        check_command => 'check_wmf_service!http://cxserver.svc.codfw.wmnet:8080!15',
    }

}
