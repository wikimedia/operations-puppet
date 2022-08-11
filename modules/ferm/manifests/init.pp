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
        before  => Package['ferm', 'libnet-dns-perl', 'conntrack'],
    }

    ensure_packages(['ferm', 'libnet-dns-perl', 'conntrack'])

    file {'/usr/local/sbin/ferm-status':
        ensure  => file,
        mode    => '0550',
        owner   => 'root',
        group   => 'root',
        content => file('ferm/ferm_status.py')
    }
    service { 'ferm':
        ensure  => 'running',
        status  => '/usr/local/sbin/ferm-status',
        start   => '/bin/systemctl restart ferm',
        require => [
            Package['ferm'],
            File['/usr/local/sbin/ferm-status'],
        ]
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
        mode    => '0551',
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

    # Starting with Bullseye iptables default to the nft backend, but for ferm
    # we need the legacy backend
    if debian::codename::ge('bullseye') {
        alternatives::select { 'iptables':
            path    => '/usr/sbin/iptables-legacy',
        }

        alternatives::select { 'ip6tables':
            path    => '/usr/sbin/ip6tables-legacy',
        }
    }

    # the rules are virtual resources for cases where they are defined in a
    # class but the host doesn't have the ferm class included
    File <| tag == 'ferm' |>
}
