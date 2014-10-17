# Resource toollabs::hostgroup::collector
#
#
define toollabs::hostgroup::collector( $hgname = $title )
{

    $hgrpfile  = "/etc/gridengine/local/${hgname}.hosts"

    exec { "make-${hgname}-hosts":
        cwd     => $toollabs::hostgroup::hgstore,
        path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
        command => "(echo group_name @{$hgname};echo hostlist \$(/bin/egrep -l '^${hgname}' *)) >'${hgrpfile}'",
    }

    gridengine::hostgroup { "@${hgname}":
        source  => $hgrpfile,
        require => Exec["make-${hgname}-hosts"],
    }

}

