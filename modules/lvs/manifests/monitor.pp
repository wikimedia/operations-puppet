# lvs/monitor.pp

class lvs::monitor {
    include lvs::configuration

    $ip = $lvs::configuration::lvs_service_ips['production']

    # INTERNAL

    lvs::monitor_service_http { "appservers.svc.eqiad.wmnet": ip_address => "10.2.2.1", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
    lvs::monitor_service_http { "hhvm-appservers.svc.eqiad.wmnet": ip_address => "10.2.2.2", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
    lvs::monitor_service_http { "api.svc.eqiad.wmnet": ip_address => "10.2.2.22", check_command => "check_http_lvs!en.wikipedia.org!/w/api.php?action=query&meta=siteinfo" }
    lvs::monitor_service_http { "rendering.svc.eqiad.wmnet": ip_address => "10.2.2.21", check_command => "check_http_lvs!en.wikipedia.org!/wiki/Main_Page" }
    lvs::monitor_service_http { "ms-fe.eqiad.wmnet": ip_address => "10.2.2.27", check_command => "check_http_lvs!ms-fe.eqiad.wmnet!/monitoring/backend" }
    lvs::monitor_service_http { "parsoid.svc.eqiad.wmnet": ip_address => "10.2.2.28", check_command => "check_http_on_port!8000", contact_group => "admins,parsoid" }
    lvs::monitor_service_http { "search.svc.eqiad.wmnet": ip_address => "10.2.2.30", check_command => "check_http_on_port!9200", contact_group => "admins" }
    lvs::monitor_service_http { 'ocg.svc.eqiad.wmnet': ip_address => $ip['ocg']['eqiad'], check_command => "check_http_lvs_on_port!ocg.svc.eqiad.wmnet!8000!/?command=health" }

    lvs::monitor_service_custom { "search-pool1.svc.eqiad.wmnet": ip_address => "10.2.2.11", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
    lvs::monitor_service_custom { "search-pool2.svc.eqiad.wmnet": ip_address => "10.2.2.12", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
    lvs::monitor_service_custom { "search-pool3.svc.eqiad.wmnet": ip_address => "10.2.2.13", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
    lvs::monitor_service_custom { "search-pool4.svc.eqiad.wmnet": ip_address => "10.2.2.14", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
    lvs::monitor_service_custom { "search-pool5.svc.eqiad.wmnet": ip_address => "10.2.2.16", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }
    lvs::monitor_service_custom { "search-prefix.svc.eqiad.wmnet": ip_address => "10.2.2.15", port => 8123, description => "LVS Lucene", check_command => "check_lucene" }

    # EQIAD
    lvs::monitor_service_http_https {
        'text-lb.eqiad.wikimedia.org':
            ip_address => $ip['text']['eqiad']['textlb'],
            uri => 'en.wikipedia.org!/wiki/Main_Page';
        'bits-lb.eqiad.wikimedia.org':
            ip_address => $ip['bits']['eqiad']['bitslb'],
            uri => 'bits.wikimedia.org!/skins/common/images/poweredby_mediawiki_88x31.png';
        'upload-lb.eqiad.wikimedia.org':
            ip_address => $ip['upload']['eqiad']['uploadlb'],
            uri => 'upload.wikimedia.org!/monitoring/backend';
        'mobile-lb.eqiad.wikimedia.org':
            ip_address => $ip['mobile']['eqiad']['mobilelb'],
            uri => 'en.m.wikipedia.org!/wiki/Main_Page';
        'misc-web-lb.eqiad.wikimedia.org':
            ip_address => $ip['misc_web']['eqiad']['misc_web'],
            uri => 'varnishcheck!/';
    }

    lvs::monitor_service6_http_https {
        'text-lb.eqiad.wikimedia.org':
            ip_address => $ip['text']['eqiad']['textlb6'],
            uri => 'en.wikipedia.org!/wiki/Main_Page';
        'bits-lb.eqiad.wikimedia.org':
            ip_address => $ip['bits']['eqiad']['bitslb6'],
            uri => 'bits.wikimedia.org!/skins/common/images/poweredby_mediawiki_88x31.png';
        'upload-lb.eqiad.wikimedia.org':
            ip_address => $ip['upload']['eqiad']['uploadlb6'],
            uri => 'upload.wikimedia.org!/monitoring/backend';
        'mobile-lb.eqiad.wikimedia.org':
            ip_address => $ip['mobile']['eqiad']['mobilelb6'],
            uri => 'en.m.wikipedia.org!/wiki/Main_Page';
        'misc-web-lb.eqiad.wikimedia.org':
            ip_address => $ip['misc_web']['eqiad']['misc_web6'],
            uri => 'varnishcheck!/';
    }

    lvs::monitor_service_http { 'parsoid-lb.eqiad.wikimedia.org':
        ip_address => $ip['parsoidcache']['eqiad']['parsoidlb'],
        check_command => "check_http_on_port!80",
        contact_group => "admins,parsoid"
    }
    # TODO: ipv6

    # ESAMS

    lvs::monitor_service_http_https {
        "text-lb.esams.wikimedia.org":
            ip_address => $ip['text']['esams']['textlb'],
            uri => "en.wikipedia.org!/wiki/Main_Page";
        "bits-lb.esams.wikimedia.org":
            ip_address => $ip['bits']['esams']['bitslb'],
            uri => "bits.wikimedia.org!/skins/common/images/poweredby_mediawiki_88x31.png";
        "upload-lb.esams.wikimedia.org":
            ip_address => $ip['upload']['esams']['uploadlb'],
            uri => "upload.wikimedia.org!/monitoring/backend";
        "mobile-lb.esams.wikimedia.org":
            ip_address => $ip['mobile']['esams']['mobilelb'],
            uri => "en.m.wikipedia.org!/wiki/Main_Page";
    }

    lvs::monitor_service6_http_https {
        "text-lb.esams.wikimedia.org":
            ip_address => $ip['text']['esams']['textlb6'],
            uri => "en.wikipedia.org!/wiki/Main_Page";
        "bits-lb.esams.wikimedia.org":
            ip_address => $ip['bits']['esams']['bitslb6'],
            uri => "bits.wikimedia.org!/skins/common/images/poweredby_mediawiki_88x31.png";
        "upload-lb.esams.wikimedia.org":
            ip_address => $ip['upload']['esams']['uploadlb6'],
            uri => "upload.wikimedia.org!/monitoring/backend";
        "mobile-lb.esams.wikimedia.org":
            ip_address => $ip['mobile']['esams']['mobilelb6'],
            uri => "en.m.wikipedia.org!/wiki/Main_Page";
    }

    # ULSFO

    lvs::monitor_service_http_https {
        "text-lb.ulsfo.wikimedia.org":
            ip_address => $ip['text']['ulsfo']['textlb'],
            uri => "en.wikipedia.org!/wiki/Main_Page";
        "bits-lb.ulsfo.wikimedia.org":
            ip_address => $ip['bits']['ulsfo']['bitslb'],
            uri => "bits.wikimedia.org!/skins/common/images/poweredby_mediawiki_88x31.png";
        "upload-lb.ulsfo.wikimedia.org":
            ip_address => $ip['upload']['ulsfo']['uploadlb'],
            uri => "upload.wikimedia.org!/monitoring/backend";
        "mobile-lb.ulsfo.wikimedia.org":
            ip_address => $ip['mobile']['ulsfo']['mobilelb'],
            uri => "en.m.wikipedia.org!/wiki/Main_Page";
    }

    lvs::monitor_service6_http_https {
        "text-lb.ulsfo.wikimedia.org":
            ip_address => $ip['text']['ulsfo']['textlb6'],
            uri => "en.wikipedia.org!/wiki/Main_Page";
        "bits-lb.ulsfo.wikimedia.org":
            ip_address => $ip['bits']['ulsfo']['bitslb6'],
            uri => "bits.wikimedia.org!/skins/common/images/poweredby_mediawiki_88x31.png";
        "upload-lb.ulsfo.wikimedia.org":
            ip_address => $ip['upload']['ulsfo']['uploadlb6'],
            uri => "upload.wikimedia.org!/monitoring/backend";
        "mobile-lb.ulsfo.wikimedia.org":
            ip_address => $ip['mobile']['ulsfo']['mobilelb6'],
            uri => "en.m.wikipedia.org!/wiki/Main_Page";
    }
}
