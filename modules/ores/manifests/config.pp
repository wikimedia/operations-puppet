define ores::config(
    $priority,
    $config,
    $owner='www-data',
    $group='www-data',
    $mode='0660',
) {
    file { "/etc/ores/${priority}-${title}.yaml":
        content => ordered_yaml($config),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }
}
