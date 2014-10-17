# gridengine/master.pp

class gridengine::master
{
    class { 'gridengine':
        gridmaster => $fqdn,
    }

    package { 'gridengine-master':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    $etcdir = '/etc/gridengine/local'

    file { $etcdir:
        ensure  => directory,
        require => Package['gridengine-master'],
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    gridengine::resourcedir { 'queues': }
    gridengine::resourcedir { 'hostgroups': }
    gridengine::resourcedir { 'quotas': }
    gridengine::resourcedir { 'checkpoints': }
    gridengine::resourcedir { 'exechosts':   local => false }
    gridengine::resourcedir { 'submithosts': local => false }

    file { "$etcdir/complex":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    file { "$etcdir/complex/99-default":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        source  => 'puppet:///modules/gridengine/99-default';
    }

    exec { "create-complex-conf":
        cwd     => $etcdir,
        command => '/usr/bin/sort -ufst " " -k 1,1 complex/* >complex.conf && echo /usr/bin/qconf -Mc complex.conf',
        require => File["$etcdir/complex/complex-99-default"],
    }

    file { "$etcdir/config":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => true,
        purge   => true,
    }

    file { "$etcdir/config/99-default":
        ensure  => file,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0664',
        source  => 'puppet:///modules/gridengine/config-99-default';
    }

    exec { "create-config-conf":
        cwd     => $etcdir,
        command => '/usr/bin/sort -ufst " " -k 1,1 config/* >config.conf && echo /usr/bin/qconf -Mconf config.conf',
        require => File["$etcdir/complex/99-default"],
    }

}

# gridengine/resourcedir.pp

define gridengine::resourcedir(
    $etcdir = '/etc/gridengine/local',
    $dir    = $title,
    $local  = true )
{
    file { "$etcdir/$dir":
        ensure  => directory,
        force   => $local,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => $local,
        purge   => $local,
    }

    file { "$etcdir/.tracker/$dir":
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

    exec { "purge-deleted-$dir":
        cwd     => "$etcdir/.tracker/$dir",
        command => "for r in *; do if [ ! -f $etcdir/$dir/\$r ]; then /bin/bash \$r && rm \$f; fi; done",
    }

}

