
define tc::ruleset(
    $iface = $name,
    $rules
) {

    file { "/etc/tc/${name}.ruleset":
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('tc/ruleset.erb'),
        notify  => Service['tc'],
        require => Class['tc'],
    }

}

