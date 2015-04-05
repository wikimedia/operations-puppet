# == Class: phabricator::migration
#
# Tools and such needed to migrate 3rd party content
#
class phabricator::migration (
    $dbhost                = 'localhost',
    $manifest_user         = '',
    $manifest_pass         = '',
    $app_user              = '',
    $app_pass              = '',
    $bz_user               = '',
    $bz_pass               = '',
    $rt_user               = '',
    $rt_pass               = '',
    $phabtools_cert        = '',
    $phabtools_user        = '',
) {
    package { 'python-mysqldb': ensure => present }

    file { '/etc/phabtools.conf':
        content => template('phabricator/phabtools.conf.erb'),
        require => Git::Install['phabricator/tools'],
    }

    git::install { 'phabricator/tools':
        directory => '/srv/phab/tools',
        git_tag   => 'HEAD',
        lock_file => '/srv/phab/tools.lock',
    }

    $fab_lock = '/var/run/fab_update_user.flock'
    cron { 'fab_user_update':
        ensure  => absent,
        command => "/usr/bin/flock -n ${fab_lock} -c '/srv/phab/tools/fab_update_user.py -a' >/dev/null 2>&1",
        user    => root,
        hour    => '*/1',
        minute  => 0,
    }

    $bz_header = '/var/run/bz_header.flock'
    cron { 'bz_header_update':
        ensure  => present,
        command => "/usr/bin/flock -n ${bz_header} -c '/srv/phab/tools/bugzilla_update_user_header.py -a' >/dev/null 2>&1",
        user    => root,
        hour    => '0',
    }

    $bz_comments = '/var/run/bz_comments.flock'
    cron { 'bz_comment_update':
        ensure  => present,
        command => "/usr/bin/flock -n ${bz_comments} -c '/srv/phab/tools/bugzilla_update_user_comments.py -a' >/dev/null 2>&1",
        user    => root,
        hour    => '1',
    }
}

