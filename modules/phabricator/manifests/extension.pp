# == Class: phabricator::extension
#
# === Parameters
#
# [*rootdir*]
#    Phabricator repo directory
#
# Obsolete: Put extensions in phutil libraries under libext/ instead!
#
define phabricator::extension($rootdir='/') {
    file { "${rootdir}/phabricator/src/extensions/${name}":
        ensure  => 'absent',
    }
}
