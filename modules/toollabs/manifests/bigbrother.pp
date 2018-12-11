class toollabs::bigbrother {
    file { '/usr/local/sbin/bigbrother':
        ensure => absent,
    }

    file { '/etc/init/bigbrother.conf':
        ensure => absent,
    }

    service { 'bigbrother':
        ensure => stopped,
        enable => false,
    }
}
