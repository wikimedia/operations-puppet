# SPDX-License-Identifier: Apache-2.0
# @summary Configures an Apache vhost that lets trusted projects and other trusted hosts
#   (for example cloudcumin) submit requests to the alertmanager api. (see T304716 and T362061)
# @param $trusted_hosts List of trusted Prometheus hosts per project
class profile::wmcs::metricsinfra::alertmanager::api_rw_proxy (
    Hash[String, Array[Stdlib::Fqdn]] $trusted_hosts = lookup('profile::wmcs::metricsinfra::alertmanager::api_rw_proxy::trusted_hosts'),
) {
    $trusted_ips = $trusted_hosts.values.flatten.map |Stdlib::Fqdn $fqdn| {
        ipresolve($fqdn, 4)
    }

    httpd::site { 'alertmananger-api-rw-proxy':
        content => epp(
            'profile/wmcs/metricsinfra/alertmanager/api_rw_proxy/vhost.conf.epp',
            {
                'server_name' => $facts['fqdn'],
                'domain'      => $facts['domain'],
                'trusted_ips' => $trusted_ips,
            },
        ),
    }
}
