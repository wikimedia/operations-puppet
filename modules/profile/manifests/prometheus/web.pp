# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::web () {
    # Acts as a reverse proxy http -> https, hence 'mod_ssl' + http_only
    class { '::httpd':
        modules   => ['rewrite',
                      'proxy','proxy_http', 'proxy_balancer',
                      'lbmethod_byrequests', 'ssl'],
        http_only => true,
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
        if $facts['networking']['fqdn'] in $config['hosts'] or !empty($hosts_for_site) {
            prometheus::web { $instance:
                proxy_pass => prometheus::proxy_pass($config),
            }
        }
    }
}
