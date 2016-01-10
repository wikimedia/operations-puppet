# gridengine/master.pp

class gridengine::master
{
    package { 'gridengine-master':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    service { 'gridengine-master':
        ensure    => running,
        enable    => true,
        hasstatus => false,
        pattern   => 'sge_qmaster',
        require   => Package['gridengine-master'],
    }

    # berkleydb utils for doing db recovery and other operations
    package {'db-util':
        ensure => latest,
    }

    $etcdir = '/var/lib/gridengine/etc'

    file { "${etcdir}/tracker":
        ensure => directory,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0775',
    }

    file { "${etcdir}/bin":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        force   => true,
        recurse => true,
        purge   => true,
    }

    file { "${etcdir}/bin/mergeconf":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/gridengine/mergeconf',
    }

    file { "${etcdir}/bin/tracker":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/gridengine/tracker',
    }

    file { "${etcdir}/bin/collector":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/gridengine/collector',
    }

    gridengine::resourcedir { 'queues':
        addcmd => '/usr/bin/qconf -Aq',
        modcmd => '/usr/bin/qconf -Mq',
        delcmd => '/usr/bin/qconf -dq',
    }
    gridengine::resourcedir { 'hostgroups':
        addcmd => '/usr/bin/qconf -Ahgrp',
        modcmd => '/usr/bin/qconf -Mhgrp',
        delcmd => '/usr/bin/qconf -dhgrp',
    }
    gridengine::resourcedir { 'quotas':
        addcmd => '/usr/bin/qconf -Arqs',
        modcmd => '/usr/bin/qconf -Mrqs',
        delcmd => '/usr/bin/qconf -drqs',
    }
    gridengine::resourcedir { 'checkpoints':
        addcmd => '/usr/bin/qconf -Ackpt',
        modcmd => '/usr/bin/qconf -Mckpt',
        delcmd => '/usr/bin/qconf -dckpt',
    }
    gridengine::resourcedir { 'exechosts':
        addcmd => '/usr/bin/qconf -Ae',
        modcmd => '/usr/bin/qconf -Me',
        delcmd => '/usr/bin/qconf -de',
    }
    gridengine::resourcedir { 'submithosts':
        addcmd => '/usr/bin/qconf -as',
        modcmd => '/bin/true',
        delcmd => '/usr/bin/qconf -ds',
    }

    gridengine::resourcedir { 'adminhosts':
        addcmd => '/usr/bin/qconf -ah',
        modcmd => '/bin/true',
        delcmd => '/usr/bin/qconf -dh',
    }

    file { "${etcdir}/config":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    file { "${etcdir}/config/99-default":
        ensure => file,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0664',
        source => 'puppet:///modules/gridengine/config-99-default',
    }

    exec { 'update-config-conf':
        onlyif  => "${etcdir}/bin/mergeconf ${etcdir}/config.conf ${etcdir}/config/*",
        command => "/bin/echo /usr/bin/qconf -Mconf ${etcdir}/config.conf",
        require => File[ "${etcdir}/bin", "${etcdir}/config/99-default" ],
    }

}
