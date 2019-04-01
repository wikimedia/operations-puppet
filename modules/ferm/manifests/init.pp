# ferm is a frontend for iptables
# https://wiki.debian.org/ferm
class ferm {
    # @resolve requires libnet-dns-perl

    file { '/etc/modprobe.d/nf_conntrack.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/firewall/nf_conntrack.conf',
    }

    # The nf_conntrack kernel module is usually auto-loaded during ferm startup.
    # But some additional configuration options for timewait handling are configured
    #   via sysctl settings and if ferm autoloads the kernel module after
    #   systemd-sysctl.service has run, the sysctl settings are not applied.
    # Add the nf_conntrack module via /etc/modules-load.d/ which loads
    #   them before systemd-sysctl.service is executed.
    file { '/etc/modules-load.d/conntrack.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "nf_conntrack\n",
        require => File['/etc/modprobe.d/nf_conntrack.conf'],
    }

    package { ['ferm', 'libnet-dns-perl', 'conntrack']:
        ensure  => present,
        require => File['/etc/modprobe.d/nf_conntrack.conf'],
    }

    service { 'ferm':
        hasstatus => false,
        status    => '/bin/true',
        require   => Package['ferm'],
    }

    file { '/etc/ferm/ferm.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        source  => 'puppet:///modules/ferm/ferm.conf',
        require => Package['ferm'],
        notify  => Service['ferm'],
    }

    file { '/etc/ferm/functions.conf' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        source  => 'puppet:///modules/ferm/functions.conf',
        require => Package['ferm'],
        notify  => Service['ferm'],
    }

    file { '/etc/ferm/conf.d' :
        ensure  => directory,
        owner   => 'root',
        group   => 'adm',
        mode    => '0500',
        recurse => true,
        purge   => true,
        require => Package['ferm'],
        notify  => Service['ferm'],
    }

    file { '/etc/default/ferm' :
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        source  => 'puppet:///modules/ferm/ferm.default',
        require => Package['ferm'],
        notify  => Service['ferm'],
    }

    # the rules are virtual resources for cases where they are defined in a
    # class but the host doesn't have the ferm class included
    File <| tag == 'ferm' |>
}
