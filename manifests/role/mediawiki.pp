@monitoring::group { 'appserver_eqiad':     description => 'eqiad application servers' }
@monitoring::group { 'api_appserver_eqiad': description => 'eqiad API application servers' }
@monitoring::group { 'imagescaler_eqiad':   description => 'eqiad image scalers' }
@monitoring::group { 'jobrunner_eqiad':     description => 'eqiad jobrunner application servers' }
@monitoring::group { 'videoscaler_eqiad':   description => 'eqiad video scaler' }

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
                servers              => hiera('mediawiki_memcached_servers'),
            },
        },
    }

    monitoring::service { 'mediawiki-installation DSH group':
        description           => 'mediawiki-installation DSH group',
        check_command         => 'check_dsh_groups!mediawiki-installation',
        normal_check_interval => 60,
    }

    $scap_proxies = hiera('dsh::config::scap_proxies',[])
    if member($scap_proxies, $::fqdn) {
        include deployment::scap_proxy
    }
}

class role::mediawiki::webserver( $pool) {
    include ::role::mediawiki::common
    include ::apache::monitoring
    include ::lvs::configuration
    include ::mediawiki::web::sites
    include ::mediawiki::web

    $ips = $lvs::configuration::lvs_service_ips[$::realm][$pool][$::site]

    class { 'lvs::realserver':
        realserver_ips => $ips,
    }

    monitoring::service { 'appserver http':
        description   => 'Apache HTTP',
        check_command => 'check_http_wikipedia',
    }

    if os_version('ubuntu >= trusty') {
        monitoring::service { 'appserver_http_hhvm':
            description   => 'HHVM rendering',
            check_command => 'check_http_wikipedia_main',
        }

        nrpe::monitor_service { 'hhvm':
            description   => 'HHVM processes',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: -C hhvm',
        }
    }
}

class role::mediawiki::appserver {
    system::role { 'role::mediawiki::appserver': }

    include ::role::mediawiki::webserver

}

class role::mediawiki::appserver::api {
    system::role { 'role::mediawiki::appserver::api': }

    include ::role::mediawiki::webserver
}

class role::mediawiki::imagescaler {
    system::role { 'role::mediawiki::imagescaler': }

    include ::mediawiki::multimedia
    include ::role::mediawiki::webserver
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
        runners_parsoid => 4,
        runners_upload  => 7,
        runners_gwt     => 1,
    }
}

# monitor the Apple dictionary bridge (RT #6128)
class role::mediawiki::searchmonitor {

    # https://search.wikimedia.org/?lang=en&site=wikipedia&search=Wikimedia_Foundation&limit=1
    monitoring::service { 'mediawiki-dict-bridge':
        description   => 'Mediawiki Apple Dictionary Bridge',
        check_command => 'check_https_dictbridge',
    }

}

# Class for a subgroup of appservers where we can test experimental features
class role::mediawiki::canary_appserver {
    include role::mediawiki::appserver
}

# Ditto, for api
class role::mediawiki::appserver::canary_api {
    include role::mediawiki::appserver::api
}
