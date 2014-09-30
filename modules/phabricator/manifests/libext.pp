define phabricator::libext ($rootdir, $libext_tag, $libext_lock_path, $libname = $title) {

        file { "${rootdir}/libext":
            ensure => 'directory',
        }

        git::install { "phabricator/extensions/${libname}" :
            directory => "${rootdir}/libext/${libname}",
            git_tag   => $libext_tag,
            lock_file => $libext_lock_path,
            notify    => Exec[$libext_lock_path],
            before    => Git::Install['phabricator/phabricator'],
        }

        exec {$libext_lock_path:
            command => "touch ${libext_lock_path}",
            unless  => "test -z ${libext_lock_path} || test -e ${libext_lock_path}",
            path    => '/usr/bin:/bin',
        }
}

