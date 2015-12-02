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
