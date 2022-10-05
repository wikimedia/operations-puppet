# SPDX-License-Identifier: Apache-2.0
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
define profile::prometheus::redis_exporter (
    String       $password,
    Stdlib::Host $hostname  = $facts['hostname'],
    Stdlib::Port $port      = Integer($title) + 10000,
    String       $arguments = '',
){

    prometheus::redis_exporter { $title:
        hostname  => $hostname,
        port      => $port,
        password  => $password,
        arguments => $arguments,
    }
}
