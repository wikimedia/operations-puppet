# Monitoing checks that live in icinga and page people
class icinga::monitor::ores {

    @monitoring::host { 'ores.wmflabs.org':
        host_fqdn => 'ores.wmflabs.org',
    }

    monitoring::service { 'ores_main_page':
        description    => 'ORES home page',
        check_command  => 'check_http',
        host           => 'ores.wmflabs.org',
        contact_group  => 'team-ores',
    }

}
