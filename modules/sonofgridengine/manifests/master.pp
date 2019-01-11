# sonofgridengine/master.pp

class sonofgridengine::master (
    $etcdir  = '/var/lib/gridengine/etc',
){

    include ::sonofgridengine

    package { ['gridengine-master', 'gridengine-client']:
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    # berkleydb utils for doing db recovery and other operations
    package {'db-util':
        ensure => latest,
    }

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

    file { "${etcdir}/bin/tracker":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/sonofgridengine/tracker',
    }

    file { "${etcdir}/bin/collector":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/sonofgridengine/collector',
    }

    sonofgridengine::resourcedir { 'queues':
        addcmd => '/usr/bin/qconf -Aq',
        modcmd => '/usr/bin/qconf -Mq',
        delcmd => '/usr/bin/qconf -dq',
    }
    sonofgridengine::resourcedir { 'hostgroups':
        addcmd => '/usr/bin/qconf -Ahgrp',
        modcmd => '/usr/bin/qconf -Mhgrp',
        delcmd => '/usr/bin/qconf -dhgrp',
    }
    sonofgridengine::resourcedir { 'quotas':
        addcmd => '/usr/bin/qconf -Arqs',
        modcmd => '/usr/bin/qconf -Mrqs',
        delcmd => '/usr/bin/qconf -drqs',
    }
    sonofgridengine::resourcedir { 'checkpoints':
        addcmd => '/usr/bin/qconf -Ackpt',
        modcmd => '/usr/bin/qconf -Mckpt',
        delcmd => '/usr/bin/qconf -dckpt',
    }
    sonofgridengine::resourcedir { 'exechosts':
        addcmd => '/usr/bin/qconf -Ae',
        modcmd => '/usr/bin/qconf -Me',
        delcmd => '/usr/bin/qconf -de',
    }
    sonofgridengine::resourcedir { 'submithosts':
        addcmd => '/usr/bin/qconf -as',
        modcmd => '/bin/true',
        delcmd => '/usr/bin/qconf -ds',
    }

    sonofgridengine::resourcedir { 'adminhosts':
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

    file {'/usr/local/bin/grid-configurator':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/sonofgridengine/grid_configurator/grid_configurator.py',
    }

    # remove the sysvinit script and links shipped with the package
    file { '/etc/init.d/gridengine-master':
        ensure => absent,
    }

    file { '/etc/rc0.d/K01gridengine-master':
        ensure => absent,
    }

    file { '/etc/rc1.d/K01gridengine-master':
        ensure => absent,
    }

    file { '/etc/rc6.d/K01gridengine-master':
        ensure => absent,
    }

    file { '/etc/rc2.d/S01gridengine-master':
        ensure => absent,
    }

    file { '/etc/rc3.d/S01gridengine-master':
        ensure => absent,
    }

    file { '/etc/rc4.d/S01gridengine-master':
        ensure => absent,
    }

    file { '/etc/rc5.d/S01gridengine-master':
        ensure => absent,
    }

    systemd::unit { 'gridengine-master.service':
        ensure   => present,
        content  => file('sonofgridengine/gridengine-master.service'),
        override => false,
        restart  => true,
        require  => Package['gridengine-master'],
    }
}
