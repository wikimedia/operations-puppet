# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::pushgateway (
    Optional[Stdlib::Fqdn] $pushgateway_host = lookup('profile::prometheus::pushgateway_host'),
) {
    $http_port = 9091

    if $pushgateway_host == $::fqdn {
        $ensure = present
    } else {
        $ensure = absent
    }

    class { 'prometheus::pushgateway':
        ensure      => $ensure,
        listen_port => $http_port,
    }
}
