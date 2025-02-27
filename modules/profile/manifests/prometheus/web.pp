# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::web () {
    class { '::httpd':
        modules => ['proxy', 'proxy_http', 'rewrite', 'lbmethod_byrequests', 'proxy_balancer'],
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    firewall::service { 'prometheus-web':
        proto    => 'tcp',
        port     => [80],
        src_sets => ['DOMAIN_NETWORKS'],
    }

    prometheus::instances().each |$instance, $config| {
        # Configure reverse proxy for prometheus instances belonging to this host or site
        $hosts_for_site = $config['hosts'].filter |$h| { $h =~ "\\.${::site}" }
        if $::fqdn in $config['hosts'] or !empty($hosts_for_site) {
            prometheus::web { $instance:
                proxy_pass => prometheus::proxy_pass($config),
            }
        }
    }
}
