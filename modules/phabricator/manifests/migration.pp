# == Class: phabricator::migration
#
# Tools and such needed to migrate 3rd party content
#
class phabricator::migration {

    package { 'python-mysqldb': ensure => present } 

    git::install { 'phabricator/tools':
        directory => '/srv/phab/tools',
        git_tag   => 'HEAD',
    }

    fab_lock = '/var/run/fab_update_user.flock'
    cron { 'fab_user_update':
        ensure  => present,
        command => "/usr/bin/flock -n ${fab_lock} -c '/srv/phab/tools/fab_update_user.py -a' 2>&1",
        user    => root,
        hour    => '*/1',
        minute  => 0,
    }
}

