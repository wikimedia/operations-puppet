# == Define profile::prometheus::redis_exporter
#
# Install an instance of prometheus-redis-exporter.
#
# [*title*]
#   The port redis server is listening on
#
# [*password*]
#   The password to be used to access redis.
#
# [*hostname*]
#   The hostname for redis-exporter to listen on.
#
# [*port*]
#   The port for redis-exporter to listen on.
#
# [*prometheus_nodes*]
#   A list of hosts to allow access to redis-exporter
#
define profile::prometheus::redis_exporter (
    $password,
    $prometheus_nodes,
    $hostname = $::hostname,
    $port = $title + 10000,
    $arguments = '',
) {
    ::prometheus::redis_exporter { $title:
        hostname  => $hostname,
        port      => $port,
        password  => $password,
        arguments => $arguments,
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { "redis_exporter_${title}":
        proto  => 'tcp',
        port   => $port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
