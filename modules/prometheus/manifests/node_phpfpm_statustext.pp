# = Class: prometheus::node_phpfpm_statustext
#
# Periodically parse the PHP-FPM status text and export e.g. the number of idle vs busy workers
# via a node_exporter textfile collector.  Needed for tracking metrics when appservers are under
# excessive load and all workers are busy, causing the exporter that scrapes status from the
# HTTP endpoint to fail. https://phabricator.wikimedia.org/T252605
#
# = Parameters
#
# [*outfile*]
#   Path to write the finished textfile-exporter-format file.
#
# [*php_versions*]
#   List of php versions with the php-fpm pools you want to monitor.

class prometheus::node_phpfpm_statustext (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/phpfpm-statustext.prom',
    Array[Wmflib::Php_version] $php_versions = ['7.2'],
) {
    $exec = '/usr/local/bin/prometheus-phpfpm-statustext'
    file { $exec:
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-phpfpm-statustext.sh',
    }

    # Collect every minute
    systemd::timer::job { 'prometheus-phpfpm-statustext-textfile':
        ensure          => $ensure,
        description     => 'Update PHP-FPM worker count stats exported by node_exporter',
        command         => "${exec} ${outfile} ${php_versions.join(' ')}",
        user            => 'root',
        logging_enabled => false,
        require         => [File[$exec]],
        interval        => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '60s',
        },
    }
}

