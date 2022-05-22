# SPDX-License-Identifier: Apache-2.0
# @summary Configures an Apache vhost that lets other trusted projects
# submit requests to the alertmanager api. (see T304716)
# @param $trusted_hosts List of trusted Prometheus hosts per project
class profile::wmcs::metricsinfra::alertmanager::project_proxy (
    Hash[String, Array[Stdlib::Fqdn]] $trusted_hosts = lookup('profile::wmcs::metricsinfra::alertmanager::project_proxy::trusted_hosts'),
) {
    $trusted_ips = $trusted_hosts.values.flatten.map |Stdlib::Fqdn $fqdn| {
        ipresolve($fqdn, 4)
    }

    httpd::site { 'alertmananger-project-proxy':
        content => template('profile/wmcs/metricsinfra/alertmanager/project-proxy/vhost.conf.erb'),
    }
}
