# SPDX-License-Identifier: Apache-2.0
# = Class: prometheus::node_dpkg_success
#
# Periodically check whether dpkg is functioning.
#
# Intended to run on all hosts.
#
class prometheus::node_dpkg_success (
    Wmflib::Ensure $ensure = 'present',
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/dpkg.prom',
) {
    $exec = '/usr/local/bin/prometheus-dpkg-success'
    file { $exec:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-dpkg-success.sh',
    }

    systemd::timer::job { 'prometheus-dpkg-success-textfile':
        ensure          => $ensure,
        description     => 'Update dpkg status exported by node_exporter',
        command         => "${exec} ${outfile}",
        user            => 'prometheus',
        logging_enabled => false,
        require         => [File[$exec]],
        interval        => {'start' => 'OnCalendar', 'interval' => '*:00/30:00'},
        splay           => 1800
    }
}
