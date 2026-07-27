# SPDX-License-Identifier: Apache-2.0
class profile::toolforge::opensearch::haproxy (
    Opensearch::InstanceParams $opensearch_settings = lookup('profile::opensearch::common_settings'),
    Array[Hash]                $users               = lookup('profile::toolforge::opensearch::haproxy::users'),
) {
    class { 'haproxy':
        template => 'profile/toolforge/opensearch/haproxy.cfg.erb',
        # No Icinga support here
        monitor  => false,
    }

    haproxy::site { 'opensearch':
        content => template('profile/toolforge/opensearch/haproxy-site.cfg.erb'),
    }

    # Allow load balancer traffic to peers on back-end ports
    firewall::service { 'haproxy-backend':
        proto  => 'tcp',
        port   => $opensearch_settings['http_port'],
        srange => $opensearch_settings['cluster_hosts'].delete($facts['networking']['fqdn']),
    }

    # Allow front-end traffic to haproxy
    firewall::service { 'haproxy-http':
        proto    => 'tcp',
        port     => 80,
        notrack  => true,
        src_sets => ['CLOUD_NETWORKS'],
    }
}
