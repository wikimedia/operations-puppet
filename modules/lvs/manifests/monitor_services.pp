# Class lvs::monitor_services
#
# Monitor services using service_checker

class lvs::monitor_services(
    String $contacts                = 'admins,team-services',
    Boolean $critical               = false,
    Array[String] $main_datacenters = [],
    Array[String] $all_datacenters  = [],
) {
    $main_datacenters.each |$dc| {
        monitoring::service {
            default:
                critical      => $critical,
                contact_group => $contacts,
                group         => 'lvs',
                ;
            "check_mobileapps_cluster_${dc}":
                host          => "mobileapps.svc.${dc}.wmnet",
                description   => "Mobileapps LVS ${dc}",
                check_command => "check_wmf_service!http://mobileapps.svc.${dc}.wmnet:8888!15",
                contact_group => 'mobileapps',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Mobileapps_(service)',
                ;
            "check_graphoid_cluster_${dc}":
                host          => "graphoid.svc.${dc}.wmnet",
                description   => "Graphoid LVS ${dc}",
                check_command => "check_wmf_service!http://graphoid.svc.${dc}.wmnet:19000!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Graphoid',
                ;
            "check_citoid_cluster_${dc}":
                host          => "citoid.svc.${dc}.wmnet",
                description   => "Citoid LVS ${dc}",
                check_command => "check_wmf_service!http://citoid.svc.${dc}.wmnet:1970!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Citoid',
                ;
            "check_restbase_cluster_${dc}":
                host          => "restbase.svc.${dc}.wmnet",
                description   => "Restbase LVS ${dc}",
                check_command => "check_wmf_service!http://restbase.svc.${dc}.wmnet:7231/en.wikipedia.org/v1!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
                ;
            "check_restrouter_cluster_${dc}":
                host          => "restrouter.svc.${dc}.wmnet",
                description   => "Restrouter LVS ${dc}",
                check_command => "check_wmf_service!http://restrouter.svc.${dc}.wmnet:7231/en.wikipedia.org/v1!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
                ;
            "check_mathoid_cluster_${dc}":
                host          => "mathoid.svc.${dc}.wmnet",
                description   => "Mathoid LVS ${dc}",
                check_command => "check_wmf_service!http://mathoid.svc.${dc}.wmnet:10042!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Mathoid',
                ;
            "check_cxserver_cluster_${dc}":
                host          => "cxserver.svc.${dc}.wmnet",
                description   => "Cxserver LVS ${dc}",
                check_command => "check_wmf_service!http://cxserver.svc.${dc}.wmnet:8080!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/CX',
                ;
            "check_kartotherian_cluster_${dc}":
                host          => "kartotherian.svc.${dc}.wmnet",
                description   => "Kartotherian LVS ${dc}",
                check_command => "check_wmf_service!http://kartotherian.svc.${dc}.wmnet:6533!15",
                contact_group => 'admins,team-interactive',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps#Kartotherian',
                critical      => true,
                ;
            "check_eventgate_analytics_cluster_${dc}":
                host          => "eventgate-analytics.svc.${dc}.wmnet",
                description   => "eventgate-analytics LVS ${dc}",
                check_command => "check_wmf_service!http://eventgate-analytics.svc.${dc}.wmnet:31192!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Event*#EventGate_(repository)',
                ;
            "check_eventgate_main_cluster_${dc}":
                host          => "eventgate-main.svc.${dc}.wmnet",
                description   => "eventgate-main LVS ${dc}",
                check_command => "check_wmf_service!http://eventgate-main.svc.${dc}.wmnet:32192!15",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Event*#EventGate_(repository)',
                ;
            "check_docker_registry_cluster_${dc}":
                host          => "docker-registry.svc.${dc}.wmnet",
                description   => "docker-registry LVS ${dc}",
                check_command => "check_https_url!docker-registry.svc.${dc}.wmnet!/v2/",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Docker-registry-runbook',
                ;
            "check_sessionstore_${dc}":
                host          => "sessionstore.svc.${dc}.wmnet",
                description   => "Sessionstore ${dc}",
                check_command => "check_wmf_service_url!https://sessionstore.svc.${dc}.wmnet:8081!15!/openapi",
                notes_url     => 'https://www.mediawiki.org/wiki/Kask',
                ;
            "check_termbox_${dc}":
                host          => "termbox.svc.${dc}.wmnet",
                description   => "termbox ${dc}",
                check_command => "check_wmf_service!http://termbox.svc.${dc}.wmnet:3030!15!",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/WMDE/Wikidata/SSR_Service',
                ;
            "check_wikifeeds_${dc}":
                host          => "wikifeeds.svc.${dc}.wmnet",
                description   => "wikifeeds ${dc}",
                check_command => "check_wmf_service!http://wikifeeds.svc.${dc}.wmnet:8889!15!",
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikifeeds',
                ;
            "check_echostore_${dc}":
                host          => "echostore.svc.${dc}.wmnet",
                description   => "Echotore ${dc}",
                check_command => "check_wmf_service_url!https://echostore.svc.${dc}.wmnet:8082!15!/openapi",
                notes_url     => 'https://www.mediawiki.org/wiki/Kask',
                ;

        }
    }


    # External monitoring for restbase and kartotherian, at the TLS terminators
    $all_datacenters.each |$dc| {
        monitoring::service {
            default:
                contact_group => $contacts,
                group         => 'lvs',
                critical      => $critical,
                ;
            "check_maps_${dc}":
                host          => "upload-lb.${dc}.wikimedia.org",
                description   => "Maps edge ${dc}",
                check_command => 'check_wmf_service!https://maps.wikimedia.org!15',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
                ;
            "check_restbase_${dc}":
                host          => "text-lb.${dc}.wikimedia.org",
                description   => "Restbase edge ${dc}",
                check_command => 'check_wmf_service!https://en.wikipedia.org/api/rest_v1!15',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
        }
    }

}
