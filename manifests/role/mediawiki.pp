@monitor_group { 'appserver_eqiad': description => 'eqiad application servers' }
@monitor_group { 'api_appserver_eqiad': description => 'eqiad API application servers' }
@monitor_group { 'imagescaler_eqiad': description => 'eqiad image scalers' }
@monitor_group { 'jobrunner_eqiad': description => 'eqiad jobrunner application servers' }
@monitor_group { 'videoscaler_eqiad': description => 'eqiad video scaler' }

class role::mediawiki::common {
    include standard
    include geoip
    include ::mediawiki
    include ::twemproxy::monitoring
    include ::nutcracker::monitoring

    $mediawiki_log_aggregator = 'fluorine.eqiad.wmnet:8420'

    class { '::mediawiki::php':
        fatal_log_file => "udp://${mediawiki_log_aggregator}",
    }

    class { '::mediawiki::syslog':
        apache_log_aggregator => $mediawiki_log_aggregator,
    }
}

class role::mediawiki::webserver( $pool, $maxclients ) {
    include ::mediawiki
    include ::apache::monitoring
    include role::mediawiki::common
    include lvs::configuration

    class { '::mediawiki::web':
        maxclients => $maxclients,
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm][$pool][$::site],
    }

    monitor_service { 'appserver http':
        description   => 'Apache HTTP',
        check_command => 'check_http_wikipedia',
    }
}

class role::mediawiki::appserver {
    system::role { 'role::mediawiki::appserver': }

    class { 'role::mediawiki::webserver':
        pool       => 'apaches',
        maxclients => $::processorcount ? {
            16      => 60,
            12      => 50,
            24      => 50,
            default => 40,
        }
    }
}

class role::mediawiki::appserver::api {
    system::role { 'role::mediawiki::appserver::api': }

    class { 'role::mediawiki::webserver':
        pool       => 'api',
        maxclients => 100,
    }
}

class role::mediawiki::imagescaler {
    system::role { 'role::mediawiki::imagescaler': }

    include ::mediawiki::multimedia

    class { 'role::mediawiki::webserver':
        pool       => 'rendering',
        maxclients => 18,
    }
}

class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    include role::mediawiki::common
    include ::mediawiki::multimedia

    class { '::mediawiki::jobqueue':
        run_jobs_enabled       => true,
        dprioprocs             => 5,
        iprioprocs             => 0,
        procs_per_iobound_type => 0,
        type                   => 'webVideoTranscode',
        timeout                => 14400,
    }
}

class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    include role::mediawiki::common

    class { '::mediawiki::jobqueue':
        dprioprocs             => 17,
        iprioprocs             => 6,
        procs_per_iobound_type => 5,
        run_jobs_enabled       => true,
    }
}
