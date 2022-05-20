# SPDX-License-Identifier: Apache-2.0
# == Define: thanos::sidecar
#
# The sidecar sits alongside each Prometheus server instance. It exposes
# Thanos' StoreAPI for Thanos query to consume. Optionally, data can be
# uploaded to object storage for long term retention.
#
# = Parameters
# [*prometheus_port*] The port Prometheus server is listening to
# [*prometheus_instance*] The name of the Prometheus instance to sidecar
# [*http_port*] The port to listen on for HTTP
# [*grpc_port*] The port to listen on for gRPC
# [*objstore_account*] The account to use to access object storage
# [*objstore_password*] The password to access object storage
# [*min_time*] Start of time range limit to serve. Can be RFC3339-style
#              absolute time or relative to now (e.g. -1d)

define thanos::sidecar (
    Stdlib::Port::Unprivileged $prometheus_port,
    String $prometheus_instance,
    Stdlib::Port::Unprivileged $http_port,
    Stdlib::Port::Unprivileged $grpc_port,
    Optional[Hash[String, String]] $objstore_account = undef,
    Optional[String] $objstore_password = undef,
    Optional[String] $min_time = undef,
) {
    ensure_packages(['thanos'])

    $grpc_address = "0.0.0.0:${grpc_port}"
    $http_address = "0.0.0.0:${http_port}"
    $prometheus_base = "/srv/prometheus/${prometheus_instance}"
    $prometheus_url = "http://localhost:${prometheus_port}/${prometheus_instance}"
    $service_name = "thanos-sidecar@${title}"
    $tsdb_path = "${prometheus_base}/metrics"
    $objstore_config_file = "/etc/${service_name}/objstore.yaml"

    file { "/etc/${service_name}":
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    # Clean up credentials as needed
    $objstore_config_state = $objstore_account ? {
        undef   => absent,
        default => present,
    }
    $objstore_content = $objstore_account ? {
        undef   => '',
        default => template('thanos/objstore.yaml.erb'),
    }

    file { $objstore_config_file:
        ensure    => $objstore_config_state,
        mode      => '0440',
        owner     => 'prometheus', # sidecar runs as 'prometheus' to be able to read local TSDB
        group     => 'root',
        show_diff => false,
        content   => $objstore_content,
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        content        => systemd_template('thanos-sidecar@'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
