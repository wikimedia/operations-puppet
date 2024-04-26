# SPDX-License-Identifier: Apache-2.0
# Configure a Redis instance to receive PHP stack traces from MediaWiki app servers,
# for processing by Arc Lamp servers.  (see profile::webperf::arclamp).

class profile::arclamp::redis() {

    redis::instance { '6379':
        settings => {
            maxmemory                   => '2Mb',
            stop_writes_on_bgsave_error => 'no',
            bind                        => '0.0.0.0',
        },
    }

    firewall::service { 'xenon_redis':
        proto    => 'tcp',
        port     => 6379,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    prometheus::redis_exporter { '6379': }

    profile::auto_restarts::service { 'redis-instance-tcp_6379': }
}
