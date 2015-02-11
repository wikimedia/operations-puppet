# == Class: phabricator::extension
#
# === Parameters
#
# [*rootdir*]
#    Phabricator repo directory

define phabricator::extension($rootdir='/') {
    file { "${rootdir}/phabricator/src/extensions/${name}":
        ensure => link,
        target => "${rootdir}/extensions/${name}",
    }
}
