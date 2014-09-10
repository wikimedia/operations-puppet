# == Class: phabricator::migration
#
# Tools and such needed to migrate 3rd party content
#
class phabricator::migration() {

    package { 'python-mysqldb': ensure => present}

    git::install { 'phabricator/tools':
        directory => "/srv/phab/tools",
        git_tag   => 'HEAD',
    }

}

