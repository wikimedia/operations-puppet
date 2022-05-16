# SPDX-License-Identifier: Apache-2.0
# == Class: query_service::crontasks
#
# Installs all the major cron jobs for Query service
#
# == Parameters:
# - $package_dir:  Directory where the service is installed.
# - $data_dir: Where the data is installed.
# - $log_dir: Directory where the logs go
# - $username: Username owning the service
# - $load_categories: frequency of loading categories
# - $run_tests: run test queries periodically (useful for test servers)
class query_service::crontasks(
    String $package_dir,
    String $data_dir,
    String $log_dir,
    String $username,
    String $deploy_name,
    Enum['none', 'daily', 'weekly'] $load_categories,
    Boolean $run_tests,
    Boolean $reload_wcqs_data,
) {
    ## BEGIN Temporary mitigation for T290330
    # Script to restart wdqs-blazegraph.service if hostname starts with wdqs2
    # Note: Script adds random delay between 0 and 10 minutes
    file { '/usr/local/bin/wdqs-codfw-restart-hourly-w-randomization.sh':
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/query_service/cron/wdqs-codfw-restart-hourly-w-randomization.sh',
    }
    systemd::timer::job { 'wdqs-restart-hourly-w-random-delay':
        ensure      => absent,
        description => 'Restarts WDQS on average once per hour to preserve WDQS availability',
        command     => '/usr/local/bin/wdqs-codfw-restart-hourly-w-randomization.sh',
        user        => 'root',
        interval    => [{'start' => 'OnUnitActiveSec', 'interval' => '55min'}],
    }


    ## END Temporary mitigation for T290330

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

    # the reload-categories cron needs to reload nginx once the categories are up to date
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
    systemd::timer::job { 'load-catgories-daily':
        ensure          => $ensure_daily_categories,
        description     => 'Query service category dump (daily)',
        command         => "/usr/local/bin/loadCategoriesDaily.sh ${deploy_name}",
        user            => $username,
        logfile_basedir => $log_dir,
        logfile_name    => 'reloadCategories.log',
        interval        => {'start' => 'OnCalendar', 'interval' => "Mon *-*-* 07:${fqdn_rand(60)}:00"},
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

    cron { 'reload-categories':
        ensure => 'absent',
        user   => $username,
    }

    cron { 'load-categories-daily':
        ensure => 'absent',
        user   => $username,
    }

    cron { 'load-dcatap-weekly':
        ensure => 'absent',
        user   => $username,
    }

    $ensure_tests = $run_tests ? {
        true    => present,
        default => absent,
    }

    $ensure_reload_wcqs_data = $reload_wcqs_data ? {
        true    => present,
        default => absent,
    }

    # Run test queries
    systemd::timer::job { 'run-query-service-test-queries':
        ensure       => $ensure_tests,
        description  => 'Run test queries for query service',
        command      => "${package_dir}/queries/test.sh",
        user         => $username,
        send_mail_to => 'wdqs-admin@wikimedia.org',
        send_mail    => true,
        interval     => {'start' => 'OnCalendar', 'interval' => '*:0/30:00' }
    }

    systemd::timer::job { 'wcqs-data-reload-weekly':
        ensure          => $ensure_reload_wcqs_data,
        description     => 'WCQS data reload',
        command         => "${package_dir}/wcqs-data-reload.sh",
        user            => 'root', # we need to restart blazegraph, so we need sudo priviliges
        logfile_basedir => $log_dir,
        logfile_name    => 'reloadWCQS.log',
        interval        => {'start' => 'OnCalendar', 'interval' => "Tue *-*-* 07:${fqdn_rand(60)}:00"},
    }

    cron { 'run-query-service-test-queries':
        ensure => 'absent',
        user   => $username,
    }

    cron { 'wcqs-data-reload-weekly':
        ensure => 'absent',
        user   => 'root',
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
