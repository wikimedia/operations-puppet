# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::web () {
    class { '::httpd':
        modules => ['proxy', 'proxy_http', 'rewrite', 'lbmethod_byrequests', 'proxy_balancer'],
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    prometheus::instances().each |$instance, $config| {
        if $::fqdn in $config['hosts'] {
            prometheus::web { $instance:
                proxy_pass => prometheus::proxy_pass($config),
            }
        }
    }
}
