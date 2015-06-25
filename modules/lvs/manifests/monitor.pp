# lvs/monitor.pp

class lvs::monitor {
    include lvs::configuration

    $ip = $lvs::configuration::lvs_service_ips['production']

    # WARNING: Temporary, do not lint this, it is going in hiera anyway
    # lint:ignore:80chars
    # INTERNAL EQIAD
    $monitors_internal_eqiad = {
        'appservers.svc.eqiad.wmnet' => { ip_address => '10.2.2.1', check_command => 'check_http_lvs!en.wikipedia.org!/wiki/Main_Page' },
        'api.svc.eqiad.wmnet' => { ip_address => '10.2.2.22', check_command => 'check_http_lvs!en.wikipedia.org!/w/api.php?action=query&meta=siteinfo' },
        'rendering.svc.eqiad.wmnet' => { ip_address => '10.2.2.21', check_command => 'check_http_lvs!en.wikipedia.org!/wiki/Main_Page' },
        'ms-fe.eqiad.wmnet' => { ip_address => '10.2.2.27', check_command => 'check_http_lvs!ms-fe.eqiad.wmnet!/monitoring/backend' },
        'parsoid.svc.eqiad.wmnet' => { ip_address => '10.2.2.28', check_command => 'check_http_on_port!8000', contact_group => 'admins,parsoid' },
        'search.svc.eqiad.wmnet' => { ip_address => '10.2.2.30', check_command => 'check_http_on_port!9200', contact_group => 'admins' },
        'ocg.svc.eqiad.wmnet' => { ip_address => $ip['ocg']['eqiad'], check_command => 'check_http_lvs_on_port!ocg.svc.eqiad.wmnet!8000!/?command=health' },
        'mathoid.svc.eqiad.wmnet' => { ip_address => $ip['mathoid']['eqiad'], check_command => 'check_http_lvs_on_port!mathoid.svc.eqiad.wmnet!10042!/_info' },
        'citoid.svc.eqiad.wmnet' => { ip_address => $ip['citoid']['eqiad'], check_command => 'check_http_lvs_on_port!citoid.svc.eqiad.wmnet!1970!/', contact_group => 'admins,parsoid' },
        'cxserver.svc.eqiad.wmnet' => { ip_address => $ip['cxserver']['eqiad'], check_command => 'check_http_lvs_on_port!citoid.svc.eqiad.wmnet!8080!/' },
        'graphoid.svc.eqiad.wmnet' => { ip_address => $ip['graphoid']['eqiad'], check_command => 'check_http_lvs_on_port!graphoid.svc.eqiad.wmnet!19000!/_info', contact_group => 'admins,parsoid' },
        'restbase.svc.eqiad.wmnet' => { ip_address => $ip['restbase']['eqiad'], check_command => 'check_http_lvs_on_port!restbase.svc.eqiad.wmnet!7231!/' },
        'zotero.svc.eqiad.wmnet' => { ip_address => $ip['zotero']['eqiad'], check_command => 'check_http_zotero_lvs_on_port!zotero.svc.eqiad.wmnet!1969!/export?format=wikipedia' },
    }
    create_resources(lvs::monitor_service_http, $monitors_internal_eqiad)

    # INTERNAL CODFW
    $monitors_internal_codfw = {
        'ms-fe.svc.codfw.wmnet' => { ip_address => '10.2.1.27', check_command => 'check_http_lvs!ms-fe.svc.codfw.wmnet!/monitoring/backend' },
    }
    create_resources(lvs::monitor_service_http, $monitors_internal_codfw)

    # EQIAD
    $monitors_eqiad = {
        'text-lb.eqiad.wikimedia.org' => { ip_address => $ip['text']['eqiad']['textlb'], uri => 'en.wikipedia.org!/wiki/Main_Page' },
        'bits-lb.eqiad.wikimedia.org' => { ip_address => $ip['bits']['eqiad']['bitslb'], uri => 'bits.wikimedia.org!/static-current/resources/assets/poweredby_mediawiki_88x31.png'},
        'upload-lb.eqiad.wikimedia.org' => { ip_address => $ip['upload']['eqiad']['uploadlb'], uri => 'upload.wikimedia.org!/monitoring/backend'},
        'mobile-lb.eqiad.wikimedia.org' => { ip_address => $ip['mobile']['eqiad']['mobilelb'], uri => 'en.m.wikipedia.org!/wiki/Main_Page'},
        'misc-web-lb.eqiad.wikimedia.org' => { ip_address => $ip['misc_web']['eqiad']['misc_web'], uri => 'varnishcheck!/'},
        'parsoid-lb.eqiad.wikimedia.org' => { ip_address => $ip['parsoidcache']['eqiad']['parsoidlb'], check_command => 'check_http_on_port!80', contact_group => 'admins,parsoid' },
    }
    create_resources(lvs::monitor_service_http_https, $monitors_eqiad)
    create_resources(lvs::monitor_service6_http_https, $monitors_eqiad)

    # ESAMS
    $monitors_esams = {
        'text-lb.esams.wikimedia.org' => { ip_address => $ip['text']['esams']['textlb'], uri => 'en.wikipedia.org!/wiki/Main_Page' },
        'bits-lb.esams.wikimedia.org' => { ip_address => $ip['bits']['esams']['bitslb'], uri => 'bits.wikimedia.org!/static-current/resources/assets/poweredby_mediawiki_88x31.png'},
        'upload-lb.esams.wikimedia.org' => { ip_address => $ip['upload']['esams']['uploadlb'], uri => 'upload.wikimedia.org!/monitoring/backend'},
        'mobile-lb.esams.wikimedia.org' => { ip_address => $ip['mobile']['esams']['mobilelb'], uri => 'en.m.wikipedia.org!/wiki/Main_Page'},
    }
    create_resources(lvs::monitor_service_http_https, $monitors_esams)
    create_resources(lvs::monitor_service6_http_https, $monitors_esams)

    # ULSFO
    $monitors_ulsfo = {
        'text-lb.ulsfo.wikimedia.org' => { ip_address => $ip['text']['ulsfo']['textlb'], uri => 'en.wikipedia.org!/wiki/Main_Page' },
        'bits-lb.ulsfo.wikimedia.org' => { ip_address => $ip['bits']['ulsfo']['bitslb'], uri => 'bits.wikimedia.org!/static-current/resources/assets/poweredby_mediawiki_88x31.png'},
        'upload-lb.ulsfo.wikimedia.org' => { ip_address => $ip['upload']['ulsfo']['uploadlb'], uri => 'upload.wikimedia.org!/monitoring/backend'},
        'mobile-lb.ulsfo.wikimedia.org' => { ip_address => $ip['mobile']['ulsfo']['mobilelb'], uri => 'en.m.wikipedia.org!/wiki/Main_Page'},
    }
    create_resources(lvs::monitor_service_http_https, $monitors_ulsfo)
    create_resources(lvs::monitor_service6_http_https, $monitors_ulsfo)
    # lint:endignore
}
