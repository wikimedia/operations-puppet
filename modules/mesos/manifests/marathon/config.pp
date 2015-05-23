define mesos::marathon::config(
    $value,
) {
    require ::mesos::marathon::master

    file { "/etc/marathon/conf/${title}":
        content => $value,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['marathon'],
    }
}
