

define tc::interface($iface) {

    file { "/etc/rc/${iface}.d":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        recurse => true,
        purge   => true,
    }

    # Rules are applied additively; insert a 00_flush
    # rule to clean the slate before anything else

    tc::rule('flush':
        iface  => $iface,
        action => 'del',
        rule   => 'root',
        prio   => '00',
    }

}

