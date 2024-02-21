# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::etherpad_exporter(
    Stdlib::IP::Address $listen_ip = lookup('profile::prometheus::etherpad_exporter::listen_ip', {'default_value' => '127.0.0.1'}),
    Stdlib::Port $listen_port = lookup('profile::prometheus::etherpad_exporter::listen_port', {'default_value' => 9198}),
    Stdlib::Ensure::Service $service_ensure = lookup('profile::prometheus::etherpad_exporter::service_ensure', {'default_value' => running}),
) {

    ensure_packages('prometheus-etherpad-exporter')

    service { 'prometheus-etherpad-exporter':
        ensure  => $service_ensure,
    }

    $ensure_override = $service_ensure ? {
        running => 'present',
        default => 'absent',
    }

    systemd::override { 'prometheus-etherpad-exporter-add-listen-address':
        ensure  => $ensure_override,
        unit    => 'prometheus-etherpad-exporter',
        content => "[Service]\nExecStart=/usr/bin/prometheus-etherpad-exporter --listen ${listen_ip}:${listen_port}\n",
    }

    profile::auto_restarts::service { 'prometheus-etherpad-exporter': }
}
