# SPDX-License-Identifier: Apache-2.0
#
class prometheus::ethtool_exporter(
    Wmflib::Ensure $ensure = 'present',
) {
    if debian::codename::ge('bookworm') {
        ensure_packages(['prometheus-ethtool-exporter',], {'ensure' => $ensure})

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

