# SPDX-License-Identifier: Apache-2.0
# = Define: prometheus::dnsbox_service_state_exporter
#
# Periodically exports the state of various dnsbox services, as observed and
# set through confd/confctl.
define prometheus::dnsbox_service_state_exporter (
    Wmflib::Ensure     $ensure,
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/dnsbox_service_state.prom',
) {
    ensure_packages(['python3-prometheus-client'])

    $script_file = '/usr/local/bin/prometheus_dnsbox_service_state'

    file { $script_file:
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/prometheus/${script_file}.py",
    }

    # Collect every minute.
    systemd::timer::job { 'prometheus_dnsbox_service_state_exporter':
        ensure      => $ensure,
        description => 'Regular job to collect state of services (pooled or not) on dnsbox hosts',
        user        => 'root',
        command     => "${script_file} -o ${outfile}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
