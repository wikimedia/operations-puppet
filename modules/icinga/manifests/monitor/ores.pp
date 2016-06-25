# monitoring of https://meta.wikimedia.org/wiki/ORES
class icinga::monitor::ores {

    @monitoring::host { 'ores.wmflabs.org':
        host_fqdn => 'ores.wmflabs.org',
    }

    @monitoring::host { 'ores.wikimedia.org':
        host_fqdn => 'ores.wikimedia.org',
    }

    monitoring::service { 'ores_main_page':
        description   => 'ORES home page',
        check_command => 'check_http',
        host          => 'ores.wmflabs.org',
        contact_group => 'team-ores',
    }

    # T121656
    monitoring::service { 'ores_worker_labs':
        description   => 'ORES worker labs',
        check_command => 'check_ores_workers!oresweb',
        host          => 'ores.wmflabs.org',
        contact_group => 'team-ores',
    }

    monitoring::service { 'ores_worker_production':
        description   => 'ORES worker production',
        check_command => 'check_ores_workers!ores.wikimedia.org',
        host          => 'ores.wikimedia.org',
        contact_group => 'team-ores',
    }

    # T122830
    file { '/usr/local/lib/nagios/plugins/check_ores_workers':
        source => 'puppet:///modules/nagios_common/check_commands/check_ores_workers',
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0550',
    }
}
