class base::resolving (
    $domain_search = $::domain,
){
    if ! $::nameservers {
        error("Variable ${::nameservers} is not defined!")
    }
    else {
        file { '/etc/resolv.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => $::realm? {
                'labs'  => template('base/resolv.conf.labs.erb'),
                default => template('base/resolv.conf.erb'),
            }
        }
    }
}
