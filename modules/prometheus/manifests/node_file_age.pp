# SPDX-License-Identifier: Apache-2.0
# == Define: prometheus::node_file_age
#
# Generate file age (UNIX time of the last modification) metrics
# for export via node-exporter textfile collector.
#
# == Parameters
# [*paths*]
#   Array of path names to collect
#
# [*outfile*]
#   The collector will write metrics to this file.
#
# [*metric*]
#   The metric name to use.
#
# [*ensure*]
#   Present or absent
#

define prometheus::node_file_age (
    Array[Stdlib::Unixpath, 1] $paths,
    Stdlib::Unixpath $outfile,
    String $metric = 'node_file_age_timestamp_seconds',
    Wmflib::Ensure $ensure = 'present',
) {

    if !($outfile =~ /\.prom$/) {
        fail("\$outfile should end with '.prom' but is [${outfile}]")
    }

    ensure_packages(['python3-prometheus-client'])

    if (!defined(File['/usr/local/bin/prometheus-file-age'])) {
        file { '/usr/local/bin/prometheus-file-age':
            ensure => $ensure,
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-file-age.py',
        }
    }

    # Collect every minute
    $safe_title = regsubst($title, ' ', '_', 'G')
    systemd::timer::job { $safe_title:
        ensure      => $ensure,
        description => 'Regular job to collect file age metrics',
        user        => 'root',
        command     => inline_template("/usr/local/bin/prometheus-file-age --outfile <%= @outfile %> --metric <%= @metric %> <%= @paths.map{ | i | '\"' + i + '\"' }.join(' ') %>"),
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
        require     => Class['prometheus::node_exporter'],
    }
}
