# monitor an ores labs web node
define monitor_ores_labs_web_node ($realserver = $title) {
    $server_parts = split($realserver, ':')
    $server = $server_parts[0]

    monitoring::service { "ores_web_node_labs_${server}" {
        description   => "ORES web node labs ${server}",
        check_command => "check_ores_workers!oresweb/${server}",
        host          => 'ores.wmflabs.org',
        contact_group => 'team-ores',
    }
}
