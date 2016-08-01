# == Class: phabricator::tools
#
# Tools and such needed to migrate 3rd party content
# and perform administrative tasks.
#
class phabricator::tools (
    $dbhost                = 'localhost',
    $dbslave               = 'localhost',
    $directory             = '/srv/phab/tools',
    $deploy_target         = 'phabricator/deployment',
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
    $gerritbot_token       = '',
    $dump                  = absent,
) {

    package { 'python-mysqldb': ensure => present }

    file { '/etc/phabtools.conf':
        content => template('phabricator/phabtools.conf.erb'),
        require => Package[$deploy_target],
    }

    $dump_script = "${directory}/public_task_dump.py"

    file { $dump_script:
        mode    => '0555',
        require => Package[$deploy_target],
    }

    cron { $dump_script:
        ensure  => $dump,
        command => $dump_script,
        user    => root,
        hour    => '2',
        minute  => '0',
        require => Package[$deploy_target],
    }

    # These bz_*_update jobs require the bugzilla_migration DB
    # The equivalent rt_*_update crons which are not present
    # at the moment require the rt_migration DB.

    $bz_header = '/var/run/bz_header.flock'
    cron { 'bz_header_update':
        ensure  => absent,
        command => "/usr/bin/flock -n ${bz_header} -c '/srv/phab/tools/bugzilla_update_user_header.py -a' >/dev/null 2>&1",
        user    => root,
        hour    => '0',
        require => Package[$deploy_target],
    }

    $bz_comments = '/var/run/bz_comments.flock'
    cron { 'bz_comment_update':
        ensure  => absent,
        command => "/usr/bin/flock -n ${bz_comments} -c '/srv/phab/tools/bugzilla_update_user_comments.py -a' >/dev/null 2>&1",
        user    => root,
        hour    => '1',
        require => Package[$deploy_target],
    }
}
