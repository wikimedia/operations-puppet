# monitoring of https://meta.wikimedia.org/wiki/PAWS
class icinga::monitor::paws {

    @monitoring::host { 'paws.wmflabs.org':
        host_fqdn => 'paws.wmflabs.org',
    }

    monitoring::service { 'paws_main_page':
        description   => 'PAWS Main page',
        check_command => 'check_http_url!paws.wmflabs.org!/paws/hub/login',
        host          => 'paws.wmflabs.org',
        contact_group => 'team-paws',
    }

}
