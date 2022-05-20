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
                target        => "https://mobileapps.svc.${dc}.wmnet:4102",
                contact_group => 'admins,mobileapps',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Mobileapps_(service)',
                ;
            "check_citoid_cluster_${dc}":
                host        => "citoid.svc.${dc}.wmnet",
                description => "Citoid LVS ${dc}",
                target      => "https://citoid.svc.${dc}.wmnet:4003",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Citoid',
                ;
            "check_restbase_cluster_${dc}":
                host        => "restbase.svc.${dc}.wmnet",
                description => "Restbase LVS ${dc}",
                target      => "https://restbase.svc.${dc}.wmnet:7443/en.wikipedia.org/v1",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/RESTBase',
                ;
            "check_mathoid_cluster_${dc}":
                host        => "mathoid.svc.${dc}.wmnet",
                description => "Mathoid LVS ${dc}",
                target      => "https://mathoid.svc.${dc}.wmnet:4001",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Mathoid',
                ;
            "check_cxserver_cluster_${dc}":
                host        => "cxserver.svc.${dc}.wmnet",
                description => "Cxserver LVS ${dc}",
                target      => "https://cxserver.svc.${dc}.wmnet:4002",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/CX',
                ;
            "check_kartotherian_cluster_${dc}":
                host          => "kartotherian.svc.${dc}.wmnet",
                description   => "Kartotherian LVS ${dc}",
                target        => "http://kartotherian.svc.${dc}.wmnet:6533",
                contact_group => 'admins,team-interactive',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Maps#Kartotherian',
                ;
            "check_eventgate_analytics_cluster_${dc}":
                host        => "eventgate-analytics.svc.${dc}.wmnet",
                description => "eventgate-analytics LVS ${dc}",
                target      => "https://eventgate-analytics.svc.${dc}.wmnet:4592",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_eventgate_main_cluster_${dc}":
                host        => "eventgate-main.svc.${dc}.wmnet",
                description => "eventgate-main LVS ${dc}",
                target      => "https://eventgate-main.svc.${dc}.wmnet:4492",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_eventgate_logging_external_cluster_${dc}":
                host        => "eventgate-logging-external.svc.${dc}.wmnet",
                description => "eventgate-logging-external LVS ${dc}",
                target      => "https://eventgate-logging-external.svc.${dc}.wmnet:4392",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
                ;
            "check_eventgate_analytics_external_cluster_${dc}":
                host        => "eventgate-analytics-external.svc.${dc}.wmnet",
                description => "eventgate-analytics-external LVS ${dc}",
                target      => "https://eventgate-analytics-external.svc.${dc}.wmnet:4692",
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
                target      => "https://termbox.svc.${dc}.wmnet:4004",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/WMDE/Wikidata/SSR_Service',
                ;
            "check_wikifeeds_${dc}":
                host        => "wikifeeds.svc.${dc}.wmnet",
                description => "wikifeeds ${dc}",
                target      => "https://wikifeeds.svc.${dc}.wmnet:4101",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Wikifeeds',
                ;
            "check_echostore_${dc}":
                host        => "echostore.svc.${dc}.wmnet",
                description => "Echostore ${dc}",
                target      => "https://echostore.svc.${dc}.wmnet:8082",
                params      => {'spec_segment' => ['/openapi']},
                notes_url   => 'https://www.mediawiki.org/wiki/Kask',
                ;
            "check_proton_cluster_${dc}":
                host        => "proton.svc.${dc}.wmnet",
                description => "proton LVS ${dc}",
                target      => "https://proton.svc.${dc}.wmnet:4030",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Proton',
                ;
            "check_eventstreams_cluster_${dc}":
                host        => "eventstreams.svc.${dc}.wmnet",
                description => "eventstreams LVS ${dc}",
                target      => "https://eventstreams.svc.${dc}.wmnet:4892",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams',
                ;
            "check_eventstreams_internal_cluster_${dc}":
                host        => "eventstreams-internal.svc.${dc}.wmnet",
                description => "eventstreams-internal LVS ${dc}",
                target      => "https://eventstreams-internal.svc.${dc}.wmnet:4992",
                notes_url   => 'https://wikitech.wikimedia.org/wiki/Event_Platform/Instrumentation_How_To#In_production',
                ;
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
