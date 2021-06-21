# = Class: profile::query_service::wikidata
#
# This class defines a meta-class that pulls in all the query_service profiles
# necessary for a query service installation servicing the www.wikidata.org
# dataset.
#
# This additionally provides a location for defining datasource specific
# configuration, such as if geo support is necessary. This kind of
# configuration doesn't end up fitting in hiera as we have multiple blazegraph
# instances per host (preventing configuration by profile), and multiple roles
# per datasource (preventing configuration by role).
class profile::query_service::wikidata(
    String $username = lookup('profile::query_service::username'),
    Stdlib::Unixpath $package_dir = lookup('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = lookup('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = lookup('profile::query_service::log_dir'),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Stdlib::Port $logstash_logback_port = lookup('logstash_logback_port'),
    String $heap_size = lookup('profile::query_service::blazegraph_heap_size', {'default_value' => '31g'}),
    Boolean $use_deployed_config = lookup('profile::query_service::blazegraph_use_deployed_config', {'default_value' => false}),
    Array[String] $options = lookup('profile::query_service::blazegraph_options'),
    Array[String] $extra_jvm_opts = lookup('profile::query_service::blazegraph_extra_jvm_opts'),
    Array[String] $prometheus_nodes = lookup('prometheus_nodes'),
    String $contact_groups = lookup('contactgroups', {'default_value' => 'admins'}),
    Boolean $monitoring_enabled = lookup('profile::query_service::blazegraph::monitoring_enabled', {'default_value' => false}),
    Optional[String] $sparql_query_stream = lookup('profile::query_service::sparql_query_stream', {'default_value' => undef}),
    Optional[String] $event_service_endpoint = lookup('profile::query_service::event_service_endpoint', {'default_value' => undef}),
    String $federation_user_agent = lookup('profile::query_service::federation_user_agent'),
    String $blazegraph_main_ns = lookup('profile::query_service::blazegraph_main_ns'),
    Enum['regular','streaming'] $updater_type = lookup('profile::query_service::updater_type', {'default_value' => 'regular'})
) {
    require ::profile::query_service::common
    case $updater_type {
        'regular': { require ::profile::query_service::updater }
        'streaming': { require ::profile::query_service::streaming_updater }
        default: { fail("Unsupported updater_type: ${updater_type}") }
    }
    require ::profile::query_service::gui

    $instance_name = "${deploy_name}-blazegraph"
    $nginx_port = 80
    $blazegraph_port = 9999
    $prometheus_port = 9193
    $prometheus_agent_port = 9102

    profile::query_service::blazegraph { $instance_name:
        journal                => 'wikidata',
        blazegraph_main_ns     => $blazegraph_main_ns,
        username               => $username,
        package_dir            => $package_dir,
        data_dir               => $data_dir,
        log_dir                => $log_dir,
        deploy_name            => $deploy_name,
        logstash_logback_port  => $logstash_logback_port,
        heap_size              => $heap_size,
        use_deployed_config    => $use_deployed_config,
        options                => $options,
        extra_jvm_opts         => $extra_jvm_opts,
        prometheus_nodes       => $prometheus_nodes,
        contact_groups         => $contact_groups,
        monitoring_enabled     => $monitoring_enabled,
        sparql_query_stream    => $sparql_query_stream,
        event_service_endpoint => $event_service_endpoint,
        nginx_port             => $nginx_port,
        blazegraph_port        => $blazegraph_port,
        prometheus_port        => $prometheus_port,
        prometheus_agent_port  => $prometheus_agent_port,
        config_file_name       => 'RWStore.wikidata.properties',
        prefixes_file          => 'prefixes.conf',
        use_geospatial         => true,
        federation_user_agent  => $federation_user_agent,
    }

    if ($monitoring_enabled) {
        class { '::profile::query_service::monitor::wikidata': }
    }
}
