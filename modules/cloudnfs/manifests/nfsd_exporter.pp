# SPDX-License-Identifier: Apache-2.0
# == Class: cloudnfs::nfsd_exporter
#
# Exports metrics from /proc/fs/nfsd (NFSv4 client and stateid counts,
# per-export statistics labelled by the exported path and the NFSd file
# cache statistics) as a node exporter textfile collector, complementing
# the "nfsd" metrics that node_exporter itself reads from /proc/net/rpc/nfsd.
#
# [*outfile*]
#   Output file for the exporter, inside the node exporter textfile directory
#
# [*interval*]
#   systemd timer syntax (systemd.time(7)) controlling how often the exporter
#   runs, e.g. 'minutely' for every minute
#
class cloudnfs::nfsd_exporter (
    Wmflib::Ensure $ensure = 'present',
    String         $outfile  = '/var/lib/prometheus/node.d/nfsd.prom',
    String         $interval = 'minutely',
) {
    # Summarise /proc/fs/nfsd for the node exporter textfile collector
    prometheus::node_textfile { 'nfsd-textfile-exporter':
        ensure         => $ensure,
        filesource     => 'puppet:///modules/cloudnfs/nfsd-textfile-exporter.py',
        interval       => $interval,
        run_cmd        => "/usr/local/bin/nfsd-textfile-exporter --outfile ${outfile}",
        extra_packages => ['python3-prometheus-client'],
    }

    file { $outfile:
      ensure => $ensure,
    }
}
