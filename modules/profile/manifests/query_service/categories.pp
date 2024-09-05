# SPDX-License-Identifier: Apache-2.0
# = Class: profile::query_service::categories
#
# This class defines a meta-class that pulls in all the query_service profiles
# necessary for a query service installation servicing the commons.wikimedia.org
# dataset.
#
# This additionally provides a location for defining datasource specific
# configuration, such as if geo support is necessary. This kind of
# configuration doesn't end up fitting in hiera as we have multiple blazegraph
# instances per host (preventing configuration by profile), and multiple roles
# per datasource (preventing configuration by role).
class profile::query_service::categories(
    String $username = lookup('profile::query_service::username'),
    Stdlib::Unixpath $package_dir = lookup('profile::query_service::package_dir'),
    Stdlib::Unixpath $data_dir = lookup('profile::query_service::data_dir'),
    Stdlib::Unixpath $log_dir = lookup('profile::query_service::log_dir'),
    String $deploy_name = lookup('profile::query_service::deploy_name'),
    Stdlib::Port $logstash_logback_port = lookup('logstash_logback_port'),
    Boolean $use_deployed_config = lookup('profile::query_service::blazegraph_use_deployed_config', {'default_value' => false}),
    Array[String] $extra_jvm_opts = lookup('profile::query_service::blazegraph_extra_jvm_opts'),
    String $contact_groups = lookup('contactgroups', {'default_value' => 'admins'}),
    String $federation_user_agent = lookup('profile::query_service::federation_user_agent'),
    Enum['none', 'daily', 'weekly'] $load_categories = lookup('profile::query_service::load_categories', { 'default_value' => 'daily' }),
    Stdlib::Httpurl $categories_endpoint =  lookup('profile::query_service::categories_endpoint', { 'default_value' => 'http://localhost:9990' }),
) {
    require ::profile::query_service::common
    include ::profile::query_service::monitor::categories

    $instance_name = "${deploy_name}-categories"
    $nginx_port = 80
    $blazegraph_port = 9990
    $prometheus_port = 9194
    $prometheus_agent_port = 9103

    class { 'query_service::categories_reload_crontasks':
      package_dir         => $package_dir,
      data_dir            => $data_dir,
      log_dir             => $log_dir,
      deploy_name         => $deploy_name,
      username            => $username,
      load_categories     => $load_categories,
      categories_endpoint => $categories_endpoint,
    }

    profile::query_service::blazegraph { $instance_name:
        journal                => 'categories',
        # initial namespace for categories, this will not be used as importing
        # the categories should always create a new namespace suffixed with the
        # date and tracked in the aliases.map file
        blazegraph_main_ns     => 'categories',
        username               => $username,
        package_dir            => $package_dir,
        data_dir               => $data_dir,
        log_dir                => $log_dir,
        deploy_name            => $deploy_name,
        logstash_logback_port  => $logstash_logback_port,
        heap_size              => '8g',
        use_deployed_config    => $use_deployed_config,
        extra_jvm_opts         => $extra_jvm_opts,
        contact_groups         => $contact_groups,
        monitoring_enabled     => true, # ????
        sparql_query_stream    => undef,
        event_service_endpoint => undef,
        nginx_port             => $nginx_port,
        blazegraph_port        => $blazegraph_port,
        prometheus_port        => $prometheus_port,
        prometheus_agent_port  => $prometheus_agent_port,
        config_file_name       => 'RWStore.categories.properties',
        prefixes_file          => 'prefixes.conf',
        use_geospatial         => false,
        use_oauth              => false,
        federation_user_agent  => $federation_user_agent,
    }
}
