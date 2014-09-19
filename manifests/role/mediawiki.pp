@monitor_group { 'appserver_hhvm_eqiad':     description => 'eqiad application servers (HHVM)' }
@monitor_group { 'appserver_eqiad':     description => 'eqiad application servers' }
@monitor_group { 'api_appserver_eqiad': description => 'eqiad API application servers' }
@monitor_group { 'imagescaler_eqiad':   description => 'eqiad image scalers' }
@monitor_group { 'jobrunner_eqiad':     description => 'eqiad jobrunner application servers' }
@monitor_group { 'videoscaler_eqiad':   description => 'eqiad video scaler' }

class role::mediawiki::common {
    include ::standard
    include ::geoip
    include ::mediawiki
    include ::nutcracker::monitoring

    class { '::nutcracker':
        mbuf_size => '64k',
        pools     => {
            'memcached' => {
                auto_eject_hosts     => true,
                distribution         => 'ketama',
                hash                 => 'md5',
                listen               => '127.0.0.1:11212',
                preconnect           => true,
                server_connections   => 2,
                server_failure_limit => 3,
                timeout              => 250,
                servers              => [
                    '10.64.0.180:11211:1',
                    '10.64.0.181:11211:1',
                    '10.64.0.182:11211:1',
                    '10.64.0.183:11211:1',
                    '10.64.0.184:11211:1',
                    '10.64.0.185:11211:1',
                    '10.64.0.186:11211:1',
                    '10.64.0.187:11211:1',
                    '10.64.0.188:11211:1',
                    '10.64.0.189:11211:1',
                    '10.64.0.190:11211:1',
                    '10.64.0.191:11211:1',
                    '10.64.0.192:11211:1',
                    '10.64.0.193:11211:1',
                    '10.64.0.194:11211:1',
                    '10.64.0.195:11211:1',
                ],
            },
        },
    }

    monitor_service { 'mediawiki-installation DSH group':
        description   => 'mediawiki-installation DSH group',
        check_command => "check_dsh_groups!mediawiki-installation",
        normal_check_interval => 60,
    }
}

class role::mediawiki::webserver( $pool, $workers_limit = undef ) {
    include ::role::mediawiki::common
    include ::apache::monitoring
    include ::lvs::configuration
    include ::mediawiki::web::sites

    class { '::mediawiki::web':
        workers_limit       => $workers_limit,
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

    if ubuntu_version('>= trusty') {

        $pool = 'hhvm_appservers'

        monitor_service { 'appserver_http_hhvm':
            description   => 'HHVM rendering',
            check_command => 'check_http_wikipedia_main',
        }
    } else {
        $pool = 'apaches'
    }

    class { 'role::mediawiki::webserver': pool => $pool, }
}

class role::mediawiki::appserver::api {
    system::role { 'role::mediawiki::appserver::api': }

    class { 'role::mediawiki::webserver': pool => 'api' }
}

class role::mediawiki::imagescaler {
    system::role { 'role::mediawiki::imagescaler': }

    include ::mediawiki::multimedia

    class { 'role::mediawiki::webserver': pool => 'rendering', workers_limit => 30 }
}

class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    include ::role::mediawiki::common
    include ::mediawiki::multimedia

    class { '::mediawiki::jobrunner':
        queue_servers     => ['rdb1001.eqiad.wmnet', 'rdb1003.eqiad.wmnet'],
        statsd_server     => 'statsd.eqiad.wmnet:8125',
        runners_transcode => 5,
    }
}

class role::mediawiki::jobrunner {
    system::role { 'role::mediawiki::jobrunner': }

    include ::role::mediawiki::common

    class { '::mediawiki::jobrunner':
        queue_servers   => ['rdb1001.eqiad.wmnet', 'rdb1003.eqiad.wmnet'],
        statsd_server   => 'statsd.eqiad.wmnet:8125',
        runners_basic   => 14,
        runners_parsoid => 21,
        runners_upload  => 7,
        runners_gwt     => 1,
    }
}
