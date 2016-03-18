class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    include ::role::mediawiki::common
    include ::mediawiki::jobrunner

    monitoring::service { 'jobrunner_http_hhvm':
        description   => 'HHVM jobrunner',
        check_command => 'check_http_jobrunner',
        retries       => 2,
    }

    # Bump safety margin until T130364 analysed further
    sysctl::parameters { 'jobrunner_conntrack':
        values => {
            'net.ipv4.netfilter.ip_conntrack_max' => '524288',
        },
    }
}
