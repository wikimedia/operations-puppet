class prometheus::node_cloudvirt_libvirt_stats(
  Wmflib::Ensure $ensure  = 'present',
  Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/node_cloudvirt_libvirt_stats.prom',
) {
    ensure_packages(['python3-click'])

    $script = '/usr/local/bin/prometheus-node-cloudvirt-libvirt-stats'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-node-cloudvirt-libvirt-stats.py',
    }

    systemd::timer::job { 'prometheus-node-cloudvirt-libvirt-stats':
        ensure         => $ensure,
        user           => 'root',
        description    => 'Generate cloudvirt specific libvirt statistics.',
        command        => $script,
        stdout         => "file:${outfile}",
        stderr         => 'journal',
        exec_start_pre => "/usr/bin/rm -f ${outfile}",
        interval       => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        require        => [File[$script], Class['prometheus::node_exporter'],]
    }
}
