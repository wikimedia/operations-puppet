# Monitoing checks that live in icinga and page people
class ores::monitoring {
    # Paging checks!
    @monitoring::host { 'ores.wmflabs.org':
        host_fqdn => 'ores.wmflabs.org',
    }

    monitoring::service { 'main_page':
        description    => 'ORES home page',
        check_command  => 'check_http',
        host           => 'ores.wmflabs.org',
        contact_groups => 'team-ores',
    }
}
