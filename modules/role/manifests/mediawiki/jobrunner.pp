class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    include ::role::mediawiki::common
    include ::mediawiki::jobrunner

    monitoring::service { 'jobrunner_http_hhvm':
        description   => 'HHVM jobrunner',
        check_command => 'check_http_jobrunner',
        retries       => 2,
    }

}
