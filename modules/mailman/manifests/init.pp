class mailman (
    Stdlib::Fqdn $lists_servername,
    Hash[String, String] $renamed_lists,
    Stdlib::Ensure::Service $mailman_service_ensure = 'running',
    Optional[String] $acme_chief_cert = undef,
    Boolean $enable_mm3 = false,
){

    class { '::mailman::listserve':
        mailman_service_ensure => $mailman_service_ensure,
    }

    class { '::mailman::webui':
        lists_servername => $lists_servername,
        acme_chief_cert  => $acme_chief_cert,
        enable_mm3       => $enable_mm3,
        renamed_lists    => $renamed_lists,
    }

    include mailman::scripts
}
