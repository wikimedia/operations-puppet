# SPDX-License-Identifier: Apache-2.0
#
# Configuration files holding service mesh definitions from hieradata. Sophroid's expected format is
# the same as hieradata/common/profile/services_proxy/envoy.yaml and hieradata/common/service.yaml.
#
# These are injected via ConfigMap into the Sophroid pod as a transitional phase, so changes require
# a Puppet run on the deploy host, then a helmfile apply. When Sophroid is reading this data
# canonically from etcd instead, we can remove this, or shrink it to only the long-term static
# config (such as just the services list).
class profile::kubernetes::deployment_server::sophroid_config (
    Stdlib::Unixpath $general_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', { default_value => '/etc/helmfile-defaults' }),
    Hash[String, Hash] $service_catalog = lookup('service::catalog', { 'default_value' => [] }),
    Boolean $listen_ipv6 = lookup('profile::services_proxy::envoy::listen_ipv6', { 'default_value' => false }),
    Array[Profile::Service_listener] $listeners = lookup('profile::services_proxy::envoy::listeners', { 'default_value' => [] }),
    Array[String] $enabled_listeners = lookup('profile::services_proxy::envoy::enabled_listeners', { 'default_value' => [] }),
    Float $local_otel_reporting_pct = lookup('profile::services_proxy::envoy::local_otel_reporting_pct', { 'default_value' => 0.0 }),
) {
    $sophroid_dir = "${general_dir}/sophroid"
    file { $sophroid_dir:
      ensure => directory,
    }

    file { "${sophroid_dir}/service.yaml":
      ensure  => present,
      content => to_yaml({
        'service::catalog' => $service_catalog,
      }),
    }

    file { "${sophroid_dir}/listeners.yaml":
      ensure  => present,
      content => to_yaml({
        'profile::services_proxy::envoy::listen_ipv6'              => $listen_ipv6,
        'profile::services_proxy::envoy::listeners'                => $listeners,
        'profile::services_proxy::envoy::enabled_listeners'        => $enabled_listeners,
        'profile::services_proxy::envoy::local_otel_reporting_pct' => $local_otel_reporting_pct,
      }),
    }
}
