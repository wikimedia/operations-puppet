# == Define: phabricator::libext
#
# Installs libphutil library extensions
#

define phabricator::libext ($rootdir, $libext_tag, $libext_lock_path, $libname = $name) {

        git::install { "phabricator/extensions/${libname}" :
            directory => "${rootdir}/libext/${libname}",
            git_tag   => $libext_tag,
            lock_file => $libext_lock_path,
            notify    => Exec[$libext_lock_path],
            before    => Git::Install['phabricator/phabricator'],
        }

        $libname_lock = "${libext_lock_path}_${libname}"
        exec {$libname_lock:
            command => "touch ${libname_lock}",
            unless  => "test -z ${libname_lock} || test -e ${libname_lock}",
            path    => '/usr/bin:/bin',
        }
}

