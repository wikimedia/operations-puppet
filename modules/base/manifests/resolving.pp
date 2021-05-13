class base::resolving (
    Array[Stdlib::IP::Address] $nameservers,
    Array[Stdlib::Fqdn]        $domain_search              = [$facts['domain']],
    Array[Stdlib::Fqdn]        $labs_additional_domains    = [],
    String                     $legacy_cloud_search_domain = '',
    Integer[1,30]              $timeout                    = 1,
    Integer[1,5]               $ndots                      = 1,
    Integer[1,5]               $attempts                   = 3,
){
    if $::realm == 'labs' {
        $disable_resolvconf  = true
        $disable_dhcpupdates = true
        $_domain_search      = $legacy_cloud_search_domain.empty ? {
            true    => $domain_search,
            default => $domain_search + ["${::labsproject}.${legacy_cloud_search_domain}", $legacy_cloud_search_domain],
        }
    } else {
        $disable_resolvconf  = false
        $disable_dhcpupdates = false
        $_domain_search      = $domain_search
    }
    if $disable_resolvconf {
        # Thanks to dhcp, resolvconf is constantly messing with our resolv.conf.  Disable it.
        file { '/sbin/resolvconf':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/base/resolv/resolvconf.dummy',
        }
    }
    if $disable_dhcpupdates {
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

    }

    file { '/etc/resolv.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('base/resolv.conf.erb'),
    }
}
