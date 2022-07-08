# SPDX-License-Identifier: Apache-2.0
# Simple daemon that works as a sidecar for Prometheus Alertmanager and will
# automatically extend expiring silences. The goal of this project is to provide a simple way of
# acknowledging alerts, which is currently not possible with Alertmanager itself.

# https://github.com/prymitive/kthxbye

class alertmanager::ack (
    Optional[Stdlib::Host] $listen_host = undef,
    Stdlib::Port $listen_port = 19195,
    Wmflib::Ensure $ensure = absent,
) {
    ensure_packages(['kthxbye'])

    systemd::service { 'kthxbye':
        ensure   => $ensure,
        content  => init_template('kthxbye', 'systemd_override'),
        override => true,
        restart  => true,
    }
}
