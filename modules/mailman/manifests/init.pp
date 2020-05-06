class mailman (
    String $mailman_service_ensure = 'running'
) {

    class { '::mailman::listserve':
        mailman_service_ensure => $mailman_service_ensure,
    }

    include mailman::webui
    include mailman::scripts
    include mailman::cron
}
