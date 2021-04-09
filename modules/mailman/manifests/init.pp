class mailman (
    Stdlib::Fqdn $lists_servername,
    Stdlib::Ensure::Service $mailman_service_ensure = 'running',
    Optional[String] $acme_chief_cert = undef,
){

    class { '::mailman::listserve':
        mailman_service_ensure => $mailman_service_ensure,
    }

    class { '::mailman::webui':
        lists_servername => $lists_servername,
        acme_chief_cert  => $acme_chief_cert,
    }

    include mailman::scripts
}
