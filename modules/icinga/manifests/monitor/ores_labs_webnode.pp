# monitor an ores labs web node
define ores_labs_web_node () {
    monitoring::service { "ores_web_node_labs_${title}":
        description   => "ORES web node labs ${title}",
        check_command => "check_ores_workers!oresweb/node/${title}",
        host          => 'ores.wmflabs.org',
        contact_group => 'team-ores',
    }
}
