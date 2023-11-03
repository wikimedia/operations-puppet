# SPDX-License-Identifier: Apache-2.0
# @summary simple class to configure resolv.conf
# @param nameservers a list of nameserveres to configre
# @param domain_search a list of domains to add to the domain search list
# @param timeout the timeout option
# @param attempts the attempts option
# @param ndots the ndots option
# @param disable_resolvconf stop resolvconf from messing with our resolv.conf
# @param disable_dhcpupdates stop dhcpd from messing with our resolv.conf
# @param manage_resolv_conf if false dont try to manage resolv_conf, usefull for docker runs
class resolvconf (
    Array[Stdlib::Host,1] $nameservers,
    Array[Stdlib::Fqdn]   $domain_search       = [$facts['networking']['domain']],
    Integer[1,30]         $timeout             = 1,
    Integer[1,5]          $attempts            = 3,
    Integer[1,15]         $ndots               = 1,
    Boolean               $disable_resolvconf  = false,
    Boolean               $disable_dhcpupdates = false,
    Boolean               $manage_resolv_conf  = true,
) {
    $nameserver_ips = wmflib::hosts2ips($nameservers)
    if $disable_resolvconf {
        file { '/sbin/resolvconf':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/resolvconf/resolvconf.dummy',
        }
    }
    if $disable_dhcpupdates {
        file { '/etc/dhcp/dhclient-enter-hooks.d':
            ensure => 'directory',
        }

        file { '/etc/dhcp/dhclient-enter-hooks.d/nodnsupdate':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/resolvconf/nodnsupdate',
        }
    }

    if $manage_resolv_conf {
        file { '/etc/resolv.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('resolvconf/resolv.conf.erb'),
        }
    }
}
