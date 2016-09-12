class dataset::common {
    package { 'rsync':
        ensure => present,
    }

    include vm::higher_min_free_kbytes

    file { '/etc/modprobe.d/nfs-lockd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "options lockd nlm_udpport=33679 nlm_tcpport=37710"
    }
}
