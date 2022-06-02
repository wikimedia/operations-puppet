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
    $reload_dcatap_log = "${log_dir}/reloadDCATAP.log"
    $reload_wcqs_data_log = "${log_dir}/reloadWCQS.log"
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
    cron { 'reload-categories':
        ensure  => $ensure_reload_categories,
        command => "/usr/local/bin/reloadCategories.sh ${deploy_name} >> ${reload_categories_log} 2>&1",
        user    => $username,
        weekday => 1,
        minute  => fqdn_rand(60),
        hour    => fqdn_rand(2),
    }

    # Categories daily dump starts at 5:00. Currently it is done by 5:05, but just in case
    # it ever takes longer, start at 7:00.
    cron { 'load-categories-daily':
        ensure  => $ensure_daily_categories,
        command => "/usr/local/bin/loadCategoriesDaily.sh ${deploy_name} >> ${reload_categories_log} 2>&1",
        user    => $username,
        minute  => fqdn_rand(60),
        hour    => 7
    }

    cron { 'load-dcatap-weekly':
        ensure  => $ensure_daily_categories,
        command => "/usr/local/bin/reloadDCAT-AP.sh ${deploy_name} >> ${reload_dcatap_log} 2>&1",
        user    => $username,
        minute  => fqdn_rand(60),
        hour    => 7,
        weekday => 5,
    }

    $ensure_tests = $run_tests ? {
        true    => present,
        default => absent,
    }

    $ensure_reload_wcqs_data = $reload_wcqs_data ? {
        true    => present,
        default => absent,
    }

    cron { 'run-query-service-test-queries':
        ensure      => $ensure_tests,
        environment => 'MAILTO=wdqs-admins',
        command     => "${package_dir}/queries/test.sh > /dev/null",
        user        => $username,
        minute      => '*/30',
    }

    cron { 'wcqs-data-reload-weekly':
      ensure  => $ensure_reload_wcqs_data,
      command => "${package_dir}/wcqs-data-reload.sh >> ${reload_wcqs_data_log} 2>&1",
      user    => 'root',        #we need to restart blazegraph, so we need sudo priviliges
      minute  => fqdn_rand(60),
      hour    => 7,
      weekday => 2,
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
