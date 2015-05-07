

define tc::rule(
    $rule,
    $iface,
    $action = 'add',
    $type   = 'qdisc',
    $prio   = 10,
) {

    file { "/etc/tc/${iface}.d/${prio}_${name}":
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('tc/rule.erb'),
        require => File["/etc/tc/${iface}.d"],
        notify  => Service['tc'],
    }

}

