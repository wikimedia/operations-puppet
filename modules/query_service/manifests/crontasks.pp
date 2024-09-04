# SPDX-License-Identifier: Apache-2.0
# == Class: query_service::crontasks
#
# Installs all the major recurring jobs for Query service
#
# == Parameters:
# - $package_dir:  Directory where the service is installed.
# - $data_dir: Where the data is installed.
# - $log_dir: Directory where the logs go
# - $username: Username owning the service
# - $load_categories: frequency of loading categories
class query_service::crontasks(
    String $package_dir,
    String $data_dir,
    String $log_dir,
    String $username,
    String $deploy_name,
    Enum['none', 'daily', 'weekly'] $load_categories,
) {
    file { '/usr/local/bin/cronUtils.sh':
        ensure => present,
        source => 'puppet:///modules/query_service/cron/cronUtils.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/reloadCategories.sh':
        ensure => present,
        source => 'puppet:///modules/query_service/cron/reloadCategories.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/loadCategoriesDaily.sh':
        ensure => present,
        source => 'puppet:///modules/query_service/cron/loadCategoriesDaily.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/local/bin/reloadDCAT-AP.sh':
        ensure => present,
        source => 'puppet:///modules/query_service/cron/reloadDCAT-AP.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $reload_categories_log = "${log_dir}/reloadCategories.log"

    # the reload-categories job needs to reload nginx once the categories are up to date
    sudo::user { "${username}-reload-nginx":
      ensure     => present,
      user       => $username,
      privileges => [ 'ALL = NOPASSWD: /bin/systemctl reload nginx' ],
    }

    $ensure_reload_categories = $load_categories ? {
        'weekly' => 'present',
        default  => 'absent',
    }

    $ensure_daily_categories = $load_categories ? {
        'daily' => 'present',
        default => 'absent',
    }

    # Category dumps start on Sat 20:00. By Mon, they should be done.
    # We want random time so that hosts don't reboot at the same time, but we
    # do not want them to be too far from one another.
    systemd::timer::job { 'reload-categories':
        ensure          => $ensure_reload_categories,
        description     => 'Query service category dump (weekly)',
        command         => "/usr/local/bin/reloadCategories.sh ${deploy_name}",
        user            => $username,
        logfile_basedir => $log_dir,
        logfile_name    => 'reloadCategories.log',
        interval        => {'start' => 'OnCalendar', 'interval' => "Mon *-*-* ${fqdn_rand(2)}:${fqdn_rand(60)}:00"},
    }

    # Categories daily dump starts at 5:00. Currently it is done by 5:05, but just in case
    # it ever takes longer, start at 7:00.
    systemd::timer::job { 'load-categories-daily':
        ensure          => $ensure_daily_categories,
        description     => 'Query service category dump (daily)',
        command         => "/usr/local/bin/loadCategoriesDaily.sh ${deploy_name}",
        user            => $username,
        logfile_basedir => $log_dir,
        logfile_name    => 'reloadCategories.log',
        interval        => {'start' => 'OnCalendar', 'interval' => "*-*-* 07:${fqdn_rand(60)}:00"},
    }

    systemd::timer::job{ 'load-dcatap-weekly':
        ensure          => $ensure_daily_categories,
        description     => 'Reload DCAT-AP',
        command         => "/usr/local/bin/reloadDCAT-AP.sh ${deploy_name}",
        user            => $username,
        logfile_basedir => $log_dir,
        logfile_name    => 'reloadDCATAP.log',
        interval        => {'start' => 'OnCalendar', 'interval' => "Fri *-*-* 07:${fqdn_rand(60)}:00"},
    }

    logrotate::rule { 'query-service-reload-categories':
        ensure       => present,
        file_glob    => $reload_categories_log,
        frequency    => 'monthly',
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 3,
        compress     => true,
        create       => "0640 ${username} wikidev",
    }

}
