# gridengine/master.pp

class gridengine::master {

    include ::gridengine

    package { ['gridengine-master', 'gridengine-client']:
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    # berkleydb utils for doing db recovery and other operations
    package {'db-util':
        ensure => latest,
    }

    $etcdir = '/var/lib/gridengine/etc'

    file { "${etcdir}/tracker":
        ensure => absent,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0775',
    }

    file { "${etcdir}/bin":
        ensure  => absent,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        force   => true,
        recurse => true,
        purge   => true,
    }

    file { "${etcdir}/bin/tracker":
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/gridengine/tracker',
    }

    file { "${etcdir}/bin/collector":
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/gridengine/collector',
    }

    gridengine::resourcedir { 'queues': }
    gridengine::resourcedir { 'hostgroups': }
    gridengine::resourcedir { 'quotas': }
    gridengine::resourcedir { 'checkpoints': }
    gridengine::resourcedir { 'exechosts': }
    gridengine::resourcedir { 'submithosts': }
    gridengine::resourcedir { 'adminhosts': }

    file { "${etcdir}/config":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    # Changes made to global.conf will be applied to the grid only on running
    # `qconf -Mconf global` from /var/lib/gridengine/etc/config/.
    # See https://linux.die.net/man/5/sge_conf for docs
    file { "${etcdir}/config/global":
        ensure => file,
        owner  => 'sgeadmin',
        group  => 'sgeadmin',
        mode   => '0664',
        source => 'puppet:///modules/gridengine/global.conf',
    }

    service { 'gridengine-master':
        ensure    => running,
        enable    => true,
        hasstatus => false,
        pattern   => 'sge_qmaster',
        require   => Package['gridengine-master'],
    }
}
