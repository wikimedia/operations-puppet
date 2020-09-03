class mailman (
    Stdlib::Fqdn $lists_servername,
    Stdlib::Ensure::Service $mailman_service_ensure = 'running',
){

    class { '::mailman::listserve':
        mailman_service_ensure => $mailman_service_ensure,
    }

    class { '::mailman::webui':
        lists_servername => $lists_servername,
    }

    include mailman::scripts
    include mailman::cron
}
