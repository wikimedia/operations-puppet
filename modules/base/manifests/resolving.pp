class base::resolving {
    if ! $::nameservers {
        error("Variable ${::nameservers} is not defined!")
    }
    else {
        if $::realm != 'labs' {
            file { '/etc/resolv.conf':
                owner   => 'oot'
                group   => 'root'
                mode    => '0444',
                content => template('base/resolv.conf.erb'),
            }
        }
    }
}
