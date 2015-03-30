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

            file { '/etc/resolvconf/resolv.conf.d/base':
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('base/resolv.conf.base.labs.erb'),
            }

            exec { 'resolvconf':
                subscribe   => File['/etc/resolvconf/resolv.conf.d/base',
                                    '/etc/resolvconf/resolv.conf.d/tail',
                                    '/etc/resolv.conf'],
                command     => '/sbin/resolvconf -u && /sbin/resolvconf -u',
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
