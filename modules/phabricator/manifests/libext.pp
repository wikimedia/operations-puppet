# == Define: phabricator::libext
#
# Installs libphutil library extensions
#
# === Parameters
#
# [*rootdir*]
#    The path on disk to clone the needed repositories
#
# [*libext_tag*]
#    Git tag to hold repo at
#
# [*libext_lock_path*]
#    Path to local file that provides local settings lock
#
# [*libname*]
#    Case sensitive extension name


define phabricator::libext ($rootdir, $libext_tag, $libext_lock_path, $libname = $name) {

        # Build per extension lock file
        $libname_lock = "${libext_lock_path}_${libname}"

        git::install { "phabricator/extensions/${libname}" :
            directory => "${rootdir}/libext/${libname}",
            git_tag   => $libext_tag,
            lock_file => $libname_lock,
            notify    => Exec[$libname_lock],
            before    => Git::Install['phabricator/phabricator'],
        }

        exec {$libname_lock:
            command => "touch ${libname_lock}",
            unless  => "test -z ${libname_lock} || test -e ${libname_lock}",
            path    => '/usr/bin:/bin',
        }

        file { "${rootdir}/phabricator/webroot/rsrc/libext":
            ensure => 'link',
            target => "${rootdir}/libext/Sprint/rsrc/webroot-static",
        }
}
