# monitoring of https://www.mediawiki.org/wiki/ORES
class icinga::monitor::ores (
    String $icinga_user,
    String $icinga_group,
){

    @monitoring::host { 'ores.wikimedia.org':
        host_fqdn => 'ores.discovery.wmnet',
    }

    monitoring::service { 'ores_worker_production':
        description   => 'ORES worker production',
        check_command => 'check_ores_workers!ores.wikimedia.org',
        host          => 'ores.wikimedia.org',
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
    }

    # T122830
    file { '/usr/local/lib/nagios/plugins/check_ores_workers':
        source => 'puppet:///modules/nagios_common/check_commands/check_ores_workers',
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0550',
    }
}
