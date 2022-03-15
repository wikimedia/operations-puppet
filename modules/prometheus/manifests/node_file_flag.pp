# == Define: prometheus::node_file_flag
#
# Generate file flag metrics by checking existence of specific paths
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

define prometheus::node_file_flag (
    Array[String] $paths,
    Stdlib::AbsolutePath $outfile,
    String $metric = 'node_file_flag',
    Wmflib::Ensure $ensure = 'present',
) {

    if !($outfile =~ /\.prom$/) {
        fail("\$outfile should end with '.prom' but is [${outfile}]")
    }

    ensure_packages(['python3-prometheus-client'])

    if (!defined(File['/usr/local/bin/prometheus-file-flag'])) {
        file { '/usr/local/bin/prometheus-file-flag':
            ensure => $ensure,
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-file-flag.py',
        }
    }

    # Collect every minute
    $safe_title = regsubst($title, ' ', '_', 'G')
    systemd::timer::job { $safe_title:
        ensure      => $ensure,
        description => 'Regular job to collect file flag metrics',
        user        => 'root',
        command     => inline_template("/usr/local/bin/prometheus-file-flag --outfile <%= @outfile %> --metric <%= @metric %> <%= @paths.map{ | i | '\"' + i + '\"' }.join(' ') %>"),
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
        require     => Class['prometheus::node_exporter'],
    }
}
