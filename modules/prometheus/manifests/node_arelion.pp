# SPDX-License-Identifier: Apache-2.0
# = Class: prometheus::node_arelion
#
# Periodically export Arelion stats via node-exporter textfile collector.
#
# Connects to the Arelion API and fetch then expose the data we need to Prometheus


class prometheus::node_arelion (
    Stdlib::Fqdn     $active_server,
    String           $username,
    String           $password,
    String           $client_id,
    String           $client_secret,
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/arelion.prom',
) {
    if $outfile !~ '\.prom$' {
        fail("outfile (${outfile}): Must have a .prom extension")
    }

    ensure_packages( [
        'python3-prometheus-client',
        'python3-requests',
    ] )

    file { '/usr/local/bin/prometheus-arelion-exporter':
        ensure  => file,
        mode    => '0555',
        content => template('prometheus/usr/local/bin/prometheus-arelion-exporter.py.erb'),
    }

    $timer_ensure = ($active_server == $facts['networking']['fqdn']) ? {
        true    => 'present',
        default => 'absent',
    }
    # Collect every minute
    systemd::timer::job { 'prometheus_arelion_exporter':
        ensure      => $timer_ensure,
        description => 'Regular job to collect Arelion data',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-arelion-exporter --outfile ${outfile}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
