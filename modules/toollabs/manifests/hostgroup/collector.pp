# Resource toollabs::hostgroup::collector
#
#
define toollabs::hostgroup::collector( $hgname = $title )
{

    $hgrpfile  = "/etc/gridengine/local/${hgname}.hosts"

    file { $dir:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    exec { "make-${hgname}-hosts":
        cwd     => $toollabs::hostgroup::hgstore,
        command => "(echo group_name @{$hgname};echo hostlist \$(/bin/egrep -l '^${hgname}' *)) >'${hgrpfile}'",
    }

    gridengine::hostgroup { "@${hgname}":
        spirce  => $hgrpfile,
        require => Exec["make-${hgname}-hosts"],
    }

}

