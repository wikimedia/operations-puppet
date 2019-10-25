# == Define: prometheus::node_file_count
#
# Generate file count metrics (non-recursive) of specific paths
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

define prometheus::node_file_count (
    Array[String] $paths,
    Stdlib::AbsolutePath $outfile,
    String $metric = 'node_files_total',
    Wmflib::Ensure $ensure = 'present',
) {

    if !($outfile =~ /\.prom$/) {
        fail("\$outfile should end with '.prom' but is [${outfile}]")
    }

    if !($metric =~ /^node_[a-z_]*_total$/) {
        fail("\$metric should begin with 'node_' then lowercase chars or _ and end with '_total' but is [${metric}]")
    }

    require_package(['python3-prometheus-client'])

    if (!defined(File['/usr/local/bin/prometheus-file-count'])) {
        file { '/usr/local/bin/prometheus-file-count':
            ensure => $ensure,
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-file-count.py',
        }
    }

    # Collect every minute
    cron { $title:
        ensure  => $ensure,
        user    => 'root',
        command => inline_template("/usr/local/bin/prometheus-file-count --outfile <%= @outfile %> --metric <%= @metric %> <%= @paths.map{ | i | '\"' + i + '\"' }.join(' ') %>"),
        require => Package['prometheus-node-exporter'],
    }
}
