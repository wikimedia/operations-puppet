class base::resolving (
    $domain_search = $::domain,
){
    if ! $::nameservers {
        error("Variable ${::nameservers} is not defined!")
    }
    else {
        if $::realm == 'labs' {
            # Thanks to dhcp, resolvconf is constantly messing with our resolv.conf.  Disable it.
            file { '/sbin/resolvconf':
                owner   => 'root',
                group   => 'root',
                mode    => '0555',
                source  => 'puppet:///modules/base/resolv/resolvconf.dummy',
            }

            file { '/etc/dhcp/dhclient-enter-hooks.d':
                ensure => 'directory',
            }

            # also stop dhclient from updating resolv.conf.
            file { '/etc/dhcp/dhclient-enter-hooks.d/nodnsupdate':
                owner   => 'root',
                group   => 'root',
                mode    => '0555',
                source  => 'puppet:///modules/base/resolv/nodnsupdate',
                require => File['/etc/dhcp/dhclient-enter-hooks.d'],
            }

            $use_dnsmasq_server = hiera('use_dnsmasq', $::use_dnsmasq)
            # Now, finally, we can just puppetize the damn file
            file { '/etc/resolv.conf':
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('base/resolv.conf.labs.erb'),
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
