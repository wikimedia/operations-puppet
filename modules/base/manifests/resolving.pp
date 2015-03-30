class base::resolving (
    $domain_search = $::domain,
){
    if ! $::nameservers {
        error("Variable ${::nameservers} is not defined!")
    }
    else {
        if $::realm == 'labs' {
            file { '/etc/resolv.conf':
                ensure => 'link',
                target => '/run/resolvconf/resolv.conf'
            }

            file { '/etc/resolvconf/resolv.conf.d/tail':
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('base/resolv.conf.tail.labs.erb'),
            }

            file { '/etc/network/interfaces':
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('base/interfaces.labs.erb'),
            }

            exec { 'resolvconf':
                subscribe   => File['/etc/network/interfaces',
                                    '/etc/resolvconf/resolv.conf.d/tail'],
                creates     => '/run/resolvconf/resolv.conf',
                refreshonly => true,
                command     => '/sbin/resolvconf -u',
            }
        } else {
            file { '/etc/resolv.conf':
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('base/resolv.conf.erb'),
            }
        }
    }
}
