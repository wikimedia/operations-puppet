# SPDX-License-Identifier: Apache-2.0
# == class contint::firewall
#
# === Parameters
#
# Several bricks communicate with the Zuul Gearman server:
#
# [$zuul_merger_hosts] List of zuul-mergers
#
class profile::ci::firewall (
    Array[Stdlib::Fqdn] $zuul_merger_hosts = lookup('profile::ci::firewall::zuul_merger_hosts'),
){
    include profile::firewall
    include network::constants

    # Each master is an agent of the other
    include profile::ci::firewall::jenkinsagent

    # Gearman is used between Zuul and the Jenkin master, both on the same
    # server and communicating over localhost.
    # It is also used by Zuul merger daemons.
    firewall::service { 'gearman_from_zuul_mergers':
        proto  => 'tcp',
        port   => 4730,
        srange => $zuul_merger_hosts,
    }

    firewall::service { 'ci_http':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['CACHES'],
    }
}
