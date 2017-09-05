# === Class profile::mediawiki::jobrunner_tls
#
# Sets up the TLS proxy to the jobrunner rpc endpoints
#
class profile::mediawiki::jobrunner_tls {
    require ::profile::mediawiki::jobrunner

    class { '::tlsproxy::nginx_bootstrap': }

    $certname = "jobrunner.svc.${::site}.wmnet"
    tlsproxy::localssl { 'unified':
        server_name    => $certname,
        certs          => [$certname],
        certs_active   => [$certname],
        default_server => true,
        do_ocsp        => false,
        upstream_ports => [$::profile::mediawiki::jobrunner::local_only_port],
        access_log     => false,
    }

    ::ferm::service { 'mediawiki-jobrunner-https':
        proto   => 'tcp',
        port    => 'https',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

}
