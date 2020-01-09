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
        monitoring::openapi_service {
            default:
                critical      => $critical,
                contact_group => $contacts,
                group         => 'lvs',
                site          => $dc,
                timeout       => 15,
                ;
            "check_mobileapps_cluster_${dc}":
                host          => "mobileapps.svc.${dc}.wmnet",
                description   => "Mobileapps LVS ${dc}",
                target        => "http://mobileapps.svc.${dc}.wmnet:8888",
                contact_group => 'admins,mobileapps',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Mobileapps_(service)',
                ;
            "check_graphoid_cluster_${dc}":
                host        => "graphoid.svc.${dc}.wmnet",
                description => "Graphoid LVS ${dc}",
                target      => "http://graphoid.svc.${dc}.wmnet:19000",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Graphoid',
                ;
            "check_citoid_cluster_${dc}":
                host        => "citoid.svc.${dc}.wmnet",
                description => "Citoid LVS ${dc}",
                target      => "http://citoid.svc.${dc}.wmnet:1970",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Citoid',
                ;
            "check_restbase_cluster_${dc}":
                host        => "restbase.svc.${dc}.wmnet",
                description => "Restbase LVS ${dc}",
                target      => "http://restbase.svc.${dc}.wmnet:7231/en.wikipedia.org/v1",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/RESTBase',
                ;
            "check_restrouter_cluster_${dc}":
                host        => "restrouter.svc.${dc}.wmnet",
                description => "Restrouter LVS ${dc}",
                target      => "http://restrouter.svc.${dc}.wmnet:7231/en.wikipedia.org/v1",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/RESTBase',
                ;
            "check_mathoid_cluster_${dc}":
                host        => "mathoid.svc.${dc}.wmnet",
                description => "Mathoid LVS ${dc}",
                target      => "http://mathoid.svc.${dc}.wmnet:10042",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Mathoid',
                ;
            "check_cxserver_cluster_${dc}":
                host        => "cxserver.svc.${dc}.wmnet",
                description => "Cxserver LVS ${dc}",
                target      => "http://cxserver.svc.${dc}.wmnet:8080",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/CX',
                ;
            "check_kartotherian_cluster_${dc}":
                host          => "kartotherian.svc.${dc}.wmnet",
                description   => "Kartotherian LVS ${dc}",
                target        => "http://kartotherian.svc.${dc}.wmnet:6533",
                contact_group => 'admins,team-interactive',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps#Kartotherian',
                critical      => true,
                ;
            "check_eventgate_analytics_cluster_${dc}":
                host        => "eventgate-analytics.svc.${dc}.wmnet",
                description => "eventgate-analytics LVS ${dc}",
                target      => "https://eventgate-analytics.svc.${dc}.wmnet:4192",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_eventgate_analytics_http_cluster_${dc}":
                host        => "eventgate-analytics.svc.${dc}.wmnet",
                description => "eventgate-analytics-http LVS ${dc}",
                target      => "http://eventgate-analytics.svc.${dc}.wmnet:31192",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_eventgate_main_cluster_${dc}":
                host        => "eventgate-main.svc.${dc}.wmnet",
                description => "eventgate-main LVS ${dc}",
                target      => "https://eventgate-main.svc.${dc}.wmnet:4292",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_eventgate_main_http_cluster_${dc}":
                host        => "eventgate-main.svc.${dc}.wmnet",
                description => "eventgate-main-http LVS ${dc}",
                target      => "http://eventgate-main.svc.${dc}.wmnet:32192",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_eventgate_logging_external_cluster_${dc}":
                host        => "eventgate-logging-external.svc.${dc}.wmnet",
                description => "eventgate-logging-external LVS ${dc}",
                target      => "https://eventgate-logging-external.svc.${dc}.wmnet:4392",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_sessionstore_${dc}":
                host        => "sessionstore.svc.${dc}.wmnet",
                description => "Sessionstore ${dc}",
                target      => "https://sessionstore.svc.${dc}.wmnet:8081",
                params      => {'spec_segment' => ['/openapi']},
                notes_url   => 'https://www.mediawiki.org/wiki/Kask',
                ;
            "check_termbox_${dc}":
                host        => "termbox.svc.${dc}.wmnet",
                description => "termbox ${dc}",
                target      => "http://termbox.svc.${dc}.wmnet:3030",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/WMDE/Wikidata/SSR_Service',
                ;
            "check_wikifeeds_${dc}":
                host        => "wikifeeds.svc.${dc}.wmnet",
                description => "wikifeeds ${dc}",
                target      => "http://wikifeeds.svc.${dc}.wmnet:8889",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Wikifeeds',
                ;
            "check_echostore_${dc}":
                host        => "echostore.svc.${dc}.wmnet",
                description => "Echostore ${dc}",
                target      => "https://echostore.svc.${dc}.wmnet:8082",
                params      => {'spec_segment' => ['/openapi']},
                notes_url   => 'https://www.mediawiki.org/wiki/Kask',
                ;
        }
        monitoring::service { "check_docker_registry_cluster_${dc}":
            host          => "docker-registry.svc.${dc}.wmnet",
            description   => "docker-registry LVS ${dc}",
            check_command => "check_https_url!docker-registry.svc.${dc}.wmnet!/v2/",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Docker-registry-runbook',
            critical      => $critical,
            contact_group => $contacts,
            group         => 'lvs'
        }
    }

    # External monitoring for restbase and kartotherian, at the TLS terminators
    $all_datacenters.each |$dc| {
        monitoring::openapi_service {
            default:
                contact_group => $contacts,
                group         => 'lvs',
                critical      => $critical,
                site          => $dc,
                timeout       => 15
                ;
            "check_maps_${dc}":
                host        => "upload-lb.${dc}.wikimedia.org",
                description => "Maps edge ${dc}",
                target      => 'https://maps.wikimedia.org',
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Maps/RunBook',
                ;
            "check_restbase_${dc}":
                host        => "text-lb.${dc}.wikimedia.org",
                description => "Restbase edge ${dc}",
                target      => 'https://en.wikipedia.org/api/rest_v1',
                notes_url   => 'https://wikitech.wikimedia.org/wiki/RESTBase',
                ;
        }
    }
}
