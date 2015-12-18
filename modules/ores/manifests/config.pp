define ores::config(
    $priority,
    $config,
) {
    require ::ores::base

    file { "${::ores::base::config_path}/config/${priority}-${title}":
        content => ordered_yaml($config),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0660',
    }
}
