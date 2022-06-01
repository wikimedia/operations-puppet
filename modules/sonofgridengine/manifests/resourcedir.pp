# SPDX-License-Identifier: Apache-2.0
# gridengine/resourcedir.pp

define sonofgridengine::resourcedir(
    $addcmd,
    $modcmd,
    $delcmd,
    $dir = $title,
    $etcdir     = '/var/lib/gridengine/etc',
) {

    $confdir    = "${etcdir}/${dir}"
    $trackerdir = "${etcdir}/tracker/${dir}"

    file { $confdir:
        ensure  => directory,
        force   => false,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

    file { $trackerdir:
        ensure  => directory,
        force   => true,
        owner   => 'sgeadmin',
        group   => 'sgeadmin',
        mode    => '0775',
        recurse => false,
        purge   => false,
    }

    # Disable tracker execution, pending removal
    # exec { "track-${dir}":
    #     command => "${etcdir}/bin/tracker '${confdir}' '${trackerdir}' '${addcmd}' '${modcmd}' '${delcmd}'",
    #     require => File["${etcdir}/bin/tracker", $confdir, $trackerdir],
    # }
}
