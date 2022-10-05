# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::alertmanager::ack (
    Stdlib::Host $active_host = lookup('profile::wmcs::metricsinfra::alertmanager_active_host'),
) {
    if $active_host == $::fqdn {
        $ensure = present
    } else {
        $ensure = absent
    }

    class { 'alertmanager::ack':
        ensure      => $ensure,
        listen_port => 19195,
    }
}
