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

define thanos::sidecar (
    Stdlib::Port::Unprivileged $prometheus_port,
    String $prometheus_instance,
    Stdlib::Port::Unprivileged $http_port,
    Stdlib::Port::Unprivileged $grpc_port,
) {
    require_package('thanos')

    $grpc_address = "0.0.0.0:${grpc_port}"
    $http_address = "0.0.0.0:${http_port}"
    $prometheus_base = "/srv/prometheus/${prometheus_instance}"
    $prometheus_url = "http://localhost:${prometheus_port}/${prometheus_instance}"
    $service_name = "thanos-sidecar@${title}"
    $tsdb_path = "${prometheus_base}/metrics"

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
