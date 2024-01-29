# == Class: phabricator::tools
#
# Tools and such needed to migrate 3rd party content
# and perform administrative tasks.
#
class phabricator::tools (
    Stdlib::Fqdn $dbmaster_host       = 'localhost',
    String $dbmaster_port       = '3306',
    Stdlib::Fqdn $dbslave_host        = 'localhost',
    String $dbslave_port        = '3323',
    Stdlib::Unixpath $directory = '/srv/phab/tools',
    String $deploy_target       = 'phabricator/deployment',
    String $manifest_user       = '',
    String $manifest_pass       = '',
    String $app_user            = '',
    String $app_pass            = '',
    String $bz_user             = '',
    String $bz_pass             = '',
    String $rt_user             = '',
    String $rt_pass             = '',
    String $phabtools_cert      = '',
    String $phabtools_user      = '',
    String $gerritbot_token     = '',
    Boolean $dump               = false,
) {

    if debian::codename::eq('buster') {
        package { 'python-mysqldb': ensure => present }
    } else {
        package { 'python3-mysqldb': ensure => present }
        package { 'python3-pymysql': ensure => present }
    }

    file { '/etc/phabtools.conf':
        content => template('phabricator/phabtools.conf.erb'),
        require => Package[$deploy_target],
        owner   => 'root',
        group   => 'root',
        mode    => '0660',
    }

    file { '/srv/dumps':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/srv/dumps/WARNING_NEVER_PUT_PRIVATE_DATA_HERE_THIS_IS_SYNCED_TO_PUBLIC':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    $dump_script = "${directory}/public_task_dump.py"

    file { $dump_script:
        mode    => '0555',
        require => Package[$deploy_target],
    }

    $dump_job_ensure = $dump ? {
        true    => present,
        default => absent,
    }

    systemd::timer::job { 'phabricator_task_dump':
        ensure      => absent, # Removed until T355502 is resolved
        user        => 'root',
        description => 'phabricator public task dump',
        command     => "/usr/bin/python3 ${dump_script}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'Monday *-*-* 02:00:00'},
        require     => Package[$deploy_target],
    }
    # clean up old tmp files (T150396)
    $clean_tmp_cmd='/usr/bin/find /tmp -user www-data -mtime +14 -delete'
    systemd::timer::job { 'phabricator_clean_tmp_files':
        ensure      => present,
        user        => 'root',
        description => 'phabricator cleanup temp files',
        command     => $clean_tmp_cmd,
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 07:00:00'},
    }
}
