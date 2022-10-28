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
    Array[Stdlib::Fqdn] $jenkins_master_hosts = lookup('profile::ci::firewall::jenkins_master_hosts'),
    Array[Stdlib::Fqdn] $zuul_merger_hosts = lookup('profile::ci::firewall::zuul_merger_hosts'),
) {
    class { '::profile::base::firewall': }
    include ::network::constants

    # Restrict some services to be only reacheable from localhost over both
    # IPv4 and IPv6 (to be safe)

    # Jenkins on port 8080, reacheable via Apache proxying the requests
    ferm::service { 'jenkins_localhost_only':
        proto  => 'tcp',
        port   => '8080',
        srange => '(127.0.0.1 ::1)',
    }

    # Zuul status page on port 8001, reacheable via Apache proxying the requests
    ferm::service { 'zuul_localhost_only':
        proto  => 'tcp',
        port   => '8001',
        srange => '(127.0.0.1 ::1)',
    }

    # Each master is an agent of the other
    $jenkins_master_hosts_ferm = join($jenkins_master_hosts, ' ')
    ferm::service { 'jenkins_masters_ssh':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${jenkins_master_hosts_ferm}))",
    }

    # Gearman is used between Zuul and the Jenkin master, both on the same
    # server and communicating over localhost.
    # It is also used by Zuul merger daemons.
    $zuul_merger_hosts_ferm = join($zuul_merger_hosts, ' ')

    ferm::service { 'gearman_from_zuul_mergers':
        proto  => 'tcp',
        port   => '4730',
        srange => "(${zuul_merger_hosts_ferm})",
    }

    # web access
    ferm::service { 'ci_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}
