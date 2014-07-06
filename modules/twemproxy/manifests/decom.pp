# == Class: twemproxy::decom
#
# Decommission twemproxy.
#
class twemproxy::decom {
    service { 'twemproxy':
        ensure   => stopped,
        provider => upstart,
        before   => File['/etc/init/twemproxy.conf'],
    }

    file { '/etc/init/twemproxy.conf':
        ensure => absent,
        before => File['/etc/default/twemproxy'],
    }

    file { '/etc/default/twemproxy':
        ensure => absent,
        before => Package['twemproxy'],
    }

    package { 'twemproxy':
        ensure => absent,
    }
}
