# == Class: phabricator::tools
#
# Tools and such needed to migrate 3rd party content
# and perform administrative tasks.
#
class phabricator::tools (
    $dbhost                = 'localhost',
    $directory             = '/srv/phab/tools',
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
    $dump                  = false,
) {

    package { 'python-mysqldb': ensure => present }

    file { '/etc/phabtools.conf':
        content => template('phabricator/phabtools.conf.erb'),
        require => Git::Install['phabricator/tools'],
    }

    git::install { 'phabricator/tools':
        directory => $directory,
        git_tag   => 'HEAD',
        lock_file => '/srv/phab/tools.lock',
    }

    if ($dump) {
        $dump_script = "${directory}/public_task_dump.py"

        file { $dump_script:
            mode  => '0555',
            require => Git::Install['phabricator/tools'],
        }

        cron { $dump_script:
            ensure  => present,
            command => $dump_script,
            user    => root,
            hour    => '2',
            require => Git::Install['phabricator/tools'],
        }
    }

    $bz_header = '/var/run/bz_header.flock'
    cron { 'bz_header_update':
        ensure  => present,
        command => "/usr/bin/flock -n ${bz_header} -c '/srv/phab/tools/bugzilla_update_user_header.py -a' >/dev/null 2>&1",
        user    => root,
        hour    => '0',
        require => Git::Install['phabricator/tools'],
    }

    $bz_comments = '/var/run/bz_comments.flock'
    cron { 'bz_comment_update':
        ensure  => present,
        command => "/usr/bin/flock -n ${bz_comments} -c '/srv/phab/tools/bugzilla_update_user_comments.py -a' >/dev/null 2>&1",
        user    => root,
        hour    => '1',
        require => Git::Install['phabricator/tools'],
    }
}
