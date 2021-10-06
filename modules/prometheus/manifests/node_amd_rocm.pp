# = Class: prometheus::node_amd_rocm
#
# Periodically export AMD ROCm GPU stats via node-exporter textfile collector.
#
# Why not a node_amd_rocm exporter?
#
# In WMF's case there aren't a lot of machines with a GPU deployed, and the
# number of metrics to collect are really few.
#
class prometheus::node_amd_rocm (
    Wmflib::Ensure   $ensure = 'present',
    Stdlib::Unixpath $outfile = '/var/lib/prometheus/node.d/rocm.prom',
    Stdlib::Unixpath $rocm_smi_path = '/opt/rocm/bin/rocm-smi',
) {
    if $outfile !~ '\.prom$' {
        fail("outfile (${outfile}): Must have a .prom extension")
    }

    ensure_packages( [
        'python3-prometheus-client',
        'python3-requests',
    ] )

    file { '/usr/local/bin/prometheus-amd-rocm-stats':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-amd-rocm-stats.py',
    }

    # Collect every minute
    systemd::timer::job { 'prometheus_amd_rocm_stats':
        ensure      => $ensure,
        description => 'Regular job to collect AMD ROCm GPU stats',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-amd-rocm-stats --outfile ${outfile} --rocm-smi-path ${rocm_smi_path}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
