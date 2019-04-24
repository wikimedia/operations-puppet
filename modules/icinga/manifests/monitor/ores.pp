# monitoring of https://www.mediawiki.org/wiki/ORES
class icinga::monitor::ores (
    String $icinga_user,
    String $icinga_group,
){

    monitoring::grafana_alert { 'ores':
        dashboard_uid => 'vAN_bQemz',
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
    }

    # T154175
    monitoring::grafana_alert { 'ores-extension':
        dashboard_uid => '000000263',
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
    }

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
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
    }

    $web_nodes = [ 'ores-web-01', 'ores-web-02' ]

    icinga::monitor::ores_labs_web_node { $web_nodes: }

    # T121656
    monitoring::service { 'ores_worker_labs':
        description   => 'ORES worker labs',
        check_command => 'check_ores_workers!oresweb',
        host          => 'ores.wmflabs.org',
        contact_group => 'team-scoring',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/ORES',
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
