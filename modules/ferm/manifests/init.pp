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

    # The connection tracking values cannot be set via the standard
    # /etc/sysctl.d hierarchy: The conntrack entries are only available
    # once ferm loads the connection tracking kernel modules. So these
    # values are set via a separate systemd unit which is started after
    # ferm. This doesn't use the /etc/sysctl.d path used by the sysctl
    # class to avoid confusion
    file { '/etc/ferm/conntrack-sysctl.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/ferm/conntrack.conf',
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
