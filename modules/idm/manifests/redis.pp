# SPDX-License-Identifier: Apache-2.0
class idm::redis (
    Stdlib::Fqdn        $redis_master,
    Array[Stdlib::Fqdn] $redis_replicas,
    String              $redis_password,
    Stdlib::Port        $redis_port,
    Integer             $redis_maxmem,
){

    unless $redis_replicas.empty() {
        firewall::service { 'redis_replication':
            proto  => 'tcp',
            port   => $redis_port,
            srange => $redis_replicas,
        }
    }

    $base_redis_settings =  {
        bind        => [$facts['networking']['ip'], $facts['networking']['ip6']],
        maxmemory   => $redis_maxmem,
        port        => $redis_port,
        requirepass => $redis_password,
    }

    $replica_redis_settings = {
        replicaof  => "${$redis_master} ${redis_port}",
        masterauth => $redis_password,
    }

    unless $facts['networking']['hostname'] in $redis_master {
        $redis_settings = $base_redis_settings + $replica_redis_settings
    } else {
        $redis_settings =  $base_redis_settings
    }

    redis::instance { String($redis_port):
        settings => $redis_settings,
        notify   => Service['uwsgi-bitu', 'rq-bitu'],
    }

    $redis_service_name = "redis-instance-tcp_${redis_port}"
    profile::auto_restarts::service { $redis_service_name: }
}
