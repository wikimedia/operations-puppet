# === Class profile::mediawiki::jobrunner_tls
#
# Sets up the TLS proxy to the jobrunner rpc endpoints
#
class profile::mediawiki::jobrunner_tls {
    require ::profile::mediawiki::jobrunner
    require ::profile::tlsproxy::instance

    each({'jobrunner' => 1200, 'videoscaler' => 86400}) |$sitename, $timeout| {
        $certname = "${sitename}.svc.${::site}.wmnet"
        tlsproxy::localssl { $sitename:
            server_name    => $certname,
            server_aliases => ["${sitename}.discovery.wmnet"],
            certs          => [$certname],
            certs_active   => [$certname],
            default_server => ($sitename == 'jobrunner'),
            do_ocsp        => false,
            upstream_ports => [$::profile::mediawiki::jobrunner::local_only_port],
            access_log     => false,
            read_timeout   => $timeout,
        }
        monitoring::service { "${sitename} https":
            description    => "Nginx local proxy to ${sitename}",
            check_command  => "check_https_url!${certname}!/rpc/RunJobs.php",
            retries        => 2,
            retry_interval => 2,
        }
    }

    ::ferm::service { 'mediawiki-jobrunner-https':
        proto   => 'tcp',
        port    => 'https',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }
}
