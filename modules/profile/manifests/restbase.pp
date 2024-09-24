# == class profile::restbase
#
# sets up a REST API & storage service
#
# === Parameters
#
# [*cassandra_user*]
#   Cassandra user name.
#
# [*cassandra_password*]
#   Cassandra password.
#
# [*seeds*]
#   Array of cassandra hosts (IP or host names) to contact.
#
# [*seeds_ng*]
#   Array of cassandra hosts (IP or host names) to contact (next-gen storage module).
#
# [*cassandra_local_dc*]
#   Which DC should be considered local.
#
# [*cassandra_datacenters*]
#   The full list of member datacenters.
#
# [*cassandra_tls*]
#   An associative array of TLS options for the Cassandra driver.
#   See: https://nodejs.org/api/tls.html#tls_tls_createsecurecontext_options
#
# [*logging_label*]
#   The logging label to use both for logging and statsd.
#
# [*monitor_restbase*]
#   Whether RESTBase HTTP root monitoring is enabled. (true/false)
#
# [*monitor_domain*]
#   The domain to monitor during the service's operation.
#
# [*hosts*]
#   The list of RESTBase hosts used for setting up the rate-limiting DHT.
#
# In production, URIs are looked up automatically. In other environments,
# you will need to define via hiera the following variables:
# [*parsoid_uri*]
#   URI to reach Parsoid. Format: http://parsoid.svc.eqiad.wmnet:8000
#
# [*mobileapps_uri*]
#   MobileApps service URI. Format: https://mobileapps.svc.eqiad.wmnet:4102
#
# [*mathoid_uri*]
#   Mathoid service URI. Format: https://mathoid.svc.eqiad.wmnet:4001
#
# [*event_service_uri*]
#   Eventgate service URI. Format: https://eventgate-main.discovery.wmnet:4492/v1/events
#
# [*proton_uri*]
#   Proton PDF Render service URI. Format: https://proton.discovery.wmnet:4030
#
# [*citoid_uri*]
#   Citoid service URI. Format: http://citoid.svc.eqiad.wmnet:1970
#
# [*cxserver_uri*]
#   CXServer service uri. Format: https://cxserver.discovery.wmnet:4002
#
# [*recommendation_uri*]
#   Recommendation API service URI. Format:
#   http://recommendation-api.discovery.wmnet:9632
#
# [*wikifeeds_uri*]
#   Wikifeeds service URI. Format: https://wikifeeds.discovery.wmnet:4101
#
class profile::restbase(
    $cassandra_user = lookup('profile::restbase::cassandra_user'),
    $cassandra_password = lookup('profile::restbase::cassandra_password'),
    $no_workers = lookup('profile::restbase::no_workers', {'default_value' => 'ncpu'}),
    $seeds_ng = lookup('profile::restbase::seeds_ng', {'default_value' => []}),
    $hosts = lookup('profile::restbase::hosts'),
    $cassandra_local_dc = lookup('profile::restbase::cassandra_local_dc'),
    $cassandra_datacenters = lookup('profile::restbase::cassandra_datacenters'),
    $cassandra_tls = lookup('profile::restbase::cassandra_tls', {'default_value' => {}}),
    $salt_key = lookup('profile::restbase::salt_key'),
    $logging_label = lookup('profile::restbase::logging_label'),
    $listeners  = lookup('profile::services_proxy::envoy::listeners'),
    $parsoid_uri = lookup(
        'profile::restbase::parsoid_uri',
        {'default_value' => wmflib::service::get_url('mw-parsoid', '/w/rest.php', $listeners)}
    ),
    $mobileapps_uri = lookup(
        'profile::restbase::mobileapps_uri',
        {'default_value' => wmflib::service::get_url('mobileapps', '', $listeners)}
    ),
    $mathoid_uri    = lookup(
        'profile::restbase::mathoid_uri',
        {'default_value' => wmflib::service::get_url('mathoid', '', $listeners)}
    ),
    $event_service_uri = lookup(
        'profile::restbase::event_service_uri',
        {'default_value' => wmflib::service::get_url('eventgate-main','/v1/events', $listeners)}
    ),
    $proton_uri     = lookup(
        'profile::restbase::proton_uri',
        {'default_value' => wmflib::service::get_url('proton', '', $listeners)}
    ),
    $citoid_uri     = lookup(
        'profile::restbase::citoid_uri',
        {'default_value' => wmflib::service::get_url('citoid', '', $listeners)}
    ),
    $cxserver_uri   = lookup(
        'profile::restbase::cxserver_uri',
        {'default_value' => wmflib::service::get_url('cxserver', '', $listeners)}
    ),
    $recommendation_uri = lookup(
        'profile::restbase::recommendation_uri',
        {'default_value' => wmflib::service::get_url('recommendation', '', $listeners)}
    ),
    $wikifeeds_uri  = lookup(
        'profile::restbase::wikifeeds_uri',
        {'default_value' => wmflib::service::get_url('wikifeeds', '', $listeners)}
    ),
    $monitor_restbase = lookup('profile::restbase::monitor_restbase', {'default_value' => true}),
    $monitor_domain = lookup('profile::restbase::monitor_domain'),
) {
    # Default values that need no overriding
    $port = 7231
    $page_size = 250

    require ::service::configuration
    $local_logfile = "${service::configuration::log_dir}/${title}/main.log"

    # Uris
    service::node { 'restbase':
        port              => $port,
        no_workers        => $no_workers,
        no_file           => 200000,
        healthcheck_url   => "/${monitor_domain}/v1",
        icinga_check      => false, # done via service::catalog 'probes'
        has_spec          => true,
        starter_script    => 'restbase/server.js',
        auto_refresh      => false,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            ipaddress             => $::ipaddress,
            rl_seeds              => reject(reject($hosts, $::hostname), $::ipaddress),
            seeds_ng              => $seeds_ng,
            cassandra_local_dc    => $cassandra_local_dc,
            cassandra_datacenters => $cassandra_datacenters,
            cassandra_user        => $cassandra_user,
            cassandra_password    => $cassandra_password,
            cassandra_tls         => $cassandra_tls,
            parsoid_uri           => $parsoid_uri,
            mathoid_uri           => $mathoid_uri,
            mobileapps_uri        => $mobileapps_uri,
            citoid_uri            => $citoid_uri,
            event_service_uri     => $event_service_uri,
            proton_uri            => $proton_uri,
            cxserver_uri          => $cxserver_uri,
            recommendation_uri    => $recommendation_uri,
            wikifeeds_uri         => $wikifeeds_uri,
            salt_key              => $salt_key,
            page_size             => $page_size,
        },
        logging_name      => $logging_label,
        statsd_prefix     => $logging_label,
    }

    sysctl::parameters { 'tcp_performance':
        values => {
            # Allow TIME_WAIT connection reuse state as attempt to
            # reduce the usage of ephemeral ports.
            # See <http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html>
            'net.ipv4.tcp_tw_reuse' => 1,
        },
    }

    $ensure_monitor_restbase = $monitor_restbase ? {
        true    => present,
        false   => absent,
        default => present,
    }

    monitoring::service { 'restbase_http_root':
        ensure        => $ensure_monitor_restbase,
        description   => 'Restbase root url',
        check_command => "check_http_port_url!${port}!/",
        contact_group => 'admins,team-services',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/RESTBase',
    }


    nrpe::monitor_service { 'restbase_instance_space':
        ensure       => $ensure_monitor_restbase,
        description  => 'Cassandra instance data free space',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/RESTBase#instance-data',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 30% -c 20% -p /srv/cassandra/instance-data',
    }


    # RESTBase rate limiting DHT firewall rule
    $rb_hosts_ferm = join($hosts, ' ')
    ferm::service { 'restbase-ratelimit':
        proto  => 'tcp',
        port   => '3050',
        srange => "@resolve((${rb_hosts_ferm}))",
    }

    # TEMP for T223953
    # Allow access to 7233 as well. Once RESTRouter is used, remove
    # this block and entirely and change the port to 7233
    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7233',
    }
    # END TEMP

}
