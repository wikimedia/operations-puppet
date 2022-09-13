# SPDX-License-Identifier: Apache-2.0
# = Class: profile::query_service::wcqs
#
# This class defines a meta-class that pulls in all the query_service profiles
# necessary for a query service installation servicing the commons.wikimedia.org
# dataset.
class profile::query_service::wcqs(
    Stdlib::Unixpath $package_dir = lookup('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = lookup('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = lookup('profile::query_service::log_dir'),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Stdlib::Port $logstash_logback_port = lookup('logstash_logback_port'),
    String $heap_size = lookup('profile::query_service::blazegraph_heap_size'),
    Boolean $use_deployed_config = lookup('profile::query_service::blazegraph_use_deployed_config'),
    Array[String] $extra_jvm_opts = lookup('profile::query_service::blazegraph_extra_jvm_opts'),
    String $contact_groups = lookup('contactgroups', {'default_value' => 'admins'}),
    Boolean $monitoring_enabled = lookup('profile::query_service::blazegraph::monitoring_enabled'),
    Optional[String] $sparql_query_stream = lookup('profile::query_service::sparql_query_stream', {'default_value' => undef}),
    Optional[String] $event_service_endpoint = lookup('profile::query_service::event_service_endpoint', {'default_value' => undef}),
    String $oauth_access_token_secret = lookup('profile::query_service::oauth_access_token_secret'),
    String $oauth_consumer_secret = lookup('profile::query_service::oauth_consumer_secret'),
    String $federation_user_agent = lookup('profile::query_service::federation_user_agent'),
    String $blazegraph_main_ns = lookup('profile::query_service::blazegraph_main_ns'),
    Optional[String] $jvmquake_options = lookup('profile::query_service::jvmquake_options', {'default_value' => undef}),
    Optional[Integer] $jvmquake_warn_threshold = lookup('profile::query_service::jvmquake_warn_threshold', {'default_value' => undef}),
    String $jvmquake_warn_file = lookup('profile::query_service::jvmquake_warn_file', {'default_value' => '/tmp/wcqs_blazegraph_jvmquake_warn_gc'}),
    Array[String] $uri_scheme_options = lookup('profile::query_service::uri_scheme_options')
) {
    require ::profile::query_service::common
    require ::profile::query_service::gui
    require ::profile::query_service::streaming_updater

    $username = 'blazegraph'
    $instance_name = "${deploy_name}-blazegraph"
    $nginx_port = 80
    $blazegraph_port = 9999
    $prometheus_port = 9195
    $prometheus_agent_port = 9102

    $data_options = ['-DwikibaseSomeValueMode=skolem']

    $private_jvm_opts = [
        "-Dorg.wikidata.query.rdf.mwoauth.OAuthProxyConfig.accessTokenSecret=${oauth_access_token_secret}",
        "-Dorg.wikidata.query.rdf.mwoauth.OAuthProxyConfig.consumerSecret=${oauth_consumer_secret}",
        "-Dwdqs.jwt-identity-filter.jwt-identity-secret=${oauth_access_token_secret}",
    ]

    profile::query_service::blazegraph { $instance_name:
        username                => $username,
        package_dir             => $package_dir,
        data_dir                => $data_dir,
        log_dir                 => $log_dir,
        deploy_name             => $deploy_name,
        logstash_logback_port   => $logstash_logback_port,
        heap_size               => $heap_size,
        use_deployed_config     => $use_deployed_config,
        extra_jvm_opts          => $extra_jvm_opts + $private_jvm_opts + $uri_scheme_options + $data_options,
        contact_groups          => $contact_groups,
        monitoring_enabled      => $monitoring_enabled,
        sparql_query_stream     => $sparql_query_stream,
        event_service_endpoint  => $event_service_endpoint,
        nginx_port              => $nginx_port,
        blazegraph_port         => $blazegraph_port,
        prometheus_port         => $prometheus_port,
        prometheus_agent_port   => $prometheus_agent_port,
        config_file_name        => 'RWStore.wcqs.properties',
        prefixes_file           => 'prefixes-sdc.conf',
        use_geospatial          => true,
        journal                 => 'wcqs',
        blazegraph_main_ns      => $blazegraph_main_ns,
        use_oauth               => true,
        federation_user_agent   => $federation_user_agent,
        jvmquake_options        => $jvmquake_options,
        jvmquake_warn_threshold => $jvmquake_warn_threshold,
        jvmquake_warn_file      => $jvmquake_warn_file
    }
}
