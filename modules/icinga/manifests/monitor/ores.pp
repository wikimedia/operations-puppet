# monitoring of https://meta.wikimedia.org/wiki/ORES
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

    # T121656, T122830
    monitoring::service { 'ores_worker':
        description    => 'ORES worker',
        check_command  => 'check_ores_workers',
        host           => 'ores.wmflabs.org',
        contact_group  => 'team-ores',
    }
}
