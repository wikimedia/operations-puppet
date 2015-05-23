define mesos::marathon::config(
    $value,
) {
    include ::mesos::marathon::master

    file { "/etc/marathon/conf/${title}":
        content => $value,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['marathon'],
    }
}
