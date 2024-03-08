# SPDX-License-Identifier: Apache-2.0
#
class prometheus::ethtool_exporter(
    Wmflib::Ensure $ensure = 'present',
) {
    if debian::codename::ge('bookworm') {
        package { 'prometheus-ethtool-exporter':
            ensure => stdlib::ensure($ensure, 'package'),
        }

        $override_content = @(CONTENT)
        [Service]
        ExecStart =
        ExecStart = /usr/bin/prometheus-ethtool-exporter --skip-no-link -f /var/lib/prometheus/node.d/ethtool.prom -q
        | CONTENT

        systemd::service {  'prometheus-ethtool-exporter':
            ensure   => $ensure,
            override => true,
            restart  => true,
            content  => $override_content,
        }

        profile::auto_restarts::service { 'prometheus-ethtool-exporter': }
    }
}
