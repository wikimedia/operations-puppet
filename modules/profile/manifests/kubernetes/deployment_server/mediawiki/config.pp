# SPDX-License-Identifier: Apache-2.0
# @summary This profile handles installing the mediawiki configuration generated from puppet into mw on k8s
#
# @note This class generates yaml files under $general_dir/mediawiki to handle apache virtual hosts, mcrouter pools,
# tlsproxy pools. The reason to have this profile is to keep stuff in sync between the legacy and k8s worlds.
class profile::kubernetes::deployment_server::mediawiki::config(
    String $deployment_server                           = lookup('deployment_server'),
    Array[Mediawiki::SiteCollection] $common_sites      = lookup('mediawiki::common_sites'),
    Array[Mediawiki::SiteCollection] $mediawiki_sites   = lookup('mediawiki::sites'),
    String $domain_suffix                               = lookup('mediawiki::web::sites::domain_suffix', {'default_value' => 'org'}),
    Stdlib::Unixpath $general_dir                       = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
    Hash  $servers_by_datacenter_category               = lookup('profile::mediawiki::mcrouter_wancache::shards'),
    Optional[Array[String]]          $enabled_listeners = lookup('profile::services_proxy::envoy::enabled_listeners', {'default_value' => undef}),
    String $statsd_server                               = lookup('statsd'),
    String $udp2log_aggregator                          = lookup('udp2log_aggregator')
){
    # Generate the apache-config defining yaml, and save it to
    # $general_dir/mediawiki/httpd.yaml
    # Beware: here we manually set the fcgi proxy, it should be changed
    # if it gets changed on kubernetes.
    # Uncomment if using FCGI_UNIX
    #$fcgi_proxy = 'unix:/run/shared/fpm-www.sock|fcgi://localhost'
    # Uncomment if using FCGI_TCP
    $fcgi_proxy = 'fcgi://127.0.0.1:9000'
    $all_sites = $mediawiki_sites + $common_sites
    class { '::mediawiki::web::yaml_defs':
        path          => "${general_dir}/mediawiki/httpd.yaml",
        siteconfigs   => $all_sites,
        fcgi_proxy    => $fcgi_proxy,
        domain_suffix => $domain_suffix,
        statsd        => $statsd_server,
    }

    # logging.
    # TODO: use codfw logging pipeline for codfw once it's ready
    $kafka_config = kafka_config('logging-eqiad')
    $kafka_brokers = $kafka_config['brokers']['array']
    class { 'mediawiki::logging::yaml_defs':
        path          => "${general_dir}/mediawiki/logging.yaml",
        udp2log       => $udp2log_aggregator,
        kafka_brokers => $kafka_brokers,
    }
    class { 'mediawiki::mcrouter::yaml_defs':
        path                           => "${general_dir}/mediawiki/mcrouter_pools.yaml",
        servers_by_datacenter_category => $servers_by_datacenter_category,
    }
    class { 'mediawiki::tlsproxy::yaml_defs':
        path      => "${general_dir}/mediawiki/tlsproxy.yaml",
        listeners => $enabled_listeners,
    }
}
