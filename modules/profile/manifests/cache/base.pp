# SPDX-License-Identifier: Apache-2.0
# === Class profile::cache::base
#
# Sets up some common things for cache instances:
# - conftool
# - monitoring
# - logging/analytics
# - purging
#
class profile::cache::base(
    String $cache_cluster                            = lookup('cache::cluster'),
    Array[Stdlib::Fqdn] $wikimedia_domains           = lookup('wikimedia_domains'),
    Array[Stdlib::Fqdn] $wmcs_domains                = lookup('wmcs_domains'),
    Optional[Stdlib::Host] $logstash_host            = lookup('logstash_host', {'default_value' => undef}),
    Optional[Stdlib::Port] $logstash_syslog_port     = lookup('logstash_syslog_port', {'default_value' => undef}),
    Optional[Stdlib::Port] $logstash_json_lines_port = lookup('logstash_json_lines_port', {'default_value' => undef}),
    Float $log_slow_request_threshold                = lookup('profile::cache::base::log_slow_request_threshold', {'default_value' => 60.0}),
    Boolean $allow_iptables                          = lookup('profile::cache::base::allow_iptables', {'default_value' => false}),
    Boolean $performance_tweaks                      = lookup('profile::cache::base::performance_tweaks', {'default_value' => true}),
    Array $extra_trust                               = lookup('profile::cache::base::extra_trust', {'default_value' => []}),
    Optional[Hash[String, Integer]] $default_weights = lookup('profile::cache::base::default_weights', {'default_value' => undef}),
    String $conftool_prefix                          = lookup('conftool_prefix'),
    Boolean $use_ip_reputation                       = lookup('profile::cache::varnish::frontend::use_ip_reputation'),
    Boolean $enable_monitoring                       = lookup('profile::cache::varnish::frontend::enable_monitoring'),
    Boolean $use_noflow_iface_preup                  = lookup('profile::cache::base::use_noflow_iface_preup', {'default_value' => false}),
){

    require network::constants
    # NOTE: Add the public WMCS IP space when T209011 is done
    $wikimedia_nets = flatten(concat($::network::constants::aggregate_networks, '172.16.0.0/12'))
    $wikimedia_trust = flatten(concat($::network::constants::aggregate_networks, $extra_trust))

    # Needed profiles
    require ::profile::conftool::client
    require ::profile::prometheus::cadvisor
    require ::profile::base::production
    require ::profile::base::systemd

    # FIXME: this cannot be required or it will cause a dependency cycle. It might be a good idea not to include it here
    include ::profile::cache::kafka::webrequest

    include ::profile::prometheus::varnishkafka_exporter

    # Purging
    require ::profile::cache::purge

    # Globals we need to include
    include ::network::constants

    if ! $allow_iptables {
        # Prevent accidental iptables module loads
        kmod::blacklist { 'cp-bl':
            modules => ['x_tables'],
        }
    }

    class { 'conftool::scripts': }

    if $performance_tweaks {
        # Only production needs system perf tweaks
        class { '::cpufrequtils': }
        class { 'cacheproxy::performance':
            use_noflow_iface_preup => $use_noflow_iface_preup,
        }
    }
    # Basic varnish classes

    class { '::varnish::common':
        log_slow_request_threshold => $log_slow_request_threshold,
        logstash_host              => $logstash_host,
        logstash_json_lines_port   => $logstash_json_lines_port,
    }

    class { [
        '::varnish::common::errorpage',
        '::varnish::common::browsersec',
    ]:
    }

    if $enable_monitoring {
        class { '::varnish::common::director_scripts': }
    }

    class { '::varnish::netmapper_update_common': }
    class { 'varnish::trusted_proxies': }
    # Add /var/netmapper/public_clouds.json from etcd.
    # This file is loaded in wikimedia-frontend.vcl.erb
    confd::file { '/var/netmapper/public_clouds.json':
        ensure     => present,
        watch_keys => ['/request-ipblocks/cloud'],
        prefix     => $conftool_prefix,
        before     => Service['varnish-frontend'],
        content    => template('profile/cache/public_clouds.json.tpl.erb'),
        check      => '/usr/bin/vnm_validate {{.src}}'
    }
    # Add /var/netmapper/known_clients.json from etcd.
    # This file is loaded in wikimedia-frontend.vcl.erb
    confd::file { '/var/netmapper/known_clients.json':
        ensure     => present,
        watch_keys => ['/request-ipblocks/known-clients'],
        prefix     => $conftool_prefix,
        before     => Service['varnish-frontend'],
        content    => template('profile/cache/known_clients.json.tpl.erb'),
        check      => '/usr/bin/vnm_validate {{.src}}'
    }
    if ( $use_ip_reputation ) {
        # Add /var/netmapper/vendor_proxies.json
        # This file is loaded in wikimedia-frontend.vcl.erb
        # lint:ignore:puppet_url_without_modules
        file { '/var/netmapper/vendor_proxies.json':
            ensure       => present,
            source       => 'puppet:///volatile/ip_reputation_vendors/proxies.json',
            before       => Service['varnish-frontend'],
            validate_cmd => '/usr/bin/vnm_validate %',
        }
    }
    # lint:endignore

    ###########################################################################
    # Analytics/Logging stuff
    ###########################################################################

    # Programs installed on both text and upload nodes
    $common_mtail_programs = ['varnishreqstats', 'varnishttfb', 'varnishxcache']

    # Programs specific to either upload or text
    if $cache_cluster == 'upload' {
        # Media browser cache hit rate and request volume stats.
        $mtail_programs = $common_mtail_programs + [ 'varnishmedia' ]
    } else {
        # ResourceLoader browser cache hit rate and request volume stats.
        $mtail_programs = $common_mtail_programs + [ 'varnishrls' ]
    }

    class { '::varnish::logging':
        default_mtail_programs  => $mtail_programs,
        internal_mtail_programs => [ 'varnishprocessing', 'varnisherrors', 'varnishsli' ],
    }

    # auto-depool on shutdown + conditional one-shot auto-pool on start
    class { 'cacheproxy::traffic_pool': }

    ###########################################################################
    # Purging
    ###########################################################################

    # Node initialization script for conftool
    if $default_weights != undef {
        class { 'conftool::scripts::initialize':
            services => $default_weights,
        }
    }
}
