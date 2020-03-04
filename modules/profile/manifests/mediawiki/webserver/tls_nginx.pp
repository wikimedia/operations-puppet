class profile::mediawiki::webserver::tls_nginx(
    Boolean $has_lvs = lookup('has_lvs'),
    String $ocsp_proxy = lookup('http_proxy', {'default_value' => ''}),
    Integer $tls_keepalive_requests = lookup('profile::mediawiki::webserver::tls_keepalive_requests', {'default_value' => 100}),
) {
    # TLSproxy instance to accept traffic on port 443
    require ::profile::tlsproxy::instance
    # Get the cert name from the service catalog.
    if $has_lvs {
        require ::profile::lvs::realserver
        $services = wmflib::service::fetch()
        $all_certs = $::profile::lvs::realserver::pools.map |$pool, $data| {
            $service = pick($services[$pool], {})
            if $service != undef and $service['monitoring'] {
                pick($service['monitoring']['sites'][$::site]['hostname'], $::fqdn)
            }
            else {
                $::fqdn
            }
        }
        $certs = unique($all_certs)
    }
    else {
        $certs = [$::fqdn]
    }

    tlsproxy::localssl { 'unified':
        server_name        => 'www.wikimedia.org',
        certs              => $certs,
        certs_active       => $certs,
        default_server     => true,
        do_ocsp            => false,
        upstream_ports     => [80],
        access_log         => true,
        ocsp_proxy         => $ocsp_proxy,
        keepalive_requests => $tls_keepalive_requests,
    }

    monitoring::service { 'appserver https':
        description    => 'Nginx local proxy to apache',
        check_command  => 'check_https_url!en.wikipedia.org!/',
        retries        => 2,
        retry_interval => 2,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    }
    ferm::service { 'mediawiki-https':
        proto   => 'tcp',
        notrack => true,
        port    => 'https',
    }
}
