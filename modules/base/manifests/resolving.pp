class base::resolving (
    $domain_search = $::domain,
){
    if ! $::nameservers {
        error("Variable ${::nameservers} is not defined!")
    }
    else {
        if $::realm != 'labs' {
            file { '/etc/resolv.conf':
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('base/resolv.conf.erb'),
            }
        }
    }
}
